## 1. Before You Begin

In Lesson 11 you built the Read part of CRUD: fetching entries from the database and displaying them. The remaining three operations — Create, Update, Delete — all involve writing back to the database through forms. This lesson completes the cycle and adds one essential pattern: Post/Redirect/Get, which prevents the frustrating problem of data being submitted twice when a user refreshes the page.

### Introduction

Every dynamic web application, from social media to e-commerce to content management systems, is built on CRUD. You have already built the Read part. Now you will wire forms to SQL INSERT, UPDATE, and DELETE statements, implement validation before any database operation runs, and apply the Post/Redirect/Get pattern that professional applications use to prevent double submissions. By the end of this lesson, Catatku will be a fully functional, database-driven journal that users can interact with completely.

### What You'll Build

You will build a `create.php` form for writing new entries, a `detail.php` page for reading one entry, an `edit.php` form that pre-fills with existing data, a `delete.php` handler that removes entries, and an updated `list.php` with navigation links to every CRUD operation.

### What You'll Learn

- ✅ Saving form data to the database with INSERT
- ✅ Keeping the read detail page available inside the completed CRUD folder
- ✅ Updating existing records with UPDATE
- ✅ Deleting records safely with DELETE
- ✅ The Post/Redirect/Get (PRG) pattern and why it exists
- ✅ Pre-filling edit forms with current database values
- ✅ Displaying operation success messages across a redirect

### What You'll Need

- Laragon running
- The `db_catatku` database with data from Lesson 10
- Lessons 1 through 11 completed

---

## 2. Setup

Create a new subfolder called `lesson-12` inside `learn-php`.

---

## 3. Creating a New Entry

### Step 1: Create the File

In `lesson-12`, create `create.php`.

### Step 2: Write the Code

Open `create.php` and type the following code:

```php
<?php
require_once __DIR__ . '/../config.php';

$errors      = [];
$old_title   = '';
$old_content = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_title   = trim($_POST['title'] ?? '');
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
        $stmt = $pdo->prepare(
            "INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)"
        );
        $stmt->execute([
            'user_id' => 1,           // Hardcoded until Lesson 13 adds sessions
            'title'   => $old_title,
            'content' => $old_content,
        ]);

        // PRG: redirect to list so browser refresh does not re-submit
        header('Location: list.php?message=created');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Write New Entry — Catatku</title></head>
<body>

    <p><a href="list.php">&larr; Back to list</a></p>
    <h1>Write New Entry</h1>

    <form method="POST" action="">
        <div style="margin-bottom: 15px;">
            <label><strong>Title:</strong></label><br>
            <input type="text" name="title"
                   value="<?= htmlspecialchars($old_title) ?>"
                   style="width: 100%; max-width: 500px; padding: 8px;">
            <?php if (isset($errors['title'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['title']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 15px;">
            <label><strong>Content:</strong></label><br>
            <textarea name="content" rows="10"
                      style="width: 100%; max-width: 500px; padding: 8px;"
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

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Create the Updated List Page

Create `list.php` in `lesson-12` with success message support:

```php
<?php
require_once __DIR__ . '/../config.php';

$stmt    = $pdo->query("SELECT * FROM entries ORDER BY created_at DESC");
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>My Entries — Catatku</title></head>
<body>

    <h1>Catatku — Entry List</h1>

    <?php if (isset($_GET['message'])): ?>
        <?php $messages = ['created' => 'Entry saved!', 'updated' => 'Entry updated!', 'deleted' => 'Entry deleted!']; ?>
        <p style="color: green; border: 1px solid green; padding: 10px; max-width: 500px;">
            <?= $messages[$_GET['message']] ?? 'Done!' ?>
        </p>
    <?php endif; ?>

    <p><a href="create.php">+ Write New Entry</a></p>

    <?php if (empty($entries)): ?>
        <p>No entries yet.</p>
    <?php else: ?>
        <table border="1" cellpadding="10" cellspacing="0">
            <tr><th>No</th><th>Title</th><th>Date</th><th>Actions</th></tr>
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
                           onclick="return confirm('Delete this entry?')">Delete</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

</body>
</html>
```

### Step 5: Create the Detail Page

The updated list page links to `detail.php`, so this lesson also needs a detail page inside the same `lesson-12` folder. Create `detail.php` in `lesson-12` and add:

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) {
    echo "<h1>Error</h1><p>Invalid entry ID.</p>";
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
    echo "<p>Entry with ID $id does not exist.</p>";
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

This page is the same read pattern from Lesson 11, placed in the Lesson 12 folder so the Read link works alongside create, edit, and delete. It still validates the ID, uses a prepared statement, joins the author name from `users`, handles missing records, and escapes database content before display.

### Step 6: Run in the Browser

```
http://localhost/learn-php/lesson-12/list.php
```

Click **+ Write New Entry**, fill in the form, and click Save Entry. You should be redirected back to the list with a green "Entry saved!" message. Click the **Read** link on any entry and confirm that `detail.php` opens the full entry instead of a missing page.

Now let us trace through the create logic step by step. At the top, `$old_title` and `$old_content` start as empty strings so the form renders blank on the first visit. The `$_SERVER['REQUEST_METHOD'] === 'POST'` check gates the entire processing block, so it only runs after a form submission. The `trim()` call removes accidental leading and trailing spaces from user input. Validation runs before any database operation: if `$old_title` is empty, `$errors['title']` gets the error message. The `strlen() > 255` check ensures the title will not exceed the VARCHAR(255) column size in the database, which would cause a truncation error. Only when `empty($errors)` is true does the INSERT happen. The `header('Location: list.php?message=created')` redirect is followed immediately by `exit` — without `exit`, PHP would continue executing code below the redirect header, which could cause unexpected behavior.

The `?message=created` in the redirect URL is how you pass success information across the PRG redirect. The list page reads `$_GET['message']` and displays the appropriate text. Using a whitelist array (`$messages`) ensures that only known message keys produce output, preventing a user from crafting a malicious URL that displays arbitrary text on the list page.

---

## 4. Editing an Entry

### Step 1: Create the File

Create `edit.php` in `lesson-12`.

### Step 2: Write the Code

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

$stmt = $pdo->prepare("SELECT * FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
$entry = $stmt->fetch();

if (!$entry) {
    echo "<h1>Entry not found</h1><p><a href='list.php'>Back</a></p>";
    exit;
}

$errors      = [];
$old_title   = $entry['title'];      // Pre-fill with database values on GET
$old_content = $entry['content'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_title   = trim($_POST['title'] ?? '');
    $old_content = trim($_POST['content'] ?? '');

    if (empty($old_title)) $errors['title'] = 'Title is required.';
    if (empty($old_content)) $errors['content'] = 'Content is required.';

    if (empty($errors)) {
        $stmt = $pdo->prepare(
            "UPDATE entries SET title = :title, content = :content, updated_at = NOW() WHERE id = :id"
        );
        $stmt->execute(['id' => $id, 'title' => $old_title, 'content' => $old_content]);

        header('Location: list.php?message=updated');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Edit Entry — Catatku</title></head>
<body>

    <p><a href="list.php">&larr; Back to list</a></p>
    <h1>Edit Entry</h1>

    <form method="POST" action="">
        <div style="margin-bottom: 15px;">
            <label><strong>Title:</strong></label><br>
            <input type="text" name="title"
                   value="<?= htmlspecialchars($old_title) ?>"
                   style="width: 100%; max-width: 500px; padding: 8px;">
            <?php if (isset($errors['title'])): ?>
                <br><span style="color: red;"><?= $errors['title'] ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 15px;">
            <label><strong>Content:</strong></label><br>
            <textarea name="content" rows="10"
                      style="width: 100%; max-width: 500px; padding: 8px;"
            ><?= htmlspecialchars($old_content) ?></textarea>
            <?php if (isset($errors['content'])): ?>
                <br><span style="color: red;"><?= $errors['content'] ?></span>
            <?php endif; ?>
        </div>

        <button type="submit" style="padding: 8px 20px;">Save Changes</button>
    </form>

</body>
</html>
```

### Step 3: Save and Test

Visit `http://localhost/learn-php/lesson-12/edit.php?id=1`. The form pre-fills with the entry's current title and content from the database. Edit something and save — you should be redirected to the list with "Entry updated!".

The pre-filling behavior is controlled by how `$old_title` and `$old_content` are initialized. On the first visit (GET request), they are set directly from `$entry['title']` and `$entry['content']` so the form shows current values. On a POST request with validation errors, the variables are overwritten with the user's latest submitted values so their edits are not lost. This dual-use initialization pattern is a common PHP idiom for edit forms.

The UPDATE query uses `SET title = :title, content = :content, updated_at = NOW()`. The `NOW()` function inserts the current database timestamp into the `updated_at` column automatically. The `WHERE id = :id` clause is critically important — omitting it would update every row in the table instead of just the intended one. This category of bug (running an UPDATE or DELETE without a WHERE clause) is one of the most dangerous in database programming.

---

## 5. Deleting an Entry

### Step 1: Create the File

Create `delete.php` in `lesson-12`.

### Step 2: Write the Code

```php
<?php
require_once __DIR__ . '/../config.php';

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) {
    echo "<p>Invalid ID.</p>"; exit;
}

// Verify the entry exists before attempting to delete it
$stmt = $pdo->prepare("SELECT id FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);
if (!$stmt->fetch()) {
    echo "<h1>Entry not found</h1><p><a href='list.php'>Back</a></p>"; exit;
}

// Delete the entry
$stmt = $pdo->prepare("DELETE FROM entries WHERE id = :id");
$stmt->execute(['id' => $id]);

header('Location: list.php?message=deleted');
exit;
?>
```

### Step 3: Save and Test

From the list page, click Delete on any entry. The JavaScript `confirm()` in `list.php` asks for confirmation first. Click OK and the entry is gone.

The `delete.php` file is deliberately simple because deletion is a one-step action with no form to validate. The pattern is: validate the ID, check the entry exists, delete it, redirect. Note that the existence check runs a SELECT before the DELETE. This may seem redundant since DELETE on a non-existent ID simply deletes zero rows, but the check lets you give a meaningful error message rather than silently redirecting after a no-op. It also helps detect race conditions where two users might try to delete the same entry simultaneously.

A production application would protect delete operations with authorization checks so only the entry's owner can delete it — that requires sessions, which Lesson 13 introduces.

---

## 6. Run and Test

With all four files in place, you have a working CRUD application. Take a few minutes to exercise every operation systematically. Start by creating a new entry — fill in both fields, click save, and verify it appears at the top of the list. Then edit it by changing the title, save it, and verify the list shows the updated title. Try submitting the create form with an empty title and confirm the red error message appears while your content is preserved. Finally delete the entry you created and confirm it disappears.

Also test the Post/Redirect/Get pattern specifically: create an entry, watch the redirect happen, then immediately press F5 to refresh the page. Notice that the browser does NOT ask "resend form data?" and no duplicate entry appears. This is the PRG pattern working correctly. Compare this to what would happen if `create.php` rendered HTML directly after a successful insert instead of redirecting.

---

## 7. Fix the Errors in Your Code

```php
<?php
require_once __DIR__ . '/../config.php';

// Mistake 1: Missing WHERE clause in UPDATE
$stmt = $pdo->prepare("UPDATE entries SET title = :title");
$stmt->execute(['title' => 'New Title']);  // Updates EVERY entry!

// Mistake 2: Using GET for a delete operation
echo '<a href="delete.php?id=5">Delete</a>';  // Bots and prefetchers can delete entries!

// Mistake 3: No redirect after successful insert
if (empty($errors)) {
    $stmt->execute([...]);
    echo "<p>Entry saved!</p>";  // No redirect — F5 will re-submit the form
}
?>
```

The first mistake is catastrophic: `UPDATE entries SET title = 'New Title'` without a `WHERE` clause changes the title of every single entry in the table. Always include `WHERE id = :id` and bind the specific row ID. The second mistake exposes a delete operation through a simple anchor link, which uses the GET method. Search engine crawlers, browser prefetching, and link checkers can follow these links without user intent, accidentally deleting entries. Delete operations should use POST (with a form) so they are not triggered by passive link following. The third mistake renders HTML directly after a successful insert rather than redirecting. If the user presses F5 to refresh the page, the browser resends the POST request, inserting a duplicate entry. Always use `header('Location: ...')` followed by `exit` after successful write operations.

---

## 8. Exercises

**Exercise 1:** Add a "Copy Entry" feature. Create `copy.php` that accepts an entry ID via GET, reads that entry from the database, then inserts a new entry with the same content and a title prefixed by "Copy: ". Redirect to the list with a success message.

**Exercise 2:** Add word count information to the edit form. Below the content textarea, display "Word count: X" where X is the word count of the current content. This can be done purely in PHP using `str_word_count()`.

**Exercise 3:** Add a simple character counter to the title field. After saving an entry, display how many characters the title uses out of the 255 maximum. Hint: use `strlen($entry['title'])` and display it next to the entry on the list.

---

## 9. Understanding CRUD and PRG

The CRUD operations map directly to SQL statements and HTTP verbs. Create uses INSERT and ideally POST. Read uses SELECT and GET. Update uses UPDATE and ideally POST. Delete uses DELETE and ideally POST. The GET/POST alignment is not just convention — it has semantic meaning: GET requests should be safe (no side effects) and idempotent (repeatable without harm), while POST requests are explicitly non-safe operations that change data.

The Post/Redirect/Get pattern solves a specific HTTP mechanism: when a browser receives a successful response to a POST request, pressing F5 offers to resend the POST. For read-only pages, this is harmless. For write operations, it means duplicate inserts. By redirecting to a GET page after every successful POST, you ensure the URL in the browser always points to a safe, re-requestable page. This is why the message is carried in the URL query string rather than being rendered directly on the create or edit page — the redirect loses access to POST data, but GET parameters survive.

Validation before database writes is not just about showing the user helpful errors. It is also the last line of defense before data enters your database. The database has its own constraints (NOT NULL, VARCHAR length, UNIQUE), but those produce unhelpful error messages if they fire. Your PHP validation should catch problems first and present them in user-friendly language.

---

## 10. Conclusion

INSERT adds new rows, UPDATE modifies existing rows (always with WHERE), DELETE removes rows (always with WHERE). Validate before every write operation. Use Post/Redirect/Get: after successful writes, redirect with a success message in the URL rather than rendering HTML. Pre-fill edit forms by initializing variables from the database values before checking whether the form was submitted. The security concern of who is allowed to edit or delete belongs in the authentication layer, which Lesson 13 introduces.

**In Lesson 13**, you will learn sessions and simple authentication — how PHP remembers which user is logged in across multiple page requests, and how to build a login system that protects your CRUD pages.
