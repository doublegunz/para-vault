## 1. Before You Begin

In Lesson 20, you read an AI-generated component piece by piece, tested its edges, and improved it. That component mostly worked; it needed a simplification and one small fix. Generated code is not always that kind. Sometimes it looks complete and confident, renders something reasonable at first glance, and hides several real bugs that only show up when you use the feature, check the console, or look at another page.

In this lesson you will add a generated **Statistics** page to Tasklane that contains four of the bugs AI tools produce most often in Vue code: a runaway watcher, a missing `key`, a child component that mutates its prop, and state that lost its reactivity. You will find them with the linter, the browser console, and careful testing, fix them one at a time, and finish with a review checklist you can use on any generated code. Every one of these bugs is a mistake you already met in an earlier lesson; this time, you have to find them yourself.

### What You'll Build

A "Stats" page at `/stats`, linked from the navigation bar. It shows a summary line such as `2 of 6 cards done (33%)`, the number of cards in each column, the open cards sorted by priority, and a "Finish all in-progress cards" button. After your fixes, the page has no console errors, passes the linter, updates every number when you click the button, and leaves the order of the cards on the board untouched.

### What You'll Learn

- ✅ How to review generated code before and after running it
- ✅ Why both linters must pass, and how to run ESLint on its own
- ✅ How to recognize and fix a watcher that keeps triggering itself
- ✅ How a child that sorts its prop in place changes the parent's data
- ✅ How destructuring a store freezes values, and how to spot it in a running app
- ✅ Why silencing the linter or guarding a broken watcher hides bugs instead of fixing them
- ✅ A checklist for reviewing AI-generated Vue code

### What You'll Need

- The Tasklane project from Lesson 20, with the development server running
- Your browser open at `http://localhost:5173`, with the developer tools console open

---

## 2. Add the AI-Generated Statistics Page

Imagine you asked an AI assistant, with the context from Lesson 20's prompt, for "a statistics page with a summary, the number of cards per column, the open cards sorted by priority, and a button that finishes all in-progress cards". The two files below are an example of the kind of code you might get back. They were written for this course to contain typical mistakes; your assistant's answer would differ.

### Step 1: Create the Page and Its Component

Create `src/views/StatsView.vue` with the generated code exactly as it is:

```vue
<script setup>
import { ref, watch } from "vue";
import PriorityList from "../components/PriorityList.vue";
import { columns } from "../data/board.js";
import { useBoardStore } from "../stores/board.js";

const board = useBoardStore();
const { cards, doneCount } = board;

const summary = ref({ total: cards.length, done: doneCount, percent: 0 });

watch(
  summary,
  (value) => {
    summary.value = { ...value, percent: Math.round((value.done / value.total) * 100) };
  },
  { deep: true, immediate: true },
);

function finishInProgress() {
  for (const card of cards) {
    if (card.status === "in-progress") {
      board.updateCard(card.id, { status: "done" });
    }
  }
}
</script>

<template>
  <section class="stats-page">
    <h2>Statistics</h2>
    <p class="summary">
      {{ summary.done }} of {{ summary.total }} cards done ({{ summary.percent }}%)
    </p>

    <h3>Cards per column</h3>
    <ul>
      <li v-for="column in columns">
        {{ column.title }}: {{ cards.filter((card) => card.status === column.status).length }}
      </li>
    </ul>

    <h3>Open cards by priority</h3>
    <PriorityList :cards="cards" />

    <button type="button" @click="finishInProgress">Finish all in-progress cards</button>
  </section>
</template>

<style scoped>
.stats-page {
  max-width: 640px;
  padding: 16px 24px;
  background-color: #ffffff;
  border-radius: 12px;
}

.summary {
  font-weight: 600;
}
</style>
```

And create `src/components/PriorityList.vue`:

```vue
<script setup>
import { computed } from "vue";

const props = defineProps({
  cards: {
    type: Array,
    required: true,
  },
});

const order = { high: 0, medium: 1, low: 2 };

const openCards = computed(() =>
  props.cards
    .sort((a, b) => order[a.priority] - order[b.priority])
    .filter((card) => card.status !== "done"),
);
</script>

<template>
  <ol>
    <li v-for="card in openCards" :key="card.id">
      <strong>{{ card.priority }}</strong> {{ card.title }}
    </li>
  </ol>
</template>
```

Before going further, skim both files with what you know. Most of it looks familiar: a store, a computed property, `v-for`, a prop, a click handler. Nothing looks obviously wrong at a glance, and that is exactly why a structured review matters.

### Step 2: Add the Route and the Link

In `src/router/index.js`, import the view and add a route before `/about`:

```javascript
import StatsView from "../views/StatsView.vue";
```

```javascript
{ path: "/stats", name: "stats", component: StatsView },
```

And in `src/components/AppHeader.vue`, add a link after "Board":

```vue
<RouterLink to="/board">Board</RouterLink>
<RouterLink to="/stats">Stats</RouterLink>
```

Save all four files.

---

## 3. Review Before You Run

The cheapest bugs to fix are the ones a tool finds before you open the browser.

### Step 1: Run the Linters

```bash
npm run lint
```

Output:

```text

> tasklane@0.0.0 lint
> run-s "lint:*"


> tasklane@0.0.0 lint:oxlint
> oxlint . --fix

src/components/PriorityList.vue:14:3: error vue(no-side-effects-in-computed-properties): Unexpected side effect in computed function.
ERROR: "lint:oxlint" exited with 1.
```

Oxlint found a problem in line 14 of `PriorityList.vue`, the `.sort(...)` call, and called it a **side effect in a computed function**. Notice what did not happen: ESLint never ran. `run-s` runs the two linters one after the other and stops at the first failure. So there may be more problems. Run ESLint on its own:

```bash
npm run lint:eslint
```

Output:

```text
> tasklane@0.0.0 lint:eslint
> eslint . --fix --cache


/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/PriorityList.vue
  14:3  error  Unexpected mutation of "cards" prop  vue/no-mutating-props

/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/views/StatsView.vue
  38:7  error  Elements in iteration expect to have 'v-bind:key' directives  vue/require-v-for-key

✖ 2 problems (2 errors, 0 warnings)
```

ESLint confirms the sort problem from a different angle, a **mutation of the `cards` prop**, and finds a second one: the `<li v-for>` in `StatsView.vue` has no `key`. Write down two bugs: "PriorityList sorts its prop" and "missing key".

### Step 2: Open the Page

Linters do not catch everything, so run the page. Delete the `tasklane-cards` key in the Application tab, open `http://localhost:5173/board`, and note the order of the cards in In Progress:

```text
In Progress on the board before visiting Stats: Design home page, Set up hosting
```

Then click "Stats". The page appears and looks plausible:

```text
-- Stats page
Summary: "2 of 6 cards done (33%)"
Columns: To Do: 2 | In Progress: 2 | Done: 2
Priority list: high Write project brief | high Set up hosting | medium Design home page | low Collect logo files
Header badge: 4 open
```

But the console is not empty. It shows warnings and an uncaught error:

```text
[Vue warn]: Unhandled error during execution of app errorHandler
[Vue warn]: Unhandled error during execution of vnode hook 
Uncaught (in promise)
```

The terminal running the development server shows the full message of that error:

```text
[Unhandled rejection] Unknown Error: Maximum recursive updates exceeded in component <StatsView>. This means you have a reactive effect that is mutating its own dependencies and thus recursively triggering itself. Possible sources include component template, render function, updated hook or watcher source function.
```

Vue stopped something that kept triggering itself. Write down bug three: "runaway update in StatsView".

### Step 3: Use the Feature

Click "Finish all in-progress cards":

```text
-- after Finish all in-progress cards
Summary: "2 of 6 cards done (33%)"
Columns: To Do: 2 | In Progress: 0 | Done: 4
Priority list: high Write project brief | low Collect logo files
Header badge: 2 open
```

The columns say four cards are done, the header badge says two are open, and the summary still says `2 of 6 cards done (33%)`. The summary is frozen. That is bug four. Finally, click "Board" and look at the Done column:

```text
-- back on the board: To Do: Write project brief, Collect logo files | Done: Set up hosting, Design home page, Pick color palette, Write About page text
```

"Set up hosting" now comes before "Design home page", the opposite of their order in In Progress before you visited the page. Visiting a statistics page changed the order of the cards on the board, and since the store saves to `localStorage`, the new order was saved too. That is the visible effect of the prop mutation the linters reported.

Your bug list:

1. A runaway watcher in `StatsView`
2. A missing `key` in `StatsView`
3. `PriorityList` sorts its `cards` prop in place
4. The summary does not update

---

## 4. Fix the Bugs One at a Time

Fix one bug, test, then move on. Changing everything at once makes it impossible to tell which change fixed what, or which one broke something else.

### Step 1: Replace the Runaway Watcher

The watcher watches `summary`, and its callback assigns a new object to `summary.value`. That assignment changes the source, which triggers the watcher again, which assigns again: a loop that Vue stops after about a hundred rounds with "Maximum recursive updates exceeded". The deeper problem is the one from Lesson 20: `summary` is derived state, and derived state belongs in a computed property.

In `src/views/StatsView.vue`, change the Vue import and replace the `summary` ref and the whole `watch` with a computed property:

```javascript
import { computed } from "vue";
```

```javascript
const summary = computed(() => ({
  total: cards.length,
  done: doneCount,
  percent: Math.round((doneCount / cards.length) * 100),
}));
```

Save, delete the saved key, and repeat the test from the board. The console stays clean now, and the page shows the same numbers:

```text
-- Stats page
Summary: "2 of 6 cards done (33%)"
Columns: To Do: 2 | In Progress: 2 | Done: 2
Priority list: high Write project brief | high Set up hosting | medium Design home page | low Collect logo files
Header badge: 4 open
```

The other bugs are still there: after "Finish all in-progress cards", the summary still says `2 of 6 cards done (33%)`. That is expected; you have fixed one bug, not four.

### Step 2: Add the Missing Key

Each column has a unique `status`, so use it as the key:

```vue
<li v-for="column in columns" :key="column.status">
```

Nothing changes on the screen, because this list never reorders. But the linter was right to insist: keys are cheap, and a list without them breaks in confusing ways once items are added, removed, or reordered, as Lesson 6 explained.

### Step 3: Stop PriorityList from Sorting Its Prop

`Array.prototype.sort` sorts the array it is called on, in place. In `PriorityList`, that array is `props.cards`, which is the store's `cards` array itself, so the child reordered the parent's data from inside a computed property. The fix is to sort a **new** array. Here, simply filtering first does it, because `filter` returns a new array. Replace `openCards` in `src/components/PriorityList.vue`:

```javascript
const openCards = computed(() =>
  props.cards
    .filter((card) => card.status !== "done")
    .sort((a, b) => order[a.priority] - order[b.priority]),
);
```

The priority list looks the same, but the board is left alone now. Repeat the test, and the Done column keeps the original order after visiting Stats:

```text
-- back on the board: To Do: Write project brief, Collect logo files | Done: Design home page, Set up hosting, Pick color palette, Write About page text
```

Lesson 12's Exercise 2 used the same rule: copy, or filter, before you sort.

### Step 4: Restore Reactivity

`const { cards, doneCount } = board;` destructures the store. `doneCount` became a plain number at that moment, `2`, and it never changes again, which is why the summary froze. `cards` happens to keep working for status changes, because it holds the store's reactive array, but it would freeze too as soon as the store replaced the array, for example after a deletion. Both should come from the store directly, as Lesson 19 showed.

Since the summary only repeats the store's getters, the cleanest fix removes it entirely and reads the getters in the template. The per-column counts also deserve a computed property instead of a `filter` call inside the template. Replace the `<script setup>` block and the `<template>` of `src/views/StatsView.vue`:

```vue
<script setup>
import { computed } from "vue";
import PriorityList from "../components/PriorityList.vue";
import { columns } from "../data/board.js";
import { useBoardStore } from "../stores/board.js";

const board = useBoardStore();

const columnCounts = computed(() =>
  columns.map((column) => ({
    status: column.status,
    title: column.title,
    count: board.cards.filter((card) => card.status === column.status).length,
  })),
);

function finishInProgress() {
  for (const card of board.cards) {
    if (card.status === "in-progress") {
      board.updateCard(card.id, { status: "done" });
    }
  }
}
</script>

<template>
  <section class="stats-page">
    <h2>Statistics</h2>
    <p class="summary">
      {{ board.doneCount }} of {{ board.cards.length }} cards done ({{ board.progress }}%)
    </p>

    <h3>Cards per column</h3>
    <ul>
      <li v-for="column in columnCounts" :key="column.status">
        {{ column.title }}: {{ column.count }}
      </li>
    </ul>

    <h3>Open cards by priority</h3>
    <PriorityList :cards="board.cards" />

    <button type="button" @click="finishInProgress">Finish all in-progress cards</button>
  </section>
</template>
```

Here is what changed:

- The destructuring line and `summary` are gone. The template reads `board.doneCount`, `board.cards.length`, and `board.progress`, the getters the store already calculates.
- `columnCounts` builds one object per column with its count. The template only displays it, and the key is still the column's status.
- `finishInProgress` and `PriorityList` use `board.cards`.

The styles stay the same. Save the file.

---

## 5. Run and Test

Delete the `tasklane-cards` key, open the board, and go through the whole test again:

```text
In Progress on the board before visiting Stats: Design home page, Set up hosting
-- Stats page
Summary: "2 of 6 cards done (33%)"
Columns: To Do: 2 | In Progress: 2 | Done: 2
Priority list: high Write project brief | high Set up hosting | medium Design home page | low Collect logo files
Header badge: 4 open
-- after Finish all in-progress cards
Summary: "4 of 6 cards done (67%)"
Columns: To Do: 2 | In Progress: 0 | Done: 4
Priority list: high Write project brief | low Collect logo files
Header badge: 2 open
-- back on the board: To Do: Write project brief, Collect logo files | Done: Design home page, Set up hosting, Pick color palette, Write About page text
```

All four checks pass: no console errors, the summary follows the button, the header and the page agree, and the board keeps its order. Run the linters:

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

Both linters pass now.

---

## 6. The AI Code Review Checklist

Here is the review you just did, as a checklist you can use on any generated Vue code. Each line names the lesson where you learned the underlying rule.

**Before running**

- [ ] Do all import paths exist, with the right folder names? (Lessons 4 and 20)
- [ ] Does `npm run lint` pass? If Oxlint fails, did you also run `npm run lint:eslint`? (Lessons 2 and 21)
- [ ] Does every `v-for` have a unique, stable `key`, and is there no `v-if` on the same element? (Lesson 6)

**Reactivity**

- [ ] Is every value that can be calculated a `computed`, not a `ref` filled by a `watch`? (Lessons 12 and 20)
- [ ] Does any watcher change its own source? (Lessons 13 and 21)
- [ ] Is a `reactive` object or a store destructured without `storeToRefs`? (Lessons 9 and 19)
- [ ] Is `.value` used in the script and left out in the template, and never used on store state? (Lessons 9 and 20)

**Data ownership**

- [ ] Does any child change a prop, including with `sort`, `push`, `splice`, or `v-model`? (Lessons 5, 11, and 21)
- [ ] Does data change only in the component or store that owns it? (Lessons 11 and 19)

**Behavior**

- [ ] Is the console empty after loading and using the feature?
- [ ] Do the edge cases work: empty lists, zero, one, yesterday, today, tomorrow? (Lesson 20)
- [ ] Do other pages still look and behave the same after using the feature? (Lesson 21)

You can also give this checklist to your AI assistant together with the code and ask it to check each point. The assistant is often good at finding a problem once it is told exactly what to look for. You still verify the result yourself.

---

## 7. Fix the Errors in Your Code

These are the most common **wrong fixes**: changes that make a symptom disappear while the bug stays.

**Error 1: Guarding a runaway watcher instead of removing it.**

```javascript
// Wrong
watch(
  summary,
  (value) => {
    const percent = Math.round((value.done / value.total) * 100);
    if (value.percent !== percent) {
      summary.value = { ...value, percent };
    }
  },
  { deep: true, immediate: true },
);

// Correct
const summary = computed(() => ({
  total: board.cards.length,
  done: board.doneCount,
  percent: board.progress,
}));
```

The guard stops the loop, and the console error disappears. It looks fixed. But with the destructured `doneCount` still in place, clicking "Finish all in-progress cards" gives:

```text
-- Stats page
Summary: "2 of 6 cards done (33%)"
-- after Finish all in-progress cards
Summary: "2 of 6 cards done (33%)"
```

The watcher only ever reacts to its own changes, so the summary is still frozen. A guard like this treats the symptom, the loop, instead of the cause: derived data stored in a ref. When a watcher writes to the value it watches, replace it with a computed property.

**Error 2: Adding `.value` to store values in the template.**

When a value does not update, it is tempting to sprinkle `.value` around:

```vue
<!-- Wrong -->
{{ board.doneCount.value }} of {{ board.cards.length }} cards done ({{ board.progress.value }}%)

<!-- Correct -->
{{ board.doneCount }} of {{ board.cards.length }} cards done ({{ board.progress }}%)
```

With the wrong version, the summary loses its numbers:

```text
Summary: "of 6 cards done (%)"
```

Pinia already unwraps the getters, so `board.doneCount` is a number, and a number has no `value` property. `undefined` renders as nothing. Adding `.value` is never the fix for store values used through the store object.

**Error 3: Silencing the linter.**

Linters accept special comments that turn a rule off for one line. Some AI tools add them to make errors go away:

```vue
<!-- Wrong -->
<!-- eslint-disable-next-line vue/require-v-for-key -->
<li v-for="column in columns">

<!-- Correct -->
<li v-for="column in columns" :key="column.status">
```

With the wrong version, `npx eslint src/views/StatsView.vue` reports nothing and exits successfully. The rule did not stop applying; it stopped being checked. Treat every `eslint-disable` comment in generated code as a question: "what problem is this hiding?" Unless you can explain why the rule is wrong in this specific place, fix the code and delete the comment.

---

## 8. Exercises

**Exercise 1:** Finishing a whole column is a change to the board's data, so it belongs in the store. Add an action `completeColumn(status)` to `useBoardStore` that marks every card with that status as done, remove `finishInProgress` from `StatsView`, and call the action directly from the button.

**Exercise 2:** Add a line `Overdue cards: 1` (with the real number) under the summary on the Stats page, using an existing getter of the store.

**Exercise 3:** Review this generated component without running it, and list every problem you find, with the lesson that explains it:

```vue
<script setup>
const props = defineProps(["cards"]);

function rename(card, title) {
  card.title = title;
}
</script>

<template>
  <ul>
    <li v-for="(card, index) in props.cards" :key="index">
      <input v-model="card.title" @change="rename(card, $event.target.value)" />
    </li>
  </ul>
</template>
```

---

## 9. Solutions

**Solution for Exercise 1:**

Add the action to `src/stores/board.js`, before `moveCard`, and add `completeColumn` to the returned object:

```javascript
function completeColumn(status) {
  for (const card of cards.value) {
    if (card.status === status) {
      card.status = "done";
    }
  }
}
```

In `src/views/StatsView.vue`, delete the `finishInProgress` function and call the action from the button:

```vue
<button type="button" @click="board.completeColumn('in-progress')">
  Finish all in-progress cards
</button>
```

Inside the store's setup function, `cards` is a ref, so the loop uses `cards.value`. The result is the same as before, and any other page can now finish a column with one call.

**Solution for Exercise 2:**

Add the line after the summary paragraph:

```vue
<p>Overdue cards: {{ board.overdueCount }}</p>
```

The paragraphs of the Stats page before and after clicking the button (with Exercise 1 applied):

```text
before: 2 of 6 cards done (33%) / Overdue cards: 1
after: 4 of 6 cards done (67%) / Overdue cards: 0 | Columns: To Do: 2 | In Progress: 0 | Done: 4
```

"Set up hosting" was overdue, and finishing it removed it from the count, because done cards are never overdue. The getter already existed; reusing it keeps the rule for "overdue" in one place.

**Solution for Exercise 3:**

The component has four problems:

1. **It mutates its prop, twice.** `v-model="card.title"` writes directly into an object from the `cards` prop, and `rename` assigns `card.title` as well. The parent's data changes behind its back (Lessons 5 and 11). The component should emit an event such as `rename` with the card's id and the new title, and let the owner of the data, here the store, change it.
2. **The `rename` function is redundant.** `v-model` already wrote the new title before `@change` runs, so `rename` assigns the same value again. Two mechanisms doing one job is a common sign of generated code that was patched until it seemed to work (Lesson 10).
3. **The key is the index.** Inputs hold their own state, such as the cursor position. If a card is removed or the list is reordered, the inputs would be reused for the wrong cards (Lesson 6). Use `:key="card.id"`.
4. **The props are declared as an array.** `defineProps(["cards"])` works, but it has no type and no `required`, so Vue cannot warn you when the wrong data arrives (Lesson 5). Declare `cards` as a required `Array`.

`props.cards` in the template also works, but it is unusual; Vue makes props available in the template by their names. Undo the exercise changes before the next lesson, so your code matches Lesson 22.

---

## Next Up - Lesson 22

In this lesson you reviewed a generated page that looked finished and was not. You ran both linters and learned that Oxlint can stop ESLint from running, read the console and the terminal for the runaway-watcher error, tested the feature and other pages, and fixed four classic bugs one at a time: a watcher that triggered itself, a missing key, a prop sorted in place, and destructured store values that froze. You also learned to recognize wrong fixes and finished with a review checklist. That completes Module 7.

In Lesson 22, the final lesson, you will prepare Tasklane for the world. You will build it for production with `npm run build`, preview the result, look at what Vite produced, learn what a server needs to host a single-page app with Vue Router, and plan your next steps, including adding drag and drop to the board on your own.
