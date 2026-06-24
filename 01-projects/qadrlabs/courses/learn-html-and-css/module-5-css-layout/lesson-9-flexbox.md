## 1. Before You Begin

Before Flexbox, creating horizontal layouts in CSS required using `float`, clearing those floats, or relying on `display: inline-block` with its quirky whitespace behavior. Centering an element both horizontally and vertically required complex combinations of `position: absolute` and negative margins. All of this was hacky, fragile, and hard to maintain.

Flexbox (Flexible Box Layout) was introduced specifically to solve alignment and distribution problems. It works in one dimension at a time: either a row (horizontal) or a column (vertical). You set `display: flex` on a container element and its direct children automatically become "flex items" that respond to alignment and distribution properties. The result is predictable, readable, and requires far less code than the old approaches.

### What You'll Build

You will build a set of demonstrations covering all major Flexbox properties, culminating in two practical components: a navigation bar where the brand logo is on the left and navigation links are on the right, and a three-column card layout where all cards share equal width.

### What You'll Learn

- ✅ `display: flex` and the flex container
- ✅ `flex-direction`: `row`, `column`, `row-reverse`, `column-reverse`
- ✅ `justify-content`: `flex-start`, `center`, `flex-end`, `space-between`, `space-around`, `space-evenly`
- ✅ `align-items`: `flex-start`, `center`, `flex-end`, `stretch`
- ✅ `gap` for consistent spacing between items
- ✅ `flex-wrap` for allowing items to wrap to the next line
- ✅ `flex: 1` for equal-width items

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 8 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-09`, and press Enter.

---

## 3. Flex Container Basics

Flexbox requires at least two elements: a container (the parent) and one or more items (the children). You apply Flexbox properties to the container, and it automatically controls how the items are arranged inside it. The container never needs to know how many items it holds - Flexbox distributes them based on the properties you set.

### Step 1: Create the Files

Right-click on `lesson-09`, select **New File**, type `flexbox.html`. Right-click again, select **New File**, type `flexbox.css`. Both files go inside `lesson-09`.

### Step 2: Write the HTML

Add the following to `flexbox.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flexbox</title>
    <link rel="stylesheet" href="flexbox.css">
</head>
<body>
    <h1>Flexbox Layouts</h1>

    <h2>Basic Row (default)</h2>
    <div class="flex-demo">
        <div class="box">1</div>
        <div class="box">2</div>
        <div class="box">3</div>
    </div>

    <h2>justify-content: space-between</h2>
    <div class="flex-demo jc-between">
        <div class="box">A</div>
        <div class="box">B</div>
        <div class="box">C</div>
    </div>

    <h2>justify-content: center</h2>
    <div class="flex-demo jc-center">
        <div class="box">A</div>
        <div class="box">B</div>
        <div class="box">C</div>
    </div>

    <h2>align-items: center (vertical centering)</h2>
    <div class="flex-demo ai-center" style="height:150px">
        <div class="box">Centered</div>
        <div class="box" style="height:80px">Tall</div>
        <div class="box">Centered</div>
    </div>

    <h2>Perfect Center (both axes)</h2>
    <div class="perfect-center">
        <div class="box">Centered!</div>
    </div>

    <h2>flex-wrap: wrap (items wrap to next line)</h2>
    <div class="flex-demo wrap-demo">
        <div class="box w-200">1</div>
        <div class="box w-200">2</div>
        <div class="box w-200">3</div>
        <div class="box w-200">4</div>
        <div class="box w-200">5</div>
    </div>

    <h2>flex: 1 (equal width children)</h2>
    <div class="flex-demo">
        <div class="box flex-1">Equal</div>
        <div class="box flex-1">Equal</div>
        <div class="box flex-1">Equal</div>
    </div>

    <h2>Practical: Navigation Bar</h2>
    <nav class="navbar">
        <a href="#" class="brand">MySite</a>
        <div class="nav-links">
            <a href="#">Home</a>
            <a href="#">About</a>
            <a href="#">Services</a>
            <a href="#">Contact</a>
        </div>
    </nav>

    <h2>Practical: Three Cards</h2>
    <div class="cards">
        <div class="card">
            <h3>Card 1</h3>
            <p>Flexbox makes equal-width card layouts simple and reliable.</p>
        </div>
        <div class="card">
            <h3>Card 2</h3>
            <p>Each card takes equal width automatically with flex: 1.</p>
        </div>
        <div class="card">
            <h3>Card 3</h3>
            <p>Gap adds consistent spacing between cards without margin math.</p>
        </div>
    </div>
</body>
</html>
```

### Step 3: Write the CSS

Add the following to `flexbox.css`:

```css
* { box-sizing: border-box; margin: 0; }
body { font-family: Arial, sans-serif; max-width: 800px; margin: 20px auto; padding: 0 15px; }
h1, h2 { margin: 20px 0 10px; }

.box {
    background: #dbeafe;
    border: 2px solid #2563eb;
    padding: 16px 24px;
    border-radius: 6px;
    text-align: center;
    font-weight: bold;
}

.flex-demo {
    display: flex;
    gap: 10px;
    background: #f8fafc;
    padding: 10px;
    border-radius: 8px;
    margin-bottom: 16px;
}

.jc-between { justify-content: space-between; }
.jc-center { justify-content: center; }

.ai-center { align-items: center; background: #fef3c7; }

.perfect-center {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 200px;
    background: #f0fdf4;
    border-radius: 8px;
    margin-bottom: 16px;
}

.wrap-demo { flex-wrap: wrap; }
.w-200 { min-width: 200px; flex: 1; }

.flex-1 { flex: 1; }

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #1e293b;
    padding: 12px 20px;
    border-radius: 8px;
    margin-bottom: 16px;
}

.navbar .brand {
    color: white;
    font-weight: bold;
    font-size: 1.2em;
    text-decoration: none;
}

.nav-links { display: flex; gap: 16px; }
.nav-links a { color: #93c5fd; text-decoration: none; }
.nav-links a:hover { color: white; }

.cards { display: flex; gap: 16px; margin-bottom: 16px; }
.card { flex: 1; background: white; border: 1px solid #e2e8f0; padding: 20px; border-radius: 8px; }
.card h3 { margin-bottom: 8px; }
```

`display: flex` on `.flex-demo` activates Flexbox on that element, making all its direct children flex items arranged in a row by default. The default `flex-direction` is `row`, which places items horizontally from left to right.

`justify-content` controls alignment along the main axis - horizontal when `flex-direction: row`. `space-between` pushes the first item to the left edge, the last item to the right edge, and distributes remaining items evenly in between with equal gaps. `center` groups all items together in the middle of the container.

`align-items` controls alignment along the cross axis - vertical when `flex-direction: row`. `align-items: center` vertically centers all items within the container's height, regardless of how tall each individual item is.

The `.perfect-center` class combines both properties to achieve perfect centering on both axes simultaneously - something that required significant CSS trickery before Flexbox.

`flex-wrap: wrap` allows items to move to the next line instead of shrinking when they cannot all fit in one row. Without it, Flexbox forces all items onto one line even if they overflow the container.

`flex: 1` on a flex item tells it to grow and occupy an equal share of the remaining space in the container. When all items have `flex: 1`, they all expand to equal widths automatically, regardless of how much content each one contains.

In the `.navbar`, `justify-content: space-between` pushes the brand to the left and the nav links to the right, with all remaining space in the middle. The `.nav-links` div is itself a flex container, which places the individual links in a horizontal row with a consistent `gap` between them. This pattern of nesting flex containers inside flex items is a common and powerful technique.

### Step 4: Save and View

Press **Ctrl+S** for both files and open `flexbox.html` with Live Server. Work through each section from top to bottom and observe how each set of Flexbox properties changes the layout.

---

## 4. Flexbox Properties Summary

Flexbox properties are divided into two categories: container properties (applied to the parent element) and item properties (applied to the children).

**Container properties** (applied to the parent with `display: flex`):

| Property | Values | Purpose |
|----------|--------|---------|
| `display` | `flex` | Enables Flexbox on the container |
| `flex-direction` | `row`, `column`, `row-reverse`, `column-reverse` | Sets the main axis direction |
| `justify-content` | `flex-start`, `center`, `flex-end`, `space-between`, `space-around`, `space-evenly` | Aligns items along the main axis |
| `align-items` | `flex-start`, `center`, `flex-end`, `stretch`, `baseline` | Aligns items along the cross axis |
| `flex-wrap` | `nowrap`, `wrap`, `wrap-reverse` | Controls whether items wrap to a new line |
| `gap` | any length value | Adds space between items |

**Item properties** (applied to the children inside a flex container):

| Property | Values | Purpose |
|----------|--------|---------|
| `flex: 1` | number | Makes the item grow to fill available space equally |
| `flex-grow` | number | How much the item grows relative to siblings |
| `flex-shrink` | number | How much the item shrinks relative to siblings |
| `flex-basis` | length | The item's initial size before growing or shrinking |
| `align-self` | `auto`, `flex-start`, `center`, `flex-end` | Overrides `align-items` for this specific item |
| `order` | number | Reorders the item visually without changing the HTML |

---

## 5. Fix the Errors in Your Code

Three Flexbox mistakes appear frequently when developers first start using the layout system. Each one produces a result that looks wrong but is not immediately obvious why.

**Error 1: Applying `display: flex` to both the container and its items.**

Setting `display: flex` on both the parent and the children makes each child behave as a flex container for its own children. This is not inherently wrong, but when done by accident because a developer is unsure which element needs it, it causes confusion about why certain properties are or are not working.

```css
/* Wrong: both container and items are flex containers unnecessarily */
.container { display: flex; }
.container .item { display: flex; }

/* Correct: only the parent needs display: flex to control its children */
.container { display: flex; }
```

`display: flex` on a parent element makes its direct children into flex items. The children do not need `display: flex` themselves unless they also need to control the alignment of their own inner content.

**Error 2: Using `justify-content` to center vertically.**

The most common Flexbox confusion is mixing up which axis each property controls. A very large proportion of Flexbox questions come down to this exact mistake.

```css
/* Wrong: justify-content centers on the main (horizontal) axis, not vertical */
.container { display: flex; justify-content: center; }

/* Correct: align-items centers on the cross (vertical) axis */
.container { display: flex; align-items: center; }

/* For perfect centering on both axes, use both */
.container {
    display: flex;
    justify-content: center;
    align-items: center;
}
```

In a standard `flex-direction: row` container, `justify-content` controls horizontal positioning and `align-items` controls vertical positioning. If you need vertical centering, `align-items: center` is the property to use. The container must also have an explicit `height` for vertical centering to be visible.

**Error 3: Expecting `gap` to work in very old browsers.**

`gap` for Flexbox became well-supported in all major browsers around 2021. If you are targeting users who may be on older browsers (particularly older versions of Safari), `gap` may not work as expected.

```css
/* Works in all modern browsers (Chrome 84+, Firefox 63+, Safari 14.1+) */
.container { display: flex; gap: 20px; }

/* Fallback for older browsers: apply margin to children instead */
.container .item { margin-right: 20px; }
.container .item:last-child { margin-right: 0; }
```

For modern projects targeting current browsers, `gap` is the preferred approach. It is cleaner and avoids the need for a `:last-child` rule to remove the trailing margin. For projects that must support older browsers, apply margin to the items directly.

---

## 6. Exercises

**Exercise 1:** Create `footer.html` with a three-column footer using Flexbox. The footer should have a dark background and contain three columns: Company (with a short description), Links (with an unordered list of five navigation links), and Contact (with an address and email). All three columns should share equal width using `flex: 1`.

**Exercise 2:** Create `hero.html` with a hero section using Flexbox. Place descriptive text on the left (headline, subheadline, and a button) and a placeholder image on the right. Both sides should be vertically centered relative to each other. The text side should take two-thirds of the width and the image side should take one-third.

**Exercise 3:** Create `badges.html` with a horizontally centered row of technology badge pills. Include at least six badges (HTML, CSS, JavaScript, PHP, Java, Python). Use `flex-wrap: wrap` so they wrap to a new line at narrower widths. Each badge should have a colored background, white text, `border-radius: 20px`, and consistent padding.

---

## 7. Solutions

**Solution for Exercise 1:**

Create a new file called `footer.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Footer</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; margin: 0; }

        .footer {
            display: flex;
            gap: 40px;
            background: #1e293b;
            color: #cbd5e1;
            padding: 40px;
        }

        .footer-col { flex: 1; }

        .footer-col h4 { color: white; margin: 0 0 12px; }

        .footer-col ul { list-style: none; padding: 0; margin: 0; }

        .footer-col li { margin-bottom: 8px; }

        .footer-col a { color: #94a3b8; text-decoration: none; }

        .footer-col a:hover { color: white; }
    </style>
</head>
<body>
    <footer class="footer">
        <div class="footer-col">
            <h4>Company</h4>
            <p>We build clean, accessible, and responsive web experiences for clients worldwide.</p>
        </div>
        <div class="footer-col">
            <h4>Links</h4>
            <ul>
                <li><a href="#">Home</a></li>
                <li><a href="#">About</a></li>
                <li><a href="#">Services</a></li>
                <li><a href="#">Blog</a></li>
                <li><a href="#">Contact</a></li>
            </ul>
        </div>
        <div class="footer-col">
            <h4>Contact</h4>
            <p>Jl. Merdeka No. 10<br>Bandung, Jawa Barat</p>
            <p>hello@example.com</p>
        </div>
    </footer>
</body>
</html>
```

`display: flex` on `.footer` places all three column `<div>` elements in a horizontal row. `flex: 1` on each `.footer-col` instructs each column to grow equally, dividing the available space into three equal thirds. `gap: 40px` adds a consistent 40px gap between each column without requiring any margin on the columns themselves.

**Solution for Exercise 2:**

Create a new file called `hero.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hero Section</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; margin: 0; }

        .hero {
            display: flex;
            align-items: center;
            gap: 40px;
            padding: 60px 40px;
            background: #f8fafc;
        }

        .hero-text { flex: 2; }

        .hero-text h1 { font-size: 2.5rem; color: #1e293b; margin: 0 0 12px; }

        .hero-text p { font-size: 1.1rem; color: #64748b; margin: 0 0 24px; }

        .hero-text a {
            background: #2563eb;
            color: white;
            padding: 12px 24px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: bold;
        }

        .hero-image { flex: 1; }

        .hero-image img { width: 100%; border-radius: 12px; }
    </style>
</head>
<body>
    <section class="hero">
        <div class="hero-text">
            <h1>Build Beautiful Websites</h1>
            <p>Learn HTML and CSS from scratch and create professional, responsive web pages.</p>
            <a href="#">Get Started</a>
        </div>
        <div class="hero-image">
            <img src="https://placehold.co/400x300" alt="Hero illustration">
        </div>
    </section>
</body>
</html>
```

`align-items: center` vertically centers the text column and image column relative to each other, so neither is pinned to the top. `flex: 2` on `.hero-text` and `flex: 1` on `.hero-image` means the text side takes twice the space of the image side, resulting in a 2:1 ratio across the row. `width: 100%` on the image ensures it fills its flex column completely.

**Solution for Exercise 3:**

Create a new file called `badges.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Technology Badges</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 40px; }

        .badges {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            justify-content: center;
        }

        .badge {
            background: #dbeafe;
            color: #1e40af;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1 style="text-align:center">Technology Stack</h1>
    <div class="badges">
        <span class="badge">HTML</span>
        <span class="badge">CSS</span>
        <span class="badge">JavaScript</span>
        <span class="badge">PHP</span>
        <span class="badge">Java</span>
        <span class="badge">Python</span>
    </div>
</body>
</html>
```

`justify-content: center` groups all badges toward the center of the row. `flex-wrap: wrap` allows badges to move to the next line if the screen is not wide enough to fit all of them, preventing horizontal overflow. `border-radius: 20px` on elements with padding creates the pill shape by making the corners more rounded than the height of the element itself.

---

## 10. Next Up - Lesson 10

Flexbox aligns and distributes elements in one dimension: a row or a column. `display: flex` on the parent makes its children flex items. `justify-content` controls positioning along the main axis (horizontal in a row), while `align-items` controls positioning along the cross axis (vertical in a row). Combining both with `center` achieves perfect centering on both axes simultaneously. `gap` adds consistent spacing between items. `flex: 1` distributes available space equally. `flex-wrap: wrap` allows items to flow to the next line when space runs out.

In Lesson 10, you will learn CSS Grid: the two-dimensional layout system that lets you place elements into rows and columns simultaneously, making it ideal for complex page layouts that Flexbox alone cannot handle cleanly.