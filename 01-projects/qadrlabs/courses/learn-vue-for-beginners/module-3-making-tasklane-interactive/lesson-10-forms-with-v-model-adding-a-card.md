## 1. Before You Begin

In Lesson 9, Tasklane's cards became reactive state, and the "Back" and "Next" buttons started moving them between columns. But the board can only ever show the six sample cards. A task board you cannot add tasks to is not much use, and the "+ New card" button in the toolbar still only prints a message.

In this lesson you will build the form that creates new cards. You will meet `v-model`, Vue's directive for **two-way binding**: it keeps a form input and a piece of reactive state in sync, in both directions, without any event handling code. You will bind text inputs, a textarea, selects, and a date input, handle the form's submission with `@submit.prevent`, validate what the user typed, and add the new card to the board.

### What You'll Build

A "New card" form that opens when you click "+ New card". It has a title input with a live character counter, a description textarea, a column select, a priority select, and a due date picker. Submitting an empty title shows "Please enter a title." Submitting a valid card adds it to the right column, closes the form, and gives the card a new unique id. A "Cancel" button closes the form without adding anything.

### What You'll Learn

- ✅ What two-way binding is and how `v-model` works on text inputs, textareas, selects, and date inputs
- ✅ How to keep form fields together in a `reactive` object
- ✅ How to use the `.trim` modifier to clean up user input
- ✅ How to handle a form submission with `@submit.prevent`
- ✅ How to validate input and show an error message
- ✅ How to add a new item to a reactive array and generate a unique id
- ✅ How to show and hide a component with a boolean ref

### What You'll Need

- The Tasklane project from Lesson 9, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Build the CardForm Component

The form has many fields and its own logic, so it gets its own component. `App.vue` will only decide when to show it and what to do with the result.

### Step 1: Bind the Fields with v-model

Create `src/components/CardForm.vue` with this code.

```vue
<script setup>
import { reactive } from "vue";
import { columns } from "../data/board.js";

const form = reactive({
  title: "",
  description: "",
  status: "todo",
  priority: "medium",
  dueDate: "",
});
</script>

<template>
  <form class="card-form">
    <h3>New card</h3>

    <label>
      Title
      <input v-model.trim="form.title" type="text" placeholder="What needs to be done?" />
    </label>

    <label>
      Description
      <textarea v-model.trim="form.description" rows="3"></textarea>
    </label>

    <div class="row">
      <label>
        Column
        <select v-model="form.status">
          <option v-for="column in columns" :key="column.status" :value="column.status">
            {{ column.title }}
          </option>
        </select>
      </label>

      <label>
        Priority
        <select v-model="form.priority">
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>
      </label>

      <label>
        Due date
        <input v-model="form.dueDate" type="date" />
      </label>
    </div>

    <pre>{{ form }}</pre>
  </form>
</template>
```

Here is what the code does:

- `const form = reactive({ ... })` keeps all five fields of a new card together in one reactive object. Every field starts with a sensible default: empty text, the To Do column, and medium priority. This is a typical use of `reactive`: a group of values that always travel together.
- `v-model="form.status"` on a `<select>` connects the selected option to `form.status`. When the user picks an option, `form.status` changes; when `form.status` changes in code, the select shows the matching option.
- `v-model.trim="form.title"` does the same for the text input, and the `.trim` modifier removes spaces at the start and end of what the user typed. The textarea uses it too.
- `v-model="form.dueDate"` on `<input type="date">` stores the chosen date as text in the `YYYY-MM-DD` format, exactly the format Tasklane's cards use. If no date is chosen, the value is an empty string.
- The column options are generated with `v-for` from the `columns` data, and each option's `:value` is the column's status. The priority options are written by hand, because the three priorities are fixed.
- Each input sits inside its `<label>`. Wrapping an input in a label connects the two, so clicking the label text focuses the input, and screen readers announce the label.
- `<pre>{{ form }}</pre>` is a temporary debugging aid. When you interpolate an object, Vue displays it as formatted JSON, so you can watch the form's state change while you type.

### Step 2: Show the Form in App.vue

To see the form, `App.vue` needs to render it. Open `src/App.vue`, import the component, and render it right after the toolbar. Change only these two parts:

```javascript
import CardForm from "./components/CardForm.vue";
```

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <button type="button" class="primary" @click="handleNewCard">+ New card</button>
</div>
<CardForm />
```

The import goes next to the other component imports. Save both files. The form appears above the board, without styles for now, followed by the debugging output.

The debugging output before you type anything:

```text
{
  "title": "",
  "description": "",
  "status": "todo",
  "priority": "medium",
  "dueDate": ""
}
```

The select boxes already show "To Do" and "Medium", because `v-model` set them from the initial state. Now type `Write SEO checklist` into the title, choose "High" as the priority, and pick November 10, 2026 as the due date.

The debugging output after typing:

```text
{
  "title": "Write SEO checklist",
  "description": "",
  "status": "todo",
  "priority": "high",
  "dueDate": "2026-11-10"
}
```

Every keystroke and every selection updated the reactive object immediately. You did not write a single event handler. That is two-way binding: the state flows into the input, and the input flows back into the state.

---

## 3. Submit, Validate, and Add the Card

The form can collect data, but it cannot send it anywhere yet. In this section you will finish `CardForm`: handle the submission, check the input, and emit the new card to `App.vue`, which will add it to the board.

### Step 1: Handle the Submission in CardForm

Replace the contents of `src/components/CardForm.vue` with the complete component.

```vue
<script setup>
import { reactive, ref } from "vue";
import { columns } from "../data/board.js";

const emit = defineEmits(["save", "cancel"]);

const form = reactive({
  title: "",
  description: "",
  status: "todo",
  priority: "medium",
  dueDate: "",
});
const error = ref("");

function resetForm() {
  form.title = "";
  form.description = "";
  form.status = "todo";
  form.priority = "medium";
  form.dueDate = "";
}

function handleSubmit() {
  if (form.title === "") {
    error.value = "Please enter a title.";
    return;
  }

  if (form.title.length > 60) {
    error.value = "The title can be at most 60 characters long.";
    return;
  }

  error.value = "";
  emit("save", { ...form });
  resetForm();
}
</script>

<template>
  <form class="card-form" @submit.prevent="handleSubmit">
    <h3>New card</h3>

    <label>
      Title
      <input v-model.trim="form.title" type="text" placeholder="What needs to be done?" />
      <small>{{ form.title.length }}/60 characters</small>
    </label>

    <label>
      Description
      <textarea v-model.trim="form.description" rows="3"></textarea>
    </label>

    <div class="row">
      <label>
        Column
        <select v-model="form.status">
          <option v-for="column in columns" :key="column.status" :value="column.status">
            {{ column.title }}
          </option>
        </select>
      </label>

      <label>
        Priority
        <select v-model="form.priority">
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>
      </label>

      <label>
        Due date
        <input v-model="form.dueDate" type="date" />
      </label>
    </div>

    <p v-if="error !== ''" class="error">{{ error }}</p>

    <div class="buttons">
      <button type="button" @click="emit('cancel')">Cancel</button>
      <button type="submit" class="primary">Add card</button>
    </div>
  </form>
</template>

<style scoped>
.card-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 560px;
  margin-bottom: 16px;
  padding: 16px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

h3 {
  margin: 0;
}

label {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 14px;
  font-weight: 600;
}

input,
textarea,
select {
  padding: 6px 8px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font: inherit;
  font-weight: 400;
}

small {
  font-weight: 400;
  color: #6b7280;
}

.row {
  display: flex;
  gap: 12px;
}

.row label {
  flex: 1;
}

.error {
  margin: 0;
  font-size: 14px;
  color: #dc2626;
}

.buttons {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
```

Take it in parts. In the script:

- `defineEmits(["save", "cancel"])` declares two events. `save` carries the new card's data, and `cancel` tells the parent the user gave up.
- `const error = ref("");` holds the current validation message, or an empty string when there is none.
- `resetForm()` puts every field back to its default value.
- `handleSubmit()` validates first. An empty title or a title longer than 60 characters sets `error.value` and stops with `return`. Because the title input uses `.trim`, a title of only spaces arrives as an empty string and is rejected too.
- When the input is valid, `emit("save", { ...form })` sends a **copy** of the form data. The spread syntax `{ ...form }` creates a new plain object with the same five properties. The form keeps its own object, and the parent gets one it can safely store.
- `resetForm()` then clears the fields, ready for the next card.

In the template:

- `<form @submit.prevent="handleSubmit">` listens to the form's `submit` event, which fires when the user clicks a submit button or presses Enter in a text input. The `.prevent` modifier stops the browser's default behavior, which is to reload the page with the form data in the address. A single-page app must never let that happen.
- `<small>{{ form.title.length }}/60 characters</small>` is a live counter. It reads the same reactive state that `v-model` writes, so it updates on every keystroke.
- `<p v-if="error !== ''" class="error">` shows the validation message only when there is one.
- The "Cancel" button has `type="button"`, so it does not submit the form. It emits `cancel` instead. The "Add card" button has `type="submit"`, so clicking it submits the form.
- The `<pre>` debugging output is gone.

The styles stack the fields vertically with `flex-direction: column`, put the three short fields side by side in `.row`, and align the buttons to the right.

### Step 2: Show, Hide, and Handle the Form in App.vue

`App.vue` decides when the form is visible and what happens to a saved card. Replace the `<script setup>` block of `src/App.vue` with this code:

```vue
<script setup>
import { reactive, ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);
const lastMove = reactive({
  title: "",
  from: "",
  to: "",
});
const showForm = ref(false);

function cardsFor(status) {
  return cards.value.filter((card) => card.status === status);
}

function handleNewCard() {
  showForm.value = true;
}

function nextId() {
  const ids = cards.value.map((card) => card.id);
  return Math.max(0, ...ids) + 1;
}

function addCard(newCard) {
  cards.value.push({ id: nextId(), ...newCard });
  showForm.value = false;
}

function columnTitle(status) {
  return columns.find((column) => column.status === status).title;
}

function moveCard(cardId, direction) {
  const card = cards.value.find((card) => card.id === cardId);
  const statuses = columns.map((column) => column.status);
  const index = statuses.indexOf(card.status);
  const newStatus = direction === "next" ? statuses[index + 1] : statuses[index - 1];

  lastMove.title = card.title;
  lastMove.from = columnTitle(card.status);
  lastMove.to = columnTitle(newStatus);
  card.status = newStatus;
}
</script>
```

Then change the `<CardForm />` line in the template to:

```vue
<CardForm v-if="showForm" @save="addCard" @cancel="showForm = false" />
```

Here is what is new:

- `const showForm = ref(false);` remembers whether the form is open. It starts closed.
- `handleNewCard()` no longer prints a message; it opens the form by setting `showForm.value = true`.
- `nextId()` finds the highest id among the current cards and adds one. `Math.max(0, ...ids)` spreads the ids into `Math.max`, and the extra `0` makes it work even when there are no cards at all. With the six sample cards, the first new card gets the id `7`.
- `addCard(newCard)` receives the data from the `save` event, builds a complete card with `{ id: nextId(), ...newCard }`, adds it to the array with `push`, and closes the form. `push` changes the array inside a ref, and Vue tracks that like any other change.
- `<CardForm v-if="showForm" ...>` renders the form only while `showForm` is true. Because it uses `v-if`, closing the form removes the component completely, and opening it again creates a fresh one with empty fields.
- `@cancel="showForm = false"` closes the form when the user clicks "Cancel".

Save both files. Click "+ New card". The form opens above the board.

The text of the form:

```text
New card
Title
Description
Column
To Do
In Progress
Done
Priority
Low
Medium
High
Due date
Cancel
Add card
```

The form shows each label, the options of both selects, and the two buttons. On the screen it is a white panel with the title field and the description on top, and the column, priority, and due date side by side.

---

## 4. Run and Test

Test the whole flow, including the cases where the user makes mistakes. Restart the development server and open `http://localhost:5173`.

First, open the form and click "Add card" without typing anything. The form stays open and shows:

```text
Please enter a title.
```

The address in the browser stays `http://localhost:5173/`, which proves that `.prevent` stopped the page from reloading.

Next, type a title that is too long, such as `Write a very long title that keeps going and going until it is far too long`, and click "Add card".

The error message and the counter under the title:

```text
The title can be at most 60 characters long. | 75/60 characters
```

Now replace the title with `Write SEO checklist` and click "Add card" again. The form closes, and the new card appears at the bottom of the To Do column.

The column headers and the To Do column:

```text
To Do (3) | In Progress (2) | Done (2)
```

The To Do column, from top to bottom:

```text
To Do (3)
HIGH
Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

Next →
LOW
Collect logo files

Ask the client for SVG versions of the logo.

No due date

Next →
MEDIUM
Write SEO checklist

No due date

Next →
```

The new card has the default priority, medium, and no due date. Try one more card with every field filled in: title `Write SEO checklist`, description `List the pages that need titles and descriptions.`, priority High, and due date November 10, 2026, with some extra spaces typed before and after the title. After a page refresh to reset the board, the new card in the Elements panel looks like this:

```html
<article data-v-bdaa6335="" data-v-05cf9fb1="" id="card-7" title="Write SEO checklist" class="card"><span data-v-bdaa6335="" class="badge badge-high">high</span><h4 data-v-bdaa6335="">Write SEO checklist</h4><p data-v-bdaa6335="" class="description">List the pages that need titles and descriptions.</p><p data-v-bdaa6335="" class="due"> Due <time data-v-bdaa6335="" datetime="2026-11-10">2026-11-10</time><!--v-if--></p><p data-v-bdaa6335="" class="completed" style="display: none;">Completed</p><div data-v-bdaa6335="" class="actions"><!--v-if--><button data-v-bdaa6335="" type="button"> Next → </button></div></article>
```

It has the id `card-7`, the high priority badge, the description, and the due date, and its title has no extra spaces thanks to `.trim`. Finally, open the form and click "Cancel": the form closes and nothing is added.

The new card behaves like any other: its "Next →" button moves it, and it counts toward its column. Refresh the page, and it disappears, because the board still starts from `sampleCards`; Lesson 13 fixes that.

Run the linters too.

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

## 5. Fix the Errors in Your Code

These are the most common mistakes with forms.

**Error 1: Forgetting `.prevent` on the submit event.**

```vue
<!-- Wrong -->
<form class="card-form" @submit="handleSubmit">

<!-- Correct -->
<form class="card-form" @submit.prevent="handleSubmit">
```

With the wrong version, typing a title and clicking "Add card" seems to do nothing useful: the page flashes, and the board shows its original six cards. After the click, the address and the column headers are:

```text
URL: http://localhost:5199/? | FORM: false
To Do (2) | In Progress (2) | Done (2)
```

The test server ran on port 5199; on your computer the address is `http://localhost:5173/?`. The form is gone (`FORM: false`), and the browser submitted the form the old-fashioned way and reloaded the page, with a `?` added to the address. The reload wiped out Vue's state, including the card you just added. In a single-page app, every form needs `@submit.prevent`.

**Error 2: Forgetting the `.trim` modifier.**

```vue
<!-- Wrong -->
<input v-model="form.title" type="text" placeholder="What needs to be done?" />

<!-- Correct -->
<input v-model.trim="form.title" type="text" placeholder="What needs to be done?" />
```

With the wrong version, typing only three spaces and clicking "Add card" passes the validation, because `"   "` is not an empty string. A card with an invisible title appears in To Do. Its heading in the Elements panel:

```html
<h4 data-v-bdaa6335="">   </h4>
```

With `.trim`, the same input becomes `""`, and the form shows "Please enter a title." Users type stray spaces all the time, especially on phones, so trim text fields that should not start or end with spaces.

**Error 3: Using `:value` instead of `v-model`.**

`:value` binds in one direction only: from the state into the input.

```vue
<!-- Wrong -->
<input :value="form.title" type="text" placeholder="What needs to be done?" />

<!-- Correct -->
<input v-model.trim="form.title" type="text" placeholder="What needs to be done?" />
```

With the wrong version, you can type `Write SEO checklist` into the field, but clicking "Add card" still shows:

```text
Please enter a title.
```

The text is visible in the input, but `form.title` never changed, because nothing copies the input's value back into the state. `v-model` does both directions: it is a shortcut for `:value` plus an `@input` handler that writes the new value into the state.

---

## 6. Exercises

**Exercise 1:** A high-priority task without a deadline is easy to forget. Add a validation rule to `handleSubmit`: when the priority is `"high"` and the due date is empty, show `High priority cards need a due date.` and do not add the card.

**Exercise 2:** Disable the "Add card" button while the title is empty, with a bound `disabled` attribute, and add a CSS rule that makes disabled buttons look faded and shows a "not allowed" cursor.

**Exercise 3:** Show a live preview of the card inside the form, above the buttons. Reuse `TaskCard` and pass it an object made from the form data with a temporary id of `0`. Add a small "Preview" label above it.

---

## 7. Solutions

**Solution for Exercise 1:**

Add a third check to `handleSubmit` in `src/components/CardForm.vue`, after the length check:

```javascript
function handleSubmit() {
  if (form.title === "") {
    error.value = "Please enter a title.";
    return;
  }

  if (form.title.length > 60) {
    error.value = "The title can be at most 60 characters long.";
    return;
  }

  if (form.priority === "high" && form.dueDate === "") {
    error.value = "High priority cards need a due date.";
    return;
  }

  error.value = "";
  emit("save", { ...form });
  resetForm();
}
```

With the title `Write SEO checklist`, priority High, and no date, clicking "Add card" shows:

```text
High priority cards need a due date.
```

After choosing a date and clicking "Add card" again, the form closes and the To Do column shows `To Do (3)`. Validation rules can combine several fields; they are ordinary `if` statements.

**Solution for Exercise 2:**

Bind `disabled` on the submit button:

```vue
<button type="submit" class="primary" :disabled="form.title === ''">Add card</button>
```

And add this rule to the style block of `CardForm.vue`:

```css
button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

`:disabled` is a boolean attribute: Vue adds it when the expression is true and removes it when it is false. When the form opens, the button's `disabled` property is `true`. After typing `Write SEO checklist`, it becomes `false`. Keep the "Please enter a title." check in `handleSubmit` anyway: users can still submit by pressing Enter in some browsers, and validation in the handler is the reliable safety net.

**Solution for Exercise 3:**

Import `TaskCard` in `src/components/CardForm.vue`:

```javascript
import TaskCard from "./TaskCard.vue";
```

Add the preview before the buttons:

```vue
<p class="preview-label">Preview</p>
<TaskCard :card="{ id: 0, ...form }" />
```

And a rule for the label:

```css
.preview-label {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
}
```

`{ id: 0, ...form }` builds a card-shaped object from the form's current values on every render. Because `form` is reactive, the preview updates as you type. When the form opens, the preview shows:

```text
MEDIUM

No due date

Next →
```

After typing `Write SEO checklist` and choosing High, it shows:

```text
HIGH
Write SEO checklist

No due date

Next →
```

Reusing `TaskCard` guarantees the preview looks exactly like the real card. Its buttons do nothing here, because the form does not listen to the card's events. Undo these exercise changes before the next lesson, so your code matches Lesson 11.

---

## 8. How v-model Works

`v-model` looks like magic, but it is a shortcut for two things you already know. On a text input, this:

```vue
<input v-model="form.title" />
```

does the same as this:

```vue
<input :value="form.title" @input="form.title = $event.target.value" />
```

`:value` puts the state into the input, and the `input` event writes every change back. `$event` is the native DOM event, and `$event.target.value` is the text in the input. For other elements, `v-model` uses the matching property and event: `checked` and `change` for checkboxes, `value` and `change` for selects.

The three `v-model` modifiers are:

| Modifier | What it does |
| --- | --- |
| `.trim` | Removes spaces at the start and end of the text |
| `.number` | Converts the text to a number when possible, useful for `type="number"` inputs |
| `.lazy` | Updates the state on `change` (when the field loses focus) instead of on every keystroke |

One rule matters a lot for the next lesson: `v-model` writes to whatever you give it. Give it local state, such as `form.title`, never a prop. Props belong to the parent, as you learned in Lesson 5. In Lesson 11 you will reuse this form for editing existing cards, and you will see how to copy a prop into local state first.

---

## Next Up - Lesson 11

In this lesson you built Tasklane's card form. You bound inputs, a textarea, selects, and a date picker with `v-model`, trimmed text with `.trim`, handled the submission with `@submit.prevent`, validated the input, emitted a copy of the form data, and added new cards to the reactive array with a generated id. "+ New card" now does exactly what it says.

In Lesson 11, you will complete the card's life cycle. You will delete cards, edit existing cards by reusing `CardForm` with an initial card passed as a prop, and clean up how cards move between columns, all while keeping `App.vue` as the single source of truth for the board.
