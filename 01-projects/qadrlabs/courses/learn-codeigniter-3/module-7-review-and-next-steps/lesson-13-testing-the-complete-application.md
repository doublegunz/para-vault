## 1. Before You Begin

The blog application is complete. This lesson walks through every feature, reviews the final file structure, and covers common CI3 debugging techniques. Testing end-to-end is essential — it confirms that all the pieces we built across Lessons 1-12 connect correctly in a real browser environment.

### What You'll Learn

- ✅ The complete project file structure
- ✅ End-to-end test checklist
- ✅ Common CI3 errors and solutions
- ✅ The complete request flow

### What You'll Need

- All previous lessons completed

---

## 2. Complete File Structure

Before testing, let's review the complete structure of the project we have built. Every file listed here was created or modified in a previous lesson.

```text
ci3-blog/
    application/
        config/
            autoload.php
            config.php
            database.php
            routes.php
        controllers/
            Posts.php
            Auth.php
        models/
            Post_model.php
            User_model.php
        views/
            templates/
                header.php
                footer.php
            posts/
                index.php
                show.php
                create.php
                edit.php
            auth/
                login.php
    system/
    .htaccess
    index.php
```

Here is a summary of what each part does and which lesson it came from:

- **`config/autoload.php`**: Loads `database`, `session` libraries and `url`, `form` helpers on every request (Lesson 2).
- **`config/config.php`**: Sets `base_url` and empties `index_page` to remove `index.php` from URLs (Lesson 2).
- **`config/database.php`**: Holds MySQL connection credentials (`hostname`, `database`, `username`, `password`) (Lesson 5).
- **`config/routes.php`**: Defines custom routes and sets `default_controller = 'posts'` (Lesson 4).
- **`controllers/Posts.php`**: The main controller with 7 methods — `index`, `show`, `create`, `store`, `edit`, `update`, `delete`. Its constructor loads `Post_model` and guards write methods against unauthenticated access (Lessons 3, 6, 7, 8, 9, 10, 12).
- **`controllers/Auth.php`**: Handles `login`, `attempt`, and `logout` (Lesson 12).
- **`models/Post_model.php`**: Contains all Query Builder methods for the `posts` table: `get_all`, `get_by_id`, `create`, `update`, `delete`, `count_all`, `get_by_status`, `generate_slug` (Lesson 6).
- **`models/User_model.php`**: Contains a single method, `get_by_email`, used during login (Lesson 12).
- **`views/templates/header.php`**: The shared header partial — doctype, global CSS, navigation bar with session-aware links (Lessons 11, 12).
- **`views/templates/footer.php`**: The shared footer partial — closes the container, body, and html tags (Lesson 11).
- **`views/posts/`**: Four content views for listing, detail, create form, and edit form (Lessons 3, 7, 8, 9, 11).
- **`views/auth/login.php`**: The login form view (Lesson 12).
- **`system/`**: The CI3 framework core — never modified.
- **`.htaccess`**: Enables URL rewriting to remove `index.php` from all URLs (Lesson 2).
- **`index.php`**: The single entry point for all requests (CI3 default).

---

## 3. Test Checklist

Work through every item below in order. Each test confirms a specific feature of the application.

| Test | URL | Expected Result |
|------|-----|-----------------|
| Home redirect | `/` | Redirects to `/posts` via `default_controller` |
| Post listing | `/posts` | Table of all posts with View/Edit/Delete buttons |
| Post detail | `/posts/1` | Shows title, content, status, and date of post 1 |
| Non-existent post | `/posts/999` | CI3 displays the 404 error page |
| Create (not logged in) | `/posts/create` | Redirects to `/auth/login` via constructor guard |
| Login page | `/auth/login` | Login form renders correctly |
| Login (correct credentials) | POST `/auth/attempt` | Redirects to `/posts`, navbar shows username and Logout |
| Login (wrong credentials) | POST `/auth/attempt` | Stays on login page with red error flash message |
| Create form (logged in) | `/posts/create` | Empty form renders with all fields |
| Create validation | POST empty form | Inline error messages appear below each field |
| Create success | POST valid form | Redirects to `/posts` with green success flash message, new post in list |
| Edit form | `/posts/edit/1` | Form renders pre-filled with post 1's current data |
| Update success | POST changes | Redirects to `/posts` with success message, updated title visible |
| Delete | `/posts/delete/1` | JS confirm dialog appears, on confirm post is removed and flash message shows |
| Logout | `/auth/logout` | Session destroyed, redirects to `/auth/login`, navbar shows Login link |

---

## 4. Common Errors

This section covers the most frequent CI3 errors you may encounter and how to diagnose and fix each one.

**404 on all pages.**
Check that `.htaccess` exists in the project root and that Apache's `mod_rewrite` module is enabled. Also verify `routes.php` has `$route['default_controller'] = 'posts'` set — without it, visiting `/` returns a 404. In Laragon, `mod_rewrite` is on by default. In XAMPP, check `httpd.conf`.

**"Unable to connect to your database server."**
Open `application/config/database.php` and verify that `hostname`, `username`, `password`, and `database` are exactly correct. Also confirm that MySQL is running (check Laragon's dashboard). This error appears on every page load if the `database` library is in autoload but the credentials are wrong.

**"Unable to load the requested class: Session."**
The session library is not loaded. Add `'session'` to `$autoload['libraries']` in `autoload.php`:

```php
$autoload['libraries'] = array('database', 'session');
```

This error will cause flash messages and authentication to fail completely.

**Form validation errors not showing.**
Calling `$this->form_validation->set_rules()` before loading the library will throw an error. Always call `$this->load->library('form_validation')` first. Also check that `form_error('field_name')` in the view uses the exact same field name as the `name` attribute on the HTML input.

**Flash message not appearing.**
Flash messages depend on the session library being loaded. If `'session'` is missing from `autoload.php`, flash messages will never work. Also confirm that the view checks `$this->session->flashdata('success')` — not a plain PHP variable — because flash messages are stored in the session, not in `$data`.

---

## 5. Exercises

Test the application thoroughly with the following exercises.

**Exercise 1:** Complete a full CRUD cycle: log in, create a new post, view it on the detail page, edit its title, confirm the change on the listing, then delete it and confirm it disappears.

**Exercise 2:** Without logging out, manually navigate to `/posts/create`, `/posts/edit/1`, and `/posts/delete/1` and confirm all three work. Then log out and try the same URLs again — verify that all three redirect to the login page.

**Exercise 3:** Add a live post count to the navigation bar that reads "Posts (X)" where X is the total number of posts in the database.

---

## 6. Solutions

**Solution for Exercises 1 and 2:** These are manual end-to-end testing tasks. Follow the steps in sequence and observe the browser behavior at each step.

**Solution for Exercise 3:**

The post count needs to be available in `header.php`. The simplest approach is to load it via a base controller or pass it from every controller method. A practical shortcut is to use CI3's built-in database access directly from within the header view (since `$this->db` is available in views):

```php
// In header.php
$count = $this->db->count_all('posts');
```

Then display it in the nav link:

```php
<a href="<?php echo site_url('posts'); ?>">Posts (<?php echo $count; ?>)</a>
```

`$this->db->count_all('posts')` runs `SELECT COUNT(*) FROM posts` and returns an integer. Because `$this->db` is available inside views (CI3 makes the controller's `$this` accessible in loaded views), this works without any changes to the controller. However, for better separation of concerns, it is preferable to pass the count from the controller via `$data['post_count']` and read it in the header view.

---

## Next Up - Lesson 14

The CI3 blog application is complete: 2 controllers (`Posts` and `Auth`), 2 models, 5 views, template layout, authentication, form validation, and flash messages. The MVC pattern keeps code organized — models for data, views for HTML, controllers for request handling. Every feature was built using CI3's core libraries: Query Builder, form_validation, session, and URL helpers.

In Lesson 14, you will compare CI3 with CI4 and Laravel, and plan your path to modern PHP frameworks.