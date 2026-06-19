## 1. Before You Begin

The blog needs a database to store posts. CI3 uses a configuration file (`database.php`) for connection settings and a built-in **Query Builder** for constructing SQL queries without writing raw SQL. This lesson connects CI3 to MySQL and creates the posts table.

### What You'll Build

You will configure the database connection, create the `ci3_blog` database and `posts` table, and verify the connection.

### What You'll Learn

- ✅ Configuring `database.php` for MySQL
- ✅ Creating the database and table manually
- ✅ Testing the connection from a controller
- ✅ Understanding CI3's database configuration options

### What You'll Need

- MySQL running (Laragon Start All)
- HeidiSQL or MySQL CLI for creating the database

---

## 2. Create the Database

We need to prepare our MySQL database and the table schema to store blog posts.

### Step 1: Open HeidiSQL

In Laragon, click **Database** to open HeidiSQL. If you prefer the command line, you can also connect to MySQL directly from your terminal.

```bash
mysql -u root -p
```

This command opens the MySQL interactive shell. The `-u root` flag tells MySQL to log in as the `root` user, and `-p` prompts you to enter a password. In a standard Laragon setup, the password is usually empty — just press **Enter** when prompted.

### Step 2: Create the Database

Before creating tables, we need to create a dedicated database for the blog application and switch into it.

```sql
CREATE DATABASE ci3_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ci3_blog;
```

`CREATE DATABASE ci3_blog` creates a new database named `ci3_blog`. The `CHARACTER SET utf8mb4` and `COLLATE utf8mb4_unicode_ci` ensure the database can store a wide range of characters, including emoji and non-Latin alphabets. `USE ci3_blog` then switches the active context to that new database so all subsequent commands apply to it.

### Step 3: Create the Posts Table

Now we create the `posts` table that will hold every blog post in our application.

```sql
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status ENUM('draft', 'publish') NOT NULL DEFAULT 'draft',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

Here is what each column does:

- **`id`**: A unique integer that auto-increments with every new post. It serves as the primary key, meaning each row can be identified by this number.
- **`title`**: The post title, stored as a string of up to 255 characters. `NOT NULL` means it cannot be left empty.
- **`slug`**: A URL-friendly version of the title (e.g., `my-first-post`). It is used to form readable URLs.
- **`content`**: The full body of the post. `TEXT` can hold up to 65,535 characters, which is more than enough for most blog posts.
- **`status`**: An `ENUM` field that only accepts the values `'draft'` or `'publish'`. The default is `'draft'`, so newly created posts are hidden from public view until explicitly published.
- **`created_at`**: Automatically records the date and time when a row is inserted.
- **`updated_at`**: Automatically updates to the current timestamp every time that row is modified.
- **`ENGINE=InnoDB`**: Specifies the storage engine. InnoDB supports foreign keys and transactions, making it the recommended engine for modern MySQL applications.

### Step 4: Insert Sample Data

To avoid starting with an empty application, we insert three sample posts to test with.

```sql
INSERT INTO posts (title, slug, content, status) VALUES
('Getting Started with CodeIgniter', 'getting-started-with-codeigniter', 'CodeIgniter is a lightweight PHP framework...', 'publish'),
('Understanding MVC Pattern', 'understanding-mvc-pattern', 'MVC stands for Model-View-Controller...', 'publish'),
('Query Builder in CI3', 'query-builder-in-ci3', 'Query Builder lets you build SQL queries...', 'draft');
```

This `INSERT INTO` statement inserts three rows at once. Notice that `id`, `created_at`, and `updated_at` are omitted — MySQL will fill them in automatically based on the column definitions we set earlier.

---

## 3. Configure database.php

Now we will configure CodeIgniter to connect to the database we just created.

### Step 1: Open the File

Open `application/config/database.php` in VS Code. This file contains the connection settings that CI3 uses to talk to MySQL.

### Step 2: Update the Settings

Locate the `$db['default']` array and update it to match your local MySQL setup.

```php
$db['default'] = array(
    'dsn'      => '',
    'hostname' => 'localhost',
    'username' => 'root',
    'password' => '',
    'database' => 'ci3_blog',
    'dbdriver' => 'mysqli',
    'dbprefix' => '',
    'pconnect' => FALSE,
    'db_debug' => (ENVIRONMENT !== 'production'),
    'cache_on' => FALSE,
    'cachedir' => '',
    'char_set' => 'utf8mb4',
    'dbcollat' => 'utf8mb4_unicode_ci',
    'swap_pre' => '',
    'encrypt'  => FALSE,
    'compress'  => FALSE,
    'stricton' => FALSE,
    'failover' => array(),
    'save_queries' => TRUE
);
```

The key fields to pay attention to are:

- **`hostname`**: The address of your MySQL server. For local development, this is almost always `localhost`.
- **`username`**: The MySQL user. Laragon uses `root` by default.
- **`password`**: The password for that user. In a default Laragon installation, this is empty.
- **`database`**: The name of the database to connect to — in our case, `ci3_blog`.
- **`dbdriver`**: The PHP extension used to communicate with MySQL. `mysqli` is the modern, recommended driver (as opposed to the older `mysql`).
- **`db_debug`**: When set to `TRUE`, CI3 will display database errors directly on the page. This is fine during development but should always be `FALSE` in production.
- **`char_set` and `dbcollat`**: These must match what we specified when creating the database (`utf8mb4` and `utf8mb4_unicode_ci`).

### Step 3: Save the File

Press **Ctrl+S** to save. CI3 will load this configuration automatically on the next request.

### Step 4: Ensure the Database Library Is Autoloaded

CI3's database library is not loaded by default — we need to tell CI3 to load it on every request. Open `application/config/autoload.php` and verify the `libraries` entry looks like this.

```php
$autoload['libraries'] = array('database', 'session');
```

Adding `'database'` here means CI3 will instantiate a database connection automatically on every page load, making `$this->db` available inside any controller without needing to call `$this->load->database()` manually each time.

---

## 4. Test the Connection

Now let's verify that everything is wired up correctly by fetching posts from the database. Open `application/controllers/Posts.php` and temporarily update the `index()` method.

```php
public function index()
{
    $query = $this->db->get('posts');
    $data['title'] = 'All Posts';
    $data['posts'] = $query->result_array();
    $this->load->view('posts/index', $data);
}
```

`$this->db->get('posts')` is the simplest Query Builder call: it runs `SELECT * FROM posts` and returns a query result object. Calling `->result_array()` on that object converts every row into a regular PHP associative array, so `$data['posts']` becomes an array of arrays — one entry per post.

Visit `http://localhost/ci3-blog/posts`. If the configuration is correct, you should see the three seed posts from the database rendered on the page instead of the hardcoded dummy data from Lesson 3.

---

## 5. Fix the Errors in Your Code

Here are some common database connection errors and how to fix them.

**Error 1: Unable to connect to your database server.**
Double-check the credentials in your `database.php` file. Ensure the hostname, username, password, and database name are exactly correct.

**Error 2: Table doesn't exist.**
Ensure you are using the correct table name. If the table is `posts` (plural), attempting to query `post` (singular) will throw an error.

```php
// Incorrect
$this->db->get('post');

// Correct
$this->db->get('posts');
```

CI3's Query Builder does not validate table names before running the query — it will happily run `SELECT * FROM post` against MySQL and receive an error response from the database. Always double-check that the table name string exactly matches the name you used in `CREATE TABLE`.

**Error 3: Database library not loaded.**
If you receive an error stating that the property `db` does not exist on `$this`, it means the database library isn't loaded. Add `'database'` to your `autoload.php` libraries array, or load it manually.

---

## 6. Exercises

Test your understanding of database connections and basic queries.

**Exercise 1:** Log in to MySQL and verify the `posts` table exists with `DESCRIBE posts;`.

**Exercise 2:** Add 2 more posts via SQL INSERT. Refresh the posts page to see them.

**Exercise 3:** In the controller, use `$this->db->count_all('posts')` to display the total post count on the page.

---

## 7. Solutions

Here are answers to the exercises above.

**Solution for Exercise 1:**

Open the MySQL CLI and run the following commands in order:

```sql
mysql -u root -p
USE ci3_blog;
DESCRIBE posts;
```

`DESCRIBE posts` asks MySQL to output the structure of the `posts` table — each column name, its data type, whether it allows NULL, and its default value. This is the quickest way to confirm the table was created exactly as intended.

**Solution for Exercise 2:**

```sql
INSERT INTO posts (title, slug, content, status) VALUES
('PHP Best Practices', 'php-best-practices', 'Always use prepared statements...', 'publish'),
('CSS Flexbox Guide', 'css-flexbox-guide', 'Flexbox simplifies layout...', 'publish');
```

**Solution for Exercise 3:**

```php
$data['post_count'] = $this->db->count_all('posts');
```

In the view, display the count like this:

```php
<p>Total: <?php echo $post_count; ?> posts</p>
```

`count_all('posts')` runs `SELECT COUNT(*) FROM posts` and returns an integer. Storing it in `$data['post_count']` makes it available as `$post_count` inside the view.

---

## Next Up - Lesson 6

`database.php` holds MySQL connection settings. The database library is auto-loaded via `autoload.php`. `$this->db->get('table')` queries the table. CI3's database library wraps MySQLi and provides Query Builder methods.

In Lesson 6, you will create the Post_model with Query Builder methods for all CRUD operations.