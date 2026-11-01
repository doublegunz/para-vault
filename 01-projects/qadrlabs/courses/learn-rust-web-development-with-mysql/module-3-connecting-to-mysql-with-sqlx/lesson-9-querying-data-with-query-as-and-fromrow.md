## 1. Before You Begin

In Lesson 8, a migration created the `tasks` table, and Todo Web now brings its schema up to date at every start. The table is still empty, and the pages still show hard-coded sample tasks. Before wiring the database into the handlers in Module 4, you need to be comfortable with SQLx's query API: how to send SQL with values from Rust, how to read rows back into Rust structs, and how to tell "no rows" apart from "an error."

Learning this inside a web server would mean restarting the server and clicking through pages for every experiment. Instead, you will write a small playground program that runs next to the server code in the same project, prints its results to the terminal, and finishes in a second. Every query in it is one that Todo Web will use in the next lessons.

### What You'll Build

A playground program, `examples/queries.rs`, that empties the `tasks` table, inserts tasks with bound parameters, reads them into a `Task` struct with `query_as` and `#[derive(FromRow)]`, counts them, finds single tasks by ID, and updates and deletes tasks while checking how many rows were affected.

### What You'll Learn

- ✅ How to run a separate program from the same project with Cargo examples
- ✅ How to send values safely with `?` placeholders and `.bind()`
- ✅ How to read `last_insert_id()` and `rows_affected()` from a query result
- ✅ How to map rows to a struct with `#[derive(sqlx::FromRow)]` and `query_as`
- ✅ How MySQL types map to Rust types, including `Option` for `NULL` columns
- ✅ When to use `fetch_all`, `fetch_one`, and `fetch_optional`

### What You'll Need

- The `todo-web` project from Lesson 8, with the `tasks` table created by its migration
- The `.env` file with `DATABASE_URL`

---

## 2. Insert Rows with Bound Parameters

Cargo treats every file in an `examples` folder as a separate small program that can use all of the project's dependencies. That makes it a perfect place for experiments: `cargo run` still starts the server, and `cargo run --example queries` runs the playground.

### Step 1: Add chrono for Dates

The `tasks` table has a `due_date` column of type `DATE`. Rust's standard library has no date type, so add chrono, the most widely used date and time crate, and turn on SQLx's chrono support:

```bash
cargo add chrono
cargo add sqlx --features chrono
```

The second command adds the `chrono` feature to the existing SQLx dependency. `Cargo.toml` now contains:

```toml
chrono = "0.4.45"
sqlx = { version = "0.9.0", features = ["runtime-tokio", "mysql", "chrono"] }
```

### Step 2: Write the First Playground

Create the folder `examples` next to `src`, and in it a file named `queries.rs`:

```rust
use sqlx::mysql::MySqlPoolOptions;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");
    let pool = MySqlPoolOptions::new().connect(&database_url).await?;

    sqlx::query("TRUNCATE TABLE tasks").execute(&pool).await?;

    let titles = ["Learn Rust", "Build a web app", "Connect to MySQL"];
    for title in titles {
        let result = sqlx::query("INSERT INTO tasks (title) VALUES (?)")
            .bind(title)
            .execute(&pool)
            .await?;
        println!(
            "inserted task {} ({} row affected)",
            result.last_insert_id(),
            result.rows_affected()
        );
    }

    Ok(())
}
```

Here is what each part does:

- `main` returns `Result<(), sqlx::Error>`. A `main` that returns a `Result` can use the `?` operator, exactly like the functions in the first course. If any query fails, the program stops and prints the error.
- The first three lines load `.env` and create a pool, as in Lesson 7. The pool uses default settings, which is fine for a playground.
- `sqlx::query("TRUNCATE TABLE tasks")` empties the table and resets the auto-increment counter, so every run starts again from ID 1 and prints the same output. This is fine for a learning database; never put it in real application code.
- `.execute(&pool)` runs a statement that does not return rows, such as `INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE`.
- In `INSERT INTO tasks (title) VALUES (?)`, the `?` is a placeholder. `.bind(title)` supplies its value. SQLx sends the SQL and the value to MySQL separately, so the value can never be mistaken for SQL code, no matter what it contains. This is the protection against SQL injection, explained further in Section 6.
- `execute` returns a `MySqlQueryResult`. `last_insert_id()` gives the ID that `AUTO_INCREMENT` assigned to the new row, and `rows_affected()` tells you how many rows the statement changed.

Run it:

```bash
cargo run --example queries
```

Output:

```text
inserted task 1 (1 row affected)
inserted task 2 (1 row affected)
inserted task 3 (1 row affected)
```

---

## 3. Read Rows into a Struct

Reading data back is where SQLx becomes really useful. Instead of picking values out of each row by hand, you describe the shape of a row with a struct, and SQLx fills it for you.

### Step 1: Define the Task Struct with FromRow

Replace `examples/queries.rs` with this version:

```rust
use chrono::NaiveDate;
use sqlx::MySqlPool;
use sqlx::mysql::MySqlPoolOptions;

#[derive(Debug, sqlx::FromRow)]
struct Task {
    id: u64,
    title: String,
    done: bool,
    due_date: Option<NaiveDate>,
}

fn print_task(task: &Task) {
    let mark = if task.done { "x" } else { " " };
    match task.due_date {
        Some(date) => println!("{:>2}. [{mark}] {} (due {date})", task.id, task.title),
        None => println!("{:>2}. [{mark}] {}", task.id, task.title),
    }
}

async fn insert_task(
    pool: &MySqlPool,
    title: &str,
    due_date: Option<NaiveDate>,
) -> Result<u64, sqlx::Error> {
    let result = sqlx::query("INSERT INTO tasks (title, due_date) VALUES (?, ?)")
        .bind(title)
        .bind(due_date)
        .execute(pool)
        .await?;
    Ok(result.last_insert_id())
}

async fn all_tasks(pool: &MySqlPool) -> Result<Vec<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks ORDER BY id")
        .fetch_all(pool)
        .await
}

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");
    let pool = MySqlPoolOptions::new().connect(&database_url).await?;

    sqlx::query("TRUNCATE TABLE tasks").execute(&pool).await?;

    insert_task(&pool, "Learn Rust", None).await?;
    insert_task(&pool, "Build a web app", NaiveDate::from_ymd_opt(2026, 11, 30)).await?;
    let id = insert_task(&pool, "Connect to MySQL", None).await?;
    println!("last inserted id: {id}");

    for task in all_tasks(&pool).await? {
        print_task(&task);
    }

    Ok(())
}
```

There is a lot here, so take it piece by piece:

- `#[derive(Debug, sqlx::FromRow)]` generates code that builds a `Task` from a database row by matching column names to field names. The `SELECT` must return columns called `id`, `title`, `done`, and `due_date`.
- The field types follow the column types: `BIGINT UNSIGNED` becomes `u64`, `VARCHAR` becomes `String`, `BOOLEAN` (stored as `tinyint(1)`) becomes `bool`, and `DATE` becomes chrono's `NaiveDate`. "Naive" means a date without a time zone, which is exactly what a due date is.
- `due_date` is `Option<NaiveDate>` because the column allows `NULL`. SQLx turns `NULL` into `None` and a date into `Some(date)`. If the field were a plain `NaiveDate`, reading a row with no due date would fail.
- `print_task` prints a task in the style of the command-line to-do list. `{:>2}` right-aligns the ID in two characters.
- `insert_task` packages the insert into a reusable function. It takes the pool by reference, `&MySqlPool`, so callers keep their pool. Binding an `Option<NaiveDate>` works naturally: `None` is sent as `NULL`. The function returns the new ID.
- `all_tasks` uses `sqlx::query_as::<_, Task>(...)`, which works like `query` but maps every row to a `Task`. `.fetch_all(pool)` collects all rows into a `Vec<Task>`. The function returns the query's `Result` directly, so it has no `?` and no `Ok(...)`.
- `NaiveDate::from_ymd_opt(2026, 11, 30)` builds a date. It returns an `Option`, because not every combination is a valid date (`from_ymd_opt(2026, 2, 30)` returns `None`), and that `Option` is exactly what `insert_task` expects.
- The columns are listed explicitly in the `SELECT` instead of using `SELECT *`. The table also has `created_at`, which `Task` does not need. Listing columns keeps the query and the struct in agreement, even when a later migration adds more columns.

Run it:

```bash
cargo run --example queries
```

Output:

```text
last inserted id: 3
 1. [ ] Learn Rust
 2. [ ] Build a web app (due 2026-11-30)
 3. [ ] Connect to MySQL
```

The rows made a round trip: Rust values were bound into `INSERT` statements, stored by MySQL, and read back into `Task` structs, including the optional date.

---

## 4. Fetch One Row or None

Not every query returns a list. Counting returns exactly one value, and looking up a task by ID returns one task or nothing. SQLx has a fetch method for each situation.

### Step 1: Count and Find Tasks

Add these two functions below `all_tasks`:

```rust
async fn count_tasks(pool: &MySqlPool) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar("SELECT COUNT(*) FROM tasks")
        .fetch_one(pool)
        .await
}

async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}
```

Here is the difference between them:

- `count_tasks` uses `query_scalar` from Lesson 7 with `fetch_one`. A `COUNT(*)` query always returns exactly one row, so `fetch_one` is the right choice. The return type `i64` tells SQLx how to decode MySQL's `BIGINT` count.
- `find_task` uses `fetch_optional`, which returns `Ok(Some(task))` when a row is found and `Ok(None)` when there is none. "No task with this ID" is a normal situation, not an error, and `Option` expresses that perfectly. In Lesson 10, `None` will become a 404 page.

Then add these lines to `main`, after the `for` loop and before `Ok(())`:

```rust
    println!("total tasks: {}", count_tasks(&pool).await?);

    match find_task(&pool, 2).await? {
        Some(task) => print_task(&task),
        None => println!("task 2 not found"),
    }
    match find_task(&pool, 99).await? {
        Some(task) => print_task(&task),
        None => println!("task 99 not found"),
    }
```

Run it:

```bash
cargo run --example queries
```

Output:

```text
last inserted id: 3
 1. [ ] Learn Rust
 2. [ ] Build a web app (due 2026-11-30)
 3. [ ] Connect to MySQL
total tasks: 3
 2. [ ] Build a web app (due 2026-11-30)
task 99 not found
```

Task 2 was found, and task 99 cleanly became `None`.

---

## 5. Update and Delete Rows

Changing and deleting rows uses `execute`, just like inserting. The interesting part is the result: `rows_affected()` tells you whether the row you aimed at actually existed.

### Step 1: Add mark_done and delete_task

Add these functions below `find_task`:

```rust
async fn mark_done(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE tasks SET done = TRUE WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

async fn delete_task(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM tasks WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}
```

Both functions return `true` when a row was changed and `false` when no row matched the ID. An `UPDATE` or `DELETE` that matches nothing is not an error in SQL, so this boolean is how your code finds out. In Lesson 12, `false` will become a 404 page.

### Step 2: Use Them in main

Replace the whole `main` function with this final version, which inserts the tasks, runs the lookups from Section 4, and then changes the data:

```rust
#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");
    let pool = MySqlPoolOptions::new().connect(&database_url).await?;

    sqlx::query("TRUNCATE TABLE tasks").execute(&pool).await?;

    insert_task(&pool, "Learn Rust", None).await?;
    insert_task(&pool, "Build a web app", NaiveDate::from_ymd_opt(2026, 11, 30)).await?;
    let id = insert_task(&pool, "Connect to MySQL", None).await?;
    println!("last inserted id: {id}");

    println!("total tasks: {}", count_tasks(&pool).await?);

    match find_task(&pool, 2).await? {
        Some(task) => print_task(&task),
        None => println!("task 2 not found"),
    }
    match find_task(&pool, 99).await? {
        Some(task) => print_task(&task),
        None => println!("task 99 not found"),
    }

    println!("mark 1 as done: {}", mark_done(&pool, 1).await?);
    println!("mark 99 as done: {}", mark_done(&pool, 99).await?);
    println!("delete 3: {}", delete_task(&pool, 3).await?);
    println!("delete 3 again: {}", delete_task(&pool, 3).await?);

    for task in all_tasks(&pool).await? {
        print_task(&task);
    }

    Ok(())
}
```

The final loop prints the table after the changes, so you can see their effect.

---

## 6. Run and Test

Run the complete playground:

```bash
cargo run --example queries
```

Output:

```text
last inserted id: 3
total tasks: 3
 2. [ ] Build a web app (due 2026-11-30)
task 99 not found
mark 1 as done: true
mark 99 as done: false
delete 3: true
delete 3 again: false
 1. [x] Learn Rust
 2. [ ] Build a web app (due 2026-11-30)
```

Read the middle lines carefully. Marking task 1 changed a row, so the result is `true`; task 99 does not exist, so the result is `false`. The first delete removed task 3. The second delete found nothing to remove and returned `false` instead of failing. The final list shows task 1 done and task 3 gone.

Confirm the state from the `mysql` client:

```bash
mysql -u todo_user -p db_rust_todo -e "SELECT id, title, done, due_date FROM tasks;"
```

Output:

```text
id	title	done	due_date
1	Learn Rust	1	NULL
2	Build a web app	0	2026-11-30
```

These two rows stay in the table, and the web pages will show them in Lesson 10. The server itself still works as before; check with `cargo run`, which starts Todo Web, not the example. Commit your work:

```bash
git add -A
git commit -m "lesson 9: queries playground"
```

---

## 7. SQLx Queries at a Glance

You have now used every query building block the to-do app needs. Here they are side by side:

| Function | Returns rows as | Typical use |
| --- | --- | --- |
| `sqlx::query(sql)` | nothing (with `execute`) | `INSERT`, `UPDATE`, `DELETE` |
| `sqlx::query_as::<_, T>(sql)` | a struct `T` that derives `FromRow` | `SELECT` whole records |
| `sqlx::query_scalar(sql)` | a single value | `COUNT(*)`, `VERSION()` |

| Fetch method | Result | Use it when |
| --- | --- | --- |
| `.execute(pool)` | `MySqlQueryResult` | The statement returns no rows |
| `.fetch_all(pool)` | `Vec<T>` | You want every matching row |
| `.fetch_one(pool)` | `T`, or `Err(RowNotFound)` if no row | Exactly one row must exist |
| `.fetch_optional(pool)` | `Option<T>` | Zero or one row is normal |

| MySQL type | Rust type |
| --- | --- |
| `BIGINT UNSIGNED` | `u64` |
| `INT` | `i32` |
| `VARCHAR`, `TEXT` | `String` |
| `BOOLEAN` (`tinyint(1)`) | `bool` |
| `DATE` | `chrono::NaiveDate` |
| `DATETIME` | `chrono::NaiveDateTime` |
| any column that allows `NULL` | `Option<T>` |

Two ideas deserve special attention:

- **Placeholders keep data and code apart.** With `?` and `.bind()`, values travel separately from the SQL text. If you built the SQL with `format!` instead, a title such as `x'); DROP TABLE tasks; --` would become part of the statement, an attack called SQL injection. SQLx 0.9 makes the unsafe version hard to write by accident: the query functions only accept string literals, as Section 8 shows. For queries whose structure really must change at runtime, such as optional filters, SQLx offers `QueryBuilder`, which you will use in Lesson 16.
- **These queries are checked at runtime.** SQLx also has macros such as `sqlx::query_as!` that check the SQL against a live database while compiling. They are powerful, but they need the database (or prepared metadata) available every time you build. This course uses the runtime functions, which compile anywhere and report mistakes as errors when the query runs, so the "Fix the Errors" sections show what those errors look like.

---

## 8. Fix the Errors in Your Code

**Error 1: Building SQL with format!**

```rust
// Wrong
async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    let sql = format!("SELECT id, title, done, due_date FROM tasks WHERE id = {id}");
    sqlx::query_as::<_, Task>(&sql)
        .fetch_optional(pool)
        .await
}
```

```rust
// Correct
async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}
```

SQLx refuses SQL built at runtime:

```text
error[E0277]: dynamic SQL strings should be audited for possible injections
   --> examples/queries.rs:48:31
    |
 48 |     sqlx::query_as::<_, Task>(&sql)
    |     ------------------------- ^^^^ dynamic SQL string
    |     |
    |     required by a bound introduced by this call
    |
    = help: the trait `SqlSafeStr` is not implemented for `&std::string::String`
    = note: prefer literal SQL strings with bind parameters or `QueryBuilder` to add dynamic data to a query.
```

The note gives the right fix: keep the SQL a string literal and pass values with `.bind()`. The compiler's "consider dereferencing" suggestion further down would not help, because the trait is only implemented for `&'static str`, as another note in the full message explains.

**Error 2: A field type that does not match the column**

```rust
// Wrong
struct Task {
    id: i32,
    // ...
}
```

```rust
// Correct
struct Task {
    id: u64,
    // ...
}
```

This compiles, because the runtime query functions cannot see the table while compiling. The mistake appears when a row is decoded:

```text
Error: ColumnDecode { index: "\"id\"", source: "mismatched types; Rust type `i32` (as SQL type `INT`) is not compatible with SQL type `BIGINT UNSIGNED`" }
```

The message names the column and both types. SQLx is strict on purpose: a `BIGINT UNSIGNED` can hold values far larger than an `i32`, so silently converting could corrupt data. Use the mapping table in Section 7.

**Error 3: Selecting fewer columns than the struct needs**

```rust
// Wrong
sqlx::query_as::<_, Task>("SELECT id, title FROM tasks ORDER BY id")
```

```rust
// Correct
sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks ORDER BY id")
```

`FromRow` looks up every field by name. When a column is missing from the result, the query fails:

```text
Error: ColumnNotFound("done")
```

Every field of the struct must appear as a column in the `SELECT`. The reverse is fine: extra columns in the result are ignored. If a column has a different name in the table, rename it in SQL with `AS`, for example `SELECT title AS name`.

**Error 4: Using fetch_one when a row might be missing**

```rust
// Wrong
async fn find_task(pool: &MySqlPool, id: u64) -> Result<Task, sqlx::Error> {
    sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks WHERE id = ?")
        .bind(id)
        .fetch_one(pool)
        .await
}
```

```rust
// Correct
async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>("SELECT id, title, done, due_date FROM tasks WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}
```

With `fetch_one`, looking up task 99 is an error, and the `?` in `main` stops the program:

```text
Error: RowNotFound
```

In a web application, treating "not found" as an error would turn a simple 404 into a 500 Internal Server Error. Use `fetch_optional` whenever zero rows is a normal answer.

---

## 9. Exercises

**Exercise 1:** Write `pending_tasks(pool: &MySqlPool) -> Result<Vec<Task>, sqlx::Error>` that returns only the tasks that are not done, ordered by ID. Print them under a `pending:` heading at the end of `main`.

**Exercise 2:** Write `rename_task(pool: &MySqlPool, id: u64, title: &str) -> Result<bool, sqlx::Error>` that changes a task's title and reports whether the task existed. Call it for task 2 with the title `Build Todo Web`, and for task 99.

**Exercise 3:** Write `tasks_due_before(pool: &MySqlPool, date: NaiveDate) -> Result<Vec<Task>, sqlx::Error>` that returns tasks with a due date before the given date, ordered by due date. In `main`, insert a task `Write tests` due on 2026-12-15, then print the tasks due before 2026-12-01. What happens to tasks without a due date?

---

## 10. Solutions

All three functions go below `delete_task`, and the calls go at the end of `main`, before `Ok(())`.

**Solution for Exercise 1:**

```rust
async fn pending_tasks(pool: &MySqlPool) -> Result<Vec<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date FROM tasks WHERE done = FALSE ORDER BY id",
    )
    .fetch_all(pool)
    .await
}
```

```rust
    println!("pending:");
    for task in pending_tasks(&pool).await? {
        print_task(&task);
    }
```

The query is the same as in `all_tasks` plus a `WHERE` clause. The filter runs in MySQL, so only matching rows travel to your program, which matters once a table has thousands of rows.

**Solution for Exercise 2:**

```rust
async fn rename_task(pool: &MySqlPool, id: u64, title: &str) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE tasks SET title = ? WHERE id = ?")
        .bind(title)
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}
```

```rust
    println!("rename 2: {}", rename_task(&pool, 2, "Build Todo Web").await?);
    println!("rename 99: {}", rename_task(&pool, 99, "Nothing").await?);
```

With several placeholders, the `.bind()` calls fill them in order: the first `bind` is the first `?` (the title), the second `bind` is the second `?` (the ID). Swapping them would compare the ID column with a title and update nothing.

**Solution for Exercise 3:**

```rust
async fn tasks_due_before(pool: &MySqlPool, date: NaiveDate) -> Result<Vec<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date FROM tasks WHERE due_date < ? ORDER BY due_date",
    )
    .bind(date)
    .fetch_all(pool)
    .await
}
```

```rust
    insert_task(&pool, "Write tests", NaiveDate::from_ymd_opt(2026, 12, 15)).await?;
    let deadline = NaiveDate::from_ymd_opt(2026, 12, 1).expect("valid date");
    println!("due before {deadline}:");
    for task in tasks_due_before(&pool, deadline).await? {
        print_task(&task);
    }
```

A `NaiveDate` can be bound just like a string or a number. `.expect("valid date")` unwraps the `Option` from `from_ymd_opt`, which is safe here because the date is written by hand. Run the playground; the end of the output is:

```text
pending:
 2. [ ] Build a web app (due 2026-11-30)
rename 2: true
rename 99: false
due before 2026-12-01:
 2. [ ] Build Todo Web (due 2026-11-30)
```

`Write tests` is due on 2026-12-15, so it is not included. Task 1 has no due date and is not included either: in SQL, comparing `NULL` with anything gives "unknown," never true, so `WHERE due_date < ?` skips rows where `due_date` is `NULL` without any extra condition. Note that running this solution leaves the renamed task and the extra task in your database. Before Lesson 10, run the playground once more without the exercise code, or simply keep the extra rows; Lesson 10 works with whatever tasks are in the table.

---

## Next Up - Lesson 10

In this lesson, you learned SQLx's query API in a playground: inserting with `?` placeholders and `.bind()`, reading rows into a `Task` struct with `query_as` and `FromRow`, mapping MySQL types to Rust types with `Option` for `NULL`, and choosing between `fetch_all`, `fetch_one`, and `fetch_optional`. You also used `rows_affected()` to find out whether an update or delete hit a row.

Module 4 brings these queries into the web application. In Lesson 10, you will replace `sample_tasks()` with real MySQL queries: the home page will count unfinished tasks from the database, the task list will show every task from the `tasks` table, each task will get a detail page, and a missing task will return a proper 404 page.
