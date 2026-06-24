## 1. Before You Begin

HTML provides structure. CSS provides style. Without CSS, every website would look like a plain text document printed on white paper - readable, but completely undesigned. CSS controls colors, fonts, spacing, sizing, layout, borders, shadows, and animations. Everything that makes a web page look professional and intentional is CSS.

In Lesson 6, you learned to give meaning to HTML sections using semantic elements. In this lesson, you will learn how to visually style those sections: how to write CSS, how to target specific elements with selectors, and which properties are used most often.

### What You'll Build

You will create three demonstration files: one to compare the three methods of adding CSS, one to explore selectors with a styled HTML page, and one to practice common CSS properties including colors, fonts, borders, and sizing. By the end, you will build a styled profile card using an external stylesheet.

### What You'll Learn

- ✅ Three ways to add CSS: inline, internal, external
- ✅ CSS syntax: selectors, properties, and values
- ✅ Selectors: element, class, ID, grouping, descendant
- ✅ Common properties: `color`, `background`, `font-family`, `border`
- ✅ CSS color values: named, hex, RGB, RGBA, HSL
- ✅ CSS units: `px`, `em`, `rem`, `%`, `vh`/`vw`
- ✅ The cascade and specificity (which rule wins when styles conflict)

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 6 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder in the Explorer panel, select **New Folder**, type `lesson-07`, and press Enter.

---

## 3. Three Ways to Add CSS

CSS can be added to an HTML page in three different ways. Understanding all three is important because you will encounter all of them in existing code, even though only one of them is recommended for production work.

### Step 1: Create the File

Right-click on the `lesson-07` folder in VS Code, select **New File**, type `css-ways.html`, and press Enter.

### Step 2: Write the Code

Add the following to `css-ways.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Three Ways to Add CSS</title>

    <!-- Method 2: Internal CSS (in the head) -->
    <style>
        .internal {
            color: green;
            font-size: 18px;
        }
    </style>

    <!-- Method 3: External CSS (separate file) -->
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <!-- Method 1: Inline CSS (on the element) -->
    <p style="color: red; font-size: 20px;">This uses inline CSS.</p>

    <!-- Method 2: Internal CSS -->
    <p class="internal">This uses internal CSS (written in the head).</p>

    <!-- Method 3: External CSS -->
    <p class="external">This uses external CSS (a separate file).</p>

    <p><strong>Best practice:</strong> Always use external CSS. It keeps HTML clean and allows reuse across pages.</p>
</body>
</html>
```

Method 1 (inline CSS) adds styles directly to an element using the `style` attribute. It overrides all other styles but cannot be reused across elements and clutters the HTML. Method 2 (internal CSS) writes styles inside a `<style>` tag in the `<head>`. This is fine for single-page experiments but cannot be shared across multiple HTML files. Method 3 (external CSS) links to a separate `.css` file using `<link rel="stylesheet" href="...">`. This is the correct approach for any real project because the same stylesheet can be linked from every HTML page in the site, and updating one file updates all pages at once.

### Step 3: Create the External Stylesheet

Right-click on `lesson-07`, select **New File**, type `style.css`, and press Enter. Add the following:

```css
.external {
    color: blue;
    font-size: 18px;
    font-weight: bold;
}
```

The `<link>` tag in the HTML file tells the browser to fetch `style.css` and apply its rules to the page. The `rel="stylesheet"` attribute specifies the relationship between the HTML file and the linked resource. The `href` value must exactly match the filename, including spelling and capitalization.

### Step 4: Save Both Files and View

Press **Ctrl+S** in both files. Open `css-ways.html` with Live Server. You will see three differently styled paragraphs, each demonstrating one method.

---

## 4. CSS Syntax and Selectors

CSS is written as a series of rules. Each rule has two parts: a selector that targets one or more HTML elements, and a declaration block that lists the properties to apply to those elements. Selectors are the most critical skill in CSS - choosing the right selector determines which elements are styled and which are left alone.

### Step 1: Create the File

Right-click on `lesson-07`, select **New File**, type `selectors.html`, and press Enter.

### Step 2: Write the HTML

Add the following to `selectors.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSS Selectors</title>
    <link rel="stylesheet" href="selectors.css">
</head>
<body>
    <h1>CSS Selectors</h1>
    <h2>Section Title</h2>

    <p>This is a regular paragraph.</p>
    <p class="highlight">This paragraph has the "highlight" class.</p>
    <p class="highlight important">This has two classes.</p>
    <p id="special">This paragraph has the "special" ID.</p>

    <div class="card">
        <h3>Card Title</h3>
        <p>Card content paragraph.</p>
    </div>

    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
        <li>Item 3</li>
    </ul>
</body>
</html>
```

### Step 3: Create selectors.css

Right-click on `lesson-07`, select **New File**, type `selectors.css`, and press Enter. Add the following:

```css
/* Element selector: targets ALL <p> elements */
p {
    font-family: Arial, sans-serif;
    line-height: 1.6;
}

/* Class selector: targets elements with class="highlight" */
.highlight {
    background-color: #fef3c7;
    padding: 8px;
    border-left: 4px solid #f59e0b;
}

/* Multiple classes: targets elements with BOTH classes */
.highlight.important {
    font-weight: bold;
    border-left-color: #dc2626;
}

/* ID selector: targets the ONE element with id="special" */
#special {
    color: #7c3aed;
    font-style: italic;
}

/* Descendant selector: targets <p> inside .card */
.card p {
    color: #666;
    font-size: 14px;
}

/* Grouping selector: targets h1 AND h2 */
h1, h2 {
    color: #1e293b;
}

/* Universal selector: targets every element */
* {
    box-sizing: border-box;
}

/* Card styling */
.card {
    border: 1px solid #e2e8f0;
    padding: 16px;
    border-radius: 8px;
    margin: 12px 0;
}

/* List items */
li {
    padding: 4px 0;
}
```

The element selector (`p`) applies to every `<p>` on the page. The class selector (`.highlight`) applies to any element that has `class="highlight"` in its HTML, and the same class can appear on multiple elements. The ID selector (`#special`) applies to the single element with `id="special"` - by convention, IDs must be unique on a page. The descendant selector (`.card p`) applies only to `<p>` elements that are nested inside an element with class `card`, leaving other paragraphs unaffected. The grouping selector (`h1, h2`) applies the same declarations to multiple selectors at once without repeating the declarations. The universal selector (`*`) matches every element on the page and is commonly used to apply `box-sizing: border-box` globally.

### Step 4: Save and View

Press **Ctrl+S** for both files and open `selectors.html` with Live Server. Observe how each paragraph is styled differently based on which selector matches it.

### Selector Summary

| Selector | Targets | Example |
|----------|---------|---------|
| `p` | All `<p>` elements | Element selector |
| `.highlight` | Elements with `class="highlight"` | Class selector |
| `#special` | The element with `id="special"` | ID selector |
| `.card p` | `<p>` inside `.card` | Descendant selector |
| `h1, h2` | All `<h1>` and `<h2>` | Grouping selector |
| `*` | Every element | Universal selector |

Prefer classes over IDs for styling. IDs have very high specificity, which can cause unexpected overrides later when you try to apply other styles to the same element.

---

## 5. Common CSS Properties

CSS has hundreds of properties, but a small set covers the vast majority of real design work. This section walks through the most important properties grouped by category.

### Step 1: Create the File

Right-click on `lesson-07`, select **New File**, type `properties.html`, and press Enter.

### Step 2: Write the Code

Add the following to `properties.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSS Properties</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 20px auto; }

        .color-demo { color: #2563eb; background-color: #eff6ff; padding: 10px; margin-bottom: 10px; }

        .font-demo { font-family: Georgia, serif; font-size: 18px; font-weight: bold; font-style: italic; line-height: 1.8; letter-spacing: 1px; }

        .text-demo { text-align: center; text-decoration: underline; text-transform: uppercase; }

        .border-demo { border: 2px solid #2563eb; border-radius: 8px; padding: 12px; }

        .border-dashed { border: 2px dashed #f59e0b; padding: 12px; margin-top: 8px; }

        .size-demo { width: 200px; height: 100px; background: #dbeafe; display: flex; align-items: center; justify-content: center; }

        .opacity-demo { opacity: 0.5; background: #2563eb; color: white; padding: 10px; }

        .cursor-demo { cursor: pointer; background: #f0fdf4; padding: 10px; border: 1px solid #86efac; }
    </style>
</head>
<body>
    <h1>Common CSS Properties</h1>

    <h2>Colors</h2>
    <p class="color-demo">Blue text on a light blue background.</p>

    <h2>Font Properties</h2>
    <p class="font-demo">Georgia, 18px, bold, italic, 1.8 line-height.</p>

    <h2>Text Properties</h2>
    <p class="text-demo">Centered, underlined, uppercase.</p>

    <h2>Border</h2>
    <p class="border-demo">Solid border with rounded corners.</p>
    <p class="border-dashed">Dashed border.</p>

    <h2>Width and Height</h2>
    <div class="size-demo">200px x 100px</div>

    <h2>Opacity</h2>
    <p class="opacity-demo">50% opacity</p>

    <h2>Cursor</h2>
    <p class="cursor-demo">Hover me - pointer cursor.</p>
</body>
</html>
```

`color` sets the text color of an element. `background-color` fills the element's background. Both accept any valid CSS color value. `font-family` sets the typeface, and always includes a fallback (like `sans-serif`) in case the primary font is unavailable. `font-size` sets the text size, `font-weight` controls boldness, and `font-style` controls italic. `line-height` sets the vertical spacing between lines of text, and values between 1.4 and 1.8 are generally most readable. `letter-spacing` adds or removes horizontal space between individual characters.

`text-align` positions text within its container: `left`, `center`, `right`, or `justify`. `text-decoration` adds or removes underlines: `underline` adds one, `none` removes it (commonly used to remove the default underline from links). `text-transform` changes letter casing: `uppercase`, `lowercase`, or `capitalize`.

`border` is a shorthand that sets width, style, and color together. The style value (`solid`, `dashed`, `dotted`) is required for the border to be visible. `border-radius` rounds the corners: a value of `50%` on a square element produces a circle.

`opacity` controls how transparent an element is, from `0` (completely invisible) to `1` (fully opaque). Unlike `rgba()` colors which make only the background or ink transparent, `opacity` applies to the entire element including all its children.

### Step 3: Save and View

Press **Ctrl+S** and open in the browser to see each property group rendered.

### CSS Color Values

CSS supports several color formats, each with different use cases:

```css
color: red;                    /* Named color */
color: #2563eb;                /* Hex (most common in production) */
color: rgb(37, 99, 235);       /* RGB (red, green, blue: 0-255) */
color: rgba(37, 99, 235, 0.5); /* RGBA (same as RGB plus alpha for transparency) */
color: hsl(220, 83%, 53%);     /* HSL (hue: 0-360, saturation %, lightness %) */
```

Hex values are the most common format in practice. HSL is increasingly popular because it is human-readable: the hue number maps directly to a position on the color wheel, making it easy to create color variations by adjusting only the saturation or lightness.

### CSS Units

Different units serve different purposes in CSS. Choosing the right unit affects how elements scale across screen sizes.

| Unit | Type | Example | When to Use |
|------|------|---------|-------------|
| `px` | Absolute | `font-size: 16px` | Fixed dimensions, borders |
| `em` | Relative to parent font size | `padding: 1.5em` | Spacing relative to text size |
| `rem` | Relative to root font size | `font-size: 1.2rem` | Consistent type scale |
| `%` | Relative to parent element | `width: 50%` | Fluid widths |
| `vh`/`vw` | Viewport height/width | `height: 100vh` | Full-screen sections |

---

## 6. Fix the Errors in Your Code

Three CSS mistakes appear very frequently when beginners write their first stylesheets. Each one causes rules to either not apply at all or apply to unintended elements.

**Error 1: Missing semicolon after a property value.**

CSS declarations must end with a semicolon. Omitting it causes the browser to merge the next property into the broken declaration, making both rules fail silently.

```css
/* Wrong: missing semicolon after "red" breaks font-size too */
p {
    color: red
    font-size: 16px;
}

/* Correct: every declaration ends with a semicolon */
p {
    color: red;
    font-size: 16px;
}
```

The browser cannot determine where the first declaration ends without the semicolon, so it treats `font-size: 16px` as part of the string value for `color`. Neither property applies. Always end every CSS declaration with a semicolon, including the last one in a block.

**Error 2: Confusing descendant selectors with combined class selectors.**

A space between two parts of a selector means "descendant." No space means "both conditions on the same element." These behave completely differently and the space is easy to overlook.

```css
/* Wrong: this targets <p> elements nested inside .highlight */
p .highlight {
    color: red;
}

/* Correct: this targets <p> elements that also have class "highlight" */
p.highlight {
    color: red;
}
```

`p .highlight` selects any element with class `highlight` that is a child or descendant of a `<p>`. `p.highlight` selects any `<p>` element that itself has the class `highlight`. The presence or absence of the space is the entire difference.

**Error 3: The CSS filename in `href` does not match the actual file.**

The browser fetches the stylesheet by making a network request for the exact filename in `href`. If the name is wrong by even one character or one letter's capitalization, the browser gets a 404 error and no styles are applied.

```html
<!-- Wrong: href points to "styles.css" but the file is named "style.css" -->
<link rel="stylesheet" href="styles.css">

<!-- Correct: href matches the actual filename exactly -->
<link rel="stylesheet" href="style.css">
```

When styles are not appearing on the page, always check the browser's network tab in DevTools (F12) first. A red entry for the CSS file usually means the filename or path is incorrect.

---

## 7. Exercises

**Exercise 1:** Create a profile card using an external CSS file. The card should have: a border with rounded corners, padding, a name displayed in bold blue, a title in gray italic, and a light gray background. Write the HTML in `profile.html` and the CSS in `profile.css`.

**Exercise 2:** Create `specificity.html` with five paragraphs. Apply styles using an element selector to all five, a class selector to two of them, an ID selector to one, and an inline style to another. Give the same property (for example, `color`) conflicting values through multiple selectors and observe which value wins.

**Exercise 3:** Create `navbar.html` with a navigation bar using an unordered list. Style it with CSS: remove bullet points, display items horizontally, add a dark background color and white link text, and use the `:hover` pseudo-class to change the link color when the user moves their cursor over it.

---

## 8. Solutions

**Solution for Exercise 1:**

Create `profile.html` with the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profile Card</title>
    <link rel="stylesheet" href="profile.css">
</head>
<body>
    <div class="profile-card">
        <h2 class="name">Budi Santoso</h2>
        <p class="title">Web Developer</p>
        <p>Bandung, Indonesia</p>
    </div>
</body>
</html>
```

Create `profile.css` with the following rules:

```css
body {
    font-family: Arial, sans-serif;
    display: flex;
    justify-content: center;
    padding: 40px;
    background: #f1f5f9;
}

.profile-card {
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 24px;
    max-width: 300px;
    background: #f8fafc;
}

.name {
    color: #2563eb;
    margin: 0 0 4px;
}

.title {
    color: #64748b;
    font-style: italic;
    margin: 0 0 12px;
}
```

The `.profile-card` class styles the entire card container with a border, rounded corners, consistent padding, and a subtle background. The `.name` and `.title` classes target only the specific text elements inside the card, applying color and font style without affecting other text on the page.

**Solution for Exercise 2:**

The specificity order from lowest to highest is: element selector, class selector, ID selector, inline style. When multiple rules target the same element with the same property, the rule with higher specificity wins. If specificity is equal, the rule that appears later in the CSS file wins. This is the "cascade" in Cascading Style Sheets.

**Solution for Exercise 3:**

Create `navbar.html` with the following HTML structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Navigation Bar</title>
    <style>
        nav ul {
            list-style: none;
            padding: 0;
            margin: 0;
            background: #1e293b;
            display: flex;
        }

        nav a {
            color: white;
            text-decoration: none;
            padding: 12px 16px;
            display: block;
        }

        nav a:hover {
            background: #334155;
        }
    </style>
</head>
<body>
    <nav>
        <ul>
            <li><a href="#">Home</a></li>
            <li><a href="#">About</a></li>
            <li><a href="#">Services</a></li>
            <li><a href="#">Contact</a></li>
        </ul>
    </nav>
</body>
</html>
```

`list-style: none` removes the bullet points from the `<ul>`. `display: flex` on `nav ul` places the `<li>` items in a horizontal row. Setting `display: block` on the `<a>` elements makes the entire padded area clickable, not just the text. The `:hover` pseudo-class applies styles only when the user's cursor is over the element, creating the interactive hover effect.

---

## 9. Next Up - Lesson 8

CSS controls presentation using rules made up of a selector and a declaration block. External stylesheets are always the best practice for real projects. Element selectors target all matching tags, class selectors target reusable groups, and ID selectors target unique elements. Specificity determines which rule wins when multiple declarations target the same property: inline styles beat IDs, IDs beat classes, and classes beat element selectors. Common properties include `color`, `background-color`, `font-family`, `font-size`, `border`, `padding`, and `margin`.

In Lesson 8, you will learn about the box model: the fundamental concept that every HTML element is a rectangular box with four layers - content, padding, border, and margin - and how to control those layers to create precise spacing and sizing.