## 1. Before You Begin

Text is the foundation of every web page. Before CSS makes a page beautiful and JavaScript makes it interactive, HTML first needs to give meaning to every piece of content. This lesson focuses on the HTML elements that structure and format text: six levels of headings, paragraphs, line breaks, and a set of formatting tags that communicate importance, emphasis, and meaning to both the browser and the user.

Understanding the difference between block elements (which take up the full width and start on a new line) and inline elements (which flow within text) is especially important. This distinction directly affects how CSS interacts with your content in later lessons.

### What You'll Build

You will create three separate HTML files: `headings.html` to practice heading levels, `paragraphs.html` to work with paragraphs and line breaks, and `formatting.html` to apply text formatting tags and HTML entities. Together these files form a structured reference you can return to as you continue the course.

### What You'll Learn

- ✅ Heading levels `<h1>` through `<h6>`
- ✅ Paragraphs `<p>`, line breaks `<br>`, and horizontal rules `<hr>`
- ✅ Text formatting: `<strong>`, `<em>`, `<mark>`, `<small>`, `<del>`, `<sub>`, `<sup>`
- ✅ Preformatted text `<pre>` and inline code `<code>`
- ✅ Block vs inline elements
- ✅ Special characters (HTML entities)

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 2 completed

---

## 2. Setup

Before writing any code, you need to create a dedicated folder for this lesson's files. This keeps your project organized as the number of files grows across lessons.

In VS Code, right-click on the `learn-html-css` folder in the Explorer panel, select **New Folder**, type `lesson-03`, and press Enter. All three files you create in this lesson will go inside this folder.

---

## 3. Headings

HTML provides six heading levels, from `<h1>` (the most important) to `<h6>` (the least important). Headings communicate the hierarchy of your content to the browser, to search engines, and to screen readers. Choosing the right heading level is a matter of structure, not appearance.

### Step 1: Create the File

Right-click on the `lesson-03` folder in VS Code, select **New File**, type `headings.html`, and press Enter.

### Step 2: Write the Code

Type the following into `headings.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Headings</title>
</head>
<body>
    <h1>Heading Level 1 (Main Title)</h1>
    <h2>Heading Level 2 (Section Title)</h2>
    <h3>Heading Level 3 (Subsection)</h3>
    <h4>Heading Level 4</h4>
    <h5>Heading Level 5</h5>
    <h6>Heading Level 6 (Smallest)</h6>

    <p>Headings go from h1 (largest, most important) to h6 (smallest).</p>
    <p>Use h1 once per page for the main title. Use h2 for major sections, h3 for subsections.</p>
</body>
</html>
```

When you open this in the browser, you will see all six headings rendered at decreasing sizes. The browser's default styles make `<h1>` the largest and `<h6>` the smallest, but remember: these sizes can be overridden completely with CSS. The heading level you choose communicates structure, not size.

### Step 3: Save and Open

Press **Ctrl+S**. Right-click in the editor and select **Open with Live Server**, or open the file manually in the browser. You should see all six headings stacked vertically with visually decreasing sizes.

### Key Rules for Headings

There are three rules that apply to headings on every page you write:

- Use only **one `<h1>`** per page. It represents the main title of that specific page, and search engines treat it as the primary subject indicator.
- Do not skip levels. Moving from `<h1>` directly to `<h4>` confuses both screen readers and search engines. Use levels sequentially.
- Use headings for **structure**, not for visual sizing. If you want text to appear larger, use CSS. Using `<h3>` just because you want medium-sized text is a misuse of HTML semantics.

---

## 4. Paragraphs and Line Breaks

The `<p>` element is the standard way to present blocks of text. Every new paragraph should be a separate `<p>` element, not text separated by `<br>` tags. This section also introduces `<br>`, `<hr>`, and `<pre>`, each of which handles whitespace and separation in a different way.

### Step 1: Create the File

Right-click on `lesson-03`, select **New File**, type `paragraphs.html`, and press Enter.

### Step 2: Write the Code

Add the following to `paragraphs.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paragraphs</title>
</head>
<body>
    <h1>About Web Development</h1>

    <p>Web development is the process of building websites and web applications. It involves writing HTML for structure, CSS for styling, and JavaScript for interactivity.</p>

    <p>HTML was created by Tim Berners-Lee in 1991. Since then, it has evolved through several versions. The current version, HTML5, was finalized in 2014.</p>

    <p>
        Budi Santoso<br>
        Jl. Merdeka No. 10<br>
        Bandung, Jawa Barat<br>
        Indonesia
    </p>

    <hr>

    <p>The section above shows an address using line breaks. The hr element creates a horizontal line to separate content visually.</p>

    <h2>Code Example</h2>
    <pre>
function greet(name) {
    return "Hello, " + name;
}
    </pre>
</body>
</html>
```

`<p>` creates a paragraph with automatic spacing above and below it, making separate paragraphs visually distinct without any CSS. `<br>` forces a line break within the same paragraph without adding that vertical spacing - it is useful for content like addresses or poetry where lines must break at specific points but are still conceptually one block of text. `<hr>` draws a horizontal line and is used as a visual divider between sections of content. `<pre>` (preformatted text) preserves all whitespace and line breaks exactly as written in the HTML source, which makes it ideal for displaying code samples where indentation matters.

### Step 3: Save and View

Press **Ctrl+S** and open the file in your browser. Notice how each `<p>` has visible spacing above and below it, how the address breaks at the correct points without creating separate paragraphs, and how the code inside `<pre>` appears exactly as typed.

---

## 5. Text Formatting

HTML provides a set of inline elements for formatting text. Unlike `<p>` and headings, these elements do not create new lines - they wrap text within a line and change only the portion they surround. Each formatting element carries a specific semantic meaning beyond just its visual appearance.

### Step 1: Create the File

Right-click on `lesson-03`, select **New File**, type `formatting.html`, and press Enter.

### Step 2: Write the Code

Add the following to `formatting.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Text Formatting</title>
</head>
<body>
    <h1>Text Formatting in HTML</h1>

    <p>This is <strong>bold text</strong> using the strong element.</p>
    <p>This is <em>italic text</em> using the em (emphasis) element.</p>
    <p>This is <mark>highlighted text</mark> using the mark element.</p>
    <p>This is <small>small text</small> using the small element.</p>
    <p>This is <del>deleted text</del> using the del element.</p>
    <p>This is <ins>inserted text</ins> using the ins element.</p>
    <p>Water is H<sub>2</sub>O (subscript).</p>
    <p>10<sup>2</sup> = 100 (superscript).</p>

    <h2>Combining Formatting</h2>
    <p>You can <strong>combine <em>multiple</em> formats</strong> by nesting elements correctly.</p>

    <h2>Code and Keyboard</h2>
    <p>Use the <code>console.log()</code> function to debug JavaScript.</p>
    <p>Press <kbd>Ctrl</kbd> + <kbd>S</kbd> to save.</p>

    <h2>Blockquote</h2>
    <blockquote>
        <p>The best way to predict the future is to invent it.</p>
        <p>-- Alan Kay</p>
    </blockquote>

    <h2>Special Characters (HTML Entities)</h2>
    <p>Less than: &lt; Greater than: &gt;</p>
    <p>Ampersand: &amp; Copyright: &copy; Non-breaking space:&nbsp;&nbsp;&nbsp;(3 spaces)</p>
</body>
</html>
```

Each formatting element has a distinct semantic purpose. `<strong>` marks text as important - browsers display it in bold by default, but its meaning communicates urgency or significance. `<em>` marks text as emphasized - browsers display it in italic, but its meaning is that this word or phrase carries stress. `<mark>` highlights text as relevant to the current context, like a search match. `<del>` represents text that has been removed or is no longer accurate, typically displayed with a strikethrough. `<ins>` represents text that has been added, often displayed with an underline. `<sub>` renders text slightly below the baseline (useful for chemical formulas) and `<sup>` renders it above the baseline (useful for exponents). `<code>` marks a span of text as computer code and displays it in a monospace font. `<kbd>` marks keyboard input and is often used in documentation to show which key to press. `<blockquote>` is used to quote a longer passage from another source.

### Step 3: Save and View

Press **Ctrl+S** and open `formatting.html` in the browser. You will see each element rendered with its default browser styling.

---

## 6. Block vs Inline Elements

One of the most important concepts in HTML is the distinction between block-level and inline elements. This distinction determines how elements are arranged on the page and directly affects how CSS styles them later.

Block elements always start on a new line and stretch to fill the full available width of their container. Common block elements include `<h1>` through `<h6>`, `<p>`, `<div>`, `<blockquote>`, `<pre>`, `<hr>`, `<ul>`, `<table>`, and `<form>`.

Inline elements flow within the surrounding text and only take up as much width as their content requires. Common inline elements include `<strong>`, `<em>`, `<a>`, `<img>`, `<code>`, `<span>`, `<br>`, and `<mark>`.

```html
<!-- Block elements: each starts on a new line and takes full width -->
<p>Paragraph 1</p>
<p>Paragraph 2</p>

<!-- Inline elements: flow within the paragraph without breaking the line -->
<p>This word is <strong>bold</strong> and this is <em>italic</em>.</p>
```

In the first example, each `<p>` occupies its own horizontal space - you cannot place two paragraphs side by side without CSS. In the second example, `<strong>` and `<em>` sit within the flow of the paragraph text without breaking to a new line. Understanding this distinction becomes critical when you start using CSS to build layouts in Lessons 7 through 10.

---

## 7. Fix the Errors in Your Code

When working with text elements, three mistakes appear very frequently. Each one is easy to make but leads to HTML that is technically incorrect or semantically misleading.

**Error 1: Using `<br>` to add spacing between paragraphs.**

A common habit when starting out is using multiple `<br>` tags to create visual space between sections of content. This produces the visual result but communicates the wrong meaning to browsers and tools.

```html
<!-- Wrong: br tags used for spacing -->
<p>First paragraph</p>
<br>
<br>
<p>Second paragraph</p>

<!-- Correct: separate paragraphs with no extra br tags -->
<p>First paragraph</p>
<p>Second paragraph</p>
```

`<br>` means "insert a line break within this flow of text." It is semantically appropriate for addresses or poetry where line breaks are part of the content. For spacing between separate blocks of content, the correct tool is CSS `margin`. Using multiple `<br>` tags for spacing mixes presentation concerns into your HTML structure, which makes the code harder to maintain when you add CSS later.

**Error 2: Using heading levels for visual sizing instead of structure.**

Another frequent mistake is choosing a heading level based on how large you want the text to appear rather than on where the content sits in the document hierarchy.

```html
<!-- Wrong: h4 chosen because the developer wants smaller text -->
<h1>Main Title</h1>
<h4>This text should be smaller</h4>
<p>Some content here</p>

<!-- Correct: heading level reflects document structure -->
<h1>Main Title</h1>
<h2>Section Title</h2>
<p>Some content here</p>
```

If you want text at a specific size, use CSS `font-size`. Skipping from `<h1>` to `<h4>` breaks the document outline that screen readers and search engines rely on to understand the page. A screen reader user navigating by headings will encounter a confusing jump that implies missing sections. Use headings only to represent the actual structure of your content.

**Error 3: Not closing inline tags before the parent element closes.**

Forgetting to close an inline tag before its containing element closes causes the browser to interpret the nesting incorrectly.

```html
<!-- Wrong: </strong> is missing before </p> -->
<p>This is <strong>bold text</p>

<!-- Correct: strong closes before p closes -->
<p>This is <strong>bold text</strong></p>
```

When `<strong>` is not closed before `</p>`, the browser's error recovery may extend the bold styling beyond the paragraph or produce other unexpected rendering. Every inline element you open inside a block element must be closed before that block element closes.

---

## 8. Exercises

**Exercise 1:** Create `article.html`. Write a short article (three paragraphs) about a topic you enjoy. Use `<h1>` for the article title, `<h2>` for two sub-sections, and `<p>` for each paragraph. Emphasize at least two key words using `<strong>` and one phrase using `<em>`.

**Exercise 2:** Create `recipe.html`. Write a simple recipe with the dish name as `<h1>`, an introduction paragraph, a `<blockquote>` containing a cooking tip, and the preparation steps as individual `<p>` elements. Use `<hr>` to separate the introduction from the steps.

**Exercise 3:** Create `entities.html`. Display the following text exactly as it appears on screen, using HTML entities where needed: `5 < 10 & 10 > 5. The price is $29.99. Use <p> for paragraphs. Copyright 2026.`

---

## 9. Solutions

**Solution for Exercise 1:**

Create a new file called `article.html` and write the following complete document:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Article</title>
</head>
<body>
    <h1>Why I Love Programming</h1>
    <p>Programming is the art of <strong>solving problems</strong> with code.</p>

    <h2>The Joy of Building</h2>
    <p>There is something <em>deeply satisfying</em> about turning an idea into a working application.</p>

    <h2>Continuous Learning</h2>
    <p>Technology evolves constantly, which means there is always something <strong>new to learn</strong>.</p>
</body>
</html>
```

The document uses `<h1>` for the top-level article title and `<h2>` for the two subsections. This creates a clear, two-level content hierarchy. `<strong>` wraps text that carries importance, while `<em>` wraps a phrase that would be stressed when spoken aloud. Both are inline elements, so they appear within the flow of the paragraph without breaking to a new line.

**Solution for Exercise 2:**

Create a new file called `recipe.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nasi Goreng Recipe</title>
</head>
<body>
    <h1>Nasi Goreng</h1>
    <p>Nasi goreng is a <strong>classic Indonesian fried rice</strong> dish loved worldwide.</p>
    <blockquote>
        <p>Tip: Use day-old rice for the best texture.</p>
    </blockquote>

    <hr>

    <p>Step 1: Heat oil in a wok over high heat.</p>
    <p>Step 2: Add garlic, shallots, and chili. Stir for 30 seconds.</p>
    <p>Step 3: Add rice and soy sauce. Stir-fry for 3 minutes.</p>
</body>
</html>
```

The `<blockquote>` element wraps the tip because it is a distinct piece of information quoted separately from the main content. `<hr>` creates a visible dividing line between the introduction and the steps without requiring any CSS. Each preparation step is its own `<p>` element rather than one long paragraph, making the recipe easier to follow step by step.

**Solution for Exercise 3:**

Create a new file called `entities.html` and write the following paragraph:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTML Entities</title>
</head>
<body>
    <p>5 &lt; 10 &amp; 10 &gt; 5. The price is $29.99. Use &lt;p&gt; for paragraphs. Copyright &copy; 2026.</p>
</body>
</html>
```

The characters `<`, `>`, and `&` have special meaning in HTML - they are used to open tags and write entities. To display them as literal text on screen, you must use their HTML entity equivalents: `&lt;` for `<`, `&gt;` for `>`, and `&amp;` for `&`. The `&copy;` entity produces the copyright symbol. The browser converts these entities back to their visible characters when rendering the page.

---

## 10. Next Up - Lesson 4

HTML provides six heading levels to structure content hierarchically, with `<h1>` reserved for the single main title of the page. Paragraphs use `<p>`, while `<br>` forces line breaks within text and `<hr>` separates sections visually. Inline formatting elements like `<strong>`, `<em>`, `<mark>`, `<del>`, and `<code>` wrap text without breaking the flow of a line. Block elements start on a new line and take full width; inline elements flow within text. Special characters that would otherwise be interpreted as HTML must be written as entities.

In Lesson 4, you will learn how to add hyperlinks with `<a>`, display images with `<img>`, and organize content with ordered lists, unordered lists, and description lists.