## 1. Before You Begin

In the previous lesson, you connected PHP to MySQL and inserted sample data. But the data stored in the database is not yet visible in the browser - it only exists inside MySQL tables. This lesson bridges the two: fetching data from the database and rendering it as a web page.

This is the pattern used most often in web development: the user opens a page, PHP sends a query to the database, the database returns rows of data, PHP renders those rows into HTML, and the browser displays the result. Every dynamic website - from online stores to social media - works with this exact pattern.

### What You'll Build

You will build a journal entry listing page whose data comes directly from the database, and a detail page for reading a single entry in full. Together these two pages form the Read part of a CRUD application.

### What You'll Learn

- ✅ How to run SELECT queries with PDO
- ✅ The difference between `fetch()` (one row) and `fetchAll()` (all rows)
- ✅ How to display database data inside HTML
- ✅ How to use `$_GET` for a dynamic detail page
- ✅ How to handle data not found (404 scenario)

### What You'll Need

- Termux open with Apache and MariaDB running
- The `db_catatku` database with sample data from Lesson 10
- Lessons 1 through 10 completed

---

## 2. Setup

Create a dedicated folder for this lesson inside your project directory.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-11
cd lesson-11
```

This lesson reuses the shared `config.php` in the `learn-php` root folder created in Lesson 10. Files here will load it with `require_once __DIR__ . '/../config.php'`.

---

## 3. Displaying the Entry Listing

The listing page is the starting point for most data-driven applications. It fetches all rows from a table and renders them as an HTML table, with a link from each row to its full detail page.

### Step 1: Create the File

Make sure you are in the `lesson-11` folder, then open a new file:

```bash
micro list.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt    = $pdo->query("SELECT * FROM entries ORDER BY created_at DESC");
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Entries - Catatku</title>
</head>
<body>

    <h1>Catatku - Entry List</h1>

    <?php if (empty($entries)): ?>
        <p>No entries yet. Start writing your first entry!</p>
    <?php else: ?>
        <table border="1" cellpadding="10" cellspacing="0">
            <tr>
                <th>No</th>
                <th>Title</th>
                <th>Date</th>
                <th>Action</th>
            </tr>
            <?php $no = 1; ?>
            <?php foreach ($entries as $entry): ?>
                <tr>
                    <td><?= $no++ ?></td>
                    <td><?= htmlspecialchars($entry['title']) ?></td>
                    <td><?= htmlspecialchars($entry['created_at']) ?></td>
                    <td>
                        <a href="detail.php?id=<?= $entry['id'] ?>">Read</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
        <p>Total: <?= count($entries) ?> entries</p>
    <?php endif; ?>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL:

```
http://localhost:8080/learn-php/lesson-11/list.php
```

You will see an HTML table containing all three entries from the database, with a number, title, date, and a "Read" link for each.

`$pdo->query("SELECT * FROM entries ORDER BY created_at DESC")` sends the SQL command to the database. Because this query contains no user input, `query()` is safe to use directly without `prepare()`. `ORDER BY created_at DESC` sorts rows from newest to oldest so the most recent entry appears first. `$stmt->fetchAll()` retrieves all result rows at once and returns them as a PHP array of associative arrays. Each element represents one row, so `$entry['title']` accesses the title column and `$entry['created_at']` accesses the timestamp. The `if (empty($entries))` block handles the case where no rows exist yet, displaying a friendly message instead of an empty table. `htmlspecialchars($entry['title'])` escapes the title before inserting it into HTML. Even though the data comes from the database, it was originally entered by a user and may contain characters that the browser would interpret as HTML markup. The link `detail.php?id=<?= $entry['id'] ?>` passes the entry's database ID through the URL so the detail page knows which record to fetch.

---

## 4. The Detail Page: Displaying a Single Entry

The detail page receives an ID from the URL, queries the database for exactly that row, and renders the full content. It must handle two edge cases: an ID that is not a valid number, and an ID that does not exist in the database.

### Step 1: Create the File

Make sure you are in the `lesson-11` folder, then open a new file:

```bash
micro detail.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) {
    echo "<h1>Error</h1>";
    echo "<p>Invalid entry ID.</p>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}

$stmt = $pdo->prepare("
    SELECT entries.*, users.name AS author_name
    FROM entries
    INNER JOIN users ON entries.user_id = users.id
    WHERE entries.id = :id
");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<h1>Entry Not Found</h1>";
    echo "<p>The entry with ID $id does not exist in the database.</p>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars($entry['title']) ?> - Catatku</title>
</head>
<body>

    <p><a href="list.php">&larr; Back to list</a></p>

    <h1><?= htmlspecialchars($entry['title']) ?></h1>

    <p><small>
        Written by: <?= htmlspecialchars($entry['author_name']) ?> |
        Date: <?= htmlspecialchars($entry['created_at']) ?>
        <?php if ($entry['updated_at'] && $entry['updated_at'] !== $entry['created_at']): ?>
            | Updated: <?= htmlspecialchars($entry['updated_at']) ?>
        <?php endif; ?>
    </small></p>

    <hr>

    <div style="white-space: pre-line;">
        <?= htmlspecialchars($entry['content']) ?>
    </div>

    <hr>

    <p><a href="list.php">Back to list</a></p>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

From the listing page, click the "Read" link on any entry. Or navigate directly to:

```
http://localhost:8080/learn-php/lesson-11/detail.php?id=1
```

Also test with an ID that does not exist:

```
http://localhost:8080/learn-php/lesson-11/detail.php?id=999
```

The second URL will show the "Entry Not Found" error message.

`(int) $_GET['id']` explicitly converts the URL parameter to an integer. `$_GET` always returns a string, so even a numeric-looking value like `"3"` is technically a string. Casting to `int` ensures the value is a whole number before it touches the database, and also neutralizes any non-numeric input by converting it to zero. The check `if ($id <= 0)` immediately stops the script if the cast produced zero or a negative number, because those are not valid database IDs. The SQL uses `INNER JOIN users ON entries.user_id = users.id` to retrieve the author's name alongside the entry data in a single query. `AS author_name` gives the joined column a clear alias so it can be accessed as `$entry['author_name']`. `$stmt->fetch()` retrieves one row or returns `false` if no match was found. The `if (!$entry)` check catches the not-found case, displays a helpful message, and calls `exit` to stop the script before any code tries to access columns on the non-existent row. `white-space: pre-line` in the CSS tells the browser to preserve line breaks in the content field, which would otherwise be collapsed into a single long line.

---

## 5. Fix the Errors in Your Code

This section presents three mistakes that are common when first building pages that read from a database. Two are security vulnerabilities and one causes a PHP fatal error on any ID that does not exist.

**Error 1: Embedding URL parameter data directly in a SQL query.**

`$_GET['id']` comes from the browser and must never be placed directly inside a SQL string. A malicious user could pass a crafted value that alters the query logic.

```php
// Wrong
$id   = $_GET['id'];
$stmt = $pdo->query("SELECT * FROM entries WHERE id = $id");

// Correct
$id   = (int) $_GET['id'];
$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
```

Casting to `(int)` first converts the input to an integer, and the prepared statement sends it as data rather than embedding it in the SQL text. Together these two steps guarantee that the value can never expand into SQL commands.

---

**Error 2: Accessing fetch result columns without checking if a row was found.**

`fetch()` returns `false` when no row matches the query. Accessing an array key on `false` causes a PHP warning or fatal error, and the page renders with missing data or crashes.

```php
// Wrong
$entry = $stmt->fetch();
echo "<h1>" . $entry['title'] . "</h1>";

// Correct
$entry = $stmt->fetch();
if (!$entry) {
    echo "<p>Entry not found.</p>";
    exit;
}
echo "<h1>" . htmlspecialchars($entry['title']) . "</h1>";
```

Checking `if (!$entry)` before accessing any column is mandatory whenever you use `fetch()`. If the row does not exist, display a meaningful message and call `exit` to stop the script cleanly.

---

**Error 3: Displaying database content without `htmlspecialchars()`.**

Even though the content came from the database, it was originally typed by a user and may contain characters that the browser interprets as HTML. Displaying it without escaping creates an XSS vulnerability.

```php
// Wrong
echo "<p>" . $entry['content'] . "</p>";

// Correct
echo "<p>" . htmlspecialchars($entry['content']) . "</p>";
```

`htmlspecialchars()` converts `<`, `>`, `"`, `'`, and `&` to their HTML entity equivalents, so even if the content contains `<script>` tags they are displayed as visible text rather than executed. Apply it to every database value that gets inserted into HTML output.

---

## 6. Exercises

Complete the following exercises in the `lesson-11` folder. Each file must begin with `require_once __DIR__ . '/../config.php';`.

**Exercise 1:** Create `exercise-1.php`. Display a list of all users from the `users` table in an HTML table with four columns: No, Name, Email, and Registered Date.

**Exercise 2:** Create `exercise-2.php`. Display entries written by a specific user. Read the user ID from a URL parameter named `user_id` (e.g. `exercise-2.php?user_id=1`). Show the user's name at the top of the page and all their entries below. Use a JOIN to fetch the user's name and a separate query to fetch their entries.

**Exercise 3:** Create `exercise-3.php`. Display database statistics: the total number of users, the total number of entries, and the title and date of the most recent entry. Use three separate queries.

---

## 7. Solutions

**Solution for Exercise 1:**

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt  = $pdo->query("SELECT * FROM users ORDER BY created_at DESC");
$users = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>User List</title></head>
<body>
    <h1>User List</h1>
    <table border="1" cellpadding="8" cellspacing="0">
        <tr><th>No</th><th>Name</th><th>Email</th><th>Registered</th></tr>
        <?php $no = 1; ?>
        <?php foreach ($users as $user): ?>
            <tr>
                <td><?= $no++ ?></td>
                <td><?= htmlspecialchars($user['name']) ?></td>
                <td><?= htmlspecialchars($user['email']) ?></td>
                <td><?= htmlspecialchars($user['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
```

`SELECT * FROM users ORDER BY created_at DESC` fetches all user rows sorted from newest registration to oldest. `fetchAll()` returns them as an array of associative arrays, which `foreach` then iterates. The `$no++` idiom starts the display counter at 1 and increments it after each row, giving each user a sequential number without needing to track the database's auto-incremented `id` column.

---

**Solution for Exercise 2:**

```php
<?php
require_once __DIR__ . '/../config.php';

$user_id = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;

if ($user_id <= 0) {
    echo "<p>Invalid user_id parameter. Example: exercise-2.php?user_id=1</p>";
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
$stmt->execute(['id' => $user_id]);
$user = $stmt->fetch();

if (!$user) {
    echo "<p>User not found.</p>";
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM entries WHERE user_id = :user_id ORDER BY created_at DESC");
$stmt->execute(['user_id' => $user_id]);
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Entries by <?= htmlspecialchars($user['name']) ?></title></head>
<body>
    <h1>Entries by <?= htmlspecialchars($user['name']) ?></h1>
    <p>Email: <?= htmlspecialchars($user['email']) ?></p>
    <?php if (empty($entries)): ?>
        <p>No entries yet.</p>
    <?php else: ?>
        <ul>
            <?php foreach ($entries as $entry): ?>
                <li><strong><?= htmlspecialchars($entry['title']) ?></strong>
                    (<?= htmlspecialchars($entry['created_at']) ?>)</li>
            <?php endforeach; ?>
        </ul>
    <?php endif; ?>
</body>
</html>
```

The user is fetched first with a prepared statement. If the user does not exist, the script stops cleanly with `exit` before attempting to fetch entries. The entries query uses a separate prepared statement filtered by `user_id`, which ensures only that user's entries are returned. Both the user check and the entries fetch use prepared statements because both receive external input from `$_GET`.

---

**Solution for Exercise 3:**

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt       = $pdo->query("SELECT COUNT(*) AS total FROM users");
$user_count = $stmt->fetch()['total'];

$stmt        = $pdo->query("SELECT COUNT(*) AS total FROM entries");
$entry_count = $stmt->fetch()['total'];

$stmt   = $pdo->query("SELECT title, created_at FROM entries ORDER BY created_at DESC LIMIT 1");
$latest = $stmt->fetch();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Database Statistics</title></head>
<body>
    <h1>Catatku Database Statistics</h1>
    <ul>
        <li>Total users: <strong><?= $user_count ?></strong></li>
        <li>Total entries: <strong><?= $entry_count ?></strong></li>
        <li>Latest entry:
            <?php if ($latest): ?>
                <strong><?= htmlspecialchars($latest['title']) ?></strong>
                (<?= htmlspecialchars($latest['created_at']) ?>)
            <?php else: ?>
                No entries yet
            <?php endif; ?>
        </li>
    </ul>
</body>
</html>
```

`$stmt->fetch()['total']` chains the method call and array access in one expression, producing the count value directly without storing the intermediate row in a separate variable. `SELECT COUNT(*) AS total` asks the database to count all rows and name the result column `total`. The third query uses `LIMIT 1` to retrieve only the most recently created entry rather than fetching all rows and discarding everything but the first. This is more efficient because MySQL applies the limit before returning data to PHP.

---

## Next Up - Lesson 12

You can now build pages that read from MySQL and display the data dynamically. `fetchAll()` retrieves every matching row for listings. `fetch()` retrieves one row for detail pages and returns `false` when nothing matches, which you must always check before accessing column values. URL parameters (`$_GET['id']`) tell the detail page which record to load, and casting to `(int)` combined with prepared statements keeps those lookups safe. Always apply `htmlspecialchars()` to every database value before inserting it into HTML output.

In Lesson 12, you will complete the full CRUD cycle by building the Create, Update, and Delete operations: a form to write new journal entries, a form to edit existing ones, and a confirmation flow to delete them.