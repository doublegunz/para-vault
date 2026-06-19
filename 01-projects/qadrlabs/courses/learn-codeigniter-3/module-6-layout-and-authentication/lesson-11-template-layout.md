## 1. Before You Begin

Every view currently has the full HTML structure: doctype, head, body, and styles. If you change the navigation or styling, you must edit every single view file. A **template layout** solves this: a shared header and footer loaded around the main content. CI3 does not have a dedicated template engine — instead, it uses a simple and effective approach of loading multiple views in sequence.

### What You'll Build

You will create header and footer partials and update every controller method to load them around the page-specific content.

### What You'll Learn

- ✅ Creating header and footer partials
- ✅ Loading multiple views in sequence
- ✅ Adding navigation links
- ✅ CI3's approach to templates (simple partials)

### What You'll Need

- Lesson 10 completed

---

## 2. Create Template Partials

In CI3, a "template" is achieved simply by creating partial view files and loading them in order. We will create two partials: `header.php` (everything before the page content) and `footer.php` (everything after it).

First, create the folder `application/views/templates/`. This folder will hold all shared view partials that are not specific to any single controller.

### header.php

Create `application/views/templates/header.php` with the following content.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo isset($title) ? $title : 'CI3 Blog'; ?></title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; color: #333; }
        nav { background: #1e293b; padding: 12px 20px; display: flex; justify-content: space-between; align-items: center; }
        nav a { color: #93c5fd; text-decoration: none; margin-left: 16px; }
        nav a:hover { color: white; }
        .brand { color: white; font-weight: bold; font-size: 1.2em; }
        .container { max-width: 900px; margin: 20px auto; padding: 0 15px; }
        .card { background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .btn { display: inline-block; padding: 6px 14px; border-radius: 4px; text-decoration: none; font-size: 0.85em; font-weight: bold; color: #fff; }
        .btn-primary { background: #2563eb; }
        .btn-info { background: #3b82f6; }
        .btn-warning { background: #f59e0b; }
        .btn-danger { background: #dc2626; }
        .btn-sm { padding: 4px 10px; font-size: 0.8em; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f8f8; text-align: left; padding: 10px; border-bottom: 2px solid #e5e5e5; font-size: 0.8em; text-transform: uppercase; color: #666; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        label { display: block; font-weight: bold; margin-bottom: 4px; font-size: 0.9em; }
        input, textarea, select { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; margin-bottom: 4px; }
        .error { color: #dc2626; font-size: 0.8em; margin-bottom: 10px; }
        .form-group { margin-bottom: 14px; }
        .badge { padding: 2px 8px; border-radius: 10px; font-size: 0.75em; font-weight: bold; }
        .badge-green { background: #d1fae5; color: #065f46; }
        .badge-gray { background: #f3f4f6; color: #374151; }
        .flash-success { background: #d1fae5; border: 1px solid #a7f3d0; color: #065f46; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; }
        .flash-error { background: #fef2f2; border: 1px solid #fca5a5; color: #991b1b; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; }
    </style>
</head>
<body>
    <nav>
        <a href="<?php echo site_url('posts'); ?>" class="brand">CI3 Blog</a>
        <div>
            <a href="<?php echo site_url('posts'); ?>">Posts</a>
            <a href="<?php echo site_url('posts/create'); ?>">Create</a>
        </div>
    </nav>
    <div class="container">
```

Notice that this file intentionally does not close the `<body>` or `<html>` tags, and the `<div class="container">` is left open at the end. The header partial is the opening half of the page — it will be immediately followed by the content view.

The `<?php echo isset($title) ? $title : 'CI3 Blog'; ?>` in the `<title>` tag uses PHP's ternary operator to check whether `$title` exists. If the controller passed a title via `$data['title']`, it will be used. If not, the fallback `'CI3 Blog'` is displayed. Using `isset()` here prevents a PHP notice when the header is loaded before `$title` is defined.

The navigation links use `site_url()` to generate correct URLs tied to the application's base URL, so they work regardless of the server or folder the application is deployed to.

### footer.php

Create `application/views/templates/footer.php` with the following content.

```php
    </div>
    <footer style="text-align:center;padding:20px;color:#999;font-size:0.85em;">
        <p>Copyright 2026 CI3 Blog. Built with CodeIgniter 3.</p>
    </footer>
</body>
</html>
```

This file closes the `<div class="container">` that was opened in `header.php`, then adds the footer, and finally closes `</body>` and `</html>`. Together, the header and footer form a complete HTML document, with the content view in between supplying the page-specific body.

---

## 3. Update the Controller

Now we update each controller method to load three views in sequence: header, content, and footer. In CI3, calling `$this->load->view()` multiple times within a single method will output each view in the order they are called — all concatenated into a single response.

Open `application/controllers/Posts.php` and update the `index()` method as shown below. Apply the same three-view pattern to `show()`, `create()`, and `edit()`.

```php
public function index()
{
    $data['title'] = 'All Posts';
    $data['posts'] = $this->Post_model->get_all();

    $this->load->view('templates/header', $data);
    $this->load->view('posts/index', $data);
    $this->load->view('templates/footer');
}
```

The key CI3 behavior here is that `$this->load->view()` does not immediately send output to the browser — CI3 buffers the output internally and sends everything as a combined response at the end of the request. This is why loading three views sequentially produces a single, coherent HTML page rather than three separate responses.

Notice that `$data` is passed to both `templates/header` and `posts/index`. The header needs `$data` because it reads `$title` to populate the `<title>` tag. The content view also needs `$data` for its own variables (`$posts`, `$post`, etc.). The footer view does not need any variables, so no `$data` is passed.

---

## 4. Simplify the View Files

Now that the header and footer are handled by partials, each content view only needs its page-specific HTML. Remove the full `<!DOCTYPE html>`, `<head>`, `<body>`, and `<html>` tags from every view.

Update `application/views/posts/index.php` to contain only the following.

```php
<div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
        <h1><?php echo $title; ?></h1>
        <a href="<?php echo site_url('posts/create'); ?>" class="btn btn-primary">Create New Post</a>
    </div>

    <?php if ($this->session->flashdata('success')): ?>
        <div class="flash-success"><?php echo $this->session->flashdata('success'); ?></div>
    <?php endif; ?>

    <table>
        <tr><th>No</th><th>Title</th><th>Status</th><th>Actions</th></tr>
        <?php foreach ($posts as $i => $post): ?>
        <tr>
            <td><?php echo $i + 1; ?></td>
            <td><strong><?php echo htmlspecialchars($post['title']); ?></strong></td>
            <td>
                <?php if ($post['status'] === 'publish'): ?>
                    <span class="badge badge-green">Publish</span>
                <?php else: ?>
                    <span class="badge badge-gray">Draft</span>
                <?php endif; ?>
            </td>
            <td>
                <a href="<?php echo site_url('posts/' . $post['id']); ?>" class="btn btn-info btn-sm">View</a>
                <a href="<?php echo site_url('posts/edit/' . $post['id']); ?>" class="btn btn-warning btn-sm">Edit</a>
                <a href="<?php echo site_url('posts/delete/' . $post['id']); ?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this post?')">Delete</a>
            </td>
        </tr>
        <?php endforeach; ?>
    </table>
</div>
```

The CSS classes (`card`, `btn`, `badge-green`, `flash-success`, etc.) that were previously defined inline in each view are now defined once in `header.php`. Every view that is wrapped between the header and footer partials automatically inherits these styles.

Apply the same cleanup to `show.php`, `create.php`, and `edit.php` — remove the opening `<!DOCTYPE html>` through `<body>` and the closing `</body></html>`, keeping only the content `<div>` and its children.

---

## 5. Fix the Errors in Your Code

Here are common mistakes when switching to the template layout pattern.

**Error 1: Forgetting header and footer in one controller method.**
If you update `index()` to use the three-view pattern but forget to update `show()`, visiting a post detail page will show raw, unstyled HTML without the navigation bar.

```php
// Wrong: content view loads alone, no layout
public function show($id) {
    $this->load->view('posts/show', $data);
}

// Correct: always wrap with header and footer
public function show($id) {
    $this->load->view('templates/header', $data);
    $this->load->view('posts/show', $data);
    $this->load->view('templates/footer');
}
```

**Error 2: Passing `$data` to the header but not to the content view.**
Both the header and the content view need `$data`. The header reads `$title`, and the content view reads everything else (`$posts`, `$post`, etc.). Forgetting to pass `$data` to the content view will cause "Undefined variable" PHP notices inside the view.

```php
// Wrong: content view receives no data
$this->load->view('templates/header', $data);
$this->load->view('posts/index');

// Correct: pass $data to all views that need it
$this->load->view('templates/header', $data);
$this->load->view('posts/index', $data);
```

**Error 3: Leaving the full HTML structure in the content view.**
If you forget to remove `<!DOCTYPE html>`, `<head>`, and `<body>` from a content view after switching to the layout pattern, the final HTML output will contain duplicate tags — two `<html>` elements, two `<head>` elements, and nested `<body>` tags. Always strip all wrapper HTML from content views when adopting this pattern.

---

## 6. Exercises

Practice implementing and extending the template system.

**Exercise 1:** Add an "active" CSS class to the current navigation link. Pass a `$active_page` variable from the controller and check it in `header.php` to conditionally apply the active class.

**Exercise 2:** Add a hardcoded "Welcome, Admin" text in the right side of the navbar (we will replace this with a real session-based username in Lesson 12).

**Exercise 3:** Verify that all four views (index, show, create, edit) are fully updated to use the header/footer layout by visiting each URL and confirming the navigation bar appears consistently.

---

## 7. Solutions

Here are the solutions to the exercises above.

**Solution for Exercise 1:**

In the controller, pass the current page identifier:

```php
$data['active_page'] = 'posts';
```

Then in `header.php`, apply the active class conditionally:

```php
<a href="<?php echo site_url('posts'); ?>"
   <?php if (isset($active_page) && $active_page === 'posts') echo 'style="color:white;"'; ?>>
   Posts
</a>
```

Since `$data` is passed to the header view, `$active_page` becomes available as a variable inside it. The `isset()` check prevents a PHP notice if the variable is not set by a particular controller method.

**Solution for Exercise 2:**

In `header.php`, add the text inside the `<nav>` div:

```php
<div>
    <span style="color:#94a3b8;font-size:0.85em;margin-right:10px;">Welcome, Admin</span>
    <a href="<?php echo site_url('posts'); ?>">Posts</a>
    <a href="<?php echo site_url('posts/create'); ?>">Create</a>
</div>
```

This will be replaced with a real session check in Lesson 12.

**Solution for Exercise 3:** This is a manual verification task. Visit `/posts`, `/posts/1`, `/posts/create`, and `/posts/edit/1` and confirm that the navigation bar and footer appear on all pages.

---

## Next Up - Lesson 12

Template partials eliminate HTML duplication. Load header, content, then footer in sequence using `$this->load->view()`. CI3 buffers multiple view calls and sends them as a single combined response. The header contains the doctype, navigation, and global CSS. Content views contain only the page-specific HTML.

In Lesson 12, you will add simple authentication: login, logout, and page protection using CI3 sessions.