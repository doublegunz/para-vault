## 1. Before You Begin

In Lesson 10, the "+ New card" button opened a form that added real cards to the board. Tasklane can now create cards and move them, but a card that has a typo cannot be fixed, and a task that is no longer needed cannot be removed. Every card on a real Kanban board goes through a full life cycle: created, moved, changed, and eventually removed.

In this lesson you will complete that life cycle. You will add "Edit" and "Delete" buttons to every card, delete cards by replacing the reactive array with a filtered copy, and edit cards by reusing `CardForm` with the card passed in as a prop. Along the way you will tidy up `App.vue` so that one status line reports every action, and you will learn why `App.vue` must stay the single place that changes the board's data.

### What You'll Build

Every card gets four possible buttons: "← Back", "Next →", "Edit", and "Delete". "Delete" removes the card immediately. "Edit" opens the form titled "Edit card", already filled in with the card's data and a "Save changes" button. Saving updates the card in place; "Cancel" leaves it untouched. A status line above the board reports the last action, such as `Deleted "Set up hosting".`, `Updated "Design home and about pages".`, or `Added "Write SEO checklist" to To Do.`

### What You'll Learn

- ✅ How to remove an item from a reactive array with `filter`
- ✅ How to update an existing object with `Object.assign`
- ✅ How to reuse one form component for both creating and editing
- ✅ How to copy a prop into local state, and why `v-model` must never bind to a prop
- ✅ How the `key` attribute can force Vue to create a fresh component
- ✅ What "single source of truth" means and how it keeps your app predictable

### What You'll Need

- The Tasklane project from Lesson 10, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Add Edit and Delete Buttons to the Cards

The new buttons follow exactly the pattern of "Back" and "Next" from Lesson 8: `TaskCard` emits an event, `BoardColumn` passes it on, and `App.vue` decides what to do.

### Step 1: Emit edit and delete from TaskCard

In `src/components/TaskCard.vue`, update the `defineEmits` line in `<script setup>`:

```javascript
const emit = defineEmits(["move", "edit", "delete"]);
```

Then replace the `<template>` block with this version, which adds two buttons at the end of the actions row:

```vue
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
      <button type="button" @click.stop="emit('edit', card.id)">Edit</button>
      <button type="button" class="danger" @click.stop="emit('delete', card.id)">Delete</button>
    </div>
  </article>
</template>
```

Both new buttons emit an event with the card's id and use `.stop`, so they do not also trigger the card's own click handler. The "Delete" button has the class `danger`. Add this rule to the style block, after `.actions button`:

```css
.actions .danger {
  margin-left: auto;
  color: #b91c1c;
}
```

`margin-left: auto;` pushes the "Delete" button to the far right of the row, away from the other buttons, so it is harder to click by accident. The red text marks it as a destructive action.

### Step 2: Pass the Events Up Through BoardColumn

In `src/components/BoardColumn.vue`, update `defineEmits`:

```javascript
const emit = defineEmits(["move", "edit", "delete"]);
```

And forward the two new events from each card:

```vue
<TaskCard
  v-for="card in cards"
  :key="card.id"
  :card="card"
  @move="(cardId, direction) => emit('move', cardId, direction)"
  @edit="(cardId) => emit('edit', cardId)"
  @delete="(cardId) => emit('delete', cardId)"
/>
```

Save both files. Each card now shows "Edit" and "Delete" next to its move buttons; the In Progress cards, for example, show:

```text
← Back / Next → / Edit / Delete
```

Clicking the new buttons does nothing yet, because `App.vue` is not listening.

---

## 3. Delete, Edit, and Report Every Action in App.vue

`App.vue` now needs four actions on its data: add, edit, delete, and move. This is a good moment to reorganize it. The `lastMove` object from Lesson 9 only describes moves, so it becomes a general `message` that every action can update.

### Step 1: Rewrite App.vue

Replace the contents of `src/App.vue` with this code.

```vue
<script setup>
import { ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);

function cardsFor(status) {
  return cards.value.filter((card) => card.status === status);
}

function findCard(cardId) {
  return cards.value.find((card) => card.id === cardId);
}

function columnTitle(status) {
  return columns.find((column) => column.status === status).title;
}

function nextId() {
  const ids = cards.value.map((card) => card.id);
  return Math.max(0, ...ids) + 1;
}

function openNewForm() {
  editingCard.value = null;
  showForm.value = true;
}

function openEditForm(cardId) {
  editingCard.value = findCard(cardId);
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  editingCard.value = null;
}

function saveCard(cardData) {
  if (editingCard.value === null) {
    cards.value.push({ id: nextId(), ...cardData });
    message.value = `Added "${cardData.title}" to ${columnTitle(cardData.status)}.`;
  } else {
    Object.assign(editingCard.value, cardData);
    message.value = `Updated "${cardData.title}".`;
  }
  closeForm();
}

function deleteCard(cardId) {
  const card = findCard(cardId);
  cards.value = cards.value.filter((card) => card.id !== cardId);
  message.value = `Deleted "${card.title}".`;
}

function moveCard(cardId, direction) {
  const card = findCard(cardId);
  const statuses = columns.map((column) => column.status);
  const index = statuses.indexOf(card.status);
  const newStatus = direction === "next" ? statuses[index + 1] : statuses[index - 1];

  const from = columnTitle(card.status);
  const to = columnTitle(newStatus);
  message.value = `Moved "${card.title}" from ${from} to ${to}.`;
  card.status = newStatus;
}
</script>

<template>
  <AppHeader />

  <main>
    <div class="toolbar">
      <h2>{{ boardName }}</h2>
      <button type="button" class="primary" @click="openNewForm">+ New card</button>
    </div>
    <CardForm
      v-if="showForm"
      :key="editingCard ? editingCard.id : 'new'"
      :card="editingCard"
      @save="saveCard"
      @cancel="closeForm"
    />
    <p class="status">{{ message }}</p>
    <div class="board">
      <BoardColumn
        v-for="column in columns"
        :key="column.status"
        :title="column.title"
        :color="column.color"
        :cards="cardsFor(column.status)"
        @move="moveCard"
        @edit="openEditForm"
        @delete="deleteCard"
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

.status {
  margin: 0 0 16px;
  font-size: 14px;
  color: #4b5563;
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

There is a lot here, so go through it state by state and action by action.

The state:

- `cards` is unchanged: the reactive array of cards.
- `message` replaces `lastMove`. It is a single string that every action overwrites, so `reactive` is no longer needed in this file.
- `showForm` controls whether the form is visible, as in Lesson 10.
- `editingCard` holds the card being edited, or `null` when the form creates a new card.

The helpers:

- `findCard(cardId)` looks up a card by id. Four functions need it, so it gets its own function instead of repeating the same `find` call.
- `columnTitle` and `nextId` are the same as before.

The actions:

- `openNewForm()` clears `editingCard` and opens the form. The "+ New card" button calls it.
- `openEditForm(cardId)` stores the card to edit and opens the form. It runs when a column emits `edit`.
- `closeForm()` hides the form and forgets the edited card. Both a successful save and "Cancel" use it.
- `saveCard(cardData)` handles both cases. When `editingCard.value` is `null`, it adds a new card exactly as `addCard` did in Lesson 10. Otherwise it updates the existing card: `Object.assign(editingCard.value, cardData)` copies every property of `cardData` onto the card object, so its title, description, status, priority, and due date all change while its `id` stays the same. Because the card lives inside the reactive `cards` array, Vue sees each of these changes.
- `deleteCard(cardId)` removes a card. `cards.value.filter((card) => card.id !== cardId)` builds a new array with every card except the deleted one, and assigning it to `cards.value` replaces the old array. Replacing the whole value of a ref is fully reactive. The function looks the card up first, so the message can still mention its title after it is gone.
- `moveCard` works as before, but writes to `message` instead of `lastMove`. The two column titles are stored in `from` and `to` first, which keeps the template literal short.

In the template:

- The status paragraph shrinks to `<p class="status">{{ message }}</p>`.
- `@edit="openEditForm"` and `@delete="deleteCard"` connect the new events.
- `<CardForm>` receives the card to edit through `:card="editingCard"` and reports through `@save="saveCard"` and `@cancel="closeForm"`.
- `:key="editingCard ? editingCard.id : 'new'"` gives the form a key that changes whenever it switches to a different card. You will see why it matters in Section 5.

### Step 2: Fill the Form from the card Prop

`CardForm` must now accept an optional card and start with its values. Replace the `<script setup>` block of `src/components/CardForm.vue` with this code.

```vue
<script setup>
import { reactive, ref } from "vue";
import { columns } from "../data/board.js";

const props = defineProps({
  card: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(["save", "cancel"]);

const isEditing = props.card !== null;
const form = reactive({
  title: isEditing ? props.card.title : "",
  description: isEditing ? props.card.description : "",
  status: isEditing ? props.card.status : "todo",
  priority: isEditing ? props.card.priority : "medium",
  dueDate: isEditing ? props.card.dueDate : "",
});
const error = ref("");

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
}
</script>
```

Then change two lines in the template, the heading and the submit button:

```vue
<h3>{{ isEditing ? "Edit card" : "New card" }}</h3>
```

```vue
<button type="submit" class="primary">{{ isEditing ? "Save changes" : "Add card" }}</button>
```

Here is what changed:

- `card` is an optional prop with the default `null`. "No card" means "create a new one".
- `const isEditing = props.card !== null;` decides the mode once, when the form is created.
- The `form` object copies each field from `props.card` when editing, or uses the defaults when creating. This is the key idea of the lesson: the form gets its **own copy** of the data. `v-model` edits the copy, and the original card in `App.vue` does not change until the user clicks "Save changes".
- `resetForm()` is gone. `App.vue` closes the form after every save, and because the form is shown with `v-if`, closing it destroys the component. The next time it opens, Vue creates a fresh one with fresh state.
- The heading and the submit button change their text depending on the mode.

Save both files.

---

## 4. Run and Test

Restart the development server and open `http://localhost:5173`. The status line starts with the hint:

```text
Use the buttons on a card to move, edit, or delete it.
```

**Delete.** Click "Delete" on "Set up hosting". The card disappears.

The status line and the column headers:

```text
Deleted "Set up hosting".
To Do (2) | In Progress (1) | Done (2)
```

**Edit.** Click "Edit" on "Design home page". The form opens in edit mode and is already filled in. The heading, the field values, and the submit button:

```text
FORM H3: Edit card | TITLE: Design home page | STATUS: in-progress | PRIORITY: medium | DUE: 2026-11-07 | SUBMIT: Save changes
```

Change the title to `Design home and about pages` and the priority to High. While you type, look at the card on the board: its title still reads `Design home page`, because the form edits its own copy. Now click "Save changes".

The status line, the column headers, and the updated card:

```text
Updated "Design home and about pages".
To Do (2) | In Progress (1) | Done (2)
```

The updated card:

```text
HIGH
Design home and about pages

Create the first layout for the home page.

Due 2026-11-07

← Back
Next →
Edit
Delete
```

The card kept its place, its description, and its due date, and got the new title and priority.

**Cancel.** Click "Edit" on "Write project brief", change the title to anything, and click "Cancel". The form closes, and the card still reads `Write project brief`. The status line keeps the previous message, because nothing happened.

**Add.** Click "+ New card". The form opens in create mode with the heading "New card" and an empty title. Type `Write SEO checklist` and click "Add card".

The status line and the column headers:

```text
Added "Write SEO checklist" to To Do.
To Do (3) | In Progress (1) | Done (2)
```

**Move.** Click "← Back" on "Pick color palette".

```text
Moved "Pick color palette" from Done to In Progress.
To Do (3) | In Progress (2) | Done (1)
```

All four actions go through `App.vue`, and all four report in the same status line. Run the linters as well.

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

These are the most common mistakes when editing and deleting data.

**Error 1: Binding `v-model` directly to a prop.**

It is tempting to skip the copy and let the form edit the card itself.

```vue
<!-- Wrong -->
<input v-model.trim="card.title" type="text" placeholder="What needs to be done?" />

<!-- Correct -->
<input v-model.trim="form.title" type="text" placeholder="What needs to be done?" />
```

With the wrong version, open "Edit" on "Design home page" and type `Something else`. The card on the board changes while you type, and clicking "Cancel" does not undo it:

```text
CARD3 WHILE TYPING: Something else
CARD3 AFTER CANCEL: Something else
```

`card` is the very same object that lives in `App.vue`'s array, so the child changed its parent's data behind its back, and "Cancel" became meaningless. The linter refuses this code:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/CardForm.vue
  46:28  error  Unexpected mutation of "card" prop  vue/no-mutating-props

✖ 1 problem (1 error, 0 warnings)

ERROR: "lint:eslint" exited with 1.
```

Copy props into local state first, edit the copy with `v-model`, and emit it when the user confirms.

**Error 2: Forgetting the key on a reused form.**

```vue
<!-- Wrong -->
<CardForm
  v-if="showForm"
  :card="editingCard"
  @save="saveCard"
  @cancel="closeForm"
/>

<!-- Correct -->
<CardForm
  v-if="showForm"
  :key="editingCard ? editingCard.id : 'new'"
  :card="editingCard"
  @save="saveCard"
  @cancel="closeForm"
/>
```

With the wrong version, click "Edit" on "Design home page" and then, while the form is still open, click "Edit" on "Write project brief". The form still shows the first card:

```text
TITLE: Design home page
AFTER CLICKING EDIT ON CARD 1, TITLE: Design home page
```

`showForm` was already true, so Vue kept the existing `CardForm` and only passed it a new `card` prop. But the form copied the prop into `form` once, when it was created, and never looks at it again. Clicking "Save changes" would now write "Design home page" over the "Write project brief" card. A changing `key` tells Vue that this is a different form: Vue destroys the old component and creates a new one, which copies the new card. You saw keys identify list items in Lesson 6; on a single component, a key is the simplest way to start it fresh.

**Error 3: Calling `filter` without using its result.**

`filter` does not change the array it is called on. It returns a new one.

```javascript
// Wrong
function deleteCard(cardId) {
  const card = findCard(cardId);
  cards.value.filter((card) => card.id !== cardId);
  message.value = `Deleted "${card.title}".`;
}

// Correct
function deleteCard(cardId) {
  const card = findCard(cardId);
  cards.value = cards.value.filter((card) => card.id !== cardId);
  message.value = `Deleted "${card.title}".`;
}
```

With the wrong version, clicking "Delete" on "Set up hosting" reports success, but the card stays on the board:

```text
STATUS: Deleted "Set up hosting".
H3s: To Do (2) | In Progress (2) | Done (2)
```

The filtered array was created and immediately thrown away. Assign the result back to `cards.value`. The same applies to `map` and `slice`, which also return new arrays, while `push`, `splice`, and `sort` change the array in place.

---

## 6. Exercises

**Exercise 1:** Deleting is permanent, so ask first. Before removing a card, show the browser's confirmation dialog with `` window.confirm(`Delete "${card.title}"?`) ``, and only delete the card when the user clicks OK.

**Exercise 2:** Add a "Clear done" button to the toolbar, to the left of "+ New card". It should remove every card in the Done column and set the message to `Cleared 2 done cards.` (with the real number).

**Exercise 3:** Add a "Copy" button between "Edit" and "Delete". It should add a duplicate of the card to the same column with a new id and the title followed by ` (copy)`, and set the message to `Duplicated "<title>".`

---

## 7. Solutions

**Solution for Exercise 1:**

Add a check at the start of `deleteCard` in `src/App.vue`:

```javascript
function deleteCard(cardId) {
  const card = findCard(cardId);
  if (!window.confirm(`Delete "${card.title}"?`)) {
    return;
  }
  cards.value = cards.value.filter((card) => card.id !== cardId);
  message.value = `Deleted "${card.title}".`;
}
```

`window.confirm` shows a dialog with OK and Cancel buttons and returns `true` for OK and `false` for Cancel. Clicking "Delete" on "Set up hosting" opens a dialog with this text:

```text
Delete "Set up hosting"?
```

After clicking OK, the status line and headers read:

```text
Deleted "Set up hosting".
To Do (2) | In Progress (1) | Done (2)
```

After clicking Cancel, the function returns early and nothing changes. The built-in dialog is plain, but it works everywhere; in Lesson 14 you will build your own modal window with slots.

**Solution for Exercise 2:**

Add the function to `src/App.vue`:

```javascript
function clearDone() {
  const doneCount = cardsFor("done").length;
  cards.value = cards.value.filter((card) => card.status !== "done");
  message.value = `Cleared ${doneCount} done cards.`;
}
```

And the button to the toolbar, wrapped with "+ New card" in a `<div>`:

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <div>
    <button type="button" @click="clearDone">Clear done</button>
    <button type="button" class="primary" @click="openNewForm">+ New card</button>
  </div>
</div>
```

The count is taken before filtering, while the done cards still exist. `cardsFor("done")` reuses the helper you already have. After clicking "Clear done":

```text
Cleared 2 done cards.
To Do (2) | In Progress (1) | Done (0)
```

This run started after deleting "Set up hosting" in Exercise 1, which is why In Progress shows 1. The Done column now shows its empty state.

**Solution for Exercise 3:**

Add the function to `src/App.vue`:

```javascript
function duplicateCard(cardId) {
  const card = findCard(cardId);
  const copy = { ...card, id: nextId(), title: `${card.title} (copy)` };
  cards.value.push(copy);
  message.value = `Duplicated "${card.title}".`;
}
```

`{ ...card, id: nextId(), title: ... }` copies every property of the card and then overrides `id` and `title`. Properties written after the spread win. Pass the new event through the components exactly like `edit`: add `"duplicate"` to `defineEmits` in `TaskCard.vue` and `BoardColumn.vue`, add the button in `TaskCard.vue`:

```vue
<button type="button" @click.stop="emit('duplicate', card.id)">Copy</button>
```

forward it in `BoardColumn.vue`:

```vue
@duplicate="(cardId) => emit('duplicate', cardId)"
```

and listen in `App.vue` with `@duplicate="duplicateCard"`. After clicking "Copy" on "Write project brief":

```text
Duplicated "Write project brief".
To Do (3) | In Progress (1) | Done (0)
```

The cards in To Do are now:

```text
card-1 Write project brief | card-2 Collect logo files | card-4 Write project brief (copy)
```

Notice the copy's id: `4`. This run had deleted "Set up hosting" (id 4) and cleared the done cards (ids 5 and 6) in the earlier exercises, so the highest remaining id was 3, and `nextId()` reused 4. Inside Tasklane that is harmless, because no other card has that id. But once cards get their own web addresses in Lesson 18, such as `/cards/4`, a reused id could make an old bookmark open a different card. Real apps often use ids that never repeat, such as `crypto.randomUUID()`. Undo these exercise changes before the next lesson.

---

## 8. A Single Source of Truth

Look at where the board's data can change in Tasklane: only in `App.vue`. `TaskCard` emits `move`, `edit`, and `delete`; `BoardColumn` passes them on; `CardForm` emits a copy of its form. None of them change the cards themselves. `App.vue` owns `cards`, and every change to it happens in one of its functions: `saveCard`, `deleteCard`, or `moveCard`.

This pattern is called keeping a **single source of truth**. It has very practical benefits:

- **Bugs are easy to find.** If a card ends up in the wrong column, there is exactly one function that moves cards. You do not have to search every component.
- **Features are easy to add.** The status line reports every action because every action already passes through `App.vue`. Saving the board to the browser's storage in Lesson 13 will work the same way.
- **Cancel really cancels.** Because the form edits a copy, nothing reaches the source of truth until the user confirms.

As apps grow, passing events up through several components becomes tiring, just as passing props down did in Lesson 9's Exercise 3. In Lesson 19 you will move the source of truth into a Pinia store, where any component can call actions such as `deleteCard` directly. The principle stays the same: one owner for the data, and clear functions for every change.

---

## Next Up - Lesson 12

In this lesson you completed the card life cycle. You added "Edit" and "Delete" buttons, removed cards by replacing the array with a filtered copy, updated cards in place with `Object.assign`, reused `CardForm` for editing by copying the `card` prop into local state, used a `key` to give each edit a fresh form, and gathered every change in `App.vue` behind one status line. That completes Module 3: Tasklane is now a fully interactive board.

In Lesson 12, you will start calculating new information from the cards. With computed properties, you will show progress like `2 of 6 cards done (33%)`, count overdue cards, and add a search box and a priority filter that update the board as you type, and you will learn why computed properties are better than methods or extra state for this job.
