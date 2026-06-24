## 1. Before You Begin

A web page without links is an island. Links connect pages to each other, forming the "web" in World Wide Web. Images make pages visual and informative. Lists organize content into ordered or unordered groups, making information scannable and accessible. These three elements appear on virtually every web page you will ever build, and mastering them is essential before moving on to CSS.

In Lesson 3, you learned how to structure text with headings and paragraphs. In this lesson, you will go further by adding navigation between pages, displaying media, and organizing content into lists.

### What You'll Build

You will create three HTML files: `links.html` to practice all types of hyperlinks, `images.html` to display local and remote images with proper semantic markup, and `lists.html` to build unordered, ordered, nested, and description lists. By the end, all three pages will link to each other.

### What You'll Learn

- ✅ Hyperlinks with `<a>`: internal, external, email, phone, and anchor links
- ✅ Images with `<img>`: `src`, `alt`, `width`, `height`
- ✅ `<figure>` and `<figcaption>` for semantic image markup
- ✅ Unordered lists `<ul>` and ordered lists `<ol>`
- ✅ Nested lists
- ✅ Description lists `<dl>` for key-value pairs
- ✅ Relative vs absolute paths

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 3 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder in the Explorer panel, select **New Folder**, type `lesson-04`, and press Enter. All files you create in this lesson go inside this folder.

---

## 3. Links (Hyperlinks)

The `<a>` element (short for "anchor") is how HTML creates clickable links. An anchor can point to another page on the same website, a page on a different website, an email address, a phone number, or even a specific section further down the same page.

### Step 1: Create the File

Right-click on the `lesson-04` folder, select **New File**, type `links.html`, and press Enter.

### Step 2: Write the Code

Add the following to `links.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Links</title>
</head>
<body>
    <h1>Types of Links</h1>

    <h2>External Link</h2>
    <p>Visit <a href="https://www.google.com" target="_blank">Google</a> (opens in new tab).</p>

    <h2>Internal Link</h2>
    <p>Go to <a href="lists.html">the lists page</a> (same site).</p>

    <h2>Email Link</h2>
    <p>Contact us at <a href="mailto:hello@example.com">hello@example.com</a>.</p>

    <h2>Phone Link</h2>
    <p>Call us: <a href="tel:+6281234567890">+62 812-3456-7890</a>.</p>

    <h2>Anchor Link</h2>
    <p>Jump to <a href="#bottom">the bottom of this page</a>.</p>

    <h2>Link Styled as Button</h2>
    <p><a href="https://example.com" style="background:#2563eb;color:white;padding:8px 16px;text-decoration:none;border-radius:4px;">Click Me</a></p>

    <br><br><br><br><br><br><br><br><br><br>
    <p id="bottom">You reached the bottom! <a href="#top">Back to top</a>.</p>
</body>
</html>
```

Each link type uses a different value for the `href` attribute, which is what determines the link's destination. External links use a full URL starting with `https://`. Internal links use just a filename, like `lists.html`, because the file lives in the same folder. Email links use `mailto:` followed by an email address, which opens the user's default email app. Phone links use `tel:` followed by a phone number in international format, which triggers a call on mobile devices. Anchor links use `#` followed by the `id` of a target element on the same page, which causes the browser to scroll directly to that element. The `target="_blank"` attribute on external links tells the browser to open the destination in a new tab instead of replacing the current page.

### Step 3: Save and View

Press **Ctrl+S** and open with Live Server. Click each link to test how it behaves differently.

### Link Attributes Reference

| Attribute | Purpose | Example |
|-----------|---------|---------|
| `href` | The destination URL or target | `href="about.html"` |
| `target` | Where to open the link | `target="_blank"` (new tab) |
| `title` | Tooltip text shown on hover | `title="Visit Google"` |

---

## 4. Images

The `<img>` element embeds images into an HTML page. Unlike most HTML elements, `<img>` is self-closing because it does not wrap any content. It pulls in an image file specified by the `src` attribute and displays it inline in the document.

### Step 1: Download a Sample Image

For this exercise, save any image file as `photo.jpg` inside the `lesson-04` folder. Alternatively, you can use a placeholder URL from the internet and skip the local image entirely.

### Step 2: Create the File

Right-click on `lesson-04`, select **New File**, type `images.html`, and press Enter.

### Step 3: Write the Code

Add the following to `images.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Images</title>
</head>
<body>
    <h1>Working with Images</h1>

    <h2>Local Image</h2>
    <img src="photo.jpg" alt="A sample photo" width="400">

    <h2>Online Image</h2>
    <img src="https://placehold.co/400x250" alt="Placeholder image">

    <h2>Clickable Image</h2>
    <a href="https://example.com">
        <img src="https://placehold.co/300x200" alt="Click to visit example.com">
    </a>

    <h2>Figure with Caption</h2>
    <figure>
        <img src="https://placehold.co/400x250" alt="A beautiful landscape">
        <figcaption>A beautiful landscape photo (placeholder).</figcaption>
    </figure>
</body>
</html>
```

The `src` attribute points the browser to the image file. If the file exists locally, you write just the filename or a relative path. If it is hosted online, you write the full URL. The `alt` attribute provides alternative text that appears when the image cannot load, and is read aloud by screen readers for visually impaired users. Never omit `alt`: for content images, write a description of what the image shows; for decorative images, use `alt=""` (an empty value, which tells screen readers to skip the image). The `width` attribute sets the display width in pixels. Setting only `width` without `height` makes the browser automatically calculate the correct height to preserve the original aspect ratio.

Wrapping an `<img>` inside an `<a>` element makes the image a clickable link. Wrapping an image in `<figure>` with a `<figcaption>` gives it semantic structure: the `<figure>` element represents self-contained media, and `<figcaption>` provides a visible caption that is semantically associated with that media.

### Step 4: Save and View

Press **Ctrl+S** and open the file in your browser. If `photo.jpg` does not exist, the browser will show the `alt` text in its place, demonstrating exactly why the attribute is important.

### Relative vs Absolute Paths

When writing `src` or `href` values, you choose between a relative path (which is based on the current file's location) or an absolute path (a full URL including the domain).

```html
<!-- Relative: relative to the current HTML file's location -->
<img src="photo.jpg">           <!-- Same folder -->
<img src="images/photo.jpg">    <!-- Subfolder named images -->
<img src="../photo.jpg">        <!-- Parent folder -->

<!-- Absolute: full URL including the domain -->
<img src="https://example.com/photo.jpg">
```

Use relative paths for files within your own project. Use absolute paths for images or pages hosted on a different server.

---

## 5. Lists

HTML provides three types of lists for different purposes. Unordered lists display items with bullet points when the sequence does not matter. Ordered lists display items with numbers when the sequence is important. Description lists pair a term with its definition, making them well-suited for glossaries or key-value data.

### Step 1: Create the File

Right-click on `lesson-04`, select **New File**, type `lists.html`, and press Enter.

### Step 2: Write the Code

Add the following to `lists.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lists</title>
</head>
<body>
    <h1>Types of Lists</h1>

    <h2>Unordered List (Bullets)</h2>
    <ul>
        <li>HTML</li>
        <li>CSS</li>
        <li>JavaScript</li>
        <li>PHP</li>
    </ul>

    <h2>Ordered List (Numbers)</h2>
    <ol>
        <li>Learn HTML</li>
        <li>Learn CSS</li>
        <li>Learn JavaScript</li>
        <li>Build a project</li>
    </ol>

    <h2>Nested List</h2>
    <ul>
        <li>Frontend
            <ul>
                <li>HTML</li>
                <li>CSS</li>
                <li>JavaScript</li>
            </ul>
        </li>
        <li>Backend
            <ul>
                <li>PHP</li>
                <li>Java</li>
                <li>Python</li>
            </ul>
        </li>
    </ul>

    <h2>Description List</h2>
    <dl>
        <dt>HTML</dt>
        <dd>HyperText Markup Language. Defines page structure.</dd>

        <dt>CSS</dt>
        <dd>Cascading Style Sheets. Controls page appearance.</dd>

        <dt>JavaScript</dt>
        <dd>Programming language for web interactivity.</dd>
    </dl>

    <p><a href="links.html">Back to links page</a></p>
</body>
</html>
```

`<ul>` (unordered list) creates a bulleted list. `<ol>` (ordered list) creates a numbered list. Both types use `<li>` (list item) for each individual entry. To nest a list inside another, place a new `<ul>` or `<ol>` inside an existing `<li>` element. The browser automatically indents inner lists and uses different bullet styles at each nesting level.

`<dl>` (description list) works differently from `<ul>` and `<ol>`. Instead of `<li>`, it uses two child elements: `<dt>` (description term) for the label or key, and `<dd>` (description details) for the corresponding value or explanation. Description lists are commonly used for glossaries, FAQ sections, and metadata displays.

### Step 3: Save and View

Press **Ctrl+S** and open in the browser. Notice how the nested list is automatically indented, and how the description list renders each term with its definition on a separate line.

---

## 6. Fix the Errors in Your Code

When working with links, images, and lists, certain mistakes are particularly common. Each one results in HTML that either breaks functionality or violates accessibility standards.

**Error 1: Missing `alt` attribute on an image.**

Omitting `alt` leaves screen readers with no way to describe the image to visually impaired users, and means there is no fallback text if the image fails to load.

```html
<!-- Wrong: no alt attribute -->
<img src="photo.jpg">

<!-- Correct: descriptive alt text for content images -->
<img src="photo.jpg" alt="A photo of the Bandung city skyline">
```

Every `<img>` element must have an `alt` attribute. For images that carry meaning, write a concise description of what the image shows. For purely decorative images that add no information to the page, use `alt=""` so that screen readers know to skip over the image entirely.

**Error 2: An `<a>` tag with no `href` attribute.**

An anchor element without `href` is not a functional link. It renders as clickable-looking text but does nothing when clicked, and screen readers will not announce it as a link.

```html
<!-- Wrong: anchor without href -->
<a>Click me</a>

<!-- Correct: anchor with a valid destination -->
<a href="page.html">Click me</a>
```

If you are building a navigation link and the destination page does not exist yet, use `href="#"` as a temporary placeholder. This makes the element behave as a link while you continue building.

**Error 3: `<li>` elements placed outside a list container.**

A `<li>` element must always be a direct child of `<ul>` or `<ol>`. Placing it outside produces invalid HTML, even if the browser renders it visually.

```html
<!-- Wrong: li elements without a parent list -->
<li>Item 1</li>
<li>Item 2</li>

<!-- Correct: li elements wrapped in a ul -->
<ul>
    <li>Item 1</li>
    <li>Item 2</li>
</ul>
```

While browsers often attempt to recover from invalid nesting, the resulting behavior is unpredictable and differs between browsers. Always wrap `<li>` elements inside a proper `<ul>` or `<ol>` parent.

---

## 7. Exercises

**Exercise 1:** Create `portfolio.html`. Add your name as `<h1>`, a profile image using a placeholder URL, a paragraph about yourself, and an unordered list of five skills. Below the skills, add a section with links to three websites you find useful.

**Exercise 2:** Create `navigation.html`. Build a horizontal navigation bar using an unordered list with four links: Home, About, Services, Contact. Apply inline styles `style="display:inline; margin-right:15px;"` directly on each `<li>` to push them side by side.

**Exercise 3:** Create `gallery.html`. Display six images using placeholder URLs with different dimensions. Wrap each image in an `<a>` tag that opens the full-size image in a new tab. Use `<figure>` and `<figcaption>` for each image, and add a caption describing what the photo shows.

---

## 8. Solutions

**Solution for Exercise 1:**

Create a new file called `portfolio.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Portfolio</title>
</head>
<body>
    <h1>Budi Santoso</h1>
    <img src="https://placehold.co/200x200" alt="Profile photo of Budi Santoso">
    <p>I am a web developer from Bandung, Indonesia, passionate about building clean and accessible web pages.</p>

    <h2>Skills</h2>
    <ul>
        <li>HTML</li>
        <li>CSS</li>
        <li>JavaScript</li>
        <li>PHP</li>
        <li>MySQL</li>
    </ul>

    <h2>Favorite Sites</h2>
    <ul>
        <li><a href="https://developer.mozilla.org" target="_blank">MDN Web Docs</a></li>
        <li><a href="https://css-tricks.com" target="_blank">CSS-Tricks</a></li>
        <li><a href="https://github.com" target="_blank">GitHub</a></li>
    </ul>
</body>
</html>
```

The profile image uses a placeholder URL so the file works immediately without any local image. The `alt` attribute describes who the image shows, which is critical for screen readers. Skills and favorite sites are presented as separate `<ul>` elements under their own `<h2>` headings, making the page structure clear and well-organized.

**Solution for Exercise 2:**

Create a new file called `navigation.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Navigation</title>
</head>
<body>
    <nav>
        <ul style="list-style:none; padding:0; background:#333;">
            <li style="display:inline; margin-right:0">
                <a href="#" style="color:white; padding:10px 15px; text-decoration:none; display:inline-block;">Home</a>
            </li>
            <li style="display:inline; margin-right:0">
                <a href="#" style="color:white; padding:10px 15px; text-decoration:none; display:inline-block;">About</a>
            </li>
            <li style="display:inline; margin-right:0">
                <a href="#" style="color:white; padding:10px 15px; text-decoration:none; display:inline-block;">Services</a>
            </li>
            <li style="display:inline; margin-right:0">
                <a href="#" style="color:white; padding:10px 15px; text-decoration:none; display:inline-block;">Contact</a>
            </li>
        </ul>
    </nav>
    <h1>Welcome</h1>
    <p>This page demonstrates a horizontal navigation bar built from an unordered list.</p>
</body>
</html>
```

Setting `display:inline` on each `<li>` removes the default block behavior so the items appear side by side. The `<ul>` has `list-style:none` to remove bullet points, and `padding:0` to remove the default indentation browsers apply to lists. The `<nav>` wrapper tells browsers and screen readers that this list is a navigation landmark, not just decorative content.

**Solution for Exercise 3:**

Create a new file called `gallery.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gallery</title>
</head>
<body>
    <h1>Photo Gallery</h1>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 1">
        </a>
        <figcaption>Mountain landscape at sunrise</figcaption>
    </figure>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 2">
        </a>
        <figcaption>Ocean view at sunset</figcaption>
    </figure>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 3">
        </a>
        <figcaption>Forest path in autumn</figcaption>
    </figure>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 4">
        </a>
        <figcaption>Desert dunes at midday</figcaption>
    </figure>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 5">
        </a>
        <figcaption>Snowy mountain peak</figcaption>
    </figure>

    <figure style="display:inline-block; margin:10px;">
        <a href="https://placehold.co/800x600" target="_blank">
            <img src="https://placehold.co/200x150" alt="Landscape photo 6">
        </a>
        <figcaption>Waterfall in a tropical rainforest</figcaption>
    </figure>
</body>
</html>
```

Each thumbnail is wrapped in an `<a>` tag pointing to the full-resolution version of the image. `target="_blank"` opens the larger image in a new tab, leaving the gallery page open. `<figure>` groups each image with its `<figcaption>`, creating a semantic association between the media and its label. Setting `display:inline-block` on each `<figure>` allows them to sit side by side instead of stacking vertically.

---

## 9. Next Up - Lesson 5

Links use `<a href="...">` to connect pages, with different `href` formats for external URLs, internal files, email addresses, phone numbers, and on-page anchor targets. Images use `<img src="..." alt="...">` and must always include a descriptive `alt` attribute for accessibility. Unordered lists (`<ul>`) use bullet points for items with no specific order, ordered lists (`<ol>`) use numbers for sequential steps, and description lists (`<dl>`) pair terms with definitions. Relative paths reference files based on folder location, while absolute paths use a full URL.

In Lesson 5, you will learn how to display structured data with HTML tables and how to collect user input with forms, including text fields, dropdowns, radio buttons, checkboxes, and submit buttons.