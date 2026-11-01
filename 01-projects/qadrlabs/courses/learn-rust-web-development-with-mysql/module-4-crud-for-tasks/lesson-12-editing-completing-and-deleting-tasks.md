## 1. Before You Begin

Todo Web can now create tasks (Lesson 11) and read them (Lesson 10). A to-do list is only useful if tasks can also change: a title needs fixing, a deadline moves, a task gets done, an old task gets removed. This lesson adds the last two letters of CRUD, update and delete, in three features: an edit form, a done toggle, and a delete button.

All three change data, so all three use `POST` forms, never plain links. And all three face the same question: what if the task does not exist, for example because it was deleted in another browser tab a minute ago? The answer comes from `rows_affected()`, which you met in the Lesson 9 playground. When an `UPDATE` or `DELETE` touches no rows, the handler returns the 404 page instead of pretending everything worked.

### What You'll Build

An edit page at `/tasks/{id}/edit` with the current title and due date already filled in, a toggle button on the list and detail pages that marks a task as done or not done, and a delete button on the detail page. Each action redirects after success and shows the 404 page when the task is missing.

### What You'll Learn

- ✅ How to pre-fill an edit form with a task's current values
- ✅ How to combine `State`, `Path`, and `Form` extractors in one handler
- ✅ How to update a row with several bound parameters in the right order
- ✅ How to flip a boolean in SQL with `SET done = NOT done`
- ✅ How to use `rows_affected()` to detect missing rows
- ✅ Why actions that change data must use `POST`, not links

### What You'll Need

- The `todo-web` project from Lesson 11
- A few tasks in the database; create some with the form if your table is nearly empty

---

## 2. Add the Update and Delete Queries

As before, the SQL goes into small query functions first, and the handlers call them afterwards.

### Step 1: Rename the Form Struct

The edit form sends the same two fields as the new task form, so one struct can serve both. Rename `NewTask` to `TaskForm`:

```rust
#[derive(Deserialize)]
struct TaskForm {
    title: String,
    due_date: String,
}
```

Remember to change `Form<NewTask>` to `Form<TaskForm>` in `create_task` as well. The compiler will point at it if you forget.

### Step 2: Add the Query Functions

Add these three functions below `insert_task`:

```rust
async fn update_task(
    pool: &MySqlPool,
    id: u64,
    title: &str,
    due_date: Option<NaiveDate>,
) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE tasks SET title = ?, due_date = ? WHERE id = ?")
        .bind(title)
        .bind(due_date)
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

async fn toggle_task(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE tasks SET done = NOT done WHERE id = ?")
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

Here is what each one does:

- `update_task` has three placeholders, and the three `.bind()` calls fill them in order: title, due date, then the ID in the `WHERE` clause. The order of the binds must follow the order of the `?` marks in the SQL, not the order of the function's parameters.
- `toggle_task` flips the flag inside MySQL with `SET done = NOT done`. The handler does not need to read the task first to know its current state, and two quick clicks always toggle twice, because each `UPDATE` sees the latest value.
- `delete_task` is the function from the playground.
- All three return `true` when a row matched. SQLx's MySQL driver asks the server to count matched rows, not only changed rows, so saving a task without changing anything still returns `true`. Only a missing ID returns `false`.

### Step 3: Share the Date Parsing

Creating and editing both turn the date text into an `Option<NaiveDate>`. Add a small helper below `delete_task`:

```rust
fn parse_due_date(text: &str) -> Option<NaiveDate> {
    NaiveDate::parse_from_str(text, "%Y-%m-%d").ok()
}
```

Then use it in `create_task`, replacing the `NaiveDate::parse_from_str(...)` line:

```rust
    let due_date = parse_due_date(&form.due_date);
```

---

## 3. Build the Edit Page

Editing takes two requests: `GET /tasks/{id}/edit` shows the form with the current values, and `POST /tasks/{id}/edit` saves it. One route can handle both methods, just like `/tasks`.

### Step 1: Create the Edit Template

Create `templates/tasks/edit.html`:

```html
{% extends "base.html" %}

{% block title %}Edit {{ task.title }} - Todo Web{% endblock %}

{% block content %}
<h1>Edit Task</h1>
<form method="post" action="/tasks/{{ task.id }}/edit">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="{{ task.title }}" required>
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date"
           value="{% if let Some(date) = task.due_date %}{{ date }}{% endif %}">
  </p>
  <button type="submit">Save changes</button>
  <a href="/tasks/{{ task.id }}">Cancel</a>
</form>
{% endblock %}
```

The form looks like the new task form with two differences. The `action` contains the task's ID, so the browser posts to the right URL. The inputs have `value` attributes holding the current data: the title, and the due date in `YYYY-MM-DD` format, which is exactly what a `NaiveDate` displays as and what a date input expects. When there is no due date, the `if let` prints nothing and the date field starts empty. Askama escapes the title, so a title containing `"` cannot break out of the attribute.

### Step 2: Add the Template Struct

Add this struct next to the other template structs:

```rust
#[derive(Template)]
#[template(path = "tasks/edit.html")]
struct EditTaskTemplate {
    task: Task,
}
```

### Step 3: Write the Two Edit Handlers

Add these handlers below `create_task`:

```rust
async fn edit_task_form(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    match task {
        Some(task) => Ok(render(EditTaskTemplate { task })),
        None => Ok(not_found_page("That task does not exist.")),
    }
}

async fn save_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<TaskForm>,
) -> Result<Response, (StatusCode, String)> {
    let title = form.title.trim();
    if title.is_empty() {
        return Ok(Redirect::to(&format!("/tasks/{id}/edit")).into_response());
    }
    let due_date = parse_due_date(&form.due_date);

    let updated = update_task(&pool, id, title, due_date)
        .await
        .map_err(internal_error)?;
    if !updated {
        return Ok(not_found_page("That task does not exist."));
    }
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}
```

Here is how they work:

- `edit_task_form` is almost the same as `show_task`: find the task, render a template, or show the 404 page.
- `save_task` uses three extractors: `State` for the pool, `Path` for the ID in the URL, and `Form` for the submitted fields, with `Form` last because it reads the body.
- The title check and date parsing are the same as in `create_task`. A blank title sends the user back to the edit form.
- `update_task` returns `false` when no row has that ID. Then the handler shows the 404 page instead of redirecting to a task page that would not exist.
- The handler returns two different kinds of responses, a redirect or a page, so it returns `Response` and converts the redirects with `.into_response()`, the technique from Lesson 5.

---

## 4. Add the Toggle and Delete Actions

The toggle and delete actions need no form fields at all: the ID in the URL says everything. They still use `POST`, for reasons explained in Section 6.

### Step 1: Write the Handlers

Add these handlers below `save_task`:

```rust
async fn toggle_done(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let toggled = toggle_task(&pool, id).await.map_err(internal_error)?;
    if !toggled {
        return Ok(not_found_page("That task does not exist."));
    }
    Ok(Redirect::to("/tasks").into_response())
}

async fn remove_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let deleted = delete_task(&pool, id).await.map_err(internal_error)?;
    if !deleted {
        return Ok(not_found_page("That task does not exist."));
    }
    Ok(Redirect::to("/tasks").into_response())
}
```

Both follow the same pattern: run the query, show the 404 page if nothing matched, and otherwise redirect to the task list. The handler names (`toggle_done` and `remove_task`) differ from the query names (`toggle_task` and `delete_task`), because two functions in the same module cannot share a name.

### Step 2: Register the Routes

Import `post` next to `get` at the top of the file:

```rust
    routing::{get, post},
```

Then add three routes to the router in `main`, below the `/tasks/{id}` route:

```rust
    let app = Router::new()
        .route("/", get(home))
        .route("/health", get(health))
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/new", get(new_task_form))
        .route("/tasks/{id}", get(show_task))
        .route("/tasks/{id}/edit", get(edit_task_form).post(save_task))
        .route("/tasks/{id}/toggle", post(toggle_done))
        .route("/tasks/{id}/delete", post(remove_task))
        .fallback(not_found)
        .with_state(pool);
```

`post(toggle_done)` attaches a handler to the `POST` method only, just as `get` does for `GET`. The edit route handles both methods with `get(...).post(...)`.

### Step 3: Add Buttons to the Pages

Replace `templates/tasks/show.html` with:

```html
{% extends "base.html" %}

{% block title %}{{ task.title }} - Todo Web{% endblock %}

{% block content %}
<h1>{{ task.title }}</h1>
<p>Status: {% if task.done %}done{% else %}not done{% endif %}</p>
<p>Due date: {% if let Some(date) = task.due_date %}{{ date.format("%d %B %Y") }}{% else %}none{% endif %}</p>
<p>Created: {{ task.created_at.format("%Y-%m-%d %H:%M") }}</p>

<p><a href="/tasks/{{ task.id }}/edit">Edit</a></p>

<form method="post" action="/tasks/{{ task.id }}/toggle">
  <button type="submit">{% if task.done %}Mark as not done{% else %}Mark as done{% endif %}</button>
</form>

<form method="post" action="/tasks/{{ task.id }}/delete">
  <button type="submit">Delete task</button>
</form>

<p><a href="/tasks">Back to all tasks</a></p>
{% endblock %}
```

The edit page is a link, because opening a form changes nothing. The toggle and delete actions are small forms with a single button each, and the toggle button's label depends on the current state.

In `templates/tasks/list.html`, replace the `<li>` inside the `for` loop so the checkbox marker becomes a toggle button:

```html
      <li>
        <form method="post" action="/tasks/{{ task.id }}/toggle" style="display: inline">
          <button type="submit">{% if task.done %}[x]{% else %}[ ]{% endif %}</button>
        </form>
        <a href="/tasks/{{ task.id }}">{{ task.title }}</a>
        {% if let Some(date) = task.due_date %}(due {{ date }}){% endif %}
      </li>
```

`style="display: inline"` keeps the form on the same line as the title; a form is a block element by default. Lesson 19 moves styling into a CSS file.

---

## 5. Run and Test

Start the server with `cargo run`. The examples below use task 7 (`Plan the demo` from Lesson 11) and task 9 (`Call the bank`); use IDs from your own task list.

### Step 1: Open the Edit Form

```bash
curl -s http://127.0.0.1:3000/tasks/7/edit | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Edit Task</h1>
<form method="post" action="/tasks/7/edit">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="Plan the demo" required>
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date"
           value="2026-11-12">
  </p>
  <button type="submit">Save changes</button>
  <a href="/tasks/7">Cancel</a>
</form>

  </main>
```

Both fields are filled with the stored values.

### Step 2: Save Changes

Change the title and the due date:

```bash
curl -i -d "title=Plan the team demo&due_date=2026-11-20" http://127.0.0.1:3000/tasks/7/edit
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks/7
content-length: 0
date: Sun, 01 Nov 2026 17:07:46 GMT
```

```bash
curl -s http://127.0.0.1:3000/tasks/7 | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Plan the team demo</h1>
<p>Status: not done</p>
<p>Due date: 20 November 2026</p>
<p>Created: 2026-11-01 17:04</p>

<p><a href="/tasks/7/edit">Edit</a></p>

<form method="post" action="/tasks/7/toggle">
  <button type="submit">Mark as done</button>
</form>

<form method="post" action="/tasks/7/delete">
  <button type="submit">Delete task</button>
</form>

<p><a href="/tasks">Back to all tasks</a></p>

  </main>
```

The title and due date changed; the creation time did not.

### Step 3: Toggle a Task

```bash
curl -i -X POST http://127.0.0.1:3000/tasks/7/toggle
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks
content-length: 0
date: Sun, 01 Nov 2026 17:07:46 GMT
```

Check the database:

```bash
mysql -u todo_user -p db_rust_todo -e "SELECT id, title, done, due_date FROM tasks WHERE id = 7;"
```

Output:

```text
id	title	done	due_date
7	Plan the team demo	1	2026-11-20
```

`done` is now `1`. Sending the same request again would set it back to `0`.

### Step 4: Delete a Task, Then Try Again

```bash
curl -i -X POST http://127.0.0.1:3000/tasks/9/delete
```

Output:

```text
HTTP/1.1 303 See Other
location: /tasks
content-length: 0
date: Sun, 01 Nov 2026 17:07:46 GMT
```

Task 9 is gone. Now send the same delete again, and also try the other actions on the missing task. `-w "%{http_code}\n"` prints only the status code:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:3000/tasks/9/delete
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:3000/tasks/9/toggle
curl -s -o /dev/null -w "%{http_code}\n" -d "title=x&due_date=" http://127.0.0.1:3000/tasks/9/edit
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/tasks/9/edit
```

Output:

```text
404
404
404
404
```

Every action on the missing task returns `404`, thanks to the `rows_affected()` checks (and `fetch_optional` for the edit form).

### Step 5: Click Through in the Browser

Open `http://127.0.0.1:3000/tasks`. Click a `[ ]` button: the page reloads with the task marked `[x]`, and the finished task moves down the list because of `ORDER BY done, id`. Open a task, click **Edit**, change the title, and save. Clear the date field and save again to remove a due date. Finally, delete a task from its detail page. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 12: edit, toggle, delete"
```

---

## 6. CRUD, Routes, and Safe Methods

Todo Web now implements all four CRUD operations. Here is the complete map of task routes:

| Operation | Method and path | Handler | SQL |
| --- | --- | --- | --- |
| List | `GET /tasks` | `list_tasks` | `SELECT ... WHERE title LIKE ...` |
| Show | `GET /tasks/{id}` | `show_task` | `SELECT ... WHERE id = ?` |
| New form | `GET /tasks/new` | `new_task_form` | none |
| Create | `POST /tasks` | `create_task` | `INSERT` |
| Edit form | `GET /tasks/{id}/edit` | `edit_task_form` | `SELECT ... WHERE id = ?` |
| Update | `POST /tasks/{id}/edit` | `save_task` | `UPDATE ... SET title, due_date` |
| Toggle | `POST /tasks/{id}/toggle` | `toggle_done` | `UPDATE ... SET done = NOT done` |
| Delete | `POST /tasks/{id}/delete` | `remove_task` | `DELETE` |

The most important rule behind this table: **`GET` requests must never change data.** Browsers, search engines, and link previewers follow links freely. A browser may load a link in the background to make the page appear faster, and a chat app may fetch a pasted link to show a preview. If `GET /tasks/9/delete` deleted a task, any of them could delete it without anyone clicking. `POST` requests are only sent when someone submits a form, so every action that changes data uses a form with `method="post"`.

HTML forms only support `GET` and `POST`. JSON APIs often use the methods `PUT`, `PATCH`, and `DELETE` for updates and deletes, but a server-rendered app without JavaScript expresses those operations as `POST` requests to descriptive paths such as `/edit`, `/toggle`, and `/delete`.

---

## 7. Fix the Errors in Your Code

**Error 1: Binding values in the wrong order**

```rust
// Wrong: the ID is bound first, but the first ? is the title
    let result = sqlx::query("UPDATE tasks SET title = ?, due_date = ? WHERE id = ?")
        .bind(id)
        .bind(title)
        .bind(due_date)
```

```rust
// Correct: follow the order of the ? marks in the SQL
    let result = sqlx::query("UPDATE tasks SET title = ?, due_date = ? WHERE id = ?")
        .bind(title)
        .bind(due_date)
        .bind(id)
```

The function's parameters are `(pool, id, title, due_date)`, so it is tempting to bind in that order. But placeholders are positional, and each value lands in the wrong place: the ID becomes the title, the title is compared as a date, and the date is used as the ID. Saving the edit form fails with a `500`, and the server terminal shows MySQL's complaint:

```text
database error: error returned from database: 1292 (22007): Incorrect datetime value: '1' for column `db_rust_todo`.`tasks`.`id` at row 1
```

The message is confusing because MySQL tried to make sense of values that ended up in the wrong places. When an `UPDATE` produces strange type errors, compare the binds with the `?` marks first. If the types had happened to match, the mistake would be worse: the query could succeed and change the wrong data.

**Error 2: Using a link for an action that changes data**

```html
<!-- Wrong -->
<a href="/tasks/{{ task.id }}/delete">Delete task</a>
```

```html
<!-- Correct -->
<form method="post" action="/tasks/{{ task.id }}/delete">
  <button type="submit">Delete task</button>
</form>
```

A link sends a `GET` request, and the route only accepts `POST`:

```bash
curl -i http://127.0.0.1:3000/tasks/7/delete
```

Output:

```text
HTTP/1.1 405 Method Not Allowed
allow: POST
content-length: 0
date: Sun, 01 Nov 2026 17:07:46 GMT
```

The `405` protects the data: even a mistaken link cannot delete anything. The fix belongs in the template, not in the router. Do not "solve" this by adding `get(remove_task)` to the route, for the reasons in Section 6.

**Error 3: Forgetting to pre-fill a field in the edit form**

```html
<!-- Wrong: the date input has no value -->
    <input id="due_date" name="due_date" type="date">
```

```html
<!-- Correct -->
    <input id="due_date" name="due_date" type="date"
           value="{% if let Some(date) = task.due_date %}{{ date }}{% endif %}">
```

This compiles and seems to work, but it quietly destroys data. The edit form starts with an empty date, the user changes only the title and saves, and the empty date is sent along with it. `parse_due_date` turns the empty string into `None`, and the task loses its due date. An edit form always submits every field, so every field must start with the current value.

---

## 8. Exercises

**Exercise 1:** Add a "Delete all completed tasks" button below the task list. It posts to `/tasks/clear-done`, deletes every task with `done = TRUE`, prints how many were deleted in the server terminal, and redirects back to the list. Write a `delete_done_tasks` query function that returns the number of deleted rows.

**Exercise 2:** When a task is toggled from its detail page, the user is sent to the list, which is surprising. Add a hidden input `return_to` with the value `/tasks/{{ task.id }}` to the toggle form on the detail page, and redirect there after toggling. Only accept paths that start with `/tasks`; anything else falls back to `/tasks`.

**Exercise 3:** Deleting with one click is risky. Replace the delete form on the detail page with a "Delete task" link to `GET /tasks/{id}/delete`, which shows a confirmation page asking `Are you sure you want to delete "<title>"?` with a "Yes, delete it" button (a `POST` form to the same URL) and a "Cancel" link.

---

## 9. Solutions

**Solution for Exercise 1:**

Add the query below `delete_task`:

```rust
async fn delete_done_tasks(pool: &MySqlPool) -> Result<u64, sqlx::Error> {
    let result = sqlx::query("DELETE FROM tasks WHERE done = TRUE")
        .execute(pool)
        .await?;
    Ok(result.rows_affected())
}
```

Add the handler below `remove_task`:

```rust
async fn clear_done(State(pool): State<MySqlPool>) -> Result<Redirect, (StatusCode, String)> {
    let deleted = delete_done_tasks(&pool).await.map_err(internal_error)?;
    println!("cleared {deleted} completed tasks");
    Ok(Redirect::to("/tasks"))
}
```

Register the route in `main`:

```rust
        .route("/tasks/clear-done", post(clear_done))
```

And add the form to `templates/tasks/list.html`, right after `</ul>` and before `{% endif %}`:

```html
  <form method="post" action="/tasks/clear-done">
    <button type="submit">Delete all completed tasks</button>
  </form>
```

This time `rows_affected()` is useful as a number: it is the count of deleted tasks. Deleting zero tasks is not an error, so there is no 404 case. The route `/tasks/clear-done` does not conflict with `/tasks/{id}/delete`, because it has a different number of segments, and fixed paths always win over captures anyway. With two completed tasks in the table, clicking the button prints this line in the server terminal:

```text
cleared 2 completed tasks
```

**Solution for Exercise 2:**

Add a form struct for the toggle action:

```rust
#[derive(Deserialize)]
struct ToggleForm {
    return_to: Option<String>,
}
```

Update `toggle_done` to read it:

```rust
async fn toggle_done(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<ToggleForm>,
) -> Result<Response, (StatusCode, String)> {
    let toggled = toggle_task(&pool, id).await.map_err(internal_error)?;
    if !toggled {
        return Ok(not_found_page("That task does not exist."));
    }
    let target = match form.return_to.as_deref() {
        Some(path) if path.starts_with("/tasks") => path,
        _ => "/tasks",
    };
    Ok(Redirect::to(target).into_response())
}
```

And add the hidden input to the toggle form in `templates/tasks/show.html`:

```html
<form method="post" action="/tasks/{{ task.id }}/toggle">
  <input type="hidden" name="return_to" value="/tasks/{{ task.id }}">
  <button type="submit">{% if task.done %}Mark as not done{% else %}Mark as done{% endif %}</button>
</form>
```

A hidden input is sent with the form but not shown to the user. The toggle buttons on the list page do not include it, so `return_to` is `None` there and the list remains the target. The `match` with a guard (`if path.starts_with("/tasks")`) is important: without it, anyone could craft a form that sends `return_to=https://evil.example`, and your site would redirect visitors to another site, a weakness called an open redirect. Test both cases:

```bash
curl -s -o /dev/null -w "%{redirect_url}\n" -d "return_to=/tasks/2" http://127.0.0.1:3000/tasks/2/toggle
curl -s -o /dev/null -w "%{redirect_url}\n" -d "return_to=https://evil.example" http://127.0.0.1:3000/tasks/2/toggle
```

Output:

```text
http://127.0.0.1:3000/tasks/2
http://127.0.0.1:3000/tasks
```

The toggle handler now has a `Form` extractor, so every request must be form-encoded. Browsers always send forms that way, even forms without fields. With `curl`, send at least `-d ""`; a bare `curl -X POST` without a body is now rejected with `415 Unsupported Media Type`, the status you met in Lesson 5.

**Solution for Exercise 3:**

Create `templates/tasks/delete.html`:

```html
{% extends "base.html" %}

{% block title %}Delete {{ task.title }} - Todo Web{% endblock %}

{% block content %}
<h1>Delete Task</h1>
<p>Are you sure you want to delete "{{ task.title }}"? This cannot be undone.</p>
<form method="post" action="/tasks/{{ task.id }}/delete">
  <button type="submit">Yes, delete it</button>
  <a href="/tasks/{{ task.id }}">Cancel</a>
</form>
{% endblock %}
```

Add the template struct and a handler that shows it:

```rust
#[derive(Template)]
#[template(path = "tasks/delete.html")]
struct DeleteTaskTemplate {
    task: Task,
}
```

```rust
async fn confirm_delete(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    match task {
        Some(task) => Ok(render(DeleteTaskTemplate { task })),
        None => Ok(not_found_page("That task does not exist.")),
    }
}
```

Attach it to the `GET` method of the delete route:

```rust
        .route("/tasks/{id}/delete", get(confirm_delete).post(remove_task))
```

And replace the delete form in `templates/tasks/show.html` with a link:

```html
<p><a href="/tasks/{{ task.id }}/delete">Delete task</a></p>
```

This keeps the rule from Section 6: the `GET` request only shows a page and changes nothing; the actual deletion still requires a `POST`. It works without any JavaScript.

```bash
curl -s http://127.0.0.1:3000/tasks/8/delete | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Delete Task</h1>
<p>Are you sure you want to delete "Read the Axum docs"? This cannot be undone.</p>
<form method="post" action="/tasks/8/delete">
  <button type="submit">Yes, delete it</button>
  <a href="/tasks/8">Cancel</a>
</form>

  </main>
```

---

## Next Up - Lesson 13

In this lesson, you completed CRUD for tasks. The edit form is pre-filled with the current values, `update_task` binds its three values in placeholder order, `SET done = NOT done` toggles a task in one statement, and every update and delete checks `rows_affected()` so that missing tasks return a 404. You also saw why every action that changes data must be a `POST`.

The forms still handle bad input poorly: a blank title just sends the user back to an empty form without explanation, and an invalid date is silently dropped. Module 5 makes Todo Web safe and friendly. In Lesson 13, you will validate titles and dates on the server, show error messages next to the fields, and keep what the user typed when the form has mistakes.
