## 1. Before You Begin

In Lesson 7, Todo Web learned to connect to MySQL through a connection pool. The database is still empty, though: there is no `tasks` table for the application to read from or write to. In Lesson 3, you created a practice table by typing `CREATE TABLE` into the `mysql` client. That works once, on one computer. It does not work for a real project, where the same schema must exist on your laptop, on a teammate's laptop, on a test database, and on the production server, and where the schema keeps changing as features are added.

Migrations solve this. A migration is a small SQL file with a version number that describes one change to the schema, such as "create the tasks table" or "add a category column." The files live in the project folder and are committed to Git like any other code. A tool keeps track of which migrations a database has already applied and runs only the new ones, in order. In this lesson, you will install sqlx-cli, write the migration that creates the `tasks` table, apply and revert it, and then make Todo Web run pending migrations automatically when it starts.

### What You'll Build

A `migrations` folder in `todo-web` with a reversible migration that creates the `tasks` table, a `tasks` table in `db_rust_todo` created by that migration, and a `main` function that brings the database up to date with `sqlx::migrate!()` before the server starts.

### What You'll Learn

- ✅ What migrations are and why projects use them instead of manual SQL
- ✅ How to install sqlx-cli with MySQL support
- ✅ How to create a reversible migration with `sqlx migrate add -r`
- ✅ How to check, apply, and revert migrations with `sqlx migrate info`, `run`, and `revert`
- ✅ How SQLx records applied migrations in the `_sqlx_migrations` table
- ✅ How to run migrations from Rust at startup with `sqlx::migrate!()`

### What You'll Need

- The `todo-web` project from Lesson 7, including its `.env` file
- The `db_rust_todo` database and `todo_user` account from Lesson 3
- An internet connection to install sqlx-cli

---

## 2. Install sqlx-cli

sqlx-cli is the command-line companion to the SQLx library. It creates migration files, runs them against a database, and can create or drop the database itself. It is a separate program, installed with Cargo.

### Step 1: Install the Tool

Run:

```bash
cargo install sqlx-cli --no-default-features --features mysql,rustls
```

`cargo install` downloads a crate, compiles it, and puts the resulting program in `~/.cargo/bin`, which rustup added to your `PATH`. By default, sqlx-cli is built with support for every database SQLx knows. `--no-default-features` turns that off, and `--features mysql,rustls` turns back on only the MySQL driver and `rustls`, a TLS library written in Rust for encrypted connections. The build takes a few minutes and prints many `Compiling` lines, ending with a line that says the `sqlx` and `cargo-sqlx` executables were installed.

### Step 2: Check the Installation

```bash
sqlx --version
```

Output:

```text
sqlx-cli 0.9.0
```

A newer `0.9.x` version is fine. The tool must match the major version of the SQLx library in your project (0.9 in this course), because the two share the same migration format.

---

## 3. Create the First Migration

sqlx-cli finds the database through the same `DATABASE_URL` variable you put in `.env` in Lesson 7. Run every `sqlx` command from the `todo-web` folder, so it can find both `.env` and the `migrations` folder.

### Step 1: Generate the Migration Files

In the `todo-web` folder, run:

```bash
sqlx migrate add -r create_tasks_table
```

Output:

```text
Creating migrations/20261101165548_create_tasks_table.up.sql
Creating migrations/20261101165548_create_tasks_table.down.sql
```

sqlx-cli created a `migrations` folder with two files. The number at the start is the version: the current date and time (`2026-11-01 16:55:48` here). Your number will be different, which is expected. Versions sort in the order the migrations were created, and that is the order they will run in. `-r` makes the migration reversible, which is why there are two files:

- The `.up.sql` file applies the change.
- The `.down.sql` file undoes it.

Both files only contain a comment so far, such as `-- Add up migration script here`.

### Step 2: Write the Up Migration

Replace the contents of the `.up.sql` file with:

```sql
CREATE TABLE tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE,
    due_date DATE NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

This is the practice table from Lesson 3 with two improvements and two new columns:

- `id BIGINT UNSIGNED` is a 64-bit unsigned number, which matches the `u64` IDs in your `Task` struct. It will never run out.
- `title` and `done` are the same as in the practice table.
- `due_date DATE NULL` stores an optional date without a time. `NULL` means "no due date," which will become an `Option` in Rust.
- `created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP` records when each task was created. The database fills it in automatically, so your Rust code never has to send it.

### Step 3: Write the Down Migration

Replace the contents of the `.down.sql` file with:

```sql
DROP TABLE tasks;
```

The down migration must exactly undo the up migration. Creating a table is undone by dropping it. Keep in mind that reverting a migration like this deletes every row in the table, so on a real server, reverting is an emergency tool, not an everyday one.

---

## 4. Apply and Revert the Migration

With the files written, use sqlx-cli to compare the folder with the database, apply the migration, and practice undoing it.

### Step 1: Check the Status

```bash
sqlx migrate info
```

Output:

```text
20261101165548/pending create tasks table
```

Each line shows a version, its status, and a description made from the file name. `pending` means the migration exists in the folder but has not been applied to the database yet.

### Step 2: Apply It

```bash
sqlx migrate run
```

Output:

```text
Applied 20261101165548/migrate create tasks table (6.398208ms)
```

The `tasks` table now exists. Check the status again:

```bash
sqlx migrate info
```

Output:

```text
20261101165548/installed create tasks table
```

### Step 3: Look at the Database

Inspect the result with the `mysql` client. The `-t` option prints table borders even in `-e` mode, and the database name after the options selects `db_rust_todo`:

```bash
mysql -u todo_user -p db_rust_todo -t -e "SHOW TABLES; DESCRIBE tasks;"
```

Output:

```text
+------------------------+
| Tables_in_db_rust_todo |
+------------------------+
| _sqlx_migrations       |
| tasks                  |
+------------------------+
+------------+---------------------+------+-----+---------------------+----------------+
| Field      | Type                | Null | Key | Default             | Extra          |
+------------+---------------------+------+-----+---------------------+----------------+
| id         | bigint(20) unsigned | NO   | PRI | NULL                | auto_increment |
| title      | varchar(255)        | NO   |     | NULL                |                |
| done       | tinyint(1)          | NO   |     | 0                   |                |
| due_date   | date                | YES  |     | NULL                |                |
| created_at | datetime            | NO   |     | current_timestamp() |                |
+------------+---------------------+------+-----+---------------------+----------------+
```

There are two tables. `tasks` is yours. `_sqlx_migrations` was created by SQLx to remember which migrations have been applied. Look inside it:

```bash
mysql -u todo_user -p db_rust_todo -t -e "SELECT version, description, success FROM _sqlx_migrations;"
```

Output:

```text
+----------------+--------------------+---------+
| version        | description        | success |
+----------------+--------------------+---------+
| 20261101165548 | create tasks table |       1 |
+----------------+--------------------+---------+
```

Each applied migration gets one row. The table also stores a checksum of the SQL file, which SQLx uses to detect files that were changed after they were applied (Section 7 shows what happens then). Never edit this table by hand.

### Step 4: Revert and Re-apply

Undo the most recent migration:

```bash
sqlx migrate revert
```

Output:

```text
Applied 20261101165548/revert create tasks table (11.293399ms)
```

The down file ran and the `tasks` table is gone. Only `_sqlx_migrations` remains, now without the row for this migration:

```bash
mysql -u todo_user -p db_rust_todo -t -e "SHOW TABLES;"
```

Output:

```text
+------------------------+
| Tables_in_db_rust_todo |
+------------------------+
| _sqlx_migrations       |
+------------------------+
```

Apply it again so the table is back:

```bash
sqlx migrate run
```

Output:

```text
Applied 20261101165548/migrate create tasks table (6.281378ms)
```

Being able to go back and forth like this is useful while you are developing a new migration: apply it, test it, revert it, fix it, and apply it again.

---

## 5. Run Migrations When the App Starts

Running `sqlx migrate run` by hand is easy to forget. If a teammate pulls your code with a new migration and starts the server without running it, the application queries a table that does not exist. The safest approach is to let the application bring its own database up to date every time it starts.

### Step 1: Add sqlx::migrate! to main

In `src/main.rs`, add the migration step to `main`, right after the pool is created:

```rust
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

    let app = Router::new()
        .route("/", get(home))
        .route("/health", get(health))
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/new", get(new_task_form))
        .route("/tasks/{id}", get(show_task))
        .fallback(not_found)
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("port 3000 should be free");
    println!("Todo Web running on http://127.0.0.1:3000");

    axum::serve(listener, app).await.expect("server should run");
}
```

Here is what the new lines do:

- `sqlx::migrate!()` is a macro that reads every file in the `migrations` folder at compile time and embeds them in your program. The finished binary carries its migrations with it, so a server does not need the `migrations` folder next to the executable.
- `.run(&pool).await` compares the embedded migrations with the `_sqlx_migrations` table and applies the pending ones, in order. If everything is already applied, it does nothing, so it is safe to run on every start.
- `.expect(...)` stops the program if a migration fails. Starting a server whose database is in an unknown state would only cause confusing errors later.

The macro uses SQLx's `migrate` and `macros` features, which are part of SQLx's default features, so no change to `Cargo.toml` is needed.

### Step 2: Tell Cargo to Rebuild When Migrations Change

Because the migrations are embedded at compile time, Cargo needs to know that a new or changed file in `migrations` means the program must be rebuilt. sqlx-cli can generate the small build script that does this:

```bash
sqlx migrate build-script
```

Output:

```text
Created `build.rs`; be sure to check it into version control!
```

The new `build.rs` file in the project folder contains:

```rust
// generated by `sqlx migrate build-script`
fn main() {
    // trigger recompilation when a new migration is added
    println!("cargo:rerun-if-changed=migrations");
}
```

Cargo runs `build.rs` before compiling your program. The `cargo:rerun-if-changed=migrations` line is an instruction to Cargo: rebuild whenever anything in the `migrations` folder changes. Without it, adding a migration might not trigger a rebuild, and the program would keep running with the old set.

---

## 6. Run and Test

To see the automatic migration in action, start from a database without the `tasks` table.

### Step 1: Revert, Then Start the App

```bash
sqlx migrate revert
cargo run
```

`sqlx migrate revert` prints the same `Applied .../revert` line as before. Then the server starts, and its output shows the new step:

```text
Connected to MySQL
Migrations are up to date
Todo Web running on http://127.0.0.1:3000
```

In a second terminal, confirm that the table is back:

```bash
mysql -u todo_user -p db_rust_todo -e "SHOW TABLES;"
```

Output:

```text
Tables_in_db_rust_todo
_sqlx_migrations
tasks
```

The application applied the pending migration by itself before it started listening.

### Step 2: Restart and Check the Status

Stop the server with `Ctrl+C` and start it again with `cargo run`. The output is the same, but this time nothing was applied, because the migration was already installed. sqlx-cli agrees:

```bash
sqlx migrate info
```

Output:

```text
20261101165548/installed create tasks table
```

### Step 3: Commit the Migration

```bash
git add -A
git commit -m "lesson 8: migrations"
```

The commit includes `build.rs` and both migration files. Anyone who clones the project and runs it gets the same `tasks` table automatically.

---

## 7. The Golden Rules of Migrations

Migrations are simple, but a few rules keep them safe. Most migration problems in real projects come from breaking one of these:

- **Never edit a migration that has been applied.** Other databases, such as a teammate's or the production server, already ran the old version. Changing the file would make databases disagree about the schema. To change the schema, add a new migration, for example `add_priority_to_tasks`. SQLx enforces this rule with the checksum stored in `_sqlx_migrations`.
- **One change per migration.** Small migrations with clear names are easier to review, apply, and revert. The file names become a readable history of your schema.
- **Always write the down migration, and test it.** Run `sqlx migrate revert` followed by `sqlx migrate run` before committing. A down migration that has never been run will probably fail when you need it most.
- **Do not edit the database by hand.** If you change a table with the `mysql` client, the migrations no longer describe the real schema, and a fresh database built from them will be different.
- **MySQL cannot roll back schema changes.** In MySQL, statements like `CREATE TABLE` and `ALTER TABLE` take effect immediately and cannot be undone by a transaction. If a migration with several statements fails halfway, the first statements stay applied. Keeping each migration to one change limits the damage.

| Command | What it does |
| --- | --- |
| `sqlx migrate add -r <name>` | Create a new reversible migration pair |
| `sqlx migrate info` | List migrations and whether each is installed or pending |
| `sqlx migrate run` | Apply all pending migrations in order |
| `sqlx migrate revert` | Undo the most recently applied migration |
| `sqlx database reset -y` | Drop the database, create it again, and run all migrations |
| `sqlx migrate build-script` | Create `build.rs` so migration changes trigger a rebuild |

---

## 8. Fix the Errors in Your Code

**Error 1: Editing a migration that was already applied**

```sql
-- Wrong: the applied migration file was changed afterwards
    title VARCHAR(200) NOT NULL,
```

```sql
-- Correct: keep the applied file unchanged
    title VARCHAR(255) NOT NULL,
```

If the column really must change, create a new migration with `ALTER TABLE tasks MODIFY title VARCHAR(200) NOT NULL;` instead. When an applied file is modified, sqlx-cli refuses to continue:

```text
error: migration 20261101165548 was previously applied but has been modified
```

The application refuses to start, too:

```text
Connected to MySQL

thread 'main' (36267) panicked at src/main.rs:144:10:
migrations should run: VersionMismatch(20261101165548)
```

`VersionMismatch` names the version whose checksum no longer matches. Undo your edit to the file (Git makes this easy with `git checkout -- migrations/`), and the error goes away.

**Error 2: A syntax error in a migration**

```sql
-- Wrong: AFTERR is a typo
ALTER TABLE tasks ADD COLUMN priority TINYINT NOT NULL DEFAULT 0 AFTERR done;
```

```sql
-- Correct
ALTER TABLE tasks ADD COLUMN priority TINYINT NOT NULL DEFAULT 0 AFTER done;
```

SQLx sends the file to MySQL as it is, so the database reports the problem:

```text
error: while executing migration 20261101165628: error returned from database: 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 'done' at line 1
```

Error 1064 always means invalid SQL. The text after `near` shows where MySQL stopped understanding the statement; the real mistake is usually just before it, here `AFTERR`. The failed migration stays `pending`, so you can fix the file and run `sqlx migrate run` again. Testing a new statement in the `mysql` client first is a quick way to avoid this.

**Error 3: Running sqlx-cli from the wrong folder**

```bash
# Wrong: running sqlx-cli outside the project folder
cd /tmp
sqlx migrate info
```

```bash
# Correct: run it where .env and migrations/ live
cd todo-web
sqlx migrate info
```

Output for the wrong version:

```text
error: `--database-url` or `DATABASE_URL` must be set
```

sqlx-cli reads `.env` from the current folder, just like your application. Outside the project, it does not know which database to use. The same mistake can also show up as an empty migration list, because the `migrations` folder is looked up in the current folder too.

---

## 9. Exercises

**Exercise 1:** Create a second reversible migration named `add_done_index_to_tasks` that adds an index on the `done` column (`CREATE INDEX idx_tasks_done ON tasks (done);`), with a down migration that drops it. Apply it, check it with `SHOW INDEX FROM tasks;`, revert it, and then delete the two files so the project keeps only the first migration.

**Exercise 2:** Use `sqlx database reset -y` to drop and recreate `db_rust_todo` and run all migrations from scratch. Check the tables afterwards. When is this command useful, and why must it never be used on a production server?

**Exercise 3:** After the migrations run in `main`, count the rows in `_sqlx_migrations` with `query_scalar` and print `Migrations are up to date (1 applied)`. MySQL's `COUNT(*)` returns a `BIGINT`, so decode it as an `i64`.

---

## 10. Solutions

**Solution for Exercise 1:**

```bash
sqlx migrate add -r add_done_index_to_tasks
```

Put this in the new `.up.sql` file:

```sql
CREATE INDEX idx_tasks_done ON tasks (done);
```

And this in the new `.down.sql` file:

```sql
DROP INDEX idx_tasks_done ON tasks;
```

Then apply it, inspect it, and revert it:

```bash
sqlx migrate run
mysql -u todo_user -p db_rust_todo -t -e "SHOW INDEX FROM tasks;"
sqlx migrate revert
sqlx migrate info
```

`SHOW INDEX` lists two indexes: `PRIMARY` on `id`, created by `PRIMARY KEY`, and `idx_tasks_done` on `done`. After the revert, `sqlx migrate info` shows the new migration as pending again:

```text
20261101165548/installed create tasks table
20261101165656/pending add done index to tasks
```

An index lets MySQL find rows by a column without scanning the whole table, much like the index at the back of a book. Delete the two `add_done_index_to_tasks` files when you are done. Because the migration is no longer applied, deleting it is safe; deleting an applied migration would be another way to make the folder and the database disagree.

**Solution for Exercise 2:**

```bash
sqlx database reset -y
```

Output:

```text
Applied 20261101165548/migrate create tasks table (6.071228ms)
```

```bash
mysql -u todo_user -p db_rust_todo -e "SHOW TABLES;"
```

Output:

```text
Tables_in_db_rust_todo
_sqlx_migrations
tasks
```

`reset` drops the whole database, creates it again, and runs every migration. `-y` skips the confirmation question. It works for `todo_user` because the account has all privileges on `db_rust_todo`, including dropping and creating it. The command is handy during development: when your local data is a mess, or when you want to prove that the migrations alone can build the full schema. It must never run against production, because dropping the database deletes all real user data.

**Solution for Exercise 3:**

In `main`, replace the `println!("Migrations are up to date");` line with:

```rust
    let applied: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM _sqlx_migrations")
        .fetch_one(&pool)
        .await
        .expect("should count migrations");
    println!("Migrations are up to date ({applied} applied)");
```

The type annotation `i64` on `applied` tells `query_scalar` what to decode. If you chose a type that does not match the column, such as `String`, the query would fail at runtime with a type mismatch error. Running the server prints:

```text
Connected to MySQL
Migrations are up to date (1 applied)
Todo Web running on http://127.0.0.1:3000
```

---

## Next Up - Lesson 9

In this lesson, you installed sqlx-cli, created a reversible migration for the `tasks` table, applied and reverted it, and saw how SQLx tracks migrations in `_sqlx_migrations`. Todo Web now runs pending migrations automatically at startup, and `build.rs` makes sure new migrations trigger a rebuild.

The `tasks` table exists but is empty, and the pages still show `sample_tasks()`. In Lesson 9, you will learn SQLx's query API in a small playground program: insert rows with bound parameters, read them into a `Task` struct with `query_as` and `FromRow`, and choose between `fetch_all`, `fetch_one`, and `fetch_optional` for different kinds of queries.
