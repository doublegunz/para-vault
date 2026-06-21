## 1. Before You Begin

The blog is publicly accessible. Anyone can create, edit, and delete posts. Authentication restricts these actions to logged-in users. This lesson implements a simple session-based login system: a users table, login form, session management, and page protection.

### What You'll Build

You will create a users table, a login form, session-based authentication, and protect the create/edit/delete actions.

### What You'll Learn

- ✅ Creating the `users` table with hashed passwords
- ✅ `password_hash()` and `password_verify()`
- ✅ CI3 session library for login state
- ✅ Login and logout controller methods
- ✅ Protecting routes with session checks
- ✅ Displaying logged-in user in the navbar

### What You'll Need

- Lesson 11 completed

---

## 2. Create the Users Table

Before building the login system, we need a `users` table to store credentials. Open HeidiSQL or the MySQL CLI and run the following against the `ci3_blog` database.

```sql
USE ci3_blog;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO users (name, email, password) VALUES
('Admin', 'admin@example.com', '$2y$10$bD0v3dD4gJ5dT47J4XfEn.HiP2rsZ5Ym57d/Xsilm5iFx3nLu6e1C');
```

The long string starting with `$2y$10$` is the result of calling `password_hash('password123', PASSWORD_DEFAULT)` in PHP. We insert the hash directly so the test user immediately has a valid, securely stored password. The `email` column is marked `UNIQUE`, which means the database will reject any attempt to insert a second row with the same email address.

> The hash above is equivalent to `password_hash('password123', PASSWORD_DEFAULT)`. Use `admin@example.com` / `password123` to log in during testing.

---

## 3. Create the Auth Controller

Now we create a dedicated controller for all authentication-related actions: showing the login form, processing the login attempt, and logging out.

Create `application/controllers/Auth.php` with the following content.

```php
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Auth extends CI_Controller {

    public function login()
    {
        if ($this->session->userdata('user_id')) {
            redirect('posts');
            return;
        }

        $data['title'] = 'Login';
        $this->load->view('templates/header', $data);
        $this->load->view('auth/login', $data);
        $this->load->view('templates/footer');
    }

    public function attempt()
    {
        $this->load->library('form_validation');
        $this->form_validation->set_rules('email', 'Email', 'required|valid_email');
        $this->form_validation->set_rules('password', 'Password', 'required');

        if ($this->form_validation->run() === FALSE) {
            $data['title'] = 'Login';
            $this->load->view('templates/header', $data);
            $this->load->view('auth/login', $data);
            $this->load->view('templates/footer');
            return;
        }

        $this->load->model('User_model');
        $user = $this->User_model->get_by_email($this->input->post('email'));

        if ($user && password_verify($this->input->post('password'), $user['password'])) {
            $this->session->set_userdata([
                'user_id'   => $user['id'],
                'user_name' => $user['name'],
                'logged_in' => TRUE,
            ]);
            redirect('posts');
        } else {
            $this->session->set_flashdata('error', 'Invalid email or password.');
            redirect('auth/login');
        }
    }

    public function logout()
    {
        $this->session->sess_destroy();
        redirect('auth/login');
    }
}
```

Let's walk through each key part:

- In `login()`, `$this->session->userdata('user_id')` checks whether the session already contains a `user_id` key. If it does, the user is already logged in and there is no reason to show the login form again — we redirect them straight to the post listing.
- In `attempt()`, `valid_email` is a CI3 built-in validation rule that checks whether the submitted value is a properly formatted email address (e.g., contains `@` and a domain). It does not check if the email actually exists in the database — that is handled separately.
- `$this->load->model('User_model')` loads the User model that we will create in the next step, making it available as `$this->User_model`.
- `$this->User_model->get_by_email($this->input->post('email'))` queries the `users` table for a row matching the submitted email. If found, it returns an associative array. If not found, it returns `null`.
- `password_verify($this->input->post('password'), $user['password'])` is a PHP native function that compares the plain-text password the user typed with the bcrypt hash stored in the database. It returns `TRUE` if they match. You cannot simply compare the two strings with `===` because a bcrypt hash of the same password changes every time `password_hash()` is called — `password_verify()` is the only correct way to check it.
- `$this->session->set_userdata([...])` stores multiple values into the CI3 session at once by passing an associative array. After this call, `user_id`, `user_name`, and `logged_in` are all available via `$this->session->userdata()` on every subsequent request until the session is destroyed or expires.
- When credentials are invalid, `set_flashdata('error', 'Invalid email or password.')` stores an error message for exactly one request, then `redirect('auth/login')` sends the user back to the login page. The flash message is displayed there.
- `$this->session->sess_destroy()` in `logout()` clears the entire session, removing all stored keys including `user_id`, `user_name`, and `logged_in`. After this, the user is effectively logged out and redirected to the login page.

---

## 4. Create the User Model

The User model has a single responsibility: find a user by their email address. Create `application/models/User_model.php` with the following content.

```php
<?php
class User_model extends CI_Model {

    public function get_by_email($email)
    {
        return $this->db->get_where('users', ['email' => $email])->row_array();
    }
}
```

`get_where('users', ['email' => $email])` generates the SQL `SELECT * FROM users WHERE email = ?`. CI3's Query Builder automatically escapes the `$email` value, preventing SQL injection. `row_array()` returns a single row as an associative array, or `null` if no matching row is found — which is what we check in `Auth::attempt()`.

---

## 5. Create the Login View

Create the folder `application/views/auth/` and inside it create `login.php` with the following content.

```php
<div class="card" style="max-width:400px;margin:40px auto;">
    <h1 style="text-align:center;margin-bottom:20px;"><?php echo $title; ?></h1>

    <?php if ($this->session->flashdata('error')): ?>
        <div class="flash-error"><?php echo $this->session->flashdata('error'); ?></div>
    <?php endif; ?>

    <?php echo form_open('auth/attempt'); ?>
        <div class="form-group">
            <label for="email">Email</label>
            <input type="email" name="email" id="email" value="<?php echo set_value('email'); ?>">
            <div class="error"><?php echo form_error('email'); ?></div>
        </div>
        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" name="password" id="password">
            <div class="error"><?php echo form_error('password'); ?></div>
        </div>
        <button type="submit" class="btn btn-primary" style="width:100%;padding:10px;">Login</button>
    <?php echo form_close(); ?>
</div>
```

The CI3-specific elements here should be familiar from Lesson 8:

- `$this->session->flashdata('error')` reads the error flash message set in `Auth::attempt()` when credentials are invalid. Since this is a flash message, it only appears once after an invalid login attempt.
- `form_open('auth/attempt')` points the form to the `attempt()` method on the `Auth` controller.
- `set_value('email')` repopulates the email field after failed validation, so the user does not have to retype it. We deliberately do not repopulate the password field — it is a security best practice to always clear password inputs after a failed attempt.

---

## 6. Protect Routes

With the login system in place, we need to ensure that only logged-in users can access the create, edit, and delete actions. The cleanest place to add this guard in CI3 is in the `Posts` controller's constructor, because the constructor runs on every request to that controller.

Open `application/controllers/Posts.php` and update the `__construct()` method.

```php
public function __construct()
{
    parent::__construct();
    $this->load->model('Post_model');

    $protected = ['create', 'store', 'edit', 'update', 'delete'];
    $method = $this->router->fetch_method();

    if (in_array($method, $protected) && !$this->session->userdata('logged_in')) {
        redirect('auth/login');
    }
}
```

Here is how the route protection works:

- `$this->router->fetch_method()` is a CI3 Router class method that returns the name of the controller method being called for the current request. For a request to `/posts/edit/1`, it returns `'edit'`. For a request to `/posts`, it returns `'index'`.
- `$protected = ['create', 'store', 'edit', 'update', 'delete']` is an array of method names that require authentication. Methods not in this list — `index()` and `show()` — are left publicly accessible so any visitor can read the blog without logging in.
- `in_array($method, $protected)` checks whether the current method is one of the protected ones. If it is, and `!$this->session->userdata('logged_in')` evaluates to `TRUE` (meaning the user is not logged in), CI3 immediately redirects the request to the login page.
- This approach is efficient because the check happens before the actual method body executes. If the user is not logged in and tries to access `/posts/create`, the constructor intercepts the request, redirects to `/auth/login`, and the `create()` method body never runs.

---

## 7. Update the Navbar

Now that we have a real session, we can update the navbar to show different links based on whether the user is logged in. Open `application/views/templates/header.php` and update the `<nav>` block.

```php
<nav>
    <a href="<?php echo site_url('posts'); ?>" class="brand">CI3 Blog</a>
    <div>
        <a href="<?php echo site_url('posts'); ?>">Posts</a>
        <?php if ($this->session->userdata('logged_in')): ?>
            <a href="<?php echo site_url('posts/create'); ?>">Create</a>
            <span style="color:#93c5fd;">| <?php echo $this->session->userdata('user_name'); ?></span>
            <a href="<?php echo site_url('auth/logout'); ?>">Logout</a>
        <?php else: ?>
            <a href="<?php echo site_url('auth/login'); ?>">Login</a>
        <?php endif; ?>
    </div>
</nav>
```

`$this->session->userdata('logged_in')` reads the `logged_in` value from the session. If it is `TRUE`, the navbar shows the "Create" link, the logged-in user's name, and a "Logout" link. If it is `null` or `FALSE` (not logged in), the navbar shows only a "Login" link. `$this->session->userdata('user_name')` reads the user's name that was stored during login via `set_userdata()` in the `Auth::attempt()` method.

---

## 8. Fix the Errors in Your Code

Here are common authentication mistakes and how to correct them.

**Error 1: Storing passwords as plain text.**
Never store raw passwords in the database. If the database is compromised, all passwords are immediately exposed.

```php
// Wrong: plain text password stored
$this->db->insert('users', ['password' => $password]);

// Correct: always hash before storing
$this->db->insert('users', ['password' => password_hash($password, PASSWORD_DEFAULT)]);
```

`password_hash()` uses bcrypt by default (`PASSWORD_DEFAULT`), which is slow by design — it makes brute-force attacks computationally expensive.

**Error 2: Comparing hashed passwords with `===`.**
A bcrypt hash of the same password is never the same string twice. The only correct way to verify a password is with `password_verify()`.

```php
// Wrong: always returns false
if ($user['password'] === $this->input->post('password')) { }

// Correct: uses timing-safe comparison
if (password_verify($this->input->post('password'), $user['password'])) { }
```

**Error 3: Session library not loaded or encryption key missing.**
CI3's session library requires an `encryption_key` to be set in `config.php`, and the library itself must be loaded. If either is missing, sessions will not work.

```php
// In application/config/config.php
$config['encryption_key'] = 'your-random-secret-key-here';
```

Also ensure `'session'` is in the autoload libraries array:

```php
$autoload['libraries'] = array('database', 'session');
```

---

## 9. Exercises

Practice the authentication system with the following tasks.

**Exercise 1:** Test login with valid credentials (`admin@example.com` / `password123`). Verify that after login, you can access the Create, Edit, and Delete actions.

**Exercise 2:** Without logging in, navigate directly to `/posts/create` in the browser. Verify that you are automatically redirected to the login page.

**Exercise 3:** Add a registration page at `/auth/register` that accepts a name, email, and password, hashes the password with `password_hash()`, and inserts the new user into the `users` table.

---

## 10. Solutions

Here are the solutions to the exercises above.

**Solution for Exercises 1 and 2:** These are manual testing tasks. Follow the steps described in each exercise and observe the behavior in your browser.

**Solution for Exercise 3:**

Add `register()` and `save_register()` methods to `Auth.php`:

```php
public function register()
{
    $data['title'] = 'Register';
    $this->load->view('templates/header', $data);
    $this->load->view('auth/register', $data);
    $this->load->view('templates/footer');
}

public function save_register()
{
    $this->load->library('form_validation');
    $this->form_validation->set_rules('name', 'Name', 'required');
    $this->form_validation->set_rules('email', 'Email', 'required|valid_email|is_unique[users.email]');
    $this->form_validation->set_rules('password', 'Password', 'required|min_length[8]');

    if ($this->form_validation->run() === FALSE) {
        $this->register();
        return;
    }

    $this->load->model('User_model');
    $this->User_model->create([
        'name'     => $this->input->post('name'),
        'email'    => $this->input->post('email'),
        'password' => password_hash($this->input->post('password'), PASSWORD_DEFAULT),
    ]);

    $this->session->set_flashdata('success', 'Account created. Please log in.');
    redirect('auth/login');
}
```

The `is_unique[users.email]` validation rule is a CI3 built-in that automatically queries the `users.email` column in the database and fails validation if the submitted email already exists. This prevents duplicate accounts without writing custom query logic. `password_hash()` hashes the password before inserting it into the database.

---

## Next Up - Lesson 13

Authentication uses sessions to track logged-in state. `password_hash()` stores passwords securely as bcrypt hashes. `password_verify()` is the only correct way to compare a plain-text password against a stored hash. Session data (`user_id`, `logged_in`) is checked in the constructor to protect routes. The navbar updates dynamically based on `$this->session->userdata('logged_in')`.

In Lesson 13, you will test the complete application end-to-end and review the full MVC architecture.
