---
title: "Spring Boot 4 CRUD Tutorial: Build a Simple Blog Step by Step"
slug: "spring-boot-4-crud-tutorial-build-a-simple-blog-step-by-step"
category: "Java"
date: "2026-04-05"
status: "published"
---

If you come from a PHP or Laravel background, building a Java web application can feel overwhelming. The ecosystem has a steep learning curve: dependency injection, annotations, JPA entities, repositories, services, controllers, and template engines. There are many layers compared to a framework like Laravel where you can go from route to view in minutes.

Spring Boot simplifies this dramatically. It provides auto-configuration, embedded servers, and sensible defaults so you can focus on writing your application instead of wiring infrastructure. In this tutorial, we will build a complete CRUD blog application using Spring Boot 4, Spring Data JPA, Thymeleaf, and MySQL. By the end, you will understand the standard Spring Boot project structure and be able to create, read, update, and delete records through a web interface.


## Overview {#overview}

We will build a blog post management system with full CRUD functionality. The application uses a layered architecture: an Entity defines the database structure, a Repository handles data access, a Service contains business logic, a Controller handles HTTP requests, and Thymeleaf templates render the HTML views.

### What You'll Build

- A post listing page with a table showing all posts.
- A create form with server-side validation.
- A detail page showing a single post.
- An edit form with pre-filled data.
- A delete function with confirmation.
- Flash messages for success and error feedback.

### What You'll Learn

- How to generate a Spring Boot 4 project using Spring Initializr.
- How to define a JPA entity with annotations.
- How to create a repository interface for data access.
- How to build a service layer for business logic.
- How to write a controller with `@GetMapping` and `@PostMapping`.
- How to use Thymeleaf templates for server-rendered HTML.
- How to handle form validation with `@Valid` and `BindingResult`.
- How to use flash attributes for success messages across redirects.

### What You'll Need

- Java 17 or higher (Java 21 recommended).
- Maven or Gradle (this tutorial uses Maven).
- MySQL or another supported database.
- An IDE (IntelliJ IDEA, Eclipse, or VS Code with Java extensions).
- Basic understanding of Java and object-oriented programming.


## Step 1: Generate the Project {#step-1-generate-project}

Go to [Spring Initializr](https://start.spring.io/) and configure the project:

- **Project:** Maven
- **Language:** Java
- **Spring Boot:** 4.0.5 (or the latest stable 4.x version)
- **Group:** com.qadrlabs
- **Artifact:** blog
- **Package name:** com.qadrlabs.blog
- **Packaging:** Jar
- **Java:** 17 (or 21)

Add the following dependencies:

- **Spring Web** (for building web applications with Spring MVC)
- **Spring Data JPA** (for database access with JPA/Hibernate)
- **MySQL Driver** (for connecting to MySQL)
- **Thymeleaf** (for server-side HTML templates)
- **Validation** (for bean validation with `@NotBlank`, `@Size`, etc.)
- **Spring Boot DevTools** (for automatic restart during development)

Click **Generate** to download the project. Extract the ZIP file and open it in your IDE.

### Project Structure

> **Important Note:** Ensure your `BlogApplication.java` is inside the `com.qadrlabs.blog` package directory (and has `package com.qadrlabs.blog;` at the top). If it is inadvertently placed at the root `blog` package while your controllers are inside `com.qadrlabs.blog.controller`, Spring's Component Scan won't be able to find and register your controllers, leading to 404 errors!

After extraction, the project structure looks like this:

```
blog/
  src/
    main/
      java/com/qadrlabs/blog/
        BlogApplication.java
      resources/
        application.properties
        templates/
        static/
    test/
      java/com/qadrlabs/blog/
        BlogApplicationTests.java
  pom.xml
```

The `pom.xml` file contains the project dependencies. The key dependencies are:

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-devtools</artifactId>
        <scope>runtime</scope>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```


## Step 2: Configure the Database {#step-2-configure-database}

Open `src/main/resources/application.properties` and add the database configuration:

```properties
spring.application.name=blog

# Database
spring.datasource.url=jdbc:mysql://localhost:3306/db_spring_blog?createDatabaseIfNotExist=true
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA / Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
```

Let's explain each setting:

**`spring.datasource.url`**: The JDBC connection URL. The `createDatabaseIfNotExist=true` parameter tells MySQL to create the database automatically if it does not exist yet.

**`spring.jpa.hibernate.ddl-auto=update`**: Hibernate will automatically create or update the database tables based on your entity classes. In production, you would use a migration tool like Flyway or Liquibase instead.

**`spring.jpa.show-sql=true`**: Logs all SQL queries to the console. Useful for debugging during development.


## Step 3: Create the Post Entity {#step-3-create-entity}

The entity class maps to a database table. Create the file `src/main/java/com/qadrlabs/blog/model/Post.java`:

```java
package com.qadrlabs.blog.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "posts")
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    @Column(nullable = false)
    private String title;

    @Size(max = 255, message = "Slug must not exceed 255 characters")
    @Column(nullable = false, unique = true)
    private String slug;

    @NotBlank(message = "Content is required")
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @NotBlank(message = "Status is required")
    @Column(nullable = false)
    private String status;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    // Default constructor (required by JPA)
    public Post() {
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
```

Here is what each annotation does:

**`@Entity`**: Marks this class as a JPA entity. Hibernate will map it to a database table.

**`@Table(name = "posts")`**: Specifies the table name. Without this, Hibernate would use the class name ("Post") as the table name.

**`@Id` and `@GeneratedValue`**: Marks `id` as the primary key with auto-increment.

**`@NotBlank` and `@Size`**: Validation constraints from the Bean Validation API. These are checked when we use `@Valid` in the controller. Notice we omitted `@NotBlank` on the `slug` field! Because the slug isn't part of our form inputs, adding `@NotBlank` would cause the submission to instantly fail. Our Service layer will automatically generate it.

**`@Column`**: Configures the column. `nullable = false` adds a NOT NULL constraint. `columnDefinition = "TEXT"` uses the MySQL TEXT type instead of the default VARCHAR(255).

**`@CreationTimestamp` and `@UpdateTimestamp`**: Hibernate automatically sets these timestamps when a record is created or updated.

**Default constructor**: JPA requires a no-argument constructor. Without it, Hibernate cannot instantiate the entity.


## Step 4: Create the Repository {#step-4-create-repository}

The repository interface provides data access methods. Spring Data JPA automatically generates the implementation. Create `src/main/java/com/qadrlabs/blog/repository/PostRepository.java`:

```java
package com.qadrlabs.blog.repository;

import com.qadrlabs.blog.model.Post;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostRepository extends JpaRepository<Post, Long> {

    List<Post> findAllByOrderByCreatedAtDesc();
}
```

By extending `JpaRepository<Post, Long>`, you get the following methods for free (no implementation needed): `findAll()`, `findById(Long id)`, `save(Post post)`, `deleteById(Long id)`, `count()`, and many more.

The `findAllByOrderByCreatedAtDesc()` method is a custom query derived from the method name. Spring Data JPA parses the method name and generates the SQL: `SELECT * FROM posts ORDER BY created_at DESC`. No `@Query` annotation needed.


## Step 5: Create the Service {#step-5-create-service}

The service layer sits between the controller and the repository. It contains business logic and keeps the controller thin. Create `src/main/java/com/qadrlabs/blog/service/PostService.java`:

```java
package com.qadrlabs.blog.service;

import com.qadrlabs.blog.model.Post;
import com.qadrlabs.blog.repository.PostRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PostService {

    private final PostRepository postRepository;

    public PostService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    public List<Post> getAllPosts() {
        return postRepository.findAllByOrderByCreatedAtDesc();
    }

    public Post getPostById(Long id) {
        return postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));
    }

    public Post createPost(Post post) {
        post.setSlug(generateSlug(post.getTitle()));
        return postRepository.save(post);
    }

    public Post updatePost(Long id, Post postDetails) {
        Post post = getPostById(id);
        post.setTitle(postDetails.getTitle());
        post.setSlug(generateSlug(postDetails.getTitle()));
        post.setContent(postDetails.getContent());
        post.setStatus(postDetails.getStatus());
        return postRepository.save(post);
    }

    public void deletePost(Long id) {
        Post post = getPostById(id);
        postRepository.delete(post);
    }

    private String generateSlug(String title) {
        return title.toLowerCase()
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-")
                .replaceAll("^-|-$", "");
    }
}
```

**Constructor injection**: The `PostRepository` is injected via the constructor. Spring automatically resolves the dependency. This is the recommended injection pattern (over `@Autowired` on fields) because it makes the dependency explicit and the class easier to test.

**`getPostById()`**: Uses `findById()` which returns an `Optional<Post>`. The `orElseThrow()` call unwraps the value or throws an exception if the post does not exist.

**`generateSlug()`**: Converts the title to a URL-friendly slug. "My First Post" becomes "my-first-post".


## Step 6: Create the Controller {#step-6-create-controller}

The controller handles HTTP requests and returns views. Create `src/main/java/com/qadrlabs/blog/controller/PostController.java`:

```java
package com.qadrlabs.blog.controller;

import com.qadrlabs.blog.model.Post;
import com.qadrlabs.blog.service.PostService;
import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping
    public String index(Model model) {
        model.addAttribute("posts", postService.getAllPosts());
        return "posts/index";
    }

    @GetMapping("/create")
    public String create(Model model) {
        model.addAttribute("post", new Post());
        return "posts/create";
    }

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

    @GetMapping("/{id}")
    public String show(@PathVariable Long id, Model model) {
        model.addAttribute("post", postService.getPostById(id));
        return "posts/show";
    }

    @GetMapping("/{id}/edit")
    public String edit(@PathVariable Long id, Model model) {
        model.addAttribute("post", postService.getPostById(id));
        return "posts/edit";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id,
                         @Valid @ModelAttribute("post") Post post,
                         BindingResult bindingResult,
                         RedirectAttributes redirectAttributes) {
        if (bindingResult.hasErrors()) {
            return "posts/edit";
        }

        postService.updatePost(id, post);
        redirectAttributes.addFlashAttribute("success", "Post updated successfully.");
        return "redirect:/posts";
    }

    @GetMapping("/{id}/delete")
    public String destroy(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        postService.deletePost(id);
        redirectAttributes.addFlashAttribute("success", "Post deleted successfully.");
        return "redirect:/posts";
    }
}
```

Let's examine the key patterns:

**`@Controller`**: Marks this class as a Spring MVC controller that returns view names (not JSON). For REST APIs, you would use `@RestController` instead.

**`@RequestMapping("/posts")`**: Sets the base URL path for all methods in this controller.

**`@GetMapping` and `@PostMapping`**: Map HTTP GET and POST requests to specific methods. `@GetMapping` is for displaying pages, `@PostMapping` is for processing form submissions.

**`Model model`**: The `Model` object is a map of data passed to the Thymeleaf template. `model.addAttribute("posts", ...)` makes the data available as `${posts}` in the template.

**`@Valid @ModelAttribute("post") Post post`**: The `@ModelAttribute` binds form fields to the `Post` object automatically. `@Valid` triggers the validation constraints we defined on the entity (`@NotBlank`, `@Size`).

**`BindingResult bindingResult`**: Contains validation errors. If `bindingResult.hasErrors()` is true, we return the form template so the user can see and fix the errors. This parameter must come immediately after the `@Valid` parameter.

**`RedirectAttributes redirectAttributes`**: Used to pass flash messages across redirects. `addFlashAttribute()` stores the message in the session for one request, similar to `session()->flash()` in Laravel.

**`return "posts/index"`**: Returns the view name. Spring resolves this to `src/main/resources/templates/posts/index.html`.

**`return "redirect:/posts"`**: Sends a 302 redirect to the `/posts` URL.


## Step 7: Create the Thymeleaf Templates {#step-7-create-templates}

Create the directory structure:

```
src/main/resources/templates/posts/
```

### Index Page

Create `src/main/resources/templates/posts/index.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
            <a th:href="@{/posts/create}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                Create New Post
            </a>
        </div>

        <div th:if="${success}" class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-6">
            <span th:text="${success}"></span>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">No</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
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
                    <tr th:if="${#lists.isEmpty(posts)}">
                        <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No posts found.</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Spring Boot at qadrlabs.com</a>
    </div>
</body>
</html>
```

Let's compare the Thymeleaf syntax with Blade (Laravel):

| Purpose | Blade (Laravel) | Thymeleaf (Spring Boot) |
|---------|-----------------|-------------------------|
| Print variable | `{{ $post->title }}` | `th:text="${post.title}"` |
| Loop | `@foreach($posts as $post)` | `th:each="post : ${posts}"` |
| Conditional | `@if($post->status == 'publish')` | `th:if="${post.status == 'publish'}"` |
| URL generation | `{{ route('posts.show', $post) }}` | `th:href="@{/posts/{id}(id=${post.id})}"` |
| Empty check | `@forelse ... @empty` | `th:if="${#lists.isEmpty(posts)}"` |
| Flash message | `session('success')` | `${success}` (from `addFlashAttribute`) |

### Create Page

Create `src/main/resources/templates/posts/create.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Post</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Create Post</h1>
            <a th:href="@{/posts}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>

        <form th:action="@{/posts}" th:object="${post}" method="post" class="space-y-6">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" th:field="*{title}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('title')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('title')}" th:errors="*{title}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea th:field="*{content}" rows="8" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y"
                          th:classappend="${#fields.hasErrors('content')} ? 'border-red-500' : ''"></textarea>
                <p th:if="${#fields.hasErrors('content')}" th:errors="*{content}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select th:field="*{status}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition"
                        th:classappend="${#fields.hasErrors('status')} ? 'border-red-500' : ''">
                    <option value="">Select status</option>
                    <option value="draft">Draft</option>
                    <option value="publish">Publish</option>
                </select>
                <p th:if="${#fields.hasErrors('status')}" th:errors="*{status}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Submit Post
                </button>
            </div>
        </form>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Spring Boot at qadrlabs.com</a>
    </div>
</body>
</html>
```

Key Thymeleaf form patterns:

**`th:object="${post}"`**: Binds the form to the `Post` object passed from the controller. All `th:field` references inside this form use `*{...}` (selection variable) syntax to refer to properties of this object.

**`th:field="*{title}"`**: Binds the input to the `title` property. This handles both setting the `name` attribute and pre-filling the value (for edit forms or after validation errors).

**`th:errors="*{title}"`**: Displays the validation error message for the `title` field.

**`th:classappend`**: Conditionally adds CSS classes. If the field has errors, we add `border-red-500` to highlight it.

### Show Page

Create `src/main/resources/templates/posts/show.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title th:text="${post.title}">Post Title</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-start mb-6 pb-6 border-b border-gray-200">
            <div>
                <h1 class="text-3xl font-bold text-gray-900 mb-2" th:text="${post.title}"></h1>
                <div class="flex items-center space-x-4 text-sm text-gray-500">
                    <span th:text="${post.slug}"></span>
                    <span th:if="${post.status == 'publish'}" class="px-2 py-0.5 text-xs font-semibold rounded-full bg-green-100 text-green-800">Publish</span>
                    <span th:if="${post.status == 'draft'}" class="px-2 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-800">Draft</span>
                </div>
            </div>
            <div class="flex space-x-3">
                <a th:href="@{/posts}" class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</a>
                <a th:href="@{/posts/{id}/edit(id=${post.id})}" class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit Post</a>
            </div>
        </div>

        <div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap" th:text="${post.content}"></div>

        <div class="mt-10 pt-6 border-t border-gray-100 text-sm text-gray-500">
            <span th:text="'Posted: ' + ${#temporals.format(post.createdAt, 'MMM dd, yyyy')}"></span>
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Spring Boot at qadrlabs.com</a>
    </div>
</body>
</html>
```

**`#temporals.format()`**: Thymeleaf's temporal utility for formatting `LocalDateTime` objects. `'MMM dd, yyyy'` produces output like "Apr 04, 2026".

### Edit Page

Create `src/main/resources/templates/posts/edit.html`:

```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Post</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Edit Post</h1>
            <a th:href="@{/posts}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>

        <form th:action="@{/posts/{id}(id=${post.id})}" th:object="${post}" method="post" class="space-y-6">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" th:field="*{title}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition"
                       th:classappend="${#fields.hasErrors('title')} ? 'border-red-500' : ''">
                <p th:if="${#fields.hasErrors('title')}" th:errors="*{title}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea th:field="*{content}" rows="8" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y"
                          th:classappend="${#fields.hasErrors('content')} ? 'border-red-500' : ''"></textarea>
                <p th:if="${#fields.hasErrors('content')}" th:errors="*{content}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select th:field="*{status}" class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition"
                        th:classappend="${#fields.hasErrors('status')} ? 'border-red-500' : ''">
                    <option value="">Select status</option>
                    <option value="draft">Draft</option>
                    <option value="publish">Publish</option>
                </select>
                <p th:if="${#fields.hasErrors('status')}" th:errors="*{status}" class="text-red-500 text-sm mt-1"></p>
            </div>

            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Update Post
                </button>
            </div>
        </form>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Spring Boot at qadrlabs.com</a>
    </div>
</body>
</html>
```

The edit form is identical to the create form with two differences: the `th:action` points to `/posts/{id}` (the update route), and the `th:field` directives automatically pre-fill the form with the existing post data because `th:object="${post}"` is bound to the existing post from the controller.


## Step 8: Add a Home Redirect {#step-8-add-home-redirect}

Open `src/main/java/com/qadrlabs/blog/controller/PostController.java` and add a root redirect method. You can add this as a separate controller or add it to the existing one. The simplest approach is to create a small `HomeController`:

Create `src/main/java/com/qadrlabs/blog/controller/HomeController.java`:

```java
package com.qadrlabs.blog.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "redirect:/posts";
    }
}
```

This redirects the root URL (`/`) to the posts listing page.


## Step 9: Try It Out {#step-9-try-it-out}

Run the application from your IDE or from the terminal:

```bash
./mvnw spring-boot:run
```

Open your browser and navigate to `http://localhost:8080/posts`. You should see the posts index page with an empty table.

### Test Creating a Post

Click **Create New Post**. Fill in the title, content, and select a status. Click **Submit Post**. You should be redirected to the index page with a green success message, and your new post should appear in the table.

### Test Validation

Try submitting the create form with empty fields. You should see validation error messages below each field. The title field should show "Title is required" and the content field should show "Content is required".

### Test Viewing a Post

Click **View** on any post. You should see the full post detail page with the title, slug, status badge, content, and created date.

### Test Editing a Post

Click **Edit** on any post. The form should be pre-filled with the existing data. Change the title and click **Update Post**. You should be redirected back to the index page with a success message and the updated title.

### Test Deleting a Post

Click **Delete** on any post. A browser confirmation dialog should appear. Click OK. The post should disappear from the table with a success message.


## Spring Boot vs Laravel: Architecture Comparison {#spring-boot-vs-laravel}

If you are coming from Laravel, here is how the Spring Boot architecture maps to what you already know:

| Concept | Laravel | Spring Boot |
|---------|---------|-------------|
| Project generator | `composer create-project` | Spring Initializr (start.spring.io) |
| Configuration | `.env` file | `application.properties` or `application.yml` |
| Database model | Eloquent Model | JPA Entity (`@Entity`) |
| Mass assignment | `#[Fillable]` attribute | Setter methods on entity |
| Validation | Form Request or `$request->validate()` | `@Valid` + Bean Validation annotations |
| Data access | Eloquent (built into model) | Repository interface (separate layer) |
| Business logic | Controller (or Service class) | Service class (separate layer) |
| HTTP handling | Controller | Controller (`@Controller`) |
| Template engine | Blade (`.blade.php`) | Thymeleaf (`.html`) |
| URL generation | `route('posts.index')` | `@{/posts}` |
| Flash messages | `session()->flash()` | `redirectAttributes.addFlashAttribute()` |
| Database migration | Migration files + `php artisan migrate` | `ddl-auto=update` or Flyway/Liquibase |
| Package manager | Composer | Maven or Gradle |
| Dev server | `php artisan serve` | `./mvnw spring-boot:run` |

The biggest structural difference is the **layered architecture**. In Laravel, the model handles both data structure and data access (via Eloquent). In Spring Boot, these are separated: the Entity defines the structure, the Repository handles data access, and the Service contains business logic. This separation adds more files but makes each layer independently testable.


## Conclusion {#conclusion}

In this tutorial, we built a complete CRUD blog application using Spring Boot 4, Spring Data JPA, Thymeleaf, and MySQL. We created an entity, a repository, a service, a controller, and four Thymeleaf templates.

Here are the key takeaways:

- **Spring Initializr generates a ready-to-run project.** Select your dependencies, download the ZIP, and you have a working Spring Boot application with all the configuration in place.
- **JPA entities map Java classes to database tables.** Annotations like `@Entity`, `@Table`, `@Column`, and `@Id` replace migration files. With `ddl-auto=update`, Hibernate creates and updates tables automatically.
- **Spring Data JPA eliminates boilerplate data access code.** Extend `JpaRepository` and you get `findAll()`, `findById()`, `save()`, `deleteById()` for free. Custom queries can be derived from method names.
- **The service layer keeps controllers thin.** Business logic (like slug generation) lives in the service. The controller only handles HTTP concerns (receiving requests, calling the service, returning views).
- **Bean Validation integrates with Thymeleaf forms.** `@NotBlank` and `@Size` on the entity, `@Valid` in the controller, and `th:errors` in the template work together to display field-level error messages.
- **`RedirectAttributes` provides flash messages.** Similar to Laravel's `session()->flash()`, flash attributes survive one redirect and are automatically available in the next view.
- **Thymeleaf uses `th:` attributes instead of special syntax.** Where Blade uses `{{ }}` and `@foreach`, Thymeleaf uses `th:text`, `th:each`, `th:if`, and `th:field`. The HTML stays valid even without the server processing it.
- **Constructor injection is the recommended pattern.** Instead of `@Autowired` on fields, inject dependencies via the constructor. This makes the class easier to test and the dependencies explicit.