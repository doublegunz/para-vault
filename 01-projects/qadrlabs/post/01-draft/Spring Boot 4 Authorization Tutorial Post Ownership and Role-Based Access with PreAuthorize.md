# Spring Boot 4 Authorization Tutorial: Post Ownership and Role-Based Access with @PreAuthorize

In the [authentication tutorial](https://qadrlabs.com/post/spring-boot-4-authentication-tutorial-add-login-and-registration-with-spring-security-7-and-jpa) we put a login wall around the blog, and in the [file upload tutorial](https://qadrlabs.com/post/spring-boot-4-file-upload-and-download-tutorial-multipart-validation-and-safe-storage) we let users attach files. The app now knows who you are. What it still does not know is what you are allowed to do. Right now any logged-in user can open `/posts`, click Edit on a post they did not write, change it, or delete it outright. Authentication answered "who are you?" but never "is this yours?"

That gap is not a small one. On a multi-author blog it means one writer can silently rewrite another's article, or a disgruntled user can wipe the front page. The fix is authorization: rules that decide, per action, whether the current user may proceed. We want two rules in particular. A post belongs to the user who created it, and only that author, or an administrator, may edit or delete it. Everyone else gets a polite 403.

In this tutorial we will give every post an owner, stamp that owner automatically at creation time from the logged-in user, and enforce the "owner or admin" rule with Spring Security's method security and the `@PreAuthorize` annotation. We will seed an administrator account, hide the Edit and Delete buttons from users who cannot use them, and then update the test suite, because turning on method security is exactly the kind of change that breaks controller tests written before security existed.

## Overview {#overview}

Authorization in Spring Security comes in two flavors, and this tutorial leans on the more precise one. URL security, which we already use with `anyRequest().authenticated()`, decides access based on the request path. Method security decides access based on a Java method and the arguments passed to it, which is what we need when the rule depends on the specific post being edited. We turn it on with `@EnableMethodSecurity`, then annotate the edit, update, and delete handlers with a SpEL expression that calls a small ownership-checking bean. The database gets a new `author` column, the create flow fills it from the session, and the UI hides actions the user is not allowed to take. None of this changes the URL rules; the two layers work together.

### What You'll Build

- An `author` relationship on every post, stored as a foreign key that can never be null.
- Automatic ownership: a new post is always stamped with the user who created it, taken from the session, never the form.
- Method-level rules so only the author or an admin can reach the edit, update, and delete actions; everyone else gets a 403 page.
- A seeded administrator account that can moderate any post.
- A posts table that shows the author and only renders Edit and Delete for users who are allowed to use them.
- An updated test suite that proves owners succeed, non-owners are forbidden, and admins can moderate.

### What You'll Learn

- The difference between URL security and method security, and when each one fits.
- How to enable method security with `@EnableMethodSecurity` and write `@PreAuthorize` rules in SpEL.
- How to reference a Spring bean from inside a `@PreAuthorize` expression with the `@beanName` syntax.
- How to read the authenticated user in a controller with `Principal` and stamp ownership safely.
- How to seed an admin role at startup with a `CommandLineRunner`.
- How to test secured controllers with `@WithMockUser`, the CSRF post-processor, and the `springSecurity()` MockMvc configurer.

### What You'll Need

- The secured blog from the authentication tutorial, fully running with a working login.
- Java 17 or higher (Java 21 recommended).
- Maven, a running MariaDB or MySQL database, and an IDE.
- Basic familiarity with Spring Security from the authentication tutorial (the login wall, roles, and BCrypt).

## Step 1: See the Problem and Establish a Baseline {#step-1-see-the-problem-and-establish-a-baseline}

Before changing anything, it helps to see the current behavior and to record a green test suite as a baseline. The authentication tutorial left us with a blog where every authenticated user shares the same powers. Log in as one user, create a post, log out, log in as a second user, and you will find you can edit and delete the first user's post freely. There is no concept of ownership anywhere in the code.

Run the existing test suite first so we have a known-good starting point:

```bash
./mvnw test
```

```
[INFO] Tests run: 32, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Thirty-two tests pass. Keep that number in mind. By the end of this tutorial the suite will be larger, because we are adding authorization tests, and some of the existing controller tests will need to change to account for the new security rules. The goal is to finish with everything green again, including the new cases. The reason the current `PostControllerTest` passes without dealing with security at all is that the `@WebMvcTest` slice does not load our `SecurityConfig`, so method security simply is not active in those tests yet. That is about to change.

## Step 2: Add the Author Relationship to Post {#step-2-add-the-author-relationship-to-post}

Ownership has to live in the database, so the first change is a relationship from `Post` to `User`. A post has exactly one author, and a user can write many posts, which is a classic many-to-one relationship. We make the foreign key non-null so the database itself guarantees no post can ever exist without an owner.

Open `src/main/java/com/qadrlabs/blog/model/Post.java`. The old version had no author field; the status field was followed directly by the timestamps:

```java
@NotBlank(message = "Status is required")
@Column(nullable = false)
private String status;

@CreationTimestamp
```

Add the author relationship between them:

```java
@NotBlank(message = "Status is required")
@Column(nullable = false)
private String status;

// The user who created this post. optional = false makes the foreign key
// NOT NULL, so a post can never exist without an owner. We load it lazily
// because the list page does not always need the full author record.
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "author_id", nullable = false)
private User author;

@CreationTimestamp
```

The `@ManyToOne` annotation declares the relationship, and `optional = false` together with `@JoinColumn(nullable = false)` makes the `author_id` column `NOT NULL` at the schema level. We use `FetchType.LAZY` so loading a post does not always drag in the full author record; Hibernate fetches it only when we actually read `post.getAuthor()`. Because the application has `spring.jpa.open-in-view` enabled by default, the Thymeleaf templates can still read the author during rendering.

Then add the getter and setter alongside the existing ones:

```java
public User getAuthor() {
    return author;
}

public void setAuthor(User author) {
    this.author = author;
}
```

Since `Post` and `User` live in the same `model` package, no import is needed. One thing to be aware of: if your `posts` table already holds rows from earlier tutorials, adding a `NOT NULL` column to a non-empty table will fail. For a tutorial database the simplest path is to clear the demo posts first, or add the column as nullable, backfill an owner, then tighten it. On a fresh table there is nothing to worry about.

## Step 3: Stamp the Author on Create {#step-3-stamp-the-author-on-create}

A post must be owned by the person who created it, and that person is whoever is logged in. The critical security principle here is that the author comes from the session, never from the form. If we let the form supply an author id, any user could create a post in someone else's name by editing the request. So we read the authenticated username on the server and resolve it to a `User`.

First, update the service so `createPost` accepts the author. Open `src/main/java/com/qadrlabs/blog/service/PostService.java`. The old method took only the post:

```java
public Post createPost(Post post) {
    post.setSlug(generateSlug(post.getTitle()));
    return postRepository.save(post);
}
```

Change it to accept and stamp the author:

```java
public Post createPost(Post post, User author) {
    // Stamp the post with its owner before saving. The author comes from the
    // authenticated session, never from the form, so a user cannot create a
    // post on someone else's behalf.
    post.setAuthor(author);
    post.setSlug(generateSlug(post.getTitle()));
    return postRepository.save(post);
}
```

Add the matching import at the top of the file:

```java
import com.qadrlabs.blog.model.User;
```

Now the controller has to supply that author. Open `src/main/java/com/qadrlabs/blog/controller/PostController.java`. We need the `UserRepository` to look up the logged-in user, so update the imports and the constructor. The old constructor took only the service:

```java
private final PostService postService;

public PostController(PostService postService) {
    this.postService = postService;
}
```

Replace it with a version that also injects the repository:

```java
private final PostService postService;
private final UserRepository userRepository;

public PostController(PostService postService, UserRepository userRepository) {
    this.postService = postService;
    this.userRepository = userRepository;
}
```

Add these imports to the top of the controller, since we now reference the `User` entity, the repository, the `@PreAuthorize` annotation we will use shortly, and the `Principal` type:

```java
import com.qadrlabs.blog.model.User;
import com.qadrlabs.blog.repository.UserRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.security.Principal;
```

Finally, update the `store` handler. The old version created the post with no owner:

```java
@PostMapping
public String store(@Valid @ModelAttribute("post") Post post,
                    BindingResult bindingResult,
                    RedirectAttributes redirectAttributes) {
    if (bindingResult.hasErrors()) {
        return "posts/create";
    }

    postService.createPost(post);
    redirectAttributes.addFlashAttribute("success", "Post created successfully.");
    return "redirect:/posts";
}
```

The new version injects the `Principal`, resolves it to a `User`, and passes it to the service:

```java
@PostMapping
public String store(@Valid @ModelAttribute("post") Post post,
                    BindingResult bindingResult,
                    Principal principal,
                    RedirectAttributes redirectAttributes) {
    if (bindingResult.hasErrors()) {
        return "posts/create";
    }

    // principal.getName() is the username of the logged-in user, injected by
    // Spring Security. We resolve it to the full User entity to stamp ownership.
    User author = userRepository.findByUsername(principal.getName())
            .orElseThrow(() -> new UsernameNotFoundException(
                    "Authenticated user not found: " + principal.getName()));

    postService.createPost(post, author);
    redirectAttributes.addFlashAttribute("success", "Post created successfully.");
    return "redirect:/posts";
}
```

The `Principal` parameter is filled in by Spring Security from the current session, and `principal.getName()` returns the username. We look that username up through the `UserRepository` we already built in the authentication tutorial. Resolving the full `User` is what lets us set a real foreign key. Notice there is no author field anywhere in the form; the ownership decision is made entirely on the server from trusted session data.

## Step 4: Build the PostSecurity Ownership Bean {#step-4-build-the-postsecurity-ownership-bean}

The rule we want to enforce is "the current user owns this post." That check needs to load the post and compare its author to the logged-in username, which is a little too much logic to cram into an annotation. The clean Spring idiom is to put it in a small bean and then call that bean from the `@PreAuthorize` expression. This keeps the security expression readable and the logic unit-testable.

Create `src/main/java/com/qadrlabs/blog/security/PostSecurity.java`:

```java
package com.qadrlabs.blog.security;

import com.qadrlabs.blog.model.Post;
import com.qadrlabs.blog.repository.PostRepository;
import org.springframework.stereotype.Component;

@Component
public class PostSecurity {

    private final PostRepository postRepository;

    public PostSecurity(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    // Returns true only when the post exists AND its author matches the given
    // username. We look the post up fresh from the database rather than trusting
    // anything from the request, so the ownership decision cannot be spoofed.
    // @PreAuthorize references this method by bean name: @postSecurity.isOwner(...).
    public boolean isOwner(Long postId, String username) {
        if (postId == null || username == null) {
            return false;
        }
        return postRepository.findById(postId)
                .map(Post::getAuthor)
                .map(author -> username.equals(author.getUsername()))
                .orElse(false);
    }
}
```

The method is deliberately defensive. It returns `false` for null arguments and for posts that do not exist, so a missing post results in a denied request rather than a crash. It loads the post fresh from the database on every call, which means the ownership decision is always based on the real stored author, not on anything the client sent. Because the class is a `@Component`, Spring registers it as a bean named `postSecurity`, and that name is exactly how we will reference it from the annotation in the next step.

## Step 5: Enable Method Security and Protect the Actions {#step-5-enable-method-security-and-protect-the-actions}

Now we turn on method security and attach the rule to the three dangerous actions: showing the edit form, saving an update, and deleting. Method security is opt-in, so first we enable it on the security configuration.

Open `src/main/java/com/qadrlabs/blog/config/SecurityConfig.java`. The old class carried two annotations:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
```

Add `@EnableMethodSecurity` and its import:

```java
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
```

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
```

`@EnableMethodSecurity` activates the infrastructure that scans for `@PreAuthorize` and friends. Without it, the annotations are silently ignored, which is a subtle and dangerous failure mode, so it is worth double checking this line is present.

While we are in this file, we also want a friendly response when access is denied. By default a blocked request produces a bare 403. Wire in a custom access-denied page by adding one line to the existing filter chain. The old chain ended with the logout block:

```java
                // Configure logout. Spring Security handles POST /logout automatically.
                .logout(logout -> logout
                        .logoutSuccessUrl("/login?logout")
                        .permitAll()
                );

        return http.build();
```

Add an `exceptionHandling` block:

```java
                // Configure logout. Spring Security handles POST /logout automatically.
                .logout(logout -> logout
                        .logoutSuccessUrl("/login?logout")
                        .permitAll()
                )
                // When @PreAuthorize denies access, Spring Security throws an
                // AccessDeniedException. Instead of a raw 403 error page, send the
                // user to our own friendly page that still carries the 403 status.
                .exceptionHandling(ex -> ex.accessDeniedPage("/403"));

        return http.build();
```

Now annotate the handlers. Open `PostController.java` again and add a `@PreAuthorize` line above the edit, update, and delete methods. The expression is the same on all three:

```java
@PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#id, authentication.name)")
@GetMapping("/{id}/edit")
public String edit(@PathVariable Long id, Model model) {
    model.addAttribute("post", postService.getPostById(id));
    return "posts/edit";
}

@PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#id, authentication.name)")
@PostMapping("/{id}")
public String update(@PathVariable Long id,
                     @Valid @ModelAttribute("post") Post post,
                     BindingResult bindingResult,
                     RedirectAttributes redirectAttributes) {
    // ...unchanged body...
}

@PreAuthorize("hasRole('ADMIN') or @postSecurity.isOwner(#id, authentication.name)")
@GetMapping("/{id}/delete")
public String destroy(@PathVariable Long id, RedirectAttributes redirectAttributes) {
    // ...unchanged body...
}
```

The expression reads almost like English: allow the call if the user has the `ADMIN` role, or if the `postSecurity` bean says this user owns the post. Two pieces of SpEL syntax make it work. The `@postSecurity` reference resolves the Spring bean by name and calls its method, which is why naming the component matters. The `#id` reference binds to the method parameter named `id`, so Spring Security passes the actual post id from the URL into our check. The `authentication.name` is the username of the current user. Because `hasRole('ADMIN')` comes first and `or` short-circuits, an admin never even triggers the database lookup in `isOwner`.

We also need the page that the access-denied handler forwards to. Create `src/main/resources/templates/error/403.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Access Denied</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-16 text-center">
        <div class="text-5xl font-bold text-red-600 mb-2">403</div>
        <h1 class="text-2xl font-bold text-gray-900 mb-3">Access Denied</h1>
        <p class="text-gray-600 mb-6">
            You do not have permission to modify this post. Only its author or an administrator can.
        </p>
        <a th:href="@{/posts}" class="inline-block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-5 rounded-md transition duration-200 shadow-sm">
            Back to Posts
        </a>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial Spring Boot Authorization at qadrlabs.com</a>
    </div>
</body>
</html>
```

Finally, add a handler for `/403`. Open `src/main/java/com/qadrlabs/blog/controller/HomeController.java` and add the mapping. There is a real subtlety here that is easy to get wrong. When `@PreAuthorize` denies a `POST` request, Spring Security forwards the still-`POST` request to `/403`. If we map `/403` with `@GetMapping`, that forwarded `POST` finds no matching handler and the user gets a confusing `405 Method Not Allowed` instead of a `403`. Mapping it with a plain `@RequestMapping`, which matches any HTTP method, fixes that:

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "redirect:/posts";
    }

    // Spring Security forwards here (keeping the 403 status) when @PreAuthorize
    // blocks a request. We use @RequestMapping with no method so the page handles
    // a forwarded POST too; a GET-only mapping would answer a denied POST with 405.
    @RequestMapping("/403")
    public String accessDenied() {
        return "error/403";
    }
}
```

This 405-versus-403 detail is the kind of thing that only shows up when you actually exercise a denied `POST` in a running server, which we will do in the Try It Out step.

## Step 6: Seed an Admin User {#step-6-seed-an-admin-user}

Our rule grants special power to anyone with the `ADMIN` role, but the registration flow from the authentication tutorial only ever creates `ROLE_USER` accounts. We need at least one administrator, and the cleanest way to guarantee one exists is to seed it at startup. A `CommandLineRunner` runs once after the application context is ready, which is the perfect hook.

Create `src/main/java/com/qadrlabs/blog/config/DataInitializer.java`:

```java
package com.qadrlabs.blog.config;

import com.qadrlabs.blog.model.User;
import com.qadrlabs.blog.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        // Seed a first administrator on startup if one does not already exist.
        // Real applications would read these values from environment variables;
        // hardcoding them is acceptable only for a local tutorial database.
        if (userRepository.existsByUsername("admin")) {
            return;
        }

        User admin = new User();
        admin.setUsername("admin");
        admin.setEmail("admin@qadrlabs.test");
        // The password is hashed with the same BCrypt bean used at login, so the
        // seeded account authenticates exactly like a normally registered user.
        admin.setPassword(passwordEncoder.encode("admin12345"));
        admin.setRole("ROLE_ADMIN");
        userRepository.save(admin);
    }
}
```

The runner is idempotent: it checks `existsByUsername("admin")` first and does nothing if the account is already there, so restarting the app never creates duplicates. It reuses the `PasswordEncoder` bean from the security config, which means the seeded password is BCrypt-hashed exactly like one from the registration form, and the admin can log in through the normal login page. In a production system you would pull the username and password from environment variables rather than hardcoding them, but for a local tutorial database this is fine.

## Step 7: Show Edit and Delete Only to the Owner or Admin {#step-7-show-edit-and-delete-only-to-the-owner-or-admin}

The server now blocks unauthorized edits, but the UI still shows Edit and Delete buttons to everyone, which leads users straight into a 403. Good authorization hides actions a user cannot perform. We will add an Author column and render the action buttons conditionally. The important mental note is that this is purely cosmetic; the `@PreAuthorize` rule on the server is the real guard. Hiding a button never secures anything on its own, because anyone can craft the request by hand.

Open `src/main/resources/templates/posts/index.html`. First add an Author column header. The old header row went straight from Slug to Status:

```html
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
```

Insert an Author column between them:

```html
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Author</th>
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
```

Now the table row. The old row rendered Edit and Delete unconditionally:

```html
<tr th:each="post, iterStat : ${posts}" class="hover:bg-gray-50 transition duration-150">
    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center" th:text="${iterStat.count}"></td>
    <td class="px-6 py-4 text-sm font-medium text-gray-900" th:text="${post.title}"></td>
    <td class="px-6 py-4 text-sm text-gray-500" th:text="${post.slug}"></td>
    <td class="px-6 py-4 whitespace-nowrap text-sm">
        <span th:if="${post.status == 'publish'}" class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Publish</span>
        <span th:if="${post.status == 'draft'}" class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">Draft</span>
    </td>
    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
        <a th:href="@{/posts/{id}(id=${post.id})}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 rounded-md text-xs text-white uppercase hover:bg-blue-700 transition shadow-sm">View</a>
        <a th:href="@{/posts/{id}/edit(id=${post.id})}" class="inline-flex items-center px-3 py-1.5 bg-amber-500 rounded-md text-xs text-white uppercase hover:bg-amber-600 transition shadow-sm">Edit</a>
        <a th:href="@{/posts/{id}/delete(id=${post.id})}" onclick="return confirm('Are you sure you want to delete this post?')" class="inline-flex items-center px-3 py-1.5 bg-red-600 rounded-md text-xs text-white uppercase hover:bg-red-700 transition shadow-sm">Delete</a>
    </td>
</tr>
```

The new row computes a `canModify` flag, adds the Author cell, and gates Edit and Delete on that flag:

```html
<!-- canModify is true when the current user owns this post or is an admin.
     #authorization.expression evaluates a SpEL security check from the template. -->
<tr th:each="post, iterStat : ${posts}"
    th:with="canModify=${(post.author != null and post.author.username == #authentication.name) or #authorization.expression('hasRole(''ADMIN'')')}"
    class="hover:bg-gray-50 transition duration-150">
    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center" th:text="${iterStat.count}"></td>
    <td class="px-6 py-4 text-sm font-medium text-gray-900" th:text="${post.title}"></td>
    <td class="px-6 py-4 text-sm text-gray-500" th:text="${post.slug}"></td>
    <td class="px-6 py-4 text-sm text-gray-500" th:text="${post.author != null ? post.author.username : '-'}"></td>
    <td class="px-6 py-4 whitespace-nowrap text-sm">
        <span th:if="${post.status == 'publish'}" class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Publish</span>
        <span th:if="${post.status == 'draft'}" class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">Draft</span>
    </td>
    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
        <a th:href="@{/posts/{id}(id=${post.id})}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 rounded-md text-xs text-white uppercase hover:bg-blue-700 transition shadow-sm">View</a>
        <!-- Edit and Delete render only for the owner or an admin. The @PreAuthorize
             rule on the server is the real guard; hiding the buttons is just UX. -->
        <a th:if="${canModify}" th:href="@{/posts/{id}/edit(id=${post.id})}" class="inline-flex items-center px-3 py-1.5 bg-amber-500 rounded-md text-xs text-white uppercase hover:bg-amber-600 transition shadow-sm">Edit</a>
        <a th:if="${canModify}" th:href="@{/posts/{id}/delete(id=${post.id})}" onclick="return confirm('Are you sure you want to delete this post?')" class="inline-flex items-center px-3 py-1.5 bg-red-600 rounded-md text-xs text-white uppercase hover:bg-red-700 transition shadow-sm">Delete</a>
    </td>
</tr>
```

The `canModify` expression mirrors the server rule. It is true when the post's author username matches `#authentication.name`, the logged-in user, or when `#authorization.expression('hasRole(''ADMIN'')')` reports the user is an admin. That second helper comes from the Thymeleaf Security Extras dialect we added in the authentication tutorial; it evaluates any SpEL security expression from inside the template. The doubled single quotes around `ADMIN` are how you nest a string literal inside an attribute value. Remember to update the empty-state row's `colspan` from `5` to `6` since the table now has six columns.

Apply the same idea to `src/main/resources/templates/posts/show.html` so the detail page only offers Edit to those who can use it. Declare the security namespace on the `<html>` tag, wrap the button group with the same `canModify` calculation, and gate the Edit link:

```html
<div class="flex space-x-3"
     th:with="canModify=${(post.author != null and post.author.username == #authentication.name) or #authorization.expression('hasRole(''ADMIN'')')}">
    <a th:href="@{/posts}"
        class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</a>
    <!-- Only the author or an admin sees the Edit button. -->
    <a th:if="${canModify}" th:href="@{/posts/{id}/edit(id=${post.id})}"
        class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit
        Post</a>
</div>
```

You can also display the author on the detail page by adding a line near the posted date, for example `<span th:if="${post.author != null}" th:text="'By ' + ${post.author.username} + ' · '"></span>`, so readers can see who wrote each post.

## Step 8: Try It Out {#step-8-try-it-out}

This is where the rules come alive. Start the application:

```bash
./mvnw spring-boot:run
```

On startup the `DataInitializer` seeds the admin account. You can confirm it landed in the database:

```sql
SELECT id, username, role FROM users WHERE role = 'ROLE_ADMIN';
```

```
id	username	role
3	admin	ROLE_ADMIN
```

Now exercise the three perspectives. Register a user named `alice2`, log in, and create a post. The post is stamped with her as the author, which you can verify directly:

```
alice create post -> 302 http://localhost:8080/posts
```

```sql
SELECT p.id, p.title, u.username AS author FROM posts p JOIN users u ON u.id = p.author_id;
```

```
id	title	author
1	Alice First Post	alice2
```

The post belongs to `alice2`, set automatically from her session, with no author field anywhere on the form. Next, register a second user named `bob2`, log in as him, and try to touch Alice's post. Every route is refused:

```
bob GET  edit   -> 403
bob POST update -> 403
bob GET  delete -> 403
```

All three return `403 Forbidden`, and the browser shows our friendly access-denied page. This is also where the `@RequestMapping("/403")` detail pays off: the denied `POST update` returns a clean `403` rather than a `405`. If you had mapped `/403` with `@GetMapping`, that line would read `405` instead, because the forwarded `POST` would not match.

Finally, log in as the seeded `admin` and edit the very same post. The admin is not the owner, but the role grants the power to moderate:

```
admin POST update -> 302 http://localhost:8080/posts
```

```sql
SELECT id, title FROM posts WHERE id = 1;
```

```
id	title
1	Edited by Admin
```

The admin's edit went through and the title changed, while Bob's attempts left the post untouched. That is the entire authorization model working end to end: owners and admins succeed, everyone else is stopped.

## Step 9: Update the Test Suite {#step-9-update-the-test-suite}

Turning on method security is exactly the kind of change the authentication tutorial warned about: it breaks controller tests that were written before security mattered. Our old `PostControllerTest` fired plain requests with no authenticated user and no CSRF token, which worked only because the test slice ignored security. Now that we import the real `SecurityConfig`, those requests get redirected to the login page or rejected. We have to teach the tests about security, and we should add cases for the new rules. We will also need Spring Security's test support.

Add the `spring-security-test` dependency to `pom.xml` so we can use `@WithMockUser` and the CSRF helper:

```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-test</artifactId>
    <scope>test</scope>
</dependency>
```

Start with the service test, which only needs a small change because `createPost` now takes an author. In `PostServiceTest.java`, the old test created a post with one argument:

```java
@Test
void shouldGenerateSlugWhenCreatingPost() {
    Post post = new Post();
    post.setTitle("My First Post");
    post.setContent("Hello world");
    post.setStatus("draft");

    when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

    Post saved = postService.createPost(post);

    assertThat(saved.getSlug()).isEqualTo("my-first-post");
    verify(postRepository).save(post);
}
```

The new test passes an author and also asserts it was stamped:

```java
@Test
void shouldGenerateSlugAndStampAuthorWhenCreatingPost() {
    User author = new User();
    author.setUsername("alice");

    Post post = new Post();
    post.setTitle("My First Post");
    post.setContent("Hello world");
    post.setStatus("draft");

    when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

    Post saved = postService.createPost(post, author);

    assertThat(saved.getSlug()).isEqualTo("my-first-post");
    // The author passed into the service must be stamped onto the saved post
    assertThat(saved.getAuthor()).isEqualTo(author);
    verify(postRepository).save(post);
}
```

The repository test needs a similar adjustment because a post now requires a non-null author. In `PostRepositoryTest.java`, the old helper built a post with no owner:

```java
private Post newPost(String title, String slug) {
    Post post = new Post();
    post.setTitle(title);
    post.setSlug(slug);
    post.setContent("Body content for " + title);
    post.setStatus("draft");
    return post;
}
```

The new helper persists a user first and attaches it:

```java
private Post newPost(String title, String slug) {
    // A post now requires an author (author_id is NOT NULL), so we persist a
    // user first and attach it. The username/email are derived from the slug
    // to stay unique across the posts created within a single test.
    User author = new User();
    author.setUsername("author-" + slug);
    author.setEmail(slug + "@example.com");
    author.setPassword("hashed-password");
    author.setRole("ROLE_USER");
    entityManager.persist(author);

    Post post = new Post();
    post.setTitle(title);
    post.setSlug(slug);
    post.setContent("Body content for " + title);
    post.setStatus("draft");
    post.setAuthor(author);
    return post;
}
```

The biggest change is to `PostControllerTest`. We import `SecurityConfig` to activate the real filter chain and method security, include `HomeController` so the `/403` forward resolves, build MockMvc with the `springSecurity()` configurer, and use `@WithMockUser` plus the CSRF post-processor on every request. Here is the new setup, with the key pieces highlighted:

```java
@WebMvcTest({PostController.class, HomeController.class})
@Import(SecurityConfig.class)
class PostControllerTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        // Build MockMvc with the springSecurity() configurer so the filter chain
        // and the @WithMockUser security context are wired together. Without it,
        // every request would be treated as anonymous and redirected to /login.
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @MockitoBean
    private PostService postService;

    @MockitoBean
    private UserRepository userRepository;

    // The bean name must be "postSecurity" so @PreAuthorize("@postSecurity...") resolves it.
    @MockitoBean(name = "postSecurity")
    private PostSecurity postSecurity;
```

Two details in that setup are easy to get wrong and worth calling out. The MockMvc instance must be built with `.apply(springSecurity())`, otherwise the `@WithMockUser` security context never reaches the filter chain and every request is treated as anonymous and redirected to `/login`. And the mocked `PostSecurity` must be registered under the exact bean name `postSecurity` with `@MockitoBean(name = "postSecurity")`, because the `@PreAuthorize` expression resolves it by that name; a default-named mock causes a "No bean named 'postSecurity' available" error at evaluation time.

With that in place, the tests read naturally. Each test declares who is acting with `@WithMockUser`, and POST requests carry `.with(csrf())`. Here are the new authorization cases:

```java
@Test
@WithMockUser(username = "alice")
void storeShouldCreatePostForLoggedInUserAndRedirect() throws Exception {
    User alice = new User();
    alice.setUsername("alice");
    when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));

    mockMvc.perform(post("/posts").with(csrf())
            .param("title", "My New Post")
            .param("content", "Some content")
            .param("status", "draft"))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/posts"))
            .andExpect(flash().attribute("success", "Post created successfully."));

    // The post must be created with alice as the author.
    verify(postService).createPost(any(Post.class), eq(alice));
}

@Test
@WithMockUser(username = "alice")
void updateShouldModifyPostAndRedirectWhenOwner() throws Exception {
    when(postSecurity.isOwner(1L, "alice")).thenReturn(true);

    mockMvc.perform(post("/posts/1").with(csrf())
            .param("title", "Updated Title")
            .param("content", "Updated content")
            .param("status", "publish"))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/posts"))
            .andExpect(flash().attribute("success", "Post updated successfully."));

    verify(postService).updatePost(eq(1L), any(Post.class));
}

@Test
@WithMockUser(username = "bob")
void updateShouldBeForbiddenWhenNotOwner() throws Exception {
    when(postSecurity.isOwner(1L, "bob")).thenReturn(false);

    mockMvc.perform(post("/posts/1").with(csrf())
            .param("title", "Hijacked Title")
            .param("content", "Hijacked content")
            .param("status", "publish"))
            .andExpect(status().isForbidden());

    verify(postService, never()).updatePost(anyLong(), any(Post.class));
}

@Test
@WithMockUser(username = "carol", roles = {"ADMIN"})
void adminCanUpdateAnyPost() throws Exception {
    // carol does not own the post, but hasRole('ADMIN') short-circuits the check.
    when(postSecurity.isOwner(anyLong(), any())).thenReturn(false);

    mockMvc.perform(post("/posts/1").with(csrf())
            .param("title", "Admin Edit")
            .param("content", "Admin content")
            .param("status", "publish"))
            .andExpect(status().is3xxRedirection())
            .andExpect(redirectedUrl("/posts"));

    verify(postService).updatePost(eq(1L), any(Post.class));
}
```

Each case stubs `postSecurity.isOwner(...)` to return whatever the scenario needs, then asserts the outcome. The owner case redirects, the non-owner case returns `403`, and the admin case redirects even though `isOwner` is false, because the role short-circuits the expression. Apply the same owner-versus-forbidden pattern to the edit and delete handlers.

Finally, add a focused unit test for the ownership bean itself. Create `src/test/java/com/qadrlabs/blog/security/PostSecurityTest.java`:

```java
package com.qadrlabs.blog.security;

import com.qadrlabs.blog.model.Post;
import com.qadrlabs.blog.model.User;
import com.qadrlabs.blog.repository.PostRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PostSecurityTest {

    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private PostSecurity postSecurity;

    private Post postOwnedBy(String username) {
        User author = new User();
        author.setUsername(username);
        Post post = new Post();
        post.setId(1L);
        post.setAuthor(author);
        return post;
    }

    @Test
    void isOwnerReturnsTrueWhenUsernameMatchesAuthor() {
        when(postRepository.findById(1L)).thenReturn(Optional.of(postOwnedBy("alice")));

        assertThat(postSecurity.isOwner(1L, "alice")).isTrue();
    }

    @Test
    void isOwnerReturnsFalseWhenUsernameDoesNotMatch() {
        when(postRepository.findById(1L)).thenReturn(Optional.of(postOwnedBy("alice")));

        assertThat(postSecurity.isOwner(1L, "bob")).isFalse();
    }

    @Test
    void isOwnerReturnsFalseWhenPostDoesNotExist() {
        when(postRepository.findById(99L)).thenReturn(Optional.empty());

        assertThat(postSecurity.isOwner(99L, "alice")).isFalse();
    }

    @Test
    void isOwnerReturnsFalseForNullArguments() {
        assertThat(postSecurity.isOwner(null, "alice")).isFalse();
    }
}
```

Run the whole suite:

```bash
./mvnw test
```

```
[INFO] Running com.qadrlabs.blog.service.PostServiceTest
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.958 s -- in com.qadrlabs.blog.service.PostServiceTest
[INFO] Running com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.155 s -- in com.qadrlabs.blog.service.FileStorageServiceTest
[INFO] Running com.qadrlabs.blog.security.PostSecurityTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.020 s -- in com.qadrlabs.blog.security.PostSecurityTest
[INFO] Running com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.949 s -- in com.qadrlabs.blog.controller.AttachmentControllerTest
[INFO] Running com.qadrlabs.blog.controller.PostControllerTest
[INFO] Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.067 s -- in com.qadrlabs.blog.controller.PostControllerTest
[INFO] Running com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.999 s -- in com.qadrlabs.blog.repository.PostRepositoryTest
[INFO] Running com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.961 s -- in com.qadrlabs.blog.BlogApplicationTests
[INFO] Tests run: 37, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

The suite is green again, now at thirty-seven tests. We started at thirty-two, added four `PostSecurity` unit tests, and grew `PostControllerTest` from ten cases to eleven by splitting the old "anyone can edit" assumptions into explicit owner, non-owner, and admin scenarios. Every original test that survived still passes, and the new ones lock in the authorization rules.

## How Spring Method Security Works {#how-method-security-works}

Now that everything passes, it is worth understanding what happens when a request hits a `@PreAuthorize` method, because the flow explains both the behavior we saw and how to extend it. When you annotate a method with `@PreAuthorize` and enable `@EnableMethodSecurity`, Spring wraps the bean in a proxy. Every call to the method first goes through an `AuthorizationManager` that evaluates the SpEL expression against the current `Authentication`.

The expression is evaluated in a context where a few things are available. The `authentication` object is the logged-in principal, so `authentication.name` is the username and `hasRole('ADMIN')` checks its authorities. Method arguments are bound by name, which is why `#id` refers to the `id` parameter of the handler. Beans are reachable with the `@` prefix, so `@postSecurity` resolves the Spring bean named `postSecurity` and lets us call its methods. If the expression returns true, the method runs normally. If it returns false, the `AuthorizationManager` throws an `AccessDeniedException` before the method body executes, which is why a denied request never touches the controller logic or the service.

That `AccessDeniedException` then travels up to Spring Security's `ExceptionTranslationFilter`, which decides what to do with it. For an authenticated user who lacks permission, it invokes the access-denied handler, and because we configured `accessDeniedPage("/403")`, that handler forwards the request to our `/403` page while keeping the `403` status. This is the entire chain behind the behavior we observed: the SpEL check fails, an exception is thrown, the filter catches it, and the user lands on a friendly page with the right status code.

## URL Security vs Method Security {#url-vs-method-security}

This application now uses both styles of authorization, and knowing when to reach for each is a useful mental model. URL security, configured in the `authorizeHttpRequests` block, makes decisions based on the request path and broad attributes like "is the user authenticated" or "does the user have a role." It is perfect for coarse rules: lock everything under `/posts` behind a login, leave `/login` and `/register` open, restrict an `/admin` section to admins. It cannot, however, express a rule like "only if this specific post belongs to you," because at the URL layer the application has not yet loaded the post or run any business logic.

Method security fills that gap. By moving the decision onto the handler method, it gains access to the method arguments and to beans that can hit the database, which is what lets `@PreAuthorize` ask whether the current user owns the exact post identified by `#id`. The trade-off is that method security runs later in the request lifecycle, after routing, so it is slightly more expensive and more granular than a blanket URL rule. The two are not competitors. A healthy application uses URL security for the broad strokes and method security for the fine-grained, data-dependent rules, exactly as we did here: the login wall is a URL rule, and post ownership is a method rule.

## Conclusion {#conclusion}

In this tutorial we closed the gap between authentication and authorization. We gave every post an owner, stamped that owner automatically from the session at creation time, and enforced an "owner or admin" rule on the edit, update, and delete actions with Spring Security's method security. We seeded an administrator, hid actions the current user cannot perform, added a friendly 403 page, and updated the test suite so it proves the rules hold for owners, non-owners, and admins alike.

The key takeaways:

- **Authentication and authorization are different problems.** Logging a user in tells you who they are; it says nothing about what they may do. A post-ownership rule is authorization, and it needs its own layer on top of the login wall.
- **Decide ownership on the server, never from the form.** The author of a new post comes from `Principal.getName()` and the session, resolved to a real `User`. If the form could supply an author id, any user could forge ownership.
- **`@EnableMethodSecurity` plus `@PreAuthorize` expresses data-dependent rules.** The SpEL expression `hasRole('ADMIN') or @postSecurity.isOwner(#id, authentication.name)` reads almost like a sentence, binding the method argument `#id`, the current `authentication`, and a Spring bean referenced by `@postSecurity`.
- **Put non-trivial checks in a bean.** Moving the ownership logic into a `PostSecurity` component keeps the annotation readable and makes the rule unit-testable on its own, separate from any HTTP machinery.
- **Hiding a button is UX, not security.** The conditional Edit and Delete links improve the interface, but the `@PreAuthorize` rule on the server is the only thing that actually stops a forged request.
- **Map the access-denied page for any method.** A denied `POST` is forwarded to the error page as a `POST`, so a `@GetMapping("/403")` answers it with a confusing `405`. Using `@RequestMapping("/403")` lets the page handle both and return a clean `403`.
- **Enabling security breaks old controller tests, and that is expected.** Importing the real `SecurityConfig` means tests need `@WithMockUser`, the CSRF post-processor, and a MockMvc built with `springSecurity()`. A mocked bean used in a SpEL expression must also be registered under its exact bean name.

With ownership and roles in place, the blog finally behaves like a real multi-author platform. A natural next step is to connect the file attachments from the previous tutorial to individual posts through a JPA relationship, so each post can carry its own images and downloads, owned and managed by the same author who wrote it.
