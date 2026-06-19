## 1. Before You Begin

In MVC, the **model** handles all database operations. Instead of writing queries directly in the controller, you create a model class with methods like `get_all()`, `get_by_id()`, `create()`, `update()`, and `delete()`. CI3's **Query Builder** lets you construct SQL queries using PHP methods instead of raw SQL strings, which keeps your code readable, database-agnostic, and protected against SQL injection by default.

### What You'll Build

You will create `Post_model` with all CRUD methods using Query Builder, then update the `Posts` controller to use it.

### What You'll Learn

- ✅ Creating a model that extends `CI_Model`
- ✅ Loading models in controllers
- ✅ Query Builder: `get()`, `get_where()`, `insert()`, `update()`, `delete()`
- ✅ `where()`, `order_by()`, `limit()` for filtering
- ✅ `result()` vs `result_array()` vs `row()` vs `row_array()`

### What You'll Need

- Database configured from Lesson 5

---

## 2. Create the Post Model

A model is a PHP class that lives in `application/models/`. Its sole responsibility is to talk to the database — nothing more. By centralizing all SQL queries inside the model, your controllers stay clean and your database logic is reusable across multiple controllers if needed.

### Step 1: Create the File

Inside `application/models/`, create a new file named `Post_model.php`. Just like controllers, the filename must start with an uppercase letter. CI3 uses the filename to locate and load the class, so the name must match exactly.

### Step 2: Write the Code

Open the file and write the complete `Post_model` class with methods for every CRUD operation.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Post_model extends CI_Model {

    private $table = 'posts';

    public function get_all()
    {
        return $this->db
            ->order_by('created_at', 'DESC')
            ->get($this->table)
            ->result_array();
    }

    public function get_by_id($id)
    {
        return $this->db
            ->get_where($this->table, ['id' => $id])
            ->row_array();
    }

    public function create($data)
    {
        $this->db->insert($this->table, $data);
        return $this->db->insert_id();
    }

    public function update($id, $data)
    {
        return $this->db
            ->where('id', $id)
            ->update($this->table, $data);
    }

    public function delete($id)
    {
        return $this->db
            ->where('id', $id)
            ->delete($this->table);
    }

    public function count_all()
    {
        return $this->db->count_all($this->table);
    }

    public function get_by_status($status)
    {
        return $this->db
            ->where('status', $status)
            ->order_by('created_at', 'DESC')
            ->get($this->table)
            ->result_array();
    }
}
```

Let's walk through each part of this class:

- `class Post_model extends CI_Model` defines the model. Extending `CI_Model` gives it access to `$this->db` (the Query Builder) and all other CI3 features. The naming convention in CI3 for models is `Tablename_model` — so for the `posts` table, the model is named `Post_model`.
- `private $table = 'posts'` stores the table name in a property. Instead of typing the string `'posts'` in every method, we reference `$this->table`. If the table name ever changes, you only need to update it in one place.
- **`get_all()`** chains `order_by('created_at', 'DESC')` before calling `get()`, so the most recently published posts appear first. It calls `result_array()` to return the rows as an array of associative arrays.
- **`get_by_id($id)`** uses `get_where()`, which is a shorthand for `WHERE id = $id`. It calls `row_array()` because we expect exactly one row — a single post by its ID.
- **`create($data)`** passes an associative array to `insert()`. CI3's Query Builder automatically generates the `INSERT INTO` statement and escapes all values to prevent SQL injection. `insert_id()` returns the auto-incremented `id` of the newly created row.
- **`update($id, $data)`** chains `where('id', $id)` before calling `update()`. This is critical — calling `update()` without a `where()` clause would update every single row in the table.
- **`delete($id)`** follows the same pattern: `where()` before `delete()` to target only the specific post.
- **`count_all()`** runs `SELECT COUNT(*) FROM posts` and returns the total number of rows as an integer.
- **`get_by_status($status)`** demonstrates filtering. By chaining `where('status', $status)` before `get()`, CI3 adds a `WHERE status = ?` clause to the SQL query.

### Step 3: Save the File

Press **Ctrl+S** to save the model file.

---

## 3. Use the Model in the Controller

Now that the model is ready, we need to update the `Posts` controller to load and use it. This replaces all the hardcoded dummy data from Lesson 3 with real data from the database.

### Step 1: Update Posts Controller

Open `application/controllers/Posts.php` and replace its entire contents with the following.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Posts extends CI_Controller {

    public function __construct()
    {
        parent::__construct();
        $this->load->model('Post_model');
    }

    public function index()
    {
        $data['title'] = 'All Posts';
        $data['posts'] = $this->Post_model->get_all();
        $this->load->view('posts/index', $data);
    }

    public function show($id)
    {
        $post = $this->Post_model->get_by_id($id);

        if (!$post) {
            show_404();
            return;
        }

        $data['title'] = $post['title'];
        $data['post'] = $post;
        $this->load->view('posts/show', $data);
    }
}
```

Here is a detailed explanation of the important changes:

- `public function __construct()` is a PHP constructor that runs automatically every time the controller is instantiated — that is, on every request handled by this controller. By placing model loading inside the constructor, we ensure the model is always available without having to call `$this->load->model()` inside every single method.
- `parent::__construct()` must be called first inside the constructor. This calls CI3's own constructor, which sets up `$this->db`, `$this->session`, and all other auto-loaded components. Skipping this call would break the entire CI3 framework initialization.
- `$this->load->model('Post_model')` tells CI3 to find `application/models/Post_model.php`, instantiate the `Post_model` class, and assign it to `$this->Post_model`. After this line, every method in the controller can call `$this->Post_model->get_all()`, `$this->Post_model->get_by_id($id)`, etc.
- In `index()`, `$this->Post_model->get_all()` now fetches the real posts from the database instead of the hardcoded array we used in Lesson 3.
- In `show($id)`, calling `$this->Post_model->get_by_id($id)` returns either an associative array (if the post exists) or `null` (if no row was found). The `if (!$post)` check handles the case where someone visits a URL like `/posts/999` for a post that does not exist — instead of a blank page or a PHP error, CI3 displays a proper 404 page.

### Step 2: Save and Test

Save the controller file and test the following URLs in your browser:

- Visit `http://localhost/ci3-blog/posts` - data should now come from the database via the model.
- Visit `http://localhost/ci3-blog/posts/1` - shows the first post's detail page.
- Visit `http://localhost/ci3-blog/posts/999` - shows a 404 page because post ID 999 does not exist.

---

## 4. Query Builder Reference

CI3's Query Builder provides a fluent, chainable API for building SQL queries without writing raw SQL. The table below summarizes the most important methods you will use throughout this course.

| Method | SQL Equivalent | Example |
|--------|----------------|---------|
| `get('posts')` | `SELECT * FROM posts` | `$this->db->get('posts')` |
| `get_where('posts', ['id'=>1])` | `SELECT * WHERE id=1` | Returns query object |
| `where('status','publish')` | `WHERE status='publish'` | Chainable |
| `order_by('created_at','DESC')` | `ORDER BY created_at DESC` | Chainable |
| `limit(5)` | `LIMIT 5` | Chainable |
| `insert('posts', $data)` | `INSERT INTO posts` | `$data` is assoc array |
| `update('posts', $data)` | `UPDATE posts SET ...` | Needs `where()` first |
| `delete('posts')` | `DELETE FROM posts` | Needs `where()` first |

| Result Method | Returns |
|--------------|---------|
| `result()` | Array of objects |
| `result_array()` | Array of associative arrays |
| `row()` | Single object |
| `row_array()` | Single associative array |
| `num_rows()` | Row count |

The key distinction when choosing a result method is whether you expect one row or many. Use `result_array()` when you expect to loop over multiple rows (for example, listing all posts). Use `row_array()` when you expect exactly one row (for example, fetching a single post by its ID). Using `result_array()` for a single-row query will not cause an error, but it returns an outer array, meaning you would have to access the row as `$result[0]['title']` instead of the simpler `$result['title']`.

---

## 5. Fix the Errors in Your Code

Here are common mistakes when working with models and how to correct them.

**Error 1: Model filename starts with lowercase.**
CI3 requires the model filename to start with an uppercase letter. Use `Post_model.php`, not `post_model.php`.

**Error 2: Forgetting to load the model.**
If you attempt to call `$this->Post_model->get_all()` without first loading the model, CI3 will throw an error saying the property does not exist.

```php
// Wrong: model never loaded
$this->Post_model->get_all();

// Correct: load in constructor first
public function __construct()
{
    parent::__construct();
    $this->load->model('Post_model');
}
```

Always load the model in the constructor so it is available to all methods in the controller.

**Error 3: Using `result_array()` when you need a single row.**
`result_array()` always returns an array of arrays — even if only one row was found. If you use it to fetch a single record, you must access it as `$result[0]['column']`, which is awkward and can lead to bugs.

```php
// Incorrect: returns array of arrays
$post = $this->db->get_where('posts', ['id' => 1])->result_array();

// Correct: returns a single associative array
$post = $this->db->get_where('posts', ['id' => 1])->row_array();
```

With `result_array()`, the data is wrapped in an outer array even when only one row is returned. To access the title you would have to write `$post[0]['title']`, which is redundant and easy to forget. With `row_array()`, CI3 unwraps that outer array automatically, so `$post['title']` works directly — cleaner and less error-prone.

---

## 6. Exercises

Put your Query Builder knowledge to practice with the following exercises.

**Exercise 1:** Add a method `get_published()` to the model that returns only posts with `status = 'publish'`. Use it in the controller and verify only published posts appear.

**Exercise 2:** Add a method `search($keyword)` that uses `$this->db->like('title', $keyword)` to search posts by title. Test it.

**Exercise 3:** In the controller `index()`, pass the total post count to the view and display it above the posts table.

---

## 7. Solutions

Here are the solutions to the exercises provided above.

**Solution for Exercise 1:**

```php
public function get_published()
{
    return $this->db
        ->where('status', 'publish')
        ->order_by('created_at', 'DESC')
        ->get($this->table)
        ->result_array();
}
```

This method chains `where('status', 'publish')` before calling `get()`, so the generated SQL is `SELECT * FROM posts WHERE status = 'publish' ORDER BY created_at DESC`. CI3 automatically escapes the value `'publish'` to prevent SQL injection.

**Solution for Exercise 2:**

```php
public function search($keyword)
{
    return $this->db
        ->like('title', $keyword)
        ->get($this->table)
        ->result_array();
}
```

`->like('title', $keyword)` generates the SQL clause `WHERE title LIKE '%keyword%'`. The `%` wildcards are added automatically by CI3, so the method matches any post whose title contains the keyword anywhere — not just at the start or end.

**Solution for Exercise 3:**

In the controller's `index()` method, add this line before loading the view:

```php
$data['total'] = $this->Post_model->count_all();
```

Then in the view, display it like this:

```php
<p>Total: <?php echo $total; ?> posts</p>
```

`count_all()` runs `SELECT COUNT(*) FROM posts` and returns a plain integer. Storing it as `$data['total']` makes it available in the view as `$total`.

---

## Next Up - Lesson 7

Models extend `CI_Model` and contain all database operations. Load with `$this->load->model('Model_name')`. Query Builder chains methods: `where()`, `order_by()`, `limit()`, `get()`. Use `result_array()` for lists and `row_array()` for single records. The model keeps database logic out of the controller.

In Lesson 7, you will build the full Read operations — the post listing page and the post detail page — using the model we created in this lesson.