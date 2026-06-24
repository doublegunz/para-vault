## 1. Before You Begin

You can technically build an entire web page using nothing but `<div>` elements. A `<div>` is a generic container that carries no inherent meaning - it is just a box. The problem is that when the browser, a search engine, or a screen reader encounters a page full of `<div>` elements, it has no way of knowing which box is the site header, which is the main article, and which is the sidebar. The page works visually, but its structure is invisible to machines.

Semantic HTML solves this by providing purpose-built elements. `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, and `<footer>` each communicate a specific meaning about the content they contain. Search engines use these signals to index pages more accurately. Screen readers use them to let users navigate directly to the main content or the navigation bar, skipping over repeated sections. And future developers who read your code can instantly understand the page structure without having to read every line.

### What You'll Build

You will create a blog-style page called `semantic.html` that uses every major semantic element to build a complete layout with a site header, navigation bar, main content area with articles, a sidebar, and a footer.

### What You'll Learn

- ✅ Semantic elements: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`
- ✅ The difference between `<div>` and semantic elements
- ✅ How to structure a complete page layout
- ✅ When to use `<div>` vs a semantic element
- ✅ The `<span>` element for inline grouping

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 5 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder in the Explorer panel, select **New Folder**, type `lesson-06`, and press Enter.

---

## 3. Semantic Page Structure

The standard structure of a semantic HTML page follows a predictable pattern: a header at the top, a navigation bar, a main content area that may include sections and articles alongside a sidebar, and a footer at the bottom. This pattern is used by the vast majority of websites on the internet.

### Step 1: Create the File

Right-click on the `lesson-06` folder in VS Code, select **New File**, type `semantic.html`, and press Enter.

### Step 2: Write the Code

Add the following to `semantic.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Semantic HTML</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; color: #333; }
        header { background: #1e293b; color: white; padding: 16px 20px; }
        nav { background: #334155; padding: 10px 20px; }
        nav a { color: #93c5fd; margin-right: 15px; text-decoration: none; }
        main { max-width: 900px; margin: 20px auto; padding: 0 20px; display: flex; gap: 20px; }
        .content { flex: 3; }
        aside { flex: 1; background: #f8fafc; padding: 15px; border-radius: 8px; }
        section { margin-bottom: 24px; }
        article { background: #fff; border: 1px solid #e2e8f0; padding: 16px; margin-bottom: 12px; border-radius: 6px; }
        footer { background: #1e293b; color: #94a3b8; text-align: center; padding: 16px; margin-top: 40px; }
    </style>
</head>
<body>

    <header>
        <h1>My Blog</h1>
    </header>

    <nav>
        <a href="#">Home</a>
        <a href="#">Articles</a>
        <a href="#">About</a>
        <a href="#">Contact</a>
    </nav>

    <main>
        <div class="content">
            <section>
                <h2>Latest Articles</h2>

                <article>
                    <h3>Getting Started with HTML</h3>
                    <p>HTML is the foundation of every website. Learn the basics in this guide.</p>
                    <small>Posted on April 1, 2026</small>
                </article>

                <article>
                    <h3>CSS Box Model Explained</h3>
                    <p>Understanding the box model is crucial for CSS layout.</p>
                    <small>Posted on March 28, 2026</small>
                </article>
            </section>

            <section>
                <h2>About This Site</h2>
                <p>This is a blog about <span style="color:#2563eb; font-weight:bold">web development</span> and programming.</p>
            </section>
        </div>

        <aside>
            <h3>Categories</h3>
            <ul>
                <li>HTML</li>
                <li>CSS</li>
                <li>JavaScript</li>
            </ul>

            <h3>About Me</h3>
            <p>I am a web developer from Indonesia.</p>
        </aside>
    </main>

    <footer>
        <p>Copyright 2026 My Blog. All rights reserved.</p>
    </footer>

</body>
</html>
```

`<header>` marks the introductory section of the page or of a specific section. Here it contains the blog's site title. A page can have multiple `<header>` elements - one for the page itself, and one inside each `<article>` for the article's own header.

`<nav>` marks a group of navigation links. Browsers and screen readers treat this element as a navigation landmark, allowing keyboard users to jump directly to the navigation menu. Not every group of links needs to be inside `<nav>` - only major navigation blocks, like the site's primary menu or breadcrumbs.

`<main>` marks the primary content of the page. There must be exactly one `<main>` per page, and it should not contain content that repeats across pages, such as the site header or footer. Screen readers allow users to jump directly to `<main>`, skipping past repeated navigation.

`<section>` groups related content under a common theme. Every `<section>` should have a heading (`<h2>` through `<h6>`) that describes what the section contains. If a grouping of content does not have its own heading, a `<div>` is more appropriate.

`<article>` marks a self-contained piece of content that could be republished independently. Blog posts, news articles, and forum entries are all good candidates for `<article>`. An article contains its own heading, content, and metadata.

`<aside>` marks content that is related to the main content but is not part of the primary flow. Sidebars, pull quotes, and related link lists are typical uses. Browsers and screen readers treat `<aside>` as a complementary landmark.

`<footer>` marks closing content for the page or for a specific section. At the page level, it typically contains copyright notices, legal links, and secondary navigation.

`<span>` is the inline equivalent of `<div>`. It has no semantic meaning and is used solely as a hook for CSS styling within a line of text, without breaking the flow of the surrounding content.

### Step 3: Save and View

Press **Ctrl+S** and open with Live Server. You will see a styled two-column layout with a dark header, a navigation bar, a main content area with article cards, a sidebar, and a footer.

---

## 4. Semantic Elements Explained

Knowing which element to use is a matter of understanding what each one means and applying that meaning consistently across your pages.

| Element | Purpose | When to Use |
|---------|---------|-------------|
| `<header>` | Introductory content | Site header, article header |
| `<nav>` | Navigation links | Main menu, breadcrumbs, pagination |
| `<main>` | Primary content | One per page, for unique page content |
| `<section>` | Thematic grouping | Group related content that has a heading |
| `<article>` | Self-contained content | Blog posts, news items, comments |
| `<aside>` | Secondary related content | Sidebars, pull quotes, related links |
| `<footer>` | Closing content | Copyright, legal links, contact info |
| `<div>` | Generic block container | When no semantic meaning applies |
| `<span>` | Generic inline container | Styling a word or phrase within text |

### div vs Semantic Elements

The visual output of `<div>` and semantic elements is identical, because both are generic containers by default. The difference is in the meaning they communicate to non-visual tools.

```html
<!-- Without semantics: works visually but conveys no meaning -->
<div class="header">...</div>
<div class="nav">...</div>
<div class="content">...</div>
<div class="sidebar">...</div>
<div class="footer">...</div>

<!-- With semantics: the same layout but now meaningful -->
<header>...</header>
<nav>...</nav>
<main>...</main>
<aside>...</aside>
<footer>...</footer>
```

Both examples produce the same visual result in the browser. However, a screen reader navigating the semantic version can announce "navigation landmark" when it reaches `<nav>`, and a search engine can identify the `<main>` content as the primary subject of the page. With `<div>`, neither tool has any basis for making those distinctions.

---

## 5. Fix the Errors in Your Code

Three mistakes appear frequently when developers first learn to use semantic elements. Each one either misuses an element against its intended purpose or violates a structural rule.

**Error 1: Using more than one `<main>` element per page.**

`<main>` is designed to identify the single, unique primary content area of the page. Using it more than once is invalid HTML and prevents screen readers from correctly identifying the main content.

```html
<!-- Wrong: two main elements on one page -->
<main>Content 1</main>
<main>Content 2</main>

<!-- Correct: exactly one main per page -->
<main>
    <section>
        <h2>Content 1</h2>
        <p>...</p>
    </section>
    <section>
        <h2>Content 2</h2>
        <p>...</p>
    </section>
</main>
```

If you have multiple distinct areas of content, place them as separate `<section>` or `<article>` elements inside a single `<main>`. `<main>` is the outer boundary for all of it, not a repeating container.

**Error 2: Using `<section>` without a heading.**

A `<section>` element represents a thematic grouping of content, and a thematic group by definition has a subject - which should be expressed by a heading. A `<section>` without a heading is not truly a named section; it is just a grouping, for which `<div>` is the appropriate element.

```html
<!-- Wrong: section with no heading -->
<section>
    <p>Some text without a heading.</p>
</section>

<!-- Correct: section has a descriptive heading -->
<section>
    <h2>About This Project</h2>
    <p>Some text with a heading above.</p>
</section>
```

If your grouped content does not have or need a heading, replace `<section>` with `<div>`. Reserve `<section>` for content that has a clearly identifiable topic expressed by a heading element.

**Error 3: Placing navigation links in a footer without wrapping them in `<nav>`.**

It is valid to have navigation links inside a `<footer>`, but those links should still be wrapped in a `<nav>` element so that screen readers can identify them as a navigation landmark.

```html
<!-- Wrong: links in footer with no nav wrapper -->
<footer>
    <a href="/">Home</a>
    <a href="/about">About</a>
</footer>

<!-- Correct: footer navigation wrapped in nav -->
<footer>
    <nav>
        <a href="/">Home</a>
        <a href="/about">About</a>
    </nav>
    <p>Copyright 2026</p>
</footer>
```

A footer often contains two things: navigational links (which belong in `<nav>`) and non-navigational content like copyright notices (which belong directly in `<footer>`). Structuring them this way allows assistive tools to distinguish between the two.

---

## 6. Exercises

**Exercise 1:** Create `blog.html`. Build a complete blog page with `<header>` containing the site name, `<nav>` with four links (Home, Articles, About, Contact), `<main>` containing two `<article>` elements (each with an `<h2>` title, a date in `<small>`, and a brief excerpt paragraph), and a `<footer>` with a copyright notice.

**Exercise 2:** Create `portfolio-semantic.html`. Build a portfolio page with `<header>`, `<nav>`, and `<main>` containing three sections: a `<section>` for "About Me" with a paragraph, a `<section>` for "Projects" with three `<article>` elements each describing one project, and an `<aside>` for "Skills" containing an unordered list.

**Exercise 3:** Take the `forms.html` file from Lesson 5 and restructure it using semantic elements. Add a `<header>` with the site name, wrap the form in `<main>` then `<section>`, and add a `<footer>` with a copyright notice. The form content itself should remain unchanged.

---

## 7. Solutions

**Solution for Exercise 1:**

Create a new file called `blog.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tech Blog</title>
</head>
<body>
    <header>
        <h1>Tech Blog</h1>
    </header>

    <nav>
        <a href="#">Home</a> |
        <a href="#">Articles</a> |
        <a href="#">About</a> |
        <a href="#">Contact</a>
    </nav>

    <main>
        <article>
            <h2>Understanding Flexbox</h2>
            <small>April 2, 2026</small>
            <p>Flexbox is a powerful CSS layout model that makes it easy to align and distribute items in one direction.</p>
        </article>

        <article>
            <h2>CSS Grid vs Flexbox</h2>
            <small>March 30, 2026</small>
            <p>When should you use CSS Grid instead of Flexbox? The answer depends on whether your layout is one-dimensional or two-dimensional.</p>
        </article>
    </main>

    <footer>
        <p>Copyright 2026 Tech Blog. All rights reserved.</p>
    </footer>
</body>
</html>
```

Each blog post is wrapped in its own `<article>` element because each post is a self-contained piece of content that could be syndicated or linked to independently. The `<h2>` inside each article serves as the article's title. Using `<h2>` rather than `<h1>` is correct here because the page's `<h1>` is already used for the site name in the `<header>`, establishing the document's top-level heading.

**Solution for Exercise 2:**

Create a new file called `portfolio-semantic.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Portfolio</title>
</head>
<body>
    <header>
        <h1>Budi Santoso - Portfolio</h1>
    </header>

    <nav>
        <a href="#">About</a> |
        <a href="#">Projects</a> |
        <a href="#">Contact</a>
    </nav>

    <main>
        <section>
            <h2>About Me</h2>
            <p>I am a web developer from Bandung, Indonesia. I specialize in building clean, accessible HTML and CSS layouts.</p>
        </section>

        <section>
            <h2>Projects</h2>

            <article>
                <h3>Personal Blog</h3>
                <p>A fully responsive blog built with HTML, CSS, and vanilla JavaScript.</p>
            </article>

            <article>
                <h3>Portfolio Website</h3>
                <p>A single-page portfolio showcasing projects and skills using Flexbox layout.</p>
            </article>

            <article>
                <h3>Landing Page</h3>
                <p>A product landing page with a hero section, features grid, and contact form.</p>
            </article>
        </section>

        <aside>
            <h2>Skills</h2>
            <ul>
                <li>HTML5</li>
                <li>CSS3</li>
                <li>JavaScript</li>
                <li>PHP</li>
            </ul>
        </aside>
    </main>

    <footer>
        <p>Copyright 2026 Budi Santoso.</p>
    </footer>
</body>
</html>
```

The "Projects" section contains three `<article>` elements because each project is a self-contained item that could be extracted and displayed independently. The "About Me" and "Projects" blocks use `<section>` rather than `<article>` because they are thematic groupings of the page, not independently redistributable content. The `<aside>` for Skills sits inside `<main>` but is marked as secondary content that complements, rather than forms, the primary content.

**Solution for Exercise 3:**

Open `lesson-05/forms.html` and add the following wrapper elements around the existing content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Us</title>
    <!-- Paste your existing styles from forms.html here -->
</head>
<body>

    <header>
        <h1>Contact Us</h1>
    </header>

    <main>
        <section>
            <h2>Send a Message</h2>
            <!-- Paste your existing form from forms.html here -->
        </section>
    </main>

    <footer>
        <p>Copyright 2026. All rights reserved.</p>
    </footer>

</body>
</html>
```

The original form content goes inside the `<section>`, which is then wrapped by `<main>`. Adding a `<header>` with the page title and a `<footer>` with a copyright notice gives the page a complete semantic structure. The `<section>` inside `<main>` has its own `<h2>` ("Send a Message") to name the thematic group, satisfying the rule that every `<section>` should have a heading.

---

## 8. Next Up - Lesson 7

Semantic HTML gives meaning to page structure. `<header>` marks introductory content, `<nav>` marks navigation links, `<main>` marks the primary content area (exactly one per page), `<section>` groups related content under a heading, `<article>` marks self-contained content, `<aside>` marks secondary related content, and `<footer>` marks closing content. Use `<div>` only when none of the semantic elements fit. Use `<span>` to target inline text for CSS styling without changing the flow of content.

In Lesson 7, you will start learning CSS: how to link a stylesheet to an HTML page, select elements using CSS selectors, and apply properties to control colors, fonts, and text styles.