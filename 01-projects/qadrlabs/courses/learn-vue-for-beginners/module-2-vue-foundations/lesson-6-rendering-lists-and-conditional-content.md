## 1. Before You Begin

In Lesson 5, props let `BoardColumn` and `TaskCard` show real data, and the board now displays all six sample cards. But the code has two hard-coded spots. `BoardColumn` renders exactly two cards, `cards[0]` and `cards[1]`, so a third card is silently ignored and an empty column would crash. And `App.vue` writes out three `BoardColumn` tags by hand. Real data changes all the time, so the template must adapt to however many items there are.

In this lesson you will learn Vue's directives for lists and conditions. `v-for` renders one element or component for every item in an array, and the `key` attribute helps Vue keep track of each one. `v-if`, `v-else`, and `v-show` decide whether something appears at all. You will use them to render every card, generate the columns from data, hide empty details on a card, and show a friendly message when a column has no cards.

### What You'll Build

A board whose columns and cards are generated entirely from data. Each column renders all of its cards, however many there are, or shows "No cards here yet." when it is empty. Each card shows its description only when it has one, shows "No due date" when it has no deadline, and shows "Completed" when it is in the Done column.

### What You'll Learn

- ✅ How to render a list with `v-for`, and how to get the index of each item
- ✅ Why every item in a `v-for` list needs a unique `key`
- ✅ How to render a list of components and pass each item as a prop
- ✅ How to show or hide elements with `v-if`, `v-else-if`, and `v-else`
- ✅ How to group elements with `<template>` without adding extra HTML
- ✅ The difference between `v-if` and `v-show`, and when to use each
- ✅ Why `v-if` and `v-for` should not be used on the same element

### What You'll Need

- The Tasklane project from Lesson 5, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Render Lists with v-for

`v-for` repeats an element once for every item in an array. Its syntax reads almost like English: `v-for="card in cards"` means "for every `card` in the `cards` array, render this element, and let me call the current item `card`".

### Step 1: Render Every Card in a Column

Open `src/components/BoardColumn.vue` and replace the two hard-coded `TaskCard` lines with a single `v-for`.

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
});
</script>

<template>
  <section>
    <h3>{{ title }} ({{ cards.length }})</h3>
    <TaskCard v-for="card in cards" :key="card.id" :card="card" />
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

Here is what the new line does:

- `v-for="card in cards"` renders one `TaskCard` for each item in the `cards` prop. Inside the tag, `card` is the current item.
- `:key="card.id"` gives each rendered card a unique identifier. You will learn why keys matter in Section 3.
- `:card="card"` passes the current item to the `card` prop of `TaskCard`. The first `card` is the prop name, and the second `card` is the loop variable.

Save the file. The board looks exactly the same as before, with two cards in each column. The difference shows up when the number of cards changes. To test it, add the seventh card from Lesson 5's Exercise 3 to `src/data/board.js`, right after card 2:

```javascript
  {
    id: 7,
    title: "Write SEO checklist",
    description: "List the pages that need titles and descriptions.",
    status: "todo",
    priority: "medium",
    dueDate: "2026-11-10",
  },
```

Save the file.

The column headers on the page:

```text
To Do (3) | In Progress (2) | Done (2)
```

This time, "Write SEO checklist" appears in the To Do column, and the board shows all seven cards. `v-for` renders whatever is in the array. Remove card 7 again so the board goes back to six cards.

### Step 2: Generate the Columns from Data

`App.vue` still writes three `BoardColumn` tags by hand and keeps three filtered arrays. The list of columns is data too, so it can live in the data file and be rendered with `v-for`. Open `src/data/board.js` and add a `columns` array at the top of the file, above `sampleCards`.

```javascript
export const columns = [
  { status: "todo", title: "To Do" },
  { status: "in-progress", title: "In Progress" },
  { status: "done", title: "Done" },
];
```

Each column object has a `status`, which matches the `status` of the cards that belong in it, and a `title` to display. The rest of the file, the `sampleCards` array, stays the same.

Then replace the contents of `src/App.vue` with this code.

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
    <BoardColumn
      v-for="column in columns"
      :key="column.status"
      :title="column.title"
      :cards="cardsFor(column.status)"
    />
  </main>
</template>
```

Here is what changed:

- `import { columns, sampleCards } from "./data/board.js";` imports both named exports in one line.
- `function cardsFor(status)` returns the cards whose status matches. It replaces the three separate constants from Lesson 5. Functions declared in `<script setup>` are available in the template, just like variables.
- `v-for="column in columns"` renders one `BoardColumn` per column object.
- `:key="column.status"` uses the status as the key, because every column has a different status.
- `:cards="cardsFor(column.status)"` calls the function with the current column's status and passes the result as the `cards` prop.
- The tag is long, so each attribute sits on its own line. This is the usual style for components with several props.

Save both files. The board still shows the same three columns with the same cards.

The column headers on the page:

```text
To Do (2) | In Progress (2) | Done (2)
```

The template no longer knows how many columns or cards there are. If you added a fourth column object to `columns`, a fourth lane would appear without changing a single line of the template. You will try that in Exercise 2.

---

## 3. Why Every List Item Needs a Key

When the data behind a `v-for` changes, Vue does not throw the whole list away and draw it again; that would be slow. Instead, it compares the old list with the new one and changes only what is different. To do that correctly, it must know which old item corresponds to which new item. The `key` is that identity card.

Imagine the To Do column shows cards 1 and 2, and card 1 is moved to In Progress. With keys, Vue sees that the item with key `2` still exists and the item with key `1` is gone, so it removes exactly the element for card 1 and keeps the element for card 2 untouched. Without keys, Vue falls back to comparing items by position. It would reuse the first element for card 2 and remove the last one. For simple text that usually looks fine, but for elements that hold their own state, such as an input you are typing in, an open menu, or an animation, the state ends up attached to the wrong card.

A good key has three properties:

- It is **unique** within the list. Two cards with the same key confuse Vue.
- It is **stable**: the same item has the same key every time the list is rendered.
- It comes from the **data**, such as an `id`. The array index is not a good key for lists that can be reordered, filtered, or have items removed, because the index of an item changes when the items before it change.

This is why Tasklane's cards have an `id`, and why Lesson 1 warned you about duplicate ids. Vue's linter also helps: as you will see in Section 7, it reports a `v-for` on a component without a key as an error.

---

## 4. Show and Hide Content with v-if and v-show

A Kanban board is full of conditions. An empty column needs a message instead of nothing, a card without a description should not show an empty paragraph, and finished cards deserve a "Completed" label. Vue handles conditions with directives.

### Step 1: Show a Message in Empty Columns

`v-if` renders an element only when its expression is true. `v-else` renders an element when the `v-if` before it was false. Update the template of `src/components/BoardColumn.vue`:

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
});
</script>

<template>
  <section>
    <h3>{{ title }} ({{ cards.length }})</h3>
    <p v-if="cards.length === 0">No cards here yet.</p>
    <template v-else>
      <TaskCard v-for="card in cards" :key="card.id" :card="card" />
    </template>
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

Here is what the new lines do:

- `<p v-if="cards.length === 0">` renders the message only when the column has no cards.
- `<template v-else>` renders its content when the column does have cards. A `v-else` must come directly after the element with `v-if`.
- `<template>` is an invisible wrapper. It lets you apply a directive to a group of elements without adding an extra `<div>` to the page. Here it holds the `v-for` list, which keeps `v-else` and `v-for` on different elements.

Every column has cards at the moment, so nothing changes on the page yet. You will see the message in Exercise 2, when you add an empty column.

### Step 2: Show Card Details Only When They Exist

In Lesson 3 you used ternaries to show "No description yet." and "Due anytime". With `v-if`, a card can simply leave out what it does not have. Replace the contents of `src/components/TaskCard.vue` with this code.

```vue
<script setup>
defineProps({
  card: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <article :id="`card-${card.id}`" :title="card.title">
    <p>{{ card.priority.toUpperCase() }}</p>
    <h4>{{ card.title }}</h4>
    <p v-if="card.description !== ''">{{ card.description }}</p>
    <p v-if="card.dueDate !== ''">
      Due <time :datetime="card.dueDate">{{ card.dueDate }}</time>
    </p>
    <p v-else>No due date</p>
    <p v-show="card.status === 'done'">Completed</p>
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

Here is what changed:

- `<p v-if="card.description !== ''">` renders the description only when it is not empty. There is no `v-else`, so a card without a description simply has no description paragraph.
- `<p v-if="card.dueDate !== ''">` shows the due date when there is one, and the `<p v-else>` right after it shows "No due date" otherwise.
- `<p v-show="card.status === 'done'">Completed</p>` uses `v-show` instead of `v-if`. Notice the single quotes around `'done'`: the attribute value is already inside double quotes, so strings inside it use single quotes.

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

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

Due 2026-10-28

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

"Set up hosting" no longer shows a description line, "Collect logo files" says "No due date", and both cards in the Done column say "Completed".

### Step 3: Compare v-if and v-show in the Elements Panel

`v-if` and `v-show` look similar on the page, but they work differently. Right-click the "Set up hosting" card, choose **Inspect**, and look at its HTML.

The "Set up hosting" card in the Elements panel:

```html
<article data-v-bdaa6335="" data-v-05cf9fb1="" id="card-4" title="Set up hosting"><p data-v-bdaa6335="">HIGH</p><h4 data-v-bdaa6335="">Set up hosting</h4><!--v-if--><p data-v-bdaa6335=""> Due <time data-v-bdaa6335="" datetime="2026-10-28">2026-10-28</time></p><p data-v-bdaa6335="" style="display: none;">Completed</p></article>
```

Two details stand out:

- Where the description would be, there is only a comment, `<!--v-if-->`. When a `v-if` condition is false, the element does not exist in the page at all. Vue leaves a comment as a placeholder so it knows where to insert the element if the condition becomes true.
- The "Completed" paragraph is there, but with `style="display: none;"`. `v-show` always renders the element and only toggles its CSS `display` property.

The two `data-v-...` attributes on the `<article>` come from scoped styles: one from `TaskCard` and one from `BoardColumn`, because the root element of a child component also receives the parent's scope attribute.

So which one should you use? `v-if` is the default choice: it keeps the page free of elements that are not needed. `v-show` is useful for something that is toggled on and off very often, such as a dropdown or a details panel, because showing and hiding with CSS is cheaper than creating and destroying elements again and again. A card's "Completed" label rarely changes, so `v-if` would be just as good here; `v-show` is used so you can see the difference.

---

## 5. Run and Test

Restart the development server and open `http://localhost:5173`. Check the following:

1. The board shows three columns, To Do, In Progress, and Done, each with two cards.
2. "Set up hosting" has no description line, and "Collect logo files" shows "No due date".
3. Only the cards in the Done column show "Completed".
4. Adding a card to `sampleCards` makes it appear in the right column, and removing it makes it disappear.

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

No problems are reported.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with lists and conditions.

**Error 1: Forgetting the key on a component in v-for.**

```vue
<!-- Wrong -->
<TaskCard v-for="card in cards" :card="card" />

<!-- Correct -->
<TaskCard v-for="card in cards" :key="card.id" :card="card" />
```

The page still renders, but `npm run lint` reports the problem:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/BoardColumn.vue
  21:7  error  Custom elements in iteration require 'v-bind:key' directives  vue/valid-v-for

✖ 1 problem (1 error, 0 warnings)

ERROR: "lint:eslint" exited with 1.
```

"Custom elements" here means components. Add a `:key` with a unique, stable value from the data, usually an `id`.

**Error 2: Putting v-if and v-for on the same element.**

It is tempting to filter a list by adding `v-if` to the element that has `v-for`, for example to show only high-priority cards.

```vue
<!-- Wrong -->
<TaskCard
  v-for="card in cards"
  v-if="card.priority === 'high'"
  :key="card.id"
  :card="card"
/>

<!-- Correct -->
<template v-for="card in cards" :key="card.id">
  <TaskCard v-if="card.priority === 'high'" :card="card" />
</template>
```

In Vue 3, `v-if` runs before `v-for` when both are on the same element, so the condition is checked before `card` even exists. The page goes blank, and the console shows:

```text
[Vue warn]: Property "card" was accessed during render but is not defined on instance. 
  at <BoardColumn key="todo" title="To Do" cards= Array(2) > 
  at <App>
```

followed by `TypeError: Cannot read properties of undefined (reading 'priority')`. The linter also flags it:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/BoardColumn.vue
  21:7  error  The 'cards' variable inside 'v-for' directive should be replaced with a computed property that returns filtered array instead. You should not mix 'v-for' with 'v-if'  vue/no-use-v-if-with-v-for

✖ 1 problem (1 error, 0 warnings)

ERROR: "lint:eslint" exited with 1.
```

The correct version moves `v-for` to a `<template>` wrapper, so the `v-if` inside it runs once per card. The linter's advice is even better: filter the array before the template sees it, with a computed property. You will learn computed properties in Lesson 12 and use them for Tasklane's priority filter.

**Error 3: A v-else that is not right after its v-if.**

`v-else` belongs to the element immediately before it. Anything placed between them breaks the pair.

```vue
<!-- Wrong -->
<p v-if="card.dueDate !== ''">
  Due <time :datetime="card.dueDate">{{ card.dueDate }}</time>
</p>
<p v-show="card.status === 'done'">Completed</p>
<p v-else>No due date</p>

<!-- Correct -->
<p v-if="card.dueDate !== ''">
  Due <time :datetime="card.dueDate">{{ card.dueDate }}</time>
</p>
<p v-else>No due date</p>
<p v-show="card.status === 'done'">Completed</p>
```

The wrong version does not compile. The browser shows a red overlay with this message:

```text
[plugin:vite:vue] v-else/v-else-if has no adjacent v-if or v-else-if.
```

The linter reports it as well:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/TaskCard.vue
  19:8  error  'v-else' directives require being preceded by the element which has a 'v-if' or 'v-else-if' directive  vue/valid-v-else

✖ 1 problem (1 error, 0 warnings)

ERROR: "lint:eslint" exited with 1.
```

Move the `v-else` element directly below its `v-if` element.

---

## 7. Exercises

**Exercise 1:** `v-for` can also give you the position of each item: `v-for="(column, index) in columns"`. Use it in `App.vue` to number the columns, so their titles read `1. To Do`, `2. In Progress`, and `3. Done`. Do not change `board.js`.

**Exercise 2:** Add a fourth column to the `columns` array in `board.js`: status `"review"`, title `"Review"`. No card has this status. What does the new column show, and which lines of code made that happen? Remove the column afterward.

**Exercise 3:** Below the columns in `App.vue`, add an "All tasks" overview: an `<h3>` with the text `All tasks`, and a `<ul>` with one `<li>` per sample card in the format `Write project brief (todo)`.

---

## 8. Solutions

**Solution for Exercise 1:**

Change the `BoardColumn` tag in `src/App.vue`:

```vue
<BoardColumn
  v-for="(column, index) in columns"
  :key="column.status"
  :title="`${index + 1}. ${column.title}`"
  :cards="cardsFor(column.status)"
/>
```

`(column, index)` gives you the current item and its position, which starts at `0`. The title is built with a template literal inside the bound attribute, so `index + 1` turns positions `0`, `1`, `2` into the numbers `1`, `2`, `3`.

The column headers on the page:

```text
1. To Do (2) | 2. In Progress (2) | 3. Done (2)
```

Note that the key is still `column.status`, not `index`. The index is fine for display, but the key should identify the column itself. Undo the change before the next lesson.

**Solution for Exercise 2:**

Add one line to the `columns` array in `src/data/board.js`:

```javascript
export const columns = [
  { status: "todo", title: "To Do" },
  { status: "in-progress", title: "In Progress" },
  { status: "done", title: "Done" },
  { status: "review", title: "Review" },
];
```

The end of the page in the browser:

```text
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

Review (0)

No cards here yet.
```

A fourth lane appears because `v-for="column in columns"` in `App.vue` renders one `BoardColumn` per column object. `cardsFor("review")` returns an empty array, so the header reads `Review (0)`, and `<p v-if="cards.length === 0">` in `BoardColumn.vue` shows the empty message instead of the list. You did not touch any template. Remove the Review column again; Tasklane keeps the three classic columns.

**Solution for Exercise 3:**

Add the overview inside `<main>` in `src/App.vue`, after the columns:

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
    <BoardColumn
      v-for="column in columns"
      :key="column.status"
      :title="column.title"
      :cards="cardsFor(column.status)"
    />

    <h3>All tasks</h3>
    <ul>
      <li v-for="card in sampleCards" :key="card.id">{{ card.title }} ({{ card.status }})</li>
    </ul>
  </main>
</template>
```

`v-for` works on plain HTML elements as well as components. Here it repeats the `<li>` once per card, and the key is again the card's `id`.

The overview on the page:

```text
All tasks
Write project brief (todo)
Collect logo files (todo)
Design home page (in-progress)
Set up hosting (in-progress)
Pick color palette (done)
Write About page text (done)
```

Remove the overview before the next lesson.

---

## Next Up - Lesson 7

In this lesson you rendered lists with `v-for`, learned why every item needs a unique and stable `key`, and generated Tasklane's columns and cards entirely from data. You also showed and hid content with `v-if`, `v-else`, and `v-show`, grouped elements with `<template>`, and saw in the Elements panel how `v-if` removes elements while `v-show` only hides them.

In Lesson 7, Tasklane will finally look like a Kanban board. You will place the three columns side by side, style the cards, and use class and style bindings to color each card by priority, highlight overdue cards, and give each column its own accent color.
