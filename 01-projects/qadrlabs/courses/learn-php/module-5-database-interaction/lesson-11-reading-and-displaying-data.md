## 1. Before You Begin

In Lesson 10 you connected PHP to MySQL and inserted sample data. That data now lives in the database permanently, but it is invisible until you fetch it and render it as HTML. This lesson teaches you exactly that: running SELECT queries from PHP, processing the results, and building pages that display real data pulled from a real database.

### Introduction

Fetching and displaying data is the most fundamental read operation in web development. Every product listing, blog feed, user dashboard, and search result page you have ever visited is powered by this exact pattern: PHP queries the database, loops through the rows, and renders each one as HTML. By the end of this lesson, Catatku will have a working entry listing page and a detail page for reading individual entries.

### What You'll Build

You will build an entry listing page (`list.php`) that shows all journal entries in a table, and a detail page (`detail.php`) that displays one full entry based on a URL parameter.

### What You'll Learn

- ✅ SELECT queries and the difference between `fetch()` and `fetchAll()`
- ✅ Rendering database rows as dynamic HTML
- ✅ Using `$_GET` to create a dynamic detail page
- ✅ Validating URL parameters before using them in queries
- ✅ Handling the "record not found" case cleanly

### What You'll Need

- Laragon running with Apache and MySQL green
- The `db_catatku` database with data from Lesson 10
- Lessons 1 through 10 completed

---

## 2. Setup

Create a new subfolder called `lesson-11` inside `learn-php`.

---

## 3. The Entry Listing Page

### Step 1: Create the File

In `lesson-11`, create `list.php`.

### Step 2: Write the Code

Open `list.php` and type the following code:

```php
<?php
require_once __DIR__ . '/../config.php';

// Fetch all entries, newest first
// This query has no user data, so query() is safe (no need for prepare)
$stmt    = $pdo->query("SELECT * FROM entries ORDER BY created_at DESC");
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Entries — Catatku</title>
</head>
<body>

    <h1>Catatku — Entry List</h1>

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

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-11/list.php
```

Walk through the code from top to bottom to understand how every piece works. The `require_once` pulls in the PDO connection from `config.php`, making `$pdo` available for the query that follows. `$pdo->query("SELECT * FROM entries ORDER BY created_at DESC")` sends the SQL to MySQL. The `ORDER BY created_at DESC` clause sorts results with the newest entry first — omitting this clause would return rows in the order MySQL chooses, which is usually insertion order but is technically undefined. The `$stmt->fetchAll()` call retrieves every matching row as an array of associative arrays, where each inner array represents one row with column names as keys (because of the `PDO::FETCH_ASSOC` option in `config.php`).

The `<?php if (empty($entries)):` check handles the case where the table is empty, displaying a friendly message instead of an empty table. Without this check, a user with no entries would see a table with headers and no rows, which looks broken. The `foreach ($entries as $entry):` loop (using the alternative Blade-like colon syntax rather than curly braces, which many developers prefer when mixing PHP and HTML) iterates over every row. Inside, `htmlspecialchars($entry['title'])` applies XSS protection to database-sourced content — even though this data came from your own database, it was originally entered by users through forms, and a user could have stored dangerous HTML. The link `detail.php?id=<?= $entry['id'] ?>` passes each entry's unique identifier to the detail page through a URL parameter.

---

## 4. The Detail Page

### Step 1: Create the File

In `lesson-11`, create `detail.php`.

### Step 2: Write the Code

Open `detail.php` and type the following code:

```php
<?php
require_once __DIR__ . '/../config.php';

// Get the id from the URL and immediately cast it to integer
// (int) converts any string to a whole number — "abc" becomes 0, "5" becomes 5
$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

// Basic validation: the ID must be a positive integer
if ($id <= 0) {
    echo "<h1>Error</h1><p>Invalid entry ID.</p>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}

// Fetch one entry using a prepared statement
// JOIN retrieves the author's name alongside the entry data in one query
$stmt = $pdo->prepare("
    SELECT entries.*, users.name AS author_name
    FROM entries
    INNER JOIN users ON entries.user_id = users.id
    WHERE entries.id = :id
");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();   // fetch() returns ONE row, or false if not found

// Handle the case where no entry with this ID exists
if (!$entry) {
    echo "<h1>Entry Not Found</h1>";
    echo "<p>Entry with ID $id does not exist.</p>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?= htmlspecialchars($entry['title']) ?> — Catatku</title>
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

### Step 3: Save and Run

From the listing page, click any **Read** link. Also try visiting an invalid ID directly:

```
http://localhost/learn-php/lesson-11/detail.php?id=999
```

You should see the "Entry Not Found" message.

Let us trace through every significant line. The `(int) $_GET['id']` cast serves two purposes: it converts the string from the URL to an integer (which is the type the database expects), and it neutralizes any non-numeric content — if someone types `?id=hack`, the cast produces 0, which the `$id <= 0` check then catches. This is a lightweight defense against URL manipulation.

The SQL query uses `INNER JOIN users ON entries.user_id = users.id` to combine data from two tables in a single query. `INNER JOIN` says "find matching rows in both tables and combine them." The `ON entries.user_id = users.id` clause is the join condition: for each entry row, find the user row whose `id` matches the entry's `user_id`. The `users.name AS author_name` aliases the column to avoid a naming conflict with any `name` column in entries. The result is a single row containing all entry columns plus the author's name.

`$stmt->fetch()` (without `All`) retrieves exactly one row. It returns either an associative array if a matching row was found, or `false` if no row matched. The `if (!$entry)` check handles the `false` case by displaying an error and stopping execution with `exit`. Without this check, the code below would try to access `$entry['title']` on a boolean `false`, which produces errors. The `style="white-space: pre-line;"` CSS property on the content container preserves the line breaks that users typed in their journal entries — without it, all paragraph breaks collapse into a single block of text.

---

## 5. Fix the Errors in Your Code

```php
<?php
require_once __DIR__ . '/../config.php';

// Mistake 1: SQL injection — user data in query without prepared statement
$id = $_GET['id'];
$stmt = $pdo->query("SELECT * FROM entries WHERE id = $id");
$entry = $stmt->fetch();

// Mistake 2: Using data without checking if it was found
echo "<h1>" . $entry['title'] . "</h1>";

// Mistake 3: Outputting without htmlspecialchars
echo "<p>" . $entry['content'] . "</p>";
?>
```

The first mistake is SQL injection: `$_GET['id']` goes directly into the query string. Use `$stmt = $pdo->prepare("... WHERE id = :id"); $stmt->execute(['id' => (int)$_GET['id']]);`. The second mistake attempts to access `$entry['title']` without first checking whether `$entry` is `false` (meaning the ID was not found). Add `if (!$entry) { echo "Not found"; exit; }` before accessing any column. The third mistake outputs content without `htmlspecialchars()`, leaving an XSS vulnerability even though the data came from the database. Always escape output regardless of where the data originated.

---

## 6. Exercises

**Exercise 1:** Create `exercise-1.php`. Display all users from the `users` table in an HTML table showing No, Name, Email, and Registered Date. **Exercise 2:** Create `exercise-2.php`. Accept a `user_id` URL parameter, fetch that user and all their entries using two queries (or a JOIN), display the user's name at the top and entries in a list below. **Exercise 3:** Create `exercise-3.php`. Display three statistics: total users, total entries, and the title and date of the most recent entry. Use three separate queries.

---

## 7. Understanding Reading Data

The `fetchAll()` versus `fetch()` distinction maps directly to the query's purpose. When you expect multiple rows (listings, search results), use `fetchAll()` to get them all at once as an array you can `foreach` over. When you expect exactly one row (detail view, profile page, lookup by unique ID), use `fetch()` and check whether it returned `false`. Using `fetchAll()` for a single record works but is wasteful; using `fetch()` for a list would only give you the first row.

The N+1 query problem is worth understanding even at this early stage. If you listed 50 entries and then fetched the author's name separately for each one, you would run 51 queries (1 for the list plus 50 for the names). The `INNER JOIN` in the detail page combines both into one query. For the listing page where you might want author names too, the same JOIN technique applies. As your applications grow, this habit of combining related data into one query rather than making separate queries in a loop becomes critically important for performance.

`htmlspecialchars()` on output is not redundant just because you already validated input. Data validation ensures what goes into the database meets your rules. Output escaping ensures that whatever is already in the database cannot cause harm when rendered as HTML. These are separate concerns that protect against separate vulnerabilities.

---

## 8. Conclusion

`fetchAll()` retrieves all matching rows for listings; `fetch()` retrieves one row for detail views. Always check that `fetch()` did not return `false` before accessing the row's data. Use `htmlspecialchars()` on all database-sourced output. Use `$_GET` with explicit type casting and range validation for URL parameters. Use `INNER JOIN` to combine data from related tables in a single query.

**In Lesson 12**, you will complete the CRUD cycle with forms that create new entries, edit existing ones, and delete records from the database.