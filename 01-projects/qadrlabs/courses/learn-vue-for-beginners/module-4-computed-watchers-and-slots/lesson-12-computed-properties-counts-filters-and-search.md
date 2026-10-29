## 1. Before You Begin

At the end of Module 3, Tasklane became a fully interactive board: you can add, edit, delete, and move cards, and `App.vue` is the single source of truth for all of them. But the board only shows the cards themselves. It does not answer the questions people actually ask when they look at a Kanban board: How far along are we? Is anything overdue? Where is that card about the logo?

All of those answers can be calculated from the cards you already have. In this lesson you will learn **computed properties**, Vue's tool for values that are derived from other reactive state. You will add a progress line such as `2 of 6 cards done (33%), 1 overdue`, and a filter bar with a search box and a priority dropdown that narrows the board as you type. You will also build your first component with `defineModel`, which lets a parent use `v-model` on your own components.

### What You'll Build

A stats line under the board name, `2 of 6 cards done (33%), 1 overdue`, that updates whenever a card moves, is added, or is deleted. Below it, a filter bar with a search box and a priority select. Typing `page` shows only the cards whose title or description contains "page", choosing "High" shows only high-priority cards, and a line such as `Showing 2 of 6 cards.` appears while a filter is active. The column counts follow the filters.

### What You'll Learn

- ✅ What derived state is, and why you should not store it in its own ref
- ✅ How to create computed properties with `computed`
- ✅ How computed properties cache their result, and how that differs from calling a method
- ✅ How computed properties can depend on other computed properties
- ✅ How to filter a list with a search query and a dropdown
- ✅ How to support `v-model` on your own component with `defineModel`

### What You'll Need

- The Tasklane project from Lesson 11, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Show Progress with Computed Properties

Imagine storing "the number of done cards" in its own ref. Every function that changes cards, `saveCard`, `deleteCard`, `moveCard`, and any you write later, would have to remember to update that number too. Forget one, and the number is wrong. The number is **derived state**: it can always be calculated from `cards`, so it should be calculated, not stored.

A computed property does exactly that. You give `computed` a function that calculates a value from reactive state, and Vue keeps the result up to date for you.

### Step 1: Add the Progress Stats

Open `src/App.vue`. Change the first import to include `computed`, add an import for the `isOverdue` helper from Lesson 7, and add three computed properties after the existing refs. Here is the beginning of the `<script setup>` block with these changes; everything from `function cardsFor` onward stays the same for now.

```javascript
import { computed, ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import { columns, sampleCards } from "./data/board.js";
import { isOverdue } from "./utils/dates.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);

const doneCount = computed(() => cards.value.filter((card) => card.status === "done").length);
const progress = computed(() => {
  if (cards.value.length === 0) {
    return 0;
  }
  return Math.round((doneCount.value / cards.value.length) * 100);
});
const overdueCount = computed(() => cards.value.filter((card) => isOverdue(card)).length);
```

Here is what each computed property does:

- `doneCount` counts the cards whose status is `"done"`. The arrow function is the **getter**: Vue runs it to get the value.
- `progress` turns that count into a percentage. It returns `0` when there are no cards, because dividing by zero would produce `NaN`. Notice that it reads `doneCount.value`: a computed property is a ref-like object, so in `<script setup>` you read it through `.value`, exactly like a ref. One computed property can use another.
- `overdueCount` counts the cards for which `isOverdue` returns true, reusing the helper you wrote for the red card edges.

Then show the stats in the template, right after the `<CardForm>` and before the status paragraph:

```vue
<p class="stats">
  {{ doneCount }} of {{ cards.length }} cards done ({{ progress }}%),
  {{ overdueCount }} overdue
</p>
```

As with refs, the template reads computed properties without `.value`. Finally, add a style rule for the stats line to the style block, before `.status`:

```css
.stats {
  margin: 0 0 12px;
  font-weight: 600;
}
```

Save the file.

The stats line and the status line:

```text
2 of 6 cards done (33%), 1 overdue
Use the buttons on a card to move, edit, or delete it.
```

Two of the six sample cards are done, which is 33 percent after rounding. "Set up hosting" is overdue on the date these outputs were captured, 2026-10-29; your number may be higher if you follow the course later.

### Step 2: Watch the Stats Update

Click "Next →" on "Design home page" to move it to Done.

```text
3 of 6 cards done (50%), 1 overdue
Moved "Design home page" from In Progress to Done.
```

You did not touch `moveCard`. It changed `card.status` as before, and every computed property that depends on `cards` recalculated itself. Delete a card or add one, and the stats follow too. That is the point of derived state: it cannot get out of sync, because it is never stored separately.

---

## 3. Filter the Board with Search and Priority

Filtering is derived state as well. "The cards that match the search" can always be calculated from the cards and the search text. So the plan is: store only what the user typed or selected, and compute the visible cards from it.

### Step 1: Create the FilterBar Component

The filter controls get their own component. Its job is to edit two values, the search text and the selected priority, that belong to `App.vue`. In Lesson 11 you learned that a child must never `v-model` a prop. `defineModel` is Vue's official solution for exactly this case: it declares a prop **and** an update event in one line, and returns a ref you can use with `v-model` inside the child.

Create `src/components/FilterBar.vue` with this code.

```vue
<script setup>
const search = defineModel("search", { type: String, default: "" });
const priority = defineModel("priority", { type: String, default: "all" });
</script>

<template>
  <div class="filter-bar">
    <label>
      Search
      <input v-model="search" type="search" placeholder="Search cards..." />
    </label>
    <label>
      Priority
      <select v-model="priority">
        <option value="all">All</option>
        <option value="high">High</option>
        <option value="medium">Medium</option>
        <option value="low">Low</option>
      </select>
    </label>
  </div>
</template>

<style scoped>
.filter-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 12px;
}

label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
}

input,
select {
  padding: 6px 8px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font: inherit;
  font-weight: 400;
}
</style>
```

Here is what the script does:

- `defineModel("search", { type: String, default: "" })` declares a **model** named `search`. Behind the scenes, it creates a prop called `search` and an event called `update:search`. The returned `search` is a ref: reading it gives the parent's value, and assigning to it emits `update:search` with the new value, so the parent updates its own state. The child never changes the prop itself.
- `defineModel("priority", ...)` does the same for the priority, with `"all"` as its default.
- `v-model="search"` and `v-model="priority"` bind the input and the select to those refs, exactly like in Lesson 10's form.
- Like `defineProps`, `defineModel` is a compiler macro, so it needs no import.

The styles place the two controls on one line, and let them wrap onto two lines on narrow screens.

### Step 2: Compute the Visible Cards

Now `App.vue` stores the filter values, passes them to `FilterBar` with `v-model`, and computes the cards to show. Replace the `<script setup>` block of `src/App.vue` from the imports down to `function cardsFor` with this code; the functions after `cardsFor` (`findCard`, `columnTitle`, and the rest) stay exactly as they are.

```javascript
import { computed, ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import FilterBar from "./components/FilterBar.vue";
import { columns, sampleCards } from "./data/board.js";
import { isOverdue } from "./utils/dates.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);
const search = ref("");
const priorityFilter = ref("all");

const doneCount = computed(() => cards.value.filter((card) => card.status === "done").length);
const progress = computed(() => {
  if (cards.value.length === 0) {
    return 0;
  }
  return Math.round((doneCount.value / cards.value.length) * 100);
});
const overdueCount = computed(() => cards.value.filter((card) => isOverdue(card)).length);

const visibleCards = computed(() => {
  const query = search.value.trim().toLowerCase();
  return cards.value.filter((card) => {
    const matchesSearch =
      card.title.toLowerCase().includes(query) || card.description.toLowerCase().includes(query);
    const matchesPriority =
      priorityFilter.value === "all" || card.priority === priorityFilter.value;
    return matchesSearch && matchesPriority;
  });
});
const isFiltering = computed(() => search.value.trim() !== "" || priorityFilter.value !== "all");

function cardsFor(status) {
  return visibleCards.value.filter((card) => card.status === status);
}
```

Here is what is new:

- `FilterBar` is imported.
- `search` and `priorityFilter` are the only new state: exactly what the user typed and chose. Everything else is computed from them.
- `visibleCards` lowercases and trims the search text once, then keeps a card when its title or description contains the text, **and** its priority matches the filter (or the filter is `"all"`). `includes("")` is always true, so an empty search matches every card. Comparing lowercase versions makes the search case-insensitive.
- `isFiltering` is `true` when any filter is active.
- `cardsFor` now starts from `visibleCards.value` instead of `cards.value`, so each column shows only the matching cards. Notice that `doneCount`, `progress`, and `overdueCount` still use `cards`: the stats describe the whole board, no matter what is filtered.

Then add the filter bar and a "Showing" line to the template, between the stats and the status paragraph:

```vue
<p class="stats">
  {{ doneCount }} of {{ cards.length }} cards done ({{ progress }}%),
  {{ overdueCount }} overdue
</p>
<FilterBar v-model:search="search" v-model:priority="priorityFilter" />
<p v-if="isFiltering" class="status">
  Showing {{ visibleCards.length }} of {{ cards.length }} cards.
</p>
<p class="status">{{ message }}</p>
```

`v-model:search="search"` is `v-model` with an argument. It connects `App.vue`'s `search` ref to the child's model named `search`. A component can have several models this way, each with its own name. Save both files.

---

## 4. Run and Test

Restart the development server and open `http://localhost:5173`. The page now shows the stats, the filter bar, and the status line above the board.

```text
2 of 6 cards done (33%), 1 overdue
Use the buttons on a card to move, edit, or delete it.
To Do (2) | In Progress (2) | Done (2)
```

Click "Next →" on "Design home page":

```text
3 of 6 cards done (50%), 1 overdue
Moved "Design home page" from In Progress to Done.
To Do (2) | In Progress (1) | Done (3)
```

Now type `page` in the search box. The board narrows with every letter.

```text
3 of 6 cards done (50%), 1 overdue
Showing 2 of 6 cards.
Moved "Design home page" from In Progress to Done.
To Do (0) | In Progress (0) | Done (2)
```

The two remaining cards are:

```text
Design home page | Write About page text
```

Both contain "page", and both are in Done after the move. The stats line still says `3 of 6`, because it describes the whole board. Replace the search with `PAGE` in capital letters, and the result is identical, because the search is case-insensitive.

Clear the search box and choose "High" in the priority dropdown:

```text
3 of 6 cards done (50%), 1 overdue
Showing 2 of 6 cards.
Moved "Design home page" from In Progress to Done.
To Do (1) | In Progress (1) | Done (0)
```

The remaining cards:

```text
Write project brief | Set up hosting
```

Finally, keep "High" and type `xyz` in the search box. No card matches both filters:

```text
3 of 6 cards done (50%), 1 overdue
Showing 0 of 6 cards.
Moved "Design home page" from In Progress to Done.
To Do (0) | In Progress (0) | Done (0)
```

Every column shows its "No cards here yet." message from Lesson 6. Run the linters too.

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

## 5. See Computed Caching in Action

You could have written `progress` as a normal function and called it in the template as `{{ progressPercent() }}`. The page would look the same. The difference is in how often the code runs, and you can see it with two temporary `console.log` lines.

### Step 1: Compare a Computed Property and a Method

Temporarily add a log line at the top of the `progress` getter in `App.vue`:

```javascript
const progress = computed(() => {
  console.log("computed progress runs");
  if (cards.value.length === 0) {
    return 0;
  }
  return Math.round((doneCount.value / cards.value.length) * 100);
});
```

Add a method that calculates the same value, with its own log line, just before `cardsFor`:

```javascript
function progressPercent() {
  console.log("progressPercent() runs");
  return Math.round((doneCount.value / cards.value.length) * 100);
}
```

And use the method in the template, after the stats paragraph:

```vue
<p>Method: {{ progressPercent() }}%</p>
```

Save the file and reload the page. Then type `p`, `a`, `g`, `e` into the search box, one letter at a time. Finally, clear the search box, clear the console, and click "Next →" on "Design home page".

Output in the console:

```text
-- page loaded
computed progress runs
progressPercent() runs
-- typed 'p', 'pa', 'pag', 'page'
progressPercent() runs
progressPercent() runs
progressPercent() runs
progressPercent() runs
-- moved card 3 to done
computed progress runs
progressPercent() runs
```

The lines starting with `--` were added to separate the three moments. When the page loaded, both ran once. While you typed, the page re-rendered four times, because `search` changed, and the method ran on every render. The computed property did not run at all: its result depends only on `cards`, which did not change, so Vue reused the **cached** value. When a card moved, `cards` changed, and both ran again.

A computed property only recalculates when one of the reactive values it read last time changes. A method runs every time the template renders. For cheap calculations the difference is invisible, but for filtering hundreds of cards, it matters. Use computed properties for derived values, and methods for actions such as `deleteCard`.

Remove the two `console.log` lines, the `progressPercent` function, and the "Method" paragraph before you continue.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with computed properties.

**Error 1: Assigning to a computed property.**

A computed property is calculated, so it is read-only.

```javascript
// Wrong
function moveCard(cardId, direction) {
  // ...the existing code...
  card.status = newStatus;
  progress.value = Math.round((doneCount.value / cards.value.length) * 100);
}

// Correct
function moveCard(cardId, direction) {
  // ...the existing code...
  card.status = newStatus;
}
```

With the wrong version, moving a card shows this warning in the console:

```text
[Vue warn] Write operation failed: computed value is readonly
```

The stats still update correctly, because `progress` recalculates itself from `cards`. The extra line was never needed. If you catch yourself updating a derived value by hand, delete that code and let the computed property do its job.

**Error 2: Forgetting `.value` when one computed property uses another.**

```javascript
// Wrong
return Math.round((doneCount / cards.value.length) * 100);

// Correct
return Math.round((doneCount.value / cards.value.length) * 100);
```

With the wrong version, there is no error, but the stats line shows:

```text
2 of 6 cards done (NaN%), 1 overdue
```

`doneCount` without `.value` is the computed object, not a number, and dividing an object by a number gives `NaN` (Not a Number). Inside `<script setup>`, computed properties follow the same rule as refs: read them with `.value`.

**Error 3: Forgetting `return` in a getter with curly braces.**

An arrow function with curly braces must return its value explicitly.

```javascript
// Wrong
const overdueCount = computed(() => {
  cards.value.filter((card) => isOverdue(card)).length;
});

// Correct
const overdueCount = computed(() => {
  return cards.value.filter((card) => isOverdue(card)).length;
});
```

With the wrong version, the getter returns `undefined`, which the template renders as nothing:

```text
2 of 6 cards done (33%), overdue
```

The linter reports both the missing return and the useless expression:

```text

src/App.vue:25:31: error vue(return-in-computed-property): Expected to return a value in computed property. help: All code paths inside a computed getter must return a value.
src/App.vue:26:3: error eslint(no-unused-expressions): Expected expression to be used help: Consider using this expression or removing it
ERROR: "lint:oxlint" exited with 1.
```

This time the message comes from Oxlint, the first of the two linters. Either add `return`, or remove the curly braces so the arrow function returns its expression automatically, as the original version did.

---

## 7. Exercises

**Exercise 1:** Add a computed property `highPriorityCount` that counts the high-priority cards that are not done yet, and add it to the stats line, so it reads `2 of 6 cards done (33%), 1 overdue, 2 high priority open`.

**Exercise 2:** Sort the cards inside each column by priority: high first, then medium, then low. Do it in `cardsFor`, without changing the order of `cards` itself. Hint: use an object such as `{ high: 0, medium: 1, low: 2 }` to turn priorities into numbers.

**Exercise 3:** Add a "Clear filters" button inside the "Showing ..." paragraph. Clicking it should empty the search box and set the priority back to "All". Because the paragraph has `v-if="isFiltering"`, the button disappears by itself once the filters are cleared.

---

## 8. Solutions

**Solution for Exercise 1:**

Add the computed property next to the others in `src/App.vue`:

```javascript
const highPriorityCount = computed(
  () => cards.value.filter((card) => card.priority === "high" && card.status !== "done").length,
);
```

And extend the stats paragraph:

```vue
<p class="stats">
  {{ doneCount }} of {{ cards.length }} cards done ({{ progress }}%),
  {{ overdueCount }} overdue, {{ highPriorityCount }} high priority open
</p>
```

The stats line:

```text
2 of 6 cards done (33%), 1 overdue, 2 high priority open
```

The getter is written on its own lines only because it is long. Both high-priority sample cards, "Write project brief" and "Set up hosting", are still open.

**Solution for Exercise 2:**

Replace `cardsFor` in `src/App.vue`:

```javascript
const priorityOrder = { high: 0, medium: 1, low: 2 };

function cardsFor(status) {
  return visibleCards.value
    .filter((card) => card.status === status)
    .sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
}
```

`priorityOrder` turns each priority into a number. `sort` calls the comparison function with two cards, and a negative result puts `a` first. Because `filter` already returned a new array, `sort` reorders that new array, not `cards` or `visibleCards`. Sorting the original reactive array in place would change the order of the source of truth and trigger extra updates.

The badge and title of the cards in each column:

```text
HIGH Write project brief, LOW Collect logo files || HIGH Set up hosting, MEDIUM Design home page || MEDIUM Pick color palette, LOW Write About page text
```

"Set up hosting" now comes before "Design home page" in In Progress, because it has a higher priority.

**Solution for Exercise 3:**

Add a function to `src/App.vue`:

```javascript
function clearFilters() {
  search.value = "";
  priorityFilter.value = "all";
}
```

And the button inside the "Showing" paragraph:

```vue
<p v-if="isFiltering" class="status">
  Showing {{ visibleCards.length }} of {{ cards.length }} cards.
  <button type="button" @click="clearFilters">Clear filters</button>
</p>
```

With the search `logo` and the priority Low, the two status paragraphs read:

```text
Showing 1 of 6 cards. Clear filters / Use the buttons on a card to move, edit, or delete it.
```

After clicking "Clear filters", only the message remains, and the search box and the select are reset:

```text
Use the buttons on a card to move, edit, or delete it. | INPUT: "" | SELECT: all
```

`clearFilters` only changes the two refs in `App.vue`. The inputs inside `FilterBar` update by themselves, because `defineModel` keeps them connected to the parent's state in both directions. Undo these exercise changes before the next lesson.

---

## 9. When to Use computed

Here is a quick guide to choosing between the tools you now know:

| You need | Use |
| --- | --- |
| A value the user or your code changes directly (cards, search text, form fields) | `ref` (or `reactive`) |
| A value calculated from other reactive values (counts, percentages, filtered lists) | `computed` |
| Something to do in response to a click or another event (add, delete, move) | A function (method) |
| A calculation that needs an argument, such as one column's cards | A function that reads computed values, like `cardsFor(status)` |

Three rules keep computed properties healthy:

- **Getters should only calculate.** Do not change other state, fetch data, or write to `localStorage` inside a computed getter. Vue may run it at any time, or not at all if the value is cached.
- **Do not change the arrays you read.** Use methods that return new arrays, such as `filter`, `map`, and `slice`, and copy before sorting, as in Exercise 2.
- **Do not store what you can compute.** If a value can always be calculated from existing state, a computed property is safer than a ref that you update by hand.

In Lesson 13 you will meet the tool for the case that computed properties must not handle: doing something, such as saving data, when state changes.

---

## Next Up - Lesson 13

In this lesson you learned computed properties. You derived the done count, the progress percentage, and the overdue count from the cards, built a search and priority filter with a computed `visibleCards` list, created `FilterBar` with `defineModel` so it supports `v-model:search` and `v-model:priority`, and saw in the console how computed properties cache their results while methods run on every render.

There is still one big problem with Tasklane: every refresh throws your work away. In Lesson 13, you will save the board to the browser's `localStorage` with a watcher, load it again when the app starts, and learn the difference between `watch`, `watchEffect`, and lifecycle hooks such as `onMounted`.
