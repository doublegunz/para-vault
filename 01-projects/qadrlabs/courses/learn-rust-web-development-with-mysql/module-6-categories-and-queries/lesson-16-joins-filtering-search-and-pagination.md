## 1. Before You Begin

In Lesson 15, tasks got categories, but the task list does not show them yet, and it still loads every task in one long page. With a dozen tasks, that is already hard to scan; with a few hundred, the page would be slow and useless. A real to-do app needs to answer questions such as "which Work tasks are still open?" and show the answer a few tasks at a time.

This lesson upgrades the task list into a proper query page. You will read each task's category name in the same query with a `LEFT JOIN`, filter by status and category, search titles with `LIKE`, and split the results into pages with `LIMIT` and `OFFSET`. Because the filters are optional, the SQL changes from request to request, and a fixed string literal is no longer enough. SQLx's `QueryBuilder` lets you assemble such a query piece by piece while every user value still travels as a bound parameter.

### What You'll Build

A task list with a filter form (search box, status drop-down, category drop-down), category names next to each task, a "12 tasks found" counter that respects the filters, five tasks per page, and Previous and Next links that keep the current filters.

### What You'll Learn

- ✅ How `JOIN` and `LEFT JOIN` combine rows from two tables
- ✅ How to read joined columns into a struct with `AS` aliases
- ✅ How to build queries with optional conditions using `QueryBuilder`, `push`, and `push_bind`
- ✅ How to escape `%` and `_` in `LIKE` searches
- ✅ How to paginate with `LIMIT`, `OFFSET`, and a separate `COUNT(*)` query
- ✅ How to keep filters in pagination links with Askama's `urlencode` filter

### What You'll Need

- The `todo-web` project from Lesson 15, with the categories Work, Home, and Study
- Enough tasks to fill more than one page; the next section adds some

---

## 2. Load Sample Data

Pagination and filters are only interesting with data. Add seven tasks spread across the three categories. The subqueries look up each category's ID by name, so the statement works no matter which IDs your categories have:

```bash
mysql -u todo_user -p db_rust_todo -e "
INSERT INTO tasks (title, done, due_date, category_id) VALUES
  ('Reply to client emails', FALSE, '2026-11-10', (SELECT id FROM categories WHERE name = 'Work')),
  ('Clean the kitchen', FALSE, NULL, (SELECT id FROM categories WHERE name = 'Home')),
  ('Pay the electricity bill', TRUE, '2026-11-05', (SELECT id FROM categories WHERE name = 'Home')),
  ('Finish chapter 3', FALSE, '2026-11-18', (SELECT id FROM categories WHERE name = 'Study')),
  ('Fix 100% CPU bug', FALSE, NULL, (SELECT id FROM categories WHERE name = 'Work')),
  ('Buy groceries', TRUE, NULL, (SELECT id FROM categories WHERE name = 'Home')),
  ('Review pull request', FALSE, '2026-11-08', (SELECT id FROM categories WHERE name = 'Work'));"
```

If one of the categories is missing, create it on the categories page first; otherwise its tasks get no category. The `100%` in one title is deliberate; Section 4 explains why.

### Step 1: Try a JOIN by Hand

Before writing Rust, run the query that the new task list will be based on:

```bash
mysql -u todo_user -p db_rust_todo -e "SELECT t.id, t.title, t.done, c.name FROM tasks t LEFT JOIN categories c ON c.id = t.category_id ORDER BY t.done, t.id;"
```

Output:

```text
id	title	done	name
2	Build a web app	0	Work
4	Write the first handler test	0	NULL
8	Read the Axum docs	0	NULL
16	Prepare slides	0	Work
18	Reply to client emails	0	Work
19	Clean the kitchen	0	Home
21	Finish chapter 3	0	Study
22	Fix 100% CPU bug	0	Work
24	Review pull request	0	Work
13	Learn Rust	1	Study
20	Pay the electricity bill	1	Home
23	Buy groceries	1	Home
```

Your IDs and the first few tasks depend on what you created in earlier lessons. Here is how the query works:

- `FROM tasks t` and `categories c` give each table a short alias. With two tables in one query, columns are written as `t.title` and `c.name`, so it is always clear which table a column comes from. Both tables have an `id` column, so the alias is required there.
- `LEFT JOIN categories c ON c.id = t.category_id` attaches to each task the category row whose `id` matches the task's `category_id`.
- `LEFT` means "keep every row from the left table (tasks), even when there is no match." Tasks without a category get `NULL` in the category columns. A plain `JOIN` (also called `INNER JOIN`) would drop those tasks entirely, as Section 7 shows.

---

## 3. Read Joined Rows into a Struct

The list page needs a different shape of data than the `Task` struct: it needs the category's name, not its ID, and it does not need `created_at`. A dedicated struct makes that explicit.

### Step 1: Add the TaskRow Struct

Add this struct below `Task` in `src/main.rs`:

```rust
#[derive(sqlx::FromRow)]
struct TaskRow {
    id: u64,
    title: String,
    done: bool,
    due_date: Option<NaiveDate>,
    category_name: Option<String>,
}
```

`category_name` is an `Option<String>`, because the `LEFT JOIN` produces `NULL` for tasks without a category. The query will name the column with `c.name AS category_name`, so `FromRow` can match it to this field.

### Step 2: Describe the Filters

The query string will carry up to four values. Replace the `TaskFilter` struct with this version, and add a second struct that holds the cleaned-up values, plus a constant for the page size:

```rust
#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
    status: Option<String>,
    category: Option<String>,
    page: Option<u64>,
}

struct ListFilter {
    search: String,
    status: String,
    category: String,
    category_id: Option<u64>,
    page: u64,
}

const PER_PAGE: u64 = 5;

impl ListFilter {
    fn from_query(query: TaskFilter) -> Self {
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
```

This is the same "raw input, then clean data" idea as `TaskForm` and `ValidTask` in Lesson 13, but forgiving instead of strict. A filter page should never fail because of an odd URL:

- `TaskFilter` mirrors the query string. Every field is an `Option`, because any of them may be missing. `category` is a `String`, not a number, because the "All categories" option sends an empty value (`category=`), which serde could not parse as a `u64`.
- `status` accepts only `pending` or `done`; anything else, including a missing value, becomes `all`.
- `category` keeps the raw text for the form and the pagination links, and `category_id` holds the parsed number, or `None` for "all categories" or nonsense.
- `page` defaults to 1, and `.max(1)` turns `page=0` into 1, so the offset calculation never goes below zero.

`PER_PAGE` is a constant so the page size lives in one place. Five is small enough to see pagination with the sample data; a real application would show more.

---

## 4. Build the Query with QueryBuilder

Every combination of filters needs a slightly different `WHERE` clause: no conditions, a search only, a category and a status, and so on. Writing a string literal for every combination is impossible, and gluing user input into SQL with `format!` is dangerous. `QueryBuilder` solves both problems.

### Step 1: Add QueryBuilder to the Imports

Change the `sqlx::MySqlPool` import to:

```rust
use sqlx::{MySql, MySqlPool, QueryBuilder};
```

`MySql` is the type that represents the MySQL database in SQLx's generic code; `QueryBuilder<MySql>` is a builder that produces MySQL queries.

### Step 2: Push the Shared Filter Conditions

Replace the `search_tasks` function with these two functions:

```rust
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
```

Here is what each part does:

- `builder.push(...)` appends SQL text written by you. `builder.push_bind(value)` appends a placeholder (`?`) and stores the value as a bound parameter, exactly like `.bind()` in a normal query. The rule is simple and strict: **only fixed SQL goes into `push`; every value that comes from the user goes into `push_bind`.**
- `WHERE 1 = 1` is a classic trick. The condition is always true, so it changes nothing, but it means every real condition can start with ` AND ...` without checking whether it is the first one.
- The search pattern is built in Rust as `%text%` and bound as one value. Before that, `escape_like` puts a backslash in front of `%`, `_`, and backslash itself. In a `LIKE` pattern, `%` and `_` are wildcards, so without escaping, a search for `100%` would mean "100 followed by anything" and a search for `_` would match every title. Escaping makes them literal characters again. This is not about security (the value is bound either way), but about correct results.
- The status conditions contain no user data at all, only one of two fixed strings chosen by `match`, so `push` is safe there.
- The category condition binds the parsed `u64`. If the category is missing or invalid, no condition is added, which means "all categories."
- Each `push` starts with a space. The builder joins pieces exactly as given, and without the space, `1 = 1` and `AND` would run together (see Section 8).

### Step 3: Count and Fetch with the Same Filters

Pagination needs two numbers from the database: how many tasks match in total (to know how many pages there are), and the tasks for the current page. Both must use exactly the same filters, which is why `push_filters` is a separate function. Add these two query functions below it:

```rust
async fn count_filtered_tasks(pool: &MySqlPool, filter: &ListFilter) -> Result<i64, sqlx::Error> {
    let mut builder = QueryBuilder::<MySql>::new("SELECT COUNT(*) FROM tasks t");
    push_filters(&mut builder, filter);
    builder.build_query_scalar::<i64>().fetch_one(pool).await
}

async fn filtered_tasks(pool: &MySqlPool, filter: &ListFilter) -> Result<Vec<TaskRow>, sqlx::Error> {
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
```

Line by line:

- `QueryBuilder::<MySql>::new(...)` starts a builder with the first part of the SQL.
- The count query does not need the join, because filters only use columns of `tasks`. `build_query_scalar::<i64>()` turns the builder into a scalar query, just like `query_scalar` in Lesson 9.
- The list query selects `c.name AS category_name`, so the column name matches the `TaskRow` field.
- `LIMIT ?` returns at most `PER_PAGE` rows, and `OFFSET ?` skips the rows of the previous pages: page 1 skips 0, page 2 skips 5, page 3 skips 10. Both are bound like any other value.
- `build_query_as::<TaskRow>()` turns the builder into a `query_as` query, and `fetch_all` runs it.

### Step 4: Rewrite the List Handler

Replace `TaskListTemplate` and the `list_tasks` handler with:

```rust
#[derive(Template)]
#[template(path = "tasks/list.html")]
struct TaskListTemplate {
    tasks: Vec<TaskRow>,
    categories: Vec<Category>,
    filter: ListFilter,
    total: i64,
    pages: u64,
}
```

```rust
async fn list_tasks(
    State(pool): State<MySqlPool>,
    Query(query): Query<TaskFilter>,
) -> Result<Response, AppError> {
    let filter = ListFilter::from_query(query);
    let total = count_filtered_tasks(&pool, &filter).await?;
    let pages = (total as u64).div_ceil(PER_PAGE).max(1);
    let tasks = filtered_tasks(&pool, &filter).await?;
    let categories = all_categories(&pool).await?;
    render(TaskListTemplate { tasks, categories, filter, total, pages })
}
```

The handler cleans the query, runs the count, computes the number of pages, loads the current page and the categories for the drop-down, and renders. `div_ceil` divides and rounds up: 12 tasks at 5 per page make 3 pages, not 2. `.max(1)` makes an empty result still show "Page 1 of 1." `total as u64` converts the count, which is never negative.

---

## 5. Update the List Template

The template needs the filter form, the category names, the counter, and the pagination links.

### Step 1: Replace templates/tasks/list.html

```html
{% extends "base.html" %}

{% block title %}Tasks - Todo Web{% endblock %}

{% block content %}
<h1>Tasks</h1>

<form method="get" action="/tasks">
  <input name="search" value="{{ filter.search }}" placeholder="Search tasks">
  <select name="status">
    <option value="all" {% if filter.status == "all" %}selected{% endif %}>All tasks</option>
    <option value="pending" {% if filter.status == "pending" %}selected{% endif %}>Not done</option>
    <option value="done" {% if filter.status == "done" %}selected{% endif %}>Done</option>
  </select>
  <select name="category">
    <option value="">All categories</option>
    {% for category in categories %}
      <option value="{{ category.id }}" {% if filter.category == category.id.to_string() %}selected{% endif %}>{{ category.name }}</option>
    {% endfor %}
  </select>
  <button type="submit">Filter</button>
</form>

<p>{{ total }} tasks found.</p>

{% if tasks.is_empty() %}
  <p>No tasks match these filters.</p>
{% else %}
  <ul>
    {% for task in tasks %}
      <li>
        <form method="post" action="/tasks/{{ task.id }}/toggle" style="display: inline">
          <button type="submit">{% if task.done %}[x]{% else %}[ ]{% endif %}</button>
        </form>
        <a href="/tasks/{{ task.id }}">{{ task.title }}</a>
        {% if let Some(name) = task.category_name %}[{{ name }}]{% endif %}
        {% if let Some(date) = task.due_date %}(due {{ date }}){% endif %}
      </li>
    {% endfor %}
  </ul>
{% endif %}

<p>
  {% if filter.page > 1 %}
    <a href="/tasks?search={{ filter.search|urlencode }}&status={{ filter.status }}&category={{ filter.category|urlencode }}&page={{ filter.page - 1 }}">Previous</a>
  {% endif %}
  Page {{ filter.page }} of {{ pages }}
  {% if filter.page < pages %}
    <a href="/tasks?search={{ filter.search|urlencode }}&status={{ filter.status }}&category={{ filter.category|urlencode }}&page={{ filter.page + 1 }}">Next</a>
  {% endif %}
</p>
{% endblock %}
```

Here is what is new:

- The filter form uses `method="get"`, so the filters end up in the URL. Filtered views can be bookmarked, shared, and reloaded, and the browser's back button works as expected. Each drop-down marks the current choice with `selected`, so the form always reflects the filters in use.
- `{% if let Some(name) = task.category_name %}[{{ name }}]{% endif %}` prints the category in brackets, or nothing.
- The Previous and Next links rebuild the query string with the current filters and a different page number. Without the filters, clicking "Next" on a filtered view would jump to page 2 of all tasks.
- `{{ filter.search|urlencode }}` applies Askama's `urlencode` filter, which percent-encodes the text for use in a URL: a space becomes `%20` and `&` becomes `%26`. Without it, a search for `salt & pepper` would cut the query string in two at the `&`. `status` needs no encoding, because it can only be one of three fixed words.

The old `search_tasks` function is gone. If the compiler reports it as missing anywhere else, that code still uses the old search; the list handler was its only user.

---

## 6. Run and Test

Run the tests, then start the server:

```bash
cargo test
cargo run
```

The tests still pass. In the examples below, the Work category has ID 6; use the ID from your own categories page.

### Step 1: Look at the First Page

```bash
curl -s http://127.0.0.1:3000/tasks | sed -n '/<p>/,/<\/main>/p'
```

The part of the output from the counter down:

```text
<p>12 tasks found.</p>


  <ul>
    
      <li>
        <form method="post" action="/tasks/2/toggle" style="display: inline">
          <button type="submit">[ ]</button>
        </form>
        <a href="/tasks/2">Build a web app</a>
        [Work]
        (due 2026-11-30)
      </li>
    
      <li>
        <form method="post" action="/tasks/4/toggle" style="display: inline">
          <button type="submit">[ ]</button>
        </form>
        <a href="/tasks/4">Write the first handler test</a>
        
        
      </li>
    
      <li>
        <form method="post" action="/tasks/8/toggle" style="display: inline">
          <button type="submit">[ ]</button>
        </form>
        <a href="/tasks/8">Read the Axum docs</a>
        
        
      </li>
    
      <li>
        <form method="post" action="/tasks/16/toggle" style="display: inline">
          <button type="submit">[ ]</button>
        </form>
        <a href="/tasks/16">Prepare slides</a>
        [Work]
        (due 2026-11-25)
      </li>
    
      <li>
        <form method="post" action="/tasks/18/toggle" style="display: inline">
          <button type="submit">[ ]</button>
        </form>
        <a href="/tasks/18">Reply to client emails</a>
        [Work]
        (due 2026-11-10)
      </li>
    
  </ul>


<p>
  
  Page 1 of 3
  
    <a href="/tasks?search=&status=all&category=&page=2">Next</a>
  
</p>

  </main>
```

The counter says 12, but only five tasks are shown. Category names appear next to the tasks that have one, and the uncategorized tasks are still listed, thanks to the `LEFT JOIN`.

### Step 2: Jump to the Last Page

```bash
curl -s "http://127.0.0.1:3000/tasks?page=3" | sed -n '/tasks found/,/<\/main>/p'
```

Output:

```text
<p>12 tasks found.</p>


  <ul>
    
      <li>
        <form method="post" action="/tasks/20/toggle" style="display: inline">
          <button type="submit">[x]</button>
        </form>
        <a href="/tasks/20">Pay the electricity bill</a>
        [Home]
        (due 2026-11-05)
      </li>
    
      <li>
        <form method="post" action="/tasks/23/toggle" style="display: inline">
          <button type="submit">[x]</button>
        </form>
        <a href="/tasks/23">Buy groceries</a>
        [Home]
        
      </li>
    
  </ul>


<p>
  
    <a href="/tasks?search=&status=all&category=&page=2">Previous</a>
  
  Page 3 of 3
  
</p>

  </main>
```

Page 3 skips the first ten tasks and shows the last two, and there is only a Previous link.

### Step 3: Combine Filters

Show the unfinished Work tasks:

```bash
curl -s "http://127.0.0.1:3000/tasks?search=&status=pending&category=6" | grep -E "found|<a href=\"/tasks/[0-9]|Page"
```

Output:

```text
<p>5 tasks found.</p>
        <a href="/tasks/2">Build a web app</a>
        <a href="/tasks/16">Prepare slides</a>
        <a href="/tasks/18">Reply to client emails</a>
        <a href="/tasks/22">Fix 100% CPU bug</a>
        <a href="/tasks/24">Review pull request</a>
  Page 1 of 1
```

Both conditions were applied, and the count agrees with the list.

### Step 4: Search for Special Characters

Search for `100%`. In a URL, `%` itself must be written as `%25`:

```bash
curl -s "http://127.0.0.1:3000/tasks?search=100%25&status=all&category=" | grep -E "found|<a href=\"/tasks/[0-9]"
```

Output:

```text
<p>1 tasks found.</p>
        <a href="/tasks/22">Fix 100% CPU bug</a>
```

Now search for a single `%`:

```bash
curl -s "http://127.0.0.1:3000/tasks?search=%25&status=all&category=" | grep found
```

Output:

```text
<p>1 tasks found.</p>
```

Only the one title that really contains a percent sign matches. Without `escape_like`, the pattern would be `%%%`, which matches every title, and the page would claim 12 results.

### Step 5: Keep Filters Across Pages

Search for titles containing `e` among the unfinished tasks; there are enough results for two pages:

```bash
curl -s "http://127.0.0.1:3000/tasks?search=e&status=pending&category=" | grep -E "found|Next|Page"
```

Output:

```text
<p>8 tasks found.</p>
  Page 1 of 2
    <a href="/tasks?search=e&status=pending&category=&page=2">Next</a>
```

The Next link carries the search and the status, so page 2 continues the same filtered list.

### Step 6: Feed It Nonsense

```bash
curl -s "http://127.0.0.1:3000/tasks?status=weird&category=abc&page=0" | grep -E "found|Page|selected"
```

Output:

```text
    <option value="all" selected>All tasks</option>
<p>12 tasks found.</p>
  Page 1 of 3
```

An unknown status became "all," an invalid category was ignored, and page 0 became page 1. Nothing crashed. Try the filters in the browser too, then stop the server with `Ctrl+C` and commit:

```bash
git add -A
git commit -m "lesson 16: joins, filters, search, pagination"
```

---

## 7. JOINs and Pagination Explained

Two ideas from this lesson come up in almost every database-backed application.

**Choosing the right join.** The difference between `JOIN` and `LEFT JOIN` is which rows survive when there is no match:

| Query | Tasks with a category | Tasks without a category |
| --- | --- | --- |
| `FROM tasks t JOIN categories c ON ...` | included | dropped |
| `FROM tasks t LEFT JOIN categories c ON ...` | included | included, with `NULL` category columns |

You can see it in numbers with the sample data:

```bash
mysql -u todo_user -p db_rust_todo -e "SELECT COUNT(*) FROM tasks t LEFT JOIN categories c ON c.id = t.category_id; SELECT COUNT(*) FROM tasks t JOIN categories c ON c.id = t.category_id;"
```

Output:

```text
COUNT(*)
12
COUNT(*)
10
```

With a plain `JOIN`, the two uncategorized tasks would vanish from the list, while the count query (which has no join) would still report 12. The page would say "12 tasks found" and show fewer. Use `LEFT JOIN` whenever the foreign key is optional.

**Offset pagination.** Each page is a window into the sorted results:

```text
ORDER BY t.done, t.id      page 1: LIMIT 5 OFFSET 0   -> rows 1 to 5
                           page 2: LIMIT 5 OFFSET 5   -> rows 6 to 10
                           page 3: LIMIT 5 OFFSET 10  -> rows 11 to 12
```

Some rules make it work reliably:

- **Always sort with `ORDER BY`.** Without it, MySQL may return rows in any order, and the same task could appear on two pages or on none. The sort should end with a unique column, here `t.id`, so ties are broken the same way every time.
- **Count with the same filters.** The page count comes from a `COUNT(*)` query with exactly the same `WHERE` clause, which is why both queries share `push_filters`.
- **Large offsets get slower.** MySQL still reads and skips all the rows before the offset. For a to-do list this never matters; for tables with millions of rows, applications switch to "keyset" pagination (`WHERE id > last_seen_id`), which is a topic for later.

**Building dynamic SQL safely.** `QueryBuilder` gives you the flexibility of building SQL at runtime without giving up placeholders. The only dangerous method is `push`, because it inserts text as SQL. As long as `push` only ever receives text you wrote, and every user value goes through `push_bind`, the query is as safe as a string literal with `.bind()`.

---

## 8. Fix the Errors in Your Code

**Error 1: Pushing user input as SQL**

```rust
// Wrong
        builder.push(format!(" AND t.title LIKE '%{}%'", filter.search));
```

```rust
// Correct
        builder.push(" AND t.title LIKE ");
        builder.push_bind(format!("%{}%", escape_like(&filter.search)));
```

Unlike `sqlx::query`, `push` accepts any text, including a `format!` result, so this compiles (the compiler only warns that `escape_like` is unused). It breaks on the first title with an apostrophe:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -G "http://127.0.0.1:3000/tasks" --data-urlencode "search=client's"
```

Output:

```text
500
```

The server terminal shows why:

```text
database error: error returned from database: 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 's%'' at line 1
```

The apostrophe in `client's` ended the SQL string early. Worse, someone can use the same hole on purpose. `-G` with `--data-urlencode` makes `curl` encode the value into the query string for you:

```bash
curl -s -G "http://127.0.0.1:3000/tasks" --data-urlencode "search=%' OR 1=1 OR t.title LIKE '" | grep found
```

Output:

```text
<p>12 tasks found.</p>
```

The "search" rewrote the `WHERE` clause and returned every task. In a multi-user application, the same trick could reveal other people's data. With the correct version, both searches are harmless: `client's` returns a normal page, and the attack text is simply searched for as a title and finds `0 tasks`.

**Error 2: A missing space between pushed pieces**

```rust
// Wrong
            builder.push("AND t.done = FALSE");
```

```rust
// Correct
            builder.push(" AND t.done = FALSE");
```

`QueryBuilder` concatenates exactly what you give it, so the SQL becomes `... WHERE 1 = 1AND t.done = FALSE`. Filtering by status now returns a `500`, and the terminal shows:

```text
database error: error returned from database: 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 't.done = FALSE' at line 1
```

Start every pushed fragment with a space. When a dynamic query fails with error 1064, look at the text right before the position MySQL names; that is where two pieces collided.

**Error 3: Using JOIN instead of LEFT JOIN**

```rust
// Wrong
         FROM tasks t
         JOIN categories c ON c.id = t.category_id",
```

```rust
// Correct
         FROM tasks t
         LEFT JOIN categories c ON c.id = t.category_id",
```

This compiles and runs without any error, which makes it easy to miss. Tasks without a category silently disappear from the list, while the counter still includes them, as the numbers in Section 7 showed (12 versus 10). Whenever a counter and a list disagree, check the joins.

---

## 9. Exercises

**Exercise 1:** The detail page still uses two queries: one for the task and one for its category. Replace them with a single `LEFT JOIN` query. Add a `TaskDetail` struct with the task's fields and a `category_name: Option<String>`, a `find_task_detail` query function, and use it in `show_task` and `templates/tasks/show.html`.

**Exercise 2:** Add a sort option to the filter form: "Unfinished first" (the current order) and "By due date" (`sort=due`), which orders by due date with tasks without a date at the end. Keep the sort in the pagination links. Never push the user's text into `ORDER BY`; choose between fixed strings with `match`.

**Exercise 3:** Replace the counter with `Showing 6-10 of 12 tasks.` Implement two methods, `first_shown` and `last_shown`, on `TaskListTemplate` and call them from the template.

---

## 10. Solutions

**Solution for Exercise 1:**

Add the struct and the query:

```rust
#[derive(sqlx::FromRow)]
struct TaskDetail {
    id: u64,
    title: String,
    done: bool,
    due_date: Option<NaiveDate>,
    created_at: NaiveDateTime,
    category_name: Option<String>,
}
```

```rust
async fn find_task_detail(pool: &MySqlPool, id: u64) -> Result<Option<TaskDetail>, sqlx::Error> {
    sqlx::query_as::<_, TaskDetail>(
        "SELECT t.id, t.title, t.done, t.due_date, t.created_at, c.name AS category_name
         FROM tasks t
         LEFT JOIN categories c ON c.id = t.category_id
         WHERE t.id = ?",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}
```

Change the template struct and the handler:

```rust
#[derive(Template)]
#[template(path = "tasks/show.html")]
struct TaskShowTemplate {
    task: TaskDetail,
}
```

```rust
async fn show_task(
    State(pool): State<MySqlPool>,
    Path(id): Path<u64>,
) -> Result<Response, AppError> {
    let task = find_task_detail(&pool, id).await?.ok_or(AppError::NotFound)?;
    render(TaskShowTemplate { task })
}
```

And replace the category line in `templates/tasks/show.html`:

```html
<p>Category: {% if let Some(name) = task.category_name %}{{ name }}{% else %}none{% endif %}</p>
```

One round trip to the database instead of two, and the handler is shorter. The `WHERE t.id = ?` needs the alias, because both tables have an `id` column. After this change, the compiler warns that some fields of `Task` (`id`, `done`, and `created_at`) are never read: `Task` is now only used by the edit form. You can remove those fields from `Task` and from the `SELECT` in `find_task`, or leave the warning until Lesson 17 reorganizes the code.

```bash
curl -s http://127.0.0.1:3000/tasks/2 | grep Category
```

Output:

```text
<p>Category: Work</p>
```

**Solution for Exercise 2:**

Add the field to both filter structs:

```rust
#[derive(Deserialize)]
struct TaskFilter {
    search: Option<String>,
    status: Option<String>,
    category: Option<String>,
    page: Option<u64>,
    sort: Option<String>,
}

struct ListFilter {
    search: String,
    status: String,
    sort: String,
    category: String,
    category_id: Option<u64>,
    page: u64,
}
```

Clean it in `from_query`:

```rust
impl ListFilter {
    fn from_query(query: TaskFilter) -> Self {
        let status = match query.status.as_deref() {
            Some("pending") => "pending",
            Some("done") => "done",
            _ => "all",
        };
        let sort = match query.sort.as_deref() {
            Some("due") => "due",
            _ => "default",
        };
        let category = query.category.unwrap_or_default();
        let category_id = category.trim().parse::<u64>().ok();
        ListFilter {
            search: query.search.unwrap_or_default().trim().to_string(),
            status: status.to_string(),
            sort: sort.to_string(),
            category,
            category_id,
            page: query.page.unwrap_or(1).max(1),
        }
    }
}
```

In `filtered_tasks`, replace the line that pushes `ORDER BY ... LIMIT` with:

```rust
    match filter.sort.as_str() {
        "due" => builder.push(" ORDER BY t.due_date IS NULL, t.due_date, t.id"),
        _ => builder.push(" ORDER BY t.done, t.id"),
    };
    builder.push(" LIMIT ");
```

Then add a drop-down to the filter form, before the button:

```html
  <select name="sort">
    <option value="default" {% if filter.sort == "default" %}selected{% endif %}>Unfinished first</option>
    <option value="due" {% if filter.sort == "due" %}selected{% endif %}>By due date</option>
  </select>
```

And add `&sort={{ filter.sort }}` to both pagination links, before `&page=`.

`ORDER BY` cannot use placeholders (a column name is SQL, not a value), so the sort must be chosen from fixed strings. `t.due_date IS NULL` is `0` for tasks with a date and `1` for tasks without, so sorting by it first moves undated tasks to the end; MySQL would otherwise put `NULL` first. The `match` produces `&mut QueryBuilder` in both arms, and the semicolon after it discards that value.

```bash
curl -s "http://127.0.0.1:3000/tasks?sort=due&page=1" | grep -E "Showing|<a href=\"/tasks/[0-9]|due 20|Next"
```

Output (with Exercise 3 solved as well):

```text
<p>Showing 1-5 of 12 tasks.</p>
        <a href="/tasks/20">Pay the electricity bill</a>
        (due 2026-11-05)
        <a href="/tasks/24">Review pull request</a>
        (due 2026-11-08)
        <a href="/tasks/18">Reply to client emails</a>
        (due 2026-11-10)
        <a href="/tasks/21">Finish chapter 3</a>
        (due 2026-11-18)
        <a href="/tasks/16">Prepare slides</a>
        (due 2026-11-25)
    <a href="/tasks?search=&status=all&category=&sort=due&page=2">Next</a>
```

**Solution for Exercise 3:**

Add an `impl` block for the template struct:

```rust
impl TaskListTemplate {
    fn first_shown(&self) -> u64 {
        if self.tasks.is_empty() { 0 } else { (self.filter.page - 1) * PER_PAGE + 1 }
    }

    fn last_shown(&self) -> u64 {
        (self.filter.page - 1) * PER_PAGE + self.tasks.len() as u64
    }
}
```

And replace the counter line in the template:

```html
<p>Showing {{ first_shown() }}-{{ last_shown() }} of {{ total }} tasks.</p>
```

Askama templates can call methods of their own struct directly by name. `first_shown` is the position of the first task on the page, counting from 1, and `last_shown` adds the number of tasks actually shown, so a short last page reports the right range. On page 3:

```bash
curl -s "http://127.0.0.1:3000/tasks?page=3" | grep Showing
```

Output:

```text
<p>Showing 11-12 of 12 tasks.</p>
```

---

## Next Up - Lesson 17

In this lesson, you turned the task list into a real query page: a `LEFT JOIN` brings in category names, `QueryBuilder` assembles optional filters with `push` for fixed SQL and `push_bind` for every user value, `escape_like` keeps `%` and `_` literal, and `LIMIT`, `OFFSET`, and a matching `COUNT(*)` split the results into pages with links that keep the filters.

`src/main.rs` has grown to well over six hundred lines, with models, queries, validation, errors, templates, and handlers all in one file. Module 7 prepares Todo Web for the long run. In Lesson 17, you will split it into modules for models, database queries, errors, templates, and handlers, group shared resources in an `AppState` struct, and build the router in one place.
