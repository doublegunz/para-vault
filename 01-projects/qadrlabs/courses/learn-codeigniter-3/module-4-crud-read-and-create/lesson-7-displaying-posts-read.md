## 1. Before You Begin

The model and controller are in place. Now we need proper views: a post listing page with a styled table, status badges, and action links, plus a detail page for viewing a single post. This completes the Read operation of CRUD.

### What You'll Build

You will create styled index and show views that display data from the database.

### What You'll Learn

- ✅ Displaying lists with PHP foreach in views
- ✅ `site_url()` and `base_url()` for generating URLs
- ✅ Conditional display with PHP if/else in views
- ✅ Formatting dates with PHP
- ✅ Flash messages display (preparation for Create)

### What You'll Need

- Lesson 6 completed with Post_model working

---

## 2. Update the Index View

The index view is the main listing page that shows all posts in a table. We are going to upgrade it from the bare HTML created in Lesson 3 to a properly styled version with status badges, formatted dates, and action buttons.

Open `application/views/posts/index.php` and replace its entire content with the following.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $title; ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .card { background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .btn { display: inline-block; padding: 6px 14px; border-radius: 4px; text-decoration: none; font-size: 0.85em; font-weight: bold; color: #fff; }
        .btn-primary { background: #2563eb; }
        .btn-info { background: #3b82f6; }
        .btn-warning { background: #f59e0b; }
        .btn-danger { background: #dc2626; }
        .btn-sm { padding: 4px 10px; font-size: 0.8em; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f8f8; text-align: left; padding: 10px; border-bottom: 2px solid #e5e5e5; font-size: 0.8em; text-transform: uppercase; color: #666; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        .badge { padding: 2px 8px; border-radius: 10px; font-size: 0.75em; font-weight: bold; }
        .badge-green { background: #d1fae5; color: #065f46; }
        .badge-gray { background: #f3f4f6; color: #374151; }
        .flash-success { background: #d1fae5; border: 1px solid #a7f3d0; color: #065f46; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <h1><?php echo $title; ?></h1>
            <a href="<?php echo site_url('posts/create'); ?>" class="btn btn-primary">Create New Post</a>
        </div>

        <?php if ($this->session->flashdata('success')): ?>
            <div class="flash-success"><?php echo $this->session->flashdata('success'); ?></div>
        <?php endif; ?>

        <table>
            <tr>
                <th>No</th>
                <th>Title</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
            </tr>
            <?php if (empty($posts)): ?>
                <tr><td colspan="5" style="text-align:center;color:#999;padding:30px;">No posts found.</td></tr>
            <?php else: ?>
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
                    <td style="color:#888;font-size:0.85em;"><?php echo date('d M Y', strtotime($post['created_at'])); ?></td>
                    <td>
                        <a href="<?php echo site_url('posts/' . $post['id']); ?>" class="btn btn-info btn-sm">View</a>
                        <a href="<?php echo site_url('posts/edit/' . $post['id']); ?>" class="btn btn-warning btn-sm">Edit</a>
                        <a href="<?php echo site_url('posts/delete/' . $post['id']); ?>" class="btn btn-danger btn-sm" onclick="return confirm('Delete this post?')">Delete</a>
                    </td>
                </tr>
                <?php endforeach; ?>
            <?php endif; ?>
        </table>
    </div>
</body>
</html>
```

There are several CI3-specific patterns in this view worth understanding:

- `$this->session->flashdata('success')` reads a flash message stored in the session under the key `'success'`. Flash messages in CI3 are temporary values that survive exactly one redirect and then disappear automatically. We will set them in Lesson 8 after a successful form submission. If no flash message exists, this returns `null` and the block is skipped entirely.
- `site_url('posts/create')` is CI3's URL helper function. It generates a full URL by combining the `base_url` from `config.php` with the path you provide. Always use `site_url()` for links that point to controller methods — it ensures the correct base URL is used regardless of which server the application runs on.
- `$this->session->flashdata()` is only available in views because CI3 makes the `$this` object (the controller instance) accessible inside every loaded view. This is one of CI3's design choices that differs from other frameworks.
- `htmlspecialchars($post['title'])` converts characters like `<`, `>`, and `&` into safe HTML entities. This is essential to prevent XSS (Cross-Site Scripting) attacks — always apply it to any value that comes from the database or user input before rendering it as HTML.
- `date('d M Y', strtotime($post['created_at']))` formats the raw datetime string stored in MySQL (e.g., `2024-01-15 10:30:00`) into a readable format like `15 Jan 2024`. This is plain PHP — no CI3 involvement here.
- The PHP alternative syntax (`foreach ... endforeach`, `if ... endif`) is preferred in views. It is functionally identical to the curly-brace syntax but much easier to read when HTML is mixed between the PHP tags.

Save and test at `http://localhost/ci3-blog/posts`.

---

## 3. Update the Show View

The show view displays a single post in full detail. Open `application/views/posts/show.php` and replace its entire content with the following.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?php echo htmlspecialchars($post['title']); ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .card { background: #fff; padding: 25px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        a { color: #2563eb; text-decoration: none; }
        .meta { color: #888; font-size: 0.85em; margin-bottom: 16px; }
        .badge { padding: 2px 8px; border-radius: 10px; font-size: 0.75em; font-weight: bold; }
        .badge-green { background: #d1fae5; color: #065f46; }
        .badge-gray { background: #f3f4f6; color: #374151; }
        .content { white-space: pre-wrap; line-height: 1.7; }
    </style>
</head>
<body>
    <div class="card">
        <p><a href="<?php echo site_url('posts'); ?>">&larr; Back to list</a></p>
        <h1><?php echo htmlspecialchars($post['title']); ?></h1>
        <div class="meta">
            <?php echo $post['slug']; ?> |
            <?php if ($post['status'] === 'publish'): ?>
                <span class="badge badge-green">Publish</span>
            <?php else: ?>
                <span class="badge badge-gray">Draft</span>
            <?php endif; ?>
            | <?php echo date('d M Y H:i', strtotime($post['created_at'])); ?>
        </div>
        <div class="content"><?php echo htmlspecialchars($post['content']); ?></div>
    </div>
</body>
</html>
```

The key CI3-related point here is that `$post` is the single associative array returned by `Post_model::get_by_id()` via `row_array()`. Every key in that array — `title`, `slug`, `status`, `content`, `created_at` — corresponds directly to a column in the `posts` database table. `site_url('posts')` generates the link back to the listing page using CI3's URL helper.

Save and test at `http://localhost/ci3-blog/posts/1`.

---

## 4. Fix the Errors in Your Code

Here are common mistakes when building views and how to correct them.

**Error 1: Missing `htmlspecialchars()`.**
Never echo database values directly without sanitizing them. Without `htmlspecialchars()`, a post title containing `<script>alert('hacked')</script>` would execute as JavaScript in the browser.

```php
// Unsafe
<td><?php echo $post['title']; ?></td>

// Safe
<td><?php echo htmlspecialchars($post['title']); ?></td>
```

Always wrap any value that originates from user input or the database with `htmlspecialchars()` before rendering it as HTML output.

**Error 2: Confusing `site_url()` with `base_url()`.**
Both are CI3 URL helper functions, but they serve different purposes:

- `site_url('posts/1')` routes through CI3's front controller. Use this for links to controllers and methods.
- `base_url('assets/css/style.css')` simply appends a path to the base domain. Use this for static assets like CSS, images, or JavaScript files.

For controller URLs, always use `site_url()`.

**Error 3: Accessing an undefined array key.**
If you try to echo a column that does not exist in the `$post` array — for example, if you added a new column to the table but did not update the query — PHP will generate a notice.

```php
// Causes a PHP notice if 'author' column doesn't exist
<?php echo $post['author']; ?>

// Safe approach
<?php echo isset($post['author']) ? htmlspecialchars($post['author']) : 'Unknown'; ?>
```

---

## 5. Exercises

Practice the concepts from this lesson with the following tasks.

**Exercise 1:** Add a "Slug" column to the index table so the slug of each post is visible in the listing.

**Exercise 2:** Add "Edit" and "Delete" action links to the show page, below the post content (they will not work yet — that comes in later lessons).

**Exercise 3:** Add a post count display below the table that reads "Showing X posts", using PHP's `count()` function on the `$posts` array.

---

## 6. Solutions

Here are the solutions to the exercises above.

**Solution for Exercise 1:**

Add `<th>Slug</th>` to the header row, then add the cell inside the `foreach` loop:

```php
<td><?php echo htmlspecialchars($post['slug']); ?></td>
```

The slug is already available in `$post` because `Post_model::get_all()` runs `SELECT *`, fetching all columns including `slug`.

**Solution for Exercise 2:**

Add the following links to the show view:

```php
<a href="<?php echo site_url('posts/edit/' . $post['id']); ?>">Edit</a>
<a href="<?php echo site_url('posts/delete/' . $post['id']); ?>">Delete</a>
```

These will return a 404 for now because the `edit()` and `delete()` controller methods do not exist yet. They will be implemented in Lessons 9 and 10.

**Solution for Exercise 3:**

Add the following below the closing `</table>` tag:

```php
<p style="color:#888;margin-top:10px;">Showing <?php echo count($posts); ?> posts</p>
```

`count($posts)` returns the number of elements in the `$posts` array. This is a fast PHP operation — the data is already in memory from the model query, so no extra database call is made.

---

## Next Up - Lesson 8

Views display data passed from the controller. Use `site_url()` for controller URLs and `base_url()` for static assets. Use `htmlspecialchars()` for all database values rendered as HTML. Flash messages display with `$this->session->flashdata()`. PHP alternative syntax (`if/endif`, `foreach/endforeach`) makes views readable.

In Lesson 8, you will build the create form with form validation and flash messages.