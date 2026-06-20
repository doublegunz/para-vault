## 1. Before You Begin

### Introduction

The application can display entries, but there is no way to create new ones from the browser. This lesson builds the create form with validation, CSRF protection, and flash messages, using the full OOP architecture we have been building.

### What You'll Build

A complete create flow: form display, input validation, CSRF protection, and database insertion with a success message.

### What You'll Learn

- ✅ How to handle form submissions with POST routes
- ✅ How to validate user input in a controller
- ✅ What CSRF protection is and how to implement it with session tokens
- ✅ How to preserve form input after validation failures
- ✅ The two-route pattern: GET to display, POST to process

### What You'll Need

- The router, View class, and templates from Lessons 8-9
- The development server running

---

## 2. Add CSRF Helper Functions

This section creates utility helper functions to manage session-based CSRF tokens and to preserve user input after validation errors.

### Step 1: Create the File

Right-click on the `src` folder, select **New File**, type `Helpers.php`, and press Enter.

### Step 2: Write the Code

Open `src/Helpers.php` and type the following code:

```php
<?php

namespace App;

class Helpers
{
    public static function generateCsrfToken(): string
    {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }

    public static function verifyCsrfToken(string $token): bool
    {
        return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }

    public static function csrfField(): string
    {
        $token = self::generateCsrfToken();
        return '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($token) . '">';
    }

    public static function old(string $key, string $default = ''): string
    {
        $value = $_SESSION['old'][$key] ?? $default;
        return htmlspecialchars($value);
    }

    public static function setOld(array $data): void
    {
        $_SESSION['old'] = $data;
    }

    public static function clearOld(): void
    {
        unset($_SESSION['old']);
    }
}
```

CSRF (Cross-Site Request Forgery) protection prevents other websites from submitting forms to your application. A random token is stored in the session and included as a hidden field in every form. When the form is submitted, the token is verified. If it does not match, the request is rejected.

`old()` preserves form input after validation failures. When the form has errors, the user does not have to retype everything.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 3. Add a Dev-Login Route (Temporary)

Until we build real authentication in Lesson 12, we need a way to simulate a logged-in user.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Add the Dev-Login Route

Add these routes to `public/index.php` before the `dispatch()` call:

```php
$router->get('/dev-login', [HomeController::class, 'devLogin']);
$router->get('/entries/create', [EntryController::class, 'create']);
$router->post('/entries', [EntryController::class, 'store']);
```

The `GET /entries/create` route displays the form, and the `POST /entries` route receives the form submission.

### Step 3: Add the devLogin Method

Open `src/Controllers/HomeController.php` and add:

```php
    public function devLogin(): void
    {
        $_SESSION['user_id'] = 1;
        $_SESSION['user_name'] = 'Budi';
        \App\View::setFlash('success', 'Dev login successful!');
        header('Location: /entries');
        exit;
    }
```

The `devLogin` method simulates a successful login by hardcoding a user ID into the session and redirecting to the entries page.

### Step 4: Save Both Files

Press **Ctrl+S** for both files.

---

## 4. Add Controller Methods for Create

This section adds the `create` method to render the HTML form, and the `store` method to process and validate the submitted data.

### Step 1: Open the File

Open `src/Controllers/EntryController.php`.

### Step 2: Add the create() and store() Methods

Add these methods to the `EntryController` class:

```php
    public function create(): void
    {
        if (!isset($_SESSION['user_id'])) {
            header('Location: /login');
            exit;
        }
        View::render('entry/create');
    }

    public function store(): void
    {
        if (!isset($_SESSION['user_id'])) {
            header('Location: /login');
            exit;
        }

        $token = $_POST['csrf_token'] ?? '';
        if (!\App\Helpers::verifyCsrfToken($token)) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            return;
        }

        $title   = trim($_POST['title'] ?? '');
        $content = trim($_POST['content'] ?? '');
        $errors  = [];

        if (empty($title)) {
            $errors['title'] = 'Title is required.';
        } elseif (strlen($title) > 255) {
            $errors['title'] = 'Title must be 255 characters or less.';
        }

        if (empty($content)) {
            $errors['content'] = 'Content is required.';
        }

        if (!empty($errors)) {
            \App\Helpers::setOld(['title' => $title, 'content' => $content]);
            View::render('entry/create', ['errors' => $errors]);
            \App\Helpers::clearOld();
            return;
        }

        $this->entryRepo->create([
            'user_id' => $_SESSION['user_id'],
            'title'   => $title,
            'content' => $content,
        ]);

        View::setFlash('success', 'Entry created successfully!');
        header('Location: /entries');
        exit;
    }
```

The `create()` method renders the form template. The `store()` method validates the CSRF token to ensure the request is legitimate, then validates the title and content. If errors exist, it saves the input to the session using `setOld()`, re-renders the form with the errors array, and clears the old data. If validation passes, the entry is saved, a flash message is set, and the user is redirected via the Post/Redirect/Get pattern.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 5. Create the Form Template

This section creates the HTML form to capture the user's entry title and content.

### Step 1: Create the File

Right-click on `templates/entry`, select **New File**, type `create.php`.

### Step 2: Write the Code

Open `templates/entry/create.php` and type the following code:

```php
<?php $title = 'Write New Entry - Catatku'; ?>

<p><a href="/entries">&larr; Back to list</a></p>

<h2>Write New Entry</h2>

<form method="POST" action="/entries">
    <?= \App\Helpers::csrfField() ?>

    <div style="margin-bottom: 15px;">
        <label><strong>Title:</strong></label><br>
        <input type="text" name="title" value="<?= \App\Helpers::old('title') ?>"
               style="width:100%; padding:8px; border:1px solid <?= isset($errors['title']) ? 'red' : '#ccc' ?>; border-radius:4px; max-width:500px;">
        <?php if (isset($errors['title'])): ?>
            <p style="color:red; font-size:0.85em;"><?= htmlspecialchars($errors['title']) ?></p>
        <?php endif; ?>
    </div>

    <div style="margin-bottom: 15px;">
        <label><strong>Content:</strong></label><br>
        <textarea name="content" rows="10"
                  style="width:100%; padding:8px; border:1px solid <?= isset($errors['content']) ? 'red' : '#ccc' ?>; border-radius:4px; max-width:500px;"
        ><?= \App\Helpers::old('content') ?></textarea>
        <?php if (isset($errors['content'])): ?>
            <p style="color:red; font-size:0.85em;"><?= htmlspecialchars($errors['content']) ?></p>
        <?php endif; ?>
    </div>

    <div>
        <a href="/entries" style="margin-right:10px;">Cancel</a>
        <button type="submit" class="btn btn-primary">Save Entry</button>
    </div>
</form>
```

The form uses the `POST` method to send data to `/entries`. The `csrfField()` helper inserts a hidden token input. The `old()` helper ensures that any previously typed text is repopulated if the form submission fails validation, preventing data loss. Error messages are conditionally displayed next to each field by checking if the `$errors` array contains a specific key.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 6. Test the Create Flow

This section tests the end-to-end functionality, ensuring validation messages and CSRF token logic operate correctly.

### Step 1: Log In

Open `http://localhost:8080/dev-login`. You will be redirected to `/entries` with a success message.

### Step 2: Create an Entry

Click the **+ Write New Entry** button. Fill in the form and click **Save Entry**.

### Step 3: Test Validation

Submit the form with empty fields. You should see validation error messages, and previously filled data should be preserved.

---

## 7. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: Forgetting CSRF verification
public function store(): void {
    $title = $_POST['title'] ?? '';
    $this->entryRepo->create(['title' => $title, ...]);
    // No CSRF check! Any website can submit this form
}

// Error 2: Not sanitizing before display
<input value="<?= $_POST['title'] ?>">
// XSS vulnerability — use htmlspecialchars() or the old() helper

// Error 3: No redirect after successful POST
$this->entryRepo->create($data);
View::render('entry/index', ['entries' => $entries]);
// User refreshes = double submission!
```

**Error 1: Missing CSRF verification.** Without checking the token, any external website could submit a form to your application. Always verify the CSRF token before processing POST data.

**Error 2: XSS vulnerability.** Displaying `$_POST` data directly without escaping allows script injection. Use `Helpers::old()` which applies `htmlspecialchars()` automatically.

**Error 3: No redirect after POST.** Rendering directly after a POST means refreshing the page resubmits the form. Always redirect with `header('Location: ...')` after a successful POST (the Post/Redirect/Get pattern).

---

## 8. Exercises

**Exercise 1:** Add a character counter below the content textarea that shows "0 / 1000 characters" using JavaScript (no PHP needed). Limit the content field to 1000 characters in server-side validation.

**Exercise 2:** Add a "Draft" feature: add a `<select>` dropdown for status with options "Published" and "Draft". For now, just display the selected status in the success flash message without changing the database.

**Exercise 3:** Modify the `store()` method to also validate that the title contains only letters, numbers, spaces, and basic punctuation. Use `preg_match()` for the validation. Display a helpful error message if the check fails.

---

## 9. Solutions

**Solution for Exercise 1:**

Add to the content validation in `store()`:

```php
    if (strlen($content) > 1000) {
        $errors['content'] = 'Content must be 1000 characters or less.';
    }
```

This simple server-side validation guarantees the bounds check is respected regardless of client-side scripts.

Add JavaScript after the textarea in `create.php`:

```php
<script>
document.querySelector('textarea[name="content"]').addEventListener('input', function() {
    document.getElementById('char-count').textContent = this.value.length + ' / 1000 characters';
});
</script>
<p id="char-count" style="color:#999;font-size:0.8em;">0 / 1000 characters</p>
```

This JavaScript provides immediate visual feedback to the user as they type, improving the user experience before submission.

**Solution for Exercise 2:**

Add to the form template:

```php
<div style="margin-bottom: 15px;">
    <label><strong>Status:</strong></label><br>
    <select name="status" style="padding:8px;">
        <option value="published">Published</option>
        <option value="draft">Draft</option>
    </select>
</div>
```

This adds a native HTML dropdown menu for status selection.

Update flash message in `store()`:

```php
$status = $_POST['status'] ?? 'published';
View::setFlash('success', "Entry created as $status!");
```

This uses the null coalescing operator (`??`) to provide a logical default if the field is omitted.

**Solution for Exercise 3:**

Add to validation in `store()`:

```php
    if (!preg_match('/^[a-zA-Z0-9\s\.,!?\-:\'\"]+$/', $title)) {
        $errors['title'] = 'Title can only contain letters, numbers, spaces, and basic punctuation.';
    }
```

The `preg_match` provides an additional layer of constraint over standard validation, ensuring the content meets specific formatting rules before reaching the database.

---

## 10. Conclusion

CSRF protection uses a session-stored token verified on form submission. Validation checks each field and collects errors. If errors exist, the form is re-rendered with old values preserved. If no errors, the data is saved and the user is redirected (Post/Redirect/Get pattern). This is the exact same flow used by every PHP framework.

---

## Next Up - Lesson 11: Edit and Delete Operations

In the next lesson you will:

1. Build functionality to edit previously created entries
2. Safely process update statements in the repository
3. Implement secure deletion of records using POST requests