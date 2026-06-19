## 1. Before You Begin

CodeIgniter 3 is a lightweight PHP framework that follows the MVC (Model-View-Controller) pattern. Created by EllisLab and now maintained by the British Columbia Institute of Technology, it is known for its small footprint, excellent documentation, and near-zero configuration. While CodeIgniter 4 is the newer version, CI3 remains widely used in production systems, legacy applications, and university courses.

This lesson has no code. The focus is on understanding what CI3 is, how MVC works, and what you will build.

### What You'll Learn

- ✅ What CodeIgniter 3 is and why it matters
- ✅ The MVC pattern: Model, View, Controller
- ✅ How CI3 compares to Laravel and CI4
- ✅ What you will build in this course
- ✅ The course roadmap

### What You'll Need

- Basic PHP knowledge (variables, arrays, functions, forms, MySQL)
- No prior framework experience required

---

## 2. What Is MVC? {#what-is-mvc}

MVC separates an application into three layers:

**Model** talks to the database. It contains SQL queries (via Query Builder) and data logic. One model per table.

**View** displays HTML. It receives data from the controller and renders it. No database queries, no business logic. Just HTML with embedded PHP for displaying data.

**Controller** is the middleman. It receives the HTTP request (URL), calls the model to get data, and loads the view to display it.

```text
Browser request (/posts)
    |
    v
Controller (Posts.php)
    |-- calls --> Model (Post_model.php) --> Database
    |<-- data --
    |-- loads --> View (posts/index.php) --> HTML
    |
    v
Browser response (HTML page)
```

This diagram shows the complete request lifecycle in a CI3 application. When a user visits `/posts` in their browser, the request first arrives at the **Controller**. The Controller then calls the **Model** to retrieve data from the database, receives that data back, and finally passes it to the **View**. The View uses the data to render an HTML page, which is sent back to the browser as the response. Notice that the Model and View never talk to each other directly — the Controller always acts as the bridge between them.

---

## 3. CI3 vs Laravel vs CI4 {#comparison}

CI3 is simpler and lighter. Laravel is more powerful but heavier. CI4 is the modernized version of CI3 with namespaces, CLI, and better architecture.

| Feature | CodeIgniter 3 | CodeIgniter 4 | Laravel |
|---------|---------------|---------------|---------|
| PHP Version | 5.6+ | 7.4+ | 8.1+ |
| Architecture | MVC | MVC | MVC |
| ORM | Query Builder | Query Builder + Entity | Eloquent |
| Template Engine | Native PHP | Native PHP | Blade |
| CLI Tool | None | spark | artisan |
| Routing | routes.php | routes.php | web.php |
| Package Manager | None | Composer | Composer |
| Migration | Manual SQL | Built-in | Built-in |
| Size | ~2 MB | ~5 MB | ~60 MB |

---

## 4. What You Will Build {#what-you-will-build}

A blog application with: post listing, create form, edit form, delete, form validation, flash messages, template layout, and simple authentication. The same features as the Laravel and CI4 courses on qadrlabs.com.

---

## 5. Course Roadmap {#roadmap}

The following roadmap outlines the step-by-step journey you will take to build the complete blog application from scratch.

**L1-L2:** What CI3 is, installation, project structure.
**L3-L4:** Controllers, views, routing.
**L5-L6:** Database configuration, models, Query Builder.
**L7-L8:** Read and create (with validation).
**L9-L10:** Update and delete.
**L11-L12:** Template layout and authentication.
**L13-L14:** Testing and next steps.

---

## Next Up - Lesson 2

CodeIgniter 3 is a lightweight, simple PHP framework with the MVC pattern. Models handle data, views handle HTML, controllers handle requests. It is the easiest entry point to PHP frameworks before learning CI4 or Laravel.

In Lesson 2, you will install CodeIgniter 3 and explore the project structure.