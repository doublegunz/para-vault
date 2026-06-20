## 1. Before You Begin

### Introduction

The previous lesson built the create form. Users can now write new entries. But entries cannot be modified or removed. This lesson completes the CRUD cycle with edit and delete functionality, adding ownership protection so users can only modify their own entries.

### What You'll Build

Edit and delete functionality with ownership checks, CSRF protection, pre-filled forms, and proper redirects.

### What You'll Learn

- ✅ How to build an edit form with pre-filled data
- ✅ How to implement delete with CSRF verification
- ✅ How to add ownership checks so users only modify their own entries
- ✅ How `old('field', $default)` works for edit forms

### What You'll Need

- Logged in via `/dev-login`
- At least one entry created
- The development server running

---

## 2. Add the Routes

This section adds the necessary HTTP endpoints for the edit and delete workflows.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Update the Routes

Replace the route definitions with the complete set:

```php
$router->get('/', [HomeController::class, 'index']);
$router->get('/dev-login', [HomeController::class, 'devLogin']);
$router->get('/entries', [EntryController::class, 'index']);
$router->get('/entries/create', [EntryController::class, 'create']);
$router->post('/entries', [EntryController::class, 'store']);
$router->get('/entries/{id}', [EntryController::class, 'show']);
$router->get('/entries/{id}/edit', [EntryController::class, 'edit']);
$router->post('/entries/{id}/update', [EntryController::class, 'update']);
$router->post('/entries/{id}/delete', [EntryController::class, 'destroy']);
```

The new routes handle displaying the edit form (`GET /edit`), processing the edit submission (`POST /update`), and processing the deletion (`POST /delete`). Each is mapped to a dedicated method in the `EntryController`.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 3. Add Controller Methods

This section implements the controller logic to verify ownership, render forms, and perform database updates or deletions safely.

### Step 1: Open the File

Open `src/Controllers/EntryController.php`.

### Step 2: Add the Helper Method

Add a private method to find an entry with ownership check:

```php
    private function findOwnedEntry(int $id): ?\App\Models\Entry
    {
        $entry = $this->entryRepo->findById($id);
        if (!$entry || $entry->getUserId() !== (int) $_SESSION['user_id']) {
            return null;
        }
        return $entry;
    }
```

The `findOwnedEntry` method centralizes the ownership check. It ensures the current logged-in user actually owns the post before returning it, preventing unauthorized access.

### Step 3: Add the edit() Method

Add below the `store()` method:

```php
    public function edit(int $id): void
    {
        if (!isset($_SESSION['user_id'])) { header('Location: /login'); exit; }

        $entry = $this->findOwnedEntry($id);
        if (!$entry) {
            http_response_code(403);
            echo '<h1>Entry not found or access denied</h1>';
            return;
        }

        View::render('entry/edit', ['entry' => $entry]);
    }
```

The `edit` method loads the record. If the entry is not found or not owned by the user, it returns a 403 Forbidden status.

### Step 4: Add the update() Method

```php
    public function update(int $id): void
    {
        if (!isset($_SESSION['user_id'])) { header('Location: /login'); exit; }

        $entry = $this->findOwnedEntry($id);
        if (!$entry) {
            http_response_code(403);
            echo '<h1>Entry not found or access denied</h1>';
            return;
        }

        if (!\App\Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            return;
        }

        $title   = trim($_POST['title'] ?? '');
        $content = trim($_POST['content'] ?? '');
        $errors  = [];

        if (empty($title)) { $errors['title'] = 'Title is required.'; }
        if (empty($content)) { $errors['content'] = 'Content is required.'; }

        if (!empty($errors)) {
            \App\Helpers::setOld(['title' => $title, 'content' => $content]);
            View::render('entry/edit', ['entry' => $entry, 'errors' => $errors]);
            \App\Helpers::clearOld();
            return;
        }

        $this->entryRepo->update($id, ['title' => $title, 'content' => $content]);
        View::setFlash('success', 'Entry updated successfully!');
        header('Location: /entries/' . $id);
        exit;
    }
```

The `update` method is structurally similar to `store`. It verifies CSRF and ownership, validates the modified input, displays old values if validation fails, updates the database, and redirects.

### Step 5: Add the destroy() Method

```php
    public function destroy(int $id): void
    {
        if (!isset($_SESSION['user_id'])) { header('Location: /login'); exit; }

        $entry = $this->findOwnedEntry($id);
        if (!$entry) {
            http_response_code(403);
            echo '<h1>Entry not found or access denied</h1>';
            return;
        }

        if (!\App\Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            return;
        }

        $this->entryRepo->delete($id);
        View::setFlash('success', 'Entry deleted successfully!');
        header('Location: /entries');
        exit;
    }
```

The `destroy` method also verifies CSRF and ownership. This is crucial since destructive actions should never be executed without explicit and verified intent. Once deleted, it redirects to the entries list.

### Step 6: Save the File

Press **Ctrl+S**.

---

## 4. Create the Edit Template

This section creates the HTML form specifically for editing existing records, prepopulating fields with current data.

### Step 1: Create the File

Right-click on `templates/entry`, select **New File**, type `edit.php`.

### Step 2: Write the Code

Open `templates/entry/edit.php` and type:

```php
<?php $title = 'Edit Entry - Catatku'; ?>

<p><a href="/entries/<?= $entry->getId() ?>">&larr; Back to entry</a></p>

<h2>Edit Entry</h2>

<form method="POST" action="/entries/<?= $entry->getId() ?>/update">
    <?= \App\Helpers::csrfField() ?>

    <div style="margin-bottom: 15px;">
        <label><strong>Title:</strong></label><br>
        <input type="text" name="title"
               value="<?= \App\Helpers::old('title', $entry->getTitle()) ?>"
               style="width:100%; padding:8px; border:1px solid <?= isset($errors['title']) ? 'red' : '#ccc' ?>; border-radius:4px; max-width:500px;">
        <?php if (isset($errors['title'])): ?>
            <p style="color:red; font-size:0.85em;"><?= htmlspecialchars($errors['title']) ?></p>
        <?php endif; ?>
    </div>

    <div style="margin-bottom: 15px;">
        <label><strong>Content:</strong></label><br>
        <textarea name="content" rows="10"
                  style="width:100%; padding:8px; border:1px solid <?= isset($errors['content']) ? 'red' : '#ccc' ?>; border-radius:4px; max-width:500px;"
        ><?= \App\Helpers::old('content', $entry->getContent()) ?></textarea>
        <?php if (isset($errors['content'])): ?>
            <p style="color:red; font-size:0.85em;"><?= htmlspecialchars($errors['content']) ?></p>
        <?php endif; ?>
    </div>

    <div>
        <a href="/entries/<?= $entry->getId() ?>" style="margin-right:10px;">Cancel</a>
        <button type="submit" class="btn btn-primary">Save Changes</button>
    </div>
</form>
```

The `old('title', $entry->getTitle())` helper serves a dual purpose. On the first load, it displays the entry's current value from the database. After a failed validation, it displays the user's latest input to prevent data loss.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 5. Update Show Template with Edit/Delete Buttons

This section updates the detail view to include interactive buttons for modifying or removing the entry.

### Step 1: Open the File

Open `templates/entry/show.php`.

### Step 2: Add Action Buttons

Add the following after the article closing tag:

```php
<?php if (isset($_SESSION['user_id']) && $_SESSION['user_id'] === $entry->getUserId()): ?>
<div style="margin-top: 15px;">
    <a href="/entries/<?= $entry->getId() ?>/edit" class="btn btn-primary btn-sm">Edit</a>
    <form method="POST" action="/entries/<?= $entry->getId() ?>/delete"
          style="display:inline;" onsubmit="return confirm('Are you sure you want to delete this entry?')">
        <?= \App\Helpers::csrfField() ?>
        <button type="submit" class="btn btn-danger btn-sm">Delete</button>
    </form>
</div>
<?php endif; ?>
```

The `if` condition ensures these buttons only appear if the currently authenticated user is the true owner of the entry. The delete button uses a form with a CSRF token to safely trigger a `POST` request, rather than a simple (and vulnerable) `GET` link.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 6. Test Edit and Delete

This section verifies that the edit and delete functionalities work exactly as intended for an authenticated owner.

### Step 1: Log In

Visit `http://localhost:8080/dev-login` if not already logged in.

### Step 2: Test Edit

Go to any entry's detail page and click **Edit**. Change the title, click **Save Changes**. Verify the updated title appears.

### Step 3: Test Delete

On an entry's detail page, click **Delete**. Confirm the dialog. Verify the entry is removed from the listing.

### Step 4: Test Validation

On the edit form, clear the title and submit. Verify the validation error appears and the content field retains its value.

---

## 7. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: No ownership check
public function edit(int $id): void {
    $entry = $this->entryRepo->findById($id);
    View::render('entry/edit', ['entry' => $entry]);
    // Any user can edit any entry!
}

// Error 2: Delete via GET request
$router->get('/entries/{id}/delete', [EntryController::class, 'destroy']);
// GET requests can be triggered by links, bots, or browser prefetch!

// Error 3: Missing CSRF on delete form
<a href="/entries/5/delete">Delete</a>
// No CSRF token, and using GET instead of POST form
```

**Error 1: No ownership check.** Without verifying `$entry->getUserId() === $_SESSION['user_id']`, any logged-in user can edit any entry by guessing the ID. Always check ownership.

**Error 2: Delete via GET.** Destructive actions must use POST to prevent accidental deletion from link prefetching, bots, or browser extensions. Use a form with `method="POST"`.

**Error 3: No CSRF on delete.** Delete must use a POST form with a CSRF token, not a plain link. Use a form with `<?= Helpers::csrfField() ?>`.

---

## 8. Exercises

**Exercise 1:** Add a "last edited" indicator to the entry listing. If an entry has been updated (`isEdited()` returns true), show "Edited" next to the date.

**Exercise 2:** Add a "Duplicate" button on the show page that creates a copy of the entry with "(Copy)" appended to the title. Use a POST form with CSRF protection.

**Exercise 3:** Add a confirmation page for delete instead of using JavaScript `confirm()`. Create `templates/entry/delete-confirm.php` that shows the entry title and two buttons: "Yes, Delete" (POST form) and "Cancel" (link back).

---

## 9. Solutions

**Solution for Exercise 1:**

In `templates/entry/index.php`, modify the date display:

```php
<small style="color:#999;">
    <?= htmlspecialchars($entry->getCreatedAt()) ?>
    <?php if ($entry->isEdited()): ?>
        <span style="color:#cc7700;">(edited)</span>
    <?php endif; ?>
</small>
```

This condition dynamically tags entries that have been modified since their initial creation.

**Solution for Exercise 2:**

Add route in `public/index.php`:

```php
$router->post('/entries/{id}/duplicate', [EntryController::class, 'duplicate']);
```

Add method in `EntryController`:

```php
    public function duplicate(int $id): void
    {
        if (!isset($_SESSION['user_id'])) { header('Location: /login'); exit; }
        $entry = $this->findOwnedEntry($id);
        if (!$entry) { http_response_code(403); echo 'Denied'; return; }
        if (!\App\Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) { http_response_code(403); return; }

        $newId = $this->entryRepo->create([
            'user_id' => $_SESSION['user_id'],
            'title'   => $entry->getTitle() . ' (Copy)',
            'content' => $entry->getContent(),
        ]);
        View::setFlash('success', 'Entry duplicated!');
        header('Location: /entries/' . $newId);
        exit;
    }
```

The `duplicate` method retrieves an entry safely, clones its data with a modified title, inserts a new record, and redirects the user to their new copy.

**Solution for Exercise 3:**

Add route: `$router->get('/entries/{id}/delete', [EntryController::class, 'confirmDelete']);`

Controller method:

```php
    public function confirmDelete(int $id): void
    {
        $entry = $this->findOwnedEntry($id);
        if (!$entry) { http_response_code(403); echo 'Denied'; return; }
        View::render('entry/delete-confirm', ['entry' => $entry]);
    }
```

Create `templates/entry/delete-confirm.php`:

```php
<?php $title = 'Confirm Delete'; ?>
<h2>Delete Entry?</h2>
<p>Are you sure you want to delete "<strong><?= htmlspecialchars($entry->getTitle()) ?></strong>"?</p>
<form method="POST" action="/entries/<?= $entry->getId() ?>/delete" style="display:inline;">
    <?= \App\Helpers::csrfField() ?>
    <button type="submit" class="btn btn-danger">Yes, Delete</button>
</form>
<a href="/entries/<?= $entry->getId() ?>" style="margin-left:10px;">Cancel</a>
```

Instead of relying on browser dialogs, a dedicated confirmation view requires a secondary `POST` request, adding safety against accidental clicks while maintaining CSRF protection.

---

## 10. Conclusion

The CRUD cycle is now complete: create, read, update, delete, all with proper validation, CSRF protection, and ownership authorization. The `findOwnedEntry()` method centralizes the lookup and ownership check, preventing code repetition. Every POST request that modifies data verifies the CSRF token.

---

## Next Up - Lesson 12: Authentication system

In the next lesson you will:

1. Build a real authentication system
2. Handle user registration, login, and logout
3. Protect routes from unauthorized access