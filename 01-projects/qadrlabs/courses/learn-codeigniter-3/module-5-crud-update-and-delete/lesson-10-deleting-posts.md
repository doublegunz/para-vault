## 1. Before You Begin

The final CRUD operation: delete. The user clicks Delete on the listing page, a JavaScript confirmation dialog appears, and if confirmed, the post is removed from the database with a flash message.

### What You'll Build

You will implement the delete action in the controller with confirmation and flash message.

### What You'll Learn

- ✅ The delete controller method
- ✅ JavaScript confirmation before delete
- ✅ Flash message after deletion
- ✅ Checking post existence before deleting
- ✅ The complete CRUD cycle review

### What You'll Need

- Lesson 9 completed

---

## 2. Add the Delete Method

Unlike create and edit, the delete operation does not need a form or a dedicated view. It is a single controller method: verify the post exists, delete it, set a flash message, and redirect.

Open `application/controllers/Posts.php` and add the following method inside the class.

```php
public function delete($id)
{
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }

    $this->Post_model->delete($id);
    $this->session->set_flashdata('success', 'Post deleted successfully.');
    redirect('posts');
}
```

Here is what each line does:

- `$this->Post_model->get_by_id($id)` checks whether the post actually exists before attempting to delete it. This prevents a silent no-op if someone manually types a URL like `/posts/delete/999`. Without this guard, calling `delete()` on a non-existent ID would run an `UPDATE` query that matches zero rows — no error is thrown, but the behavior is incorrect.
- `if (!$post) { show_404(); return; }` stops execution immediately if the post was not found. `show_404()` is a CI3 global function that renders the default 404 error page and terminates the response.
- `$this->Post_model->delete($id)` calls the `delete()` method we defined in Lesson 6, which runs `WHERE id = $id` followed by `DELETE FROM posts`. The `WHERE` clause is what prevents all rows from being deleted — only the row matching this specific `$id` is removed.
- `$this->session->set_flashdata('success', 'Post deleted successfully.')` stores a flash message that will appear on the post listing page after the redirect.
- `redirect('posts')` sends the user back to the listing. Like in create and update, we always redirect after a write operation — never load a view directly. This prevents the browser from resubmitting the delete request if the user refreshes the page.

---

## 3. Verify the Delete Link

The index view from Lesson 7 already has the delete link built in. Let's review what it does.

```php
<a href="<?php echo site_url('posts/delete/' . $post['id']); ?>"
   class="btn btn-danger btn-sm"
   onclick="return confirm('Delete this post?')">Delete</a>
```

`site_url('posts/delete/' . $post['id'])` generates the full URL for the delete action, for example `http://localhost/ci3-blog/posts/delete/3`. When clicked, CI3 routes this URL to `Posts::delete(3)` via the route we configured in Lesson 4.

The `onclick="return confirm('Delete this post?')"` is a client-side safety net. Before the browser follows the link, it displays a native confirmation dialog. If the user clicks "Cancel", `confirm()` returns `false`, and the browser stops navigating — the delete request is never sent to the server. If the user clicks "OK", `confirm()` returns `true`, and the link is followed normally.

No changes are needed to the index view — this is already in place.

---

## 4. Test the Complete CRUD

Now that all four CRUD operations are implemented, let's review the complete URL-to-method mapping for the blog.

| Operation | URL | Controller Method |
|-----------|-----|------------------|
| List all | `/posts` | `index()` |
| View one | `/posts/1` | `show(1)` |
| Create form | `/posts/create` | `create()` |
| Save new post | POST `/posts/store` | `store()` |
| Edit form | `/posts/edit/1` | `edit(1)` |
| Save changes | POST `/posts/update/1` | `update(1)` |
| Delete post | `/posts/delete/1` | `delete(1)` |

Test the full cycle in order:

1. Visit `/posts` - see the post listing.
2. Click "Create New Post" - fill the form and submit.
3. Click "View" on the new post to see the detail page.
4. Click "Edit" - change the title, submit, and verify the change on the listing.
5. Click "Delete" - confirm the dialog, and verify the post is removed from the listing.

---

## 5. Fix the Errors in Your Code

Here are common mistakes when implementing the delete feature.

**Error 1: Deleting without checking if the post exists.**
Calling `$this->Post_model->delete($id)` without verifying that the post exists first means the delete query runs even for IDs that have no matching row. While this does not break anything in CI3 (it simply affects zero rows), it is incorrect behavior.

```php
// Unsafe: no existence check
public function delete($id) {
    $this->Post_model->delete($id);
    redirect('posts');
}

// Safe: check first
public function delete($id) {
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }
    $this->Post_model->delete($id);
    redirect('posts');
}
```

**Error 2: No confirmation dialog.**
Without the `onclick="return confirm(...)"` attribute, one accidental click permanently deletes the post with no warning.

```php
// Dangerous: no confirmation
<a href="<?php echo site_url('posts/delete/' . $post['id']); ?>">Delete</a>

// Safe: user must confirm
<a href="<?php echo site_url('posts/delete/' . $post['id']); ?>"
   onclick="return confirm('Delete this post?')">Delete</a>
```

**Error 3: DELETE via GET request (production consideration).**
In this course, the delete action is triggered by a regular GET link. In production applications, write operations such as delete should be submitted via a POST form to prevent CSRF (Cross-Site Request Forgery) attacks — where a malicious website tricks a logged-in user's browser into silently following a delete link. For a learning environment, GET with JavaScript confirmation is acceptable. In Lesson 12 (authentication), we will discuss session-based protection.

---

## 6. Exercises

Practice the delete feature with the following tasks.

**Exercise 1:** Instead of showing a 404 when a non-existent post ID is deleted, redirect to the listing with a red error flash message.

**Exercise 2:** Replace the JavaScript `confirm()` dialog with a dedicated confirmation page. When the user clicks "Delete" on the listing, redirect them to a `/posts/confirm-delete/1` page that shows the post title and two buttons: "Yes, Delete" and "Cancel".

**Exercise 3:** Test the complete CRUD cycle: create 3 posts, edit 1, delete 1, and verify that the listing correctly shows 2 posts.

---

## 7. Solutions

Here are the solutions to the exercises above.

**Solution for Exercise 1:**

Replace the `delete()` method with the following version:

```php
public function delete($id) {
    $post = $this->Post_model->get_by_id($id);
    if (!$post) {
        $this->session->set_flashdata('error', 'Post not found.');
        redirect('posts');
        return;
    }
    $this->Post_model->delete($id);
    $this->session->set_flashdata('success', 'Post deleted successfully.');
    redirect('posts');
}
```

Instead of `show_404()`, we now call `set_flashdata('error', ...)` and redirect. This gives the user a clearer, friendlier message instead of a raw 404 page. Then add the following block to the index view, alongside the existing success flash message check:

```php
<?php if ($this->session->flashdata('error')): ?>
    <div style="background:#fef2f2;border:1px solid #fca5a5;color:#991b1b;padding:10px;border-radius:6px;margin-bottom:16px;">
        <?php echo $this->session->flashdata('error'); ?>
    </div>
<?php endif; ?>
```

`flashdata('error')` uses a different session key (`'error'`) from the success message (`'success'`), so both can coexist independently in the session without overwriting each other.

**Solution for Exercise 2:**

This requires a new controller method and a new view:

```php
public function confirm_delete($id)
{
    $post = $this->Post_model->get_by_id($id);
    if (!$post) { show_404(); return; }

    $data['post'] = $post;
    $data['title'] = 'Confirm Delete';
    $this->load->view('posts/confirm_delete', $data);
}
```

The view (`application/views/posts/confirm_delete.php`) displays the post title and two buttons: one linking to `posts/delete/$id` and one linking back to `posts`. This approach keeps the delete confirmation entirely server-side and does not depend on JavaScript.

**Solution for Exercise 3:** This is a manual testing task. Follow the CRUD steps in order and verify the count in the listing matches the expected result of 2 posts.

---

## Next Up - Lesson 11

Delete checks if the post exists, removes it from the database, sets a flash message, and redirects. JavaScript `confirm()` prevents accidental deletion on the client side. The CRUD cycle is now complete: Create, Read, Update, Delete — all using the `Post_model` and CI3's Query Builder.

In Lesson 11, you will create a template layout to eliminate HTML duplication across all views.