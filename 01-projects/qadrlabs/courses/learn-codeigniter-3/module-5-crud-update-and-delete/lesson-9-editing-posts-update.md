## 1. Before You Begin

Creating posts works. Now users need to edit existing posts. The edit form is similar to the create form but pre-filled with the existing data. The controller loads the post, passes it to the view, validates the submitted changes, and updates the database.

### What You'll Build

You will create the edit form with pre-filled data, validation, and update logic.

### What You'll Learn

- ✅ Loading existing data into a form
- ✅ Using `set_value()` with a default value for edit forms
- ✅ Updating a record via the model
- ✅ The edit/update controller flow

### What You'll Need

- Lesson 8 completed

---

## 2. Add Controller Methods

Just like the create feature used two methods (`create` to show the form, `store` to process it), the edit feature follows the same pattern: `edit` loads the form pre-filled with existing data, and `update` processes the submission.

Open `application/controllers/Posts.php` and add the following two methods inside the class.

```php
public function edit($id)
{
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }

    $data['title'] = 'Edit Post';
    $data['post'] = $post;
    $this->load->view('posts/edit', $data);
}

public function update($id)
{
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }

    $this->load->library('form_validation');
    $this->form_validation->set_rules('title', 'Title', 'required|max_length[255]');
    $this->form_validation->set_rules('content', 'Content', 'required');
    $this->form_validation->set_rules('status', 'Status', 'required|in_list[draft,publish]');

    if ($this->form_validation->run() === FALSE) {
        $data['title'] = 'Edit Post';
        $data['post'] = $post;
        $this->load->view('posts/edit', $data);
        return;
    }

    $post_data = [
        'title'   => $this->input->post('title'),
        'slug'    => $this->Post_model->generate_slug($this->input->post('title')),
        'content' => $this->input->post('content'),
        'status'  => $this->input->post('status'),
    ];

    $this->Post_model->update($id, $post_data);
    $this->session->set_flashdata('success', 'Post updated successfully.');
    redirect('posts');
}
```

Here is what is happening in each method:

- In `edit($id)`, `$this->Post_model->get_by_id($id)` fetches the existing post from the database. If no post is found (for example, someone navigates to `/posts/edit/999`), `get_by_id()` returns `null`, and we immediately call `show_404()` to stop execution. If the post exists, it is passed to the view inside `$data['post']` so the form fields can be pre-filled.
- In `update($id)`, we fetch the post again at the top for the same safety reason — to confirm the post still exists before attempting to update it. The validation rules are identical to those in `store()`, because the data requirements for creating and updating a post are the same.
- When `form_validation->run()` returns `FALSE`, we must pass `$data['post'] = $post` to the view along with the title. The view needs the `$post` array to pre-fill the form fields correctly even during a failed validation — without it, the form would render completely empty after a failed submission.
- `$this->Post_model->update($id, $post_data)` calls the `update()` method we defined in Lesson 6, which runs `WHERE id = $id` followed by `UPDATE posts SET ...`. The slug is also regenerated from the new title on every update.
- `$this->session->set_flashdata('success', 'Post updated successfully.')` stores a flash message. After the redirect, the index view will pick it up and display it via `$this->session->flashdata('success')`.
- `redirect('posts')` sends the user back to the post listing page after a successful update.

---

## 3. Create the Edit View

The edit view is nearly identical to the create view. The critical difference is that every form field must be pre-filled with the existing post data when the page first loads.

Create `application/views/posts/edit.php` with the following content.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?php echo $title; ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .card { background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        label { display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9em; }
        input, textarea, select { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; margin-bottom: 4px; }
        .error { color: #dc2626; font-size: 0.8em; margin-bottom: 10px; }
        .form-group { margin-bottom: 14px; }
        .btn-submit { background: #4f46e5; color: #fff; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold; }
        a { color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h1 style="margin:0;"><?php echo $title; ?></h1>
            <a href="<?php echo site_url('posts'); ?>">Back to list</a>
        </div>

        <?php echo form_open('posts/update/' . $post['id']); ?>

            <div class="form-group">
                <label for="title">Title</label>
                <input type="text" name="title" id="title" value="<?php echo set_value('title', $post['title']); ?>">
                <div class="error"><?php echo form_error('title'); ?></div>
            </div>

            <div class="form-group">
                <label for="content">Content</label>
                <textarea name="content" id="content" rows="8"><?php echo set_value('content', $post['content']); ?></textarea>
                <div class="error"><?php echo form_error('content'); ?></div>
            </div>

            <div class="form-group">
                <label for="status">Status</label>
                <select name="status" id="status">
                    <option value="draft" <?php echo set_select('status', 'draft', $post['status'] === 'draft'); ?>>Draft</option>
                    <option value="publish" <?php echo set_select('status', 'publish', $post['status'] === 'publish'); ?>>Publish</option>
                </select>
                <div class="error"><?php echo form_error('status'); ?></div>
            </div>

            <button type="submit" class="btn-submit">Update Post</button>

        <?php echo form_close(); ?>
    </div>
</body>
</html>
```

The key CI3 differences from the create view are:

- `form_open('posts/update/' . $post['id'])` points the form action to the `update()` method with the post ID appended to the URL (e.g., `posts/update/3`). This is how the `update($id)` controller method receives the ID of the post being updated.
- `set_value('title', $post['title'])` accepts a **second argument** — the default value. On the first page load (no validation has run yet), `set_value()` returns this default, which is the post's existing title from the database. After a failed validation, it returns the user's previously submitted value instead until the user corrects the error and the form passes.
- `set_select('status', 'draft', $post['status'] === 'draft')` also accepts a **third argument** — a boolean that determines whether the option should be selected by default on first load. `$post['status'] === 'draft'` evaluates to `TRUE` if the post is currently a draft, making that option pre-selected. After a failed validation, CI3's form helper ignores this third argument and uses the submitted value instead.

---

## 4. Add Route

Open `application/config/routes.php` and add a route for the update action. The `(:num)` wildcard captures the post ID from the URL and passes it to the `update()` method.

```php
$route['posts/update/(:num)'] = 'posts/update/$1';
```

The `$1` placeholder is replaced by the numeric value captured by `(:num)`. So a request to `/posts/update/3` calls `Posts::update(3)`.

---

## 5. Fix the Errors in Your Code

Here are common mistakes when building edit forms in CI3.

**Error 1: Using `set_value()` without a default on the edit form.**
In the create form, `set_value('title')` with no default is fine because the field should start empty. In the edit form, you must provide the existing value as the second argument.

```php
// Wrong: field appears empty on first load
<input value="<?php echo set_value('title'); ?>">

// Correct: pre-fills with existing data on first load
<input value="<?php echo set_value('title', $post['title']); ?>">
```

**Error 2: Form action pointing to `store` instead of `update`.**
If you copy the create view and forget to change `form_open('posts/store')` to `form_open('posts/update/' . $post['id'])`, every submission will create a new post instead of updating the existing one.

```php
// Wrong: creates a new post
<?php echo form_open('posts/store'); ?>

// Correct: updates the existing post
<?php echo form_open('posts/update/' . $post['id']); ?>
```

**Error 3: Not checking if the post exists before loading the edit form.**
If you skip the `show_404()` guard in the `edit()` method, the view will crash with a PHP error when trying to access `$data['post']['title']` on a null value.

```php
// Unsafe: $data['post'] could be null
public function edit($id) {
    $data['post'] = $this->Post_model->get_by_id($id);
    $this->load->view('posts/edit', $data);
}

// Safe: stop execution if post not found
public function edit($id) {
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }
    $data['post'] = $post;
    $this->load->view('posts/edit', $data);
}
```

---

## 6. Exercises

Practice the edit feature with the following tasks.

**Exercise 1:** Test the edit form: change a post's title, submit, and verify the change appears on the listing page and detail page.

**Exercise 2:** Test validation on the edit form: clear the title field, submit, and verify that the error message appears and the content and status fields are preserved.

**Exercise 3:** Add a "Last Updated" display on the show page using the `updated_at` column from the database.

---

## 7. Solutions

Here are the solutions to the exercises above.

**Solution for Exercises 1 and 2:** These are manual testing tasks. Navigate to `/posts/edit/1`, make changes, and submit to verify the behavior.

**Solution for Exercise 3:**

Add the following snippet inside the `.meta` div in `application/views/posts/show.php`:

```php
<?php if ($post['updated_at']): ?>
    <p style="color:#888;">Updated: <?php echo date('d M Y H:i', strtotime($post['updated_at'])); ?></p>
<?php endif; ?>
```

The `updated_at` column is automatically managed by MySQL — it updates to the current timestamp every time the row is modified. The `if` check prevents showing the "Updated" line when the value is `NULL` (which it never should be given our table schema, but it is a safe guard).

---

## Next Up - Lesson 10

The edit form pre-fills with `set_value('field', $default)`. The form action points to `posts/update/$id`. The controller validates, then calls `$this->Post_model->update($id, $data)`. Flash messages confirm the update. The `set_select()` third argument pre-selects the correct dropdown option on first load.

In Lesson 10, you will implement the delete feature to complete the full CRUD cycle.