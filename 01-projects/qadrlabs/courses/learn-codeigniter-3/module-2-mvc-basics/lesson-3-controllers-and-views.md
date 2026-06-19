## 1. Before You Begin

In CodeIgniter 3, the **controller** receives the URL request and decides what to do. The **view** displays HTML. The controller loads the view and passes data to it. This lesson teaches the fundamental pattern you will use in every CI3 application.

### What You'll Build

You will create a Posts controller, load views, and pass data from the controller to the view.

### What You'll Learn

- ✅ Creating a controller class that extends `CI_Controller`
- ✅ Loading views with `$this->load->view()`
- ✅ Passing data to views with the `$data` array
- ✅ Displaying data in views with PHP echo
- ✅ The controller-view request flow

### What You'll Need

- CI3 installed from Lesson 2
- Laragon running

---

## 2. Setup

Open the `ci3-blog` project in VS Code. Make sure Laragon is running so we can test in the browser as we build.

---

## 3. Create the Posts Controller

Let's create our first controller to handle blog posts.

### Step 1: Create the File

Inside `application/controllers/`, create a new file named `Posts.php`. The filename must begin with an uppercase letter — this is a strict rule in CI3. If you name the file `posts.php` (lowercase), CI3 will not be able to find the controller.

> **Important:** In CI3, the controller filename must start with an uppercase letter: `Posts.php`, not `posts.php`.

### Step 2: Write the Code

Open the file and write the following controller class. For now, the post data is hardcoded in the controller. In Lesson 6 we will replace this with real data from the database.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Posts extends CI_Controller {

    public function index()
    {
        $data['title'] = 'All Posts';
        $data['posts'] = [
            ['id' => 1, 'title' => 'First Post', 'status' => 'publish'],
            ['id' => 2, 'title' => 'Second Post', 'status' => 'draft'],
            ['id' => 3, 'title' => 'Third Post', 'status' => 'publish'],
        ];

        $this->load->view('posts/index', $data);
    }

    public function show($id)
    {
        $data['title'] = 'Post Detail';
        $data['post'] = [
            'id'      => $id,
            'title'   => 'Sample Post ' . $id,
            'content' => 'This is the content of post ' . $id . '.',
            'status'  => 'publish',
        ];

        $this->load->view('posts/show', $data);
    }
}
```

Let's break down the key parts of this code:

- `defined('BASEPATH') OR exit(...)` is a security check present in every CI3 file. It prevents the file from being accessed directly via the browser, ensuring it is always executed through CI3's front controller (`index.php`).
- `class Posts extends CI_Controller` defines a controller class. The name `Posts` must match the filename `Posts.php`. By extending `CI_Controller`, this class inherits all of CI3's built-in features such as `$this->load`, `$this->db`, and `$this->session`.
- The `index()` method responds to requests for `/posts`. It prepares a `$data` array where each key will become a variable inside the view. `$data['title']` will be available as `$title`, and `$data['posts']` will be available as `$posts`.
- `$this->load->view('posts/index', $data)` tells CI3 to render the view file at `application/views/posts/index.php` and pass the `$data` array to it.
- The `show($id)` method responds to requests like `/posts/show/1`. The `$id` parameter is taken directly from the third URL segment.

### Step 3: Save the File

Press **Ctrl+S** to save the controller file.

---

## 4. Create the Views

Now we will create the views to display the data provided by the controller.

### Step 1: Create the Folder

Inside `application/views/`, create a subfolder named `posts/`. Organizing views by controller name keeps the application tidy and makes it easy to know which view belongs to which controller.

### Step 2: Create the Index View

Inside `application/views/posts/`, create a new file named `index.php`. This view will display all posts in a table.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $title; ?></title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 20px auto; padding: 0 15px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #f5f5f5; }
        a { color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <h1><?php echo $title; ?></h1>

    <table>
        <tr>
            <th>No</th>
            <th>Title</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
        <?php foreach ($posts as $i => $post): ?>
        <tr>
            <td><?php echo $i + 1; ?></td>
            <td><?php echo htmlspecialchars($post['title']); ?></td>
            <td><?php echo $post['status']; ?></td>
            <td><a href="<?php echo site_url('posts/show/' . $post['id']); ?>">View</a></td>
        </tr>
        <?php endforeach; ?>
    </table>
</body>
</html>
```

A few things to note about this view:

- `<?php echo $title; ?>` outputs the `$title` variable, which was passed from the controller via `$data['title']`. CI3 automatically extracts the `$data` array so each key becomes a standalone variable.
- `htmlspecialchars($post['title'])` converts HTML special characters (like `<`, `>`, `&`) into safe HTML entities. This is a critical security practice that prevents **Cross-Site Scripting (XSS)** attacks — always use it when displaying user-supplied data.
- `site_url('posts/show/' . $post['id'])` uses the URL helper to generate a full, correct URL for the detail page. It automatically includes the base URL and any configured prefixes.
- `<?php foreach ($posts as $i => $post): ?>` iterates over the `$posts` array. The `$i` variable holds the current index (starting at 0), and `$post` holds the current row as an associative array.

### Step 3: Create the Show View

Inside `application/views/posts/`, create a second file named `show.php`. This view will display a single post's details.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><?php echo htmlspecialchars($post['title']); ?></title>
    <style>body { font-family: Arial, sans-serif; max-width: 700px; margin: 20px auto; padding: 0 15px; } a { color: #2563eb; }</style>
</head>
<body>
    <p><a href="<?php echo site_url('posts'); ?>">&larr; Back to list</a></p>
    <h1><?php echo htmlspecialchars($post['title']); ?></h1>
    <p>Status: <strong><?php echo $post['status']; ?></strong></p>
    <p><?php echo htmlspecialchars($post['content']); ?></p>
</body>
</html>
```

Here, `$post` is the single post array passed from the controller's `show()` method. Notice how `site_url('posts')` generates a link back to the post listing page, and `&larr;` renders a left-arrow HTML entity for the "Back" link. Again, `htmlspecialchars()` is used on every piece of data before it is echoed.

### Step 4: Save and Test

Save all files. Then open your browser and test the following URLs:

- `http://localhost/ci3-blog/posts` - post listing
- `http://localhost/ci3-blog/posts/show/1` - post detail

---

## 5. How It Works

Let's examine precisely how CI3 maps a URL to a controller method.

```text
posts  → Posts controller (application/controllers/Posts.php)
show   → show() method
1      → $id parameter
```

CI3 uses **URL segments**: `controller/method/parameter`. The controller class name must match the first segment (case-insensitive for URLs, but the file must be uppercase). So the URL `http://localhost/ci3-blog/posts/show/1` breaks down as: segment 1 is `posts` (maps to `Posts.php`), segment 2 is `show` (maps to the `show()` method), and segment 3 is `1` (passed as the `$id` argument).

`$this->load->view('posts/index', $data)` loads the file at `application/views/posts/index.php`. The `$data` array is extracted automatically by CI3, so `$data['title']` becomes `$title` in the view, `$data['posts']` becomes `$posts`, and so on.

`site_url('posts/show/1')` uses the base URL from `config.php` to generate the full URL `http://localhost/ci3-blog/posts/show/1`. This means you never hardcode URLs in your templates — if you move the application to a different server, the links update automatically.

---

## 6. Fix the Errors in Your Code

Here are some common mistakes when working with controllers and views, along with how to resolve them.

**Error 1: Uppercase filename.**
CI3 requires controller files to start with an uppercase letter. For example, use `Posts.php`, not `posts.php`.

**Error 2: Class name mismatch.**
The class name must match the filename exactly. If the file is `Posts.php`, the class must be `Posts`.

```php
class Posts extends CI_Controller { }
```

If the class is named `Post` (singular) but the file is `Posts.php`, CI3 will throw an error because it expects the class name to match the filename. This is a common mistake when you rename a file without updating the class name inside it.

**Error 3: View path mismatch.**
Ensure the path used in `$this->load->view()` matches the actual folder and filename in the `application/views/` directory.

```php
// If the file is at application/views/posts/index.php
$this->load->view('posts/index');
```

If you accidentally call `$this->load->view('post/index')` (singular `post`), CI3 will throw a "Unable to load the requested file" error, because it will look for `application/views/post/index.php` which does not exist.

---

## 7. Exercises

Practice what you have learned with the following exercises.

**Exercise 1:** Create a `Pages` controller with methods `about()` and `contact()`. Each loads a view from `views/pages/`. Add basic content to each view. Test at `/pages/about` and `/pages/contact`.

**Exercise 2:** In the `Posts` controller, add a method `create()` that loads a view with an empty form (just HTML, no processing yet). Test at `/posts/create`.

**Exercise 3:** Modify the `show()` method to display "Post not found" if `$id` is greater than 3 (since we only have 3 hardcoded posts).

---

## 8. Solutions

Here are the solutions to the exercises provided above.

**Solution for Exercise 1:**

`application/controllers/Pages.php`:

```php
<?php
class Pages extends CI_Controller {
    public function about() {
        $data['title'] = 'About Us';
        $this->load->view('pages/about', $data);
    }
    public function contact() {
        $data['title'] = 'Contact';
        $this->load->view('pages/contact', $data);
    }
}
```

This controller follows the exact same pattern as `Posts.php`. Each method prepares a `$data` array and loads its corresponding view. Remember to also create the view files at `application/views/pages/about.php` and `application/views/pages/contact.php`.

**Solution for Exercise 2:** Add to `Posts.php`:

```php
public function create() {
    $data['title'] = 'Create Post';
    $this->load->view('posts/create', $data);
}
```

This method simply loads a view — no form processing yet. The actual form handling with validation will be implemented in Lesson 8.

**Solution for Exercise 3:**

```php
public function show($id) {
    if ($id > 3) {
        show_404();
        return;
    }
    $data['title'] = 'Post Detail';
    $data['post'] = [
        'id'      => $id,
        'title'   => 'Sample Post ' . $id,
        'content' => 'This is the content of post ' . $id . '.',
        'status'  => 'publish',
    ];
    $this->load->view('posts/show', $data);
}
```

The guard `if ($id > 3)` is placed at the very top of the method so execution stops immediately when an out-of-range ID is detected. `show_404()` is a CI3 global function that renders the default 404 error page and halts the response — the rest of the method body is never reached. The explicit `return` after `show_404()` is a defensive coding habit: on the rare chance a custom 404 handler does not terminate execution, `return` ensures the method exits cleanly.

---

## Next Up - Lesson 4

Controllers extend `CI_Controller`. Methods map to URL segments. `$this->load->view('path', $data)` loads a view and passes data. The `$data` array keys become variables in the view. `site_url()` generates URLs. Always use `htmlspecialchars()` when displaying user data.

In Lesson 4, you will learn about routing and URL structure.