## 1. Before You Begin

In Lesson 1, you saw why a web version of the to-do list needs a database, and in Lesson 2 you learned the async foundation that SQLx will use to talk to it. Before any Rust code connects to MySQL, the database server needs to be ready: a database for the project, a user that the application logs in with, and the right privileges for that user.

This lesson does all of that by hand with the `mysql` command-line client. You will create the `db_rust_todo` database and a dedicated `todo_user` account, check that the account can do exactly what it should and nothing more, and then run the basic SQL statements your Rust code will send later: `CREATE TABLE`, `INSERT`, `SELECT`, `UPDATE`, and `DELETE`. Knowing what these statements do on their own makes it much easier to understand them when they appear inside Rust code.

### What You'll Build

A MySQL database named `db_rust_todo`, a user named `todo_user` that can only access that database (plus the temporary test databases used in Lesson 18), and a practice table that you create, fill, query, change, and drop again.

### What You'll Learn

- ✅ How to install MySQL or MariaDB on Ubuntu and log in as the administrator
- ✅ How to create a database with the `utf8mb4` character set
- ✅ How to create a dedicated database user and grant it limited privileges
- ✅ How to check a user's privileges with `CURRENT_USER()` and `SHOW GRANTS`
- ✅ How to create a table and run `INSERT`, `SELECT`, `UPDATE`, and `DELETE` by hand
- ✅ How to read the most common MySQL error messages

### What You'll Need

- Ubuntu (or another Linux distribution) with permission to use `sudo`
- Basic SQL knowledge; the qadrlabs SQL course covers everything used here
- About 15 minutes

---

## 2. Install and Open the Database Server

You can use either MySQL or MariaDB for this course. MariaDB started as a fork of MySQL, speaks the same protocol, and accepts the same SQL for everything in this course. SQLx's MySQL driver works with both. The outputs in this course were recorded on MariaDB 11.8; if you use MySQL 8, the welcome message and some timing details look slightly different, but the results are the same.

### Step 1: Install the Server

If you already have MySQL or MariaDB running, skip to Step 2. Otherwise, install one of them. For MariaDB:

```bash
sudo apt update
sudo apt install mariadb-server
```

For MySQL, install `mysql-server` instead of `mariadb-server`. Both packages also install the `mysql` command-line client and start the server automatically. Check that the server is running:

```bash
sudo systemctl status mariadb
```

Use `mysql` instead of `mariadb` as the service name if you installed MySQL. The status should say `active (running)`. Press `q` to leave the status view.

### Step 2: Log In as the Administrator

On Ubuntu, the database administrator account `root` is linked to the operating system's root user, so you log in with `sudo` and no database password:

```bash
sudo mysql
```

You see a welcome message and a prompt such as `MariaDB [(none)]>` or `mysql>`. Everything you type at this prompt is SQL, and every statement ends with a semicolon. The `(none)` part means no database is selected yet.

The administrator account can do anything, including deleting every database on the server. That is exactly why your application should never use it. In the next section, you will create an account with much less power.

---

## 3. Create the Database and the Application User

A good habit for every project is one database and one user per application. If the application has a bug, or its password leaks, the damage stays inside that one database.

### Step 1: Create the Database

At the administrator prompt, run:

```sql
CREATE DATABASE IF NOT EXISTS db_rust_todo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

Here is what each part means:

- `CREATE DATABASE IF NOT EXISTS db_rust_todo` creates an empty database. `IF NOT EXISTS` makes the statement safe to run twice; the second time it does nothing instead of failing.
- `CHARACTER SET utf8mb4` stores text as full UTF-8, so task titles can contain any language and even emoji. The older `utf8` character set in MySQL cannot store every character, so `utf8mb4` is the right choice for new projects. Rust strings are always UTF-8 too, which makes the two a natural match.
- `COLLATE utf8mb4_unicode_ci` decides how text is compared and sorted. The `ci` suffix means case-insensitive, so a search for `rust` also finds `Rust`.

MySQL answers with `Query OK, 1 row affected`.

### Step 2: Create the User

Still at the administrator prompt, create the account the application will use:

```sql
CREATE USER IF NOT EXISTS 'todo_user'@'localhost' IDENTIFIED BY 'todo_password';
```

A MySQL account has two parts: a name (`todo_user`) and the host it may connect from (`localhost`, meaning only programs on this same computer). `IDENTIFIED BY` sets the password. `todo_password` is an example for your local machine; on a real server, choose a long random password and never commit it to Git. In Lesson 7, you will move it into a `.env` file for exactly that reason.

### Step 3: Grant Privileges

A new user can log in, but it cannot touch any data yet. Grant it full control over the project database, and over the temporary databases that SQLx creates for tests:

```sql
GRANT ALL PRIVILEGES ON db_rust_todo.* TO 'todo_user'@'localhost';
GRANT ALL PRIVILEGES ON `\_sqlx\_test%`.* TO 'todo_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Line by line:

- `GRANT ALL PRIVILEGES ON db_rust_todo.*` allows every operation (creating tables, reading, writing, deleting) on every table (`*`) inside `db_rust_todo`, and nowhere else.
- The second `GRANT` prepares for Lesson 18. The `#[sqlx::test]` attribute creates a fresh database for every test, with names that start with `_sqlx_test`, and deletes it afterwards. The `%` is a wildcard that matches any ending. In a database name pattern, `_` is also a wildcard that matches any single character, so the backslashes in `\_` make it mean a literal underscore. The backticks are needed because the name contains special characters.
- `FLUSH PRIVILEGES` tells the server to reload its privilege tables. Modern versions apply `GRANT` immediately, so this line is just a harmless safety net.
- `EXIT` leaves the administrator session.

Each `GRANT` answers with `Query OK, 0 rows affected`. That is normal: granting privileges does not change any rows in your own tables.

---

## 4. Log In as the Application User

From now on, you will only use `todo_user`. Logging in with it is the best test that the account works, because it is exactly what your Rust code will do.

### Step 1: Connect and Check the Account

Connect with the new account. `-u` sets the user name and `-p` tells the client to ask for the password:

```bash
mysql -u todo_user -p
```

Type `todo_password` when the client asks for it; the characters are not shown while you type. Then check who you are logged in as:

```sql
SELECT CURRENT_USER();
```

Output:

```text
+---------------------+
| CURRENT_USER()      |
+---------------------+
| todo_user@localhost |
+---------------------+
1 row in set (0.000 sec)
```

`CURRENT_USER()` returns the account the server actually used to authenticate you, including the host part. The time in parentheses is how long the query took; it will vary on your machine.

### Step 2: Check the Privileges

Ask the server which privileges this account has:

```sql
SHOW GRANTS;
```

Output:

```text
+------------------------------------------------------------------------------------------------------------------+
| Grants for todo_user@localhost                                                                                   |
+------------------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `todo_user`@`localhost` IDENTIFIED BY PASSWORD '*3F74EA0504AE4A08108F01BD5E863B61442CAA1D' |
| GRANT ALL PRIVILEGES ON `db_rust_todo`.* TO `todo_user`@`localhost`                                              |
| GRANT ALL PRIVILEGES ON `\_sqlx\_test%`.* TO `todo_user`@`localhost`                                             |
+------------------------------------------------------------------------------------------------------------------+
3 rows in set (0.000 sec)
```

There are three lines. `GRANT USAGE ON *.*` sounds powerful but means the opposite: "may log in, with no privileges anywhere." The long value after `PASSWORD` is a hash of the password, not the password itself. The other two lines are the grants you created. On MySQL 8, the first line does not show the password hash.

### Step 3: List the Databases

```sql
SHOW DATABASES;
```

Output:

```text
+--------------------+
| Database           |
+--------------------+
| db_rust_todo       |
| information_schema |
+--------------------+
2 rows in set (0.001 sec)
```

`todo_user` sees only the databases it has privileges for, plus `information_schema`, a read-only database every user can query to learn about tables and columns. The administrator would see more databases here, such as `mysql`, but they are invisible to this account. This is the principle of least privilege in action.

---

## 5. Practice the SQL Your App Will Use

The application will store tasks in a table with an ID, a title, and a done flag. In Lesson 8, a migration will create the real `tasks` table. Here, you will create a temporary practice table with the same idea, so you can see each statement and its result before it is hidden inside Rust code.

### Step 1: Select the Database and Create a Table

Still logged in as `todo_user`, select the project database:

```sql
USE db_rust_todo;
```

The client answers `Database changed`, and the prompt changes to `MariaDB [db_rust_todo]>`. Now create the table:

```sql
CREATE TABLE practice_tasks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE
);
```

The client lets you type a statement over several lines; it shows a `->` prompt until it sees the semicolon. Here is what each column definition means:

- `id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY` is a positive whole number that MySQL fills in automatically (1, 2, 3, ...). `PRIMARY KEY` makes it the unique identifier of each row. In your Rust code, this is the number in URLs such as `/tasks/3`.
- `title VARCHAR(255) NOT NULL` is text of up to 255 characters. `NOT NULL` means every task must have a title.
- `done BOOLEAN NOT NULL DEFAULT FALSE` is the completed flag. New rows are not done unless you say otherwise.

Output:

```text
Query OK, 0 rows affected (0.016 sec)
```

Check the table structure:

```sql
DESCRIBE practice_tasks;
```

Output:

```text
+-------+------------------+------+-----+---------+----------------+
| Field | Type             | Null | Key | Default | Extra          |
+-------+------------------+------+-----+---------+----------------+
| id    | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
| title | varchar(255)     | NO   |     | NULL    |                |
| done  | tinyint(1)       | NO   |     | 0       |                |
+-------+------------------+------+-----+---------+----------------+
3 rows in set (0.002 sec)
```

Notice the `done` column. MySQL has no real boolean type: `BOOLEAN` is stored as `tinyint(1)`, a tiny integer where `0` means false and `1` means true. This detail will matter in Lesson 9, when SQLx converts this column into a Rust `bool`.

### Step 2: Insert and Read Rows

Insert three tasks with one statement:

```sql
INSERT INTO practice_tasks (title) VALUES ('Learn Rust'), ('Build a web app'), ('Connect to MySQL');
```

Only `title` is listed. `id` is filled by `AUTO_INCREMENT` and `done` by its default.

Output:

```text
Query OK, 3 rows affected (0.005 sec)
Records: 3  Duplicates: 0  Warnings: 0
```

Read them back:

```sql
SELECT * FROM practice_tasks;
```

Output:

```text
+----+------------------+------+
| id | title            | done |
+----+------------------+------+
|  1 | Learn Rust       |    0 |
|  2 | Build a web app  |    0 |
|  3 | Connect to MySQL |    0 |
+----+------------------+------+
3 rows in set (0.001 sec)
```

### Step 3: Update, Filter, and Delete

Mark the first task as done. The `WHERE` clause chooses which rows to change; without it, every row would be updated.

```sql
UPDATE practice_tasks SET done = TRUE WHERE id = 1;
```

Output:

```text
Query OK, 1 row affected (0.007 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

`Rows matched` counts the rows the `WHERE` clause found, and `Changed` counts the rows whose values actually changed. In Lesson 12, your Rust code will use the number of affected rows to tell whether a task with the requested ID existed.

Now show only the unfinished tasks:

```sql
SELECT id, title, done FROM practice_tasks WHERE done = FALSE;
```

Output:

```text
+----+------------------+------+
| id | title            | done |
+----+------------------+------+
|  2 | Build a web app  |    0 |
|  3 | Connect to MySQL |    0 |
+----+------------------+------+
2 rows in set (0.001 sec)
```

Delete the third task and check the result:

```sql
DELETE FROM practice_tasks WHERE id = 3;
SELECT * FROM practice_tasks;
```

Output:

```text
Query OK, 1 row affected (0.006 sec)

+----+-----------------+------+
| id | title           | done |
+----+-----------------+------+
|  1 | Learn Rust      |    1 |
|  2 | Build a web app |    0 |
+----+-----------------+------+
2 rows in set (0.001 sec)
```

Task 1 now shows `done` as `1`, and task 3 is gone.

### Step 4: Drop the Practice Table

The real `tasks` table will be created by a migration in Lesson 8, so remove the practice table to leave the database empty:

```sql
DROP TABLE practice_tasks;
SHOW TABLES;
```

Output:

```text
Query OK, 0 rows affected (0.013 sec)

Empty set (0.001 sec)
```

Type `EXIT` to leave the client. The database is ready and empty, waiting for your Rust application.

---

## 6. Run and Test

Before moving on, run a final check from the shell without opening an interactive session. The `-e` option executes one or more statements and exits, which is handy for quick checks and scripts:

```bash
mysql -u todo_user -p -e "SELECT CURRENT_USER(); SHOW DATABASES;"
```

After you type the password, the client prints the same tables you saw in Section 4, but in a compact format without borders, because its output is going straight back to the shell:

```text
CURRENT_USER()
todo_user@localhost
Database
db_rust_todo
information_schema
```

If you see `todo_user@localhost` and `db_rust_todo`, everything is in place for the rest of the course. Keep these three values handy, because Lesson 7 puts them into a connection URL:

| Setting | Value |
| --- | --- |
| Database | `db_rust_todo` |
| User | `todo_user` |
| Password | `todo_password` |

---

## 7. How the Application Talks to MySQL

You have been talking to MySQL through the `mysql` client. Your Rust application will do the same thing, just without a person typing. It helps to know what happens on that connection.

- **MySQL is a server.** It runs as a separate program and listens for connections, by default on port 3306. The `mysql` client, your Rust application, and graphical tools such as DBeaver are all clients of the same server.
- **Every connection logs in.** A client sends a user name and password, and the server checks them against the account (`todo_user@localhost`). Each client connection then has its own session, including the selected database.
- **SQL travels as text, results come back as rows.** Your Rust code will send exactly the statements you typed in this lesson, and SQLx will turn the rows that come back into Rust structs.
- **Opening connections is slow.** Logging in takes a network round trip and some work on the server. A web application handling many requests should not log in again for every request. In Lesson 7, you will create a connection pool: a set of open connections that handlers borrow and return.
- **Privileges limit damage.** Because `todo_user` can only touch `db_rust_todo` and the test databases, even a serious bug in your application cannot drop another project's database.

---

## 8. Fix the Errors in Your Code

**Error 1: Wrong password or user name**

```bash
# Wrong: the password does not match the one set with IDENTIFIED BY
mysql -u todo_user -pwrong_password
```

```bash
# Correct: let the client ask for the password
mysql -u todo_user -p
```

Output for the wrong version:

```text
ERROR 1045 (28000): Access denied for user 'todo_user'@'localhost' (using password: YES)
```

Error 1045 means the server rejected the login. Either the password is wrong, the user name is misspelled, or the user was never created. `(using password: YES)` confirms that a password was sent. Writing the password right after `-p` (with no space) works, but it ends up in your shell history; letting the client ask for it is safer.

**Error 2: Using a database without privileges**

```bash
# Wrong: todo_user has no privileges on the mysql system database
mysql -u todo_user -p -e "USE mysql;"
```

```bash
# Correct: use the project database
mysql -u todo_user -p -e "USE db_rust_todo;"
```

Output for the wrong version, after the password:

```text
ERROR 1044 (42000) at line 1: Access denied for user 'todo_user'@'localhost' to database 'mysql'
```

Error 1044 means the login worked, but this account may not use that database. If you see it for `db_rust_todo`, the `GRANT` from Section 3 was not run or contains a typo; log in with `sudo mysql` and run it again.

**Error 3: Querying a table that does not exist yet**

```sql
-- Wrong: the tasks table is created by a migration in Lesson 8
SELECT title FROM tasks;
```

```sql
-- Correct: check which tables exist first
SHOW TABLES;
```

Output for the wrong version:

```text
ERROR 1146 (42S02): Table 'db_rust_todo.tasks' doesn't exist
```

Error 1146 names the database and table it looked for, which usually reveals the problem: a misspelled table name, the wrong database selected with `USE`, or a migration that has not run yet. You will see this same message inside a Rust error if your code queries a table before its migration has run.

**Error 4: Forgetting the semicolon**

If you press Enter after a statement without a semicolon, nothing seems to happen; the prompt simply changes to `->`:

```text
MariaDB [db_rust_todo]> SELECT 1 + 1
    -> ;
+-------+
| 1 + 1 |
+-------+
|     2 |
+-------+
1 row in set (0.000 sec)
```

The client is waiting for the rest of the statement. Type `;` and press Enter to run it, or type `\c` to cancel the statement and start over.

---

## 9. Exercises

**Exercise 1:** Log in as `todo_user`, select `db_rust_todo`, and create a practice table `practice_notes` with an auto-increment `id`, a `body` column of type `TEXT` that cannot be null, and a `pinned` boolean that defaults to false. Check it with `DESCRIBE`, then drop it.

**Exercise 2:** Recreate the `practice_tasks` table from Section 5, insert four tasks, mark two of them as done with a single `UPDATE` statement using `WHERE id IN (...)`, and count the unfinished tasks with `SELECT COUNT(*)`. Drop the table when you are done.

**Exercise 3:** Use `-e` to run a query from the shell that lists the tables in `db_rust_todo` together with their creation time. Hint: query the `TABLES` table in `information_schema`, filtering on `TABLE_SCHEMA`. Run it once while a practice table exists and once after dropping it.

---

## 10. Solutions

**Solution for Exercise 1:**

```sql
USE db_rust_todo;

CREATE TABLE practice_notes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    body TEXT NOT NULL,
    pinned BOOLEAN NOT NULL DEFAULT FALSE
);

DESCRIBE practice_notes;

DROP TABLE practice_notes;
```

`TEXT` stores long text, up to about 64 KB, without a fixed maximum length like `VARCHAR(255)`. It suits note bodies, while `VARCHAR` suits short values such as titles. `DESCRIBE` shows `body` as `text` and `pinned` as `tinyint(1)` with default `0`, the same boolean storage you saw for `done`.

**Solution for Exercise 2:**

```sql
USE db_rust_todo;

CREATE TABLE practice_tasks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO practice_tasks (title)
VALUES ('Learn Rust'), ('Build a web app'), ('Connect to MySQL'), ('Write tests');

UPDATE practice_tasks SET done = TRUE WHERE id IN (1, 3);

SELECT COUNT(*) FROM practice_tasks WHERE done = FALSE;

DROP TABLE practice_tasks;
```

`WHERE id IN (1, 3)` matches every row whose ID is in the list, so one statement updates both tasks and reports `2 rows affected`. `COUNT(*)` counts the rows that match the `WHERE` clause instead of returning them, so the result is a single number: `2`. In Lesson 16, a query like this will power the "pending tasks" counter and the page count for pagination.

**Solution for Exercise 3:**

```bash
mysql -u todo_user -p -e "SELECT TABLE_NAME, CREATE_TIME FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'db_rust_todo';"
```

`information_schema.TABLES` has one row per table the current user can see. Filtering on `TABLE_SCHEMA = 'db_rust_todo'` keeps only the project's tables, and `CREATE_TIME` shows when each one was created. While `practice_tasks` exists, the query prints its name and creation time; after `DROP TABLE`, it prints nothing at all, because an empty result in `-e` mode has no header. Tools such as sqlx-cli use `information_schema` in a similar way to inspect a database.

---

## Next Up - Lesson 4

In this lesson, you installed the database server, created the `db_rust_todo` database with `utf8mb4`, and set up a `todo_user` account that can reach only the project and test databases. You also practiced the SQL statements at the heart of the to-do app and learned to read MySQL's most common error messages.

With the async foundations and the database ready, it is time to write the real application. In Lesson 4, you will create the `todo-web` Cargo project, add Axum, start a web server, and map URLs to async handler functions that return text, HTML, and HTTP status codes.
