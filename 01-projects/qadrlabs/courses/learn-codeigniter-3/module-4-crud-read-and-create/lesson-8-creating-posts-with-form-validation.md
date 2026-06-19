## 1. Before You Begin

The blog can display posts. Now users need to create new posts through a form. CI3's `form_validation` library provides server-side validation with rules like `required`, `min_length`, and `max_length`. Flash messages confirm the operation.

### What You'll Build

You will create the post creation form with validation, slug generation, and flash messages.

### What You'll Learn

- ✅ Loading the `form_validation` library
- ✅ Setting validation rules with `set_rules()`
- ✅ `$this->form_validation->run()` to check input
- ✅ Displaying validation errors with `validation_errors()` and `form_error()`
- ✅ Flash messages with `$this->session->set_flashdata()`
- ✅ `form_open()` and `form_close()` helpers
- ✅ Repopulating form fields with `set_value()`

### What You'll Need

- Lesson 7 completed

---

## 2. Add the Slug Helper to the Model

Before building the form, we need a way to automatically generate a URL-friendly slug from the post title. Instead of requiring the user to type the slug manually, the model will generate it from the title on every create and update.

Open `application/models/Post_model.php` and add the following method inside the class.

```php
public function generate_slug($title)
{
    $slug = url_title($title, 'dash', TRUE);
    return $slug;
}
```

`url_title()` is a CI3 URL helper function. It takes three arguments: the string to convert, the word separator (`'dash'` produces hyphens), and a boolean to force lowercase. So a title like `"My First Post"` becomes `"my-first-post"`. This function is provided by the URL helper, which must be loaded. Verify that `autoload.php` includes it:

```php
$autoload['helper'] = array('url', 'form');
```

If `'url'` is already in this array, no further action is needed.

---

## 3. Add Controller Methods

The create form requires two controller methods: one to display the empty form (`create`), and one to process and save the submission (`store`). This pattern — one method to show, one to handle — is a common convention in CI3 applications.

Open `application/controllers/Posts.php` and add the following two methods inside the class.

```php
public function create()
{
    $data['title'] = 'Create Post';
    $this->load->view('posts/create', $data);
}

public function store()
{
    $this->load->library('form_validation');

    $this->form_validation->set_rules('title', 'Title', 'required|max_length[255]');
    $this->form_validation->set_rules('content', 'Content', 'required');
    $this->form_validation->set_rules('status', 'Status', 'required|in_list[draft,publish]');

    if ($this->form_validation->run() === FALSE) {
        $data['title'] = 'Create Post';
        $this->load->view('posts/create', $data);
        return;
    }

    $post_data = [
        'title'   => $this->input->post('title'),
        'slug'    => $this->Post_model->generate_slug($this->input->post('title')),
        'content' => $this->input->post('content'),
        'status'  => $this->input->post('status'),
    ];

    $this->Post_model->create($post_data);
    $this->session->set_flashdata('success', 'Post created successfully.');
    redirect('posts');
}
```

Here is a detailed walkthrough of the CI3-specific parts:

- `$this->load->library('form_validation')` loads CI3's built-in form validation library and makes it available as `$this->form_validation`. This can also be done in `autoload.php` if you need it on every page, but loading it only in the methods that need it is a cleaner practice.
- `$this->form_validation->set_rules('title', 'Title', 'required|max_length[255]')` registers a validation rule for the field named `title`. The three arguments are: the field name (must match the HTML input `name` attribute), a human-readable label used in error messages, and a pipe-separated list of rules. `required` means the field cannot be empty. `max_length[255]` means the value cannot exceed 255 characters. `in_list[draft,publish]` on the status field means the submitted value must be either `draft` or `publish` — anything else (including an empty selection) fails validation.
- `$this->form_validation->run()` runs all the registered rules against the submitted POST data. It returns `TRUE` if all rules pass, or `FALSE` if any rule fails. When it returns `FALSE`, we reload the create view instead of redirecting, so CI3 can preserve the validation state and error messages.
- `$this->input->post('title')` is CI3's safe way to read POST data. It is equivalent to `$_POST['title']` but with additional XSS filtering applied automatically. Never read from `$_POST` directly in a CI3 application.
- `$this->session->set_flashdata('success', 'Post created successfully.')` stores a temporary message in the session. This message will be available for exactly one subsequent request, after which CI3 removes it. We display it in the index view using `$this->session->flashdata('success')`.
- `redirect('posts')` is a CI3 URL helper function that sends an HTTP redirect response to the client, pointing it to the `/posts` URL. After a successful form submission, always redirect rather than loading a view directly — this prevents duplicate submissions if the user refreshes the page.

---

## 4. Create the Form View

Now we create the HTML form view. Create a new file at `application/views/posts/create.php` and write the following content.

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
        .btn-submit { background: #2563eb; color: #fff; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold; }
        a { color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h1 style="margin:0;"><?php echo $title; ?></h1>
            <a href="<?php echo site_url('posts'); ?>">Back to list</a>
        </div>

        <?php echo form_open('posts/store'); ?>

            <div class="form-group">
                <label for="title">Title</label>
                <input type="text" name="title" id="title" value="<?php echo set_value('title'); ?>">
                <div class="error"><?php echo form_error('title'); ?></div>
            </div>

            <div class="form-group">
                <label for="content">Content</label>
                <textarea name="content" id="content" rows="8"><?php echo set_value('content'); ?></textarea>
                <div class="error"><?php echo form_error('content'); ?></div>
            </div>

            <div class="form-group">
                <label for="status">Status</label>
                <select name="status" id="status">
                    <option value="">Select status</option>
                    <option value="draft" <?php echo set_select('status', 'draft'); ?>>Draft</option>
                    <option value="publish" <?php echo set_select('status', 'publish'); ?>>Publish</option>
                </select>
                <div class="error"><?php echo form_error('status'); ?></div>
            </div>

            <button type="submit" class="btn-submit">Create Post</button>

        <?php echo form_close(); ?>
    </div>
</body>
</html>
```

There are several CI3 form helper functions in this view that are worth understanding:

- `form_open('posts/store')` generates a complete `<form>` opening tag with the `action` attribute pointing to `site_url('posts/store')` and `method="post"` by default. It also automatically adds a hidden CSRF token field if CSRF protection is enabled in CI3's configuration.
- `set_value('title')` reads back the value the user previously typed in the `title` field after a failed validation. On the very first page load (before any submission), it returns an empty string. After a failed validation, it returns the previously submitted value so the user does not have to retype everything. This is called "repopulating" the form.
- `form_error('title')` outputs the validation error message for a specific field after a failed submission. If the `title` field failed validation, it outputs something like "The Title field is required." If the field passed, it outputs an empty string.
- `set_select('status', 'draft')` is the dropdown equivalent of `set_value()`. It outputs the HTML attribute `selected="selected"` if `'draft'` was the previously submitted value, which re-selects the correct option after a failed validation.
- `form_close()` generates the closing `</form>` tag. Using it instead of a plain `</form>` tag is a CI3 convention for consistency with `form_open()`.

---

## 5. Add Route

Open `application/config/routes.php` and make sure the route for `posts/create` appears before any wildcard route that could match it, such as `posts/(:num)`. Route order matters in CI3 — the framework evaluates routes from top to bottom and uses the first match.

```php
$route['posts/create'] = 'posts/create';
$route['posts/(:num)'] = 'posts/show/$1';
```

If `posts/(:num)` appeared first, a request to `/posts/create` would not match it (since `create` is not a number), so in this specific case the wildcard would not interfere. However, if you used `(:any)` instead of `(:num)`, the wildcard would catch `/posts/create` before the explicit route. Keeping specific routes above wildcards is a safe habit regardless.

---

## 6. Test

Visit `http://localhost/ci3-blog/posts/create` to open the form.

Submit the form while leaving fields empty — validation errors should appear inline below each field, and the previously entered values in other fields should be preserved.

Fill in all fields with valid data and submit — you should be redirected to the post listing page with a green flash message confirming the post was created.

---

## 7. Fix the Errors in Your Code

Here are common errors when working with CI3 form validation.

**Error 1: `form_validation` library not loaded.**
Calling `$this->form_validation->set_rules()` without first loading the library will throw an error because the property does not exist on `$this`.

```php
// Wrong: library never loaded
$this->form_validation->set_rules('title', 'Title', 'required');

// Correct: load first
$this->load->library('form_validation');
$this->form_validation->set_rules('title', 'Title', 'required');
```

**Error 2: `redirect()` not working.**
If `redirect('posts')` does nothing or throws an error, it means the URL helper is not loaded. `redirect()` is a URL helper function, not a built-in PHP function. Ensure `'url'` is in your `autoload.php` helpers array.

```php
$autoload['helper'] = array('url', 'form');
```

**Error 3: `set_value()` returns empty on first load.**
This is expected and correct behavior. `set_value()` only returns a value after a failed form submission. On the initial page load, it returns an empty string because no data has been submitted yet.

---

## 8. Exercises

Practice what you have learned with the following exercises.

**Exercise 1:** Add a `min_length[5]` rule to the title field. Test by submitting a title shorter than 5 characters and observe the error message.

**Exercise 2:** Add a character counter below the content textarea that shows how many characters the user has already typed, displayed only after a failed validation using `set_value('content')`.

**Exercise 3:** At the top of the form, add a summary error box that displays all validation errors at once using CI3's `validation_errors()` function.

---

## 9. Solutions

Here are the solutions to the exercises above.

**Solution for Exercise 1:**

```php
$this->form_validation->set_rules('title', 'Title', 'required|min_length[5]|max_length[255]');
```

Multiple rules are separated by a pipe (`|`). CI3 evaluates them in order from left to right and stops at the first failure for that field.

**Solution for Exercise 2:**

Add this below the `<textarea>` tag in the view:

```php
<?php if (set_value('content')): ?>
    <small><?php echo strlen(set_value('content')); ?> characters</small>
<?php endif; ?>
```

`set_value('content')` will only be non-empty after a failed submission, so this block is skipped on the initial page load. `strlen()` counts the character length of the repopulated content.

**Solution for Exercise 3:**

Add this directly below `form_open()`, before the first form group:

```php
<?php if (validation_errors()): ?>
    <div class="error" style="background:#fef2f2;padding:10px;border-radius:4px;">
        <?php echo validation_errors(); ?>
    </div>
<?php endif; ?>
```

`validation_errors()` returns all validation error messages combined into a single HTML string. It returns an empty string when there are no errors, so the wrapping `if` check prevents an empty box from being rendered on a clean page load.

---

## Next Up - Lesson 9

CI3's `form_validation` library validates input with rules like `required`, `min_length`, `max_length`, and `in_list`. `set_value()` repopulates fields after failed validation. `form_error()` shows per-field errors. `set_flashdata()` passes messages across redirects. `form_open()` generates the form tag with the correct action URL and CSRF token.

In Lesson 9, you will build the edit form for updating existing posts.