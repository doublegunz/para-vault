## 1. Before You Begin

In Lesson 18, every card got its own detail page, and the header got a small badge with the number of open cards. Then you watched that badge fall behind: moving cards on the board changed the board's stats immediately, but the header kept showing the old number until the page was refreshed. The board, the home page, the detail page, and the header each called `useLocalStorage` and got **their own copy** of the cards. They only met in `localStorage`, which stores data but does not tell anyone that it changed.

This lesson fixes the problem at its root. You will install **Pinia**, the official state management library for Vue, and create a **store**: a single, shared place that holds the cards and every action that changes them. Every component that calls `useBoardStore()` gets the same store, so a change made anywhere appears everywhere at once. Along the way, `BoardView.vue` gets shorter, because the logic about cards moves out of the page and into the store.

### What You'll Build

A Pinia store, `useBoardStore`, in `src/stores/board.js`. It holds the cards (still saved to `localStorage`), computed values such as `openCount` and `progress`, and actions such as `addCard`, `updateCard`, `deleteCard`, and `moveCard`. The board, the card detail page, the home page, and the header all use it. Moving a card on the board now updates the header badge instantly, and marking a card as done on its detail page updates every page.

### What You'll Learn

- ✅ What a store is and when shared state needs one
- ✅ How to install Pinia and register it with `app.use(createPinia())`
- ✅ How to define a setup store with `defineStore`, using `ref`, `computed`, and functions
- ✅ How state, getters, and actions map to refs, computed properties, and functions
- ✅ How to use a store in components, and why the same store is shared everywhere
- ✅ Why destructuring a store breaks reactivity, and how `storeToRefs` fixes it

### What You'll Need

- The Tasklane project from Lesson 18, with the development server running
- An internet connection to install Pinia

---

## 2. Install Pinia

Like Vue Router, Pinia is a separate package from the Vue team. Its name comes from "piña", Spanish for pineapple: a pineapple is made of many small fruits joined together, like an app made of many small stores.

### Step 1: Install the Package

In a terminal in the `tasklane` folder, run:

```bash
npm install pinia
```

Output:

```text
added 1 package, and audited 253 packages in 2s

68 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Only one package was added, because the packages Pinia depends on were already installed together with Vue Router. You can check which versions are installed with:

```bash
npm ls pinia vue-router
```

Output:

```text
tasklane@0.0.0 /home/gun-gun-priatna/obsidian-vault/sandbox/tasklane
├── pinia@4.1.0
└─┬ vue-router@5.4.0
  └── pinia@4.1.0 deduped
```

Vue Router 5 lists Pinia as an optional companion package, and `deduped` means both entries use the same installed copy. Your path and versions may differ.

### Step 2: Register Pinia

Open `src/main.js` and register Pinia, just like the router:

```javascript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router/index.js'
import './assets/main.css'

createApp(App).use(createPinia()).use(router).mount('#app')
```

`createPinia()` creates the Pinia instance that will hold every store in the app, and `.use(...)` installs it as a plugin, so any component can reach the stores. Save the file.

---

## 3. Create the Board Store

Pinia offers two ways to write a store. This course uses **setup stores**, which look exactly like the `<script setup>` code and composables you already know: refs become the store's **state**, computed properties become its **getters**, and functions become its **actions**.

### Step 1: Define useBoardStore

Create a folder named `stores` inside `src`, and inside it a file named `board.js`:

```javascript
import { defineStore } from "pinia";
import { computed } from "vue";
import { useLocalStorage } from "../composables/useLocalStorage.js";
import { columns, sampleCards } from "../data/board.js";
import { isOverdue } from "../utils/dates.js";

export const useBoardStore = defineStore("board", () => {
  const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));

  const doneCount = computed(() => cards.value.filter((card) => card.status === "done").length);
  const openCount = computed(() => cards.value.length - doneCount.value);
  const progress = computed(() => {
    if (cards.value.length === 0) {
      return 0;
    }
    return Math.round((doneCount.value / cards.value.length) * 100);
  });
  const overdueCount = computed(() => cards.value.filter((card) => isOverdue(card)).length);

  function findCard(cardId) {
    return cards.value.find((card) => card.id === cardId);
  }

  function nextId() {
    const ids = cards.value.map((card) => card.id);
    return Math.max(0, ...ids) + 1;
  }

  function addCard(cardData) {
    cards.value.push({ id: nextId(), ...cardData });
  }

  function updateCard(cardId, changes) {
    Object.assign(findCard(cardId), changes);
  }

  function deleteCard(cardId) {
    cards.value = cards.value.filter((card) => card.id !== cardId);
  }

  function moveCard(cardId, direction) {
    const card = findCard(cardId);
    const statuses = columns.map((column) => column.status);
    const index = statuses.indexOf(card.status);
    card.status = direction === "next" ? statuses[index + 1] : statuses[index - 1];
  }

  return {
    cards,
    doneCount,
    openCount,
    progress,
    overdueCount,
    findCard,
    addCard,
    updateCard,
    deleteCard,
    moveCard,
  };
});
```

Almost every line comes from `BoardView.vue`, so take it from the outside in:

- `defineStore("board", () => { ... })` defines a store. The first argument is its **id**, a unique name Pinia uses to tell stores apart. The second is the **setup function**, which runs once, the first time any component uses the store.
- `export const useBoardStore` follows the composable naming convention: it is a function you call to get the store.
- `cards` is the state. It still comes from `useLocalStorage`, so the store loads the saved cards and saves every change. Composables work inside stores just like inside components.
- `doneCount`, `openCount`, `progress`, and `overdueCount` are the getters. `openCount` is new; it is what the header and the home page need.
- `findCard`, `addCard`, `updateCard`, `deleteCard`, and `moveCard` are the actions, the only functions that change the cards. `nextId` is a helper that only the store uses.
- `updateCard(cardId, changes)` copies the changed properties onto the card with `Object.assign`, like `saveCard` did in Lesson 11. Passing only `{ status: "done" }` changes only the status.
- `moveCard` no longer writes a message, because messages are part of the board page's interface, not of the data.
- The `return` statement decides what the store offers. Everything the components use must be listed, including the state. `nextId` is left out on purpose, so it stays private.

The single source of truth from Lesson 11 has moved: it used to be `App.vue`, then `BoardView.vue`, and now it is the store, which no single page owns.

---

## 4. Use the Store Everywhere

A component gets the store by calling `useBoardStore()`. Every call returns the **same** store object, so every component sees the same cards. In the template and in the script, you read the store's state and getters as normal properties, without `.value`: `board.cards`, `board.openCount`. Pinia unwraps the refs for you.

### Step 1: Simplify BoardView

Replace the `<script setup>` block of `src/views/BoardView.vue` with this code:

```vue
<script setup>
import { computed, ref, watchEffect } from "vue";
import BaseModal from "../components/BaseModal.vue";
import BoardColumn from "../components/BoardColumn.vue";
import CardForm from "../components/CardForm.vue";
import FilterBar from "../components/FilterBar.vue";
import { useFetchJson } from "../composables/useFetchJson.js";
import { columns } from "../data/board.js";
import { useBoardStore } from "../stores/board.js";

const TODOS_URL = "https://dummyjson.com/todos?limit=3";

const board = useBoardStore();
const boardName = "Website Redesign";
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);
const search = ref("");
const priorityFilter = ref("all");
const { loading: importing, error: importError, fetchJson } = useFetchJson();

const visibleCards = computed(() => {
  const query = search.value.trim().toLowerCase();
  return board.cards.filter((card) => {
    const matchesSearch =
      card.title.toLowerCase().includes(query) || card.description.toLowerCase().includes(query);
    const matchesPriority =
      priorityFilter.value === "all" || card.priority === priorityFilter.value;
    return matchesSearch && matchesPriority;
  });
});
const isFiltering = computed(() => search.value.trim() !== "" || priorityFilter.value !== "all");

watchEffect(() => {
  document.title = `Tasklane (${board.openCount} open)`;
});

function cardsFor(status) {
  return visibleCards.value.filter((card) => card.status === status);
}

function columnTitle(status) {
  return columns.find((column) => column.status === status).title;
}

function openNewForm() {
  editingCard.value = null;
  showForm.value = true;
}

function openEditForm(cardId) {
  editingCard.value = board.findCard(cardId);
  showForm.value = true;
}

function closeForm() {
  showForm.value = false;
  editingCard.value = null;
}

function saveCard(cardData) {
  if (editingCard.value === null) {
    board.addCard(cardData);
    message.value = `Added "${cardData.title}" to ${columnTitle(cardData.status)}.`;
  } else {
    board.updateCard(editingCard.value.id, cardData);
    message.value = `Updated "${cardData.title}".`;
  }
  closeForm();
}

function deleteCard(cardId) {
  const card = board.findCard(cardId);
  board.deleteCard(cardId);
  message.value = `Deleted "${card.title}".`;
}

function todoToCard(todo) {
  return {
    title: todo.todo,
    description: "Imported from DummyJSON.",
    status: todo.completed ? "done" : "todo",
    priority: "medium",
    dueDate: "",
  };
}

async function importTasks() {
  const data = await fetchJson(TODOS_URL);
  if (data === null) {
    return;
  }

  for (const todo of data.todos) {
    board.addCard(todoToCard(todo));
  }
  message.value = `Imported ${data.todos.length} tasks from DummyJSON.`;
}

function moveCard(cardId, direction) {
  const card = board.findCard(cardId);
  const from = columnTitle(card.status);
  board.moveCard(cardId, direction);
  message.value = `Moved "${card.title}" from ${from} to ${columnTitle(card.status)}.`;
}
</script>
```

Here is what changed:

- `const board = useBoardStore();` replaces `useLocalStorage`, `sampleCards`, and `isOverdue`, which the page no longer needs.
- `doneCount`, `progress`, `overdueCount`, `findCard`, and `nextId` are gone from the page; they live in the store.
- `visibleCards` reads `board.cards`, without `.value`.
- The page keeps everything that is about **this page**: the form, the filters, the status message, and the import. Those are not shared with other pages, so they stay local.
- The page's functions now call the store's actions: `board.addCard`, `board.updateCard`, `board.deleteCard`, and `board.moveCard`. `moveCard` reads the card's new status after the action to build its message.

In the template, three expressions in the stats and "Showing" lines must read from the store now:

```vue
<p class="stats">
  {{ board.doneCount }} of {{ board.cards.length }} cards done ({{ board.progress }}%),
  {{ board.overdueCount }} overdue
</p>
<FilterBar v-model:search="search" v-model:priority="priorityFilter" />
<p v-if="isFiltering" class="status">
  Showing {{ visibleCards.length }} of {{ board.cards.length }} cards.
</p>
```

The rest of the template and the styles stay the same.

### Step 2: Use the Store on the Other Pages

In `src/views/CardDetailView.vue`, replace the `<script setup>` block:

```vue
<script setup>
import { computed } from "vue";
import { RouterLink, useRoute, useRouter } from "vue-router";
import { columns } from "../data/board.js";
import { useBoardStore } from "../stores/board.js";
import { isOverdue } from "../utils/dates.js";

const route = useRoute();
const router = useRouter();
const board = useBoardStore();

const card = computed(() => board.findCard(Number(route.params.id)));
const columnTitle = computed(
  () => columns.find((column) => column.status === card.value.status).title,
);

function markAsDone() {
  board.updateCard(card.value.id, { status: "done" });
}

function deleteCard() {
  board.deleteCard(card.value.id);
  router.push({ name: "board" });
}
</script>
```

The page asks the store for the card, and changes it only through actions. The template does not change.

In `src/views/HomeView.vue`, the script becomes three lines, and the summary reads the store's getter:

```vue
<script setup>
import { RouterLink } from "vue-router";
import { useBoardStore } from "../stores/board.js";

const board = useBoardStore();
</script>
```

```vue
<p class="summary">You have {{ board.openCount }} open cards on your board.</p>
```

### Step 3: Use the Store in the Header

Finally, in `src/components/AppHeader.vue`, replace the `<script setup>` block:

```vue
<script setup>
import { RouterLink } from "vue-router";
import { useBoardStore } from "../stores/board.js";

defineProps({
  tagline: {
    type: String,
    default: "Plan your work, one card at a time.",
  },
});

const board = useBoardStore();
</script>
```

And update the badge:

```vue
<span class="open-count">{{ board.openCount }} open</span>
```

Now search the project for `useLocalStorage("tasklane-cards"`. The only place left is the store. Save all files.

---

## 5. Run and Test

Restart the development server, delete the `tasklane-cards` key in the Application tab, and open `http://localhost:5173/board`. Repeat the test from Lesson 18: compare the header badge with the stats line while you move cards to Done.

```text
start                              | header: 4 open | stats: 2 of 6 cards done (33%), 1 overdue
after moving card 3 to Done        | header: 3 open | stats: 3 of 6 cards done (50%), 1 overdue
after moving card 4 to Done        | header: 2 open | stats: 4 of 6 cards done (67%), 0 overdue
after a page refresh               | header: 2 open | stats: 4 of 6 cards done (67%), 0 overdue
```

The badge follows every move. The header and the board read the same `cards` from the same store, so there is nothing to keep in sync anymore.

Next, clean the board again, open `http://localhost:5173/cards/3`, and click "Mark as done". Then visit the home page, go back to the board, and import tasks:

```text
on /cards/3 header: 4 open
after Mark as done header: 3 open | title: Tasklane
home: You have 3 open cards on your board.
after import header: 4 open | stats: 5 of 9 cards done (56%), 1 overdue
```

The detail page's action updated the header immediately, the home page shows the same number, and the imported cards appear everywhere at once (one of the three imported tasks is open, which raises the count to 4). The tab title still reads `Tasklane` on the detail page, because only the board page sets it. Finally, repeat the full detail-page flow from Lesson 18: open a card, mark it as done, delete another one, and use the back button. Everything behaves as before:

```text
-- back to board: URL /board | To Do (2) | In Progress (1) | Done (3)
-- clicked Next on card 2: URL /board
-- after Delete card: URL /board | To Do (1) | In Progress (1) | Done (3)
-- back button: URL /cards/2
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

No problems are reported. If you installed the Vue DevTools browser extension or use the panel that opens with `Alt+Shift+D` (from Lesson 2), you will also find a **Pinia** tab there, which shows the store's state and getters live and lists every action as it runs.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with Pinia.

**Error 1: Destructuring state or getters from the store.**

It is tempting to write shorter templates by pulling values out of the store:

```javascript
// Wrong
const { openCount } = useBoardStore();

// Correct
const board = useBoardStore();
```

With the wrong version in `AppHeader.vue` (and `{{ openCount }}` in the template), the badge is stuck again:

```text
start                              | header: 4 open | stats: 2 of 6 cards done (33%), 1 overdue
after moving card 3 to Done        | header: 4 open | stats: 3 of 6 cards done (50%), 1 overdue
after moving card 4 to Done        | header: 4 open | stats: 4 of 6 cards done (67%), 0 overdue
after a page refresh               | header: 2 open | stats: 4 of 6 cards done (67%), 0 overdue
```

A store is a `reactive` object, and destructuring copies its current values into plain variables, exactly like Lesson 9's Error 2. If you want short names, use Pinia's `storeToRefs`, which turns each piece of state and each getter into a ref:

```javascript
import { storeToRefs } from "pinia";
import { useBoardStore } from "../stores/board.js";

const { openCount } = storeToRefs(useBoardStore());
```

With `storeToRefs`, the destructured `openCount` stays connected, and the badge follows every move again:

```text
after moving card 3 to Done        | header: 3 open | stats: 3 of 6 cards done (50%), 1 overdue
after moving card 4 to Done        | header: 2 open | stats: 4 of 6 cards done (67%), 0 overdue
```

Actions are plain functions, so they can be destructured directly: `const { deleteCard } = useBoardStore();` is fine.

**Error 2: Forgetting to install Pinia.**

```javascript
// Wrong
createApp(App).use(router).mount('#app')

// Correct
createApp(App).use(createPinia()).use(router).mount('#app')
```

With the wrong version, the page is blank, and the console shows:

```text
[Vue warn]: Unhandled error during execution of setup function 
  at <AppHeader > 
  at <App>
Error: [🍍]: "getActivePinia()" was called but there was no active Pinia. Are you trying to use a store before calling "app.use(pinia)"?
See https://pinia.vuejs.org/core-concepts/outside-component-usage.html for help.
This will fail in production.
```

The pineapple in the message tells you it comes from Pinia, and the question in it is exactly right: the store was used before Pinia was installed.

**Error 3: Forgetting to return something from a setup store.**

```javascript
// Wrong
return {
  cards,
  doneCount,
  progress,
  // ...the other getters and actions, but no openCount
};

// Correct
return {
  cards,
  doneCount,
  openCount,
  progress,
  // ...the other getters and actions
};
```

With the wrong version, there is no error. The page simply shows nothing where the number should be:

```text
Tasklane

Plan your work, one card at a time.

Home
Board
About
open
Welcome to Tasklane

Tasklane keeps your work in three columns: To Do, In Progress, and Done. Add a card for every task, move it forward as you work, and watch the board empty out.

You have open cards on your board.

Open the board
```

`board.openCount` is `undefined`, which renders as nothing. In a setup store, anything you do not return is private. Pinia also expects **all** state to be returned, otherwise tools such as the DevTools cannot see it. When a store value seems to vanish, check the `return` object first.

---

## 7. Exercises

**Exercise 1:** Add a `resetBoard` action to the store that replaces the cards with a fresh copy of the sample cards. Then add a "Reset board to the sample cards" button to the About page, with a short confirmation line `The board was reset.` after clicking. In `AboutView.vue`, destructure the action directly from the store. Does the header badge update while you are still on the About page?

**Exercise 2:** Add a getter `highPriorityOpenCount` to the store that counts the open cards with high priority. Show it as a tooltip on the header badge, for example `2 high priority`, with a bound `title` attribute.

**Exercise 3:** Explain in your own words which state in Tasklane belongs in the store and which should stay local to `BoardView`: the cards, the search text, the priority filter, `showForm`, `editingCard`, and the status message. Use one question as your test: "does another component need it?"

---

## 8. Solutions

**Solution for Exercise 1:**

Add the action to `src/stores/board.js`, before `moveCard`, and return it:

```javascript
function resetBoard() {
  cards.value = structuredClone(sampleCards);
}
```

```javascript
return {
  cards,
  doneCount,
  openCount,
  progress,
  overdueCount,
  findCard,
  addCard,
  updateCard,
  deleteCard,
  moveCard,
  resetBoard,
};
```

Then give `src/views/AboutView.vue` a script and the button:

```vue
<script setup>
import { ref } from "vue";
import { useBoardStore } from "../stores/board.js";

const { resetBoard } = useBoardStore();
const resetDone = ref(false);

function handleReset() {
  resetBoard();
  resetDone.value = true;
}
</script>
```

```vue
<button type="button" @click="handleReset">Reset board to the sample cards</button>
<p v-if="resetDone">The board was reset.</p>
```

Put the two lines after the last paragraph in the template. After moving four cards forward on the board, going to About, and clicking the button:

```text
after reset on About: header: 4 open | tooltip: 2 high priority | The board was reset.
board: To Do (2) | In Progress (2) | Done (2)
```

Yes, the badge jumped to 4 while you were still on the About page, even though the board page was not on the screen. The About page and the header share the store. (The tooltip in this output comes from Exercise 2.) Destructuring `resetBoard` is safe, because actions are functions, not reactive values.

**Solution for Exercise 2:**

Add the getter to the store after `overdueCount`, and add `highPriorityOpenCount` to the returned object:

```javascript
const highPriorityOpenCount = computed(
  () => cards.value.filter((card) => card.priority === "high" && card.status !== "done").length,
);
```

Then bind the badge's `title` in `src/components/AppHeader.vue`:

```vue
<span class="open-count" :title="`${board.highPriorityOpenCount} high priority`">
  {{ board.openCount }} open
</span>
```

Hovering over the badge shows the tooltip. With "Set up hosting" open and "Write project brief" done after moving four cards forward:

```text
before reset: header: 2 open | tooltip: 1 high priority
```

A getter in the store is available to every component, so the board page could show the same number without calculating it again.

**Solution for Exercise 3:**

The test "does another component need it?" sorts the state cleanly:

- **The cards** belong in the store. The board, the detail page, the home page, and the header all need them, and they must always agree.
- **The search text and the priority filter** stay local. Only the board uses them, and another page should not suddenly show a filtered view. (If you later wanted the filter to survive navigation, moving it into the store would be a reasonable choice.)
- **`showForm` and `editingCard`** stay local. They describe what the board page is showing right now.
- **The status message** stays local. It describes the last action on the board page.

A common beginner mistake, often repeated by AI tools, is to put every ref into a store "just in case". That makes components harder to understand and reuse, because their behavior depends on hidden global state. Keep state as local as possible, and lift it into a store only when it is truly shared. Undo the changes from Exercises 1 and 2 before the next lesson, so your code matches Lesson 20.

---

## 9. Props, Composables, or a Store?

You now know three ways to give components data. Here is how to choose:

| Situation | Tool |
| --- | --- |
| A parent passes data to a direct child | Props (and events back up) |
| Several components need the same **kind** of logic, each with its own state | A composable, such as `useFetchJson` |
| Several components need the **same** state, at the same time | A Pinia store, such as `useBoardStore` |

The difference between the last two rows is the key. Every call to a composable creates new state; every call to `useBoardStore()` returns the one shared store. In fact, a setup store is written like a composable, and the store you wrote even uses one inside. Pinia adds the sharing, the DevTools integration, and a clear convention: state, getters, and actions in one file per topic.

Pinia also supports a second style, **option stores**, which you will see in older code and in AI-generated code:

```javascript
export const useCounterStore = defineStore("counter", {
  state: () => ({ count: 0 }),
  getters: {
    double: (state) => state.count * 2,
  },
  actions: {
    increment() {
      this.count++;
    },
  },
});
```

`state` returns the initial state, `getters` are like computed properties, and `actions` are methods that use `this`. Both styles create the same kind of store, and components use them in exactly the same way.

---

## Next Up - Lesson 20

In this lesson you moved Tasklane's cards into a Pinia store. You installed Pinia, defined `useBoardStore` with state, getters, and actions, used it on the board, the detail page, the home page, and in the header, and saw the header badge finally follow every change. You also learned why destructuring a store breaks reactivity and how `storeToRefs` fixes it. That completes Module 6: Tasklane is a complete multi-page app.

In Module 7, you put everything you learned to work on code you did not write. In Lesson 20, you will read an AI-generated Vue component piece by piece, map every part to a concept from this course, and decide what to keep, simplify, or rewrite.
