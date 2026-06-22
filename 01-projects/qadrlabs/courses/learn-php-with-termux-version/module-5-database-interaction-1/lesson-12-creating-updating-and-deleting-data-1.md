## 1. Before You Begin

In Lesson 11, you built pages that read data from the database and display it in the browser. But users still cannot add, edit, or delete entries from within the application - all data was inserted through the `seed-data.php` script. This lesson changes that by completing the full **CRUD** cycle.

CRUD stands for Create, Read, Update, Delete. Read was completed in Lesson 11. This lesson builds the remaining three: a form to write new entries (Create), a form to edit existing entries (Update), and a button to delete entries (Delete). When you finish this lesson, users can manage all their journal data entirely through the browser.

### What You'll Build

You will build a form to write new entries with validation, an edit page with pre-filled data, and a delete action protected by a confirmation step. You will also learn the Post/Redirect/Get pattern, which prevents duplicate submissions when users refresh after saving.

### What You'll Learn

- ✅ How to save data from a form to the database with INSERT
- ✅ How to update existing data with UPDATE
- ✅ How to delete data with DELETE
- ✅ The Post/Redirect/Get pattern to prevent double submission
- ✅ How to display success messages after an action

### What You'll Need

- Termux open with Apache and MariaDB running
- The `db_catatku` database with data from Lesson 10
- Lessons 1 through 11 completed

---

## 2. Setup

Create a dedicated folder for this lesson inside your project directory.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-12
cd lesson-12
```

This lesson's files communicate with each other through links and redirects, so all pages - `list.php`, `create.php`, `edit.php`, `delete.php`, and `detail.php` - belong in the same `lesson-12` folder.

---

## 3. Saving a New Entry (Create)

The Create page contains a form that sends data via POST. When PHP receives the POST, it validates the input, saves it to the database, and then redirects to the listing page. If validation fails, the form re-renders with error messages and the values the user typed preserved in the fields.

### Step 1: Create the File

Make sure you are in the `lesson-12` folder, then open a new file:

```bash
micro create.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$errors      = [];
$old_title   = '';
$old_content = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_title   = trim($_POST['title']   ?? '');
    $old_content = trim($_POST['content'] ?? '');

    if (empty($old_title)) {
        $errors['title'] = 'Title is required.';
    } elseif (strlen($old_title) > 255) {
        $errors['title'] = 'Title must be 255 characters or less.';
    }

    if (empty($old_content)) {
        $errors['content'] = 'Content is required.';
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)");
        $stmt->execute([
            'user_id' => 1,
            'title'   => $old_title,
            'content' => $old_content,
        ]);

        header('Location: list.php?message=created');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Write New Entry - Catatku</title>
</head>
<body>

    <p><a href="list.php">&larr; Back to list</a></p>

    <h1>Write New Entry</h1>

    <form method="POST" action="">
        <div style="margin-bottom: 15px;">
            <label for="title"><strong>Title:</strong></label><br>
            <input type="text" id="title" name="title"
                   value="<?= htmlspecialchars($old_title) ?>"
                   style="width: 100%; padding: 8px; max-width: 500px;">
            <?php if (isset($errors['title'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['title']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 15px;">
            <label for="content"><strong>Content:</strong></label><br>
            <textarea id="content" name="content" rows="10"
                      style="width: 100%; padding: 8px; max-width: 500px;"
            ><?= htmlspecialchars($old_content) ?></textarea>
            <?php if (isset($errors['content'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['content']) ?></span>
            <?php endif; ?>
        </div>

        <button type="submit" style="padding: 8px 20px;">Save Entry</button>
    </form>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: Create the List Page

This lesson needs its own `list.php` with Edit and Delete links added to each row. Create it in the `lesson-12` folder:

```bash
micro list.php
```

Type the following code:

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

    <?php if (isset($_GET['message'])): ?>
        <p style="color: green; border: 1px solid green; padding: 10px; max-width: 500px;">
            <?php
            $messages = [
                'created' => 'Entry saved successfully!',
                'updated' => 'Entry updated successfully!',
                'deleted' => 'Entry deleted successfully!',
            ];
            echo $messages[$_GET['message']] ?? 'Operation successful!';
            ?>
        </p>
    <?php endif; ?>

    <p><a href="create.php">+ Write New Entry</a></p>

    <?php if (empty($entries)): ?>
        <p>No entries yet.</p>
    <?php else: ?>
        <table border="1" cellpadding="10" cellspacing="0">
            <tr>
                <th>No</th>
                <th>Title</th>
                <th>Date</th>
                <th>Actions</th>
            </tr>
            <?php $no = 1; ?>
            <?php foreach ($entries as $entry): ?>
                <tr>
                    <td><?= $no++ ?></td>
                    <td><?= htmlspecialchars($entry['title']) ?></td>
                    <td><?= htmlspecialchars($entry['created_at']) ?></td>
                    <td>
                        <a href="detail.php?id=<?= $entry['id'] ?>">Read</a> |
                        <a href="edit.php?id=<?= $entry['id'] ?>">Edit</a> |
                        <a href="delete.php?id=<?= $entry['id'] ?>"
                           onclick="return confirm('Are you sure you want to delete this entry?')">Delete</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 4: View in the Browser

Open the list page and click "Write New Entry":

```
http://localhost:8080/learn-php/lesson-12/list.php
```

Fill in the form and click "Save Entry". The new entry appears in the list with a green success banner.

`$old_title` and `$old_content` start empty. On a POST request, they are immediately overwritten with the submitted values. If validation fails, the form renders with these variables already containing what the user typed. This is the sticky form pattern: the user's input is not lost on a failed submission. When validation passes, the code runs the INSERT with a prepared statement and then calls `header('Location: list.php?message=created')` followed immediately by `exit`. This is the Post/Redirect/Get pattern: instead of rendering HTML after saving, the script redirects the browser to a new GET request. If the user presses refresh after that redirect, the browser re-runs the GET, not the POST, so the entry is not inserted a second time. The `?message=created` query parameter tells `list.php` which success banner to display. The `$messages` array maps each keyword to a human-readable sentence, and the `??` operator provides a fallback if an unexpected keyword appears. `user_id` is hardcoded to `1` for now because session-based authentication is introduced in Lesson 13.

---

## 4. Editing an Entry (Update)

The Edit page works in two phases. On the first load (GET request), it fetches the entry from the database and pre-fills the form with the existing values. On submission (POST request), it validates the new values, saves them with an UPDATE query, and redirects.

### Step 1: Create the File

Make sure you are in the `lesson-12` folder, then open a new file:

```bash
micro edit.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<h1>Entry not found</h1>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}

$errors      = [];
$old_title   = $entry['title'];
$old_content = $entry['content'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_title   = trim($_POST['title']   ?? '');
    $old_content = trim($_POST['content'] ?? '');

    if (empty($old_title)) {
        $errors['title'] = 'Title is required.';
    } elseif (strlen($old_title) > 255) {
        $errors['title'] = 'Title must be 255 characters or less.';
    }

    if (empty($old_content)) {
        $errors['content'] = 'Content is required.';
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare("UPDATE entries SET title = :title, content = :content, updated_at = NOW() WHERE id = :id");
        $stmt->execute([
            'id'      => $id,
            'title'   => $old_title,
            'content' => $old_content,
        ]);

        header('Location: list.php?message=updated');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Edit Entry - Catatku</title>
</head>
<body>

    <p><a href="list.php">&larr; Back to list</a></p>

    <h1>Edit Entry</h1>

    <form method="POST" action="">
        <div style="margin-bottom: 15px;">
            <label for="title"><strong>Title:</strong></label><br>
            <input type="text" id="title" name="title"
                   value="<?= htmlspecialchars($old_title) ?>"
                   style="width: 100%; padding: 8px; max-width: 500px;">
            <?php if (isset($errors['title'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['title']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 15px;">
            <label for="content"><strong>Content:</strong></label><br>
            <textarea id="content" name="content" rows="10"
                      style="width: 100%; padding: 8px; max-width: 500px;"
            ><?= htmlspecialchars($old_content) ?></textarea>
            <?php if (isset($errors['content'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['content']) ?></span>
            <?php endif; ?>
        </div>

        <button type="submit" style="padding: 8px 20px;">Save Changes</button>
    </form>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

From the list page, click "Edit" on any entry, or navigate directly:

```
http://localhost:8080/learn-php/lesson-12/edit.php?id=1
```

The form renders pre-filled with the entry's current data. After saving, you are redirected to the list with the "Entry updated successfully!" message.

The entry is fetched from the database at the very start, regardless of whether the request is GET or POST. This serves two purposes: it pre-fills the form on the first load, and it acts as a security check - if the ID does not exist in the database, the script stops immediately. `$old_title = $entry['title']` sets the initial form value from the database. On a POST request, these variables are immediately overwritten with the user's submitted values. If validation fails, the form re-renders using the submitted values, not the database values, so corrections are not lost. `UPDATE entries SET title = :title, content = :content, updated_at = NOW() WHERE id = :id` modifies exactly one row. `NOW()` is a MySQL function that returns the current date and time, which is stored in the `updated_at` column to record when the entry was last changed. The `WHERE id = :id` clause is critical: without it, every row in the table would be updated to the same title and content.

---

## 5. Deleting an Entry (Delete)

The Delete page receives an ID from the URL, verifies the entry exists, performs the DELETE query, and redirects. Verifying before deleting is important: it prevents a confusing silent failure if someone bookmarks and later revisits a delete URL for a row that has already been removed.

### Step 1: Create the File

Make sure you are in the `lesson-12` folder, then open a new file:

```bash
micro delete.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) {
    echo "<p>Invalid ID.</p>";
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<h1>Entry not found</h1>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}

$stmt = $pdo->prepare("DELETE FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);

header('Location: list.php?message=deleted');
exit;
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

From the list page, click "Delete" on any entry. The browser shows a JavaScript confirmation dialog - if you click "OK", the entry is deleted and you are redirected to the list with the "Entry deleted successfully!" message.

```
http://localhost:8080/learn-php/lesson-12/list.php
```

`DELETE FROM entries WHERE id = :id` removes exactly one row, identified by the ID sent via the prepared statement placeholder `:id`. Fetching the entry before deleting serves as existence verification: if `fetch()` returns `false`, the entry does not exist and the script stops with a clear message rather than running a DELETE that silently affects zero rows. The JavaScript `onclick="return confirm(...)"` in `list.php` shows a browser dialog before the link is followed. If the user clicks "Cancel", `confirm()` returns `false` and the browser does not navigate to the delete URL. This is a convenience for the user, not a security measure. A determined attacker could bypass it entirely by crafting a direct URL request. Real security requires the server-side existence check, which this script performs.

---

## 6. Create the Detail Page

To complete the navigation, create a `detail.php` file in the `lesson-12` folder that shows a single entry with Edit and Delete links.

### Step 1: Create the File

Make sure you are in the `lesson-12` folder, then open a new file:

```bash
micro detail.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

$stmt = $pdo->prepare("
    SELECT entries.*, users.name AS author_name
    FROM entries
    INNER JOIN users ON entries.user_id = users.id
    WHERE entries.id = :id
");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<h1>Entry not found</h1>";
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
        <?php if ($entry['updated_at']): ?>
            | Updated: <?= htmlspecialchars($entry['updated_at']) ?>
        <?php endif; ?>
    </small></p>

    <hr>

    <div style="white-space: pre-line;"><?= htmlspecialchars($entry['content']) ?></div>

    <hr>

    <p>
        <a href="edit.php?id=<?= $entry['id'] ?>">Edit</a> |
        <a href="delete.php?id=<?= $entry['id'] ?>"
           onclick="return confirm('Are you sure you want to delete?')">Delete</a> |
        <a href="list.php">Back to list</a>
    </p>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

This page is nearly identical to the one from Lesson 11, with the addition of Edit and Delete action links at the bottom. The `INNER JOIN` fetches the author's name alongside the entry data in one query. The `updated_at` field is displayed only when it has a non-null value, which indicates the entry has been edited since it was first created.

---

## 7. Fix the Errors in Your Code

This section covers three mistakes that are common in CRUD implementations. One silently corrupts an entire database table. One allows duplicate form submissions. One skips a critical existence check before a destructive operation.

**Error 1: Running an UPDATE query without a WHERE clause.**

An `UPDATE` without `WHERE` modifies every row in the table. If the table has 500 entries, all 500 will have their title changed.

```php
// Wrong
$stmt = $pdo->prepare("UPDATE entries SET title = :title");
$stmt->execute(['title' => 'New Title']);

// Correct
$stmt = $pdo->prepare("UPDATE entries SET title = :title WHERE id = :id");
$stmt->execute(['title' => 'New Title', 'id' => $id]);
```

`WHERE id = :id` limits the UPDATE to exactly one row: the entry with the matching ID. This is always required unless you intentionally want to update every row (which is a rare and specific use case). The same rule applies to DELETE queries.

---

**Error 2: Rendering output directly after a successful POST instead of redirecting.**

If the code echoes a success message right after saving, the browser retains the POST state. When the user presses F5 to refresh, the browser resends the POST request and inserts a duplicate entry.

```php
// Wrong
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (1, :title, :content)");
    $stmt->execute(['title' => $_POST['title'], 'content' => $_POST['content']]);
    echo "Saved successfully!";
}

// Correct
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (1, :title, :content)");
    $stmt->execute(['title' => $_POST['title'], 'content' => $_POST['content']]);
    header('Location: list.php?message=created');
    exit;
}
```

After a successful INSERT, `header('Location: ...')` sends the browser to a new URL with a GET request. Refreshing that page only repeats the GET, which simply reloads the listing without inserting anything again. Always follow `header()` with `exit` immediately, otherwise PHP continues executing the code below and may produce output that conflicts with the redirect header.

---

**Error 3: Deleting a record without checking that it exists first.**

If someone visits a delete URL with an ID that was already deleted, the DELETE query executes silently against zero rows. There is no error, but the user sees no confirmation either, and the script may fail further down if it tries to access data about the deleted row.

```php
// Wrong
$stmt = $pdo->prepare("DELETE FROM entries WHERE id = :id");
$stmt->execute(['id' => $_GET['id']]);
header('Location: list.php?message=deleted');
exit;

// Correct
$id   = (int) ($_GET['id'] ?? 0);
$stmt = $pdo->prepare("SELECT id FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
if (!$stmt->fetch()) {
    echo "<p>Entry not found.</p>";
    exit;
}
$stmt = $pdo->prepare("DELETE FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
header('Location: list.php?message=deleted');
exit;
```

Fetching before deleting also validates that the requesting user has the right to delete that particular record - a check that becomes important once sessions are introduced in Lesson 13.

---

## 8. Exercises

Complete the following exercises in the `lesson-12` folder. Each file must begin with `require_once __DIR__ . '/../config.php';`.

**Exercise 1:** Add a minimum length requirement to `create.php`: the content field must be at least 10 characters. Add the validation rule after the existing `empty($old_content)` check and display the error message "Content must be at least 10 characters."

**Exercise 2:** Create `create-user.php`. Build a registration form with three fields: name, email, and password. Validate all fields. Before inserting, check using a SELECT query whether the email already exists in the `users` table. Hash the password with `password_hash()` before saving. Redirect to `list.php` after success.

**Exercise 3:** Create `delete-confirm.php`. Instead of deleting immediately via a GET request, this page shows a confirmation screen first. It receives the entry ID from the URL, fetches the entry, and displays its title along with a "Yes, Delete" button (a POST form) and a "Cancel" link back to the list. The actual DELETE only runs when the POST button is clicked.

---

## 9. Solutions

**Solution for Exercise 1:**

In the validation section of `create.php`, replace the content validation block with:

```php
if (empty($old_content)) {
    $errors['content'] = 'Content is required.';
} elseif (strlen($old_content) < 10) {
    $errors['content'] = 'Content must be at least 10 characters.';
}
```

`elseif` chains the minimum-length check directly onto the empty check. If `$old_content` is empty, the first branch fires and the second is never evaluated. If the content has some text but fewer than 10 characters, `strlen($old_content) < 10` is true and the length error is recorded. Only when both conditions are false does the content pass validation. No other changes to `create.php` are needed.

---

**Solution for Exercise 2:**

```php
<?php
require_once __DIR__ . '/../config.php';

$errors    = [];
$old_name  = '';
$old_email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_name  = trim($_POST['name']     ?? '');
    $old_email = trim($_POST['email']    ?? '');
    $password  = $_POST['password']      ?? '';

    if (empty($old_name))  { $errors['name']  = 'Name is required.'; }
    if (empty($old_email) || !filter_var($old_email, FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = 'A valid email is required.';
    }
    if (strlen($password) < 8) { $errors['password'] = 'Password must be at least 8 characters.'; }

    if (empty($errors['email'])) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = :email");
        $stmt->execute(['email' => $old_email]);
        if ($stmt->fetch()) {
            $errors['email'] = 'This email is already registered.';
        }
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:name, :email, :password)");
        $stmt->execute([
            'name'     => $old_name,
            'email'    => $old_email,
            'password' => password_hash($password, PASSWORD_DEFAULT),
        ]);
        header('Location: list.php?message=created');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Register User</title></head>
<body>
    <h1>Register New User</h1>
    <form method="POST" style="max-width: 400px;">
        <p>
            <label><strong>Name:</strong></label><br>
            <input type="text" name="name" value="<?= htmlspecialchars($old_name) ?>" style="width:100%;padding:8px;">
            <?php if (isset($errors['name'])): ?><br><span style="color:red;"><?= $errors['name'] ?></span><?php endif; ?>
        </p>
        <p>
            <label><strong>Email:</strong></label><br>
            <input type="email" name="email" value="<?= htmlspecialchars($old_email) ?>" style="width:100%;padding:8px;">
            <?php if (isset($errors['email'])): ?><br><span style="color:red;"><?= $errors['email'] ?></span><?php endif; ?>
        </p>
        <p>
            <label><strong>Password:</strong></label><br>
            <input type="password" name="password" style="width:100%;padding:8px;">
            <?php if (isset($errors['password'])): ?><br><span style="color:red;"><?= $errors['password'] ?></span><?php endif; ?>
        </p>
        <button type="submit" style="padding:8px 20px;">Register</button>
    </form>
</body>
</html>
```

The email uniqueness check runs only when no email format error has already been recorded, avoiding an unnecessary database query when the email is clearly invalid. `SELECT id FROM users WHERE email = :email` fetches only the `id` column rather than the whole row, which is faster. If `fetch()` returns a row, the email is already taken and the error is added. `password_hash()` runs only inside the success block, not during validation, so the CPU-intensive hashing only happens when all fields are valid and the insert is about to proceed.

---

**Solution for Exercise 3:**

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<p>Entry not found.</p>";
    echo '<p><a href="list.php">Back to list</a></p>';
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $stmt = $pdo->prepare("DELETE FROM entries WHERE id = :id");
    $stmt->execute(['id' => $id]);
    header('Location: list.php?message=deleted');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Confirm Delete</title></head>
<body>
    <h1>Confirm Delete</h1>
    <p>Are you sure you want to delete this entry?</p>
    <p><strong><?= htmlspecialchars($entry['title']) ?></strong></p>
    <form method="POST">
        <button type="submit" style="color: red; padding: 8px 20px;">Yes, Delete</button>
        <a href="list.php" style="margin-left: 10px;">Cancel</a>
    </form>
</body>
</html>
```

The page serves two HTTP methods from a single file. A GET request (following the link from the list) shows the confirmation screen. A POST request (clicking "Yes, Delete") performs the deletion. This is called a server-side confirmation flow and is more reliable than the JavaScript `confirm()` approach because it works even when JavaScript is disabled. The entry existence check runs before either flow so that both the confirmation screen and the deletion operation are guaranteed to operate on a row that actually exists in the database.

---

## Next Up - Lesson 13

With this lesson, the CRUD cycle is complete. Create sends data from a form to the database with INSERT. Read fetches and displays data as HTML (from Lesson 11). Update pre-fills a form with existing data and saves changes with UPDATE. Delete removes a row after verifying it exists. The Post/Redirect/Get pattern prevents duplicate submissions by always redirecting after a successful POST. Always validate before saving, always use prepared statements, and always check data existence before modifying or deleting.

In Lesson 13, you will learn sessions and authentication: building a registration, login, and logout system so each user can see and manage only their own journal entries.