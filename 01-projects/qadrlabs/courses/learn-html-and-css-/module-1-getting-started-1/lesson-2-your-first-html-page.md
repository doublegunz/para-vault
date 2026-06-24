## 1. Before You Begin

To build a website, you need two tools: a text editor to write code and a browser to see the result. Unlike PHP or Java, HTML does not need a server or a compiler. You create an `.html` file, open it in the browser, and it works immediately. This simplicity is one of the reasons HTML is the perfect first language to learn.

In Lesson 1, you learned that a browser reads HTML files sent by a server and turns them into visual pages. In this lesson, you will create that HTML file yourself for the first time.

### What You'll Build

You will install VS Code, create your first `index.html` file with a complete HTML document structure, and open it in a browser. You will also create a second page and link the two pages together, giving you a working two-page mini website.

### What You'll Learn

- ✅ How to install VS Code and useful extensions
- ✅ The HTML document structure: `<!DOCTYPE>`, `<html>`, `<head>`, `<body>`
- ✅ How to create and save an `.html` file
- ✅ How to open HTML files in the browser
- ✅ What tags, elements, and attributes are
- ✅ How to write HTML comments

### What You'll Need

- A computer running Windows, macOS, or Linux
- A web browser (Chrome recommended)

---

## 2. Install VS Code

VS Code (Visual Studio Code) is the most widely used code editor for web development. It is free, open-source, and available for all operating systems. Before writing your first HTML file, you need to get VS Code installed and configured with the right extensions.

### Step 1: Download VS Code

Go to [code.visualstudio.com](https://code.visualstudio.com/) and download the installer for your operating system. Run the installer and follow the default steps to complete the installation.

### Step 2: Install Extensions

Open VS Code. Click the **Extensions** icon in the left sidebar (or press Ctrl+Shift+X). Install these three extensions by searching for their names and clicking **Install**:

- **Live Server** by Ritwick Dey: automatically refreshes the browser every time you save a file, so you can see changes instantly
- **HTML CSS Support**: provides CSS class name suggestions inside HTML files, which becomes useful in later lessons
- **Auto Rename Tag**: when you edit an opening tag, the matching closing tag updates automatically, preventing mismatched tags

### Step 3: Create the Project Folder

Create a folder called `learn-html-css` on your computer, either on the Desktop or in your Documents folder. Open VS Code, click **File**, then **Open Folder**, navigate to `learn-html-css`, and click **Select Folder**. From this point on, all your lesson files will live inside this folder.

### Step 4: Create the Lesson Folder

In the VS Code Explorer panel on the left, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-02`, and press Enter. This folder will hold all files for this lesson.

---

## 3. Your First HTML File

Now that VS Code is set up, you will create your first HTML file. Every file you build in this course follows the same structural skeleton, so understanding this first file is essential.

### Step 1: Create the File

Right-click on the `lesson-02` folder in the Explorer panel, select **New File**, type `index.html`, and press Enter. The name `index.html` is a convention: web servers automatically serve a file named `index.html` as the default page for a folder.

### Step 2: Write the Code

Open `index.html` and type the following code exactly as written:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My First Page</title>
</head>
<body>
    <h1>Hello, World!</h1>
    <p>This is my first HTML page.</p>
    <p>I am learning HTML and CSS.</p>
</body>
</html>
```

This is a complete, valid HTML5 document. Every HTML page you write in this course will begin with this exact structure. The next section explains what each part means.

### Step 3: Save the File

Press **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS) to save. VS Code shows a dot on the tab when there are unsaved changes. Make it a habit to save frequently as you work.

### Step 4: Open in the Browser

You have two options to preview the file.

**Option A: Live Server (recommended).** Right-click anywhere inside the editor and select **Open with Live Server**. A browser tab opens automatically. Every time you save the file, the browser refreshes on its own. This is the fastest way to work.

**Option B: Manual.** Open your file explorer (not VS Code), navigate to the `lesson-02` folder inside `learn-html-css`, and double-click `index.html`. It opens in your default browser. To see changes, you must press F5 in the browser each time you save.

You should see "Hello, World!" as a large heading followed by two paragraphs of text.

---

## 4. The HTML Document Structure

Every HTML page you will ever write uses this same skeleton. Understanding each part of it now will save you from confusion in every lesson that follows.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Information ABOUT the page (not visible) -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Title</title>
</head>
<body>
    <!-- Visible content goes here -->
</body>
</html>
```

`<!DOCTYPE html>` is not an HTML tag. It is a declaration that tells the browser this document follows the HTML5 standard. It must always be the first line of the file. Without it, the browser enters "quirks mode," which causes inconsistent rendering across different browsers.

`<html lang="en">` is the root element that wraps the entire document. The `lang="en"` attribute tells search engines and screen readers that this page is written in English. This is important for accessibility and SEO.

`<head>` contains metadata: information about the page that is not displayed directly on screen. It holds the page title, character encoding, viewport settings, and later, links to CSS files.

`<meta charset="UTF-8">` sets the character encoding to UTF-8, which supports virtually all languages and special characters. Without this, characters like accented letters or emoji may display incorrectly.

`<meta name="viewport" content="width=device-width, initial-scale=1.0">` ensures the page displays correctly on mobile screens. Without it, mobile browsers would zoom out and show the page as a tiny desktop version.

`<title>` sets the text you see in the browser tab. Search engines also use this text as the clickable headline in search results, so it is worth writing clearly.

`<body>` contains all the visible content of the page: headings, paragraphs, images, links, and forms. Everything the user sees on screen goes inside `<body>`.

---

## 5. Tags, Elements, and Attributes

HTML has three fundamental concepts that appear in every file you write. Understanding the difference between them prevents confusion when you read documentation or error messages.

### Tags

Tags are the building blocks of HTML. Most tags come in pairs, with an opening tag and a matching closing tag:

```html
<h1>This is a heading</h1>
```

The opening tag `<h1>` marks the beginning of the element. The closing tag `</h1>` marks the end. The forward slash is what distinguishes the closing tag from the opening one.

Some tags are self-closing because they do not wrap content:

```html
<br>
<hr>
<img src="photo.jpg" alt="A photo">
```

`<br>` inserts a line break. `<hr>` draws a horizontal rule. `<img>` displays an image. None of these elements need a closing tag because they have no content to wrap between two tags.

### Elements

An element is the complete unit: the opening tag, the content between the tags, and the closing tag together.

```html
<p>This is a paragraph element.</p>
```

The element includes everything from `<p>` to `</p>`, including the text inside. When someone says "add a paragraph element," they mean the full unit, not just the tag.

### Attributes

Attributes provide extra information about an element. They are always written inside the opening tag, following the format `name="value"`.

```html
<a href="https://example.com" target="_blank">Visit Example</a>
```

In this example, `href` tells the browser where the link points, and `target="_blank"` tells the browser to open the link in a new tab. An element can have multiple attributes separated by spaces. Attribute values are always wrapped in double quotes.

---

## 6. Comments

HTML comments let you leave notes in your code that are completely invisible to the user. The browser ignores them entirely. Comments are useful for explaining your code to yourself or to teammates, and for temporarily disabling a part of the code while testing.

### Step 1: Open the File

Open `index.html` in the `lesson-02` folder.

### Step 2: Add Comments

Update the body of your file to include comments:

```html
<body>
    <!-- This is a comment. The browser ignores it. -->
    <h1>Hello, World!</h1>

    <!-- TODO: Add more content here -->
    <p>This is my first HTML page.</p>

    <!--
        Multi-line comments
        are also possible.
    -->
    <p>I am learning HTML and CSS.</p>
</body>
```

A comment begins with `<!--` and ends with `-->`. Everything between those markers is ignored by the browser. Single-line and multi-line comments use the same syntax - just extend the content across multiple lines.

### Step 3: Save and Refresh

Press **Ctrl+S**. If you are using Live Server, the browser refreshes automatically. Otherwise, press F5 in the browser. Notice that none of your comment text appears on the page - the browser skips it completely.

---

## 7. Multiple Pages

Real websites have more than one page. HTML pages link to each other using the `<a>` tag. Creating a second page and linking it to your first gives you a working multi-page website for the first time.

### Step 1: Create a Second Page

Right-click on the `lesson-02` folder in VS Code, select **New File**, and type `about.html`. This will be your second page.

### Step 2: Write the Code

Add the following HTML to `about.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Me</title>
</head>
<body>
    <h1>About Me</h1>
    <p>My name is Budi. I am learning web development.</p>
    <p><a href="index.html">Back to home</a></p>
</body>
</html>
```

The `<a href="index.html">` tag creates a link that points to `index.html`. Because both files are in the same folder, you only need to write the filename, not a full URL. This is called a relative path.

### Step 3: Add a Link from index.html

Open `index.html` and add the following line just before the closing `</body>` tag:

```html
    <p><a href="about.html">About me</a></p>
```

This creates a link on your home page that points to the about page. Save both files. Click the "About me" link on the home page - it takes you to `about.html`. Click "Back to home" - it returns you to `index.html`. You now have a functional two-page website.

---

## 8. Fix the Errors in Your Code

When learning HTML, certain mistakes appear repeatedly. This section shows the most common ones and explains why they cause problems and how to fix them correctly.

**Error 1: Missing closing tag.**

A common mistake when starting out is forgetting to close a tag. This causes the browser to treat everything that follows as part of the unclosed element.

```html
<!-- Wrong: h1 is never closed -->
<h1>My Heading
<p>My paragraph</p>

<!-- Correct: every opening tag has a matching closing tag -->
<h1>My Heading</h1>
<p>My paragraph</p>
```

When `<h1>` has no closing `</h1>`, the browser keeps reading content as part of the heading until it encounters another block-level tag. The result is unpredictable rendering. Always close every tag that has a closing pair.

**Error 2: Wrong nesting order.**

Tags must always close in the reverse order they were opened. If you open `<strong>` inside `<p>`, you must close `</strong>` before you close `</p>`.

```html
<!-- Wrong: tags close in the wrong order -->
<p>This is <strong>bold and <em>italic</p></em></strong>

<!-- Correct: inner tags close before outer tags -->
<p>This is <strong>bold and <em>italic</em></strong></p>
```

Think of nested tags like nested boxes. The innermost box must be closed first before you can close the box that contains it. Modern browsers will attempt to fix incorrect nesting automatically, but the result is often not what you intended.

**Error 3: Missing DOCTYPE.**

Omitting `<!DOCTYPE html>` puts the browser into "quirks mode," where it renders the page using older, inconsistent rules. This can cause layouts to look different across Chrome, Firefox, and Safari.

```html
<!-- Wrong: no DOCTYPE declaration -->
<html>
<head><title>Test</title></head>
<body><p>Hello</p></body>
</html>

<!-- Correct: DOCTYPE is always the first line -->
<!DOCTYPE html>
<html lang="en">
<head><title>Test</title></head>
<body><p>Hello</p></body>
</html>
```

`<!DOCTYPE html>` is not optional. Make it the very first line of every HTML file you create, with nothing - not even a blank line - before it.

---

## 9. Exercises

**Exercise 1:** Create a file `exercise-1.html` with a complete HTML document structure. Give it the title "My Hobbies." In the body, write three paragraphs, each describing one of your hobbies. Open it in the browser using Live Server.

**Exercise 2:** Create `exercise-2.html`. Add two headings (`<h1>` and `<h2>`), a paragraph under each, and a horizontal rule (`<hr>`) between them. Add an HTML comment above each section describing what it contains.

**Exercise 3:** Create a mini website with three linked pages: `home.html`, `hobbies.html`, and `contact.html`. Each page must have a `<title>`, an `<h1>`, a descriptive paragraph, and links to the other two pages.

---

## 10. Solutions

**Solution for Exercise 1:**

Create a new file called `exercise-1.html` and write the following complete document:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Hobbies</title>
</head>
<body>
    <h1>My Hobbies</h1>
    <p>I enjoy reading books, especially science fiction and technology.</p>
    <p>I like playing football on weekends with my friends.</p>
    <p>I also love cooking Indonesian food like nasi goreng and rendang.</p>
</body>
</html>
```

The document follows the complete HTML5 skeleton: `<!DOCTYPE html>` first, then `<html lang="en">`, then `<head>` with charset and viewport meta tags, then `<body>` with the visible content. Each hobby is written as a separate `<p>` element rather than putting everything in one paragraph, because separate paragraphs are easier for readers to scan.

**Solution for Exercise 2:**

Create a new file called `exercise-2.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sections</title>
</head>
<body>
    <!-- First section: main heading -->
    <h1>Main Heading</h1>
    <p>This is the main section of the page.</p>

    <hr>

    <!-- Second section: subsection -->
    <h2>Sub Heading</h2>
    <p>This is a secondary section with more detail.</p>
</body>
</html>
```

The `<hr>` element creates a horizontal line that visually separates the two sections. The comments above each section serve as labels for anyone reading the code. Note that `<h2>` is used for the subsection rather than another `<h1>`, because each page should have only one `<h1>`.

**Solution for Exercise 3:**

Create `home.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home</title>
</head>
<body>
    <h1>Welcome Home</h1>
    <p>This is the home page of my mini website.</p>
    <p>
        <a href="hobbies.html">My Hobbies</a> |
        <a href="contact.html">Contact</a>
    </p>
</body>
</html>
```

Create `hobbies.html` and `contact.html` using the same structure, but with their own `<title>`, `<h1>`, and paragraph content. Each file must include links back to the other two pages. Because all three files are in the same folder, you can reference them by filename alone (`href="home.html"`) without needing a full URL.

---

## 11. Next Up - Lesson 3

Every HTML page starts with `<!DOCTYPE html>` and uses a three-part structure: `<html>` wraps everything, `<head>` holds metadata, and `<body>` holds the visible content. Tags come in pairs or are self-closing. Attributes provide extra information inside the opening tag. Comments are invisible to users and help document your code.

In Lesson 3, you will learn about text elements: headings from `<h1>` to `<h6>`, paragraphs, line breaks, and formatting tags like `<strong>` and `<em>`. You will also learn the critical difference between block and inline elements.