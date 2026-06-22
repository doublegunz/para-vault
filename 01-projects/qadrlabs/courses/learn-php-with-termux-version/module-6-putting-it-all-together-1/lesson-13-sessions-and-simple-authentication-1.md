## 1. Before You Begin

Up to this point, all entries use a hardcoded `user_id = 1`. Anyone who opens the page can see, edit, and delete all data. In a real application, every user needs their own account, and their data must be private.

The challenge is that HTTP is stateless: every request from the browser to the server stands alone with no memory of what came before. The server does not know whether this request comes from the same person as the previous one. **Sessions** solve this problem by storing user information on the server and identifying each visitor through a small token called a cookie that the browser sends back on every request.

In this lesson you will build a complete authentication system from scratch: registration, login, logout, and page protection.

### What You'll Build

You will build a user registration page, a login page, a logout mechanism, and a protected entry list that displays only the entries belonging to the logged-in user.

### What You'll Learn

- ✅ What sessions are and how they work
- ✅ How to use `session_start()`, `$_SESSION`, and `session_destroy()`
- ✅ How to build registration with `password_hash()`
- ✅ How to verify passwords with `password_verify()`
- ✅ How to protect pages so only logged-in users can access them
- ✅ How to display data that belongs only to the current user

### What You'll Need

- Termux open with Apache and MariaDB running
- The `db_catatku` database with `users` and `entries` tables
- Lessons 1 through 12 completed

---

## 2. Setup

Create a dedicated folder for this lesson inside your project directory.

```bash
cd ~/storage/shared/htdocs/learn-php
mkdir lesson-13
cd lesson-13
```

This lesson builds several pages that link to each other: `register.php`, `login.php`, `logout.php`, `list.php`, and `create.php`. All of them go in the `lesson-13` folder and all of them load `config.php` from the root using `require_once __DIR__ . '/../config.php'`.

---

## 3. Understanding Sessions

A session is a mechanism for storing data on the server that persists across multiple page requests from the same browser. Before writing any authentication pages, it helps to see how sessions work with a simple demonstration.

### Step 1: Create the File

Make sure you are in the `lesson-13` folder, then open a new file:

```bash
micro session-demo.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
session_start();

if (!isset($_SESSION['counter'])) {
    $_SESSION['counter'] = 0;
}

$_SESSION['counter']++;

echo "<h2>Session Demo</h2>";
echo "<p>You have visited this page <strong>{$_SESSION['counter']}</strong> times.</p>";
echo "<p>Try refreshing this page a few times — the number above will keep increasing.</p>";

echo "<h3>Current Session Data:</h3>";
echo "<pre>";
print_r($_SESSION);
echo "</pre>";
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL and refresh the page several times:

```
http://localhost:8080/learn-php/lesson-13/session-demo.php
```

The counter increases on every refresh, even though no form was submitted. This demonstrates that `$_SESSION` data persists between requests.

`session_start()` must be called before any output and before accessing `$_SESSION` on every page that uses sessions. The first time it is called, PHP generates a unique session ID (a long random string like `abc123def456`), stores it in a file on the server, and sends it to the browser as a cookie named `PHPSESSID`. Every subsequent request, the browser sends that cookie back automatically, and PHP uses the ID to locate the correct session file and restore `$_SESSION` to its last saved state. `$_SESSION` is a superglobal array. Writing to it (`$_SESSION['counter'] = 5`) saves the value into the server-side session file. Reading from it on the next request returns that stored value. Data in `$_SESSION` survives as long as the session is active: until the browser is closed, the session times out, or `session_destroy()` is called explicitly.

---

## 4. Building the Registration Page

The registration page collects a name, email, and password. It validates all three fields, checks that the email is not already taken, saves the new user with a hashed password, and logs the user in automatically by writing to `$_SESSION` before redirecting.

### Step 1: Create the File

Make sure you are in the `lesson-13` folder, then open a new file:

```bash
micro register.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

if (isset($_SESSION['user_id'])) {
    header('Location: list.php');
    exit;
}

$errors    = [];
$old_name  = '';
$old_email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_name  = trim($_POST['name']                  ?? '');
    $old_email = trim($_POST['email']                 ?? '');
    $password  = $_POST['password']                   ?? '';
    $password2 = $_POST['password_confirmation']      ?? '';

    if (empty($old_name)) {
        $errors['name'] = 'Name is required.';
    }
    if (empty($old_email) || !filter_var($old_email, FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = 'A valid email is required.';
    }
    if (strlen($password) < 8) {
        $errors['password'] = 'Password must be at least 8 characters.';
    }
    if ($password !== $password2) {
        $errors['password_confirmation'] = 'Password confirmation does not match.';
    }

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

        $user_id = $pdo->lastInsertId();

        $_SESSION['user_id']   = (int) $user_id;
        $_SESSION['user_name'] = $old_name;
        session_regenerate_id(true);

        header('Location: list.php');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Register - Catatku</title>
</head>
<body>

    <h1>Create a New Account</h1>

    <form method="POST" action="" style="max-width: 400px;">
        <div style="margin-bottom: 12px;">
            <label for="name"><strong>Name:</strong></label><br>
            <input type="text" id="name" name="name"
                   value="<?= htmlspecialchars($old_name) ?>"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['name'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['name']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label for="email"><strong>Email:</strong></label><br>
            <input type="email" id="email" name="email"
                   value="<?= htmlspecialchars($old_email) ?>"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['email'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['email']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label for="password"><strong>Password:</strong></label><br>
            <input type="password" id="password" name="password"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['password'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['password']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label for="password_confirmation"><strong>Confirm Password:</strong></label><br>
            <input type="password" id="password_confirmation" name="password_confirmation"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['password_confirmation'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['password_confirmation']) ?></span>
            <?php endif; ?>
        </div>

        <button type="submit" style="padding: 8px 20px;">Register</button>
    </form>

    <p>Already have an account? <a href="login.php">Log in here</a></p>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL and register a new account:

```
http://localhost:8080/learn-php/lesson-13/register.php
```

After successful registration you will be automatically redirected to `list.php`.

The `if (isset($_SESSION['user_id']))` check at the very top redirects already-logged-in users away from the registration page immediately. This prevents a logged-in user from creating duplicate accounts by navigating back to the form. The password confirmation field is compared with `$password !== $password2`. If the two strings are not identical, the error is recorded and the form re-renders. Note that password fields are never repopulated after a failed submission - this is intentional security behavior. Sending a password back through an HTML field would expose it in the page source. After the INSERT, `$pdo->lastInsertId()` retrieves the auto-generated `id` of the new user row. That ID and the user's name are written into `$_SESSION` immediately, effectively logging the user in without requiring them to visit the login page. `session_regenerate_id(true)` creates a new session ID and deletes the old one. This prevents session fixation attacks, where an attacker could trick a user into logging in under a session ID the attacker already knows.

---

## 5. Building the Login Page

The login page takes an email and password, looks up the user in the database, and uses `password_verify()` to compare the submitted password against the stored hash. On success it writes to `$_SESSION` and redirects. On failure it shows a single vague error message.

### Step 1: Create the File

Make sure you are in the `lesson-13` folder, then open a new file:

```bash
micro login.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

if (isset($_SESSION['user_id'])) {
    header('Location: list.php');
    exit;
}

$error     = '';
$old_email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_email = trim($_POST['email']    ?? '');
    $password  = $_POST['password']      ?? '';

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email");
    $stmt->execute(['email' => $old_email]);
    $user = $stmt->fetch();

    if ($user && password_verify($password, $user['password'])) {
        $_SESSION['user_id']   = (int) $user['id'];
        $_SESSION['user_name'] = $user['name'];
        session_regenerate_id(true);

        header('Location: list.php');
        exit;
    } else {
        $error = 'The email or password you entered is incorrect.';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login - Catatku</title>
</head>
<body>

    <h1>Log in to Catatku</h1>

    <?php if ($error): ?>
        <p style="color: red; border: 1px solid red; padding: 10px; max-width: 400px;">
            <?= htmlspecialchars($error) ?>
        </p>
    <?php endif; ?>

    <form method="POST" action="" style="max-width: 400px;">
        <div style="margin-bottom: 12px;">
            <label for="email"><strong>Email:</strong></label><br>
            <input type="email" id="email" name="email"
                   value="<?= htmlspecialchars($old_email) ?>"
                   style="width: 100%; padding: 8px;">
        </div>

        <div style="margin-bottom: 12px;">
            <label for="password"><strong>Password:</strong></label><br>
            <input type="password" id="password" name="password"
                   style="width: 100%; padding: 8px;">
        </div>

        <button type="submit" style="padding: 8px 20px;">Log In</button>
    </form>

    <p>Don't have an account? <a href="register.php">Register here</a></p>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL and try logging in with `budi@example.com` and password `password123` (from the seed data in Lesson 10):

```
http://localhost:8080/learn-php/lesson-13/login.php
```

After a successful login you will be redirected to `list.php`.

`password_verify($password, $user['password'])` is the counterpart to `password_hash()`. It takes the plain-text password the user typed and the hash stored in the database, and returns `true` if they correspond. You can never reverse a bcrypt hash to recover the original password - `password_verify()` works by running the same hashing process on the input and comparing the result. The condition `$user && password_verify(...)` is evaluated in order: if `$user` is `false` (no row found for the email), the second operand is never evaluated. This means no extra database query runs for unknown emails, and the response time remains consistent whether the email exists or not. The error message `'The email or password you entered is incorrect.'` deliberately does not distinguish between "email not found" and "wrong password." Splitting these into two separate messages would allow an attacker to enumerate registered email addresses by observing which message appears.

---

## 6. Building the Logout

The logout page destroys the session on the server, clears all session data from PHP's memory, and redirects to the login page. It contains no HTML - it is a pure action script.

### Step 1: Create the File

Make sure you are in the `lesson-13` folder, then open a new file:

```bash
micro logout.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
session_start();
$_SESSION = [];
session_destroy();
header('Location: login.php');
exit;
?>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

Visiting this file in the browser immediately destroys the session and sends you back to the login page. `session_start()` must be called first even on a logout page, to initialize the session mechanism so that `session_destroy()` has a session to destroy. `$_SESSION = []` empties the session data array in memory. `session_destroy()` then deletes the session file on the server. Together these two steps ensure the session data is fully removed, not just hidden.

---

## 7. Protecting Pages and Displaying User Data

Every page that should only be accessible to logged-in users must include the same two-line guard at the top: check for `$_SESSION['user_id']` and redirect to the login page if it is absent. This guard, combined with a `WHERE user_id = :user_id` clause in the data query, ensures each user sees only their own entries.

### Step 1: Create the File

Make sure you are in the `lesson-13` folder, then open a new file:

```bash
micro list.php
```

### Step 2: Write the Code

Type the following code into the editor:

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM entries WHERE user_id = :user_id ORDER BY created_at DESC");
$stmt->execute(['user_id' => $_SESSION['user_id']]);
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Entries - Catatku</title>
</head>
<body>

    <p>
        Hello, <strong><?= htmlspecialchars($_SESSION['user_name']) ?></strong>!
        | <a href="logout.php">Logout</a>
    </p>

    <h1>My Entries</h1>

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
        <p>No entries yet. Start writing your first entry!</p>
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
                        <a href="edit.php?id=<?= $entry['id'] ?>">Edit</a> |
                        <a href="delete.php?id=<?= $entry['id'] ?>"
                           onclick="return confirm('Are you sure?')">Delete</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

</body>
</html>
```

Press **Ctrl+S** to save, then **Ctrl+Q** to quit.

### Step 3: View in the Browser

Open the following URL directly without logging in first:

```
http://localhost:8080/learn-php/lesson-13/list.php
```

You will be redirected automatically to `login.php`. After logging in, you will see only the entries that belong to the logged-in user.

`if (!isset($_SESSION['user_id']))` is the page protection guard. `$_SESSION['user_id']` is only set after a successful login. If it is absent - because the user has not logged in, or the session expired, or they cleared their cookies - `isset()` returns `false`, the condition is true, and the `header()` redirect fires immediately. The `exit` after `header()` is mandatory: without it, PHP continues executing the rest of the page even after sending the redirect header, which means the database query and the HTML would still run for an unauthenticated user. `$_SESSION['user_id']` is used directly as the parameter for `WHERE user_id = :user_id`. Because this value was set by PHP at login time from a trusted database row, it is not user-controlled and does not need sanitization. Even so, prepared statements are still used because they are the correct pattern for all parameterized queries regardless of the data source.

---

## 8. Fix the Errors in Your Code

This section covers three mistakes that are common when first implementing sessions and authentication. One disables the entire session system, one introduces a security vulnerability in password storage, and one gives attackers information they should not have.

**Error 1: Forgetting `session_start()` on a page that uses `$_SESSION`.**

Without `session_start()`, PHP does not load the session data from the server file. `$_SESSION` is empty on every request, so `isset($_SESSION['user_id'])` always returns `false` and the page protection guard always redirects every visitor to login - including those who are already logged in.

```php
// Wrong
require_once __DIR__ . '/../config.php';
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

// Correct
session_start();
require_once __DIR__ . '/../config.php';
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}
```

`session_start()` must be the very first statement in any file that reads from or writes to `$_SESSION`. It must appear before any HTML output, before `require_once`, and before any `echo` statement.

---

**Error 2: Storing a password as plain text in the database.**

Inserting the raw password string directly into the `users` table means that anyone who can read the database can immediately see every user's password. This includes database backups, log files, and anyone who gains unauthorized access.

```php
// Wrong
$stmt->execute([
    'name'     => 'Andi',
    'email'    => 'andi@email.com',
    'password' => 'secret',
]);

// Correct
$stmt->execute([
    'name'     => 'Andi',
    'email'    => 'andi@email.com',
    'password' => password_hash('secret', PASSWORD_DEFAULT),
]);
```

`password_hash()` runs the bcrypt algorithm on the plain-text password and produces a unique hash string. The hash includes the algorithm identifier, the cost factor, and a random salt, so two calls with the same input produce different hashes. To verify a login, use `password_verify($input, $stored_hash)` which handles the comparison without ever exposing the original password.

---

**Error 3: Using a specific error message that reveals which part of the login failed.**

Showing "Email not found in the database" or "The password you entered is wrong" as separate messages tells an attacker exactly which emails are registered. An attacker who sees "Email not found" knows to move on. An attacker who sees "Wrong password" knows they have a valid email and can focus their efforts on guessing the password.

```php
// Wrong
if (!$user) {
    $error = 'Email not found in the database.';
} elseif (!password_verify($password, $user['password'])) {
    $error = 'The password you entered is wrong.';
}

// Correct
if (!$user || !password_verify($password, $user['password'])) {
    $error = 'The email or password you entered is incorrect.';
}
```

A single combined error message reveals nothing about which field failed. The attacker cannot tell whether the email exists or not, which makes credential enumeration significantly harder.

---

## 9. Exercises

Complete the following exercises in the `lesson-13` folder. Every file must call `session_start()` as its very first line and include the page protection guard.

**Exercise 1:** Create `create.php`. This is a protected version of the Create page from Lesson 12. Add `session_start()` and the page protection guard at the very top. Replace the hardcoded `'user_id' => 1` with `'user_id' => $_SESSION['user_id']` so that new entries are correctly linked to the logged-in user.

**Exercise 2:** Create `profile.php`. This is a protected page that displays the currently logged-in user's account information. Fetch the full user row from the `users` table using `$_SESSION['user_id']`. Display the user's name, email, registration date, and total number of entries they have written.

**Exercise 3:** Open two different browsers (for example Chrome and Firefox). Register a different user account in each browser. Create entries with each account. Verify that when you view `list.php` in Chrome you see only the entries from that user, and in Firefox you see only the entries from the other user.

---

## 10. Solutions

**Solution for Exercise 1:**

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

$errors      = [];
$old_title   = '';
$old_content = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_title   = trim($_POST['title']   ?? '');
    $old_content = trim($_POST['content'] ?? '');

    if (empty($old_title))   { $errors['title']   = 'Title is required.'; }
    if (empty($old_content)) { $errors['content']  = 'Content is required.'; }

    if (empty($errors)) {
        $stmt = $pdo->prepare("INSERT INTO entries (user_id, title, content) VALUES (:user_id, :title, :content)");
        $stmt->execute([
            'user_id' => $_SESSION['user_id'],
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
<head><meta charset="UTF-8"><title>Write Entry - Catatku</title></head>
<body>
    <p><a href="list.php">&larr; Back</a> | <a href="logout.php">Logout</a></p>
    <h1>Write New Entry</h1>
    <form method="POST" style="max-width: 500px;">
        <p>
            <label><strong>Title:</strong></label><br>
            <input type="text" name="title" value="<?= htmlspecialchars($old_title) ?>" style="width:100%;padding:8px;">
            <?php if (isset($errors['title'])): ?><br><span style="color:red;"><?= $errors['title'] ?></span><?php endif; ?>
        </p>
        <p>
            <label><strong>Content:</strong></label><br>
            <textarea name="content" rows="10" style="width:100%;padding:8px;"><?= htmlspecialchars($old_content) ?></textarea>
            <?php if (isset($errors['content'])): ?><br><span style="color:red;"><?= $errors['content'] ?></span><?php endif; ?>
        </p>
        <button type="submit" style="padding:8px 20px;">Save Entry</button>
    </form>
</body>
</html>
```

`session_start()` is the very first line, before even `require_once`. The page protection guard immediately follows: if `$_SESSION['user_id']` is not set, the redirect fires and `exit` stops all further execution. The only meaningful change from Lesson 12's `create.php` is `'user_id' => $_SESSION['user_id']` in the execute array. This links every new entry to the currently logged-in user rather than always assigning it to user 1. From this point forward, the `WHERE user_id = :user_id` filter in `list.php` will correctly show each user only their own entries.

---

**Solution for Exercise 2:**

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

$stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
$stmt->execute(['id' => $_SESSION['user_id']]);
$user = $stmt->fetch();

$stmt = $pdo->prepare("SELECT COUNT(*) AS total FROM entries WHERE user_id = :uid");
$stmt->execute(['uid' => $_SESSION['user_id']]);
$entry_count = $stmt->fetch()['total'];
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Profile - Catatku</title></head>
<body>
    <p><a href="list.php">&larr; Back</a> | <a href="logout.php">Logout</a></p>
    <h1>My Profile</h1>
    <table border="1" cellpadding="10">
        <tr><td><strong>Name</strong></td><td><?= htmlspecialchars($user['name']) ?></td></tr>
        <tr><td><strong>Email</strong></td><td><?= htmlspecialchars($user['email']) ?></td></tr>
        <tr><td><strong>Registered</strong></td><td><?= htmlspecialchars($user['created_at']) ?></td></tr>
        <tr><td><strong>Total Entries</strong></td><td><?= $entry_count ?></td></tr>
    </table>
</body>
</html>
```

Two separate queries run after the protection guard. The first fetches the full user row by `$_SESSION['user_id']` to display name, email, and registration date. The second counts entries with `COUNT(*) AS total` filtered to the same user. Both use prepared statements with `$_SESSION['user_id']` as the parameter. Although `$_SESSION` data is server-controlled and not directly injectable, prepared statements remain the correct pattern for all parameterized queries.

---

**Solution for Exercise 3:**

This exercise does not require a new file. It is a verification exercise to confirm that session-based data separation is working correctly. Open Chrome and navigate to `register.php` to create an account with `user1@test.com`. Open Firefox and navigate to `register.php` to create a second account with `user2@test.com`. In Chrome (logged in as user1), open `create.php` and write two entries. In Firefox (logged in as user2), open `create.php` and write one entry. Now open `list.php` in both browsers. Chrome should show exactly two entries belonging to user1, and Firefox should show exactly one entry belonging to user2, with no overlap. The `WHERE user_id = :user_id` clause in the list query, combined with the session that identifies who is logged in, is what enforces this separation. Each browser maintains its own independent `PHPSESSID` cookie, so the two sessions never interfere with each other.

---

## Next Up - Lesson 14

You have now built a complete authentication system from scratch. `session_start()` must appear at the top of every file that reads or writes `$_SESSION`. `$_SESSION['user_id']` is the key that identifies who is logged in across all pages. The two-line protection guard - check for `$_SESSION['user_id']` and redirect if absent - is the same pattern used by every PHP framework and content management system. `password_hash()` stores passwords as irreversible hashes, and `password_verify()` compares input against those hashes without ever exposing the original. `session_destroy()` combined with clearing `$_SESSION = []` fully terminates a session on logout.

In Lesson 14, you will find a complete summary of everything you have built, a review of the key concepts from all thirteen lessons, and a roadmap for where to take your PHP skills next.