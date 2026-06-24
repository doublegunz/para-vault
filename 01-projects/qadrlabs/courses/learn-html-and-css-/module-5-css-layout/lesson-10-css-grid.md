## 1. Before You Begin

Flexbox is excellent for aligning items along a single axis. When you need to control layout across both rows and columns simultaneously, CSS Grid is the right tool. Grid lets you define a two-dimensional canvas of rows and columns and then precisely place elements into specific cells within that canvas. A sidebar that takes up the left column while the main content takes the right two columns, with a full-width header above and a full-width footer below - this kind of layout is where Grid excels.

Flexbox and Grid are not competing technologies. They are complementary. Flexbox handles individual components (navigation links, button groups, card rows). Grid handles the overall page structure. In most real projects you will use both.

### What You'll Build

You will build a demonstration page that covers all major Grid features: a three-column card grid, fractional unit layouts, column and row spanning, named grid areas for a complete page skeleton, and a responsive card gallery using `auto-fit` that adjusts its column count automatically without any media queries.

### What You'll Learn

- ✅ `display: grid` and defining columns with `grid-template-columns`
- ✅ The `fr` unit for distributing available space
- ✅ `gap` for consistent spacing between grid cells
- ✅ `grid-column: span N` and `grid-row: span N` for spanning cells
- ✅ `grid-template-areas` for named, readable layouts
- ✅ `repeat(auto-fit, minmax())` for responsive grids
- ✅ When to use Grid vs Flexbox

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 9 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-10`, and press Enter.

---

## 3. Grid Basics

CSS Grid is activated by setting `display: grid` on a container element. On its own, this changes nothing visually. The power comes from `grid-template-columns`, which defines how many columns the grid has and how wide each one is. Every child element of that container automatically becomes a grid item and is placed into the grid one cell at a time, from left to right and top to bottom.

### Step 1: Create the Files

Right-click on `lesson-10` in VS Code, select **New File**, type `grid.html`. Right-click again, select **New File**, type `grid.css`. Both files go inside `lesson-10`.

### Step 2: Write the HTML

Add the following to `grid.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSS Grid</title>
    <link rel="stylesheet" href="grid.css">
</head>
<body>
    <h1>CSS Grid Layouts</h1>

    <h2>3-Column Grid</h2>
    <div class="grid-3col">
        <div class="item">1</div>
        <div class="item">2</div>
        <div class="item">3</div>
        <div class="item">4</div>
        <div class="item">5</div>
        <div class="item">6</div>
    </div>

    <h2>fr Units (1fr 2fr 1fr)</h2>
    <div class="grid-fr">
        <div class="item">Sidebar (1fr)</div>
        <div class="item">Content (2fr)</div>
        <div class="item">Aside (1fr)</div>
    </div>

    <h2>Spanning Columns and Rows</h2>
    <div class="grid-span">
        <div class="item span-2">Spans 2 columns</div>
        <div class="item">Normal</div>
        <div class="item">Normal</div>
        <div class="item">Normal</div>
        <div class="item">Normal</div>
    </div>

    <h2>Named Grid Areas (Page Layout)</h2>
    <div class="page-layout">
        <header class="item">Header</header>
        <nav class="item">Nav</nav>
        <main class="item">Main Content</main>
        <aside class="item">Sidebar</aside>
        <footer class="item">Footer</footer>
    </div>

    <h2>Responsive Card Gallery (auto-fit)</h2>
    <div class="card-gallery">
        <div class="card">Card 1</div>
        <div class="card">Card 2</div>
        <div class="card">Card 3</div>
        <div class="card">Card 4</div>
        <div class="card">Card 5</div>
        <div class="card">Card 6</div>
    </div>
</body>
</html>
```

### Step 3: Write the CSS

Add the following to `grid.css`:

```css
* { box-sizing: border-box; margin: 0; }
body { font-family: Arial, sans-serif; max-width: 900px; margin: 20px auto; padding: 0 15px; }
h1, h2 { margin: 20px 0 10px; }

.item {
    background: #dbeafe;
    border: 2px solid #2563eb;
    padding: 16px;
    border-radius: 6px;
    text-align: center;
    font-weight: bold;
}

.grid-3col {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 10px;
    margin-bottom: 20px;
}

.grid-fr {
    display: grid;
    grid-template-columns: 1fr 2fr 1fr;
    gap: 10px;
    margin-bottom: 20px;
}

.grid-span {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin-bottom: 20px;
}

.span-2 { grid-column: span 2; }

.page-layout {
    display: grid;
    grid-template-areas:
        "header header header"
        "nav    main   sidebar"
        "footer footer footer";
    grid-template-columns: 200px 1fr 200px;
    grid-template-rows: auto 300px auto;
    gap: 10px;
    margin-bottom: 20px;
}

.page-layout header { grid-area: header; background: #1e293b; color: white; }
.page-layout nav    { grid-area: nav;    background: #f0fdf4; }
.page-layout main   { grid-area: main;   background: #eff6ff; }
.page-layout aside  { grid-area: sidebar; background: #fef3c7; }
.page-layout footer { grid-area: footer; background: #1e293b; color: white; }

.card-gallery {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-bottom: 20px;
}

.card {
    background: white;
    border: 1px solid #e2e8f0;
    padding: 20px;
    border-radius: 8px;
    text-align: center;
}
```

`grid-template-columns: 1fr 1fr 1fr` creates three equal columns. The `fr` unit stands for "fractional unit" and represents a share of the available space after gaps are removed. Three columns of `1fr` each divide the remaining space equally into thirds. `grid-template-columns: 1fr 2fr 1fr` gives the middle column twice as much space as each side column - the total is four fractions, so the sides are 25% each and the middle is 50%.

`gap` sets the spacing between all grid cells simultaneously, replacing the need for margin calculations on individual items.

`repeat(3, 1fr)` is shorthand for `1fr 1fr 1fr`. It is especially useful when you have many columns with the same size.

`grid-column: span 2` on the `.span-2` item tells the browser that this item should occupy two consecutive column tracks instead of one. The browser automatically places subsequent items in the remaining cells.

`grid-template-areas` defines the layout using a named map. Each string represents a row. Repeating an area name across cells in the same string spans that area across those columns. The `grid-area` property on each child element must match exactly a name used in the template - the browser uses this to place each element in its designated zone.

`repeat(auto-fit, minmax(200px, 1fr))` is a powerful one-liner for responsive grids. `auto-fit` tells the browser to create as many columns as fit within the container. `minmax(200px, 1fr)` means each column is at minimum 200px wide and at maximum as wide as one fraction of the available space. On a wide screen you get many columns; on a narrow screen you get fewer, down to one. No media queries required.

### Step 4: Save and View

Press **Ctrl+S** for both files and open `grid.html` with Live Server. Resize the browser window while looking at the card gallery to see `auto-fit` adjust the number of columns automatically.

---

## 4. Grid vs Flexbox

Understanding when to reach for each tool prevents overengineering. The distinction is simple: Flexbox is one-dimensional, Grid is two-dimensional.

| Feature | Flexbox | CSS Grid |
|---------|---------|---------|
| Dimensions | One (row or column) | Two (rows and columns) |
| Best for | Components: navbars, button groups, card rows | Page layouts, galleries, dashboards |
| Item control | Items grow and shrink along one axis | Items placed in specific row and column positions |
| Alignment | Along a main and cross axis | Along both axes independently |

The practical rule of thumb is: use Flexbox for the contents inside a section, use Grid for the sections themselves. A Grid defines where the header, sidebar, main content, and footer go on the page. Flexbox then arranges the links inside the header or the cards inside the main content area.

---

## 5. Key Grid Properties Reference

CSS Grid has a large set of properties, but a small core handles the majority of real use cases.

```css
/* Container properties */
display: grid;

grid-template-columns: 1fr 2fr 1fr;
grid-template-columns: repeat(3, 1fr);
grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));

grid-template-rows: auto 300px auto;

gap: 16px;

grid-template-areas:
    "header header"
    "main   sidebar";

/* Item properties */
grid-column: span 2;
grid-row: span 2;
grid-column: 1 / 3;
grid-area: header;
```

`grid-column: 1 / 3` is an alternative to `span` notation. It places the item starting at column line 1 and ending at column line 3, which means it spans two column tracks. Grid line numbers start at 1 on the left edge and count to the right. `grid-area: header` places the item into the cell named "header" in the `grid-template-areas` map.

---

## 6. Fix the Errors in Your Code

Three Grid mistakes appear frequently among beginners. Each one produces a layout that looks wrong for a reason that is not immediately obvious.

**Error 1: Using `display: grid` without defining columns.**

Setting `display: grid` alone does not create a multi-column layout. Without `grid-template-columns`, the browser defaults to a single column and items stack vertically.

```css
/* Wrong: grid is activated but no columns are defined */
.grid { display: grid; }

/* Correct: define how many columns and how wide they are */
.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
}
```

Every grid that needs more than one column must have an explicit `grid-template-columns` declaration. Without it, CSS Grid behaves identically to a normal block container.

**Error 2: Confusing `auto-fit` and `auto-fill`.**

Both keywords tell the browser to generate as many columns as will fit, but they handle empty space differently when items do not fill the row completely.

```css
/* auto-fill: empty columns are kept, items do not stretch to fill them */
grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));

/* auto-fit: empty columns collapse, items stretch to fill the remaining space */
grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
```

For responsive card galleries where you want items to stretch and fill the row, use `auto-fit`. For situations where you need the grid to reserve space for future items, use `auto-fill`.

**Error 3: A `grid-area` name that does not match the template.**

The name given in `grid-area` on a child element must exactly match the name used in `grid-template-areas` on the parent. A typo or a different word causes that element to be placed outside the defined template.

```css
/* Wrong: template defines "main" but element uses "content" */
.page { grid-template-areas: "header header" "main sidebar"; }
.page main { grid-area: content; }

/* Correct: both must use the same name */
.page { grid-template-areas: "header header" "main sidebar"; }
.page main { grid-area: main; }
```

The names in `grid-template-areas` are not CSS selectors - they are arbitrary labels you choose. The `grid-area` on each element must use exactly the same string, character for character.

---

## 7. Exercises

**Exercise 1:** Create `gallery.html` with a photo gallery containing eight image cards. Use `grid-template-columns: repeat(auto-fit, minmax(180px, 1fr))` on the grid container. Add `gap`, `border-radius`, and `box-shadow` to each card, and use a placeholder image inside each one.

**Exercise 2:** Create `dashboard.html` with a full-page dashboard layout using named grid areas. Include a header spanning the full width, a left sidebar for navigation, a large main content area, and a footer spanning the full width. Set `min-height: 100vh` on the grid to fill the screen.

**Exercise 3:** Create `pricing.html` with three pricing plan cards arranged using CSS Grid. The middle card (the recommended plan) should stand out with a blue background, white text, and a slightly larger size using `transform: scale(1.05)`.

---

## 8. Solutions

**Solution for Exercise 1:**

Create a new file called `gallery.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Photo Gallery</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 20px; background: #f8fafc; }

        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
        }

        .gallery-card {
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
            background: white;
        }

        .gallery-card img {
            width: 100%;
            display: block;
        }

        .gallery-card p {
            padding: 8px 12px;
            font-size: 0.85em;
            color: #64748b;
        }
    </style>
</head>
<body>
    <h1>Photo Gallery</h1>
    <div class="gallery">
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 1"><p>Landscape 1</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 2"><p>Landscape 2</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 3"><p>Landscape 3</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 4"><p>Landscape 4</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 5"><p>Landscape 5</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 6"><p>Landscape 6</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 7"><p>Landscape 7</p></div>
        <div class="gallery-card"><img src="https://placehold.co/300x200" alt="Photo 8"><p>Landscape 8</p></div>
    </div>
</body>
</html>
```

`repeat(auto-fit, minmax(180px, 1fr))` creates as many columns as can fit at a minimum width of 180px. On a 900px container with 12px gaps, approximately four columns fit. When the browser is narrower, fewer columns are created automatically. `overflow: hidden` on the card ensures the image corners respect the card's `border-radius`.

**Solution for Exercise 2:**

Create a new file called `dashboard.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <style>
        * { box-sizing: border-box; margin: 0; }
        body { font-family: Arial, sans-serif; }

        .dashboard {
            display: grid;
            grid-template-areas:
                "header header"
                "sidebar main"
                "footer footer";
            grid-template-columns: 250px 1fr;
            grid-template-rows: 60px 1fr 50px;
            min-height: 100vh;
            gap: 0;
        }

        .dashboard header  { grid-area: header;  background: #1e293b; color: white; display: flex; align-items: center; padding: 0 20px; font-size: 1.2em; font-weight: bold; }
        .dashboard nav     { grid-area: sidebar; background: #334155; color: #cbd5e1; padding: 20px; }
        .dashboard main    { grid-area: main;    background: #f8fafc; padding: 30px; }
        .dashboard footer  { grid-area: footer;  background: #1e293b; color: #94a3b8; display: flex; align-items: center; justify-content: center; font-size: 0.85em; }

        .dashboard nav ul  { list-style: none; padding: 0; }
        .dashboard nav li  { padding: 8px 0; }
        .dashboard nav a   { color: #93c5fd; text-decoration: none; }
    </style>
</head>
<body>
    <div class="dashboard">
        <header>Admin Dashboard</header>
        <nav>
            <ul>
                <li><a href="#">Overview</a></li>
                <li><a href="#">Users</a></li>
                <li><a href="#">Reports</a></li>
                <li><a href="#">Settings</a></li>
            </ul>
        </nav>
        <main>
            <h1>Welcome to the Dashboard</h1>
            <p>Select an item from the sidebar to get started.</p>
        </main>
        <footer>Copyright 2026 Admin Panel</footer>
    </div>
</body>
</html>
```

`grid-template-areas` makes the layout intent immediately readable in the CSS. `grid-template-rows: 60px 1fr 50px` sets the header to a fixed 60px, the middle row to fill all remaining space, and the footer to a fixed 50px. `min-height: 100vh` ensures the dashboard fills the full viewport height even when the content area is empty.

**Solution for Exercise 3:**

Create a new file called `pricing.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pricing</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 40px; background: #f8fafc; }

        .pricing {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            align-items: center;
            max-width: 800px;
            margin: 0 auto;
        }

        .plan {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
        }

        .plan.featured {
            background: #2563eb;
            color: white;
            transform: scale(1.05);
            box-shadow: 0 8px 24px rgba(37,99,235,0.3);
        }

        .plan h3 { font-size: 1.2rem; margin-bottom: 10px; }
        .plan .price { font-size: 2rem; font-weight: bold; margin: 10px 0; }
        .plan p { font-size: 0.9rem; opacity: 0.7; }
    </style>
</head>
<body>
    <h1 style="text-align:center; margin-bottom:30px">Choose Your Plan</h1>
    <div class="pricing">
        <div class="plan">
            <h3>Basic</h3>
            <div class="price">$9<span style="font-size:1rem">/mo</span></div>
            <p>For individuals and small projects</p>
        </div>
        <div class="plan featured">
            <h3>Pro</h3>
            <div class="price">$29<span style="font-size:1rem">/mo</span></div>
            <p>Most popular for growing teams</p>
        </div>
        <div class="plan">
            <h3>Enterprise</h3>
            <div class="price">$99<span style="font-size:1rem">/mo</span></div>
            <p>For large organizations and agencies</p>
        </div>
    </div>
</body>
</html>
```

`align-items: center` on the grid container vertically centers all three cards relative to each other, so the `.featured` card's increased size from `transform: scale(1.05)` does not push the other cards down. `transform: scale(1.05)` scales the element up by 5% from its center without affecting the layout flow of surrounding elements.

---

## 9. Next Up - Lesson 11

CSS Grid creates two-dimensional layouts using rows and columns. `display: grid` activates the grid on a container. `grid-template-columns` defines the number and width of columns, using the `fr` unit to distribute available space proportionally. `gap` adds consistent spacing between all cells. `grid-column: span N` makes an item occupy multiple columns. `grid-template-areas` creates a named map of the layout that is both readable and maintainable. `repeat(auto-fit, minmax())` builds responsive grids that adjust their column count automatically. Use Grid for page structure and Flexbox for the components within each section.

In Lesson 11, you will learn about typography, colors, and backgrounds: using Google Fonts, CSS custom properties (variables), gradients, box shadows, and smooth hover transitions to turn a functional page into a polished, professional design.