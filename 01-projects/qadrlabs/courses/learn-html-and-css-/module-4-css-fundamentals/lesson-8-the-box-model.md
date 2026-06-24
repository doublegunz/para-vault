## 1. Before You Begin

Every HTML element is a rectangular box. This is not a simplification - it is literally how browsers render everything. Text, paragraphs, images, links, and even the invisible `<div>` containers are all boxes. The CSS Box Model defines exactly how much space each box occupies: the content area where text or media appears, padding which is the space between the content and the border, the border itself which is the visible edge, and margin which is the transparent space outside the border that separates this element from its neighbors.

Understanding the box model is the single most important concept for CSS layout. Until you understand it, spacing and sizing will feel unpredictable. Once you do, you will be able to control the layout of any element with confidence.

### What You'll Build

You will create two files: `box-model.html` to visualize all four layers of the box model and compare `content-box` versus `border-box` sizing, and `spacing.html` to practice margin, padding, centering, and building a complete card component.

### What You'll Learn

- ✅ The four layers: content, padding, border, margin
- ✅ `width`, `height`, `padding`, `margin`, `border`
- ✅ The critical `box-sizing: border-box` property
- ✅ Margin shorthand notation
- ✅ Margin collapse between adjacent block elements
- ✅ Centering block elements with `margin: 0 auto`
- ✅ Using browser DevTools to inspect the box model visually

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 7 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-08`, and press Enter.

---

## 3. The Box Model Explained

Each HTML element consists of four concentric layers, ordered from the inside out. The innermost layer is the content itself. Surrounding it is padding - transparent space that separates the content from the border. The border wraps around the padding. And outside the border is the margin, which is also transparent and creates distance between this element and its neighboring elements.

```
+-----------------------------+
|           MARGIN            |  ← Space outside the border
|  +-----------------------+  |
|  |        BORDER         |  |  ← The visible edge
|  |  +-----------------+  |  |
|  |  |    PADDING      |  |  |  ← Space inside the border
|  |  |  +-----------+  |  |  |
|  |  |  |  CONTENT  |  |  |  |  ← Text, image, or other content
|  |  |  +-----------+  |  |  |
|  |  +-----------------+  |  |
|  +-----------------------+  |
+-----------------------------+
```

### Step 1: Create the File

Right-click on the `lesson-08` folder in VS Code, select **New File**, type `box-model.html`, and press Enter.

### Step 2: Write the Code

Add the following to `box-model.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The Box Model</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 20px auto; padding: 0 15px; }

        .box {
            width: 300px;
            padding: 20px;
            border: 3px solid #2563eb;
            margin: 20px 0;
            background: #eff6ff;
        }

        .box-default {
            width: 300px;
            padding: 20px;
            border: 3px solid #dc2626;
            background: #fef2f2;
        }

        .box-border-box {
            width: 300px;
            padding: 20px;
            border: 3px solid #16a34a;
            background: #f0fdf4;
            box-sizing: border-box;
        }

        .shorthand {
            padding: 10px 20px 10px 20px;
            margin: 20px auto;
            border: 2px solid #64748b;
            width: 400px;
            background: #f8fafc;
            box-sizing: border-box;
        }
    </style>
</head>
<body>
    <h1>The CSS Box Model</h1>

    <h2>Basic Box</h2>
    <div class="box">
        <p>This box has: width 300px, padding 20px, border 3px, margin 20px.</p>
    </div>

    <h2>box-sizing: content-box (default)</h2>
    <div class="box-default">
        <p>Width 300px, but total visible width = 300 + 40 (padding) + 6 (border) = <strong>346px</strong>.</p>
    </div>

    <h2>box-sizing: border-box (recommended)</h2>
    <div class="box-border-box">
        <p>Width 300px = total visible width. Padding and border are <strong>included</strong> in the 300px.</p>
    </div>

    <h2>Shorthand Properties</h2>
    <div class="shorthand">
        <p>This box uses shorthand: <code>padding: 10px 20px</code>, <code>margin: 20px auto</code> (centered), <code>border: 2px solid #64748b</code>.</p>
    </div>

    <h2>Inspect It!</h2>
    <p>Right-click any box above and select <strong>Inspect</strong>. In the DevTools panel, look for the box model diagram at the bottom of the Styles or Computed tab. It shows the exact pixel values for content, padding, border, and margin as color-coded nested rectangles.</p>
</body>
</html>
```

The `.box-default` class uses the CSS default sizing model, `content-box`. In this model, `width: 300px` sets only the content area to 300px. Padding and border are then added on top of that measurement, making the total visible width 300 + 40 (20px padding on each side) + 6 (3px border on each side) = 346px. This calculation is counterintuitive and leads to layouts that overflow or misalign.

The `.box-border-box` class uses `box-sizing: border-box`, which changes the calculation so that `width: 300px` sets the total visible box to exactly 300px. The browser automatically adjusts the content area inward to accommodate the padding and border within that 300px. The width you write is the width you get.

### Step 3: Save and View

Press **Ctrl+S** and open with Live Server. Notice that the `.box-default` (red) is visibly wider than the `.box-border-box` (green), even though both declare `width: 300px`. Right-click on any box and select **Inspect** to open DevTools and explore the box model diagram.

---

## 4. box-sizing: border-box

The default `box-sizing: content-box` is the browser's historical behavior, carried forward from the early days of CSS. It causes `width` to mean "the content area only," which means adding padding or a border always makes the element larger than the declared width. Most developers find this unexpected and difficult to work with.

`box-sizing: border-box` makes `width` mean "the total box including padding and border." Set `width: 300px` and the total rendered box is 300px, regardless of how much padding or border you add.

The standard practice in modern CSS is to apply `border-box` to every element on the page using the universal selector:

```css
*, *::before, *::after {
    box-sizing: border-box;
}
```

`*` targets every element. `*::before` and `*::after` target pseudo-elements generated by CSS that also participate in layout. Adding this rule at the top of every stylesheet means you never have to think about `content-box` math again - every element you style will behave predictably.

---

## 5. Margin, Padding, and Centering

Margin and padding are the primary tools for controlling spacing in CSS. Padding creates space inside the box, between the content and the border. Margin creates space outside the box, between this element and the elements around it. Both properties support shorthand notation to set multiple sides at once.

### Step 1: Create the File

Right-click on `lesson-08`, select **New File**, type `spacing.html`, and press Enter.

### Step 2: Write the Code

Add the following to `spacing.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Spacing</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; }

        .padding-demo {
            padding-top: 10px;
            padding-right: 20px;
            padding-bottom: 10px;
            padding-left: 20px;
            background: #dbeafe;
            margin-bottom: 10px;
        }

        .margin-demo {
            margin-top: 30px;
            margin-bottom: 30px;
            background: #fef3c7;
            padding: 10px;
        }

        .centered {
            width: 400px;
            margin: 0 auto;
            background: #d1fae5;
            padding: 20px;
            text-align: center;
        }

        .card {
            width: 100%;
            max-width: 400px;
            margin: 20px auto;
            padding: 24px;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .card h3 { margin-top: 0; }
    </style>
</head>
<body>
    <h1 style="text-align:center">Spacing and Centering</h1>

    <div class="padding-demo">Padding: space INSIDE the border.</div>
    <div class="margin-demo">Margin: space OUTSIDE the border.</div>

    <div class="centered">This box is centered with <code>margin: 0 auto</code>.</div>

    <div class="card">
        <h3>Card Title</h3>
        <p>This card uses the box model effectively: padding for inner space, border for the edge, border-radius for rounded corners, box-shadow for depth, and margin auto for centering.</p>
    </div>
</body>
</html>
```

The `.padding-demo` element has `padding-top/right/bottom/left` specified individually on four separate lines. This is the longform way to set each side separately. `margin: 0 auto` on the `.centered` element sets the top and bottom margin to zero and the left and right margins to `auto`. When both horizontal margins are `auto`, the browser splits the remaining space equally between them, which centers the element. This only works on block-level elements that have a declared `width`.

The `.card` element demonstrates a complete, real-world card component. `box-shadow` adds a soft drop shadow to create the appearance of depth without using a border. The value `0 2px 8px rgba(0,0,0,0.08)` sets the horizontal offset to 0, vertical offset to 2px, blur radius to 8px, and color to black at 8% opacity - subtle enough to feel professional rather than garish.

### Step 3: Save and View

Press **Ctrl+S** and view in the browser. Observe how the padding demo has space inside its background color, while the margin demo has blank space above and below it separating it from other elements.

### Margin Shorthand

CSS margin (and padding) supports a shorthand notation based on the number of values provided:

```css
margin: 10px;                 /* All four sides: 10px */
margin: 10px 20px;            /* Top and bottom: 10px | Left and right: 20px */
margin: 10px 20px 30px;       /* Top: 10px | Left and right: 20px | Bottom: 30px */
margin: 10px 20px 30px 40px;  /* Top, Right, Bottom, Left (clockwise from top) */
margin: 0 auto;               /* Center horizontally, no top/bottom margin */
```

The same pattern applies to `padding`. The clockwise order (top, right, bottom, left) is worth memorizing - it appears constantly in CSS and there is no way to look it up every time you need it.

---

## 6. Fix the Errors in Your Code

Three box model mistakes are particularly common and cause symptoms that are frustrating to debug without understanding the underlying concept.

**Error 1: Unexpected element width caused by missing `box-sizing`.**

Developers often declare a `width` and then add padding or a border, expecting the total box to remain that size. Without `box-sizing: border-box`, the padding and border are added on top of the width, making the element larger than intended.

```css
/* Wrong: total visible width is 350px, not 300px */
.box {
    width: 300px;
    padding: 20px;
    border: 5px solid black;
}

/* Correct: total visible width is exactly 300px */
.box {
    width: 300px;
    padding: 20px;
    border: 5px solid black;
    box-sizing: border-box;
}
```

The math for the wrong version: 300px (content) + 40px (20px padding on each side) + 10px (5px border on each side) = 350px total. To avoid this calculation entirely, apply `box-sizing: border-box` to the universal selector at the top of every new stylesheet you create.

**Error 2: `margin: auto` applied to an inline element.**

`margin: 0 auto` is the standard way to center a block element, but inline elements do not respond to width or auto margins. The browser ignores both properties on inline elements.

```css
/* Wrong: span is inline, width and margin auto are ignored */
span {
    margin: 0 auto;
    width: 200px;
}

/* Correct: change to block first, then auto margin works */
span {
    display: block;
    width: 200px;
    margin: 0 auto;
}
```

`margin: auto` requires the element to be block-level and to have a declared `width`. Without those two conditions, auto margin has no space to divide and does nothing.

**Error 3: Vertical margin collapse producing unexpected spacing.**

When two block elements are stacked vertically and both have vertical margins, those margins do not add together. Instead, the larger margin wins and the smaller one collapses.

```css
/* Wrong assumption: gap between box1 and box2 is 50px */
.box1 { margin-bottom: 30px; }
.box2 { margin-top: 20px; }

/* Correct understanding: gap is only 30px (the larger of the two margins) */
```

Margin collapse only happens vertically (between top and bottom margins) and never horizontally (left and right margins always add together). If you need a specific amount of space between two elements, set the margin on only one of them to avoid confusion.

---

## 7. Exercises

**Exercise 1:** Create `cards.html` with three cards displayed side by side using `display: inline-block`. Each card must have: `width: 30%`, `padding: 16px`, a visible border, `border-radius`, and `box-sizing: border-box`. Add `vertical-align: top` to prevent misalignment when cards have different amounts of content.

**Exercise 2:** Create `pricing-card.html` with a single pricing card centered on the page. The card should have: `max-width: 350px`, `padding: 32px`, a solid colored top border that is 4px thick, a `box-shadow`, and horizontal auto margins. Include a price, a plan name, and a list of features.

**Exercise 3:** Open any page from a previous lesson in your browser. Press F12 to open DevTools, click the **Elements** tab, and select any element. In the right panel, look at the box model diagram in the **Computed** tab. Try changing a margin or padding value directly in DevTools and watch the page update live.

---

## 8. Solutions

**Solution for Exercise 1:**

Create a new file called `cards.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cards</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 20px; }

        .card {
            display: inline-block;
            width: 30%;
            padding: 16px;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            vertical-align: top;
            margin: 1%;
        }
    </style>
</head>
<body>
    <div class="card">
        <h3>Card One</h3>
        <p>This card uses inline-block and a 30% width to sit beside its siblings.</p>
    </div>
    <div class="card">
        <h3>Card Two</h3>
        <p>box-sizing: border-box ensures the padding stays inside the declared width.</p>
    </div>
    <div class="card">
        <h3>Card Three</h3>
        <p>vertical-align: top aligns all cards to the top edge regardless of height.</p>
    </div>
</body>
</html>
```

`display: inline-block` makes the cards sit side by side while still respecting `width` and `padding`. Setting `width: 30%` on each with `margin: 1%` on each side uses approximately 96% of the row (3 cards x 30% = 90% + 6 margins x 1% = 6%), fitting comfortably within the container. `vertical-align: top` prevents the browser from aligning cards to their baseline, which would cause misalignment when card heights differ.

**Solution for Exercise 2:**

Create a new file called `pricing-card.html` and write the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pricing Card</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f1f5f9; padding: 40px; }

        .pricing {
            max-width: 350px;
            margin: 0 auto;
            padding: 32px;
            background: white;
            border: 1px solid #e2e8f0;
            border-top: 4px solid #2563eb;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }

        .price { font-size: 2.5rem; font-weight: bold; color: #2563eb; margin: 16px 0; }

        .features { list-style: none; padding: 0; text-align: left; margin-top: 20px; }
        .features li { padding: 6px 0; border-bottom: 1px solid #f1f5f9; }
    </style>
</head>
<body>
    <div class="pricing">
        <h2>Pro Plan</h2>
        <div class="price">$29<span style="font-size:1rem">/mo</span></div>
        <ul class="features">
            <li>100 GB storage</li>
            <li>Up to 5 users</li>
            <li>Priority support</li>
            <li>Custom domain</li>
        </ul>
    </div>
</body>
</html>
```

`border-top: 4px solid #2563eb` overrides only the top side of the border declared by the shorthand `border: 1px solid #e2e8f0`. Setting a side-specific border after the shorthand allows you to create asymmetric borders. `max-width: 350px` combined with `margin: 0 auto` keeps the card centered without a fixed width, so it still shrinks on smaller screens.

---

## 9. Next Up - Lesson 9

Every HTML element is a box with four layers: content, padding (space inside the border), border (the visible edge), and margin (space outside the border). `box-sizing: border-box` makes `width` include padding and border, which is the behavior most developers expect and should always be enabled globally. `margin: 0 auto` centers block elements horizontally when they have a defined width. Vertical margins between adjacent block elements collapse, meaning only the larger margin applies.

In Lesson 9, you will learn Flexbox: the modern CSS layout system that makes it simple to align and distribute items in a row or column, center elements on both axes, and build navigation bars and card layouts without relying on floats or `inline-block` workarounds.