## 1. Before You Begin

Module 2 gave Tasklane its look: a three-column board built from components, props, lists, and bindings. But so far the board is a picture. Nothing happens when you click it. In Module 3 you will make Tasklane interactive, and that starts with listening to what the user does.

In this lesson you will handle **events**, such as clicks, with Vue's `v-on` directive. You will add a "New card" button to the board, put "Back" and "Next" buttons on every card, and learn how a click inside a deeply nested component reaches the component that owns the data. That last part is the key idea of the lesson: data flows down through props, and **events flow up** through `defineEmits`. You will also use **event modifiers** to stop a button click from triggering the card it sits on.

### What You'll Build

A board with a "+ New card" button in the toolbar and "Back" and "Next" buttons on each card. Cards in To Do have no "Back" button, and cards in Done have no "Next" button. Clicking a card prints its id and title in the console. Clicking "Next" or "Back" sends an event from `TaskCard` through `BoardColumn` up to `App.vue`, which calculates where the card should go and prints it, for example `Move "Write project brief" from todo to in-progress`. The cards do not actually move yet; that is the job of Lesson 9.

### What You'll Learn

- ✅ How to listen to DOM events with `v-on:click` and its shorthand `@click`
- ✅ The difference between a method handler and an inline handler
- ✅ How to read props inside `<script setup>` with `const props = defineProps(...)`
- ✅ How to declare and send custom events with `defineEmits` and `emit`
- ✅ How to pass arguments with an event and pass an event up through several components
- ✅ How event modifiers such as `.stop` and `.prevent` work

### What You'll Need

- The Tasklane project from Lesson 7, with the development server running
- Your browser open at `http://localhost:5173`, with the developer tools console open (`Ctrl+Shift+J` on Windows and Linux, `Cmd+Option+J` on macOS)

---

## 2. Respond to a Click with v-on

In Lesson 1 you saw `@click="count++"` in the Vue counter. `@click` is the shorthand for `v-on:click`, the directive that listens to the `click` event of an element. The value can be a piece of code to run, or the name of a function to call.

### Step 1: Add Global Button Styles

Tasklane will have several buttons, and they should all look alike. Open `src/assets/main.css` and add these rules below the `body` rule.

```css
button {
  padding: 6px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  background-color: #ffffff;
  color: #1f2937;
  font: inherit;
  font-size: 14px;
  cursor: pointer;
}

button:hover {
  background-color: #f3f4f6;
}

button.primary {
  border-color: #4f46e5;
  background-color: #4f46e5;
  color: #ffffff;
}

button.primary:hover {
  background-color: #4338ca;
}
```

Here is what the rules do:

- `button` gives every button a white background, a thin grey border, rounded corners, and the same font as the rest of the page (`font: inherit;`). `cursor: pointer;` shows the hand cursor that tells users the element is clickable.
- `button:hover` darkens the background slightly when the mouse is over a button.
- `button.primary` is for the main action of a screen, such as creating a card: an indigo button with white text.

These are global styles because every component uses buttons. Save the file.

### Step 2: Add the New Card Button

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

function handleNewCard() {
  console.log("New card button clicked");
}
</script>

<template>
  <AppHeader />

  <main>
    <div class="toolbar">
      <h2>{{ boardName }}</h2>
      <button type="button" class="primary" @click="handleNewCard">+ New card</button>
    </div>
    <div class="board">
      <BoardColumn
        v-for="column in columns"
        :key="column.status"
        :title="column.title"
        :color="column.color"
        :cards="cardsFor(column.status)"
      />
    </div>
  </main>
</template>

<style scoped>
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

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

Here is what is new:

- `function handleNewCard()` is the **event handler**: the function that runs when the event happens. For now it only prints a message. In Lesson 10 it will open a form.
- `<button type="button" class="primary" @click="handleNewCard">` listens to clicks and calls `handleNewCard`. Write the function name without parentheses; Vue calls it for you. `type="button"` tells the browser this button does not submit a form, a good habit for every button that is not a submit button.
- `<div class="toolbar">` puts the board name and the button on one line. `display: flex;` places them side by side, and `justify-content: space-between;` pushes them to opposite ends.

Save the file and click "+ New card" twice.

Output in the console:

```text
New card button clicked
New card button clicked
```

The handler ran once per click.

---

## 3. Send Events from a Child to Its Parent

The "Next" and "Back" buttons belong on each card, so they live in `TaskCard`. But `TaskCard` cannot move a card. The cards are data owned by `App.vue`, and Lesson 5 taught you that a child must never change its parent's data. Instead, the child tells the parent what happened, and the parent decides what to do. In Vue, the child **emits** a custom event, and the parent listens to it with `@`, just like it listens to `click`.

### Step 1: Emit a move Event from TaskCard

Replace the `<script setup>` and `<template>` blocks of `src/components/TaskCard.vue` with this code. Keep the existing `<style scoped>` block from Lesson 7 below the template, and add two new rules to it, shown after the explanation.

```vue
<script setup>
import { isOverdue } from "../utils/dates.js";

defineProps({
  card: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["move"]);
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
    <div class="actions">
      <button
        v-if="card.status !== 'todo'"
        type="button"
        @click="emit('move', card.id, 'back')"
      >
        &larr; Back
      </button>
      <button
        v-if="card.status !== 'done'"
        type="button"
        @click="emit('move', card.id, 'next')"
      >
        Next &rarr;
      </button>
    </div>
  </article>
</template>
```

Here is what is new:

- `const emit = defineEmits(["move"]);` declares that this component can emit an event named `move`, and returns the `emit` function. Like `defineProps`, `defineEmits` is a compiler macro that needs no import. Declaring events documents the component, the same way declaring props does.
- `<div class="actions">` holds the two buttons.
- `v-if="card.status !== 'todo'"` hides "Back" for cards in the first column, and `v-if="card.status !== 'done'"` hides "Next" for cards in the last column.
- `@click="emit('move', card.id, 'back')"` is an **inline handler**: a piece of code instead of a function name. It emits the `move` event with two extra values, the card's id and the direction. The parent receives these values as arguments.
- `&larr;` and `&rarr;` are HTML entities for the arrows ← and →.
- Each button has its attributes on separate lines, because the tag is long. This is the same formatting you used for `BoardColumn` in `App.vue`.

Add these two rules to the `<style scoped>` block, after `.badge-high`:

```css
.actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.actions button {
  padding: 2px 8px;
  font-size: 12px;
}
```

They place the buttons in a row and make them smaller than the toolbar button. Save the file. Clicking the buttons does nothing visible yet, because nobody is listening to the `move` event.

### Step 2: Pass the Event Up Through BoardColumn

`App.vue` does not use `TaskCard` directly; `BoardColumn` does. So the event has to travel two steps: from `TaskCard` to `BoardColumn`, and from `BoardColumn` to `App.vue`. Replace the `<script setup>` and `<template>` blocks of `src/components/BoardColumn.vue` with this code, and keep its `<style scoped>` block.

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

const emit = defineEmits(["move"]);
</script>

<template>
  <section class="column" :style="{ borderTopColor: color }">
    <h3>{{ title }} ({{ cards.length }})</h3>
    <p v-if="cards.length === 0" class="empty">No cards here yet.</p>
    <template v-else>
      <TaskCard
        v-for="card in cards"
        :key="card.id"
        :card="card"
        @move="(cardId, direction) => emit('move', cardId, direction)"
      />
    </template>
  </section>
</template>
```

Here is what is new:

- `const emit = defineEmits(["move"]);` declares that `BoardColumn` emits a `move` event too.
- `@move="(cardId, direction) => emit('move', cardId, direction)"` listens to the `move` event of each `TaskCard`. The arrow function receives the two values the card sent and emits a new `move` event from the column with the same values. The column does not need to understand the event; it only passes it on.

### Step 3: Handle the Event in App.vue

Now `App.vue` can listen to `move` on each column. Replace the `<script setup>` block and the `BoardColumn` tag in `src/App.vue`, keeping the rest of the file the same:

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";

function cardsFor(status) {
  return sampleCards.filter((card) => card.status === status);
}

function handleNewCard() {
  console.log("New card button clicked");
}

function moveCard(cardId, direction) {
  const card = sampleCards.find((card) => card.id === cardId);
  const statuses = columns.map((column) => column.status);
  const index = statuses.indexOf(card.status);
  const newStatus = direction === "next" ? statuses[index + 1] : statuses[index - 1];
  console.log(`Move "${card.title}" from ${card.status} to ${newStatus}`);
}
</script>

<template>
  <AppHeader />

  <main>
    <div class="toolbar">
      <h2>{{ boardName }}</h2>
      <button type="button" class="primary" @click="handleNewCard">+ New card</button>
    </div>
    <div class="board">
      <BoardColumn
        v-for="column in columns"
        :key="column.status"
        :title="column.title"
        :color="column.color"
        :cards="cardsFor(column.status)"
        @move="moveCard"
      />
    </div>
  </main>
</template>
```

Here is how `moveCard` works:

- `@move="moveCard"` calls `moveCard` whenever a column emits `move`. With a function name, Vue passes the event's values as arguments, so `moveCard` receives `cardId` and `direction`.
- `sampleCards.find(...)` looks up the card by its id.
- `columns.map((column) => column.status)` builds the list `["todo", "in-progress", "done"]` from the column data, so the order of the columns decides where "next" and "back" lead.
- `statuses.indexOf(card.status)` finds the position of the card's current column. "next" takes the following status, and "back" takes the previous one.
- `console.log(...)` prints the planned move. Actually changing `card.status` is the subject of Lesson 9.

Save all three files and look at the board. Cards in To Do show only "Next →", cards in In Progress show both buttons, and cards in Done show only "← Back". Now click "Next →" on "Write project brief", "← Back" and then "Next →" on "Design home page", and "← Back" on "Pick color palette".

Output in the console:

```text
Move "Write project brief" from todo to in-progress
Move "Design home page" from in-progress to todo
Move "Design home page" from in-progress to done
Move "Pick color palette" from done to in-progress
```

Every click traveled from the card, through its column, up to `App.vue`, and arrived with the right card id and direction. Notice that "Design home page" is still in progress after you clicked "Back", because the data has not changed. `App.vue` only printed what it would do.

---

## 4. Use Event Modifiers

Clicking a card itself should do something too. Later in the course, it will open the card's detail page. For now, it will print the card's id and title. But a card contains buttons, and a click on a button is also a click on the card around it. Event modifiers solve this kind of problem.

### Step 1: Make the Whole Card Clickable

Update the `<script setup>` block and the opening `<article>` tag of `src/components/TaskCard.vue`:

```vue
<script setup>
import { isOverdue } from "../utils/dates.js";

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["move"]);

function showDetails() {
  console.log(`Selected card ${props.card.id}: ${props.card.title}`);
}
</script>

<template>
  <article
    :id="`card-${card.id}`"
    :title="card.title"
    class="card"
    :class="{ overdue: isOverdue(card), done: card.status === 'done' }"
    @click="showDetails"
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
    <div class="actions">
      <button
        v-if="card.status !== 'todo'"
        type="button"
        @click="emit('move', card.id, 'back')"
      >
        &larr; Back
      </button>
      <button
        v-if="card.status !== 'done'"
        type="button"
        @click="emit('move', card.id, 'next')"
      >
        Next &rarr;
      </button>
    </div>
  </article>
</template>
```

Here is what changed:

- `const props = defineProps(...)` stores the props in a variable. In the template you can write `card` directly, but inside `<script setup>` functions you reach props through this object, as `props.card`.
- `function showDetails()` prints the card's id and title.
- `@click="showDetails"` on the `<article>` calls it when the card is clicked.

Save the file, click the title of "Collect logo files", and then click "Next →" on "Write project brief".

Output in the console:

```text
Selected card 2: Collect logo files
Move "Write project brief" from todo to in-progress
Selected card 1: Write project brief
```

The first click works as intended. The second click printed two lines: the move, and then "Selected card 1". The click started on the button, and then, like most DOM events, it **bubbled** up to every element around it, including the `<article>`, which ran its own click handler.

### Step 2: Stop the Click at the Button

The `.stop` modifier calls `event.stopPropagation()` for you, which stops the event from bubbling further. Add it to both buttons in `TaskCard.vue`:

```vue
<div class="actions">
  <button
    v-if="card.status !== 'todo'"
    type="button"
    @click.stop="emit('move', card.id, 'back')"
  >
    &larr; Back
  </button>
  <button
    v-if="card.status !== 'done'"
    type="button"
    @click.stop="emit('move', card.id, 'next')"
  >
    Next &rarr;
  </button>
</div>
```

The only change is `@click.stop` instead of `@click`. Save the file and repeat the three clicks: the title of card 2, "Next →" on card 1, and "← Back" on card 6.

Output in the console:

```text
Selected card 2: Collect logo files
Move "Write project brief" from todo to in-progress
Move "Write About page text" from done to in-progress
```

Each button click now does exactly one thing. Vue has several other modifiers; the most common are listed in Section 9.

---

## 5. Run and Test

Restart the development server, open `http://localhost:5173` and the console, and check the following:

1. "+ New card" sits on the right of the board name and prints `New card button clicked`.
2. To Do cards show only "Next →", In Progress cards show both buttons, and Done cards show only "← Back".
3. Each move button prints one `Move ...` line with the correct from and to columns, and nothing else.
4. Clicking anywhere else on a card prints `Selected card ...`.

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

These are the most common mistakes with events.

**Error 1: Forgetting `.stop` on a button inside a clickable element.**

```vue
<!-- Wrong -->
<button
  v-if="card.status !== 'done'"
  type="button"
  @click="emit('move', card.id, 'next')"
>

<!-- Correct -->
<button
  v-if="card.status !== 'done'"
  type="button"
  @click.stop="emit('move', card.id, 'next')"
>
```

With the wrong version, one click on "Next →" runs two handlers:

```text
Move "Write project brief" from todo to in-progress
Selected card 1: Write project brief
```

Once the card's click opens a detail page, this bug would move the card and immediately leave the board. Whenever a clickable element sits inside another clickable element, decide which one should handle the click and stop it there.

**Error 2: Listening to the wrong event name.**

Event names must match exactly. A parent can listen to an event that the child never emits, and Vue will not complain.

```vue
<!-- Wrong -->
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
  @moved="moveCard"
/>

<!-- Correct -->
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
  @move="moveCard"
/>
```

With the wrong version, clicking a card still prints `Selected card ...`, but the move buttons print nothing at all, and the console shows no warning. The column emits `move`, and nobody listens to it. When an event seems to disappear, compare the name in `defineEmits` and `emit(...)` with the name after `@` in the parent, letter by letter.

**Error 3: Calling `defineEmits` without keeping the result.**

`defineEmits` returns the `emit` function. If you do not store it, there is no `emit` to call.

```javascript
// Wrong
defineEmits(["move"]);

// Correct
const emit = defineEmits(["move"]);
```

The page renders normally, but clicking a move button shows this in the console:

```text
[Vue warn]: Unhandled error during execution of native event handler 
  at <TaskCard key=1 card= Object onMove=fn > 
  at <BoardColumn key="todo" title="To Do" color="#6366f1"  ... > 
  at <App>
TypeError: _ctx.emit is not a function
```

`_ctx.emit` is how the compiled template looks up `emit`. Because nothing named `emit` was declared, it is not a function. Add `const emit =` in front of `defineEmits`.

---

## 7. Exercises

**Exercise 1:** Add a second toolbar button, "Clear done", next to "+ New card". When clicked, it should print how many cards are in the Done column, in the format `There are 2 done cards to clear.` Wrap both buttons in a `<div>` so they stay together on the right.

**Exercise 2:** Make the card title respond to a double-click with the `dblclick` event. Double-clicking a title should print `Rename card <id>`, for example `Rename card 3`. Which other messages do you see in the console when you double-click, and why?

**Exercise 3:** Add a "Delete" button after "Next →" on every card. It should emit a `delete` event with the card's id, `BoardColumn` should pass it on, and `App.vue` should print `Delete "<title>"`, for example `Delete "Set up hosting"`. Clicking "Delete" must not print `Selected card ...`.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the function to `<script setup>` in `src/App.vue`:

```javascript
function clearDone() {
  const doneCount = sampleCards.filter((card) => card.status === "done").length;
  console.log(`There are ${doneCount} done cards to clear.`);
}
```

Then replace the single button in the toolbar with a group of two:

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <div>
    <button type="button" @click="clearDone">Clear done</button>
    <button type="button" class="primary" @click="handleNewCard">+ New card</button>
  </div>
</div>
```

The new `<div>` becomes the second child of the flex toolbar, so both buttons sit together on the right. Clicking "Clear done" prints:

```text
There are 2 done cards to clear.
```

The button uses the default style, not `primary`, because it is a secondary action.

**Solution for Exercise 2:**

Add a function to `<script setup>` in `src/components/TaskCard.vue`:

```javascript
function renameCard() {
  console.log(`Rename card ${props.card.id}`);
}
```

Then listen to `dblclick` on the title:

```vue
<h4 @dblclick="renameCard">{{ card.title }}</h4>
```

Double-clicking the title of "Design home page" prints:

```text
Rename card 3
```

In a real browser you also see `Selected card 3: Design home page` twice before it. A double-click is made of two clicks, and the browser fires a `click` event for each one before it fires `dblclick`. Both clicks bubble up to the `<article>`. This is why apps rarely put both a click action and a double-click action on the same element, and why Tasklane will use a normal "Edit" button for renaming in Lesson 11.

**Solution for Exercise 3:**

In `src/components/TaskCard.vue`, declare the new event and add the button after "Next →":

```javascript
const emit = defineEmits(["move", "delete"]);
```

```vue
<button type="button" @click.stop="emit('delete', card.id)">Delete</button>
```

In `src/components/BoardColumn.vue`, declare the event and pass it on:

```javascript
const emit = defineEmits(["move", "delete"]);
```

```vue
<TaskCard
  v-for="card in cards"
  :key="card.id"
  :card="card"
  @move="(cardId, direction) => emit('move', cardId, direction)"
  @delete="(cardId) => emit('delete', cardId)"
/>
```

In `src/App.vue`, add a handler and listen to the event:

```javascript
function deleteCard(cardId) {
  const card = sampleCards.find((card) => card.id === cardId);
  console.log(`Delete "${card.title}"`);
}
```

```vue
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
  @move="moveCard"
  @delete="deleteCard"
/>
```

Clicking "Delete" on "Set up hosting" prints:

```text
Delete "Set up hosting"
```

`.stop` keeps the card's own click handler from running. Every event name appears in three places, `defineEmits` and `emit` in the child, and `@delete` in the parent, so keep them identical. You will make Delete actually remove the card in Lesson 11. Undo these exercise changes before the next lesson, so your code matches Lesson 9.

---

## 9. How Events Flow in Vue

You now know both directions of communication between components:

```text
App.vue  (owns sampleCards)
  │  ▲
  │  │ emits "move" (cardId, direction)
props │
  ▼  │
BoardColumn
  │  ▲
  │  │ emits "move" (cardId, direction)
props │
  ▼  │
TaskCard  (has the buttons)
```

**Props go down, events go up.** A parent gives data to its children through props. A child tells its parent that something happened by emitting an event. The parent, which owns the data, decides how to react. This keeps every piece of data with exactly one owner, which makes bugs much easier to track down.

**Method handlers and inline handlers.** `@click="handleNewCard"` passes a function name, and Vue calls it with the event's values as arguments. `@click="emit('move', card.id, 'next')"` is inline code that runs as written. Both are common. Use a function name when the handler is more than one short expression.

**Common event modifiers.**

| Modifier | What it does |
| --- | --- |
| `.stop` | Stops the event from bubbling to parent elements (`event.stopPropagation()`) |
| `.prevent` | Cancels the browser's default action, such as reloading the page when a form is submitted (`event.preventDefault()`) |
| `.self` | Runs the handler only if the event started on this element itself, not on a child |
| `.once` | Runs the handler at most once |
| `.enter`, `.esc` | For keyboard events: `@keyup.enter` runs only when the Enter key is released |

You will use `.prevent` with forms in Lesson 10, and `.self` and `.esc` for a modal window in Lesson 14.

---

## Next Up - Lesson 9

In this lesson you made Tasklane respond to the user. You listened to clicks with `@click`, read props in `<script setup>` through `const props = defineProps(...)`, declared and emitted custom events with `defineEmits`, passed an event with arguments up from `TaskCard` through `BoardColumn` to `App.vue`, and stopped clicks from bubbling with `.stop`.

But the cards still do not move. `App.vue` knows exactly where each card should go, and yet changing `card.status` in plain JavaScript would not update the page. In Lesson 9, you will learn why, and fix it with Vue's reactivity system: `ref` and `reactive`. Then clicking "Next →" will finally move a card to the next column.
