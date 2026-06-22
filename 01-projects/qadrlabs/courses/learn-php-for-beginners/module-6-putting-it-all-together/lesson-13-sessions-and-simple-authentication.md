## 1. Before You Begin

Every page in Catatku so far uses `user_id = 1` hardcoded into the queries. Anyone who knows the URL can read, create, or edit any entry. Real applications need user accounts: each person logs in with their own credentials, sees only their own data, and cannot touch anyone else's records. This lesson builds that authentication system from the ground up.

### Introduction

HTTP is stateless — every request to the server arrives with no memory of previous requests. The server cannot tell from a request alone who sent it or whether that person has logged in. Sessions solve this: when a user logs in, the server stores their identity on the server side and sends a cookie to the browser. On every subsequent request, the browser sends the cookie back, and the server uses it to look up the stored session data. By the end of this lesson, Catatku will have registration, login, logout, and per-user data isolation.

### What You'll Build

You will create a session demonstration page, a registration form with password hashing, a login page with password verification, a logout handler, and a protected entry list that shows only the current user's entries.

### What You'll Learn

- ✅ How sessions work: `session_start()`, `$_SESSION`, `session_destroy()`
- ✅ Registering users with `password_hash()`
- ✅ Verifying passwords with `password_verify()`
- ✅ Protecting pages so only logged-in users can access them
- ✅ Scoping database queries to the current user with `$_SESSION['user_id']`
- ✅ Security: session regeneration, vague error messages, password protection

### What You'll Need

- Laragon running
- The `db_catatku` database with `users` and `entries` tables
- Lessons 1 through 12 completed

---

## 2. Setup

Create a new subfolder called `lesson-13` inside `learn-php`.

---

## 3. Understanding Sessions

### Step 1: Create the File

In `lesson-13`, create `session-demo.php`.

### Step 2: Write the Code

Open `session-demo.php` and type the following code:

```php
<?php
// session_start() MUST be the very first thing — before any output
// It starts or resumes the session, and sends a cookie to the browser
session_start();

// If the counter key does not exist in $_SESSION yet, initialize it
if (!isset($_SESSION['counter'])) {
    $_SESSION['counter'] = 0;
}

// Increment the counter on every page load
$_SESSION['counter']++;

echo "<h2>Session Demo</h2>";
echo "<p>You have visited this page <strong>{$_SESSION['counter']}</strong> times.</p>";
echo "<p>Refresh a few times — the counter keeps increasing.</p>";

echo "<h3>Full Session Contents:</h3>";
echo "<pre>";
print_r($_SESSION);
echo "</pre>";
?>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-13/session-demo.php
```

Refresh the page four or five times. The counter increments with every refresh. This is the core of session mechanics: data stored in `$_SESSION` persists between requests.

Let us trace through exactly how this works technically. The first call to `session_start()` generates a random unique session identifier (a long string like `abc123def456`), stores it on the server in a file at `storage/sessions/sess_abc123def456`, and sends it to the browser as a cookie named `PHPSESSID`. Every subsequent request that calls `session_start()`, the browser sends the cookie back, PHP finds the session file matching that ID, and loads the stored data into `$_SESSION`. The `$_SESSION` superglobal is not a regular array — it is a special handle that connects to the server-side session storage. Whatever you write to it is automatically serialized and saved to the session file when the request ends. This server-side storage is why sessions are secure for sensitive data: the browser only sees the opaque session ID, not the actual data inside it.

---

## 4. Building the Registration Page

### Step 1: Create the File

In `lesson-13`, create `register.php`.

### Step 2: Write the Code

Open `register.php` and type the following code:

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

// If already logged in, skip the registration page
if (isset($_SESSION['user_id'])) {
    header('Location: list.php');
    exit;
}

$errors    = [];
$old_name  = '';
$old_email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_name  = trim($_POST['name'] ?? '');
    $old_email = trim($_POST['email'] ?? '');
    $password  = $_POST['password'] ?? '';
    $password2 = $_POST['password_confirmation'] ?? '';

    // Validate each field
    if (empty($old_name)) {
        $errors['name'] = 'Name is required.';
    }

    if (empty($old_email) || !filter_var($old_email, FILTER_VALIDATE_EMAIL)) {
        $errors['email'] = 'A valid email address is required.';
    }

    if (strlen($password) < 8) {
        $errors['password'] = 'Password must be at least 8 characters.';
    }

    if ($password !== $password2) {
        $errors['password_confirmation'] = 'Passwords do not match.';
    }

    // Check database for duplicate email (only if the format is valid)
    if (empty($errors['email'])) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = :email");
        $stmt->execute(['email' => $old_email]);
        if ($stmt->fetch()) {
            $errors['email'] = 'This email is already registered.';
        }
    }

    if (empty($errors)) {
        $stmt = $pdo->prepare(
            "INSERT INTO users (name, email, password) VALUES (:name, :email, :password)"
        );
        $stmt->execute([
            'name'     => $old_name,
            'email'    => $old_email,
            'password' => password_hash($password, PASSWORD_DEFAULT),
        ]);

        $user_id = $pdo->lastInsertId();

        // Auto-login after registration by writing to $_SESSION
        $_SESSION['user_id']   = (int) $user_id;
        $_SESSION['user_name'] = $old_name;

        // Generate a new session ID to prevent session fixation attacks
        session_regenerate_id(true);

        header('Location: list.php');
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Register — Catatku</title></head>
<body>

    <h1>Create a New Account</h1>

    <form method="POST" action="" style="max-width: 400px;">
        <div style="margin-bottom: 12px;">
            <label><strong>Name:</strong></label><br>
            <input type="text" name="name"
                   value="<?= htmlspecialchars($old_name) ?>"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['name'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['name']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label><strong>Email:</strong></label><br>
            <input type="email" name="email"
                   value="<?= htmlspecialchars($old_email) ?>"
                   style="width: 100%; padding: 8px;">
            <?php if (isset($errors['email'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['email']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label><strong>Password:</strong></label><br>
            <input type="password" name="password" style="width: 100%; padding: 8px;">
            <?php if (isset($errors['password'])): ?>
                <br><span style="color: red;"><?= htmlspecialchars($errors['password']) ?></span>
            <?php endif; ?>
        </div>

        <div style="margin-bottom: 12px;">
            <label><strong>Confirm Password:</strong></label><br>
            <input type="password" name="password_confirmation" style="width: 100%; padding: 8px;">
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

### Step 3: Save the File

Press **Ctrl+S**.

This registration page introduces two important security features. `password_hash($password, PASSWORD_DEFAULT)` uses bcrypt to create a one-way hash of the password. The result is a long string like `$2y$10$abcdef...` that cannot be reversed — it is mathematically infeasible to derive the original password from the hash. `PASSWORD_DEFAULT` uses whatever PHP's currently recommended algorithm is, so your hashes automatically use the strongest available option. Notice that password fields do not get their `value` attribute repopulated after validation errors — this is intentional. Sending the password value back to the browser in an HTML attribute means it stays in browser history and HTTP logs. Users should retype passwords.

`session_regenerate_id(true)` creates a new session ID immediately after login, invalidating the old one. Without this, if an attacker somehow captured the user's session cookie before login (through network sniffing or XSS), they could take over the session after the user authenticates. Regenerating the ID means the attacker's captured cookie becomes worthless the moment the user logs in.

---

## 5. Building the Login Page

### Step 1: Create the File

In `lesson-13`, create `login.php`.

### Step 2: Write the Code

Open `login.php` and type the following code:

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

// Redirect logged-in users away from the login page
if (isset($_SESSION['user_id'])) {
    header('Location: list.php');
    exit;
}

$error     = '';
$old_email = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $old_email = trim($_POST['email'] ?? '');
    $password  = $_POST['password'] ?? '';

    // Look up the user by email
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email");
    $stmt->execute(['email' => $old_email]);
    $user = $stmt->fetch();

    // password_verify() compares the plain password with the stored hash
    if ($user && password_verify($password, $user['password'])) {
        // Successful login — store minimal user info in session
        $_SESSION['user_id']   = (int) $user['id'];
        $_SESSION['user_name'] = $user['name'];
        session_regenerate_id(true);

        header('Location: list.php');
        exit;
    } else {
        // IMPORTANT: Use one vague message that covers both "wrong email" and "wrong password"
        // Separate messages would let attackers discover which emails are registered
        $error = 'The email or password you entered is incorrect.';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Login — Catatku</title></head>
<body>

    <h1>Log in to Catatku</h1>

    <?php if ($error): ?>
        <p style="color: red; border: 1px solid red; padding: 10px; max-width: 400px;">
            <?= htmlspecialchars($error) ?>
        </p>
    <?php endif; ?>

    <form method="POST" action="" style="max-width: 400px;">
        <div style="margin-bottom: 12px;">
            <label><strong>Email:</strong></label><br>
            <input type="email" name="email"
                   value="<?= htmlspecialchars($old_email) ?>"
                   style="width: 100%; padding: 8px;">
        </div>

        <div style="margin-bottom: 12px;">
            <label><strong>Password:</strong></label><br>
            <input type="password" name="password" style="width: 100%; padding: 8px;">
        </div>

        <button type="submit" style="padding: 8px 20px;">Log In</button>
    </form>

    <p>Don't have an account? <a href="register.php">Register here</a></p>

</body>
</html>
```

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-13/login.php
```

Try logging in with `budi@example.com` and `password123` (from the seed data in Lesson 10). You should be redirected to the list page.

The login flow deserves careful examination because the order of operations matters for security. First we fetch the user by email with a prepared statement. Then `password_verify($password, $user['password'])` uses PHP's built-in function to compare the plain-text password against the stored hash. This function is timing-safe — it takes the same amount of time regardless of whether the comparison succeeds or fails, which prevents timing attacks where an attacker could measure response times to guess passwords. The `$user && password_verify(...)` combines two checks: the user must exist AND the password must match. Only then is the login considered successful. The intentionally vague error message "The email or password you entered is incorrect" is important: if you said "Email not found" separately from "Wrong password", an attacker could write an automated tool to test email addresses and build a list of registered users by watching which error appears.

---

## 6. Building Logout

### Step 1: Create the File

In `lesson-13`, create `logout.php`.

### Step 2: Write the Code

```php
<?php
session_start();
$_SESSION = [];      // Clear all session data from memory
session_destroy();   // Delete the session file from the server
header('Location: login.php');
exit;
?>
```

### Step 3: Save the File

Press **Ctrl+S**.

Logout requires two steps that are often confused. `$_SESSION = []` clears the in-memory session array during this request. `session_destroy()` deletes the session data file from the server's filesystem so the session cookie becomes permanently invalid. If you only did `session_destroy()` without clearing `$_SESSION`, the session data would still be in memory for the remainder of the current request. If you only cleared `$_SESSION`, the server-side file would still exist and someone who captured the session cookie could potentially resume it. Both steps together guarantee a clean logout.

---

## 7. Protecting Pages and Scoping Data to Users

### Step 1: Create the Protected List

In `lesson-13`, create `list.php`.

### Step 2: Write the Code

```php
<?php
session_start();
require_once __DIR__ . '/../config.php';

// THE TWO-LINE PROTECTION PATTERN — add this to every protected page
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

// Only fetch entries belonging to the logged-in user
$stmt = $pdo->prepare(
    "SELECT * FROM entries WHERE user_id = :user_id ORDER BY created_at DESC"
);
$stmt->execute(['user_id' => $_SESSION['user_id']]);
$entries = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>My Entries — Catatku</title></head>
<body>

    <p>
        Hello, <strong><?= htmlspecialchars($_SESSION['user_name']) ?></strong>!
        | <a href="logout.php">Logout</a>
    </p>

    <h1>My Entries</h1>

    <?php if (isset($_GET['message'])): ?>
        <?php $messages = ['created' => 'Entry saved!', 'updated' => 'Entry updated!', 'deleted' => 'Entry deleted!']; ?>
        <p style="color: green; border: 1px solid green; padding: 10px; max-width: 500px;">
            <?= $messages[$_GET['message']] ?? 'Done!' ?>
        </p>
    <?php endif; ?>

    <p><a href="create.php">+ Write New Entry</a></p>

    <?php if (empty($entries)): ?>
        <p>No entries yet. Start writing your first entry!</p>
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

### Step 3: Save and Run

```
http://localhost/learn-php/lesson-13/list.php
```

If you are not logged in, you will be redirected to the login page immediately. After logging in, you will only see entries that belong to the current user.

The two-line protection pattern is worth memorizing because it appears at the top of every protected page in PHP applications: check `isset($_SESSION['user_id'])`, and if it is missing, redirect and exit. The `WHERE user_id = :user_id` in the query is equally important — without it, a logged-in user could potentially see or edit another user's entries by manipulating the `id` URL parameter. Filtering at the database level ensures each query returns only the current user's data regardless of what IDs are provided in the URL.

---

## 8. Run and Test

Start by visiting the login page directly. Enter the credentials from the seed data (`budi@example.com` / `password123`) and confirm you are redirected to the list page showing Budi's entries. Click the Logout link and confirm you are redirected back to the login page and can no longer access the list directly.

Now register a new account. Go to `http://localhost/learn-php/lesson-13/register.php`, fill in the form, and submit. You should be automatically logged in and redirected to the list page, which will be empty because the new user has no entries yet.

Try the access control test: log out, then manually type `http://localhost/learn-php/lesson-13/list.php` in the address bar. The page should redirect you to the login page rather than showing the content. This confirms the page protection works for direct URL access, not just for users who click the logout button.

Open a second browser (if you have Chrome and Firefox), register a second user there, and create a few entries. Switch back to the first browser and confirm that user one's list only shows their own entries. This proves the `WHERE user_id = :user_id` filter is working correctly at the data isolation level.

---

## 9. Fix the Errors in Your Code

```php
<?php
require_once __DIR__ . '/../config.php';

// Mistake 1: Missing session_start()
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

// Mistake 2: Password stored as plain text
$stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (:n, :e, :p)");
$stmt->execute(['n' => 'Andi', 'e' => 'andi@email.com', 'p' => 'secret123']);

// Mistake 3: Separate error messages reveal which part was wrong
if (!$user) {
    $error = 'Email not found.';           // Tells attacker the email doesn't exist
} elseif (!password_verify($pass, $user['password'])) {
    $error = 'Wrong password entered.';    // Confirms the email exists
}
?>
```

The first mistake is the most common session error: `session_start()` is missing. Without it, `$_SESSION` is always an uninitialized superglobal, so `isset($_SESSION['user_id'])` always returns `false` and every visitor is redirected to the login page. Place `session_start()` as the very first line, before `require_once` or any other output. The second mistake stores the plain text password `'secret123'` in the database. Use `password_hash('secret123', PASSWORD_DEFAULT)`. The third mistake uses separate error messages for "email not found" versus "wrong password." An attacker can use this to map out registered email addresses: if the first message appears, the email exists; if the second appears, the email exists but the password is wrong. Always combine them: `$error = 'The email or password you entered is incorrect.'`

---

## 10. Exercises

**Exercise 1:** Create `create.php` in `lesson-13` — a protected version that adds `session_start()` and page protection at the top and replaces `'user_id' => 1` with `'user_id' => $_SESSION['user_id']`.

**Exercise 2:** Create `profile.php` in `lesson-13`. Display the logged-in user's name, email, registration date, and total entry count. Protect the page.

**Exercise 3:** Open Chrome and Firefox. Register two different users in different browsers. Create entries with each. Verify each user sees only their own entries.

---

## 11. Understanding Sessions and Authentication

Sessions bridge the gap between HTTP's statelessness and applications that need to remember users. The session ID in a cookie is the key to a lockbox on the server, and the lockbox holds the user's identity. As long as the user has the key (cookie) and the lockbox exists (session file), they are "remembered" between requests.

The authentication flow is a three-part sequence that every secure system uses. During registration, hash the password and store the hash — never the plain text. During login, look up the user by their identifier (email), then use `password_verify()` to check the submitted password against the stored hash. During the session, store the user's ID in `$_SESSION` and use it to filter every subsequent database query. This sequence, properly implemented, means passwords are never readable in the database and users can only access their own data.

Session regeneration is a subtle but important security detail. Before a user logs in, their session cookie is unauthenticated. After login, it becomes privileged. If an attacker captured the unauthenticated session ID and is waiting to use it after the user logs in, `session_regenerate_id(true)` invalidates that old ID and issues a new one. The attacker's captured cookie is now worthless, even though the user is logged in.

Data isolation — filtering every query with `WHERE user_id = :user_id` — is the application-level enforcement of privacy. Even if a bug somewhere in your code accepted an arbitrary ID as input, the database query would still only return that user's own rows because the session's `user_id` is used as the filter, not any URL parameter.

---

## 12. Conclusion

Sessions persist user identity across HTTP requests. `session_start()` must be the first line on every page that uses sessions. `$_SESSION` is the server-side storage accessed through a cookie ID. Register with `password_hash()`, verify with `password_verify()`. Protect every restricted page with the two-line pattern: check `$_SESSION['user_id']`, redirect and exit if missing. Always use one vague error message for login failures. Filter every query by `user_id` to ensure data isolation.

**In Lesson 14**, you will review everything you have learned, see how it maps to the next stage of learning (PHP OOP), and plan your path forward.