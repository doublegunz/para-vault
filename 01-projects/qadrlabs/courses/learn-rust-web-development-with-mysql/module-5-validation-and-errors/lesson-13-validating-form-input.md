## 1. Before You Begin

Module 4 gave Todo Web complete CRUD for tasks, but its forms are not friendly yet. In Lesson 11 and Lesson 12, a blank title simply sent the user back to an empty form with no explanation, and an invalid date was silently dropped. The database would also reject a title longer than 255 characters with a `500` error. Users deserve better: they should see what is wrong, right next to the field, without losing what they typed.

This lesson introduces proper server-side validation. All the rules live in one plain Rust function that takes the raw form and returns either a clean, typed task or a set of error messages. Because that function does not touch the database or the web framework, you can test it with ordinary unit tests, just like the parsing functions in the first course. The handlers then decide what to do with the result: save and redirect, or render the form again with the errors.

### What You'll Build

A `validate_task` function with three rules (title required, title at most 255 characters, due date must be a valid date), unit tests for it, and updated new and edit forms that show error messages under each field, keep the submitted values, and respond with `422 Unprocessable Entity` when the input is invalid.

### What You'll Learn

- ✅ Why validation must happen on the server, not only in the browser
- ✅ How to separate raw form input (`TaskForm`) from validated data (`ValidTask`)
- ✅ How to collect several field errors at once in a `FormErrors` struct
- ✅ How to re-render a form with errors and the user's input
- ✅ When to use the `422 Unprocessable Entity` status
- ✅ How to unit test validation rules with `cargo test`

### What You'll Need

- The `todo-web` project from Lesson 12
- `cargo test` from the first course

---

## 2. Write the Validation Function

The idea is to turn untrusted text into trusted data in exactly one place. Everything before `validate_task` is raw text from the browser; everything after it is guaranteed to follow the rules.

### Step 1: Define the Input, Error, and Output Types

In `src/main.rs`, replace the `TaskForm` struct with these three types:

```rust
#[derive(Deserialize, Default)]
struct TaskForm {
    title: String,
    due_date: String,
}

#[derive(Default, Debug, PartialEq)]
struct FormErrors {
    title: Option<String>,
    due_date: Option<String>,
}

#[derive(Debug, PartialEq)]
struct ValidTask {
    title: String,
    due_date: Option<NaiveDate>,
}
```

Each type has one job:

- `TaskForm` is the raw input, exactly as the browser sent it. It now also derives `Default`, which creates a value with empty strings. You will use it for the blank "New task" form.
- `FormErrors` holds at most one message per field. `None` means the field is fine. Deriving `Default` gives you a value with no errors, and `Debug` and `PartialEq` let tests compare and print it.
- `ValidTask` is the result of successful validation: a trimmed title and a real `Option<NaiveDate>`. Code that receives a `ValidTask` never has to check the input again.

### Step 2: Implement validate_task

Add the function below the three types:

```rust
fn validate_task(form: &TaskForm) -> Result<ValidTask, FormErrors> {
    let mut errors = FormErrors::default();

    let title = form.title.trim();
    if title.is_empty() {
        errors.title = Some(String::from("Title is required."));
    } else if title.chars().count() > 255 {
        errors.title = Some(String::from("Title must be at most 255 characters."));
    }

    let due_text = form.due_date.trim();
    let mut due_date = None;
    if !due_text.is_empty() {
        match NaiveDate::parse_from_str(due_text, "%Y-%m-%d") {
            Ok(date) => due_date = Some(date),
            Err(_) => {
                errors.due_date = Some(String::from("Due date must be a valid date (YYYY-MM-DD)."));
            }
        }
    }

    if errors.title.is_some() || errors.due_date.is_some() {
        return Err(errors);
    }
    Ok(ValidTask { title: title.to_string(), due_date })
}
```

Line by line:

- The function borrows the form (`&TaskForm`) instead of taking ownership. The handler still needs the form afterwards, to show the user's input again if validation fails.
- It returns `Result<ValidTask, FormErrors>`: the same `Result` type you know from error handling, here used for "valid data or a list of problems."
- `errors` starts empty and collects problems. The function checks every field before returning, so the user sees all the mistakes at once instead of fixing them one by one.
- The title is trimmed, then checked twice. `chars().count()` counts characters, not bytes. MySQL's `VARCHAR(255)` limit is also in characters, and a title with accented letters or emoji uses more than one byte per character, so `len()` would be wrong here (Section 7 shows the bug).
- An empty due date is fine and stays `None`. Any other text must parse as `YYYY-MM-DD`, or the field gets an error. `parse_from_str` also rejects dates that do not exist, such as `2026-02-30`.
- If any error was recorded, the function returns `Err(errors)`. Otherwise, it builds a `ValidTask`. `title.to_string()` turns the trimmed `&str` into an owned `String`.

The `parse_due_date` helper from Lesson 12 is no longer needed, so delete it.

### Step 3: Test the Rules

Validation rules are easy to break when they change later, so they deserve tests. Add a test module at the very end of `src/main.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    fn form(title: &str, due_date: &str) -> TaskForm {
        TaskForm { title: title.to_string(), due_date: due_date.to_string() }
    }

    #[test]
    fn accepts_a_title_and_a_date() {
        let task = validate_task(&form("  Plan the demo  ", "2026-11-12")).unwrap();
        assert_eq!(task.title, "Plan the demo");
        assert_eq!(task.due_date, NaiveDate::from_ymd_opt(2026, 11, 12));
    }

    #[test]
    fn empty_due_date_means_none() {
        let task = validate_task(&form("Read the docs", "")).unwrap();
        assert_eq!(task.due_date, None);
    }

    #[test]
    fn rejects_a_blank_title() {
        let errors = validate_task(&form("   ", "")).unwrap_err();
        assert_eq!(errors.title.as_deref(), Some("Title is required."));
        assert_eq!(errors.due_date, None);
    }

    #[test]
    fn rejects_a_title_that_is_too_long() {
        let long_title = "a".repeat(256);
        let errors = validate_task(&form(&long_title, "")).unwrap_err();
        assert_eq!(errors.title.as_deref(), Some("Title must be at most 255 characters."));
    }

    #[test]
    fn reports_both_errors_at_once() {
        let errors = validate_task(&form("", "next friday")).unwrap_err();
        assert!(errors.title.is_some());
        assert_eq!(
            errors.due_date.as_deref(),
            Some("Due date must be a valid date (YYYY-MM-DD).")
        );
    }
}
```

This is the same test structure as in the first course's final project:

- `#[cfg(test)]` compiles the module only for `cargo test`, and `use super::*;` gives it access to everything in the file, including private items.
- `form` is a small helper that builds a `TaskForm` from two string slices, so each test stays short.
- `unwrap()` and `unwrap_err()` extract the `Ok` or `Err` value and fail the test if the result is the other variant. `as_deref()` turns an `Option<String>` into an `Option<&str>` so it can be compared with a string literal.
- `"a".repeat(256)` builds a title one character over the limit.

The handlers still use `parse_due_date` and the old template structs, so the project, including its tests, only compiles again once Section 3 is done. After finishing Section 3, run the tests:

```bash
cargo test
```

Cargo compiles the project in test mode and then prints:

```text
running 5 tests
test tests::accepts_a_title_and_a_date ... ok
test tests::empty_due_date_means_none ... ok
test tests::rejects_a_blank_title ... ok
test tests::reports_both_errors_at_once ... ok
test tests::rejects_a_title_that_is_too_long ... ok

test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

Tests run in parallel, so their order may differ on your machine. None of these tests needs MySQL or a running server; they finish instantly.

---

## 3. Show Errors in the Forms

A form with errors must be rendered again with three things: the error messages, the values the user typed, and the right status code. The templates therefore need the raw form and the errors, not a `Task`.

### Step 1: Update the Template Structs

Replace `NewTaskTemplate` and `EditTaskTemplate` with:

```rust
#[derive(Template)]
#[template(path = "tasks/new.html")]
struct NewTaskTemplate {
    form: TaskForm,
    errors: FormErrors,
}

#[derive(Template)]
#[template(path = "tasks/edit.html")]
struct EditTaskTemplate {
    id: u64,
    form: TaskForm,
    errors: FormErrors,
}
```

Both templates now show a `TaskForm`, whose fields are plain strings. That works for every situation: an empty form, a form filled from the database, and a form with the user's invalid input. The edit template also needs the task's `id` for the form's `action` and the cancel link.

### Step 2: Update the Templates

Replace `templates/tasks/new.html` with:

```html
{% extends "base.html" %}

{% block title %}New Task - Todo Web{% endblock %}

{% block content %}
<h1>New Task</h1>
<form method="post" action="/tasks">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="{{ form.title }}" placeholder="What needs to be done?">
    {% if let Some(error) = errors.title %}<br><strong>{{ error }}</strong>{% endif %}
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date" value="{{ form.due_date }}">
    {% if let Some(error) = errors.due_date %}<br><strong>{{ error }}</strong>{% endif %}
  </p>
  <button type="submit">Add task</button>
</form>
{% endblock %}
```

Replace `templates/tasks/edit.html` with:

```html
{% extends "base.html" %}

{% block title %}Edit Task - Todo Web{% endblock %}

{% block content %}
<h1>Edit Task</h1>
<form method="post" action="/tasks/{{ id }}/edit">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="{{ form.title }}">
    {% if let Some(error) = errors.title %}<br><strong>{{ error }}</strong>{% endif %}
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date" value="{{ form.due_date }}">
    {% if let Some(error) = errors.due_date %}<br><strong>{{ error }}</strong>{% endif %}
  </p>
  <button type="submit">Save changes</button>
  <a href="/tasks/{{ id }}">Cancel</a>
</form>
{% endblock %}
```

Here is what changed in both:

- Every input has `value="{{ form.... }}"`, so whatever the user submitted comes back in the field. Askama escapes it, so even input containing quotes or tags is shown safely.
- Under each input, `{% if let Some(error) = errors.title %}` prints the message only when that field has an error.
- The `required` attribute is gone from the title. The server now produces a clear message for a blank title, and removing the browser check lets you see that message in the browser too. You could keep `required` for convenience in a real application; the server check stays either way.
- The edit page title no longer contains the task title, because the template only has the form. If the user has just cleared the title, there would be nothing sensible to show anyway.

### Step 3: Rewrite the Form Handlers

Replace `new_task_form`, `create_task`, `edit_task_form`, and `save_task` with:

```rust
async fn new_task_form() -> Response {
    render(NewTaskTemplate { form: TaskForm::default(), errors: FormErrors::default() })
}

async fn create_task(
    State(pool): State<MySqlPool>,
    Form(form): Form<TaskForm>,
) -> Result<Response, (StatusCode, String)> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(NewTaskTemplate { form, errors });
            return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
        }
    };

    let id = insert_task(&pool, &task.title, task.due_date)
        .await
        .map_err(internal_error)?;
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

async fn edit_task_form(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, (StatusCode, String)> {
    let task = find_task(&pool, id).await.map_err(internal_error)?;
    match task {
        Some(task) => {
            let form = TaskForm {
                title: task.title,
                due_date: task.due_date.map(|date| date.to_string()).unwrap_or_default(),
            };
            Ok(render(EditTaskTemplate { id, form, errors: FormErrors::default() }))
        }
        None => Ok(not_found_page("That task does not exist.")),
    }
}

async fn save_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<TaskForm>,
) -> Result<Response, (StatusCode, String)> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(EditTaskTemplate { id, form, errors });
            return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
        }
    };

    let updated = update_task(&pool, id, &task.title, task.due_date)
        .await
        .map_err(internal_error)?;
    if !updated {
        return Ok(not_found_page("That task does not exist."));
    }
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}
```

Here is how the pieces fit:

- `new_task_form` renders the template with an empty form and no errors, both built with `Default`.
- `create_task` and `save_task` start with the same `match`. On success, `task` is a `ValidTask`. On failure, the handler renders the form again with the original `form` and the `errors`, and `return`s immediately. The `return` matters: the `Err` arm must leave the function, because the `match` itself has to produce a `ValidTask` for the code below it.
- The status for invalid input is `StatusCode::UNPROCESSABLE_ENTITY` (`422`): "I understood the request, but the content is not acceptable." Browsers display the page normally, but the status tells tools and tests that the submission failed. No redirect happens, because there is nothing new to show; the user needs the same form again.
- Only valid data reaches the database: `insert_task` and `update_task` receive `&task.title` and `task.due_date` from the `ValidTask`.
- `edit_task_form` converts the stored task into a `TaskForm`. `task.due_date.map(|date| date.to_string())` turns `Some(date)` into `Some("2026-11-30")`, and `unwrap_or_default()` turns `None` into an empty string.

`create_task` now returns `Response` instead of `Redirect`, because it can return either a page or a redirect. The project compiles again, so go back and run `cargo test` as shown at the end of Section 2; all five tests pass.

---

## 4. Run and Test

Start the server with `cargo run`.

### Step 1: Submit an Invalid Form

Send a blank title and a date that is not a date. The first command shows only the status line; the second shows the page:

```bash
curl -s -i -d "title=   &due_date=next friday" http://127.0.0.1:3000/tasks | head -1
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
```

```bash
curl -s -d "title=   &due_date=next friday" http://127.0.0.1:3000/tasks | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>New Task</h1>
<form method="post" action="/tasks">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="   " placeholder="What needs to be done?">
    <br><strong>Title is required.</strong>
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date" value="next friday">
    <br><strong>Due date must be a valid date (YYYY-MM-DD).</strong>
  </p>
  <button type="submit">Add task</button>
</form>

  </main>
```

Both errors are shown at once, each under its own field, and the submitted values are back in the inputs. Nothing was saved.

### Step 2: Check the Length Rule and Escaping

A 256-character title triggers the length rule. The shell builds it with `printf`:

```bash
curl -s -d "title=$(printf 'a%.0s' $(seq 256))&due_date=" http://127.0.0.1:3000/tasks | grep strong
```

Output:

```text
    <br><strong>Title must be at most 255 characters.</strong>
```

Now submit HTML in the title and an impossible date:

```bash
curl -s -d 'title=<b>bold</b>&due_date=2026-13-45' http://127.0.0.1:3000/tasks | grep -E "value=|strong"
```

Output:

```text
    <input id="title" name="title" value="&#60;b&#62;bold&#60;/b&#62;" placeholder="What needs to be done?">
    <input id="due_date" name="due_date" type="date" value="2026-13-45">
    <br><strong>Due date must be a valid date (YYYY-MM-DD).</strong>
```

The title passed validation (it is not empty and not too long), but it is shown back escaped. Month 13 does not exist, so the date was rejected.

### Step 3: Submit a Valid Form

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "title=Prepare slides&due_date=2026-11-25" http://127.0.0.1:3000/tasks
```

Output:

```text
303 http://127.0.0.1:3000/tasks/14
```

Valid input is saved and redirected as before.

### Step 4: Check the Edit Form

Clear the title of an existing task (task 2 here):

```bash
curl -s -i -d "title=&due_date=2026-11-20" http://127.0.0.1:3000/tasks/2/edit | head -1
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
```

```bash
curl -s -d "title=&due_date=2026-11-20" http://127.0.0.1:3000/tasks/2/edit | sed -n '/<main>/,/<\/main>/p'
```

Output:

```text
  <main>
    
<h1>Edit Task</h1>
<form method="post" action="/tasks/2/edit">
  <p>
    <label for="title">Title</label><br>
    <input id="title" name="title" value="">
    <br><strong>Title is required.</strong>
  </p>
  <p>
    <label for="due_date">Due date (optional)</label><br>
    <input id="due_date" name="due_date" type="date" value="2026-11-20">
    
  </p>
  <button type="submit">Save changes</button>
  <a href="/tasks/2">Cancel</a>
</form>

  </main>
```

The new date the user entered is kept, even though the title failed. The task in the database is unchanged.

### Step 5: Try It in the Browser

Open `http://127.0.0.1:3000/tasks/new` and press **Add task** with an empty title: the page comes back with "Title is required." under the field. Type a title and submit again; this time the task is created. Open a task's edit page and clear its title to see the same behavior. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 13: form validation"
```

---

## 5. Validation Layers

Todo Web now checks input in three places. They complement each other, and only one of them can be trusted:

| Layer | Example | Purpose | Can be bypassed? |
| --- | --- | --- | --- |
| Browser | `required`, `type="date"` | Instant feedback while typing | Yes, by any non-browser client |
| Server | `validate_task` | The real rules, with friendly messages | No |
| Database | `NOT NULL`, `VARCHAR(255)`, `DATE` | Last line of defense for data integrity | No, but errors are not user-friendly |

Some principles behind this design:

- **Parse, don't just check.** `validate_task` does not merely answer "valid or not"; it turns a `TaskForm` of strings into a `ValidTask` of real types. Code after validation cannot accidentally use the raw input, because it only receives the typed result.
- **Collect all errors.** Reporting every problem at once saves the user several round trips.
- **Keep what the user typed.** Nothing is more frustrating than a form that clears itself after one mistake.
- **Keep rules out of handlers.** A pure function is easy to read, reuse (both forms share it), and test without a server or a database.
- **Match the database's limits.** The 255-character rule mirrors `VARCHAR(255)`. If a migration changes the column, change the rule and its test too.

---

## 6. Fix the Errors in Your Code

**Error 1: Forgetting `return` in the error branch**

```rust
// Wrong
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(NewTaskTemplate { form, errors });
            (StatusCode::UNPROCESSABLE_ENTITY, page).into_response()
        }
    };
```

```rust
// Correct
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => {
            let page = render(NewTaskTemplate { form, errors });
            return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
        }
    };
```

Without `return`, the `Err` arm tries to be the value of the `match`, but the `Ok` arm produces a `ValidTask`:

```text
error[E0308]: `match` arms have incompatible types
   --> src/main.rs:256:13
    |
252 |       let task = match validate_task(&form) {
    |  ________________-
253 | |         Ok(task) => task,
    | |                     ---- this is found to be of type `ValidTask`
254 | |         Err(errors) => {
255 | |             let page = render(NewTaskTemplate { form, errors });
256 | |             (StatusCode::UNPROCESSABLE_ENTITY, page).into_response()
    | |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ expected `ValidTask`, found `Response<Body>`
257 | |         }
258 | |     };
    | |_____- `match` arms have incompatible types
```

`return Ok(...)` leaves the whole handler with the error page. A `return` expression has the type `!` ("never"), which fits anywhere, so the arms agree again.

**Error 2: Counting bytes instead of characters**

```rust
// Wrong
    } else if title.len() > 255 {
```

```rust
// Correct
    } else if title.chars().count() > 255 {
```

`len()` returns the number of bytes in the UTF-8 encoding. For plain English text, bytes and characters are the same, so the bug hides. Add a test with non-ASCII text to the test module:

```rust
    #[test]
    fn accepts_255_characters_outside_ascii() {
        let title = "é".repeat(255);
        assert!(validate_task(&form(&title, "")).is_ok());
    }
```

With `len()`, it fails:

```text
running 6 tests
test tests::accepts_a_title_and_a_date ... ok
test tests::rejects_a_title_that_is_too_long ... ok
test tests::reports_both_errors_at_once ... ok
test tests::empty_due_date_means_none ... ok
test tests::rejects_a_blank_title ... ok
test tests::accepts_255_characters_outside_ascii ... FAILED

failures:

---- tests::accepts_255_characters_outside_ascii stdout ----

thread 'tests::accepts_255_characters_outside_ascii' (47281) panicked at src/main.rs:407:9:
assertion failed: validate_task(&form(&title, "")).is_ok()
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    tests::accepts_255_characters_outside_ascii

test result: FAILED. 5 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

Each `é` takes two bytes, so 255 of them are 510 bytes and the title is rejected, although MySQL would store it without complaint. A user writing in many languages other than English would hit this limit with titles far shorter than 255 characters. With `chars().count()`, the test passes. Keep the test: it guards the rule against future changes.

**Error 3: Moving the form into the validation function**

```rust
// Wrong
fn validate_task(form: TaskForm) -> Result<ValidTask, FormErrors> {
```

```rust
// Correct
fn validate_task(form: &TaskForm) -> Result<ValidTask, FormErrors> {
```

If `validate_task` takes the form by value, the handler gives up ownership when it calls `validate_task(form)` and can no longer put the form into the template:

```text
error[E0382]: use of moved value: `form`
   --> src/main.rs:255:49
    |
250 |     Form(form): Form<TaskForm>,
    |          ---- move occurs because `form` has type `TaskForm`, which does not implement the `Copy` trait
251 | ) -> Result<Response, (StatusCode, String)> {
252 |     let task = match validate_task(form) {
    |                                    ---- value moved here
...
255 |             let page = render(NewTaskTemplate { form, errors });
    |                                                 ^^^^ value used here after move
```

This is ownership from the first course in a web setting. The compiler's note even suggests the fix: borrow the form instead. Validation only needs to read it.

---

## 7. Exercises

**Exercise 1:** New tasks should not be created with a due date in the past. In `create_task` only (editing an old task may keep its old date), after `validate_task` succeeds, compare the due date with today's date and re-render the form with the message `Due date cannot be in the past.` under the due date field.

**Exercise 2:** Add two more unit tests: the non-ASCII length test from Section 6, and a test that `2026-02-30` is rejected as a due date. Run `cargo test` and check that all seven tests pass.

**Exercise 3:** Add a summary above the new task form, such as `Please fix 2 error(s) below.`, shown only when there are errors. Implement a `count()` method on `FormErrors` and call it from the template.

---

## 8. Solutions

**Solution for Exercise 1:**

In `create_task`, add this block between the validation `match` and the call to `insert_task`:

```rust
    let today = chrono::Local::now().date_naive();
    if task.due_date.is_some_and(|date| date < today) {
        let errors = FormErrors {
            due_date: Some(String::from("Due date cannot be in the past.")),
            ..FormErrors::default()
        };
        let page = render(NewTaskTemplate { form, errors });
        return Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response());
    }
```

The check lives in the handler rather than in `validate_task`, for two reasons: it applies to creating only, and it depends on today's date, which would make `validate_task`'s tests change their result over time. `..FormErrors::default()` is struct update syntax: it fills every field you did not write (here `title`) from a default value. `is_some_and` is the same method you used for the overdue check in Lesson 10.

```bash
curl -s -i -d "title=Pay last month's bill&due_date=2026-10-01" http://127.0.0.1:3000/tasks | grep -E "HTTP|strong"
```

Output (with Exercise 3 solved as well, so the summary appears too):

```text
HTTP/1.1 422 Unprocessable Entity
  <p><strong>Please fix 1 error(s) below.</strong></p>
    <br><strong>Due date cannot be in the past.</strong>
```

**Solution for Exercise 2:**

Add these tests to the `tests` module:

```rust
    #[test]
    fn accepts_255_characters_outside_ascii() {
        let title = "é".repeat(255);
        assert!(validate_task(&form(&title, "")).is_ok());
    }

    #[test]
    fn rejects_a_date_that_does_not_exist() {
        let errors = validate_task(&form("Pay rent", "2026-02-30")).unwrap_err();
        assert!(errors.due_date.is_some());
    }
```

`2026-02-30` has the right shape, but February never has 30 days, and chrono knows it. Testing such edge cases proves that the rule checks real dates, not just the pattern of digits and dashes. With these two tests added, `cargo test` reports `7 passed`. If you also add the `counts_errors` test from Exercise 3, the total is 8.

**Solution for Exercise 3:**

Add an `impl` block for `FormErrors`, below its definition:

```rust
impl FormErrors {
    fn count(&self) -> usize {
        usize::from(self.title.is_some()) + usize::from(self.due_date.is_some())
    }
}
```

Show the summary in `templates/tasks/new.html`, right below `<h1>New Task</h1>`:

```html
{% if errors.count() > 0 %}
  <p><strong>Please fix {{ errors.count() }} error(s) below.</strong></p>
{% endif %}
```

And test the method:

```rust
    #[test]
    fn counts_errors() {
        let errors = validate_task(&form("", "soon")).unwrap_err();
        assert_eq!(errors.count(), 2);
    }
```

`usize::from(bool)` converts `true` to `1` and `false` to `0`, so the method adds up the fields that have errors. Templates can call methods on their fields, so the template asks the errors for their count instead of receiving it as a separate field.

```bash
curl -s -d "title=&due_date=soon" http://127.0.0.1:3000/tasks | grep strong
```

Output:

```text
  <p><strong>Please fix 2 error(s) below.</strong></p>
    <br><strong>Title is required.</strong>
    <br><strong>Due date must be a valid date (YYYY-MM-DD).</strong>
```

---

## Next Up - Lesson 14

In this lesson, you moved all form rules into a `validate_task` function that turns a raw `TaskForm` into a typed `ValidTask` or a `FormErrors` value, tested it with `cargo test`, and updated both forms to show errors under each field, keep the user's input, and respond with `422 Unprocessable Entity`.

The handlers still repeat `.map_err(internal_error)` on every query and return awkward `(StatusCode, String)` errors as plain text. In Lesson 14, you will create an `AppError` enum, convert SQLx and template errors into it with `From` so the `?` operator works directly, and implement `IntoResponse` so every failure becomes a friendly error page.
