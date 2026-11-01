## 1. Before You Begin

In Lesson 10, Todo Web started reading real tasks from MySQL. The "New task" page, however, is still a dead end: since Lesson 5, `create_task` only prints the submitted title in the terminal and forgets it. Adding tasks still requires the `mysql` client, which is not how anyone wants to use a to-do app.

This lesson closes the loop. You will add a due date field to the form, turn the submitted text into a `NaiveDate`, insert the task with the `insert_task` query from the Lesson 9 playground, and send the browser to the new task's page. That last step uses the Post/Redirect/Get pattern from Lesson 5, now with a real ID in the URL.

### What You'll Build

A working "New task" form with labeled title and due date fields. Submitting it inserts a row into the `tasks` table and redirects to `/tasks/{id}` for the task that was just created. An empty title sends the user back to the form, and a missing due date is stored as `NULL`.

### What You'll Learn

- ✅ How to receive several form fields, including an empty optional field
- ✅ How to parse a date string from an HTML date input with `NaiveDate::parse_from_str`
- ✅ How to insert a row from a handler and get its new ID with `last_insert_id`
- ✅ How to build a redirect URL that contains the new ID
- ✅ How `trim` and a simple guard protect against blank titles
- ✅ Why the redirect matters for refresh and the back button

### What You'll Need

- The `todo-web` project from Lesson 10
- A browser that supports `<input type="date">` (every current browser does)

---

## 2. Upgrade the New Task Form

The form needs a due date field, and labels make it easier to use. Because the form now sends two fields, the `NewTask` struct needs two fields as well.

### Step 1: Update the Template

Replace `templates/tasks/new.html` with:

```html
{% extends "base.html" %}

{% block title %}New Task - Todo Web{% endblock %}

{% block content %}
<h1>New Task</h1>
<form method="post" action="/tasks">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" placeholder="What needs to be done?" required>
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date">
  </p>
  <button type="submit">Add task</button>
</form>
{% endblock %}
```

Here is what changed:

- Each input has a `<label>` whose `for` attribute matches the input's `id`. Clicking the label focuses the field, and screen readers announce the label when the field is focused.
- `required` on the title makes the browser refuse to submit the form while the field is empty. This is a convenience for the user, not a security measure: anyone can send a request without a browser, as you do with `curl`. The server must check the data itself, which the handler does in Section 3.
- `type="date"` shows a date picker. Whatever date format the user sees in their language, the browser always sends the value as `YYYY-MM-DD`, for example `2026-11-12`. An empty date field is sent as an empty string.

### Step 2: Add the Field to NewTask

Replace the `NewTask` struct in `src/main.rs` with:

```rust
#[derive(Deserialize)]
struct NewTask {
    title: String,
    due_date: String,
}
```

`due_date` is a `String`, not an `Option<NaiveDate>`. The browser always sends the field, even when it is empty, and an empty string cannot be parsed as a date by serde. It is simpler to receive the raw text and convert it in the handler, where you control what happens with empty or invalid values.

---

## 3. Save the Task and Redirect

Saving needs two pieces: a query function that inserts a row, and a handler that prepares the values and calls it.

### Step 1: Add the insert_task Query

Add this function below `count_tasks`:

```rust
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
```

This is exactly the function from the Lesson 9 playground. The two placeholders are filled by the two `.bind()` calls in order, `None` is stored as `NULL`, and `last_insert_id()` returns the ID MySQL assigned to the new row. `done` and `created_at` get their default values from the table definition.

### Step 2: Rewrite create_task

Replace the `create_task` handler with:

```rust
async fn create_task(
    State(pool): State<MySqlPool>,
    Form(form): Form<NewTask>,
) -> Result<Redirect, (StatusCode, String)> {
    let title = form.title.trim();
    if title.is_empty() {
        return Ok(Redirect::to("/tasks/new"));
    }
    let due_date = NaiveDate::parse_from_str(&form.due_date, "%Y-%m-%d").ok();

    let id = insert_task(&pool, title, due_date)
        .await
        .map_err(internal_error)?;
    Ok(Redirect::to(&format!("/tasks/{id}")))
}
```

Line by line:

- The handler now takes `State(pool)` as well as the form. `Form` reads the body, so it stays the last parameter, as you learned in Lesson 5.
- `form.title.trim()` removes spaces at the start and end, so `"  Read the docs  "` is saved as `"Read the docs"`. `trim` returns a `&str` that borrows from `form.title`, so no new string is allocated.
- If nothing is left after trimming, the handler redirects back to the empty form instead of saving a blank task. This guard catches requests that bypass the browser's `required` check. It does not tell the user what went wrong yet; Lesson 13 adds proper error messages.
- `NaiveDate::parse_from_str(&form.due_date, "%Y-%m-%d")` parses the text using the same format codes you used for formatting in Lesson 10. It returns a `Result`: `Ok(date)` for valid input like `2026-11-12`, and an error for anything else, including the empty string. `.ok()` turns that `Result` into an `Option`, so an empty field becomes `None`, which is stored as `NULL`.
- `insert_task(...).await.map_err(internal_error)?` saves the task and turns a database failure into the `500` response from Lesson 10.
- `Redirect::to(&format!("/tasks/{id}"))` sends the browser to the new task's detail page. `Redirect::to` takes a `&str`, so the `String` from `format!` is borrowed with `&`.

An invalid date, such as text typed into the field by a non-browser client, is silently treated as "no due date." That is acceptable for now, but it is not friendly; in Lesson 13, invalid dates will produce an error message next to the field.

---

## 4. Run and Test

Start the server:

```bash
cargo run
```

Output:

```text
Connected to MySQL
Migrations are up to date
Todo Web running on http://127.0.0.1:3000
```

### Step 1: Create a Task with curl

Send the two fields exactly as the browser would:

```bash
curl -i -d "title=Plan the demo&due_date=2026-11-12" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks/7
content-length: 0
date: Sun, 01 Nov 2026 17:04:55 GMT
```

The `location` header now points to the new task's own page. The ID depends on how many rows your table has had; MySQL never reuses IDs, so yours may be different.

### Step 2: Follow the Redirect

Now create a task with extra spaces around the title and an empty due date, and let `curl` follow the redirect:

```bash
curl -s -L -d "title=  Read the Axum docs  &due_date=" http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Read the Axum docs</h1>
<p>Status: not done</p>
<p>Due date: none</p>
<p>Created: 2026-11-01 17:04</p>
<p><a href="/tasks">Back to all tasks</a></p>

  </main>
```

The spaces were trimmed, the empty date became "none," and the page shown is the detail page of the task that was just inserted.

### Step 3: Try a Blank Title and an Invalid Date

```bash
curl -i -d "title=   &due_date=" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks/new
content-length: 0
date: Sun, 01 Nov 2026 17:06:51 GMT
```

Nothing was saved; the guard sent the user back to the form. Now send a date the browser would never produce:

```bash
curl -s -o /dev/null -w "%{redirect_url}\n" -d "title=Call the bank&due_date=next friday" http://127.0.0.1:3000/tasks
```

Output:

```text
http://127.0.0.1:3000/tasks/9
```

`-w "%{redirect_url}\n"` prints only the redirect target. The task was saved, but `next friday` could not be parsed, so it has no due date. Keep this case in mind for Lesson 13.

### Step 4: Check the Table

```bash
mysql -u todo_user -p db_rust_todo -t -e "SELECT id, title, done, due_date FROM tasks ORDER BY id;"
```

Output:

```text
+----+------------------------------+------+------------+
| id | title                        | done | due_date   |
+----+------------------------------+------+------------+
|  1 | Learn Rust                   |    1 | NULL       |
|  2 | Build a web app              |    0 | 2026-11-30 |
|  4 | Write the first handler test |    0 | NULL       |
|  7 | Plan the demo                |    0 | 2026-11-12 |
|  8 | Read the Axum docs           |    0 | NULL       |
|  9 | Call the bank                |    0 | NULL       |
+----+------------------------------+------+------------+
```

The three new tasks are in the database, with `NULL` where no valid date was given. The gaps in the IDs come from rows deleted earlier.

### Step 5: Use the Form in the Browser

Open `http://127.0.0.1:3000/tasks/new`. Try to submit with an empty title: the browser stops you, because of `required`. Enter a title, pick a date, and press **Add task**. You land on the new task's page. Now press the browser's refresh button: the detail page simply reloads, and no duplicate task is created, because the last request was a `GET`, not the `POST`. Press the back button twice to return to the form; it is empty again and ready for the next task. Go to `/tasks` to see all your tasks. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 11: create tasks"
```

---

## 5. What Happens When a Form Is Submitted

Creating a task involves two requests, and it helps to see them side by side:

```text
1. POST /tasks                      body: title=Plan+the+demo&due_date=2026-11-12
      create_task: trim, parse date, INSERT ... -> last_insert_id = 7
      response: 303 See Other, location: /tasks/7

2. GET /tasks/7                     (sent automatically by the browser)
      show_task: SELECT ... WHERE id = 7
      response: 200 OK, the task's page
```

A few points are worth remembering:

- **The browser follows `303` with a `GET`.** That is what makes refresh safe: refreshing repeats request 2, not request 1. Status `303 See Other` exists exactly for this purpose.
- **The ID comes from the database.** Your code never decides IDs; it asks MySQL for `last_insert_id()` after the insert. Two people creating tasks at the same moment each get their own correct ID, because `last_insert_id()` is tracked per connection.
- **Browser checks are hints; server checks are rules.** `required` and `type="date"` improve the experience, but the handler must never trust them. The `trim` and empty check, and the careful date parsing, run no matter how the request was sent.
- **Form values are always text.** Numbers, dates, and checkboxes all arrive as strings. Converting them into Rust types, and deciding what to do when that fails, is part of every form handler.

---

## 6. Fix the Errors in Your Code

**Error 1: Passing a String to Redirect::to**

```rust
// Wrong
    Ok(Redirect::to(format!("/tasks/{id}")))
```

```rust
// Correct
    Ok(Redirect::to(&format!("/tasks/{id}")))
```

`Redirect::to` takes a `&str`, and `format!` produces an owned `String`:

```text
error[E0308]: mismatched types
   --> src/main.rs:180:21
    |
170 | ) -> Result<Redirect, (StatusCode, String)> {
    |      -------------------------------------- expected `&str` because of return type
...
180 |     Ok(Redirect::to(format!("/tasks/{id}")))
    |                     ^^^^^^^^^^^^^^^^^^^^^^ expected `&str`, found `String`
```

The important part is the last line: `expected &str, found String`. Borrowing the string with `&` fixes it. The temporary `String` lives until the end of the statement, which is long enough, because `Redirect::to` copies the text into the response header.

**Error 2: Fewer bind calls than placeholders**

```rust
// Wrong: two placeholders, one bind
    let result = sqlx::query("INSERT INTO tasks (title, due_date) VALUES (?, ?)")
        .bind(title)
        .execute(pool)
        .await?;
```

```rust
// Correct
    let result = sqlx::query("INSERT INTO tasks (title, due_date) VALUES (?, ?)")
        .bind(title)
        .bind(due_date)
        .execute(pool)
        .await?;
```

The compiler only warns that `due_date` is unused. At runtime, MySQL rejects the statement because it is missing a value. The user sees the generic `500` message, and the server terminal shows the real cause:

```text
database error: encountered unexpected or invalid data: prepared statement expected 2 parameters but 1 parameters were provided (sqlx_mysql::connection::executor:131)
```

Count the `?` marks and the `.bind()` calls whenever you change a query; they must match one to one, in the same order. The `unused variable` warning is often the first clue.

**Error 3: A form that does not send every field**

If you add a second form that posts to `/tasks` but has only a title input, for example a quick-add box on the task list, the request is rejected:

```bash
curl -i -d "title=Quick task" http://127.0.0.1:3000/tasks
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
content-type: text/plain; charset=utf-8
content-length: 57
date: Sun, 01 Nov 2026 17:05:15 GMT

Failed to deserialize form body: missing field `due_date`
```

```rust
// Wrong for forms that may leave out due_date
struct NewTask {
    title: String,
    due_date: String,
}
```

```rust
// Correct: use an empty string when the field is missing
struct NewTask {
    title: String,
    #[serde(default)]
    due_date: String,
}
```

A `String` field is required. `#[serde(default)]` tells serde to use the type's default value, an empty `String`, when the field is absent. The handler already treats an empty date as "no due date," so nothing else changes. Exercise 2 uses this.

---

## 7. Exercises

**Exercise 1:** Add a second submit button to the new task form, labeled "Add and create another." When it is used, save the task and redirect back to `/tasks/new` instead of the task's page. Hint: a `<button>` with `name="next" value="new"` sends `next=new` only when that button is clicked, so `NewTask` needs a `next: Option<String>` field.

**Exercise 2:** Add a quick-add form at the top of the task list page with only a title input and an "Add" button, posting to `/tasks`. Make it work without changing the handler's logic.

**Exercise 3:** After creating a task, show the message `Task created.` at the top of its detail page, but only right after creation. Redirect to `/tasks/{id}?created=true`, and read the flag in `show_task` with a `Query` extractor and a new `ShowOptions` struct.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the button to `templates/tasks/new.html`, after the existing one:

```html
  <button type="submit">Add task</button>
  <button type="submit" name="next" value="new">Add and create another</button>
```

Add the field to `NewTask`:

```rust
#[derive(Deserialize)]
struct NewTask {
    title: String,
    due_date: String,
    next: Option<String>,
}
```

And check it at the end of `create_task`, before the final redirect:

```rust
    if form.next.as_deref() == Some("new") {
        return Ok(Redirect::to("/tasks/new"));
    }
    Ok(Redirect::to(&format!("/tasks/{id}")))
```

Only the button that was clicked sends its `name` and `value`, so `next` is `Some("new")` for the second button and `None` for the first. `as_deref()` turns an `Option<String>` into an `Option<&str>`, which can be compared with `Some("new")`.

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "title=Buy coffee&due_date=&next=new" http://127.0.0.1:3000/tasks
```

Output:

```text
303 http://127.0.0.1:3000/tasks/new
```

**Solution for Exercise 2:**

Add `#[serde(default)]` to the `due_date` field, as shown in Error 3 of Section 6. Then add the form to `templates/tasks/list.html`, right below `<h1>Tasks</h1>`:

```html
<form method="post" action="/tasks">
  <input name="title" placeholder="Quick add a task" required>
  <button type="submit">Add</button>
</form>
```

The quick-add form sends only `title`. With `#[serde(default)]`, the missing `due_date` becomes an empty string, which the handler already turns into `None`. Both forms now share one handler.

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "title=Quick task" http://127.0.0.1:3000/tasks
```

Output:

```text
303 http://127.0.0.1:3000/tasks/11
```

If you also solved Exercise 3, the URL ends with `?created=true`.

**Solution for Exercise 3:**

Add the options struct below `NewTask`, and a field to the template struct:

```rust
#[derive(Deserialize)]
struct ShowOptions {
    created: Option<bool>,
}
```

```rust
#[derive(Template)]
#[template(path = "tasks/show.html")]
struct TaskShowTemplate {
    task: Task,
    created: bool,
}
```

Read the option in `show_task`:

```rust
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Query(options): Query<ShowOptions>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    let created = options.created.unwrap_or(false);
    match task {
        Some(task) => Ok(render(TaskShowTemplate { task, created })),
        None => Ok(not_found_page("That task does not exist.")),
    }
}
```

Change the last line of `create_task`:

```rust
    Ok(Redirect::to(&format!("/tasks/{id}?created=true")))
```

And show the message in `templates/tasks/show.html`, as the first line inside `{% block content %}`:

```html
{% if created %}<p><strong>Task created.</strong></p>{% endif %}
```

serde parses `true` and `false` from the query string into a `bool`. Because the field is an `Option`, a normal visit to `/tasks/7` without the parameter still works, and `unwrap_or(false)` hides the message. If the user refreshes, the message appears again, since the URL still contains the flag. Messages that appear exactly once, often called flash messages, need a session or a cookie to remember that they were already shown, which is beyond this course.

```bash
curl -s -L -d "title=Water the plants&due_date=" http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<p><strong>Task created.</strong></p>
<h1>Water the plants</h1>
<p>Status: not done</p>
<p>Due date: none</p>
<p>Created: 2026-11-01 17:05</p>
<p><a href="/tasks">Back to all tasks</a></p>

  </main>
```

---

## Next Up - Lesson 12

In this lesson, you made the "New task" form save real tasks. The handler trims the title, rejects blank ones, parses the optional due date with `NaiveDate::parse_from_str`, inserts the row, and redirects to the new task's page using the ID from `last_insert_id()`.

Tasks can be created and read, but not changed. In Lesson 12, you will complete CRUD: an edit form that is pre-filled with a task's current title and due date, a button that marks a task as done or not done, and a delete button. Each one is a `POST` form, and each one checks how many rows its query affected, so a task that no longer exists gets a 404 instead of a silent success.
