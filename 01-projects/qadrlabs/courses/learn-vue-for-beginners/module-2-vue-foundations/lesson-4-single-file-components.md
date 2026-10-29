## 1. Before You Begin

In Lesson 3, you displayed Tasklane's first card with template syntax: `{{ }}` for text, expressions for formatting, and `v-bind` for attributes. Everything lives in `App.vue`. That works for one card, but a real board has a header, three columns, and many cards. If all of that stays in one file, `App.vue` grows into hundreds of lines that are hard to read and impossible to reuse.

Vue solves this with **components**: small, reusable pieces of interface, each in its own `.vue` file. In this lesson you will split Tasklane into its first three components, `AppHeader`, `TaskCard`, and `BoardColumn`, learn how one component imports and uses another, and see how the `<template>`, `<script setup>`, and `<style scoped>` blocks of a single-file component work together.

### What You'll Build

A Tasklane page made of components. `App.vue` shows `AppHeader` at the top and a `BoardColumn` titled "To Do". The column itself contains two `TaskCard` components. Each component has its own small stylesheet that does not leak into the others.

### What You'll Learn

- ✅ What a single-file component is and why apps are split into components
- ✅ How to create a component in `src/components/`
- ✅ How to import a component and use it as a tag in a template
- ✅ How components nest inside other components to form a component tree
- ✅ How `<style scoped>` keeps a component's CSS from affecting the rest of the page
- ✅ The naming conventions Vue developers use for component files and tags

### What You'll Need

- The Tasklane project from Lesson 3, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Create the AppHeader Component

The easiest part of the page to move into its own component is the header: the "Tasklane" heading and the tagline. It has no data and does not change, so it is a good first component.

### Step 1: Create the Component File

Components live in a folder named `components` inside `src`. Create the folder `src/components`, and inside it create a file named `AppHeader.vue` with this code.

```vue
<template>
  <header>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>
  </header>
</template>
```

Here is what the code does:

- The file has only a `<template>` block. A component without any JavaScript does not need `<script setup>`, and one without CSS does not need `<style>`.
- `<header>` is the HTML element for the top part of a page. It wraps the heading and the tagline you wrote in Lesson 2.

The file name follows two Vue conventions. Component names use **PascalCase**, where each word starts with a capital letter, so they never clash with HTML elements, which are lowercase. And they use at least two words, such as `AppHeader` instead of `Header`, so they never clash with a future HTML element either. The `App` prefix is a common way to mark components that appear only once in the whole app.

### Step 2: Use AppHeader in App.vue

A component does nothing until another component uses it. Replace the contents of `src/App.vue` with this code.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";

const boardName = "Website Redesign";
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
  </main>
</template>
```

Here is what changed:

- `import AppHeader from "./components/AppHeader.vue";` imports the component. The path starts with `./` because it is relative to `App.vue`, and it ends with the `.vue` extension.
- In `<script setup>`, an imported component is available in the template right away, just like a variable.
- `<AppHeader />` uses the component as if it were an HTML tag. The slash before `>` makes it self-closing, because nothing goes inside it.
- The card from Lesson 3 is gone for now. You will bring it back as its own component in the next section.

Save both files.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign
```

The page looks the same as before, but the header now comes from `AppHeader.vue`. Inspect the page and you will see that the `<AppHeader />` tag itself is not in the HTML. Vue replaced it with what the component's template renders.

The HTML inside `<div id="app">`:

```html
<header><h1>Tasklane</h1><p>Plan your work, one card at a time.</p></header><main><h2>Website Redesign</h2></main>
```

---

## 3. Create the TaskCard Component

The card is the piece Tasklane will repeat the most, so it deserves its own component. A component can have its own `<script setup>` with its own data, so the card object moves into the component too.

### Step 1: Create TaskCard.vue

Create `src/components/TaskCard.vue` with this code.

```vue
<script setup>
const card = {
  id: 1,
  title: "Write project brief",
  description: "Summarize the goals and scope of the website redesign.",
  status: "todo",
  priority: "high",
  dueDate: "2026-11-03",
};
</script>

<template>
  <article :id="`card-${card.id}`" :title="card.title">
    <p>{{ card.priority.toUpperCase() }}</p>
    <h4>{{ card.title }}</h4>
    <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
    <p>
      Due
      <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
    </p>
  </article>
</template>
```

Here is what the code does:

- `<script setup>` declares the `card` constant. This time it holds card 1, the first card in the To Do column. The `card` variable belongs to `TaskCard` only; `App.vue` cannot see it.
- The template is the card from Lesson 3, with two changes: the title is now an `<h4>`, because the board name is `<h2>` and the column titles will be `<h3>`, and the status message is gone, because the column a card sits in already tells you its status.

### Step 2: Show the Card in App.vue

Import the new component and use it under the board name.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import TaskCard from "./components/TaskCard.vue";

const boardName = "Website Redesign";
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <TaskCard />
  </main>
</template>
```

`<TaskCard />` renders the whole card wherever you put the tag. Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03
```

`App.vue` is now short and easy to read: a header, a board name, and a card. The details of how a card looks live in `TaskCard.vue`.

---

## 4. Create the BoardColumn Component

A Kanban board is made of columns, and each column holds cards. That means components can contain other components. In this section you will create `BoardColumn`, which uses `TaskCard` inside its own template.

### Step 1: Create BoardColumn.vue

Create `src/components/BoardColumn.vue` with this code.

```vue
<script setup>
import TaskCard from "./TaskCard.vue";
</script>

<template>
  <section>
    <h3>To Do</h3>
    <TaskCard />
    <TaskCard />
  </section>
</template>
```

Here is what the code does:

- `import TaskCard from "./TaskCard.vue";` imports the card component. The path is `./TaskCard.vue` because both files are in the same `components` folder.
- `<section>` is the HTML element for a group of related content, here one column.
- `<h3>To Do</h3>` is the column title.
- `<TaskCard />` appears twice. A component can be used as many times as you like; each tag creates a separate copy, called an **instance**.

### Step 2: Show the Column in App.vue

`App.vue` no longer needs `TaskCard` directly. It uses `BoardColumn`, which takes care of the cards.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";

const boardName = "Website Redesign";
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <BoardColumn />
  </main>
</template>
```

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign
To Do

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03
```

The column shows two cards, and they are identical, because both instances read the same hard-coded `card` constant inside `TaskCard.vue`. The HTML also contains two elements with `id="card-1"`, which is not allowed, since an `id` must be unique on a page. A card component that can only ever show one card is not very useful. In Lesson 5, you will fix this with **props**, which let `BoardColumn` pass a different card to each `TaskCard`.

Your app now forms a **component tree**:

```text
App
├── AppHeader
└── BoardColumn
    ├── TaskCard
    └── TaskCard
```

---

## 5. Add Scoped Styles

Each component can carry its own CSS in a `<style>` block. With the `scoped` attribute, those styles apply only to the elements of that component, even if another component uses the same tags. That means you can write a simple rule like `p { ... }` without worrying about breaking another part of the page.

### Step 1: Style the Header and the Card

Open `src/components/AppHeader.vue` and add a style block at the end.

```vue
<template>
  <header>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>
  </header>
</template>

<style scoped>
p {
  margin-top: 0;
  color: #6b7280;
}
</style>
```

The rule removes the space above the tagline and makes it grey, so it reads as a subtitle. Then open `src/components/TaskCard.vue` and add a style block at the end, after the template.

```vue
<script setup>
const card = {
  id: 1,
  title: "Write project brief",
  description: "Summarize the goals and scope of the website redesign.",
  status: "todo",
  priority: "high",
  dueDate: "2026-11-03",
};
</script>

<template>
  <article :id="`card-${card.id}`" :title="card.title">
    <p>{{ card.priority.toUpperCase() }}</p>
    <h4>{{ card.title }}</h4>
    <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
    <p>
      Due
      <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
    </p>
  </article>
</template>

<style scoped>
article {
  margin-bottom: 12px;
  padding: 12px 16px;
  background-color: #ffffff;
  border-radius: 8px;
}
</style>
```

Each card is now a white box with rounded corners and some space between cards, the first step toward looking like a real Kanban card. Save both files.

### Step 2: See How Scoped Styles Work

The `AppHeader` rule targets every `p`, and the card also contains `<p>` elements. Look at the page: only the tagline is grey. The paragraphs inside the cards keep the dark text color from `main.css`. To see why, inspect the header and a card in the Elements panel.

The header and the first card in the Elements panel:

```html
<header data-v-48a13218=""><h1 data-v-48a13218="">Tasklane</h1><p data-v-48a13218="">Plan your work, one card at a time.</p></header>
<article data-v-bdaa6335="" id="card-1" title="Write project brief"><p data-v-bdaa6335="">HIGH</p><h4 data-v-bdaa6335="">Write project brief</h4><p data-v-bdaa6335="">Summarize the goals and scope of the website redesign.</p><p data-v-bdaa6335=""> Due <time data-v-bdaa6335="" datetime="2026-11-03">2026-11-03</time></p></article>
```

Vue gave every element of `AppHeader` an attribute `data-v-48a13218`, and every element of `TaskCard` a different one, `data-v-bdaa6335`. The exact codes in your browser will be different; they are generated from the file. Vue also rewrote your CSS rule. In the `<head>` of the page, the header's style looks like this:

```css
p[data-v-48a13218] {
  margin-top: 0;
  color: #6b7280;
}
```

The selector now means "a `p` that has the attribute `data-v-48a13218`", which only the header's paragraph has. That is how `scoped` keeps each component's styles to itself. Global styles, such as the font and background in `main.css`, still apply everywhere.

---

## 6. Run and Test

Restart the development server to check everything from a fresh start.

```bash
npm run dev
```

Open `http://localhost:5173` and check the following:

1. The header shows "Tasklane" and a grey tagline directly under it.
2. The "Website Redesign" heading is followed by the "To Do" column title.
3. The column shows two white cards with rounded corners, both for "Write project brief".
4. The paragraphs inside the cards are dark grey, not light grey.

Your project now looks like this:

```text
src/
├── assets/
│   └── main.css
├── components/
│   ├── AppHeader.vue
│   ├── BoardColumn.vue
│   └── TaskCard.vue
├── App.vue
└── main.js
```

Run the linters in a second terminal.

```bash
npm run lint
```

Output:

```text

> tasklane@0.0.0 lint
> run-s "lint:*"


> tasklane@0.0.0 lint:oxlint
> oxlint . --fix


> tasklane@0.0.0 lint:eslint
> eslint . --fix --cache

```

No problems are reported.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when creating and using components.

**Error 1: Using a component without importing it.**

A component must be imported in every file that uses it. Using the tag alone is not enough.

```vue
<!-- Wrong -->
<script setup>
import AppHeader from "./components/AppHeader.vue";

const boardName = "Website Redesign";
</script>

<!-- Correct -->
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";

const boardName = "Website Redesign";
</script>
```

With the wrong version, the column is missing from the page, and the console shows this warning:

```text
[Vue warn]: Failed to resolve component: BoardColumn
If this is a native custom element, make sure to exclude it from component resolution via compilerOptions.isCustomElement. 
  at <App>
```

"Failed to resolve component" means Vue found a tag named `BoardColumn` but no component with that name. The second line is about custom elements, a different web technology you are not using, so you can ignore it. Add the missing import.

**Error 2: Leaving out the `.vue` extension.**

In a Vite project, imports of `.vue` files must include the extension.

```javascript
// Wrong
import BoardColumn from "./components/BoardColumn";

// Correct
import BoardColumn from "./components/BoardColumn.vue";
```

The wrong version shows a red error overlay with this message:

```text
[plugin:vite:import-analysis] Failed to resolve import "./components/BoardColumn" from "src/App.vue". Does the file exist?
```

Vite looks for a file named exactly `BoardColumn`, without an extension, and does not find one. Add `.vue` to the path.

**Error 3: Importing a component with curly braces.**

A `.vue` file has a **default export**: the component itself. Default exports are imported without curly braces.

```javascript
// Wrong
import { BoardColumn } from "./components/BoardColumn.vue";

// Correct
import BoardColumn from "./components/BoardColumn.vue";
```

With the wrong version, the page is blank and the console shows this error:

```text
SyntaxError: The requested module '/src/components/BoardColumn.vue' does not provide an export named 'BoardColumn'
```

Curly braces ask for a **named export** called `BoardColumn`, which the file does not have. Remove the braces. You will see named exports with curly braces later, for example `import { ref } from "vue"`, where they are correct.

---

## 8. Exercises

**Exercise 1:** Create a component named `AppFooter` that renders a `<footer>` containing the paragraph `Tasklane, built with Vue.`, and show it below `<main>` in `App.vue`.

**Exercise 2:** Give the column a background so it looks like a Kanban lane. Add a `<style scoped>` block to `BoardColumn.vue` that gives the `section` a maximum width of `320px`, a padding of `12px`, the background color `#e5e7eb`, and a border radius of `12px`, and removes the top margin of the `h3` while keeping `12px` below it. Does the new `h3` rule affect the `h1` in the header?

**Exercise 3:** In your own words, explain why the two cards in the To Do column are identical. What would you need to change so that `BoardColumn` could show two different cards with one `TaskCard` component?

---

## 9. Solutions

**Solution for Exercise 1:**

Create `src/components/AppFooter.vue`:

```vue
<template>
  <footer>
    <p>Tasklane, built with Vue.</p>
  </footer>
</template>
```

Then import it and use it in `src/App.vue`:

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import AppFooter from "./components/AppFooter.vue";
import BoardColumn from "./components/BoardColumn.vue";

const boardName = "Website Redesign";
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <BoardColumn />
  </main>

  <AppFooter />
</template>
```

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign
To Do

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

Tasklane, built with Vue.
```

The footer follows the same pattern as the header: create the file, import it, and use the tag. The course does not use the footer later, so you can keep it or remove it.

**Solution for Exercise 2:**

Add the style block to the end of `src/components/BoardColumn.vue`:

```vue
<script setup>
import TaskCard from "./TaskCard.vue";
</script>

<template>
  <section>
    <h3>To Do</h3>
    <TaskCard />
    <TaskCard />
  </section>
</template>

<style scoped>
section {
  max-width: 320px;
  padding: 12px;
  background-color: #e5e7eb;
  border-radius: 12px;
}

h3 {
  margin: 0 0 12px;
}
</style>
```

The column is now a grey lane, 320 pixels wide, with the white cards inside it. `margin: 0 0 12px;` sets the top, left and right, and bottom margins of the column title in one line. The `h3` rule does not affect the `h1` in the header for two reasons: it targets a different element, and because it is scoped, it only applies to elements inside `BoardColumn`. In the browser, the computed top margin of the `h1` is still the browser default (`21.44px` with the default font size), while the `h3` has a top margin of `0px`. In Lesson 7 you will build the full board layout with three columns side by side.

**Solution for Exercise 3:**

Both cards are identical because `TaskCard` always displays the same `card` constant, which is written inside `TaskCard.vue` itself. Every instance of the component runs the same code, so every instance shows card 1. To show different cards, the card data must come from outside the component: `BoardColumn` would need a way to say "show this card here and that card there", and `TaskCard` would need a way to receive it. In Vue, that way is called props, and it is the topic of Lesson 5.

---

## Next Up - Lesson 5

In this lesson you split Tasklane into single-file components. You created `AppHeader`, `TaskCard`, and `BoardColumn`, imported components with a default import and used them as tags, nested `TaskCard` inside `BoardColumn` to form a component tree, and added scoped styles that stay inside their own component.

In Lesson 5, you will make these components reusable with props. `App.vue` will hold all of Tasklane's sample cards, `BoardColumn` will receive its title and its cards from the outside, and `TaskCard` will receive the card it should display, so the board can finally show three different columns with real data.
