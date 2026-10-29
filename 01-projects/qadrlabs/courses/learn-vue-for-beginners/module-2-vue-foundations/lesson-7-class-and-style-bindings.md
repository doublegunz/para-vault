## 1. Before You Begin

In Lesson 6, Tasklane's columns and cards started coming from data, with `v-for` for lists and `v-if` for conditions. The board works, but it does not look like a board yet: the columns are stacked on top of each other, and every card looks the same whether it is urgent, overdue, or finished. On a real Kanban board you can read the situation at a glance from colors alone.

In this lesson you will make Tasklane look like a Kanban board. You will lay out the three columns side by side with CSS Grid, then use Vue's **class bindings** to give each card a priority badge, a red edge when it is overdue, and a faded, crossed-out look when it is done. Finally you will use a **style binding** to give each column its own accent color from the data.

### What You'll Build

A three-column board on a light grey background. Each column has a colored top border (indigo for To Do, amber for In Progress, green for Done). Each card is a white box with a shadow and a small colored priority badge: green for low, amber for medium, red for high. "Set up hosting", whose due date has passed, has a red left edge and red due date text marked "(overdue)". The two Done cards are faded with their titles crossed out.

### What You'll Learn

- ✅ How to lay out a board with CSS Grid in a scoped style block
- ✅ How to bind classes with a string, with an object, and with an array
- ✅ How static `class` and bound `:class` combine on the same element
- ✅ How to bind inline styles with `:style` and camelCase property names
- ✅ How to move reusable logic, such as checking whether a card is overdue, into a utility module
- ✅ When to prefer classes over inline styles

### What You'll Need

- The Tasklane project from Lesson 6, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Lay Out the Board

The columns should sit next to each other, each taking an equal share of the width. CSS Grid is perfect for that, and the layout belongs to `App.vue`, because `App.vue` is the component that places the columns.

### Step 1: Wrap the Columns in a Grid

Replace the contents of `src/App.vue` with this code.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";

function cardsFor(status) {
  return sampleCards.filter((card) => card.status === status);
}
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <div class="board">
      <BoardColumn
        v-for="column in columns"
        :key="column.status"
        :title="column.title"
        :cards="cardsFor(column.status)"
      />
    </div>
  </main>
</template>

<style scoped>
.board {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  align-items: start;
}

@media (max-width: 720px) {
  .board {
    grid-template-columns: 1fr;
  }
}
</style>
```

Here is what changed:

- `<div class="board">` wraps the `v-for` list of columns.
- `display: grid;` turns the wrapper into a grid, and `grid-template-columns: repeat(3, 1fr);` creates three columns of equal width. `1fr` means "one fraction of the free space".
- `gap: 16px;` puts space between the columns.
- `align-items: start;` lets each column be only as tall as its cards. Without it, all columns would stretch to the height of the tallest one.
- The `@media (max-width: 720px)` rule switches to a single column on narrow screens such as phones, so the cards do not get squeezed.

Then open `src/components/BoardColumn.vue` and remove the `max-width: 320px;` line from the `section` rule, because the grid now decides how wide each column is. Save both files.

On a wide window, the three columns now sit side by side. In the Elements panel, the computed value of `grid-template-columns` on the `.board` element shows three equal tracks:

```text
400px 400px 400px
```

The exact numbers depend on the width of your browser window. Make the window narrow and the columns stack again.

---

## 3. Style the Cards with Class Bindings

Every card needs some styles that always apply, such as a white background, and some that depend on the data, such as a red edge when it is overdue. Static styles go in a normal `class` attribute. Data-dependent styles go in `:class`, which accepts three kinds of values:

- A **string**: `` :class="`badge-${card.priority}`" `` adds one computed class name.
- An **object**: `:class="{ done: card.status === 'done' }"` adds each key as a class when its value is true.
- An **array**: `:class="['badge', 'badge-high']"` adds every class in the list.

You can use `class` and `:class` on the same element; Vue merges them.

### Step 1: Create an Overdue Helper

Deciding whether a card is overdue takes a few conditions, and both the card's styles and, in Lesson 12, the board's statistics need it. Logic that several files share belongs in a plain JavaScript module. Create a folder named `utils` inside `src`, and inside it create `dates.js`.

```javascript
export function today() {
  return new Date().toLocaleDateString("en-CA");
}

export function isOverdue(card) {
  return card.dueDate !== "" && card.dueDate < today() && card.status !== "done";
}
```

Here is what the two functions do:

- `today()` returns today's date as text in the `YYYY-MM-DD` format, the same format as `dueDate`. `toLocaleDateString("en-CA")` is a short trick: the Canadian English locale happens to format dates as year-month-day, and it uses your computer's local date rather than the UTC date that `toISOString()` would give you.
- `isOverdue(card)` returns `true` when the card has a due date, the due date is before today, and the card is not done. It is the same rule you wrote in the console in Lesson 1's Exercise 3, with the real date instead of a fixed one.

### Step 2: Add Class Bindings to TaskCard

Replace the contents of `src/components/TaskCard.vue` with this code.

```vue
<script setup>
import { isOverdue } from "../utils/dates.js";

defineProps({
  card: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <article
    :id="`card-${card.id}`"
    :title="card.title"
    class="card"
    :class="{ overdue: isOverdue(card), done: card.status === 'done' }"
  >
    <span class="badge" :class="`badge-${card.priority}`">{{ card.priority }}</span>
    <h4>{{ card.title }}</h4>
    <p v-if="card.description !== ''" class="description">{{ card.description }}</p>
    <p v-if="card.dueDate !== ''" class="due">
      Due <time :datetime="card.dueDate">{{ card.dueDate }}</time>
      <strong v-if="isOverdue(card)"> (overdue)</strong>
    </p>
    <p v-else class="due">No due date</p>
    <p v-show="card.status === 'done'" class="completed">Completed</p>
  </article>
</template>

<style scoped>
.card {
  margin-bottom: 12px;
  padding: 12px 16px;
  background-color: #ffffff;
  border-radius: 8px;
  border-left: 4px solid transparent;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08);
}

.card h4 {
  margin: 8px 0 4px;
}

.description,
.due,
.completed {
  margin: 4px 0;
  font-size: 14px;
  color: #4b5563;
}

.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.badge-low {
  background-color: #dcfce7;
  color: #166534;
}

.badge-medium {
  background-color: #fef3c7;
  color: #92400e;
}

.badge-high {
  background-color: #fee2e2;
  color: #991b1b;
}

.overdue {
  border-left-color: #dc2626;
}

.overdue .due {
  color: #dc2626;
}

.done {
  opacity: 0.7;
}

.done h4 {
  text-decoration: line-through;
}
</style>
```

There is a lot here, so take it in parts. In the script and template:

- `import { isOverdue } from "../utils/dates.js";` imports the helper. The path starts with `../` because `utils` is one folder up from `components`. Imported functions can be called in the template.
- The `<article>` tag now spans several lines. `class="card"` is static and always applies. `:class="{ overdue: isOverdue(card), done: card.status === 'done' }"` is an object binding: the `overdue` class is added when `isOverdue(card)` returns true, and the `done` class when the card is in the Done column.
- `` <span class="badge" :class="`badge-${card.priority}`"> `` combines a static class with a string binding, which produces `badge-low`, `badge-medium`, or `badge-high`. The priority text itself is now lowercase in the HTML, and `text-transform: uppercase;` in CSS shows it in capitals. This replaces the `toUpperCase()` call from Lesson 3, because how text looks is the job of CSS.
- `<strong v-if="isOverdue(card)"> (overdue)</strong>` adds a word next to the date, so the warning does not rely on color alone. Color-blind users and screen readers get the information too.
- The paragraphs have classes such as `description` and `due`, so the stylesheet can target them.

In the stylesheet:

- `.card` creates the white box, with a transparent 4-pixel left border that keeps every card the same width.
- `.badge` and the three `.badge-*` rules create the rounded colored labels.
- `.overdue` colors the left border red, and `.overdue .due` turns the date text red.
- `.done` fades the whole card, and `.done h4` crosses out the title.

Save the file. The text on the board is almost the same as before, with one addition:

The board in the browser, as text:

```text
Website Redesign
To Do (2)
HIGH
Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

LOW
Collect logo files

Ask the client for SVG versions of the logo.

No due date

In Progress (2)
MEDIUM
Design home page

Create the first layout for the home page.

Due 2026-11-07

HIGH
Set up hosting

Due 2026-10-28 (overdue)

Done (2)
MEDIUM
Pick color palette

Choose the primary and accent colors.

Due 2026-10-25

Completed

LOW
Write About page text

Draft a short text about the company.

Due 2026-10-27

Completed
```

This output was captured on 2026-10-29. "Set up hosting" was due on 2026-10-28, so it is marked "(overdue)". If you follow this course later, more cards will be overdue on your board, because their due dates will also be in the past. That is the overdue rule working correctly with today's date. You can change the dates in `board.js` to future dates if you want your board to match these screenshots.

Visually, the cards now have colored badges, "Set up hosting" has a red left edge, and the Done cards are faded with crossed-out titles. To see what Vue did with the bindings, inspect three cards in the Elements panel:

```html
<article data-v-bdaa6335="" data-v-05cf9fb1="" id="card-1" title="Write project brief" class="card"><span data-v-bdaa6335="" class="badge badge-high">high</span><h4 data-v-bdaa6335="">Write project brief</h4><p data-v-bdaa6335="" class="description">Summarize the goals and scope of the website redesign.</p><p data-v-bdaa6335="" class="due"> Due <time data-v-bdaa6335="" datetime="2026-11-03">2026-11-03</time><!--v-if--></p><p data-v-bdaa6335="" class="completed" style="display: none;">Completed</p></article>
<article data-v-bdaa6335="" data-v-05cf9fb1="" id="card-4" title="Set up hosting" class="card overdue"><span data-v-bdaa6335="" class="badge badge-high">high</span><h4 data-v-bdaa6335="">Set up hosting</h4><!--v-if--><p data-v-bdaa6335="" class="due"> Due <time data-v-bdaa6335="" datetime="2026-10-28">2026-10-28</time><strong data-v-bdaa6335=""> (overdue)</strong></p><p data-v-bdaa6335="" class="completed" style="display: none;">Completed</p></article>
<article data-v-bdaa6335="" data-v-05cf9fb1="" id="card-5" title="Pick color palette" class="card done"><span data-v-bdaa6335="" class="badge badge-medium">medium</span><h4 data-v-bdaa6335="">Pick color palette</h4><p data-v-bdaa6335="" class="description">Choose the primary and accent colors.</p><p data-v-bdaa6335="" class="due"> Due <time data-v-bdaa6335="" datetime="2026-10-25">2026-10-25</time><!--v-if--></p><p data-v-bdaa6335="" class="completed">Completed</p></article>
```

Card 1 has only `class="card"`, because both object keys are false. Card 4 has `class="card overdue"`, and card 5 has `class="card done"`. Each badge combines `badge` with the string binding, for example `badge badge-high`. In every case, the static class and the bound classes were merged into one `class` attribute.

---

## 4. Color the Columns with Style Bindings

Some values are not a fixed set of classes but come straight from the data, such as a color. For those, Vue has `:style`, which takes an object of CSS properties. Property names are written in camelCase, like in JavaScript (`borderTopColor`), instead of the kebab-case of CSS (`border-top-color`).

### Step 1: Add a Color to Each Column

Open `src/data/board.js` and give each column a `color`.

```javascript
export const columns = [
  { status: "todo", title: "To Do", color: "#6366f1" },
  { status: "in-progress", title: "In Progress", color: "#f59e0b" },
  { status: "done", title: "Done", color: "#10b981" },
];
```

The `sampleCards` array below it stays the same. Then pass the color to each column in `src/App.vue`:

```vue
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
/>
```

The rest of `App.vue` stays the same as in Section 2.

### Step 2: Bind the Border Color in BoardColumn

Replace the contents of `src/components/BoardColumn.vue` with this code.

```vue
<script setup>
import TaskCard from "./TaskCard.vue";

defineProps({
  title: {
    type: String,
    required: true,
  },
  cards: {
    type: Array,
    required: true,
  },
  color: {
    type: String,
    default: "#9ca3af",
  },
});
</script>

<template>
  <section class="column" :style="{ borderTopColor: color }">
    <h3>{{ title }} ({{ cards.length }})</h3>
    <p v-if="cards.length === 0" class="empty">No cards here yet.</p>
    <template v-else>
      <TaskCard v-for="card in cards" :key="card.id" :card="card" />
    </template>
  </section>
</template>

<style scoped>
.column {
  padding: 12px;
  background-color: #e5e7eb;
  border-radius: 12px;
  border-top: 4px solid #9ca3af;
}

h3 {
  margin: 0 0 12px;
  font-size: 16px;
}

.empty {
  margin: 0;
  padding: 16px;
  text-align: center;
  font-size: 14px;
  color: #6b7280;
}
</style>
```

Here is what changed:

- `color` is a new optional prop with a grey default, so a column without a color still looks fine.
- `<section class="column" :style="{ borderTopColor: color }">` sets the inline style `border-top-color` from the prop. The key is the CSS property in camelCase, and the value is the prop.
- The `.column` rule draws a 4-pixel grey top border. The inline style only overrides its color.
- The `.empty` rule centers the "No cards here yet." message from Lesson 6 and makes it grey.

Save all three files. Each column now has a colored band along its top edge. Inspect the three sections:

```html
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(99, 102, 241);">
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(245, 158, 11);">
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(16, 185, 129);">
```

Vue converted `borderTopColor` back to the CSS name `border-top-color`, and the browser shows the hex colors from the data as `rgb(...)` values.

Use `:style` sparingly. Classes are easier to reuse, to override, and to change in one place. Reach for `:style` when the value itself comes from data and cannot be listed in advance, such as a user-chosen color or a progress bar width. A fixed set of variations, such as three priorities, is a job for `:class`.

---

## 5. Run and Test

Restart the development server and open `http://localhost:5173`. Check the following:

1. The three columns sit side by side, each with a colored top border.
2. Each card has a rounded badge: red for high, amber for medium, green for low.
3. "Set up hosting" has a red left edge and red due date text ending in "(overdue)".
4. The two Done cards are faded and their titles are crossed out.
5. Making the browser window narrow stacks the columns vertically.

Then run the linters.

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

No problems are reported. Your project now has a `utils` folder:

```text
src/
├── assets/
│   └── main.css
├── components/
│   ├── AppHeader.vue
│   ├── BoardColumn.vue
│   └── TaskCard.vue
├── data/
│   └── board.js
├── utils/
│   └── dates.js
├── App.vue
└── main.js
```

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with class and style bindings.

**Error 1: Using curly braces inside an attribute.**

`{{ }}` only works in text between tags. Inside an attribute, it is copied as literal text.

```vue
<!-- Wrong -->
<span class="badge badge-{{ card.priority }}">{{ card.priority }}</span>

<!-- Correct -->
<span class="badge" :class="`badge-${card.priority}`">{{ card.priority }}</span>
```

The wrong version shows no error, but the badges lose their colors. In the Elements panel, the class attribute of the first badge is literally:

```text
badge badge-{{ card.priority }}
```

The browser sees four class names, `badge`, `badge-{{`, `card.priority`, and `}}`, and only `badge` matches a rule, so the color rules such as `.badge-high` never apply. Use `:class` with a template literal instead.

**Error 2: Writing CSS property names in kebab-case without quotes.**

The value of `:style` is a JavaScript object, and an unquoted object key cannot contain a hyphen.

```vue
<!-- Wrong -->
<section class="column" :style="{ border-top-color: color }">

<!-- Correct -->
<section class="column" :style="{ borderTopColor: color }">
```

The wrong version does not compile, and the browser shows this overlay:

```text
[plugin:vite:vue] Error parsing JavaScript expression: Unexpected token, expected "," (1:9)
```

JavaScript reads `border - top - color` as a subtraction and stops at the unexpected `-`. Write the property in camelCase, or quote it: `{ 'border-top-color': color }` also works.

**Error 3: Passing a function instead of calling it.**

A class object adds a class when its value is truthy. A function is always truthy, whether or not it would return `true`.

```vue
<!-- Wrong -->
<article
  :id="`card-${card.id}`"
  :title="card.title"
  class="card"
  :class="{ overdue: isOverdue, done: card.status === 'done' }"
>

<!-- Correct -->
<article
  :id="`card-${card.id}`"
  :title="card.title"
  class="card"
  :class="{ overdue: isOverdue(card), done: card.status === 'done' }"
>
```

The wrong version shows no error, but every card gets a red edge. The class of each card in the Elements panel:

```text
card-1: card overdue
card-2: card overdue
card-3: card overdue
card-4: card overdue
card-5: card overdue done
card-6: card overdue done
```

`isOverdue` without parentheses is the function itself, not its result. Add `(card)` to call it. This mistake is common in AI-generated code too, so remember the symptom: a class that appears on every item.

---

## 7. Exercises

**Exercise 1:** Make an empty column look different from a full one. In `BoardColumn.vue`, add a class named `is-empty` to the `section` when the column has no cards, and give `.is-empty` a transparent background and a dashed `2px` grey border (`#d1d5db`), while keeping the colored top border. Test it by adding the Review column from Lesson 6's Exercise 2 with the color `#ec4899`. Hint: an object key with a hyphen must be quoted.

**Exercise 2:** In `TaskCard.vue`, the badge uses both `class="badge"` and a string `:class`. Rewrite it with a single `:class` that uses the array syntax, and check in the Elements panel that the resulting class attribute is the same.

**Exercise 3:** Replace the count in parentheses in each column title with a small rounded "pill" whose background color is the column's color: white text, `12px` font, at least `20px` wide. Use a `<span class="count">` with a style binding.

---

## 8. Solutions

**Solution for Exercise 1:**

Change the opening `section` tag in `src/components/BoardColumn.vue`:

```vue
<section
  class="column"
  :class="{ 'is-empty': cards.length === 0 }"
  :style="{ borderTopColor: color }"
>
```

Then add this rule to the style block, before `.empty`:

```css
.is-empty {
  background-color: transparent;
  border: 2px dashed #d1d5db;
  border-top: 4px solid #9ca3af;
}
```

`'is-empty'` must be in quotes because of the hyphen. The rule replaces the background and border, and `border-top` restores the 4-pixel top border, whose color still comes from the style binding, because inline styles win over stylesheet rules. To test it, add `{ status: "review", title: "Review", color: "#ec4899" }` to `columns` in `board.js`.

The four sections in the Elements panel:

```html
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(99, 102, 241);">
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(245, 158, 11);">
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column" style="border-top-color: rgb(16, 185, 129);">
<section data-v-05cf9fb1="" data-v-7a7a37b1="" class="column is-empty" style="border-top-color: rgb(236, 72, 153);">
```

Only the Review column gets `is-empty`. It appears as a dashed outline with a pink top border and the "No cards here yet." message in the middle. Remove the Review column from `board.js` afterward.

**Solution for Exercise 2:**

```vue
<span :class="['badge', `badge-${card.priority}`]">{{ card.priority }}</span>
```

The array contains a fixed string, `'badge'`, and a template literal. Vue adds every item of the array as a class. The first badge in the Elements panel:

```html
<span data-v-bdaa6335="" class="badge badge-high">high</span>
```

The result is identical to the version with `class` and `:class`. Both styles are common; this course keeps static classes in `class` because it makes the fixed part easy to spot.

**Solution for Exercise 3:**

Change the `h3` in the template of `src/components/BoardColumn.vue`:

```vue
<h3>
  {{ title }}
  <span class="count" :style="{ backgroundColor: color }">{{ cards.length }}</span>
</h3>
```

Then add a `.count` rule to the style block:

```css
.count {
  display: inline-block;
  min-width: 20px;
  margin-left: 4px;
  padding: 0 6px;
  border-radius: 999px;
  font-size: 12px;
  line-height: 20px;
  text-align: center;
  color: #ffffff;
}
```

The pill's background comes from the same `color` prop as the top border, so each count matches its column. The column titles in the Elements panel:

```html
<h3 data-v-05cf9fb1="">To Do <span data-v-05cf9fb1="" class="count" style="background-color: rgb(99, 102, 241);">2</span></h3>
<h3 data-v-05cf9fb1="">In Progress <span data-v-05cf9fb1="" class="count" style="background-color: rgb(245, 158, 11);">2</span></h3>
<h3 data-v-05cf9fb1="">Done <span data-v-05cf9fb1="" class="count" style="background-color: rgb(16, 185, 129);">2</span></h3>
```

The titles now read "To Do", "In Progress", and "Done", each followed by a colored number. You can keep this version; the next lessons show the counts in parentheses so the text output stays easy to read, and either version works with the rest of the course.

---

## Next Up - Lesson 8

In this lesson you turned Tasklane into a real-looking Kanban board. You laid out the columns with CSS Grid, created an `isOverdue` helper in a utility module, bound classes with strings, objects, and arrays to show priority badges, overdue warnings, and finished cards, and bound inline styles to color each column from the data. That completes Module 2: you can now display any data as a styled, component-based interface.

Module 3 makes Tasklane interactive. In Lesson 8, you will add buttons to the cards and the header, respond to clicks with `v-on`, use event modifiers, and send events from a child component up to its parent with `defineEmits`.
