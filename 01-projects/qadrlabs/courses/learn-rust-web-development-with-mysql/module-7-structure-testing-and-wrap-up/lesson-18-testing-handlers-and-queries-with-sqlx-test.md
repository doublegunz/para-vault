## 1. Before You Begin

Todo Web has eight unit tests, all for code that never touches the database: validation and `escape_like`. The most important parts of the application, the SQL queries and the handlers, are only tested by hand, with `curl` and the browser. That worked while building each feature, but it does not scale: every change could break something you tested two lessons ago, and nobody wants to click through every page after every edit.

This lesson adds automated tests for both. SQLx provides the `#[sqlx::test]` attribute, which creates a brand-new, empty database for every test, applies all migrations, hands the test a connection pool, and removes the database afterwards. Tests can insert and query freely without touching your development data or each other. For handlers, Tower's `oneshot` method sends a single HTTP request straight into the router built by `routes::app` from Lesson 17, without opening a port, so you can check status codes, headers, and HTML in milliseconds.

### What You'll Build

Four database tests in `src/db.rs` (insert and find, missing rows, filtering and pagination, and the `ON DELETE SET NULL` behavior) and four handler tests in `src/routes.rs` (the home page, a 404, creating a task, and an invalid form), bringing the suite to sixteen tests that run with one `cargo test`.

### What You'll Learn

- ✅ How `#[sqlx::test]` creates an isolated test database with migrations applied
- ✅ Why the `todo_user` account needs privileges on `_sqlx_test%` databases
- ✅ How to write async tests that receive a `MySqlPool`
- ✅ How to send requests to an Axum router with `tower::ServiceExt::oneshot`
- ✅ How to build GET and form POST requests and read response bodies in tests
- ✅ How to check the database state after a handler runs

### What You'll Need

- The `todo-web` project from Lesson 17
- The second `GRANT` from Lesson 3, on `\_sqlx\_test%`
- MySQL running, with `DATABASE_URL` set in `.env`

---

## 2. Prepare for Database Tests

`#[sqlx::test]` needs two things: permission to create databases for the tests, and a way to find the server.

### Step 1: Check the Test Privileges

In Lesson 3, you granted `todo_user` all privileges on databases whose names start with `_sqlx_test`. Check that the grant is there:

```bash
mysql -u todo_user -p -e "SHOW GRANTS;"
```

The output must contain this line:

```text
GRANT ALL PRIVILEGES ON `\_sqlx\_test%`.* TO `todo_user`@`localhost`
```

If it is missing, log in with `sudo mysql` and run the grant from Lesson 3, Section 3. Without it, every database test fails with `Access denied`, because SQLx cannot create its test databases.

### Step 2: Add Tower for Handler Tests

Axum is built on Tower, a library of building blocks for network services. Its `ServiceExt` trait provides `oneshot`, the method that sends one request to a service. Add it as a development dependency, which is only compiled for tests:

```bash
cargo add --dev tower --features util
```

`--dev` puts the crate under a new `[dev-dependencies]` section in `Cargo.toml`, so the release binary does not include it:

```toml
[dev-dependencies]
tower = { version = "0.5.3", features = ["util"] }
```

The `util` feature contains `ServiceExt`. Nothing else is needed: SQLx's test support is part of the `sqlx` crate you already have, and it reads `DATABASE_URL` from `.env` to find the server.

---

## 3. Test the Database Queries

Database tests go into the `tests` module of `src/db.rs`, next to the queries they check. Each test is an async function marked with `#[sqlx::test]` that takes a `MySqlPool` parameter.

### Step 1: Write the Query Tests

Replace the `tests` module at the bottom of `src/db.rs` with:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::TaskFilter;
    use chrono::NaiveDate;

    fn new_task(title: &str, category_id: Option<u64>) -> ValidTask {
        ValidTask { title: title.to_string(), due_date: None, category_id }
    }

    fn filter(search: &str, status: &str, page: u64) -> ListFilter {
        ListFilter::from_query(TaskFilter {
            search: Some(search.to_string()),
            status: Some(status.to_string()),
            category: None,
            page: Some(page),
        })
    }

    #[test]
    fn escapes_like_wildcards() {
        assert_eq!(escape_like("100%_done"), "100\\%\\_done");
    }

    #[sqlx::test]
    async fn inserts_and_finds_a_task(pool: MySqlPool) -> sqlx::Result<()> {
        let task = ValidTask {
            title: String::from("Write tests"),
            due_date: NaiveDate::from_ymd_opt(2026, 12, 1),
            category_id: None,
        };
        let id = insert_task(&pool, &task).await?;

        let found = find_task(&pool, id).await?.expect("task should exist");
        assert_eq!(found.title, "Write tests");
        assert!(!found.done);
        assert_eq!(found.due_date, NaiveDate::from_ymd_opt(2026, 12, 1));
        Ok(())
    }

    #[sqlx::test]
    async fn missing_task_is_none(pool: MySqlPool) -> sqlx::Result<()> {
        assert!(find_task(&pool, 42).await?.is_none());
        assert!(!delete_task(&pool, 42).await?);
        Ok(())
    }

    #[sqlx::test]
    async fn filters_and_paginates(pool: MySqlPool) -> sqlx::Result<()> {
        for number in 1..=7 {
            insert_task(&pool, &new_task(&format!("Task {number}"), None)).await?;
        }
        insert_task(&pool, &new_task("Fix 100% CPU bug", None)).await?;
        toggle_task(&pool, 1).await?;

        assert_eq!(count_filtered_tasks(&pool, &filter("", "all", 1)).await?, 8);
        assert_eq!(count_filtered_tasks(&pool, &filter("", "done", 1)).await?, 1);
        assert_eq!(count_filtered_tasks(&pool, &filter("100%", "all", 1)).await?, 1);

        let page_one = filtered_tasks(&pool, &filter("", "all", 1)).await?;
        let page_two = filtered_tasks(&pool, &filter("", "all", 2)).await?;
        assert_eq!(page_one.len(), 5);
        assert_eq!(page_two.len(), 3);
        assert_eq!(page_two.last().map(|task| task.title.as_str()), Some("Task 1"));
        Ok(())
    }

    #[sqlx::test]
    async fn deleting_a_category_keeps_its_tasks(pool: MySqlPool) -> sqlx::Result<()> {
        let category_id = insert_category(&pool, "Work").await?;
        let task_id = insert_task(&pool, &new_task("Reply to emails", Some(category_id))).await?;

        assert!(delete_category(&pool, category_id).await?);

        let task = find_task(&pool, task_id).await?.expect("task should survive");
        assert_eq!(task.category_id, None);
        Ok(())
    }
}
```

Here is how these tests work:

- `#[sqlx::test]` replaces `#[test]` for async database tests. Before the test runs, SQLx creates a new database with a random name starting with `_sqlx_test`, applies every migration from the `migrations` folder, and passes a pool connected to that database as the `pool` parameter. When the test passes, the database is dropped.
- Every test starts with empty tables and its own `AUTO_INCREMENT` counters, so the first inserted task always has ID 1. Tests do not see each other's data, even though they run in parallel.
- A test may return `sqlx::Result<()>`, an alias for `Result<(), sqlx::Error>`, so the queries can use `?`. If any query fails, the test fails with the error.
- `new_task` and `filter` are small helpers that keep the tests readable. `filter` goes through `ListFilter::from_query`, so the tests use exactly the same cleaning as the handler.
- `inserts_and_finds_a_task` checks that a task survives the round trip, including the default `done = FALSE` set by the table and the due date.
- `missing_task_is_none` checks the "not found" paths: `fetch_optional` returns `None`, and deleting a missing row returns `false`.
- `filters_and_paginates` inserts eight tasks, marks task 1 as done, and checks the counts for the status filter and an escaped `100%` search, then checks that page 1 has five tasks and page 2 the remaining three. Because unfinished tasks come first, the finished `Task 1` is the very last item on page 2.
- `deleting_a_category_keeps_its_tasks` proves the `ON DELETE SET NULL` rule from Lesson 15: after the category is deleted, the task still exists with `category_id` set to `None`.

### Step 2: Run the Database Tests

```bash
cargo test db::
```

Passing a name filter runs only the tests whose path contains it, here every test in the `db` module. All five pass. Notice that the database tests take a moment longer than the unit tests: each one creates a database and runs three migrations, which is still only a fraction of a second.

---

## 4. Test the Handlers

Database tests prove that the queries work. Handler tests prove that the whole request path works: routing, extractors, validation, queries, templates, status codes, and redirects.

### Step 1: Write the Handler Tests

Add a `tests` module at the bottom of `src/routes.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::{Body, to_bytes},
        http::{Request, StatusCode, header},
    };
    use sqlx::MySqlPool;
    use tower::ServiceExt;

    async fn body_text(response: axum::response::Response) -> String {
        let bytes = to_bytes(response.into_body(), usize::MAX).await.unwrap();
        String::from_utf8(bytes.to_vec()).unwrap()
    }

    fn post_form(uri: &str, body: &str) -> Request<Body> {
        Request::builder()
            .method("POST")
            .uri(uri)
            .header(header::CONTENT_TYPE, "application/x-www-form-urlencoded")
            .body(Body::from(body.to_string()))
            .unwrap()
    }

    #[sqlx::test]
    async fn home_page_counts_tasks(pool: MySqlPool) {
        let app = app(AppState { pool });

        let request = Request::builder().uri("/").body(Body::empty()).unwrap();
        let response = app.oneshot(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::OK);
        let html = body_text(response).await;
        assert!(html.contains("You have 0 unfinished tasks out of 0."));
    }

    #[sqlx::test]
    async fn missing_task_returns_404(pool: MySqlPool) {
        let app = app(AppState { pool });

        let request = Request::builder().uri("/tasks/999").body(Body::empty()).unwrap();
        let response = app.oneshot(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::NOT_FOUND);
        assert!(body_text(response).await.contains("404 Not Found"));
    }

    #[sqlx::test]
    async fn creating_a_task_saves_it_and_redirects(pool: MySqlPool) {
        let app = app(AppState { pool: pool.clone() });

        let request = post_form("/tasks", "title=Write+tests&due_date=2026-12-01");
        let response = app.oneshot(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::SEE_OTHER);
        assert_eq!(response.headers()[header::LOCATION], "/tasks/1");

        let title: String = sqlx::query_scalar("SELECT title FROM tasks WHERE id = 1")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(title, "Write tests");
    }

    #[sqlx::test]
    async fn invalid_form_shows_errors(pool: MySqlPool) {
        let app = app(AppState { pool: pool.clone() });

        let response = app.oneshot(post_form("/tasks", "title=&due_date=soon")).await.unwrap();

        assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
        let html = body_text(response).await;
        assert!(html.contains("Title is required."));
        assert!(html.contains("Due date must be a valid date (YYYY-MM-DD)."));

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tasks")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(count, 0);
    }
}
```

Here is what each part does:

- `use tower::ServiceExt;` brings the `oneshot` method into scope. A `Router` is a Tower service, so `app.oneshot(request)` sends the request through the router exactly as a real connection would, and returns the response. No port, no network, no running server.
- `app(AppState { pool })` builds the real router from Lesson 17 around the test database. This is why the router lives in its own function.
- `Request::builder()` builds an HTTP request: `.uri(...)` sets the path, `.method("POST")` the method, `.header(...)` a header, and `.body(...)` the body. `Body::empty()` is an empty body for `GET` requests.
- `post_form` builds a form submission. The `Content-Type: application/x-www-form-urlencoded` header is what a browser sends with a form, and the `Form` extractor requires it. In the body, `+` stands for a space, just as browsers encode it.
- `body_text` reads the whole response body with Axum's `to_bytes` (with no size limit, which is fine in tests) and converts it to a `String`, so tests can search the HTML with `contains`.
- The tests check what a user would notice: the status code, the `location` header of a redirect, and text in the page. `StatusCode::SEE_OTHER` is `303`.
- Two tests also query the database after the request. `pool.clone()` gives the router its own handle, so the test can still use `pool` afterwards. The handler test for an invalid form checks that nothing was saved, not only that an error was shown.
- Handler tests have no return type; they use `.unwrap()`, which fails the test if something goes wrong.

---

## 5. Run and Test

Run the complete suite:

```bash
cargo test
```

After the compilation lines, the output is:

```text
running 16 tests
test db::tests::escapes_like_wildcards ... ok
test models::tests::empty_due_date_means_none ... ok
test models::tests::accepts_a_title_and_a_date ... ok
test models::tests::rejects_a_category_id_that_is_not_a_number ... ok
test models::tests::rejects_a_title_that_is_too_long ... ok
test models::tests::parses_the_category_id ... ok
test models::tests::rejects_a_blank_title ... ok
test models::tests::reports_both_errors_at_once ... ok
test routes::tests::creating_a_task_saves_it_and_redirects ... ok
test routes::tests::home_page_counts_tasks ... ok
test db::tests::missing_task_is_none ... ok
test db::tests::deleting_a_category_keeps_its_tasks ... ok
test routes::tests::missing_task_returns_404 ... ok
test db::tests::inserts_and_finds_a_task ... ok
test routes::tests::invalid_form_shows_errors ... ok
test db::tests::filters_and_paginates ... ok

test result: ok. 16 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.21s
```

Sixteen tests in three modules pass in a fraction of a second. The order changes from run to run, because tests run in parallel; with `#[sqlx::test]`, that is safe, since every database test has its own database.

### Step 1: Confirm That Test Databases Are Cleaned Up

```bash
mysql -u todo_user -p -e "SHOW DATABASES LIKE '\_sqlx\_test%';"
```

The command prints nothing: every test passed, so every test database was dropped. Your development database was never touched; check that your tasks are still there by opening `http://127.0.0.1:3000/tasks` after `cargo run`.

### Step 2: Commit

```bash
git add -A
git commit -m "lesson 18: database and handler tests"
```

From now on, run `cargo test` before every commit. A few seconds of testing catches the mistakes that are easy to make and hard to notice by clicking around.

---

## 6. What to Test, and How

Todo Web now has three kinds of tests. Each catches a different class of mistakes:

| Kind | Example | Needs | Catches |
| --- | --- | --- | --- |
| Unit tests (`#[test]`) | `validate_task`, `escape_like` | Nothing | Logic and rule mistakes |
| Database tests (`#[sqlx::test]`) | `filters_and_paginates` | MySQL | Wrong SQL, wrong columns, constraint behavior |
| Handler tests (`oneshot`) | `creating_a_task_saves_it_and_redirects` | MySQL | Routing, extractors, status codes, templates |

A few habits make tests valuable over time:

- **Test behavior, not implementation.** Check the status code, the redirect target, the visible text, and the stored data, not internal details. Then the tests keep passing when you refactor, as you did in Lesson 17.
- **Test the unhappy paths.** Missing tasks, invalid forms, and duplicates are where bugs hide. Three of the eight new tests are about failures.
- **Keep tests independent.** Never rely on data in the development database or on another test running first. `#[sqlx::test]` makes this automatic.
- **Write a test when you fix a bug.** The test proves the fix and makes sure the bug never returns, like the non-ASCII title test in Lesson 13.

How `#[sqlx::test]` works with MySQL, in short: it connects with `DATABASE_URL`, creates a bookkeeping database called `_sqlx_test` and one database per test named `_sqlx_test_` plus a random suffix, runs the migrations in it, and drops it when the test passes. When a test fails, its database is kept, so you can connect and look at the data that caused the failure. Section 7 shows this.

---

## 7. Fix the Errors in Your Code

**Error 1: Forgetting to import ServiceExt**

```rust
// Wrong: the use line is missing
    use sqlx::MySqlPool;
```

```rust
// Correct
    use sqlx::MySqlPool;
    use tower::ServiceExt;
```

`oneshot` is a trait method, and trait methods can only be called when the trait is in scope:

```text
error[E0599]: no method named `oneshot` found for struct `Router<S>` in the current scope
   --> src/routes.rs:54:28
    |
 54 |         let response = app.oneshot(request).await.unwrap();
    |                            ^^^^^^^
    |
   ::: /home/gun-gun-priatna/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/tower-0.5.3/src/util/mod.rs:89:8
    |
 89 |     fn oneshot(self, req: Request) -> Oneshot<Self, Request>
    |        ------- the method is available for `Router` here
    |
    = help: items from traits can only be used if the trait is in scope
```

The compiler even points to the trait method in Tower and states the rule: `items from traits can only be used if the trait is in scope`. Add the `use` line inside the test module.

**Error 2: Posting a form without the Content-Type header**

```rust
// Wrong
        Request::builder()
            .method("POST")
            .uri(uri)
            .body(Body::from(body.to_string()))
            .unwrap()
```

```rust
// Correct
        Request::builder()
            .method("POST")
            .uri(uri)
            .header(header::CONTENT_TYPE, "application/x-www-form-urlencoded")
            .body(Body::from(body.to_string()))
            .unwrap()
```

The code compiles, but both form tests fail:

```text
failures:

---- routes::tests::invalid_form_shows_errors stdout ----
created database _sqlx_test_G2ZkjBZUegAhh4C_uSfpyI2HJxmc99_1yGWL1OPVKJrkX95dUakH

thread 'routes::tests::invalid_form_shows_errors' (63256) panicked at src/routes.rs:94:9:
assertion `left == right` failed
  left: 415
 right: 422
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace

---- routes::tests::creating_a_task_saves_it_and_redirects stdout ----
created database _sqlx_test_GJI1WI3WjpqcWPRQrLEPs6AczH5BGrArx_HKrKwyHpo_CREu7DVm

thread 'routes::tests::creating_a_task_saves_it_and_redirects' (63252) panicked at src/routes.rs:78:9:
assertion `left == right` failed
  left: 415
 right: 303


failures:
    routes::tests::creating_a_task_saves_it_and_redirects
    routes::tests::invalid_form_shows_errors

test result: FAILED. 14 passed; 2 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.23s
```

`415` is `Unsupported Media Type`, the rejection from the `Form` extractor that you met in Lesson 5. The handler never ran. Browsers always send this header with forms; in tests, you have to add it yourself.

Look at the line `created database _sqlx_test_...` in each failure. SQLx prints the name of the test database when a test fails, and it does not drop that database, so you can inspect it. After the failed run above, the two databases were still there:

```text
Database (\_sqlx\_test%)
_sqlx_test_G2ZkjBZUegAhh4C_uSfpyI2HJxmc99_1yGWL1OPVKJrkX95dUakH
_sqlx_test_GJI1WI3WjpqcWPRQrLEPs6AczH5BGrArx_HKrKwyHpo_CREu7DVm
```

Once you have looked at them, drop each one with `DROP DATABASE`, putting the name in backticks:

```bash
mysql -u todo_user -p -e "DROP DATABASE \`_sqlx_test_G2ZkjBZUegAhh4C_uSfpyI2HJxmc99_1yGWL1OPVKJrkX95dUakH\`;"
```

The backslashes before the backticks stop the shell from treating them specially. `todo_user` may drop these databases thanks to the `_sqlx_test%` grant.

**Error 3: Using the router after oneshot**

```rust
// Wrong: two requests to the same app value
        let response = app.oneshot(request).await.unwrap();
        // ...
        let response = app.oneshot(again).await.unwrap();
```

```rust
// Correct: build a new router (or clone it) for each request
        let response = app.clone().oneshot(request).await.unwrap();
        // ...
        let response = app.oneshot(again).await.unwrap();
```

`oneshot` takes the service by value, so it can only be used once:

```text
error[E0382]: use of moved value: `app`
  --> src/routes.rs:72:24
   |
63 |         let app = app(AppState { pool });
   |             --- move occurs because `app` has type `Router`, which does not implement the `Copy` trait
...
66 |         let response = app.oneshot(request).await.unwrap();
   |                            ---------------- `app` moved due to this method call
...
72 |         let response = app.oneshot(again).await.unwrap();
   |                        ^^^ value used here after move
   |
note: `tower::ServiceExt::oneshot` takes ownership of the receiver `self`, which moves `app`
  --> /home/gun-gun-priatna/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/tower-0.5.3/src/util/mod.rs:89:16
   |
89 |     fn oneshot(self, req: Request) -> Oneshot<Self, Request>
   |                ^^^^
help: you can `clone` the value and consume it, but this might not be your desired behavior
   |
66 |         let response = app.clone().oneshot(request).await.unwrap();
   |                           ++++++++
```

The note explains it: `oneshot takes ownership of the receiver self`. A `Router` is cheap to clone, so call `app.clone().oneshot(...)` for every request except the last, or simply give each test one request, as the tests in this lesson do.

---

## 8. Exercises

**Exercise 1:** Write a handler test that toggles a task with `POST /tasks/1/toggle` and checks that the response is a redirect and that the task's `done` column is now `true`.

**Exercise 2:** Write a handler test that posts `name=work` to `/categories` when a category called `Work` already exists, and checks for status `422` and the duplicate message.

**Exercise 3:** Several tests need the same starting data. Use SQLx fixtures: create `src/fixtures/tasks.sql` with two categories and three tasks, and load it with `#[sqlx::test(fixtures("tasks"))]` in the tests from Exercises 1 and 2. Then add a third test that checks the task list filtered by status and category.

---

## 9. Solutions

All three solutions use a fixture, so start with Exercise 3's file.

**Solution for Exercise 3 (the fixture):**

Create the folder `src/fixtures` and the file `src/fixtures/tasks.sql`:

```sql
INSERT INTO categories (id, name) VALUES (1, 'Work'), (2, 'Home');
INSERT INTO tasks (id, title, done, category_id) VALUES
    (1, 'Reply to client emails', FALSE, 1),
    (2, 'Clean the kitchen', FALSE, 2),
    (3, 'Buy groceries', TRUE, 2);
```

A fixture is a SQL file that `#[sqlx::test]` runs after the migrations and before the test. `fixtures("tasks")` looks for `fixtures/tasks.sql` next to the source file that contains the test, which is why the folder lives in `src/`. The IDs are written explicitly, so tests can refer to them reliably.

**Solution for Exercise 1, Exercise 2, and the third test:**

Add these tests to the `tests` module in `src/routes.rs`:

```rust
    #[sqlx::test(fixtures("tasks"))]
    async fn toggling_a_task_marks_it_done(pool: MySqlPool) {
        let app = app(AppState { pool: pool.clone() });

        let response = app.oneshot(post_form("/tasks/1/toggle", "")).await.unwrap();

        assert_eq!(response.status(), StatusCode::SEE_OTHER);
        let done: bool = sqlx::query_scalar("SELECT done FROM tasks WHERE id = 1")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert!(done);
    }

    #[sqlx::test(fixtures("tasks"))]
    async fn duplicate_category_is_rejected(pool: MySqlPool) {
        let app = app(AppState { pool });

        let response = app.oneshot(post_form("/categories", "name=work")).await.unwrap();

        assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
        assert!(body_text(response).await.contains("A category with this name already exists."));
    }

    #[sqlx::test(fixtures("tasks"))]
    async fn list_filters_by_category(pool: MySqlPool) {
        let app = app(AppState { pool });

        let request = Request::builder()
            .uri("/tasks?status=pending&category=2")
            .body(Body::empty())
            .unwrap();
        let response = app.oneshot(request).await.unwrap();

        let html = body_text(response).await;
        assert!(html.contains("1 tasks found."));
        assert!(html.contains("Clean the kitchen"));
        assert!(!html.contains("Buy groceries"));
    }
```

`post_form` with an empty body sends a valid form request with no fields, which the toggle route accepts. `query_scalar` decodes `done` directly into a `bool`, as in Lesson 9. The duplicate test sends `work` in lowercase to show that the case-insensitive `UNIQUE` constraint, not the Rust code, decides what counts as a duplicate. The filter test checks both sides: the unfinished Home task is there, and the finished one is not. If you changed the counter in the Lesson 16 exercises, adjust the expected text.

```bash
cargo test routes::
```

Output:

```text
running 7 tests
test routes::tests::toggling_a_task_marks_it_done ... ok
test routes::tests::missing_task_returns_404 ... ok
test routes::tests::list_filters_by_category ... ok
test routes::tests::invalid_form_shows_errors ... ok
test routes::tests::creating_a_task_saves_it_and_redirects ... ok
test routes::tests::home_page_counts_tasks ... ok
test routes::tests::duplicate_category_is_rejected ... ok

test result: ok. 7 passed; 0 failed; 0 ignored; 0 measured; 12 filtered out; finished in 0.19s
```

All seven handler tests pass, and the whole suite now has nineteen tests.

---

## Next Up - Lesson 19

In this lesson, you added database tests with `#[sqlx::test]`, which gives every test a fresh database with all migrations applied and keeps it for inspection when the test fails, and handler tests that send requests to `routes::app` with `oneshot` and check status codes, redirects, HTML, and the stored data. Sixteen tests now guard Todo Web.

Todo Web is complete in features, tested, and well organized. In the final lesson, you will make it ready to run for real: log every request with `tracing` and `tower-http`, replace the `eprintln!` calls with structured log messages, serve a stylesheet as a static file, build an optimized release binary, and review everything you built in this course.
