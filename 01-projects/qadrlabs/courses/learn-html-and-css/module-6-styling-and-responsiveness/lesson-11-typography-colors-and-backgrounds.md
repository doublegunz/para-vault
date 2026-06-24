## 1. Before You Begin

A web page can have correct structure, solid layout, and working forms - but still feel unprofessional and hard to read. The difference between a page that feels functional and one that feels polished comes down to typography, color, and visual depth. Good typography ensures every line of text is readable and appropriately sized. A consistent color system prevents random color choices from conflicting across the page. Backgrounds, shadows, and transitions create depth and make interfaces feel alive and interactive.

In Lesson 10, you finished building layouts. This lesson is about finishing the design - the layer of visual decisions that transforms a layout into a product.

### What You'll Build

You will create a two-file demonstration using `typography.html` and `typography.css`. The page includes a hero section with a gradient background and an animated button, a content area with Google Fonts, and a three-card row with hover transitions. All colors and spacing are managed through CSS custom properties defined in `:root`.

### What You'll Learn

- ✅ Font properties: `font-family`, `font-size`, `font-weight`, `line-height`, `letter-spacing`
- ✅ Integrating Google Fonts via a `<link>` tag
- ✅ CSS custom properties (variables) with `--name` and `var()`
- ✅ Background types: solid color, linear gradient, background image
- ✅ `box-shadow` and `text-shadow` for visual depth
- ✅ `transition` for smooth hover effects
- ✅ Which CSS properties can and cannot be animated

### What You'll Need

- VS Code with the `learn-html-css` folder open
- Lesson 10 completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-11`, and press Enter.

---

## 3. Typography and Visual Design

Typography and color are most effective when they are defined as a system rather than applied case by case. CSS custom properties, often called CSS variables, let you define your design tokens once at the top of the stylesheet and reference them throughout the file. Changing one variable updates every element that uses it.

### Step 1: Create the Files

Right-click on `lesson-11` in VS Code, select **New File**, type `typography.html`. Right-click again, select **New File**, type `typography.css`.

### Step 2: Write the HTML

Add the following to `typography.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Typography and Colors</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=Merriweather:wght@400;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="typography.css">
</head>
<body>
    <h1>Typography and Visual Design</h1>

    <section class="hero">
        <h2>Build Beautiful Web Pages</h2>
        <p>Great design starts with readable typography, consistent colors, and thoughtful spacing.</p>
        <a href="#" class="btn">Get Started</a>
    </section>

    <section class="content">
        <h2>Why Typography Matters</h2>
        <p>Good typography is invisible. When text is easy to read, users focus on the content, not the font. Bad typography creates friction and drives users away.</p>
        <p>The key properties are: <code>font-family</code> for the typeface, <code>font-size</code> for size, <code>line-height</code> for vertical spacing, and <code>letter-spacing</code> for horizontal spacing between characters.</p>
    </section>

    <section class="cards-section">
        <h2>Feature Cards</h2>
        <div class="cards">
            <div class="card">
                <h3>Responsive</h3>
                <p>Layouts adapt to any screen size automatically.</p>
            </div>
            <div class="card">
                <h3>Accessible</h3>
                <p>Content is readable for everyone, including screen reader users.</p>
            </div>
            <div class="card">
                <h3>Fast</h3>
                <p>Pages load in under two seconds on most connections.</p>
            </div>
        </div>
    </section>
</body>
</html>
```

The two `<link>` tags in the `<head>` serve different purposes. The first loads Google Fonts - specifically the Inter and Merriweather families at selected weights. Google Fonts are hosted on Google's servers and are fetched by the user's browser when the page loads. The second `<link>` loads the local stylesheet. The order matters: the Google Fonts link must come before the local stylesheet so the fonts are available when the stylesheet tries to reference them.

### Step 3: Write the CSS

Add the following to `typography.css`:

```css
:root {
    --color-primary: #2563eb;
    --color-primary-dark: #1d4ed8;
    --color-text: #1e293b;
    --color-text-light: #64748b;
    --color-bg: #f8fafc;
    --color-white: #ffffff;
    --color-border: #e2e8f0;
    --font-sans: 'Inter', Arial, sans-serif;
    --font-serif: 'Merriweather', Georgia, serif;
    --shadow-sm: 0 1px 3px rgba(0,0,0,0.1);
    --shadow-md: 0 4px 12px rgba(0,0,0,0.1);
    --radius: 8px;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: var(--font-sans);
    font-size: 16px;
    line-height: 1.6;
    color: var(--color-text);
    background: var(--color-bg);
}

h1, h2, h3 {
    font-family: var(--font-serif);
    line-height: 1.3;
    margin-bottom: 12px;
}

h1 { font-size: 2rem; text-align: center; padding: 20px; }
h2 { font-size: 1.5rem; }
h3 { font-size: 1.15rem; }
p  { margin-bottom: 12px; color: var(--color-text-light); }

.hero {
    background: linear-gradient(135deg, var(--color-primary), #7c3aed);
    color: white;
    text-align: center;
    padding: 60px 20px;
    border-radius: var(--radius);
    margin: 0 20px 30px;
}

.hero h2 { color: white; font-size: 2rem; }
.hero p  { color: rgba(255,255,255,0.85); font-size: 1.1rem; max-width: 500px; margin: 0 auto 20px; }

.btn {
    display: inline-block;
    background: white;
    color: var(--color-primary);
    padding: 12px 28px;
    border-radius: 6px;
    text-decoration: none;
    font-weight: 600;
    box-shadow: var(--shadow-sm);
    transition: transform 0.2s, box-shadow 0.2s;
}

.btn:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
}

.content {
    max-width: 700px;
    margin: 0 auto 30px;
    padding: 0 20px;
}

code {
    background: #f1f5f9;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 0.9em;
    color: var(--color-primary);
}

.cards-section { max-width: 900px; margin: 0 auto; padding: 0 20px; }

.cards { display: flex; gap: 16px; }

.card {
    flex: 1;
    background: var(--color-white);
    border: 1px solid var(--color-border);
    border-radius: var(--radius);
    padding: 24px;
    box-shadow: var(--shadow-sm);
    transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-md);
}

.card h3 { color: var(--color-primary); }
```

`:root` is the topmost element in the CSS hierarchy - essentially the `<html>` element. Custom properties declared inside `:root` are available everywhere in the stylesheet. The double-dash prefix (`--`) identifies a custom property. Referencing a custom property requires wrapping its name in `var()`.

`linear-gradient(135deg, var(--color-primary), #7c3aed)` creates a diagonal gradient that transitions from the primary blue to a purple. The angle `135deg` runs from the top-left to the bottom-right. You can use two or more colors in a gradient, and they can include color stops and `rgba()` values.

`box-shadow: 0 1px 3px rgba(0,0,0,0.1)` adds a shadow below the element. The four values are: horizontal offset, vertical offset, blur radius, and color. Using a low opacity color like `rgba(0,0,0,0.1)` produces a subtle shadow that feels natural rather than heavy.

`transition: transform 0.2s, box-shadow 0.2s` tells the browser to animate changes to the `transform` and `box-shadow` properties over 0.2 seconds whenever they change. When the user hovers, the `:hover` rule applies new values for those properties, and the transition makes the change smooth instead of instant. The value 0.2 seconds is fast enough to feel responsive but slow enough to be perceptible.

`transform: translateY(-2px)` moves the element 2px upward. Combined with a larger shadow on hover, this creates the illusion that the button is lifting off the surface.

### Step 4: Save and View

Press **Ctrl+S** for both files and open `typography.html` with Live Server. Hover over the button and the cards to see the lift-and-shadow transition effects.

---

## 4. Key Concepts Explained

This section consolidates the most important concepts from this lesson for quick reference.

**CSS Custom Properties (Variables)** define reusable values in one place and reference them everywhere else. Changing a variable in `:root` instantly updates every element in the stylesheet that references it. This is the foundation of any maintainable design system.

```css
:root { --color-primary: #2563eb; }
.btn  { background: var(--color-primary); }
```

**Gradients** create smooth color transitions. `linear-gradient(135deg, #2563eb, #7c3aed)` creates a diagonal transition from blue to purple. You can layer a gradient over a background image by separating them with a comma in the `background` shorthand.

**`box-shadow`** adds depth to elements. The format is `x-offset y-offset blur-radius color`. A positive `y-offset` produces a shadow below the element; a negative value produces one above. Setting the alpha value of `rgba()` below 0.15 keeps shadows subtle.

**`text-shadow`** works the same way as `box-shadow` but applies to the text itself. It is useful for improving contrast of text placed over busy backgrounds.

**`transition`** animates property changes smoothly. It takes a list of property names and durations. Only certain CSS properties are animatable - these include `transform`, `opacity`, `color`, `background-color`, `box-shadow`, `border-color`, and `width`/`height`.

**Google Fonts** are loaded by adding a `<link>` tag to the `<head>` that points to the Google Fonts API. Once loaded, the font is available in `font-family` using its name exactly as listed on the Google Fonts website.

---

## 5. Fix the Errors in Your Code

Three mistakes appear consistently when developers first work with typography and CSS variables. Each one produces silent failures that are difficult to diagnose without knowing the underlying rule.

**Error 1: Using a pixel value for `line-height`.**

A fixed pixel `line-height` does not scale when `font-size` changes. If `font-size` is later increased, the fixed line height may become too small, causing lines to overlap or sit uncomfortably close together.

```css
/* Wrong: line-height is fixed at 24px regardless of font size */
p { font-size: 16px; line-height: 24px; }

/* Correct: unitless value scales proportionally with font-size */
p { font-size: 16px; line-height: 1.5; }
```

A unitless `line-height` value is multiplied by the element's `font-size`. So `line-height: 1.5` on a 16px paragraph produces 24px of line height, but on a 24px heading it produces 36px. The relationship between text size and line height stays correct automatically.

**Error 2: Referencing a CSS custom property without `var()`.**

Using the property name directly without wrapping it in `var()` is not a valid CSS declaration. The browser ignores it silently without displaying an error in the browser window.

```css
/* Wrong: --color-primary without var() is invalid CSS */
.btn { background: --color-primary; }

/* Correct: always wrap custom properties in var() */
.btn { background: var(--color-primary); }
```

When troubleshooting a custom property that is not applying, always check that the property name inside `var()` matches exactly the name defined in `:root`, including the double-dash prefix.

**Error 3: Attempting to transition the `display` property.**

`display` is not an animatable property in CSS. Setting a transition on it produces no animation - the element appears or disappears instantly.

```css
/* Wrong: display cannot be animated */
.card { display: none; transition: display 0.3s; }

/* Correct: use opacity and visibility together for a fade effect */
.card { opacity: 0; visibility: hidden; transition: opacity 0.3s, visibility 0.3s; }
.card.visible { opacity: 1; visibility: visible; }
```

`opacity: 0` makes the element invisible but it still occupies space. `visibility: hidden` hides it and makes it non-interactive but still occupies space. Together, their transition produces a smooth fade. To also remove the element from layout, combine `opacity` and `max-height` transitions, or use JavaScript to add and remove a class.

---

## 6. Exercises

**Exercise 1:** Create a dark theme version of the page by overriding only the CSS custom properties in `:root`. Set `--color-bg: #0f172a`, `--color-text: #e2e8f0`, `--color-white: #1e293b`, and `--color-text-light: #94a3b8`. Open the page and confirm that the entire design adapts to the dark palette without any other changes to the HTML or CSS.

**Exercise 2:** Add a `text-shadow` to the hero section heading to improve contrast over the gradient background. Use `text-shadow: 2px 2px 4px rgba(0,0,0,0.3)`. Then modify the hero's background to use a gradient overlaid on a placeholder image, combining both in the `background` shorthand.

**Exercise 3:** Return to `lesson-09/flexbox.html` and add a hover effect to the navigation links. The effect should draw an underline in from the left using `border-bottom` and `transition`. The link should have `border-bottom: 2px solid transparent` by default and `border-bottom-color: white` on `:hover`.

---

## 7. Solutions

**Solution for Exercise 1:**

Open `typography.css` and replace the `:root` block with the following:

```css
:root {
    --color-primary: #60a5fa;
    --color-primary-dark: #3b82f6;
    --color-text: #e2e8f0;
    --color-text-light: #94a3b8;
    --color-bg: #0f172a;
    --color-white: #1e293b;
    --color-border: #334155;
    --font-sans: 'Inter', Arial, sans-serif;
    --font-serif: 'Merriweather', Georgia, serif;
    --shadow-sm: 0 1px 3px rgba(0,0,0,0.3);
    --shadow-md: 0 4px 12px rgba(0,0,0,0.4);
    --radius: 8px;
}
```

Every element in the stylesheet that uses `var()` will immediately reflect the new values. The background becomes dark, body text becomes light, and card backgrounds switch to a dark surface color - all from changes to a single block at the top of the file. This demonstrates the primary advantage of a design token system: one change propagates everywhere.

**Solution for Exercise 2:**

Add the following rules to `typography.css`:

```css
.hero h2 {
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.hero {
    background:
        linear-gradient(135deg, rgba(37,99,235,0.85), rgba(124,58,237,0.85)),
        url('https://placehold.co/1200x400') center / cover;
}
```

When multiple values are provided to the `background` property separated by commas, they are rendered as layers from top to bottom. The gradient layer is listed first so it appears on top of the background image. Using `rgba()` with an alpha value less than 1 on the gradient colors allows the image to be visible through the gradient overlay.

**Solution for Exercise 3:**

Add the following CSS to the stylesheet for the Lesson 9 navbar:

```css
nav a {
    border-bottom: 2px solid transparent;
    transition: border-bottom-color 0.2s;
}

nav a:hover {
    border-bottom-color: white;
}
```

Setting `border-bottom: 2px solid transparent` reserves the space for the border from the start, preventing the link from shifting position when the border appears. Only `border-bottom-color` is transitioned, not the full `border-bottom` shorthand, because CSS can only animate individual color values rather than shorthand border properties.

---

## 8. Next Up - Lesson 12

Good typography uses Google Fonts linked via `<link>` in the `<head>`, and applies `font-family`, `font-size`, and unitless `line-height` for readable, scalable text. CSS custom properties defined in `:root` create a reusable design system where a single variable change updates the entire page. Gradients, `box-shadow`, and `text-shadow` add visual depth. `transition` animates changes to animatable properties like `transform`, `opacity`, `color`, and `box-shadow` - but not properties like `display` or `grid-template`.

In Lesson 12, you will learn responsive design with media queries: how to write CSS that applies different layouts at different screen widths, using the mobile-first approach to ensure your pages look great on every device.