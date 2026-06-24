## 1. Before You Begin

Before writing your first line of HTML, it helps to understand how the web actually works. When you type a URL into your browser and press Enter, a series of steps happen in milliseconds: your browser asks a server for a file, the server sends it back, and your browser reads the file and displays it on screen. The files that make up a website are primarily HTML, CSS, and JavaScript.

This lesson has no code. The focus is on understanding what HTML and CSS do, how browsers render pages, and what you will build throughout this course. Getting this mental model right from the start will make every following lesson much easier to understand.

### What You'll Build

This lesson is conceptual - there is no file to create yet. By the end, you will have a clear picture of how the web works, what role HTML and CSS each play, and a preview of the complete landing page you will build by Lesson 13.

### What You'll Learn

- ✅ How browsers and servers communicate
- ✅ What HTML does (structure and content)
- ✅ What CSS does (presentation and layout)
- ✅ How HTML, CSS, and JavaScript work together
- ✅ What you will build throughout this course
- ✅ The full course roadmap

### What You'll Need

- A computer with a web browser (Chrome, Firefox, Edge, or Safari)
- No prior programming experience required

---

## 2. How the Web Works

Every time you visit a website, your browser goes through a specific sequence of steps behind the scenes. Understanding this process explains why HTML and CSS are the exact tools used to build web pages.

```
1. You type "www.example.com" in the browser
2. Browser asks a DNS server: "What is the IP address of example.com?"
3. DNS responds: "93.184.216.34"
4. Browser sends an HTTP request to that IP: "Give me the homepage"
5. Server sends back an HTML file
6. Browser reads the HTML and displays the page
7. If the HTML references CSS or images, the browser requests those too
```

The key insight is that your browser is essentially a file reader. It receives HTML files from a server and turns them into the visual pages you see on screen. HTML tells the browser what to display (text, images, links). CSS tells it how to display it (colors, fonts, layout). Without these two files, a webpage cannot exist.

---

## 3. What Is HTML?

HTML (HyperText Markup Language) defines the structure and content of a web page. It uses tags to mark up text and tell the browser what each piece of content represents.

```html
<h1>Welcome to My Website</h1>
<p>This is a paragraph of text.</p>
<img src="photo.jpg" alt="A photo">
<a href="about.html">Learn more about us</a>
```

Each tag communicates a specific meaning to the browser. `<h1>` says "this is the main heading." `<p>` says "this is a paragraph." `<img>` says "display this image." `<a>` says "this is a clickable link." The browser reads these tags and renders the content accordingly.

HTML does not control how things look. A heading appears big and bold because the browser applies default styles, not because HTML instructed it to be that size. Controlling appearance is CSS's responsibility.

---

## 4. What Is CSS?

CSS (Cascading Style Sheets) controls the presentation of HTML content: colors, fonts, spacing, layout, and responsive behavior. While HTML defines what is on the page, CSS defines how everything looks.

```css
h1 {
    color: navy;
    font-size: 36px;
    text-align: center;
}

p {
    font-family: Arial, sans-serif;
    line-height: 1.6;
}
```

This CSS instructs the browser to make all `<h1>` headings navy blue, 36 pixels tall, and horizontally centered. All paragraphs will use Arial font with 1.6 line spacing. Without CSS, every website would look like a plain text document with default browser styles. CSS is what transforms a plain document into a designed, professional-looking page.

---

## 5. What You Will Build

Throughout this course, every lesson adds new skills that build toward a single, complete project. By Lesson 13, you will have everything you need to build a full landing page.

The final project will include these sections:

- **Hero section** with a headline, description, and call-to-action button
- **Features section** with three cards arranged in a row
- **Pricing section** with a comparison table
- **Contact form** with input validation styling
- **Footer** with links and copyright

The page will look professional on both desktop and mobile screens, adapting its layout automatically using CSS media queries. Every lesson in this course teaches the skills needed for one specific part of this final project.

---

## 6. HTML, CSS, and JavaScript

Web pages are built with three technologies, each with a distinct role. Understanding the boundary between them prevents confusion as you learn.

**HTML** is the structure. It defines what is on the page: headings, paragraphs, images, links, forms. Think of it as the skeleton of a building - it determines what rooms exist and where they are located.

**CSS** is the style. It defines how everything looks: colors, fonts, spacing, layout. Think of it as the paint, furniture, and decoration that make the building visually appealing.

**JavaScript** is the behavior. It makes things interactive: dropdown menus, form validation, animations, and dynamic content loading. Think of it as the electricity and plumbing that make the building functional.

This course covers HTML and CSS. JavaScript is taught in a separate course. Together, these three technologies are the foundation of every website you use.

---

## 7. Course Roadmap

This course is organized into seven modules with fourteen lessons total. Each pair of lessons focuses on a specific skill area that contributes to the final landing page project.

**Lessons 1 and 2** cover how the web works and how to write and open your first HTML page.

**Lessons 3 and 4** teach essential HTML content elements: text formatting, links, images, and lists.

**Lessons 5 and 6** add structural HTML: tables, forms, and semantic page structure.

**Lessons 7 and 8** introduce CSS: how to write selectors, apply properties, and understand the box model.

**Lessons 9 and 10** master modern layout: Flexbox for one-dimensional arrangements and CSS Grid for two-dimensional layouts.

**Lessons 11 and 12** polish the design: typography, backgrounds, colors, and making the layout respond to different screen sizes.

**Lessons 13 and 14** combine everything into the complete landing page and point you toward your next steps after this course.

---

## Next Up - Lesson 2

The web works by exchanging files between browsers and servers. HTML defines the structure and content of a page using tags. CSS controls how that content looks. JavaScript adds interactivity. These three technologies work together to build everything you see on the internet, and this course focuses entirely on mastering HTML and CSS.

In Lesson 2, you will install VS Code, create your first HTML file with the complete document structure, and open it in a browser for the first time.