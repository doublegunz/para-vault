## 1. Before You Begin

In Lesson 12, computed properties gave Tasklane progress stats and a live search and priority filter. Tasklane now feels like a real tool, which makes one problem impossible to ignore: refresh the page, and every card you added, edited, moved, or deleted is gone. The board always starts again from `sampleCards`, because the cards only live in the browser's memory while the page is open.

In this lesson you will make the board survive a refresh by saving it in the browser's `localStorage`. Saving data is a **side effect**: something your code does to the outside world in response to a change, which is exactly what computed properties must not do. Vue's tool for side effects is the **watcher**. You will save the cards with `watch`, keep the browser tab title up to date with `watchEffect`, and use the `onMounted` lifecycle hook to put the cursor in the form's title field the moment the form opens.

### What You'll Build

A board that remembers its state. Move a card, add one, or delete one, then refresh the page, and the board looks exactly as you left it. The browser tab shows how many cards are still open, for example `Tasklane (4 open)`, and the number changes as cards reach Done. When you click "+ New card" or "Edit", the cursor is already in the title field, so you can start typing immediately.

### What You'll Learn

- ✅ What `localStorage` is and how to save and load data with `JSON.stringify` and `JSON.parse`
- ✅ What a side effect is, and why it belongs in a watcher instead of a computed property
- ✅ How to react to changes with `watch`, and why arrays of objects need `{ deep: true }`
- ✅ How `watchEffect` tracks its dependencies automatically
- ✅ What the component lifecycle is, and how to run code after mounting with `onMounted`
- ✅ How to reach a DOM element with a template ref and `useTemplateRef`

### What You'll Need

- The Tasklane project from Lesson 12, with the development server running
- Your browser open at `http://localhost:5173`, with the developer tools open

---

## 2. Save the Board to localStorage

`localStorage` is a small storage area that every browser gives each website. It stores text under names called **keys**, and the text stays there after a refresh and even after the browser is closed. It has three methods you need: `localStorage.setItem(key, text)` saves, `localStorage.getItem(key)` loads (or returns `null` when nothing is saved), and `localStorage.removeItem(key)` deletes.

`localStorage` only stores text, while Tasklane's cards are an array of objects. `JSON.stringify(cards)` turns the array into a text in JSON format, and `JSON.parse(text)` turns that text back into an array.

### Step 1: Load the Cards When the App Starts

Open `src/App.vue`. Update the Vue import, and replace the line `const cards = ref(sampleCards);` with a loading function. Here is the beginning of the `<script setup>` block, up to the line with `priorityFilter`:

```javascript
import { computed, ref, watch, watchEffect } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import FilterBar from "./components/FilterBar.vue";
import { columns, sampleCards } from "./data/board.js";
import { isOverdue } from "./utils/dates.js";

const STORAGE_KEY = "tasklane-cards";

function loadCards() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved === null) {
    return structuredClone(sampleCards);
  }
  return JSON.parse(saved);
}

const boardName = "Website Redesign";
const cards = ref(loadCards());
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);
const search = ref("");
const priorityFilter = ref("all");
```

Here is what is new:

- `watch` and `watchEffect` are imported for the next steps.
- `STORAGE_KEY` is the name under which Tasklane saves its cards. Writing it once as a constant avoids typos when the same name is used in several places. Constants like this are often written in capital letters.
- `loadCards()` reads the saved text. When nothing is saved yet, it returns the sample cards; otherwise it parses the saved text back into an array.
- `structuredClone(sampleCards)` returns a deep copy of the sample data. Until now, `ref(sampleCards)` used the sample objects themselves, so moving a card actually changed the objects inside `board.js`. That did not matter while a refresh reset everything, but from now on Tasklane will need clean sample data, for example for a "Reset board" button, so it gets a copy.
- `const cards = ref(loadCards());` starts the board from whatever `loadCards` returns.

The rest of the script, from `doneCount` onward, stays the same for now.

### Step 2: Save the Cards Whenever They Change

Add this watcher right after the `isFiltering` computed property:

```javascript
watch(
  cards,
  (newCards) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(newCards));
  },
  { deep: true },
);
```

Here is how `watch` works:

- The first argument is the **source**, the reactive value to watch: here the `cards` ref.
- The second argument is the **callback**, the function to run whenever the source changes. It receives the new value, which this callback turns into JSON and saves.
- The third argument is options. `{ deep: true }` tells Vue to watch every property of every card inside the array, not just the array itself. Without it, moving a card, which only changes `card.status`, would not trigger the watcher. Section 6 shows that bug in action.

Notice that this one watcher saves the board after every kind of change: `saveCard`, `deleteCard`, `moveCard`, and any action you add later. None of those functions needed to change. That is the single source of truth from Lesson 11 paying off.

Save the file. Then open the developer tools, go to the **Application** tab in Chrome or Edge (the **Storage** tab in Firefox), expand **Local storage**, and select `http://localhost:5173`. Nothing is saved yet, because the watcher only runs when the cards change.

### Step 3: Test the Saved Board

Click "Next →" on "Write project brief". A key named `tasklane-cards` appears in local storage, with this value:

```text
[{"id":1,"title":"Write project brief","description":"Summarize the goals and scope of the website redesign.","status":"in-progress","priority":"high","dueDate":"2026-11-03"},{"id":2,"title":"Collect logo files","description":"Ask the client for SVG versions of the logo.","status":"todo","priority":"low","dueDate":""},{"id":3,"title":"Design home page","description":"Create the first layout for the home page.","status":"in-progress","priority":"medium","dueDate":"2026-11-07"},{"id":4,"title":"Set up hosting","description":"","status":"in-progress","priority":"high","dueDate":"2026-10-28"},{"id":5,"title":"Pick color palette","description":"Choose the primary and accent colors.","status":"done","priority":"medium","dueDate":"2026-10-25"},{"id":6,"title":"Write About page text","description":"Draft a short text about the company.","status":"done","priority":"low","dueDate":"2026-10-27"}]
```

That is the whole board as JSON text, with card 1 now `"in-progress"`. Now add a card titled `Write SEO checklist`, and delete "Set up hosting". The column headers:

```text
To Do (2) | In Progress (2) | Done (2)
```

Refresh the page. The board looks exactly the same. The column headers and the cards in each column after the refresh:

```text
To Do (2) | In Progress (2) | Done (2)
Collect logo files, Write SEO checklist || Write project brief, Design home page || Pick color palette, Write About page text
```

Every change survived: card 1 is still in progress, the new card is in To Do, and "Set up hosting" is gone. To start over with the sample cards, delete the `tasklane-cards` key in the Application tab (right-click it and choose **Delete**) and refresh. You will build a "Reset board" button in Exercise 1.

---

## 3. Update the Tab Title with watchEffect

`watch` needs you to name the source you want to watch. `watchEffect` is a shorter form: you give it one function, Vue runs it immediately, records every reactive value the function reads, and runs it again whenever any of them changes. It is handy for effects that simply mirror some state somewhere else, such as the browser tab title.

### Step 1: Show the Open Count in the Tab

Add this code right after the `watch` from Section 2:

```javascript
watchEffect(() => {
  const openCount = cards.value.length - doneCount.value;
  document.title = `Tasklane (${openCount} open)`;
});
```

The function reads `cards.value.length` and `doneCount.value`, so Vue reruns it whenever either changes. `document.title` is the text in the browser tab. Setting the page title is a side effect too: it changes something outside your components.

Save the file. To start from the sample cards, delete the `tasklane-cards` key in the Application tab and refresh. Then move "Design home page" to Done, and finally move "Pick color palette" and "Write About page text" back to In Progress.

The tab title after each step:

```text
TITLE: Tasklane (4 open)
TITLE after moving card 3 to Done: Tasklane (3 open)
TITLE after moving cards 5 and 6 back: Tasklane (5 open)
```

You never told `watchEffect` what to watch; it found out by itself. Use `watchEffect` when the effect uses several values and should simply rerun when any of them changes. Use `watch` when you need to name a specific source, need the old and new values, or need options such as `deep`.

---

## 4. Focus the Title Field with onMounted

Every component goes through a **lifecycle**: Vue creates it, inserts its elements into the page (**mounts** it), updates it when its state changes, and finally removes it (**unmounts** it). Lifecycle hooks let you run code at these moments. The most common one is `onMounted`, which runs once the component's elements exist in the page.

That matters when you need a real DOM element. When "+ New card" opens the form, the cursor should already be in the title field. To focus an input you call its `focus()` method, which needs the actual `<input>` element, and that element only exists after mounting.

### Step 1: Get the Input with a Template Ref and Focus It

Open `src/components/CardForm.vue`. Replace the Vue import and add two pieces after `const error = ref("");`, so the start of the `<script setup>` block looks like this:

```javascript
import { onMounted, reactive, ref, useTemplateRef } from "vue";
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
const titleInput = useTemplateRef("title-input");

onMounted(() => {
  titleInput.value.focus();
});
```

The `handleSubmit` function below it does not change. Then give the title input a `ref` attribute in the template:

```vue
<label>
  Title
  <input
    ref="title-input"
    v-model.trim="form.title"
    type="text"
    placeholder="What needs to be done?"
  />
  <small>{{ form.title.length }}/60 characters</small>
</label>
```

Here is how the pieces fit together:

- `ref="title-input"` on the `<input>` is a **template ref**: a name you give to an element so the script can find it. It is a plain attribute, not the `ref()` function, even though they share a name.
- `useTemplateRef("title-input")` returns a ref whose `.value` will be the element with that name. Before the component is mounted, `.value` is `null`, because the element does not exist yet.
- `onMounted(() => { ... })` registers a function that Vue calls right after the component's elements are in the page. At that moment `titleInput.value` is the real `<input>`, so `focus()` works.
- The input's attributes now sit on separate lines, because there are four of them.

Save the file and click "+ New card". The cursor is already blinking in the title field. In the console, check which element has focus:

```javascript
console.log(document.activeElement.tagName, document.activeElement.placeholder);
```

Output in the console:

```text
INPUT What needs to be done?
```

The active element is the title input. Click "Cancel", then "Edit" on any card: the form opens with the cursor in the title field again, because `v-if` creates a new `CardForm` every time, and every new instance is mounted.

---

## 5. Run and Test

Restart the development server and open `http://localhost:5173`. Check the following:

1. Moving, adding, editing, and deleting cards all survive a page refresh.
2. The `tasklane-cards` key in the Application tab changes after every action.
3. Deleting the key and refreshing brings back the six sample cards.
4. The tab title shows the number of cards that are not done, and changes as cards move.
5. Opening the form puts the cursor in the title field.

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

No problems are reported. Keep in mind what `localStorage` is and is not. It belongs to one browser on one computer: open Tasklane in another browser, and you see the sample cards. It is fine for personal tools and for learning; an app shared by a team would save its data on a server instead.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with watchers and lifecycle hooks.

**Error 1: Watching an array of objects without `deep`.**

```javascript
// Wrong
watch(cards, (newCards) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(newCards));
});

// Correct
watch(
  cards,
  (newCards) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(newCards));
  },
  { deep: true },
);
```

With the wrong version, start from the sample cards, move "Write project brief" to In Progress, and refresh:

```text
Before reload: To Do (1) | In Progress (3) | Done (2)
Saved: null
After reload: To Do (2) | In Progress (2) | Done (2)
```

Nothing was saved, and the move is lost. Without `deep`, a watcher on a ref only fires when `cards.value` is replaced by a new array. Deleting a card does replace the array, so deletions would be saved, but moving, editing, and adding (with `push`) change the existing array and its objects, which a shallow watcher does not notice. Bugs like this are confusing precisely because some actions work.

**Error 2: Forgetting `JSON.parse` when loading.**

```javascript
// Wrong
return saved;

// Correct
return JSON.parse(saved);
```

The wrong version works on the very first visit, because nothing is saved yet. As soon as something is saved and the page is refreshed, the page is blank, and the console shows:

```text
[Vue warn]: Unhandled error during execution of watcher callback 
  at <App>
[Vue warn]: Unhandled error during execution of setup function 
  at <App>
TypeError: cards.value.filter is not a function
```

`cards.value` is the JSON text, a string, and strings have no `filter` method. Whatever goes into `localStorage` through `JSON.stringify` must come out through `JSON.parse`. If your app is stuck on a blank page after a mistake like this, delete the saved key in the Application tab, fix the code, and refresh.

**Error 3: Using a template ref before the component is mounted.**

```javascript
// Wrong
const titleInput = useTemplateRef("title-input");
titleInput.value.focus();

// Correct
const titleInput = useTemplateRef("title-input");

onMounted(() => {
  titleInput.value.focus();
});
```

With the wrong version, clicking "+ New card" does not open the form, and the console shows:

```text
[Vue warn]: Unhandled error during execution of setup function 
  at <CardForm key="new" card=null onSave=fn<saveCard>  ... > 
  at <App>
TypeError: Cannot read properties of null (reading 'focus')
```

The code in `<script setup>` runs while Vue is still creating the component, before its template has produced any elements, so `titleInput.value` is still `null`. Anything that needs a real DOM element belongs in `onMounted`.

---

## 7. Exercises

**Exercise 1:** Add a "Reset board" button to the toolbar, to the left of "+ New card". It should replace the cards with a fresh copy of the sample cards and set the message to `The board was reset to the sample cards.` Does the reset survive a refresh, and why?

**Exercise 2:** Make Tasklane remember the priority filter too. Save `priorityFilter` under the key `tasklane-priority` whenever it changes, and use the saved value as the starting value when the app loads. Does this watcher need `deep`?

**Exercise 3:** Celebrate a finished board. Watch the `progress` computed property, and when it changes to `100` from a lower value, set the message to `All cards are done. Great work!` Hint: the `watch` callback receives the old value as its second argument.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the function to `src/App.vue`:

```javascript
function resetBoard() {
  cards.value = structuredClone(sampleCards);
  message.value = "The board was reset to the sample cards.";
}
```

And the button, with "+ New card", in a `<div>` in the toolbar:

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <div>
    <button type="button" @click="resetBoard">Reset board</button>
    <button type="button" class="primary" @click="openNewForm">+ New card</button>
  </div>
</div>
```

After moving every card to Done and clicking "Reset board", the columns and the message read:

```text
To Do (2) | In Progress (2) | Done (2)
STATUS: The board was reset to the sample cards.
```

After a refresh, the board is still the reset one:

```text
after reload: To Do (2) | In Progress (2) | Done (2)
```

The reset survives because assigning a new array to `cards.value` is a change the watcher sees, so the fresh sample cards are saved right away. `structuredClone` matters here: without it, the board would share objects with `sampleCards`, and the next move would quietly change the sample data, making the second reset wrong.

**Solution for Exercise 2:**

Change the starting value of `priorityFilter` in `src/App.vue`:

```javascript
const priorityFilter = ref(localStorage.getItem("tasklane-priority") ?? "all");
```

And add a watcher next to the other one:

```javascript
watch(priorityFilter, (newPriority) => {
  localStorage.setItem("tasklane-priority", newPriority);
});
```

`??` is the nullish coalescing operator: it uses the value on its right when the one on its left is `null` or `undefined`, which is what `getItem` returns when nothing is saved. After choosing "High" and refreshing, the dropdown and the columns read:

```text
SELECT after reload: high | To Do (1) | In Progress (1) | Done (0)
```

And the saved value is:

```text
STORAGE priority: high
```

This watcher does not need `deep`, because `priorityFilter` holds a simple string. Every change replaces the whole value, which a normal watcher always notices. `deep` only matters for objects and arrays whose insides change.

**Solution for Exercise 3:**

Add this watcher to `src/App.vue`, after the other watchers:

```javascript
watch(progress, (newProgress, oldProgress) => {
  if (newProgress === 100 && oldProgress < 100) {
    message.value = "All cards are done. Great work!";
  }
});
```

A computed property can be the source of a watcher, just like a ref. The callback receives the new value and the old value, so it can react only to the moment the board **becomes** complete, not every time something happens while it is complete. After moving every card to Done:

```text
6 of 6 cards done (100%), 0 overdue
STATUS: All cards are done. Great work!
TITLE: Tasklane (0 open)
```

`moveCard` first set its own "Moved ..." message, and then the watcher, which runs after the change, replaced it with the celebration. Undo these exercise changes before the next lesson, so your code matches Lesson 14.

---

## 9. watch, watchEffect, and the Lifecycle

You now have three tools that run code at the right moment.

| Tool | Runs | Use it for |
| --- | --- | --- |
| `watch(source, callback)` | When the named source changes (not at first, unless you pass `{ immediate: true }`) | Side effects that need the old and new value, a specific source, or `deep` |
| `watchEffect(fn)` | Immediately, then whenever anything it read changes | Side effects that mirror several values somewhere else |
| `onMounted(fn)` | Once, after the component's elements are in the page | Working with DOM elements, such as focusing an input |

And here is the difference between `computed` and `watch`, which beginners often mix up: **`computed` calculates a value; `watch` does something.** If the result is a value you want to display or use, write a computed property. If the result is an action, such as saving, logging, changing the page title, or calling an API, write a watcher.

Vue has a few more lifecycle hooks that you will meet in code written by others, especially by AI tools:

- `onUnmounted` runs when the component is removed, a good place to clean up timers or event listeners that `onMounted` started.
- `onUpdated` runs after the component re-renders because of a state change. It is rarely needed.
- `onBeforeMount` and `onBeforeUnmount` run just before mounting and unmounting.

Watchers created in `<script setup>` stop automatically when their component is unmounted, so you do not need to clean them up yourself.

---

## Next Up - Lesson 14

In this lesson you made Tasklane remember its board. You loaded the cards from `localStorage` with `JSON.parse`, saved them on every change with a deep `watch`, mirrored the open count in the tab title with `watchEffect`, and focused the form's title field with a template ref in `onMounted`. You also learned when to use each kind of watcher and why side effects never belong in computed properties.

In Lesson 14, the card form moves out of the page and into a pop-up window. You will learn **slots**, which let a parent pass template content into a child component, and use them to build a reusable `BaseModal` with a header, a body, and a footer, plus a column that lets its parent decide what to show when it is empty.
