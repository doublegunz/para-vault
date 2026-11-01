## 1. Before You Begin

Todo Web works: it lists, filters, creates, edits, toggles, and deletes tasks, manages categories, validates forms, and turns every failure into a proper error page. But all of that lives in one file. At the end of Lesson 16, `src/main.rs` had 692 lines: data structs, validation rules, SQL queries, template structs, the error type, nineteen handlers, and `main`. Finding anything means scrolling, every change touches the same file, and it is hard to see which parts depend on which.

In this lesson, you will reorganize the project into modules, using the module system from the first course. Each module gets one responsibility: data types, database queries, templates, errors, handlers, routes, and shared state. You will also replace the bare `MySqlPool` state with an `AppState` struct, which gives the application one obvious place to add shared resources later. The behavior of Todo Web does not change at all. That is the point of a refactoring, and the tests and a quick check of every page will prove it.

### What You'll Build

The same Todo Web, now split into eight files under `src/`: `main.rs` (startup only), `state.rs`, `models.rs`, `db.rs`, `templates.rs`, `error.rs`, `handlers.rs`, and `routes.rs`, with handlers that receive `State<AppState>` and a router built by one function, `routes::app`.

### What You'll Learn

- ✅ How to split a binary crate into modules with `mod` declarations and separate files
- ✅ How `pub` controls what other modules can use, including struct fields
- ✅ How to import items across modules with `use crate::...`
- ✅ How to group shared resources in an `AppState` struct and extract it with `State<AppState>`
- ✅ How to build the router in a dedicated function
- ✅ How to refactor safely, checking behavior before and after

### What You'll Need

- The `todo-web` project from Lesson 16, with all tests passing
- Modules and `pub` from the first course
- Git, so you can compare the result with the previous commit

---

## 2. Plan the Modules

Before moving code, decide where everything goes. A good rule is to group code by what it is responsible for, so that a change to one concern touches one file.

### Step 1: Check the Starting Point

Make sure the current version is committed and the tests pass, so you have a safe point to return to:

```bash
git status --short
cargo test
```

`git status --short` should print nothing, and the tests should report `8 passed`. If anything goes wrong during the refactoring, `git checkout -- src` brings back the working single-file version.

### Step 2: Map the Code to Modules

Here is the plan for the eight files:

| File | Responsibility | Contains |
| --- | --- | --- |
| `main.rs` | Startup | `mod` declarations, loading `.env`, the pool, migrations, starting the server |
| `state.rs` | Shared state | `AppState` |
| `models.rs` | Data and rules | `Task`, `TaskRow`, `Category`, form and filter structs, `validate_task`, its tests |
| `db.rs` | Database access | every SQL query, `escape_like`, `push_filters` |
| `templates.rs` | Pages | all `#[derive(Template)]` structs and `render` |
| `error.rs` | Failures | `AppError` with its `From` and `IntoResponse` implementations |
| `handlers.rs` | HTTP logic | every handler and the form re-render helpers |
| `routes.rs` | URL map | the `app` function that builds the router |

The dependencies flow in one direction: handlers use the database functions, models, templates, and errors; routes use handlers; `main` uses routes. The models do not know about HTTP, and the database code does not know about templates. Keeping it that way makes each part easier to understand and test on its own.

---

## 3. Create the Shared State and the Data Modules

The files that depend on nothing else in the project come first. Each new file becomes a module once `main.rs` declares it with `mod`, which happens in Section 5. Until then, the project will not compile, so write all the files before building.

### Step 1: Create AppState

Create `src/state.rs`:

```rust
use sqlx::MySqlPool;

#[derive(Clone)]
pub struct AppState {
    pub pool: MySqlPool,
}
```

`AppState` holds everything handlers share. Today that is only the pool, but a real application soon needs more: a configuration value, an HTTP client for another service, a cache. With a struct, adding one is a new field, and no handler signature has to change. `#[derive(Clone)]` is required, because Axum clones the state for every request; cloning a `MySqlPool` only copies a handle, as you saw in Lesson 7. The struct and its field are `pub`, so other modules can create and read it.

### Step 2: Create the Models Module

Create `src/models.rs` and move the data types, the filter cleaning, and the validation into it, together with the validation tests:

```rust
use chrono::{NaiveDate, NaiveDateTime};
use serde::Deserialize;

#[derive(sqlx::FromRow)]
pub struct Task {
    pub id: u64,
    pub title: String,
    pub done: bool,
    pub due_date: Option<NaiveDate>,
    pub created_at: NaiveDateTime,
    pub category_id: Option<u64>,
}

#[derive(sqlx::FromRow)]
pub struct TaskRow {
    pub id: u64,
    pub title: String,
    pub done: bool,
    pub due_date: Option<NaiveDate>,
    pub category_name: Option<String>,
}

#[derive(sqlx::FromRow)]
pub struct Category {
    pub id: u64,
    pub name: String,
}

#[derive(Deserialize)]
pub struct TaskFilter {
    pub search: Option<String>,
    pub status: Option<String>,
    pub category: Option<String>,
    pub page: Option<u64>,
}

pub struct ListFilter {
    pub search: String,
    pub status: String,
    pub category: String,
    pub category_id: Option<u64>,
    pub page: u64,
}

pub const PER_PAGE: u64 = 5;

impl ListFilter {
    pub fn from_query(query: TaskFilter) -> Self {
        let status = match query.status.as_deref() {
            Some("pending") => "pending",
            Some("done") => "done",
            _ => "all",
        };
        let category = query.category.unwrap_or_default();
        let category_id = category.trim().parse::<u64>().ok();
        ListFilter {
            search: query.search.unwrap_or_default().trim().to_string(),
            status: status.to_string(),
            category,
            category_id,
            page: query.page.unwrap_or(1).max(1),
        }
    }
}

#[derive(Deserialize, Default)]
pub struct TaskForm {
    pub title: String,
    pub due_date: String,
    #[serde(default)]
    pub category_id: String,
}

#[derive(Deserialize)]
pub struct CategoryForm {
    pub name: String,
}

#[derive(Default, Debug, PartialEq)]
pub struct FormErrors {
    pub title: Option<String>,
    pub due_date: Option<String>,
    pub category_id: Option<String>,
}

impl FormErrors {
    pub fn unknown_category() -> Self {
        FormErrors {
            category_id: Some(String::from("Please choose a category from the list.")),
            ..FormErrors::default()
        }
    }
}

#[derive(Debug, PartialEq)]
pub struct ValidTask {
    pub title: String,
    pub due_date: Option<NaiveDate>,
    pub category_id: Option<u64>,
}

pub fn validate_task(form: &TaskForm) -> Result<ValidTask, FormErrors> {
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
}

#[cfg(test)]
mod tests {
    use super::*;

    fn form(title: &str, due_date: &str) -> TaskForm {
        TaskForm {
            title: title.to_string(),
            due_date: due_date.to_string(),
            category_id: String::new(),
        }
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

The code is the same as before, with three kinds of changes:

- **`pub` everywhere it is needed.** Items in a module are private by default: other modules cannot see them. Every struct, constant, and function used elsewhere gets `pub`. Struct fields are private too, even when the struct is public, so every field that handlers, queries, or templates read gets `pub` as well.
- **Imports.** The module brings in only what it uses: `chrono` types and serde's `Deserialize`. It needs nothing from Axum or SQLx except the `sqlx::FromRow` derive.
- **`unknown_category` became an associated function**, `FormErrors::unknown_category()`. It builds a `FormErrors` value, so it belongs with that type.

The validation tests moved along with `validate_task`. `use super::*;` now imports everything from `models`, which is exactly what the tests need. The test for `escape_like` moves to the `db` module in the next step.

### Step 3: Create the Database Module

Create `src/db.rs` with every query function:

```rust
use sqlx::{MySql, MySqlPool, QueryBuilder};

use crate::models::{Category, ListFilter, PER_PAGE, Task, TaskRow, ValidTask};

fn escape_like(text: &str) -> String {
    text.replace('\\', "\\\\")
        .replace('%', "\\%")
        .replace('_', "\\_")
}

fn push_filters(builder: &mut QueryBuilder<MySql>, filter: &ListFilter) {
    builder.push(" WHERE 1 = 1");
    if !filter.search.is_empty() {
        builder.push(" AND t.title LIKE ");
        builder.push_bind(format!("%{}%", escape_like(&filter.search)));
    }
    match filter.status.as_str() {
        "pending" => {
            builder.push(" AND t.done = FALSE");
        }
        "done" => {
            builder.push(" AND t.done = TRUE");
        }
        _ => {}
    }
    if let Some(category_id) = filter.category_id {
        builder.push(" AND t.category_id = ");
        builder.push_bind(category_id);
    }
}

pub async fn count_filtered_tasks(pool: &MySqlPool, filter: &ListFilter) -> Result<i64, sqlx::Error> {
    let mut builder = QueryBuilder::<MySql>::new("SELECT COUNT(*) FROM tasks t");
    push_filters(&mut builder, filter);
    builder.build_query_scalar::<i64>().fetch_one(pool).await
}

pub async fn filtered_tasks(pool: &MySqlPool, filter: &ListFilter) -> Result<Vec<TaskRow>, sqlx::Error> {
    let mut builder = QueryBuilder::<MySql>::new(
        "SELECT t.id, t.title, t.done, t.due_date, c.name AS category_name
         FROM tasks t
         LEFT JOIN categories c ON c.id = t.category_id",
    );
    push_filters(&mut builder, filter);
    builder.push(" ORDER BY t.done, t.id LIMIT ");
    builder.push_bind(PER_PAGE);
    builder.push(" OFFSET ");
    builder.push_bind((filter.page - 1) * PER_PAGE);
    builder.build_query_as::<TaskRow>().fetch_all(pool).await
}

pub async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
    sqlx::query_as::<_, Task>(
        "SELECT id, title, done, due_date, created_at, category_id FROM tasks WHERE id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub async fn count_tasks(pool: &MySqlPool) -> Result<(i64, i64), sqlx::Error> {
    let total = sqlx::query_scalar("SELECT COUNT(*) FROM tasks")
        .fetch_one(pool)
        .await?;
    let pending = sqlx::query_scalar("SELECT COUNT(*) FROM tasks WHERE done = FALSE")
        .fetch_one(pool)
        .await?;
    Ok((total, pending))
}

pub async fn insert_task(pool: &MySqlPool, task: &ValidTask) -> Result<u64, sqlx::Error> {
    let result =
        sqlx::query("INSERT INTO tasks (title, due_date, category_id) VALUES (?, ?, ?)")
            .bind(&task.title)
            .bind(task.due_date)
            .bind(task.category_id)
            .execute(pool)
            .await?;
    Ok(result.last_insert_id())
}

pub async fn update_task(pool: &MySqlPool, id: u64, task: &ValidTask) -> Result<bool, sqlx::Error> {
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

pub async fn toggle_task(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("UPDATE tasks SET done = NOT done WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

pub async fn delete_task(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM tasks WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

pub async fn all_categories(pool: &MySqlPool) -> Result<Vec<Category>, sqlx::Error> {
    sqlx::query_as::<_, Category>("SELECT id, name FROM categories ORDER BY name")
        .fetch_all(pool)
        .await
}

pub async fn find_category(pool: &MySqlPool, id: u64) -> Result<Option<Category>, sqlx::Error> {
    sqlx::query_as::<_, Category>("SELECT id, name FROM categories WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn insert_category(pool: &MySqlPool, name: &str) -> Result<u64, sqlx::Error> {
    let result = sqlx::query("INSERT INTO categories (name) VALUES (?)")
        .bind(name)
        .execute(pool)
        .await?;
    Ok(result.last_insert_id())
}

pub async fn delete_category(pool: &MySqlPool, id: u64) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM categories WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

pub async fn category_exists(pool: &MySqlPool, category_id: Option<u64>) -> Result<bool, sqlx::Error> {
    match category_id {
        Some(id) => Ok(find_category(pool, id).await?.is_some()),
        None => Ok(true),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn escapes_like_wildcards() {
        assert_eq!(escape_like("100%_done"), "100\\%\\_done");
    }
}
```

The queries are unchanged. The public query functions get `pub`; `escape_like` and `push_filters` stay private, because only the query functions in this file use them. Tests in the same file can still call private functions, so the `escape_like` test lives here. The `use crate::models::{...}` line imports the types the queries read and write. `crate` refers to the root of your own project, so `crate::models` means "the `models` module of this crate."

---

## 4. Create the Templates, Errors, and Handlers

These three modules depend on each other a little: templates need models, `render` returns an `AppError`, and the error type renders a template. Rust allows modules to refer to each other like this, as long as there is no cycle between types.

### Step 1: Create the Templates Module

Create `src/templates.rs`:

```rust
use askama::Template;
use axum::response::{Html, IntoResponse, Response};

use crate::error::AppError;
use crate::models::{Category, FormErrors, ListFilter, Task, TaskForm, TaskRow};

#[derive(Template)]
#[template(path = "home.html")]
pub struct HomeTemplate {
    pub pending: i64,
    pub total: i64,
}

#[derive(Template)]
#[template(path = "tasks/list.html")]
pub struct TaskListTemplate {
    pub tasks: Vec<TaskRow>,
    pub categories: Vec<Category>,
    pub filter: ListFilter,
    pub total: i64,
    pub pages: u64,
}

#[derive(Template)]
#[template(path = "tasks/show.html")]
pub struct TaskShowTemplate {
    pub task: Task,
    pub category: Option<Category>,
}

#[derive(Template)]
#[template(path = "tasks/new.html")]
pub struct NewTaskTemplate {
    pub form: TaskForm,
    pub errors: FormErrors,
    pub categories: Vec<Category>,
}

#[derive(Template)]
#[template(path = "tasks/edit.html")]
pub struct EditTaskTemplate {
    pub id: u64,
    pub form: TaskForm,
    pub errors: FormErrors,
    pub categories: Vec<Category>,
}

#[derive(Template)]
#[template(path = "categories/list.html")]
pub struct CategoryListTemplate {
    pub categories: Vec<Category>,
    pub name: String,
    pub error: Option<String>,
}

#[derive(Template)]
#[template(path = "error.html")]
pub struct ErrorTemplate {
    pub status: u16,
    pub title: &'static str,
    pub message: &'static str,
}

pub fn render<T: Template>(template: T) -> Result<Response, AppError> {
    let html = template.render()?;
    Ok(Html(html).into_response())
}
```

All template structs are `pub`, with `pub` fields, because handlers build them. `render` lives here too, since it is the bridge between templates and responses. It returns `Result<Response, AppError>`, so the module imports `AppError` from `crate::error`.

### Step 2: Create the Error Module

Create `src/error.rs`:

```rust
use askama::Template;
use axum::{
    http::StatusCode,
    response::{Html, IntoResponse, Response},
};

use crate::templates::ErrorTemplate;

pub enum AppError {
    NotFound,
    Database(sqlx::Error),
    Template(askama::Error),
}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::Database(err)
    }
}

impl From<askama::Error> for AppError {
    fn from(err: askama::Error) -> Self {
        AppError::Template(err)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, title, message) = match self {
            AppError::NotFound => (
                StatusCode::NOT_FOUND,
                "Not Found",
                "The page or task you are looking for does not exist.",
            ),
            AppError::Database(err) => {
                eprintln!("database error: {err}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
            AppError::Template(err) => {
                eprintln!("template error: {err}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Server Error",
                    "Something went wrong on our side. Please try again later.",
                )
            }
        };

        let page = ErrorTemplate { status: status.as_u16(), title, message };
        match page.render() {
            Ok(html) => (status, Html(html)).into_response(),
            Err(_) => (status, message).into_response(),
        }
    }
}
```

`AppError` is unchanged apart from `pub`. Variants of a public enum are automatically public, so `AppError::NotFound` can be used everywhere without extra `pub` keywords. The module imports `askama::Template`, because calling `page.render()` requires the trait to be in scope.

### Step 3: Create the Handlers Module

Create `src/handlers.rs`:

```rust
use axum::{
    Form,
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Redirect, Response},
};

use crate::db;
use crate::error::AppError;
use crate::models::{
    CategoryForm, FormErrors, ListFilter, PER_PAGE, TaskFilter, TaskForm, validate_task,
};
use crate::state::AppState;
use crate::templates::{
    CategoryListTemplate, EditTaskTemplate, HomeTemplate, NewTaskTemplate, TaskListTemplate,
    TaskShowTemplate, render,
};

pub async fn home(State(state): State<AppState>) -> Result<Response, AppError> {
    let (total, pending) = db::count_tasks(&state.pool).await?;
    render(HomeTemplate { pending, total })
}

pub async fn health(State(state): State<AppState>) -> (StatusCode, String) {
    match sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&state.pool).await {
        Ok(_) => (StatusCode::OK, String::from("ok: database reachable")),
        Err(err) => (StatusCode::SERVICE_UNAVAILABLE, format!("database error: {err}")),
    }
}

pub async fn list_tasks(
    State(state): State<AppState>,
    Query(query): Query<TaskFilter>,
) -> Result<Response, AppError> {
    let filter = ListFilter::from_query(query);
    let total = db::count_filtered_tasks(&state.pool, &filter).await?;
    let pages = (total as u64).div_ceil(PER_PAGE).max(1);
    let tasks = db::filtered_tasks(&state.pool, &filter).await?;
    let categories = db::all_categories(&state.pool).await?;
    render(TaskListTemplate { tasks, categories, filter, total, pages })
}

pub async fn show_task(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = db::find_task(&state.pool, id).await?.ok_or(AppError::NotFound)?;
    let category = match task.category_id {
        Some(category_id) => db::find_category(&state.pool, category_id).await?,
        None => None,
    };
    render(TaskShowTemplate { task, category })
}

pub async fn new_task_form(State(state): State<AppState>) -> Result<Response, AppError> {
    let categories = db::all_categories(&state.pool).await?;
    render(NewTaskTemplate { form: TaskForm::default(), errors: FormErrors::default(), categories })
}

async fn new_form_with_errors(
    state: &AppState,
    form: TaskForm,
    errors: FormErrors,
) -> Result<Response, AppError> {
    let categories = db::all_categories(&state.pool).await?;
    let page = render(NewTaskTemplate { form, errors, categories })?;
    Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response())
}

async fn edit_form_with_errors(
    state: &AppState,
    id: u64,
    form: TaskForm,
    errors: FormErrors,
) -> Result<Response, AppError> {
    let categories = db::all_categories(&state.pool).await?;
    let page = render(EditTaskTemplate { id, form, errors, categories })?;
    Ok((StatusCode::UNPROCESSABLE_ENTITY, page).into_response())
}

pub async fn create_task(
    State(state): State<AppState>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return new_form_with_errors(&state, form, errors).await,
    };
    if !db::category_exists(&state.pool, task.category_id).await? {
        return new_form_with_errors(&state, form, FormErrors::unknown_category()).await;
    }

    let id = db::insert_task(&state.pool, &task).await?;
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

pub async fn edit_task_form(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = db::find_task(&state.pool, id).await?.ok_or(AppError::NotFound)?;
    let form = TaskForm {
        title: task.title,
        due_date: task.due_date.map(|date| date.to_string()).unwrap_or_default(),
        category_id: task.category_id.map(|id| id.to_string()).unwrap_or_default(),
    };
    let categories = db::all_categories(&state.pool).await?;
    render(EditTaskTemplate { id, form, errors: FormErrors::default(), categories })
}

pub async fn save_task(
    State(state): State<AppState>,
    Path(id): Path<u64>,
    Form(form): Form<TaskForm>,
) -> Result<Response, AppError> {
    let task = match validate_task(&form) {
        Ok(task) => task,
        Err(errors) => return edit_form_with_errors(&state, id, form, errors).await,
    };
    if !db::category_exists(&state.pool, task.category_id).await? {
        return edit_form_with_errors(&state, id, form, FormErrors::unknown_category()).await;
    }

    if !db::update_task(&state.pool, id, &task).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to(&format!("/tasks/{id}")).into_response())
}

pub async fn toggle_done(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !db::toggle_task(&state.pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/tasks"))
}

pub async fn remove_task(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !db::delete_task(&state.pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/tasks"))
}

pub async fn list_categories(State(state): State<AppState>) -> Result<Response, AppError> {
    let categories = db::all_categories(&state.pool).await?;
    render(CategoryListTemplate { categories, name: String::new(), error: None })
}

pub async fn create_category(
    State(state): State<AppState>,
    Form(form): Form<CategoryForm>,
) -> Result<Response, AppError> {
    let name = form.name.trim();
    let error = if name.is_empty() {
        Some("Name is required.")
    } else if name.chars().count() > 100 {
        Some("Name must be at most 100 characters.")
    } else {
        match db::insert_category(&state.pool, name).await {
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
            let categories = db::all_categories(&state.pool).await?;
            let page = CategoryListTemplate {
                categories,
                name: form.name,
                error: Some(message.to_string()),
            };
            Ok((StatusCode::UNPROCESSABLE_ENTITY, render(page)?).into_response())
        }
    }
}

pub async fn remove_category(
    State(state): State<AppState>,
    Path(id): Path<u64>,
) -> Result<Redirect, AppError> {
    if !db::delete_category(&state.pool, id).await? {
        return Err(AppError::NotFound);
    }
    Ok(Redirect::to("/categories"))
}

pub async fn not_found() -> AppError {
    AppError::NotFound
}
```

Here is what changed in the handlers:

- **`State<AppState>` instead of `State<MySqlPool>`.** Every handler now extracts the whole state as `State(state)` and passes `&state.pool` to the queries. The helpers take `&AppState` too.
- **Queries are called through their module**, as in `db::count_tasks(...)`. The line `use crate::db;` imports the module itself rather than each function, so every call says where it comes from. Reading `db::delete_task` makes it obvious that the line talks to the database.
- **Handlers are `pub`**, because the router in `routes.rs` refers to them. The two form helpers stay private, since only handlers in this file use them.
- `FormErrors::unknown_category()` replaces the old free function.

---

## 5. Build the Router and Slim Down main

The last two files connect everything.

### Step 1: Create the Routes Module

Create `src/routes.rs`:

```rust
use axum::{
    Router,
    routing::{get, post},
};

use crate::handlers;
use crate::state::AppState;

pub fn app(state: AppState) -> Router {
    Router::new()
        .route("/", get(handlers::home))
        .route("/health", get(handlers::health))
        .route("/tasks", get(handlers::list_tasks).post(handlers::create_task))
        .route("/tasks/new", get(handlers::new_task_form))
        .route("/tasks/{id}", get(handlers::show_task))
        .route("/tasks/{id}/edit", get(handlers::edit_task_form).post(handlers::save_task))
        .route("/tasks/{id}/toggle", post(handlers::toggle_done))
        .route("/tasks/{id}/delete", post(handlers::remove_task))
        .route("/categories", get(handlers::list_categories).post(handlers::create_category))
        .route("/categories/{id}/delete", post(handlers::remove_category))
        .fallback(handlers::not_found)
        .with_state(state)
}
```

`app` takes the state and returns a complete `Router`. The return type is `Router` (short for `Router<()>`): after `.with_state(state)`, the router no longer waits for any state, so it is ready to serve. Having the router in a function, not inside `main`, matters for Lesson 18: tests can call `routes::app(...)` with a test database and send requests to it without starting a real server.

### Step 2: Rewrite main.rs

Replace all of `src/main.rs` with:

```rust
mod db;
mod error;
mod handlers;
mod models;
mod routes;
mod state;
mod templates;

use sqlx::mysql::MySqlPoolOptions;

use crate::state::AppState;

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

    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("migrations should run");
    println!("Migrations are up to date");

    let app = routes::app(AppState { pool });

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

`main.rs` is now short enough to read in one glance:

- The `mod` lines declare the modules. `mod db;` tells the compiler to load `src/db.rs` as a module named `db`. Without a `mod` line, a file in `src/` is simply ignored. The order of the declarations does not matter.
- `use crate::state::AppState;` brings the struct into scope.
- `main` keeps only the startup steps: read the configuration, create the pool, run the migrations, build the app with `routes::app(AppState { pool })`, and serve it.

---

## 6. Run and Test

A refactoring is only finished when it is proven that nothing changed for the user.

### Step 1: Build and Run the Tests

```bash
cargo test
```

Output after the compilation lines:

```text

running 8 tests
test db::tests::escapes_like_wildcards ... ok
test models::tests::parses_the_category_id ... ok
test models::tests::empty_due_date_means_none ... ok
test models::tests::accepts_a_title_and_a_date ... ok
test models::tests::rejects_a_category_id_that_is_not_a_number ... ok
test models::tests::rejects_a_blank_title ... ok
test models::tests::rejects_a_title_that_is_too_long ... ok
test models::tests::reports_both_errors_at_once ... ok

test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

The same eight tests pass, but their names now include the module path, such as `models::tests::accepts_a_title_and_a_date` and `db::tests::escapes_like_wildcards`. The build should also produce no warnings; an "unused" warning would mean something was left behind or a `pub` is missing.

### Step 2: Check Every Page

Start the server with `cargo run`. Its output is exactly as before:

```text
Connected to MySQL
Migrations are up to date
Todo Web running on http://127.0.0.1:3000
```

In a second terminal, request each kind of page and print only the status codes:

```bash
for u in / /tasks /tasks/2 /tasks/new /categories /tasks/999 /health; do
  curl -s -o /dev/null -w "$u %{http_code}\n" http://127.0.0.1:3000$u
done
curl -s -o /dev/null -w "POST %{http_code}\n" -d "title=&due_date=" http://127.0.0.1:3000/tasks
```

The `for` loop runs the same `curl` command for each path in the list, and `$u` inside the `-w` text prints the path next to its status.

Output:

```text
/ 200
/tasks 200
/tasks/2 200
/tasks/new 200
/categories 200
/tasks/999 404
/health 200
POST 422
```

Every page answers with the same status as before the refactoring: pages load, a missing task gives `404`, the health check works, and an invalid form still gets `422`. Click through the application in the browser as well. Stop the server with `Ctrl+C`.

### Step 3: Review and Commit

Look at the new structure:

```bash
wc -l src/*.rs
```

Output:

```text
  154 db.rs
   59 error.rs
  200 handlers.rs
   39 main.rs
  201 models.rs
   23 routes.rs
    6 state.rs
   67 templates.rs
  749 total
```

The total grew a little, because of the `use` lines and `pub` keywords, but no file is longer than about 200 lines, and each one has a clear job. Commit the refactoring as its own commit, separate from any feature work, so the history shows that this change only moved code:

```bash
git add -A
git commit -m "lesson 17: modules and AppState"
```

---

## 7. Modules and Visibility in Practice

The module system is the same one you used for the command-line to-do list, now applied to a larger program. A few rules explain almost every error you might see while splitting code:

- **Files become modules only through `mod`.** `mod db;` in `main.rs` looks for `src/db.rs` (or `src/db/mod.rs`). A file without a matching `mod` line is not compiled at all.
- **Everything is private by default.** Functions, structs, constants, and struct fields are visible only inside their own module and its child modules (such as `tests`). `pub` makes an item visible to the rest of the crate.
- **Making a struct public does not make its fields public.** Each field needs its own `pub` if other modules read or set it. Enum variants are the exception: they are public whenever the enum is.
- **Paths start at the crate root.** `crate::models::Task` names the `Task` struct in the `models` module from anywhere in the project. `super::` refers to the parent module, which is why tests use `use super::*;`.
- **Import modules for functions, items for types.** A common style, used here, is to import a module for its functions (`use crate::db;`, then `db::find_task(...)`) and to import types directly (`use crate::models::TaskForm;`).

Why `AppState` instead of `MySqlPool`? The router's state type appears in every `State<...>` extractor. With a struct, the type stays the same no matter how many resources you add, so adding a field never touches the handlers that do not use it. For large states, Axum also offers `FromRef`, which lets a handler extract just one field, such as `State<MySqlPool>`, from a bigger state struct.

---

## 8. Fix the Errors in Your Code

**Error 1: Calling a private function from another module**

```rust
// Wrong: in src/db.rs, find_task is not pub
async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
```

```rust
// Correct
pub async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
```

After moving the function into `db.rs`, the handlers can no longer call it:

```text
error[E0603]: function `find_task` is private
  --> src/handlers.rs:47:20
   |
47 |     let task = db::find_task(&state.pool, id).await?.ok_or(AppError::NotFound)?;
   |                    ^^^^^^^^^ private function
   |
note: the function `find_task` is defined here
  --> src/db.rs:52:1
   |
52 | async fn find_task(pool: &MySqlPool, id: u64) -> Result<Option<Task>, sqlx::Error> {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

The note points to the definition, which is where the `pub` belongs. The same error appears once for every call, so one missing `pub` can produce several errors.

**Error 2: Forgetting the mod declaration**

```rust
// Wrong: src/main.rs without mod db;
mod error;
mod handlers;
```

```rust
// Correct
mod db;
mod error;
mod handlers;
```

Without the declaration, `src/db.rs` is not part of the program, and every `use crate::db` fails:

```text
error[E0432]: unresolved import `crate::db`
 --> src/handlers.rs:8:5
  |
8 | use crate::db;
  |     ^^^^^^^--
  |            |
  |            no `db` in the root
```

`no db in the root` means the crate root, `main.rs`, has no module with that name. The compiler prints a few warnings after this error, such as `method call on a diverging inference variable`. They are side effects: the compiler cannot work out types that would come from the missing module. Fix the error and they disappear.

**Error 3: A public struct with a private field**

```rust
// Wrong: in src/models.rs, the title field is not pub
pub struct Task {
    pub id: u64,
    title: String,
```

```rust
// Correct
pub struct Task {
    pub id: u64,
    pub title: String,
```

The struct is visible, but its field is not:

```text
error[E0616]: field `title` of struct `Task` is private
   --> src/handlers.rs:103:21
    |
103 |         title: task.title,
    |                     ^^^^^ private field

error[E0616]: field `title` of struct `Task` is private
  --> src/templates.rs:24:10
   |
24 | #[derive(Template)]
   |          ^^^^^^^^ private field
   |
   = note: this error originates in the derive macro `Template` (in Nightly builds, run with -Z macro-backtrace for more info)
```

Two places read the field: the edit handler, and the generated code of the detail page template, which is why the second error points at `#[derive(Template)]` in `templates.rs`. Templates are Rust code too, so they follow the same visibility rules.

---

## 9. Exercises

**Exercise 1:** `handlers.rs` mixes task and category handlers. Turn `handlers` into a folder module: create `src/handlers/mod.rs`, `src/handlers/tasks.rs`, and `src/handlers/categories.rs`, move the handlers into the matching file, keep `not_found` in `mod.rs`, and update `routes.rs`.

**Exercise 2:** Add a `version: &'static str` field to `AppState`, fill it with `env!("CARGO_PKG_VERSION")` in `main`, and make the health check answer `ok: database reachable (Todo Web 0.1.0)`.

**Exercise 3:** Move the configuration loading out of `main` into a new `src/config.rs` module with a `Config` struct holding `database_url` and `address` (read from `APP_ADDR` with `127.0.0.1:3000` as the default, as in Lesson 7), and a `Config::from_env()` function.

---

## 10. Solutions

**Solution for Exercise 1:**

Create the folder `src/handlers`, move `src/handlers.rs` to `src/handlers/tasks.rs`, and remove the category handlers and `not_found` from it. Its imports become:

```rust
use axum::{
    Form,
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Redirect, Response},
};

use crate::db;
use crate::error::AppError;
use crate::models::{FormErrors, ListFilter, PER_PAGE, TaskFilter, TaskForm, validate_task};
use crate::state::AppState;
use crate::templates::{
    EditTaskTemplate, HomeTemplate, NewTaskTemplate, TaskListTemplate, TaskShowTemplate, render,
};
```

Create `src/handlers/categories.rs` with the three category handlers (`list_categories`, `create_category`, and `remove_category`, unchanged) below these imports:

```rust
use axum::{
    Form,
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Redirect, Response},
};

use crate::db;
use crate::error::AppError;
use crate::models::CategoryForm;
use crate::state::AppState;
use crate::templates::{CategoryListTemplate, render};
```

Create `src/handlers/mod.rs`:

```rust
pub mod categories;
pub mod tasks;

use crate::error::AppError;

pub async fn not_found() -> AppError {
    AppError::NotFound
}
```

And update `src/routes.rs`:

```rust
use axum::{
    Router,
    routing::{get, post},
};

use crate::handlers::{self, categories, tasks};
use crate::state::AppState;

pub fn app(state: AppState) -> Router {
    Router::new()
        .route("/", get(tasks::home))
        .route("/health", get(tasks::health))
        .route("/tasks", get(tasks::list_tasks).post(tasks::create_task))
        .route("/tasks/new", get(tasks::new_task_form))
        .route("/tasks/{id}", get(tasks::show_task))
        .route("/tasks/{id}/edit", get(tasks::edit_task_form).post(tasks::save_task))
        .route("/tasks/{id}/toggle", post(tasks::toggle_done))
        .route("/tasks/{id}/delete", post(tasks::remove_task))
        .route("/categories", get(categories::list_categories).post(categories::create_category))
        .route("/categories/{id}/delete", post(categories::remove_category))
        .fallback(handlers::not_found)
        .with_state(state)
}
```

When a module has submodules, its own code goes into `mod.rs` inside a folder of the same name. `mod handlers;` in `main.rs` stays the same; Rust finds `src/handlers/mod.rs` instead of `src/handlers.rs`. `pub mod tasks;` declares the submodules and makes them reachable as `handlers::tasks`. In `routes.rs`, `use crate::handlers::{self, categories, tasks};` imports the module itself (`self`, for `handlers::not_found`) and both submodules. Each file now imports only what it needs; the categories file, for example, no longer sees the task templates.

**Solution for Exercise 2:**

Add the field in `src/state.rs`:

```rust
use sqlx::MySqlPool;

#[derive(Clone)]
pub struct AppState {
    pub pool: MySqlPool,
    pub version: &'static str,
}
```

Fill it in `main`:

```rust
    let state = AppState { pool, version: env!("CARGO_PKG_VERSION") };
    let app = routes::app(state);
```

And use it in the health handler:

```rust
pub async fn health(State(state): State<AppState>) -> (StatusCode, String) {
    match sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&state.pool).await {
        Ok(_) => (
            StatusCode::OK,
            format!("ok: database reachable (Todo Web {})", state.version),
        ),
        Err(err) => (StatusCode::SERVICE_UNAVAILABLE, format!("database error: {err}")),
    }
}
```

No other handler changed, which is exactly the benefit of `AppState` described in Section 7. A `&'static str` is cheap to clone, so it adds nothing to the per-request cost.

```bash
curl -w "\n" http://127.0.0.1:3000/health
```

Output:

```text
ok: database reachable (Todo Web 0.1.0)
```

**Solution for Exercise 3:**

Create `src/config.rs`:

```rust
pub struct Config {
    pub database_url: String,
    pub address: String,
}

impl Config {
    pub fn from_env() -> Config {
        dotenvy::dotenv().ok();
        let database_url =
            std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");
        let address = std::env::var("APP_ADDR").unwrap_or_else(|_| String::from("127.0.0.1:3000"));
        Config { database_url, address }
    }
}
```

And use it in `src/main.rs`:

```rust
mod config;
mod db;
mod error;
mod handlers;
mod models;
mod routes;
mod state;
mod templates;

use sqlx::mysql::MySqlPoolOptions;

use crate::config::Config;
use crate::state::AppState;

#[tokio::main]
async fn main() {
    let config = Config::from_env();

    let pool = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&config.database_url)
        .await
        .expect("should connect to MySQL");
    println!("Connected to MySQL");

    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("migrations should run");
    println!("Migrations are up to date");

    let state = AppState { pool, version: env!("CARGO_PKG_VERSION") };
    let app = routes::app(state);

    let listener = tokio::net::TcpListener::bind(&config.address)
        .await
        .expect("address should be free");
    println!("Todo Web running on http://{}", config.address);

    axum::serve(listener, app).await.expect("server should run");
}
```

`main` now reads like a list of steps: load the configuration, connect, migrate, build the app, serve. All environment variables are read in one function, so it is easy to see every setting the application needs, which is also what a `.env.example` file should list. This version of `main` includes the `version` field from Exercise 2.

---

## Next Up - Lesson 18

In this lesson, you split Todo Web into eight focused modules, used `pub` on items and fields to control what each module exposes, imported across modules with `use crate::...`, replaced the bare pool with an `AppState` struct, and moved the router into a `routes::app` function. The tests and a status check of every page confirmed that nothing changed for the user.

The unit tests cover validation, but not the queries or the handlers, which are where most bugs in a web application hide. In Lesson 18, you will test database queries with `#[sqlx::test]`, which gives every test its own fresh database with all migrations applied, and test complete HTTP requests by sending them to `routes::app` with Tower's `oneshot`, without starting a server.
