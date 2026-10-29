## 1. Before You Begin

In Lesson 13, Tasklane started remembering its board between visits. The board is complete, but the card form still pushes everything down when it opens, because it sits in the normal flow of the page above the stats and the columns. Most apps show a form like this in a **modal**: a window that floats over the page, dims everything behind it, and closes when you click outside it.

A modal is a perfect example of a component that needs more than props. The modal itself decides how the window looks and how it closes, but what goes **inside** it, a card form, a confirmation question, or an info text, is decided by the parent. Vue's tool for this is the **slot**: a placeholder in a child's template that the parent fills with its own template content. In this lesson you will build a reusable `BaseModal` with a default slot and a named `header` slot, move the card form into it, and give `BoardColumn` an `empty` slot so the parent can decide what an empty column says.

### What You'll Build

Clicking "+ New card" or "Edit" opens the card form in a modal window over a dimmed board. The modal's heading reads "New card" or "Edit card", and it closes when you click the × button, click the dark area around it, click "Cancel", or save. When a search or priority filter hides every card in a column, that column says "No cards match your filters." instead of the usual "No cards here yet."

### What You'll Learn

- ✅ What slots are and how they differ from props
- ✅ How to create a default slot with `<slot>` and fill it from the parent
- ✅ How to create named slots and fill them with `<template #name>`
- ✅ How fallback content works when the parent does not fill a slot
- ✅ How to close a modal on a backdrop click with the `.self` modifier
- ✅ How scoped styles work with slot content, and what `:slotted()` does

### What You'll Need

- The Tasklane project from Lesson 13, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Build the BaseModal Component

Props pass data into a component. Slots pass **template content**: elements, text, and even other components. Inside the child, a `<slot>` element marks where that content should appear. The parent writes the content between the child's opening and closing tags.

The name `BaseModal` follows a common Vue convention: components prefixed with `Base` are generic building blocks that know nothing about Tasklane's cards and can be reused anywhere.

### Step 1: Create BaseModal.vue

Create `src/components/BaseModal.vue` with this code.

```vue
<script setup>
const emit = defineEmits(["close"]);
</script>

<template>
  <div class="backdrop" @click.self="emit('close')">
    <div class="modal" role="dialog" aria-modal="true">
      <header class="modal-header">
        <slot name="header">
          <h3>Tasklane</h3>
        </slot>
        <button type="button" class="close" aria-label="Close" @click="emit('close')">
          &times;
        </button>
      </header>
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
.backdrop {
  position: fixed;
  inset: 0;
  z-index: 10;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 64px 16px;
  background-color: rgba(17, 24, 39, 0.5);
  overflow-y: auto;
}

.modal {
  width: 100%;
  max-width: 560px;
  padding: 16px;
  background-color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

:slotted(h3) {
  margin: 0;
}

.close {
  border: none;
  font-size: 20px;
  line-height: 1;
}
</style>
```

Take the template first:

- `<div class="backdrop">` is the dark layer that covers the whole page. `@click.self="emit('close')"` closes the modal when the backdrop itself is clicked. The `.self` modifier from Lesson 8 matters here: a click on anything inside the white window also bubbles to the backdrop, but `.self` ignores it, because the click did not start on the backdrop.
- `<div class="modal" role="dialog" aria-modal="true">` is the white window. `role="dialog"` and `aria-modal="true"` tell screen readers that this is a dialog and that the rest of the page is inactive while it is open.
- `<slot name="header">` is a **named slot**. The parent can fill it with its own heading. The `<h3>Tasklane</h3>` between the slot tags is **fallback content**: it appears only when the parent does not fill the slot.
- The × button is part of the modal itself, not of the slot, so every modal gets one. `&times;` is the HTML entity for the × sign, and `aria-label="Close"` gives the button a name that screen readers can announce.
- `<slot></slot>` without a name is the **default slot**. Everything the parent places inside `<BaseModal>` that is not assigned to a named slot ends up here.
- The modal emits a single event, `close`. It does not decide what closing means; the parent does.

And the styles:

- `.backdrop` uses `position: fixed;` and `inset: 0;` to cover the whole browser window, a semi-transparent dark background to dim the page, and flexbox to center the window horizontally. `overflow-y: auto;` lets a tall modal scroll on small screens.
- `z-index: 10;` keeps the backdrop above everything on the page. Without it, some elements, such as the faded Done cards, would be painted on top of the modal. Section 5 shows why.
- `:slotted(h3)` styles an `<h3>` that the parent passes into a slot. Section 8 explains why a plain `h3` selector would not reach it.

### Step 2: Remove the Form's Own Box and Heading

The modal now provides the white box and the heading, so `CardForm` should not draw its own. In `src/components/CardForm.vue`, delete the heading line at the top of the template:

```vue
<h3>{{ isEditing ? "Edit card" : "New card" }}</h3>
```

Then, in the style block, replace the `.card-form` rule and delete the `h3` rule after it, so the beginning of the style block reads:

```css
.card-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
```

The form keeps its vertical layout, but loses its background, padding, shadow, margin, and maximum width, which the modal now takes care of. The rest of `CardForm.vue` stays the same, including `isEditing`, which still decides the text of the submit button.

### Step 3: Put the Form in the Modal

Open `src/App.vue`, import the new component next to the other imports:

```javascript
import BaseModal from "./components/BaseModal.vue";
```

Then replace the `<CardForm ... />` element in the template with this:

```vue
<BaseModal v-if="showForm" @close="closeForm">
  <template #header>
    <h3>{{ editingCard ? "Edit card" : "New card" }}</h3>
  </template>
  <CardForm
    :key="editingCard ? editingCard.id : 'new'"
    :card="editingCard"
    @save="saveCard"
    @cancel="closeForm"
  />
</BaseModal>
```

Here is how the content reaches the slots:

- `v-if="showForm"` moves from `CardForm` to `BaseModal`, so the whole modal appears and disappears together.
- `<template #header>` fills the named slot `header`. `#header` is the shorthand for `v-slot:header`. The heading is decided here, in the parent, because `App.vue` knows whether a card is being edited.
- `<CardForm ... />` is not inside any `<template #...>`, so it goes into the default slot.
- `@close="closeForm"` handles the modal's `close` event with the same function that "Cancel" and a successful save already use.

Notice that the `CardForm` element still listens to `@save` and `@cancel`, and those events still reach `App.vue`. Content placed in a slot belongs to the parent: it is written in `App.vue`'s template and can use `App.vue`'s data and functions, even though it is displayed inside `BaseModal`.

Save all three files and click "+ New card". The form opens in a white window over the dimmed board.

The text of the modal:

```text
New card
×
Title
0/60 characters
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

The cursor is still in the title field, because `CardForm`'s `onMounted` from Lesson 13 still runs. Inspect the modal header in the Elements panel:

```html
<header data-v-2ca291c6="" class="modal-header"><h3 data-v-7a7a37b1="" data-v-2ca291c6-s="">New card</h3><button data-v-2ca291c6="" type="button" class="close" aria-label="Close"> × </button></header>
```

The `<h3>` came from `App.vue` and carries `App.vue`'s scope attribute, `data-v-7a7a37b1`, not the modal's. It also has an extra attribute ending in `-s`, which Vue adds to slot content so that `:slotted()` can target it.

---

## 3. Let the Parent Decide What an Empty Column Says

Slots are not only for modals. In Lesson 6, every empty column showed "No cards here yet." But when a column is empty because of a filter, that message is misleading: the cards exist, they are just hidden. `BoardColumn` cannot know about filters, which live in `App.vue`. With a slot, it does not have to.

### Step 1: Add an empty Slot to BoardColumn

In `src/components/BoardColumn.vue`, replace the empty-state paragraph:

```vue
<p v-if="cards.length === 0" class="empty">No cards here yet.</p>
```

with a `div` that contains a named slot:

```vue
<div v-if="cards.length === 0" class="empty">
  <slot name="empty">No cards here yet.</slot>
</div>
```

Here is the complete template of `BoardColumn.vue` after the change:

```vue
<template>
  <section class="column" :style="{ borderTopColor: color }">
    <h3>{{ title }} ({{ cards.length }})</h3>
    <div v-if="cards.length === 0" class="empty">
      <slot name="empty">No cards here yet.</slot>
    </div>
    <template v-else>
      <TaskCard
        v-for="card in cards"
        :key="card.id"
        :card="card"
        @move="(cardId, direction) => emit('move', cardId, direction)"
        @edit="(cardId) => emit('edit', cardId)"
        @delete="(cardId) => emit('delete', cardId)"
      />
    </template>
  </section>
</template>
```

The text "No cards here yet." is now fallback content. The `div` keeps the `empty` class, so the existing `.empty` rule still centers and colors the message, whatever text the parent passes in.

### Step 2: Fill the Slot Only While Filtering

In `src/App.vue`, change the self-closing `<BoardColumn ... />` into an element with an opening and a closing tag, and put a slot template inside it:

```vue
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
  @move="moveCard"
  @edit="openEditForm"
  @delete="deleteCard"
>
  <template v-if="isFiltering" #empty>No cards match your filters.</template>
</BoardColumn>
```

`v-if="isFiltering"` on the slot template means the slot is only filled while a filter is active. When it is not filled, `BoardColumn` shows its fallback. The column itself stays simple and reusable; the parent, which knows about filters, supplies the right words. Save both files.

---

## 4. Run and Test

Restart the development server and open `http://localhost:5173`. Delete the `tasklane-cards` key in the Application tab and refresh, so you start from the sample cards. Then check the modal:

1. Click "+ New card": the form opens in a modal with the heading "New card".
2. Click inside the form, for example on the title input: the modal stays open.
3. Click the dark area outside the window: the modal closes.
4. Click "Edit" on "Design home page": the heading reads "Edit card" and the title field contains `Design home page`.
5. Click ×: the modal closes.
6. Click "+ New card", type `Write SEO checklist`, and click "Add card": the modal closes and the status line reads `Added "Write SEO checklist" to To Do.`

Then check the empty slot. Type `logo` in the search box.

The three columns, with their lines joined by slashes:

```text
To Do (1) / LOW / Collect logo files / Ask the client for SVG versions of the logo. / No due date / Next → / Edit / Delete || In Progress (0) / No cards match your filters. || Done (0) / No cards match your filters.
```

The empty columns now explain why they are empty. Clear the search box and delete both Done cards. The Done column falls back to the default text:

```text
Done (0) / No cards here yet.
```

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

These are the most common mistakes with slots and modals.

**Error 1: A slot name that does not match.**

The name after `#` must match the `name` attribute of a `<slot>` in the child.

```vue
<!-- Wrong -->
<template #heading>
  <h3>{{ editingCard ? "Edit card" : "New card" }}</h3>
</template>

<!-- Correct -->
<template #header>
  <h3>{{ editingCard ? "Edit card" : "New card" }}</h3>
</template>
```

With the wrong version, there is no error or warning. The modal header shows the fallback instead of your heading:

```text
Tasklane
×
```

`BaseModal` has no slot named `heading`, so Vue has nowhere to put that content and silently drops it. When slot content disappears, compare the name in the parent with the `<slot name="...">` in the child.

**Error 2: Closing on every click instead of backdrop clicks.**

```vue
<!-- Wrong -->
<div class="backdrop" @click="emit('close')">

<!-- Correct -->
<div class="backdrop" @click.self="emit('close')">
```

With the wrong version, the modal opens, but clicking into the title field to type closes it immediately:

```text
modal open after clicking the title input: false
```

The click on the input bubbles up through the form and the white window to the backdrop, which closes the modal. `.self` only reacts when the backdrop itself is the element that was clicked.

**Error 3: A modal without a z-index.**

```css
/* Wrong */
.backdrop {
  position: fixed;
  inset: 0;
  display: flex;
}

/* Correct */
.backdrop {
  position: fixed;
  inset: 0;
  z-index: 10;
  display: flex;
}
```

The snippets show only the relevant properties. With the wrong version, the Done cards appear on top of the open modal, cutting through the form. Checking which element is on top at the position of the "Pick color palette" title gives:

```text
TOP ELEMENT at the 'Pick color palette' title: H4 card-5
```

With `z-index: 10;`, the same check returns the modal:

```text
TOP ELEMENT at the 'Pick color palette' title: DIV modal
```

The Done cards have `opacity: 0.7`, and in CSS an element with an opacity below 1 starts its own **stacking context**, a layer that is painted according to its position in the page. The cards come after the modal in the HTML, so they were painted over it. A `z-index` on the fixed backdrop lifts the modal above all those layers.

---

## 6. Exercises

**Exercise 1:** Let users close any modal with the Escape key. In `BaseModal.vue`, add a `keydown` listener to `window` in `onMounted` that emits `close` when `event.key` is `"Escape"`, and remove the listener in `onUnmounted`.

**Exercise 2:** Replace instant deletion with a confirmation modal. Add an optional `footer` named slot to `BaseModal`, rendered inside a `<footer class="modal-footer">` only when the parent fills it (hint: `$slots.footer`). Then make "Delete" open a modal with the heading "Delete card?", the text `"<title>" will be removed from the board.`, and two buttons in the footer: "Keep it" and "Delete".

**Exercise 3:** Add an "About" button to the toolbar that opens a `BaseModal` with one paragraph: `Tasklane is a Kanban board built with Vue while learning on qadrlabs.` Do not fill the `header` slot. What does the modal's heading show, and why?

---

## 7. Solutions

**Solution for Exercise 1:**

Replace the `<script setup>` block of `src/components/BaseModal.vue`:

```vue
<script setup>
import { onMounted, onUnmounted } from "vue";

const emit = defineEmits(["close"]);

function handleKeydown(event) {
  if (event.key === "Escape") {
    emit("close");
  }
}

onMounted(() => {
  window.addEventListener("keydown", handleKeydown);
});

onUnmounted(() => {
  window.removeEventListener("keydown", handleKeydown);
});
</script>
```

The listener goes on `window`, because the user may press Escape while focus is anywhere in the page. `onUnmounted` removes it when the modal closes. Without that cleanup, every opened modal would leave a listener behind, and old listeners would keep calling `emit` on components that no longer exist. This is the `onMounted` and `onUnmounted` pair mentioned at the end of Lesson 13. After opening the form and pressing Escape:

```text
-- Exercise 1: form open after Escape: false
```

**Solution for Exercise 2:**

In the template of `src/components/BaseModal.vue`, add the footer after the default slot:

```vue
<slot></slot>
<footer v-if="$slots.footer" class="modal-footer">
  <slot name="footer"></slot>
</footer>
```

And a rule to its style block:

```css
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
}
```

`$slots` is an object available in every template, with one entry for each slot the parent filled. `v-if="$slots.footer"` skips the footer element entirely when no footer content was passed, so the form modal does not get an empty footer.

In `src/App.vue`, add a ref for the card waiting for confirmation, and split deletion into two functions:

```javascript
const cardToDelete = ref(null);
```

```javascript
function deleteCard(cardId) {
  cardToDelete.value = findCard(cardId);
}

function confirmDelete() {
  const card = cardToDelete.value;
  cards.value = cards.value.filter((item) => item.id !== card.id);
  message.value = `Deleted "${card.title}".`;
  cardToDelete.value = null;
}
```

Then add the modal to the template, after the form modal:

```vue
<BaseModal v-if="cardToDelete" @close="cardToDelete = null">
  <template #header>
    <h3>Delete card?</h3>
  </template>
  <p>"{{ cardToDelete.title }}" will be removed from the board.</p>
  <template #footer>
    <button type="button" @click="cardToDelete = null">Keep it</button>
    <button type="button" class="primary" @click="confirmDelete">Delete</button>
  </template>
</BaseModal>
```

Clicking "Delete" on "Set up hosting" opens the modal:

```text
Delete card?
×

"Set up hosting" will be removed from the board.

Keep it
Delete
```

"Keep it" closes the modal and the board still has six cards. Clicking "Delete" in the modal removes the card:

```text
after Delete: false | Deleted "Set up hosting". | To Do (2) | In Progress (1) | Done (2)
```

The same `BaseModal` now serves two completely different purposes, because the parent decides its content.

**Solution for Exercise 3:**

Add a ref and a button in `src/App.vue`, with the existing button in a `<div>`:

```javascript
const showAbout = ref(false);
```

```vue
<div>
  <button type="button" @click="showAbout = true">About</button>
  <button type="button" class="primary" @click="openNewForm">+ New card</button>
</div>
```

And the modal, with only default slot content:

```vue
<BaseModal v-if="showAbout" @close="showAbout = false">
  <p>Tasklane is a Kanban board built with Vue while learning on qadrlabs.</p>
</BaseModal>
```

The text of the modal:

```text
Tasklane
×

Tasklane is a Kanban board built with Vue while learning on qadrlabs.
```

The heading shows "Tasklane", the fallback content of the `header` slot, because the parent did not fill it. There is no footer, because `$slots.footer` is empty (if you did Exercise 2). Fallback content lets a component work sensibly with as little input as possible. Undo these exercise changes before the next lesson, so your code matches Lesson 15.

---

## 8. Slots and Scope

Two rules explain almost everything about slots.

**Slot content belongs to the parent.** The `<h3>` and the `CardForm` inside `<BaseModal>` are written in `App.vue`, so they can use `App.vue`'s data (`editingCard`), functions (`saveCard`), and events. They cannot see `BaseModal`'s internal variables. If a child does need to give data to its slot content, for example a list component that lets the parent decide how each item looks, Vue has **scoped slots**, where the child passes values with `<slot :item="item">` and the parent receives them with `<template #default="{ item }">`. You will see them in other people's code and in component libraries.

**Slot content keeps the parent's styles.** Because the `<h3>` belongs to `App.vue`, it carries `App.vue`'s scope attribute. A plain `h3 { margin: 0; }` rule in `BaseModal`'s scoped style would only match elements with `BaseModal`'s attribute, so it would not reach the heading. `:slotted(h3)` is the scoped-style selector for "an `h3` passed into one of my slots". Use it sparingly; most of the time, content should be styled by the component that wrote it.

Here is a comparison of the ways a parent can configure a child:

| Mechanism | Passes | Example in Tasklane |
| --- | --- | --- |
| Props | Data | `:cards="cardsFor(column.status)"` |
| Events | Notifications from child to parent | `@close="closeForm"` |
| `v-model` / `defineModel` | Data in both directions | `v-model:search="search"` |
| Slots | Template content | `<template #header>`, `<CardForm />` inside `BaseModal` |

A last note about modals: some apps render them with Vue's built-in `<Teleport to="body">`, which moves the modal's elements to the end of `<body>` while the component stays where it is in the tree. That avoids stacking problems like Error 3 entirely. Tasklane's modal works fine with `z-index`, but you will meet `Teleport` in larger codebases.

---

## Next Up - Lesson 15

In this lesson you learned slots. You built `BaseModal` with a default slot, a named `header` slot with fallback content, a backdrop that closes with `@click.self`, and a `z-index` that keeps it on top. You moved the card form into it, gave `BoardColumn` an `empty` slot so `App.vue` can explain filtered columns, and learned how slot content keeps the parent's data and styles. That completes Module 4.

In Module 5, Tasklane talks to the outside world. In Lesson 15, you will add an "Import tasks" button that loads sample tasks from a public API with `fetch` and `async`/`await`, shows loading and error states while it works, and converts the API's data into Tasklane cards.
