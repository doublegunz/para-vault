## 1. Before You Begin

Todo Web has one table so far. Every task stands alone, and as the list grows, it becomes hard to see which tasks belong to work, which to home, and which to study. Real applications almost always have several tables that refer to each other, and that is where relational databases like MySQL shine.

In this lesson, you will add a second table, `categories`, and connect it to `tasks` with a foreign key: each task can point to one category, and one category can have many tasks. This is called a one-to-many relationship. You will create the table and the link with two new migrations, build a page to add and delete categories, add a category drop-down to the task forms, and see how MySQL itself protects the link between the tables.

### What You'll Build

A `categories` table with unique names, a nullable `category_id` column on `tasks` with a foreign key that sets the column to `NULL` when its category is deleted, a `/categories` page to list, add, and delete categories, a category drop-down in the new and edit task forms, and the category name on each task's detail page.

### What You'll Learn

- ✅ What a one-to-many relationship and a foreign key are
- ✅ How to write migrations that create a table and alter an existing one
- ✅ What `ON DELETE SET NULL` does when a referenced row is deleted
- ✅ How to detect a unique constraint violation from SQLx with `is_unique_violation`
- ✅ How to build a `<select>` drop-down from database rows in Askama
- ✅ Why the application should still validate a foreign key value before saving

### What You'll Need

- The `todo-web` project from Lesson 14
- sqlx-cli from Lesson 8

---

## 2. Create the Categories Table and the Foreign Key

Schema changes always start with migrations. This change has two parts, a new table and a new column on an existing table, so it gets two migrations, one change each, as recommended in Lesson 8.

### Step 1: Generate the Migrations

In the `todo-web` folder, run the two commands one after the other:

```bash
sqlx migrate add -r create_categories_table
sqlx migrate add -r add_category_to_tasks
```

Output:

```text
Creating migrations/20261101171655_create_categories_table.up.sql
Creating migrations/20261101171655_create_categories_table.down.sql
Creating migrations/20261101171656_add_category_to_tasks.up.sql
Creating migrations/20261101171656_add_category_to_tasks.down.sql
```

The version numbers make sure the categories table is created first, which matters: a foreign key can only point to a table that already exists.

### Step 2: Write the Categories Migration

Put this in `..._create_categories_table.up.sql`:

```sql
CREATE TABLE categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);
```

And this in `..._create_categories_table.down.sql`:

```sql
DROP TABLE categories;
```

`UNIQUE` tells MySQL to reject a second category with the same name. With the case-insensitive collation of the database, "Work" and "work" count as the same name.

### Step 3: Write the Foreign Key Migration

Put this in `..._add_category_to_tasks.up.sql`:

```sql
ALTER TABLE tasks
    ADD COLUMN category_id BIGINT UNSIGNED NULL,
    ADD CONSTRAINT fk_tasks_category
        FOREIGN KEY (category_id) REFERENCES categories (id)
        ON DELETE SET NULL;
```

And this in `..._add_category_to_tasks.down.sql`:

```sql
ALTER TABLE tasks
    DROP FOREIGN KEY fk_tasks_category,
    DROP COLUMN category_id;
```

Here is what the up migration does:

- `ADD COLUMN category_id BIGINT UNSIGNED NULL` adds the column that stores which category a task belongs to. Its type must match `categories.id` exactly. It allows `NULL`, because a task may have no category, and every existing task starts without one.
- `ADD CONSTRAINT fk_tasks_category FOREIGN KEY (category_id) REFERENCES categories (id)` creates the foreign key. From now on, MySQL only accepts a `category_id` that exists in `categories.id` (or `NULL`). The name `fk_tasks_category` lets the down migration remove the constraint later.
- `ON DELETE SET NULL` decides what happens to tasks when their category is deleted: their `category_id` becomes `NULL`, so the tasks survive without a category. Other options are `CASCADE` (delete the tasks too) and `RESTRICT` (refuse to delete a category that still has tasks).

The down migration removes the constraint first and the column second, in one statement. The order matters, as Section 7 shows.

### Step 4: Apply and Test the Migrations

```bash
sqlx migrate run
```

Output:

```text
Applied 20261101171655/migrate create categories table (8.544094ms)
Applied 20261101171656/migrate add category to tasks (13.934561ms)
```

Following the rule from Lesson 8, test the down migrations before going further, then apply everything again:

```bash
sqlx migrate revert
sqlx migrate revert
sqlx migrate run
```

Output:

```text
Applied 20261101171656/revert add category to tasks (25.547651ms)
Applied 20261101171655/revert create categories table (5.291264ms)
Applied 20261101171655/migrate create categories table (8.086173ms)
Applied 20261101171656/migrate add category to tasks (15.082174ms)
```

Each `revert` undoes one migration, newest first. Check the result:

```bash
mysql -u todo_user -p db_rust_todo -t -e "DESCRIBE categories; DESCRIBE tasks;"
```

Output:

```text
+-------+---------------------+------+-----+---------+----------------+
| Field | Type                | Null | Key | Default | Extra          |
+-------+---------------------+------+-----+---------+----------------+
| id    | bigint(20) unsigned | NO   | PRI | NULL    | auto_increment |
| name  | varchar(100)        | NO   | UNI | NULL    |                |
+-------+---------------------+------+-----+---------+----------------+
+-------------+---------------------+------+-----+---------------------+----------------+
| Field       | Type                | Null | Key | Default             | Extra          |
+-------------+---------------------+------+-----+---------------------+----------------+
| id          | bigint(20) unsigned | NO   | PRI | NULL                | auto_increment |
| title       | varchar(255)        | NO   |     | NULL                |                |
| done        | tinyint(1)          | NO   |     | 0                   |                |
| due_date    | date                | YES  |     | NULL                |                |
| created_at  | datetime            | NO   |     | current_timestamp() |                |
| category_id | bigint(20) unsigned | YES  | MUL | NULL                |                |
+-------------+---------------------+------+-----+---------------------+----------------+
```

`UNI` marks the unique `name` column. `MUL` on `category_id` means the column has an index that allows repeated values; MySQL creates it automatically for the foreign key, so looking up all tasks of a category is fast.

---

## 3. Add Categories to the Rust Code

The Rust side needs a `Category` struct, queries for categories, and the new column wherever tasks are read or written.

### Step 1: Add the Category Struct and the New Task Field

Add a field to the end of `Task`, and a new struct below it:

```rust
#[derive(sqlx::FromRow)]
struct Task {
    id: u64,
    title: String,
    done: bool,
    due_date: Option<NaiveDate>,
    created_at: NaiveDateTime,
    category_id: Option<u64>,
}

#[derive(sqlx::FromRow)]
struct Category {
    id: u64,
    name: String,
}
```

`category_id` is an `Option<u64>`, matching the nullable `BIGINT UNSIGNED` column. Because `Task` has a new field, every query that reads tasks must select the new column. Replace `SELECT id, title, done, due_date, created_at FROM tasks` with `SELECT id, title, done, due_date, created_at, category_id FROM tasks` in `search_tasks` and `find_task`. A search-and-replace in your editor does it in one go.

### Step 2: Add the Category Queries

Add these functions below `delete_task`:

```rust
async fn all_categories(pool: &MySqlPool) -> Result<Vec<Category>, sqlx::Error> {
    sqlx::query_as::<_, Category>("SELECT id, name FROM categories ORDER BY name")
        .fetch_all(pool)
        .await
}

async fn find_category(pool: &MySqlPool, id: u64) -> Result<Option<Category>, sqlx::Error> {
    sqlx::query_as::<_, Category>("SELECT id, name FROM categories WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

async fn insert_category(pool: &MySqlPool, name: &str) -> Result<u64, sqlx::Error> {
    let result = sqlx::query("INSERT INTO categories (name) VALUES (?)")
        .bind(name)
        .execute(pool)
        .await?;
    Ok(result.last_insert_id())
}

async fn delete_category(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM categories WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

async fn category_exists(pool: &MySqlPool, category_id: Option<u64>) -> Result<bool, sqlx::Error> {
    match category_id {
        Some(id) => Ok(find_category(pool, id).await?.is_some()),
        None => Ok(true),
    }
}
```

The first four follow the same patterns as the task queries. `category_exists` answers "is this a category the task may use?": no category at all is always fine, and an ID is fine only if `find_category` finds it.

### Step 3: Save the Category with the Task

As tasks gain fields, passing each value separately gets unwieldy. Replace `insert_task` and `update_task` with versions that take the whole `ValidTask`:

```rust
async fn insert_task(pool: &MySqlPool, task: &ValidTask) -> Result<u64, sqlx::Error> {
    let result =
        sqlx::query("INSERT INTO tasks (title, due_date, category_id) VALUES (?, ?, ?)")
            .bind(&task.title)
            .bind(task.due_date)
            .bind(task.category_id)
            .execute(pool)
            .await?;
    Ok(result.last_insert_id())
}

async fn update_task(pool: &MySqlPool, id: u64, task: &ValidTask) -> Result<bool, sqlx::Error> {
    let result =
        sqlx::query("UPDATE tasks SET title = ?, due_date = ?, category_id = ? WHERE id = ?")
            .bind(&task.title)
            .bind(task.due_date)
            .bind(task.category_id)
            .bind(id)
            .execute(pool)
            .await?;
    Ok(result.rows_affected() > 0)
}
```

Each function now has one more placeholder and one more `.bind()`, in the same order. `&task.title` borrows the `String`; `due_date` and `category_id` are `Option`s of `Copy` types, so they can be bound directly. Binding `None` stores `NULL`.

---

## 4. Validate the Category in Task Forms

The form sends the selected category as text, like every form value. Validation turns it into an `Option<u64>`, and the handler then checks that the category really exists.

### Step 1: Extend the Form Types

Update the three validation types:

```rust
#[derive(Deserialize, Default)]
struct TaskForm {
    title: String,
    due_date: String,
    #[serde(default)]
    category_id: String,
}

#[derive(Default, Debug, PartialEq)]
struct FormErrors {
    title: Option<String>,
    due_date: Option<String>,
    category_id: Option<String>,
}

#[derive(Debug, PartialEq)]
struct ValidTask {
    title: String,
    due_date: Option<NaiveDate>,
    category_id: Option<u64>,
}
```

`#[serde(default)]` on `category_id` keeps forms without the drop-down, such as a quick-add form, working: a missing field becomes an empty string, meaning "no category."

### Step 2: Parse the Category ID

In `validate_task`, replace the final `if errors...` check and the `Ok(ValidTask { ... })` line with:

```rust
    let category_text = form.category_id.trim();
    let mut category_id = None;
    if !category_text.is_empty() {
        match category_text.parse::<u64>() {
            Ok(id) => category_id = Some(id),
            Err(_) => errors.category_id = Some(String::from("Please choose a category from the list.")),
        }
    }

    if errors.title.is_some() || errors.due_date.is_some() || errors.category_id.is_some() {
        return Err(errors);
    }
    Ok(ValidTask { title: title.to_string(), due_date, category_id })
```

An empty value means "no category." Anything else must parse as a `u64`. A browser only sends values from the drop-down, so a non-number means someone edited the request by hand.

### Step 3: Update the Tests

The test helper must fill the new field. Replace the `form` helper in the `tests` module, and add two tests:

```rust
    fn form(title: &str, due_date: &str) -> TaskForm {
        TaskForm {
            title: title.to_string(),
            due_date: due_date.to_string(),
            category_id: String::new(),
        }
    }
```

```rust
    #[test]
    fn parses_the_category_id() {
        let mut input = form("Plan the demo", "");
        input.category_id = String::from("3");
        assert_eq!(validate_task(&input).unwrap().category_id, Some(3));
    }

    #[test]
    fn rejects_a_category_id_that_is_not_a_number() {
        let mut input = form("Plan the demo", "");
        input.category_id = String::from("work");
        let errors = validate_task(&input).unwrap_err();
        assert!(errors.category_id.is_some());
    }
```

`validate_task` can check that the ID is a number, but not that the category exists, because it does not use the database. That check belongs in the handlers.

### Step 4: Render the Forms with Categories

The form templates now need the list of categories to build the drop-down. Add a `categories` field to both form template structs:

```rust
#[derive(Template)]
#[template(path = "tasks/new.html")]
struct NewTaskTemplate {
    form: TaskForm,
    errors: FormErrors,
    categories: Vec<Category>,
}

#[derive(Template)]
#[template(path = "tasks/edit.html")]
struct EditTaskTemplate {
    id: u64,
    form: TaskForm,
    errors: FormErrors,
    categories: Vec<Category>,
}
```

Re-rendering a form with errors now requires loading the categories too. Two helpers keep the handlers short. Add them above `create_task`, together with a function that builds the "unknown category" error:

```rust
fn unknown_category() -> FormErrors {
    FormErrors {
        category_id: Some(String::from("Please choose a category from the list.")),
        ..FormErrors::default()
    }
}

async fn new_form_with_errors(
    pool: &MySqlPool,
    form: TaskForm,
    errors: FormErrors,
) -> Result<Response, AppError> {
    let categories = all_categories(pool).await?;
    let page = render(NewTaskTemplate { form, errors, categories })?;
    Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response())
}

async fn edit_form_with_errors(
    pool: &MySqlPool,
    id: u64,
    form: TaskForm,
    errors: FormErrors,
) -> Result<Response, AppError> {
    let categories = all_categories(pool).await?;
    let page = render(EditTaskTemplate { id, form, errors, categories })?;
    Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response())
}
```

### Step 5: Update the Task Handlers

Replace `new_task_form`, `create_task`, `edit_task_form`, and `save_task` with:

```rust
async fn new_task_form(State(pool): State<MySqlPool>) -> Result<Response, AppError> {
    let categories = all_categories(&pool).await?;
    render(NewTaskTemplate { form: TaskForm::default(), errors: FormErrors::default(), categories })
}

async fn create_task(
    State(pool): State<MySqlPool>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return new_form_with_errors(&pool, form, errors).await,
    };
    if !category_exists(&pool, task.category_id).await? {
        return new_form_with_errors(&pool, form, unknown_category()).await;
    }

    let id = insert_task(&pool, &task).await?;
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

async fn edit_task_form(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
    let form = TaskForm {
        title: task.title,
        due_date: task.due_date.map(|date| date.to_string()).unwrap_or_default(),
        category_id: task.category_id.map(|id| id.to_string()).unwrap_or_default(),
    };
    let categories = all_categories(&pool).await?;
    render(EditTaskTemplate { id, form, errors: FormErrors::default(), categories })
}

async fn save_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return edit_form_with_errors(&pool, id, form, errors).await,
    };
    if !category_exists(&pool, task.category_id).await? {
        return edit_form_with_errors(&pool, id, form, unknown_category()).await;
    }

    if !update_task(&pool, id, &task).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}
```

Each handler now validates in two stages: `validate_task` checks the shape of the input, and `category_exists` checks the selected category against the database. Either failure re-renders the form with a message. `new_task_form` became a handler with state, because it needs the categories. `edit_task_form` converts the task's `Option<u64>` back to text for the form, the same way as the due date.

### Step 6: Add the Drop-Down to the Forms

In both `templates/tasks/new.html` and `templates/tasks/edit.html`, add this paragraph right before the submit button:

```html
  <p>
    <label for="category_id">Category (optional)</label><br>
    <select id="category_id" name="category_id">
      <option value="">No category</option>
      {% for category in categories %}
        <option value="{{ category.id }}" {% if form.category_id == category.id.to_string() %}selected{% endif %}>{{ category.name }}</option>
      {% endfor %}
    </select>
    {% if let Some(error) = errors.category_id %}<br><strong>{{ error }}</strong>{% endif %}
  </p>
```

The first option, with an empty value, means "no category." The loop adds one option per category: the browser shows the name and sends the ID. The `selected` attribute marks the option that matches `form.category_id`, so the edit form shows the current category and a form with errors keeps the user's choice. `form.category_id` is a `String` and `category.id` is a `u64`, so the ID is converted with `to_string()` before comparing.

### Step 7: Show the Category on the Detail Page

Add a field to `TaskShowTemplate`:

```rust
#[derive(Template)]
#[template(path = "tasks/show.html")]
struct TaskShowTemplate {
    task: Task,
    category: Option<Category>,
}
```

Look it up in `show_task`:

```rust
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = find_task(&pool, id).await?.ok_or(AppError::NotFound)?;
    let category = match task.category_id {
        Some(category_id) => find_category(&pool, category_id).await?,
        None => None,
    };
    render(TaskShowTemplate { task, category })
}
```

And print it in `templates/tasks/show.html`, above the `Created:` line:

```html
<p>Category: {% if let Some(category) = category %}{{ category.name }}{% else %}none{% endif %}</p>
```

This uses a second query to fetch the category name. In Lesson 16, you will learn to get the task and its category name in a single query with a `JOIN`.

---

## 5. Build the Categories Page

Categories need a place to be managed. One page lists them, has a form to add a new one, and a delete button next to each.

### Step 1: Create the Template

Create the folder `templates/categories` and in it `list.html`:

```html
{% extends "base.html" %}

{% block title %}Categories - Todo Web{% endblock %}

{% block content %}
<h1>Categories</h1>

<form method="post" action="/categories">
  <label for="name">New category</label>
  <input id="name" name="name" value="{{ name }}" placeholder="Work, Home, Study...">
  <button type="submit">Add</button>
  {% if let Some(error) = error %}<br><strong>{{ error }}</strong>{% endif %}
</form>

{% if categories.is_empty() %}
  <p>No categories yet.</p>
{% else %}
  <ul>
    {% for category in categories %}
      <li>
        {{ category.name }}
        <form method="post" action="/categories/{{ category.id }}/delete" style="display: inline">
          <button type="submit">Delete</button>
        </form>
      </li>
    {% endfor %}
  </ul>
{% endif %}
{% endblock %}
```

The add form keeps the typed `name` and shows an `error` when there is one, using the same pattern as the task forms. Add a link to the page in the navigation of `templates/base.html`:

```html
  <nav>
    <a href="/">Home</a> |
    <a href="/tasks">Tasks</a> |
    <a href="/tasks/new">New task</a> |
    <a href="/categories">Categories</a>
  </nav>
```

### Step 2: Add the Structs and Handlers

Add the template struct and the form struct:

```rust
#[derive(Template)]
#[template(path = "categories/list.html")]
struct CategoryListTemplate {
    categories: Vec<Category>,
    name: String,
    error: Option<String>,
}

#[derive(Deserialize)]
struct CategoryForm {
    name: String,
}
```

Then add three handlers above the `not_found` handler:

```rust
async fn list_categories(State(pool): State<MySqlPool>) -> Result<Response, AppError> {
    let categories = all_categories(&pool).await?;
    render(CategoryListTemplate { categories, name: String::new(), error: None })
}

async fn create_category(
    State(pool): State<MySqlPool>,
    Form(form): Form<CategoryForm>,
) -> Result<Response, AppError> {
    let name = form.name.trim();
    let error = if name.is_empty() {
        Some("Name is required.")
    } else if name.chars().count() > 100 {
        Some("Name must be at most 100 characters.")
    } else {
        match insert_category(&pool, name).await {
            Ok(_) => None,
            Err(sqlx::Error::Database(err)) if err.is_unique_violation() => {
                Some("A category with this name already exists.")
            }
            Err(err) => return Err(err.into()),
        }
    };

    match error {
        None => Ok(Redirect::to("/categories").into_response()),
        Some(message) => {
            let categories = all_categories(&pool).await?;
            let page = CategoryListTemplate {
                categories,
                name: form.name,
                error: Some(message.to_string()),
            };
            Ok((StatusCode::UNPROCESSABLE_ENTITY, render(page)?).into_response())
        }
    }
}

async fn remove_category(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !delete_category(&pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/categories"))
}
```

The interesting part is the duplicate check in `create_category`:

- The name is validated like a title: required, and at most 100 characters to match `VARCHAR(100)`.
- Instead of first asking the database "does this name exist?", the handler simply tries to insert and lets the `UNIQUE` constraint decide. This is more reliable: two people adding "Work" at the same moment cannot both pass a check that runs before the insert, but only one of them can pass the constraint.
- `sqlx::Error::Database(err)` matches errors reported by the database server. `err.is_unique_violation()` is a SQLx method that recognizes duplicate-key errors (MySQL error 1062) without you having to remember the number. The guard `if ...` makes the arm match only that case.
- Any other error is converted with `err.into()`, which uses the `From` implementation from Lesson 14 to produce an `AppError::Database`, and returned.
- `error` is an `Option<&str>`: `None` means success. The final `match` either redirects or re-renders the page with the message and the user's input, using `422` like the task forms.

### Step 3: Register the Routes

Add the category routes to the router in `main`:

```rust
        .route("/categories", get(list_categories).post(create_category))
        .route("/categories/{id}/delete", post(remove_category))
```

Put them before `.fallback(not_found)`. The project now builds and the tests pass:

```bash
cargo test
```

The test summary reads `test result: ok. 7 passed`.

---

## 6. Run and Test

Start the server with `cargo run`. The migrations are already applied, so it starts as usual.

### Step 1: Add Categories

Create three categories, then try a duplicate:

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "name=Work" http://127.0.0.1:3000/categories
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "name=Home" http://127.0.0.1:3000/categories
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "name=Study" http://127.0.0.1:3000/categories
```

Output:

```text
303 http://127.0.0.1:3000/categories
303 http://127.0.0.1:3000/categories
303 http://127.0.0.1:3000/categories
```

```bash
curl -s -i -d "name=work" http://127.0.0.1:3000/categories | head -1
curl -s -d "name=work" http://127.0.0.1:3000/categories | grep strong
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
  <br><strong>A category with this name already exists.</strong>
```

`work` in lowercase was rejected too, because the database compares names case-insensitively. Check the table:

```bash
mysql -u todo_user -p db_rust_todo -t -e "SELECT * FROM categories;"
```

Output:

```text
+----+-------+
| id | name  |
+----+-------+
|  2 | Home  |
|  3 | Study |
|  1 | Work  |
+----+-------+
```

MySQL lists the rows in the order of the `name` index here, because no `ORDER BY` was given; the IDs show the order of insertion.

### Step 2: Use the Drop-Down

The new task form now contains the categories, sorted by name:

```bash
curl -s http://127.0.0.1:3000/tasks/new | sed -n '/<select/,/<\/select>/p'
```

Output:

```text
    <select id="category_id" name="category_id">
      <option value="">No category</option>
      
        <option value="2" >Home</option>
      
        <option value="3" >Study</option>
      
        <option value="1" >Work</option>
      
    </select>
```

Create a task in the Work category (ID 1), and try an ID that does not exist:

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "title=Prepare slides&due_date=2026-11-25&category_id=1" http://127.0.0.1:3000/tasks
```

Output:

```text
303 http://127.0.0.1:3000/tasks/16
```

```bash
curl -s -i -d "title=Prepare slides&due_date=&category_id=99" http://127.0.0.1:3000/tasks | grep -E "HTTP|strong"
```

Output:

```text
HTTP/1.1 422 Unprocessable Entity
    <br><strong>Please choose a category from the list.</strong>
```

### Step 3: Edit a Task's Category

Move task 2 into the Work category, then look at its edit form and detail page:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -d "title=Build a web app&due_date=2026-11-30&category_id=1" http://127.0.0.1:3000/tasks/2/edit
curl -s http://127.0.0.1:3000/tasks/2/edit | grep selected
curl -s http://127.0.0.1:3000/tasks/2 | grep Category
```

Output:

```text
303
        <option value="1" selected>Work</option>
<p>Category: Work</p>
```

The edit form pre-selects the stored category, and the detail page shows its name.

### Step 4: Delete a Category

```bash
mysql -u todo_user -p db_rust_todo -t -e "SELECT id, title, category_id FROM tasks ORDER BY id;"
```

Output:

```text
+----+------------------------------+-------------+
| id | title                        | category_id |
+----+------------------------------+-------------+
|  2 | Build a web app              |           1 |
|  4 | Write the first handler test |        NULL |
|  8 | Read the Axum docs           |        NULL |
| 13 | Learn Rust                   |        NULL |
| 16 | Prepare slides               |           1 |
+----+------------------------------+-------------+
```

Two tasks belong to Work. Delete the category:

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -X POST http://127.0.0.1:3000/categories/1/delete
```

Output:

```text
303 http://127.0.0.1:3000/categories
```

```bash
mysql -u todo_user -p db_rust_todo -t -e "SELECT id, title, category_id FROM tasks ORDER BY id;"
```

Output:

```text
+----+------------------------------+-------------+
| id | title                        | category_id |
+----+------------------------------+-------------+
|  2 | Build a web app              |        NULL |
|  4 | Write the first handler test |        NULL |
|  8 | Read the Axum docs           |        NULL |
| 13 | Learn Rust                   |        NULL |
| 16 | Prepare slides               |        NULL |
+----+------------------------------+-------------+
```

The tasks survived, and MySQL set their `category_id` to `NULL` on its own: that is `ON DELETE SET NULL` at work. Your Rust code did not have to update the tasks. Add the Work category again in the browser and give a few tasks a category, so Lesson 16 has data to filter. Stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 15: categories and foreign keys"
```

---

## 7. How Foreign Keys Protect Your Data

The `categories` and `tasks` tables now form a one-to-many relationship:

```text
categories                     tasks
+----+-------+                 +----+-----------------+-------------+
| id | name  |  1 ------- many | id | title           | category_id |
+----+-------+                 +----+-----------------+-------------+
|  2 | Home  |                 |  2 | Build a web app |           6 |
|  6 | Work  | <-------------- | 16 | Prepare slides  |           6 |
+----+-------+                 | 13 | Learn Rust      |           3 |
                               +----+-----------------+-------------+
```

The foreign key lives on the "many" side, in `tasks.category_id`. The database enforces three rules with it:

- **No dangling references.** A task cannot point to a category that does not exist. MySQL rejects such an `INSERT` or `UPDATE` with error 1452.
- **A defined delete behavior.** Deleting a category triggers the `ON DELETE` rule: `SET NULL` here, so tasks lose their category but survive.
- **Matching types.** The column and the referenced key must have the same type. A mismatch, such as `INT` against `BIGINT UNSIGNED`, makes the migration fail.

Why does the application still check `category_exists` before saving? Because the database's rejection is a crash from the user's point of view: it arrives as a `sqlx::Error`, becomes an `AppError::Database`, and the user sees a `500` page. Checking first lets the application show a helpful message next to the field. The two layers work together, exactly like validation and the column limits in Lesson 13: the application gives good feedback, and the database guarantees the rule even if the application has a bug.

---

## 8. Fix the Errors in Your Code

**Error 1: Relying only on the database to check the category**

```rust
// Wrong: no category_exists check before inserting
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return new_form_with_errors(&pool, form, errors).await,
    };

    let id = insert_task(&pool, &task).await?;
```

```rust
// Correct
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return new_form_with_errors(&pool, form, errors).await,
    };
    if !category_exists(&pool, task.category_id).await? {
        return new_form_with_errors(&pool, form, unknown_category()).await;
    }

    let id = insert_task(&pool, &task).await?;
```

Without the check, a request with `category_id=99` reaches MySQL, which correctly refuses it. The user gets the `500` page, and the server terminal shows:

```text
database error: error returned from database: 1452 (23000): Cannot add or update a child row: a foreign key constraint fails (`db_rust_todo`.`tasks`, CONSTRAINT `fk_tasks_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL)
```

The data stayed correct, thanks to the foreign key, but the user experience did not. Error 1452 in your logs means some code path saves a foreign key value without checking it first.

**Error 2: Dropping the column before the foreign key**

```sql
-- Wrong: down migration that only drops the column
ALTER TABLE tasks DROP COLUMN category_id;
```

```sql
-- Correct: drop the constraint first, then the column
ALTER TABLE tasks
    DROP FOREIGN KEY fk_tasks_category,
    DROP COLUMN category_id;
```

A column that is part of a foreign key cannot simply disappear. Running `sqlx migrate revert` with the wrong down migration fails:

```text
error: while executing migrations: error returned from database: 1553 (HY000): Cannot drop index 'fk_tasks_category': needed in a foreign key constraint
```

There is a second, sneakier problem. Because the revert failed partway, SQLx marks the migration as failed in `_sqlx_migrations`, and the next `sqlx migrate run`, or the next start of Todo Web, refuses to continue with `migration 20261101171656 is partially applied; fix and remove row from _sqlx_migrations table` (the application reports it as `Dirty(20261101171656)`). Here the failing statement changed nothing, so the schema is still fully migrated. After fixing the down file, tell SQLx that the migration is in fact applied:

```bash
mysql -u todo_user -p db_rust_todo -e "UPDATE _sqlx_migrations SET success = TRUE WHERE version = 20261101171656;"
```

This is one of the rare cases where you touch `_sqlx_migrations` by hand, and only after checking the real schema with `SHOW CREATE TABLE tasks;`. If the failed migration had changed part of the schema, you would first have to undo that part manually and then delete the row instead. Testing every down migration right after writing it, as you did in Section 2, avoids this situation entirely.

**Error 3: Comparing a String with a number in the template**

```html
<!-- Wrong -->
<option value="{{ category.id }}" {% if form.category_id == category.id %}selected{% endif %}>
```

```html
<!-- Correct -->
<option value="{{ category.id }}" {% if form.category_id == category.id.to_string() %}selected{% endif %}>
```

`form.category_id` is the raw form text, a `String`, and `category.id` is a `u64`. Rust does not compare different types implicitly, not even in templates:

```text
error[E0277]: can't compare `std::string::String` with `u64`
  --> src/main.rs:51:10
   |
51 | #[derive(Template)]
   |          ^^^^^^^^ no implementation for `std::string::String == u64`
   |
   = help: the trait `PartialEq<u64>` is not implemented for `std::string::String`
```

Convert one side so both are the same type. Converting the number to text works for every case, including an empty string or invalid input in the form.

---

## 9. Exercises

**Exercise 1:** Let users rename a category. On the categories page, replace each category name with a small form containing a text input with the current name and a "Rename" button, posting to `/categories/{id}/rename`. Handle an empty name and a duplicate name with a message on the categories page, and a missing category with the 404 page.

**Exercise 2:** Show how many tasks each category has, for example `Work (2 tasks)`. Use a new `CategorySummary` struct with a `task_count: i64` field and a query with a subquery in the `SELECT` list: `(SELECT COUNT(*) FROM tasks t WHERE t.category_id = c.id) AS task_count`.

**Exercise 3:** Below the list on the categories page, show the number of tasks without a category, using a `count_uncategorized` query.

---

## 10. Solutions

The three exercises all change the categories page, so they are solved together.

**Solution for Exercise 1, Exercise 2, and Exercise 3:**

Add the summary struct below `Category`:

```rust
#[derive(sqlx::FromRow)]
struct CategorySummary {
    id: u64,
    name: String,
    task_count: i64,
}
```

Change the categories template struct to use it and to carry the uncategorized count:

```rust
#[derive(Template)]
#[template(path = "categories/list.html")]
struct CategoryListTemplate {
    categories: Vec<CategorySummary>,
    uncategorized: i64,
    name: String,
    error: Option<String>,
}
```

Add three queries below `all_categories`:

```rust
async fn category_summaries(pool: &MySqlPool) -> Result<Vec<CategorySummary>, sqlx::Error> {
    sqlx::query_as::<_, CategorySummary>(
        "SELECT c.id, c.name,
                (SELECT COUNT(*) FROM tasks t WHERE t.category_id = c.id) AS task_count
         FROM categories c
         ORDER BY c.name",
    )
    .fetch_all(pool)
    .await
}

async fn count_uncategorized(pool: &MySqlPool) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar("SELECT COUNT(*) FROM tasks WHERE category_id IS NULL")
        .fetch_one(pool)
        .await
}

async fn rename_category(pool: &MySqlPool, id: u64, name: &str) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE categories SET name = ? WHERE id = ?")
        .bind(name)
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}
```

Three handlers now render the categories page, so a helper builds the template. Replace `list_categories` with these two functions, and add the rename handler:

```rust
async fn category_page(
    pool: &MySqlPool,
    name: String,
    error: Option<&str>,
) -> Result<CategoryListTemplate, AppError> {
    let categories = category_summaries(pool).await?;
    let uncategorized = count_uncategorized(pool).await?;
    Ok(CategoryListTemplate { categories, uncategorized, name, error: error.map(String::from) })
}

async fn list_categories(State(pool): State<MySqlPool>) -> Result<Response, AppError> {
    render(category_page(&pool, String::new(), None).await?)
}

async fn save_category_name(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
    Form(form): Form<CategoryForm>,
) -> Result<Response, AppError> {
    let name = form.name.trim();
    let error = if name.is_empty() {
        Some("Name is required.")
    } else {
        match rename_category(&pool, id, name).await {
            Ok(true) => None,
            Ok(false) => return Err(AppError::NotFound),
            Err(sqlx::Error::Database(err)) if err.is_unique_violation() => {
                Some("A category with this name already exists.")
            }
            Err(err) => return Err(err.into()),
        }
    };
    match error {
        None => Ok(Redirect::to("/categories").into_response()),
        Some(message) => {
            let page = category_page(&pool, String::new(), Some(message)).await?;
            Ok((StatusCode::UNPROCESSABLE_ENTITY, render(page)?).into_response())
        }
    }
}
```

In `create_category`, use the helper in the error branch:

```rust
        Some(message) => {
            let page = category_page(&pool, form.name, Some(message)).await?;
            Ok((StatusCode::UNPROCESSABLE_ENTITY, render(page)?).into_response())
        }
```

Register the rename route:

```rust
        .route("/categories/{id}/rename", post(save_category_name))
```

And replace `templates/categories/list.html`:

```html
{% extends "base.html" %}

{% block title %}Categories - Todo Web{% endblock %}

{% block content %}
<h1>Categories</h1>

<form method="post" action="/categories">
  <label for="name">New category</label>
  <input id="name" name="name" value="{{ name }}" placeholder="Work, Home, Study...">
  <button type="submit">Add</button>
  {% if let Some(error) = error %}<br><strong>{{ error }}</strong>{% endif %}
</form>

{% if categories.is_empty() %}
  <p>No categories yet.</p>
{% else %}
  <ul>
    {% for category in categories %}
      <li>
        <form method="post" action="/categories/{{ category.id }}/rename" style="display: inline">
          <input name="name" value="{{ category.name }}">
          <button type="submit">Rename</button>
        </form>
        ({{ category.task_count }} tasks)
        <form method="post" action="/categories/{{ category.id }}/delete" style="display: inline">
          <button type="submit">Delete</button>
        </form>
      </li>
    {% endfor %}
  </ul>
{% endif %}
<p>Tasks without a category: {{ uncategorized }}</p>
{% endblock %}
```

How it works:

- The subquery in `category_summaries` runs once per category and counts the tasks that point to it. `AS task_count` names the result column, so `FromRow` can match it to the struct field. `c` and `t` are short aliases for the two tables, which keep the query readable when two tables appear in it. In Lesson 16, you will see `JOIN` with `GROUP BY` as another way to get the same counts.
- `IS NULL` is required to find tasks without a category; `= NULL` never matches anything in SQL.
- Renaming hits the same `UNIQUE` constraint as creating, so the same `is_unique_violation` check applies. `Ok(false)` from `rename_category` means no row had that ID, which becomes the 404 page. Because SQLx counts matched rows (Lesson 12), renaming a category to its current name still returns `Ok(true)`.
- `error.map(String::from)` turns an `Option<&str>` into an `Option<String>` for the template.

With Work holding two tasks and Study one, the list on the page contains:

```text
          <input name="name" value="Home">
        (0 tasks)
          <input name="name" value="Study">
        (1 tasks)
          <input name="name" value="Work">
        (2 tasks)
<p>Tasks without a category: 2</p>
```

Renaming Study (ID 3) works, and renaming it to an existing name is refused:

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -d "name=Learning" http://127.0.0.1:3000/categories/3/rename
curl -s -d "name=Home" http://127.0.0.1:3000/categories/3/rename | grep strong
```

Output:

```text
303 http://127.0.0.1:3000/categories
  <br><strong>A category with this name already exists.</strong>
```

---

## Next Up - Lesson 16

In this lesson, you added a `categories` table and linked tasks to it with a foreign key and `ON DELETE SET NULL`, built a categories page that relies on the `UNIQUE` constraint to reject duplicates, added a category drop-down to the task forms, and validated the selected category in two stages.

The task list still does not show categories, and with more tasks it becomes hard to find anything. In Lesson 16, you will show each task's category name in the list with a single `JOIN` query, filter tasks by status and category, search titles with `LIKE`, and split long lists into pages with `LIMIT` and `OFFSET`, building the query safely with SQLx's `QueryBuilder`.
