## 1. Before You Begin

A website that looks great on a desktop but breaks on a phone has a fundamental problem. As of today, more than half of all web traffic comes from mobile devices. If your page requires horizontal scrolling, has text too small to read, or has buttons too small to tap, users will leave. Responsive design is the practice of building pages that adapt their layout and appearance to suit any screen size.

The primary tool for responsive design is the media query: a CSS rule that applies a block of styles only when specific conditions are true, such as the screen being at least 768px wide or at most 600px wide. Combined with fluid units, flexible layouts (Flexbox and Grid), and the viewport meta tag, media queries give you complete control over how your page looks at any size.

### What You'll Build

You will build a complete responsive page in `responsive.html` and `responsive.css`. The page includes a navigation bar that shifts from stacked to horizontal at the tablet breakpoint, a hero section with scaling text, a card grid that switches from one column (mobile) to two columns (tablet) to three columns (desktop), and a two-column text-and-image section that collapses to a single column on mobile.

### What You'll Learn

- ✅ The viewport meta tag and why it is essential on every page
- ✅ Media queries: `@media (min-width: ...)` and `@media (max-width: ...)`
- ✅ Mobile-first vs desktop-first approach
- ✅ Common responsive breakpoints (640px, 768px, 1024px, 1280px)
- ✅ Responsive units: `%`, `em`, `rem`, `vw`, `vh`
- ✅ `max-width` for fluid containers
- ✅ Responsive images with `max-width: 100%; height: auto`
- ✅ Testing responsiveness in browser DevTools

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 11 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-12`, and press Enter.

---

## 3. The Viewport Meta Tag

Every HTML page that needs to be responsive must include this line in the `<head>`:

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

Without this tag, mobile browsers assume the page was designed for a desktop screen roughly 980px wide and zoom out to show the full desktop layout in miniature. The result is tiny, unreadable text and the need to pinch-and-zoom to interact with anything. `width=device-width` instructs the browser to set the page width to match the actual screen width of the device. `initial-scale=1.0` prevents any initial zoom. Every lesson in this course already includes this tag for exactly this reason.

---

## 4. Media Queries

A media query wraps a block of CSS declarations and applies them only when the specified condition is true. The condition most commonly used for responsive design is screen width. Media queries do not override other CSS - they add to it. Styles applied outside a media query remain in effect unless the media query explicitly changes them.

### Step 1: Create the Files

Right-click on `lesson-12` in VS Code, select **New File**, type `responsive.html`. Right-click again, select **New File**, type `responsive.css`.

### Step 2: Write the HTML

Add the following to `responsive.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Responsive Design</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="responsive.css">
</head>
<body>
    <nav class="navbar">
        <a href="#" class="brand">MySite</a>
        <div class="nav-links">
            <a href="#">Home</a>
            <a href="#">About</a>
            <a href="#">Services</a>
            <a href="#">Contact</a>
        </div>
    </nav>

    <section class="hero">
        <h1>Responsive Web Design</h1>
        <p>This page adapts to any screen size. Resize your browser to see it in action.</p>
    </section>

    <section class="container">
        <h2>Our Services</h2>
        <div class="cards">
            <div class="card">
                <h3>Web Design</h3>
                <p>Beautiful, responsive websites that work on every device.</p>
            </div>
            <div class="card">
                <h3>Development</h3>
                <p>Clean, maintainable code built with modern technologies.</p>
            </div>
            <div class="card">
                <h3>SEO</h3>
                <p>Optimize your site for search engines and increase traffic.</p>
            </div>
        </div>
    </section>

    <section class="container">
        <div class="two-col">
            <div class="col-text">
                <h2>About Us</h2>
                <p>We are a team of developers and designers who love building great web experiences. Our focus is on responsive, accessible, and performant websites.</p>
            </div>
            <div class="col-image">
                <img src="https://placehold.co/600x400" alt="About us photo">
            </div>
        </div>
    </section>

    <footer class="footer">
        <p>Copyright 2026 MySite. All rights reserved.</p>
    </footer>
</body>
</html>
```

### Step 3: Write the CSS (Mobile-First)

Add the following to `responsive.css`:

```css
/* =============================
   Base styles (mobile first)
   ============================= */

:root {
    --primary: #2563eb;
    --text: #1e293b;
    --text-light: #64748b;
    --bg: #f8fafc;
    --white: #ffffff;
    --border: #e2e8f0;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: 'Inter', Arial, sans-serif;
    color: var(--text);
    background: var(--bg);
    line-height: 1.6;
}

img { max-width: 100%; height: auto; border-radius: 8px; }

/* Navbar: stacked on mobile */
.navbar {
    background: var(--text);
    padding: 12px 16px;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
}

.brand {
    color: white;
    font-weight: 700;
    font-size: 1.2em;
    text-decoration: none;
}

.nav-links { display: flex; flex-wrap: wrap; gap: 12px; }
.nav-links a { color: #93c5fd; text-decoration: none; font-size: 0.9em; }

/* Hero: smaller on mobile */
.hero {
    background: linear-gradient(135deg, var(--primary), #7c3aed);
    color: white;
    text-align: center;
    padding: 40px 16px;
}

.hero h1 { font-size: 1.5rem; margin-bottom: 10px; }
.hero p  { color: rgba(255,255,255,0.85); max-width: 500px; margin: 0 auto; }

/* Container */
.container { max-width: 1000px; margin: 0 auto; padding: 30px 16px; }
.container h2 { margin-bottom: 16px; }

/* Cards: 1 column on mobile */
.cards {
    display: grid;
    grid-template-columns: 1fr;
    gap: 16px;
}

.card {
    background: var(--white);
    border: 1px solid var(--border);
    padding: 20px;
    border-radius: 8px;
}

.card h3 { color: var(--primary); margin-bottom: 6px; }
.card p  { color: var(--text-light); }

/* Two-column: stacked on mobile */
.two-col { display: flex; flex-direction: column; gap: 20px; }

/* Footer */
.footer {
    background: var(--text);
    color: var(--text-light);
    text-align: center;
    padding: 20px;
    margin-top: 20px;
}

/* =============================
   Tablet (768px and up)
   ============================= */
@media (min-width: 768px) {
    .navbar {
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        padding: 12px 24px;
    }

    .hero { padding: 60px 24px; }
    .hero h1 { font-size: 2rem; }

    .cards { grid-template-columns: 1fr 1fr; }

    .two-col { flex-direction: row; align-items: center; }
    .col-text { flex: 1; }
    .col-image { flex: 1; }
}

/* =============================
   Desktop (1024px and up)
   ============================= */
@media (min-width: 1024px) {
    .hero h1 { font-size: 2.5rem; }

    .cards { grid-template-columns: 1fr 1fr 1fr; }
}
```

The CSS is organized in three sections. The first section (base styles) targets mobile screens and defines the simplest possible layout: stacked navigation, small hero text, single-column cards, and stacked two-column content. The `@media (min-width: 768px)` block adds styles for tablets - the navigation becomes horizontal, the hero text grows, and cards switch to two columns. The `@media (min-width: 1024px)` block adds desktop-specific styles on top of the tablet styles, switching cards to three columns and making the hero text even larger.

This is the mobile-first approach: you write the smallest, simplest layout first and use `min-width` queries to add complexity as the screen gets larger. Each breakpoint's styles build on the previous; nothing is undone.

`img { max-width: 100%; height: auto; }` is the single most important rule for responsive images. `max-width: 100%` prevents images from being wider than their container, so they never cause horizontal overflow. `height: auto` preserves the original aspect ratio as the image scales.

### Step 4: Save and View

Press **Ctrl+S** for both files and open `responsive.html` with Live Server. Resize the browser window slowly from narrow to wide to observe each layout change at 768px and 1024px.

### Step 5: Test in DevTools

Press **F12** to open DevTools and click the device toolbar icon in the top-left area of the panel (or press Ctrl+Shift+M on Windows/Linux). DevTools switches to a mobile viewport with a device dropdown at the top. Select different devices - iPhone SE, iPad, iPad Pro, desktop - to see exactly how the layout responds at each size.

---

## 5. Mobile-First vs Desktop-First

The two approaches to writing responsive CSS differ in which screen size you write the base styles for.

**Mobile-first (recommended):** Write base styles for the smallest screens. Use `@media (min-width: ...)` to progressively enhance the layout for larger screens.

```css
/* Base: mobile, one column */
.cards { grid-template-columns: 1fr; }

/* Tablet: two columns */
@media (min-width: 768px) {
    .cards { grid-template-columns: 1fr 1fr; }
}

/* Desktop: three columns */
@media (min-width: 1024px) {
    .cards { grid-template-columns: 1fr 1fr 1fr; }
}
```

**Desktop-first:** Write base styles for the largest screens. Use `@media (max-width: ...)` to simplify the layout for smaller screens.

```css
/* Base: desktop, three columns */
.cards { grid-template-columns: 1fr 1fr 1fr; }

/* Mobile: one column */
@media (max-width: 767px) {
    .cards { grid-template-columns: 1fr; }
}
```

Mobile-first is the industry standard today for two reasons. First, mobile users represent the majority of web traffic, so designing for them first ensures the best experience for the most users. Second, it is easier to add complexity to a simple layout than to subtract complexity from a complicated one. Starting simple and enhancing progressively results in leaner, more maintainable CSS.

---

## 6. Common Responsive Breakpoints

Breakpoints are the screen width thresholds where your layout changes. There is no single correct set of breakpoints - they should reflect where your specific design naturally needs to adjust. The following values are widely used and match the breakpoints in popular CSS frameworks like Tailwind and Bootstrap.

| Breakpoint | Device | Media Query |
|-----------|--------|-------------|
| Below 640px | Small phones | Base styles (mobile-first) |
| 640px and up | Large phones | `@media (min-width: 640px)` |
| 768px and up | Tablets | `@media (min-width: 768px)` |
| 1024px and up | Desktops | `@media (min-width: 1024px)` |
| 1280px and up | Large desktops | `@media (min-width: 1280px)` |

In practice, most projects use only two or three breakpoints. Adding too many creates CSS that is hard to maintain. Start with mobile, add a tablet breakpoint at 768px, and add a desktop breakpoint at 1024px. Only add more breakpoints if the design specifically requires it.

---

## 7. Fix the Errors in Your Code

Three responsive design mistakes appear very frequently and each one has a significant impact on how the page looks on real devices.

**Error 1: Missing the viewport meta tag.**

Without the viewport meta tag, every media query in the stylesheet becomes unreliable on mobile. The browser renders a zoomed-out desktop view and media queries may fire based on the virtual viewport rather than the actual device width.

```html
<!-- Wrong: no viewport tag, mobile browsers zoom out to show desktop version -->
<head>
    <title>My Page</title>
</head>

<!-- Correct: viewport meta tag is present on every HTML page -->
<head>
    <title>My Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
```

Think of this tag as the prerequisite for all responsive CSS. If responsive styles are not working on a mobile device, the viewport meta tag is the first thing to check.

**Error 2: Using a fixed `width` on containers instead of `max-width`.**

A container with `width: 960px` will overflow its parent on any screen narrower than 960px, causing horizontal scrolling. `max-width` allows the container to be smaller if the screen is smaller, while still capping its size on large screens.

```css
/* Wrong: overflows on screens narrower than 960px */
.container { width: 960px; }

/* Correct: shrinks on small screens, limited to 960px on large ones */
.container { max-width: 960px; width: 100%; }
```

Setting both `max-width` and `width: 100%` ensures the container fills its parent on small screens and is capped at 960px on large ones. Using only `max-width` without `width: 100%` can cause unexpected behavior in some contexts.

**Error 3: Using fixed pixel values for font sizes that need to scale.**

A heading set to `font-size: 48px` may look appropriate on a large desktop but will be disproportionately large on a 375px phone screen. `rem` units scale relative to the root font size. The `clamp()` function is even more powerful, setting a minimum, a preferred fluid value, and a maximum.

```css
/* Wrong: 48px is too large on a small phone, too small on a large display */
h1 { font-size: 48px; }

/* Better: rem scales with browser settings */
h1 { font-size: 3rem; }

/* Best: clamp scales with viewport width, within min/max bounds */
h1 { font-size: clamp(1.5rem, 4vw, 3rem); }
```

`clamp(1.5rem, 4vw, 3rem)` means: the font size is at least `1.5rem`, at most `3rem`, and ideally `4vw` (4% of the viewport width). On a 375px screen, `4vw = 15px`, which is less than 1.5rem (24px), so it clamps to 24px. On a 1200px screen, `4vw = 48px`, which equals 3rem, so it clamps to that.

---

## 8. Exercises

**Exercise 1:** Make the three-column footer from Lesson 9 responsive. On mobile (below 768px), the three columns (Company, Links, Contact) should stack vertically in a single column. On tablet and above, they should sit side by side in a row. Use Flexbox with a `flex-direction` media query.

**Exercise 2:** Create `gallery-responsive.html` with a photo gallery of six images. Use CSS Grid with `repeat(auto-fit, minmax(250px, 1fr))` on the grid container. Observe how it automatically adjusts its column count as you resize the browser, without any media queries.

**Exercise 3:** Create `navbar-responsive.html` with a navigation bar that hides its links on mobile and shows them on desktop. On screens below 768px, the `.nav-links` div should be hidden with `display: none`. On screens 768px and above, it should appear with `display: flex`. Add a visible `[Menu]` text placeholder where a hamburger icon would go on mobile.

---

## 9. Solutions

**Solution for Exercise 1:**

Start with the footer HTML from Lesson 9 and update the CSS with the following rules:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Responsive Footer</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; margin: 0; }

        .footer { background: #1e293b; color: #cbd5e1; padding: 30px 20px; }

        .footer-content {
            display: flex;
            flex-direction: column;
            gap: 24px;
            max-width: 900px;
            margin: 0 auto;
        }

        .footer-col h4 { color: white; margin-bottom: 8px; }
        .footer-col ul { list-style: none; padding: 0; }
        .footer-col li { margin-bottom: 6px; }
        .footer-col a { color: #94a3b8; text-decoration: none; }

        @media (min-width: 768px) {
            .footer-content {
                flex-direction: row;
            }
            .footer-col { flex: 1; }
        }
    </style>
</head>
<body>
    <footer class="footer">
        <div class="footer-content">
            <div class="footer-col">
                <h4>Company</h4>
                <p>Building responsive web experiences since 2020.</p>
            </div>
            <div class="footer-col">
                <h4>Links</h4>
                <ul>
                    <li><a href="#">Home</a></li>
                    <li><a href="#">About</a></li>
                    <li><a href="#">Services</a></li>
                    <li><a href="#">Contact</a></li>
                </ul>
            </div>
            <div class="footer-col">
                <h4>Contact</h4>
                <p>Jl. Merdeka No. 10<br>Bandung, Indonesia</p>
                <p>hello@example.com</p>
            </div>
        </div>
    </footer>
</body>
</html>
```

The base styles set `flex-direction: column` so the three columns stack vertically on mobile with a clear gap between them. At 768px and above, the media query changes the direction to `row` and applies `flex: 1` to each column, distributing the space equally across the three columns in a horizontal row.

**Solution for Exercise 2:**

Create a new file called `gallery-responsive.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Responsive Gallery</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 20px; background: #f8fafc; }

        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 16px;
        }

        .gallery-item {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }

        .gallery-item img {
            width: 100%;
            display: block;
        }

        .gallery-item p {
            padding: 10px 14px;
            color: #64748b;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <h1>Photo Gallery</h1>
    <div class="gallery">
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 1"><p>City skyline</p></div>
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 2"><p>Mountain view</p></div>
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 3"><p>Ocean sunset</p></div>
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 4"><p>Forest path</p></div>
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 5"><p>Desert dunes</p></div>
        <div class="gallery-item"><img src="https://placehold.co/400x300" alt="Photo 6"><p>River delta</p></div>
    </div>
</body>
</html>
```

`repeat(auto-fit, minmax(250px, 1fr))` removes the need for any media queries. The browser calculates how many 250px-minimum columns can fit in the current container width and generates exactly that many. On a 375px phone (minus padding), one column fits. On a 768px tablet, two or three fit. On a 1200px desktop, four fit. Resize the browser and watch the columns adjust in real time.

**Solution for Exercise 3:**

Create a new file called `navbar-responsive.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Responsive Navbar</title>
    <style>
        * { box-sizing: border-box; margin: 0; }
        body { font-family: Arial, sans-serif; }

        .navbar {
            background: #1e293b;
            padding: 12px 16px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .brand {
            color: white;
            font-weight: bold;
            text-decoration: none;
            font-size: 1.1em;
        }

        .menu-toggle {
            color: #93c5fd;
            font-size: 0.9em;
            cursor: pointer;
        }

        .nav-links {
            display: none;
        }

        .nav-links a {
            color: #93c5fd;
            text-decoration: none;
            margin-left: 16px;
        }

        @media (min-width: 768px) {
            .menu-toggle { display: none; }
            .nav-links    { display: flex; }
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="#" class="brand">MySite</a>
        <span class="menu-toggle">[Menu]</span>
        <div class="nav-links">
            <a href="#">Home</a>
            <a href="#">About</a>
            <a href="#">Services</a>
            <a href="#">Contact</a>
        </div>
    </nav>
    <main style="padding:30px">
        <h1>Responsive Navigation</h1>
        <p>Resize your browser to below 768px to see the links hide and the menu placeholder appear.</p>
    </main>
</body>
</html>
```

`display: none` on `.nav-links` hides the links completely on mobile. The `[Menu]` placeholder becomes visible as a hint that navigation exists but is currently hidden. At 768px and above, the media query sets `display: none` on `.menu-toggle` (hiding the placeholder) and `display: flex` on `.nav-links` (revealing the horizontal link row). In a real project, JavaScript would listen for a click on the menu toggle and add a class that sets `.nav-links` back to `display: flex` on mobile.

---

## 10. Next Up - Lesson 13

Responsive design starts with the viewport meta tag on every page. Media queries use `@media (min-width: ...)` to apply CSS only above a certain screen width. The mobile-first approach writes base styles for mobile and progressively enhances them for larger screens at 768px and 1024px. `max-width` on containers prevents overflow on small screens. `max-width: 100%; height: auto` on images ensures they never overflow their container. `clamp()` produces font sizes that scale fluidly with viewport width. CSS Grid's `auto-fit` with `minmax()` creates responsive grids without any media queries at all.

In Lesson 13, you will combine everything from the entire course into a single complete project: a multi-section responsive landing page with a hero section, features grid, pricing table, contact form, and footer.