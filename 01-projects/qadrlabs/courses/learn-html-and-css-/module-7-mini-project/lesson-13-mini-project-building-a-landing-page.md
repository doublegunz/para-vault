## 1. Before You Begin

This is the lesson where everything comes together. You have spent twelve lessons learning individual skills: semantic HTML, CSS selectors, the box model, Flexbox, CSS Grid, typography, color systems, and media queries. Each skill was practiced in isolation on small, focused files. Now you will use all of them at once to build a single, complete, professional-quality landing page.

Real projects are not about individual techniques. They are about knowing which technique to reach for at each moment and how to combine them cleanly. This lesson gives you that experience: planning a multi-section page, identifying which layout tool fits each section, and wiring the whole thing together into a responsive product page that works at every screen size.

### What You'll Build

A complete, responsive marketing landing page for a fictional product called "LaunchPad". The page has six sections: a sticky navigation bar, a hero with gradient background and call-to-action buttons, a features grid, a three-column pricing table, a contact form, and a multi-column footer.

### What You'll Learn

- ✅ How to plan and structure a full page before writing a single line of code
- ✅ How to combine Flexbox and Grid across different sections of the same project
- ✅ How to build a complete design system with CSS custom properties
- ✅ How to make every section responsive with mobile-first media queries
- ✅ How all twelve previous lessons work together in a real project

### What You'll Need

- VS Code with `learn-html-css` folder open
- All previous lessons (1-12) completed

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-html-css` folder, select **New Folder**, type `lesson-13`, and press Enter.

---

## 3. Build the Landing Page

Building a complete page requires planning before writing code. The page has six distinct sections, each with its own layout requirements. The navigation bar is a Flexbox row with the brand on the left and links on the right. The hero is a full-width centered section. The features section uses CSS Grid with `auto-fit` for responsive columns. The pricing section is a three-column Grid. The contact section contains a two-column form row. The footer is a four-column Grid that collapses to a single column on mobile.

### Step 1: Create the Files

Right-click on `lesson-13`, select **New File**, type `index.html`. Right-click again, select **New File**, type `style.css`.

### Step 2: Write the HTML

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LaunchPad - Build Faster</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
</head>
<body>

    <nav class="navbar">
        <div class="container nav-content">
            <a href="#" class="brand">LaunchPad</a>
            <div class="nav-links">
                <a href="#features">Features</a>
                <a href="#pricing">Pricing</a>
                <a href="#contact">Contact</a>
                <a href="#" class="btn btn-outline">Sign Up</a>
            </div>
        </div>
    </nav>

    <section class="hero">
        <div class="container">
            <h1>Build and Launch Your Website in Minutes</h1>
            <p>LaunchPad gives you everything you need to go from idea to live website. No coding experience required.</p>
            <div class="hero-buttons">
                <a href="#" class="btn btn-primary btn-lg">Get Started Free</a>
                <a href="#features" class="btn btn-ghost btn-lg">Learn More</a>
            </div>
        </div>
    </section>

    <section id="features" class="features">
        <div class="container">
            <h2 class="section-title">Why Choose LaunchPad?</h2>
            <p class="section-subtitle">Everything you need to build a professional website.</p>
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">&#9889;</div>
                    <h3>Lightning Fast</h3>
                    <p>Pages load in under 1 second. Built on modern infrastructure for maximum speed.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">&#128241;</div>
                    <h3>Fully Responsive</h3>
                    <p>Every template looks perfect on desktop, tablet, and mobile. No extra work needed.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">&#128274;</div>
                    <h3>Secure by Default</h3>
                    <p>SSL certificates, DDoS protection, and automatic backups included in every plan.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">&#127912;</div>
                    <h3>Beautiful Templates</h3>
                    <p>50+ professionally designed templates for any industry. Customize colors and fonts.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">&#128200;</div>
                    <h3>Built-in Analytics</h3>
                    <p>Track visitors, page views, and conversions without installing third-party tools.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">&#128172;</div>
                    <h3>24/7 Support</h3>
                    <p>Our team is available around the clock via chat, email, and phone.</p>
                </div>
            </div>
        </div>
    </section>

    <section id="pricing" class="pricing">
        <div class="container">
            <h2 class="section-title">Simple, Transparent Pricing</h2>
            <p class="section-subtitle">No hidden fees. Cancel anytime.</p>
            <div class="pricing-grid">
                <div class="pricing-card">
                    <h3>Starter</h3>
                    <div class="price">$9<span>/month</span></div>
                    <ul>
                        <li>1 Website</li>
                        <li>10 GB Storage</li>
                        <li>Free SSL</li>
                        <li>Email Support</li>
                    </ul>
                    <a href="#" class="btn btn-outline btn-block">Choose Starter</a>
                </div>
                <div class="pricing-card popular">
                    <div class="popular-badge">Most Popular</div>
                    <h3>Professional</h3>
                    <div class="price">$29<span>/month</span></div>
                    <ul>
                        <li>5 Websites</li>
                        <li>100 GB Storage</li>
                        <li>Free SSL</li>
                        <li>Priority Support</li>
                        <li>Custom Domain</li>
                    </ul>
                    <a href="#" class="btn btn-primary btn-block">Choose Professional</a>
                </div>
                <div class="pricing-card">
                    <h3>Enterprise</h3>
                    <div class="price">$99<span>/month</span></div>
                    <ul>
                        <li>Unlimited Websites</li>
                        <li>Unlimited Storage</li>
                        <li>Free SSL</li>
                        <li>24/7 Phone Support</li>
                        <li>Custom Domain</li>
                        <li>API Access</li>
                    </ul>
                    <a href="#" class="btn btn-outline btn-block">Choose Enterprise</a>
                </div>
            </div>
        </div>
    </section>

    <section id="contact" class="contact">
        <div class="container">
            <h2 class="section-title">Get in Touch</h2>
            <p class="section-subtitle">Have questions? We would love to hear from you.</p>
            <form class="contact-form" action="#" method="post">
                <div class="form-row">
                    <div class="form-group">
                        <label for="name">Name</label>
                        <input type="text" id="name" name="name" placeholder="Your name" required>
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" placeholder="you@example.com" required>
                    </div>
                </div>
                <div class="form-group">
                    <label for="message">Message</label>
                    <textarea id="message" name="message" rows="5" placeholder="Your message..." required></textarea>
                </div>
                <button type="submit" class="btn btn-primary btn-lg">Send Message</button>
            </form>
        </div>
    </section>

    <footer class="footer">
        <div class="container footer-content">
            <div class="footer-col">
                <h4>LaunchPad</h4>
                <p>Build and launch your website in minutes. No coding required.</p>
            </div>
            <div class="footer-col">
                <h4>Product</h4>
                <ul>
                    <li><a href="#">Features</a></li>
                    <li><a href="#">Pricing</a></li>
                    <li><a href="#">Templates</a></li>
                </ul>
            </div>
            <div class="footer-col">
                <h4>Company</h4>
                <ul>
                    <li><a href="#">About</a></li>
                    <li><a href="#">Blog</a></li>
                    <li><a href="#">Careers</a></li>
                </ul>
            </div>
            <div class="footer-col">
                <h4>Support</h4>
                <ul>
                    <li><a href="#">Help Center</a></li>
                    <li><a href="#">Contact</a></li>
                    <li><a href="#">Status</a></li>
                </ul>
            </div>
        </div>
        <div class="container footer-bottom">
            <p>Copyright 2026 LaunchPad. All rights reserved.</p>
        </div>
    </footer>

</body>
</html>
```

The HTML is organized using semantic sectioning elements throughout. `<nav>` wraps the navigation bar. `<section>` wraps each content region, with `id` attributes matching the navigation anchor links so clicking "Features" in the navbar scrolls to the features section. `<footer>` wraps the closing columns and copyright bar. Each section uses a `.container` wrapper to limit the content width and center it horizontally, a pattern that repeats across every section for visual consistency.

### Step 3: Write the CSS

Add the following to `style.css`:

```css
/* Variables */
:root {
    --primary: #2563eb;
    --primary-dark: #1d4ed8;
    --text: #1e293b;
    --text-light: #64748b;
    --bg: #ffffff;
    --bg-alt: #f8fafc;
    --border: #e2e8f0;
    --white: #ffffff;
    --radius: 8px;
    --shadow: 0 1px 3px rgba(0,0,0,0.08);
    --shadow-lg: 0 8px 24px rgba(0,0,0,0.12);
}

/* Reset */
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Inter', sans-serif; color: var(--text); line-height: 1.6; }
a { text-decoration: none; color: inherit; }
ul { list-style: none; }
img { max-width: 100%; height: auto; }

/* Container */
.container { max-width: 1100px; margin: 0 auto; padding: 0 20px; }

/* Buttons */
.btn {
    display: inline-block;
    padding: 10px 20px;
    border-radius: 6px;
    font-weight: 600;
    font-size: 0.9em;
    transition: all 0.2s;
    cursor: pointer;
    border: 2px solid transparent;
    text-align: center;
}
.btn-primary { background: var(--primary); color: white; border-color: var(--primary); }
.btn-primary:hover { background: var(--primary-dark); }
.btn-outline { border-color: var(--primary); color: var(--primary); }
.btn-outline:hover { background: var(--primary); color: white; }
.btn-ghost { color: white; border-color: rgba(255,255,255,0.4); }
.btn-ghost:hover { background: rgba(255,255,255,0.1); }
.btn-lg { padding: 14px 28px; font-size: 1em; }
.btn-block { display: block; width: 100%; }

/* Section Titles */
.section-title { font-size: 1.8rem; text-align: center; margin-bottom: 8px; }
.section-subtitle {
    text-align: center;
    color: var(--text-light);
    margin-bottom: 40px;
    max-width: 500px;
    margin-left: auto;
    margin-right: auto;
}

/* Navbar */
.navbar { background: var(--text); position: sticky; top: 0; z-index: 100; }
.nav-content { display: flex; justify-content: space-between; align-items: center; padding-top: 12px; padding-bottom: 12px; }
.brand { color: white; font-weight: 700; font-size: 1.3em; }
.nav-links { display: flex; align-items: center; gap: 20px; }
.nav-links a { color: #cbd5e1; font-size: 0.9em; transition: color 0.2s; }
.nav-links a:hover { color: white; }

/* Hero */
.hero { background: linear-gradient(135deg, var(--primary), #7c3aed); color: white; text-align: center; padding: 80px 20px; }
.hero h1 { font-size: 2.2rem; max-width: 700px; margin: 0 auto 16px; line-height: 1.2; }
.hero p { color: rgba(255,255,255,0.85); font-size: 1.1em; max-width: 550px; margin: 0 auto 28px; }
.hero-buttons { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }

/* Features */
.features { padding: 60px 0; background: var(--bg-alt); }
.features-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; }
.feature-card { background: var(--white); padding: 28px; border-radius: var(--radius); border: 1px solid var(--border); transition: transform 0.2s, box-shadow 0.2s; }
.feature-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-lg); }
.feature-icon { font-size: 2em; margin-bottom: 12px; }
.feature-card h3 { margin-bottom: 6px; }
.feature-card p { color: var(--text-light); font-size: 0.9em; }

/* Pricing */
.pricing { padding: 60px 0; }
.pricing-grid { display: grid; grid-template-columns: 1fr; gap: 20px; max-width: 900px; margin: 0 auto; }
.pricing-card { background: var(--white); border: 1px solid var(--border); border-radius: var(--radius); padding: 32px; text-align: center; position: relative; }
.pricing-card.popular { border-color: var(--primary); box-shadow: var(--shadow-lg); transform: scale(1.02); }
.popular-badge { position: absolute; top: -12px; left: 50%; transform: translateX(-50%); background: var(--primary); color: white; padding: 4px 16px; border-radius: 20px; font-size: 0.8em; font-weight: 600; }
.price { font-size: 2.5rem; font-weight: 700; margin: 16px 0; color: var(--text); }
.price span { font-size: 0.9rem; font-weight: 400; color: var(--text-light); }
.pricing-card ul { margin: 20px 0; }
.pricing-card li { padding: 8px 0; color: var(--text-light); border-bottom: 1px solid var(--border); }
.pricing-card li:last-child { border-bottom: none; }

/* Contact */
.contact { padding: 60px 0; background: var(--bg-alt); }
.contact-form { max-width: 600px; margin: 0 auto; }
.form-row { display: grid; grid-template-columns: 1fr; gap: 16px; }
.form-group { margin-bottom: 16px; }
.form-group label { display: block; font-weight: 600; margin-bottom: 4px; font-size: 0.9em; }
.form-group input,
.form-group textarea { width: 100%; padding: 10px 14px; border: 1px solid var(--border); border-radius: 6px; font-family: inherit; font-size: 0.95em; }
.form-group input:focus,
.form-group textarea:focus { border-color: var(--primary); outline: none; box-shadow: 0 0 0 3px rgba(37,99,235,0.15); }

/* Footer */
.footer { background: var(--text); color: #94a3b8; padding: 40px 0 0; }
.footer-content { display: grid; grid-template-columns: 1fr; gap: 24px; padding-bottom: 30px; }
.footer-col h4 { color: white; margin-bottom: 10px; }
.footer-col p { font-size: 0.9em; }
.footer-col a { color: #94a3b8; font-size: 0.9em; display: block; padding: 3px 0; transition: color 0.2s; }
.footer-col a:hover { color: white; }
.footer-bottom { border-top: 1px solid #334155; padding: 16px 0; text-align: center; font-size: 0.85em; }

/* Tablet (768px and up) */
@media (min-width: 768px) {
    .hero h1 { font-size: 2.8rem; }
    .pricing-grid { grid-template-columns: repeat(3, 1fr); }
    .form-row { grid-template-columns: 1fr 1fr; }
    .footer-content { grid-template-columns: 2fr 1fr 1fr 1fr; }
}

/* Desktop (1024px and up) */
@media (min-width: 1024px) {
    .hero { padding: 100px 20px; }
    .hero h1 { font-size: 3rem; }
}

/* Mobile adjustments */
@media (max-width: 767px) {
    .nav-content { flex-direction: column; gap: 8px; }
    .nav-links { flex-wrap: wrap; justify-content: center; gap: 12px; }
    .pricing-card.popular { transform: none; }
}
```

The CSS is built on top of a design system defined in `:root`. Every color, shadow, and border radius is a custom property, which means updates to the design only require changing the variable value at the top of the file. The `.container` class creates a consistent maximum width of 1100px with horizontal auto margins, centering all content regardless of screen size.

The button system uses a single `.btn` base class combined with modifier classes: `.btn-primary` for filled blue, `.btn-outline` for bordered, `.btn-ghost` for use on dark backgrounds, `.btn-lg` for larger padding, and `.btn-block` for full-width. This pattern avoids duplicating shared properties across every button variant.

`position: sticky; top: 0; z-index: 100` on the navbar keeps it visible at the top of the viewport as the user scrolls. `z-index: 100` ensures it appears above all other content.

The features grid uses `repeat(auto-fit, minmax(280px, 1fr))`, producing a responsive grid that requires no media queries - columns are added or removed automatically as the container width changes. Each feature card uses `transition: transform 0.2s, box-shadow 0.2s` combined with a `:hover` rule to produce a subtle lift effect.

The pricing grid starts as a single column on mobile (`grid-template-columns: 1fr`) and switches to three columns at 768px via the tablet media query. The `.popular` card uses `transform: scale(1.02)` and `box-shadow` to make it stand out visually. `position: absolute` on the `.popular-badge` positions it at the top-center of the card using `top: -12px`, `left: 50%`, and `transform: translateX(-50%)`.

The contact form's `.form-row` starts as a single column on mobile and switches to two columns at 768px. The focus styles on inputs use `box-shadow: 0 0 0 3px rgba(37,99,235,0.15)` instead of the default browser outline, creating a soft blue ring that matches the site's primary color.

### Step 4: Save and View

Press **Ctrl+S** for both files and open with Live Server. Resize the browser window slowly from narrow to wide to observe the responsive behavior at the 768px and 1024px breakpoints.

---

## 4. How All Concepts Connect

Every skill from the previous twelve lessons appears in this project. The table below maps each page section to the specific concepts it uses.

| Section | HTML Concepts | CSS Concepts |
|---------|--------------|-------------|
| Navigation | `<nav>`, `<a>`, semantic structure | Flexbox, `position: sticky`, transitions |
| Hero | `<section>`, `<h1>`, `<p>` | Gradient background, centered text, `flex-wrap` for buttons |
| Features | `<section>`, `<div>`, `<h3>` | CSS Grid with `auto-fit`, `box-shadow`, hover transitions |
| Pricing | `<ul>`, `<li>`, semantic grouping | CSS Grid, `position: absolute` for badge, `transform` |
| Contact | `<form>`, `<input>`, `<textarea>`, `<label>` | CSS Grid for form row, focus styles, `box-shadow` |
| Footer | `<footer>`, `<ul>`, `<a>` | CSS Grid, responsive column counts |
| Responsive | Viewport meta tag | Mobile-first media queries, `flex-wrap` |

---

## 5. Exercises

**Exercise 1:** Add a "Testimonials" section between the Pricing and Contact sections. Include three testimonial cards in a row, each containing a quote, the author's name, and their company name. Use `display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr))` for the grid. Give each card a light border, rounded corners, and a subtle shadow. Add the new section anchor link `href="#testimonials"` to the navigation bar.

**Exercise 2:** Add a "scroll to top" button that appears in the bottom-right corner of the page at all times. The button should be a small circle with an upward arrow character (`&#8593;`). Use `position: fixed; bottom: 20px; right: 20px` to pin it to the corner, and use Flexbox with `justify-content: center; align-items: center` to center the arrow inside the circle. Link it to `href="#"` so it returns to the top of the page.

**Exercise 3:** Add `scroll-behavior: smooth` to the `html` selector in `style.css`. Click the navigation links (Features, Pricing, Contact) to confirm that clicking them now animates the scroll instead of jumping instantly to each section.

---

## 6. Solutions

**Solution for Exercise 1:**

Add the following HTML between the closing `</section>` of the Pricing section and the opening `<section>` of the Contact section:

```html
<section id="testimonials" class="testimonials">
    <div class="container">
        <h2 class="section-title">What Our Customers Say</h2>
        <p class="section-subtitle">Trusted by thousands of businesses worldwide.</p>
        <div class="testimonials-grid">
            <div class="testimonial-card">
                <p class="quote">"LaunchPad cut our time-to-launch from weeks to hours. Absolutely incredible product."</p>
                <p class="author">Andi Pratama</p>
                <p class="company">Founder, Toko Digital</p>
            </div>
            <div class="testimonial-card">
                <p class="quote">"The templates are beautiful and setting up our online store was completely painless."</p>
                <p class="author">Siti Rahayu</p>
                <p class="company">CEO, Batik Nusantara</p>
            </div>
            <div class="testimonial-card">
                <p class="quote">"Support answered our questions within minutes. I have never felt so well looked after."</p>
                <p class="author">Budi Santoso</p>
                <p class="company">Director, Media Kreatif</p>
            </div>
        </div>
    </div>
</section>
```

Add the following CSS to `style.css`:

```css
.testimonials { padding: 60px 0; }
.testimonials-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; }
.testimonial-card { background: var(--white); border: 1px solid var(--border); border-radius: var(--radius); padding: 28px; box-shadow: var(--shadow); }
.quote { color: var(--text-light); font-style: italic; margin-bottom: 16px; line-height: 1.7; }
.author { font-weight: 600; color: var(--text); }
.company { font-size: 0.85em; color: var(--text-light); }
```

`repeat(auto-fit, minmax(280px, 1fr))` on `.testimonials-grid` mirrors the features section grid pattern. On a wide screen, all three cards sit in a row. On a narrow screen, they collapse to a single stacked column automatically without any media queries.

**Solution for Exercise 2:**

Add the following HTML just before the closing `</body>` tag:

```html
<a href="#" class="scroll-top" title="Back to top">&#8593;</a>
```

Add the following CSS to `style.css`:

```css
.scroll-top {
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: var(--primary);
    color: white;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2em;
    box-shadow: var(--shadow-lg);
    transition: background 0.2s, transform 0.2s;
}

.scroll-top:hover {
    background: var(--primary-dark);
    transform: translateY(-2px);
}
```

`position: fixed` removes the element from the normal document flow and positions it relative to the viewport, not the page. `bottom: 20px; right: 20px` pins it to the bottom-right corner. `border-radius: 50%` on an element with equal `width` and `height` produces a circle. Using Flexbox with `align-items: center; justify-content: center` centers the arrow character within the circle precisely.

**Solution for Exercise 3:**

Add the following rule at the top of `style.css`, before the `:root` block:

```css
html { scroll-behavior: smooth; }
```

`scroll-behavior: smooth` instructs the browser to animate any anchor-based navigation (links with `href="#section-id"`) rather than teleporting the viewport instantly. This single line applies to all anchor links on the page, including the navigation bar links and the scroll-to-top button.

---

## 7. Next Up - Lesson 14

You have built a complete, responsive, multi-section landing page from scratch. Every concept from Lessons 1 through 12 was used: semantic HTML for structure, CSS custom properties for consistency, Flexbox for component-level alignment, CSS Grid for section-level layouts, the box model for spacing, transitions for interaction feedback, and mobile-first media queries for responsiveness across all screen sizes.

In Lesson 14, you will review the complete arc of the course, learn which topics were not covered and where to find them, explore the path forward into JavaScript and frameworks, and get a set of project ideas you can build independently to continue growing.