## 1. Before You Begin

Over the last nineteen lessons, you built Tasklane from an empty folder: templates and components, props and events, reactive state and forms, computed properties and watchers, slots, composables, routing, and a Pinia store. You wrote every line yourself, and you know why each one is there. That understanding is exactly what most people who "vibe code" with AI tools are missing, and it is what this module is about.

AI coding assistants are genuinely useful. They can write a new component in seconds, suggest an approach you had not thought of, or explain unfamiliar code. But they write code from patterns, not from your project. They guess at your folder names, your helpers, and your conventions, and they sometimes produce code that looks right and is subtly wrong. In this lesson you will practice the workflow that makes AI help safe: write a clear prompt for a new Tasklane feature, read the code that comes back piece by piece, map every part to a concept you already know, check it against your project, and only then decide what to keep, what to simplify, and what to rewrite.

### What You'll Build

An **Upcoming deadlines** panel on the home page. It lists the open cards that have a due date, soonest first, at most three of them, with a label such as `2 days overdue`, `due today`, `due tomorrow`, or `in 4 days`. Overdue labels are red, and each title links to the card's detail page. The component starts as an example of the kind of code an AI assistant returns for the prompt in this lesson, and ends as a reviewed version that fits Tasklane.

### What You'll Learn

- ✅ How to write a prompt that gives an AI assistant the context it needs
- ✅ A step-by-step method for reading unfamiliar Vue code
- ✅ How to recognize props, refs, computed properties, watchers, stores, and router links in someone else's code
- ✅ How to spot code that works but could be simpler, such as a watcher that copies data a computed property could derive
- ✅ How to test generated code against edge cases
- ✅ How to read the Options API, the older style of Vue components that AI tools still produce

### What You'll Need

- The Tasklane project from Lesson 19, with the development server running
- Optional: access to an AI coding assistant, such as Claude, ChatGPT, GitHub Copilot, or the assistant built into your editor. You can follow the whole lesson without one, using the example response provided.

---

## 2. Write a Clear Prompt

An AI assistant only knows what you tell it. A prompt like "add deadlines to my app" leaves it to guess everything: which framework and style, which files, what the data looks like, and where the result should appear. Every guess is a chance for a mistake. A good prompt has three parts: the **context**, the **task**, and the **constraints**.

### Step 1: Describe the Project Context

Start with the facts about your project that the assistant cannot see:

```text
I'm building Tasklane, a Kanban board, with Vue 3, Vite, Vue Router, and Pinia.
Components use <script setup> with plain JavaScript (no TypeScript) and scoped CSS.

The cards live in a Pinia setup store, src/stores/board.js, exported as useBoardStore.
board.cards is an array of objects like this:
{ id: 4, title: "Set up hosting", description: "", status: "in-progress",
  priority: "high", dueDate: "2026-10-28" }
status is "todo", "in-progress", or "done". dueDate is "YYYY-MM-DD" or "" (no date).
A card detail page exists at the named route "card" with the param id (/cards/:id).
```

Each line removes a guess: the framework and style, where the data comes from and what it looks like, and the route the result can link to.

### Step 2: Describe the Task

Then say exactly what you want, including where it goes:

```text
Create a component UpcomingDeadlines.vue for the home page. It shows the open
cards (status not "done") that have a due date, sorted by due date with the
soonest first, limited to 3 by a prop. Each row shows the card title as a link
to its detail page and a label: "X days overdue", "due today", "due tomorrow",
or "in X days". Overdue rows are highlighted in red.
```

### Step 3: State the Constraints

Finally, add the rules the code must follow:

```text
Keep it to one component file. Do not add any npm packages. Use the existing
store, do not change it. Show a friendly message when nothing is due.
```

Constraints prevent the most common surprises: new libraries you did not ask for, changes to files you did not mention, and a component that breaks when the list is empty.

---

## 3. Read the Response

Below is a complete response of the kind an AI assistant typically returns for this prompt. It is an example written for this course, so your own assistant's answer will differ in details. That is fine: the reading method works for any version.

```vue
<script setup>
import { ref, watch } from "vue";
import { useBoardStore } from "@/stores/board";

const props = defineProps({
  limit: {
    type: Number,
    default: 3,
  },
});

const board = useBoardStore();
const upcoming = ref([]);

watch(
  () => board.cards,
  (cards) => {
    upcoming.value = cards
      .filter((card) => card.dueDate && card.status !== "done")
      .sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate))
      .slice(0, props.limit);
  },
  { immediate: true, deep: true },
);

function daysLeft(dueDate) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const due = new Date(dueDate + "T00:00:00");
  return Math.round((due - today) / 86400000);
}

function label(days) {
  if (days < 0) return `${Math.abs(days)} days overdue`;
  if (days === 0) return "due today";
  if (days === 1) return "due tomorrow";
  return `in ${days} days`;
}
</script>

<template>
  <div class="upcoming">
    <h3>Upcoming deadlines</h3>
    <p v-if="upcoming.length === 0">Nothing due soon. Nice work!</p>
    <ul v-else>
      <li v-for="card in upcoming" :key="card.id" :class="{ late: daysLeft(card.dueDate) < 0 }">
        <router-link :to="`/cards/${card.id}`">{{ card.title }}</router-link>
        <span>{{ label(daysLeft(card.dueDate)) }}</span>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.upcoming {
  margin: 16px 0;
  padding: 16px;
  background: #fff;
  border-radius: 12px;
}

.upcoming h3 {
  margin-top: 0;
}

ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

li {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #e5e7eb;
}

li:last-child {
  border-bottom: none;
}

.late span {
  color: #dc2626;
  font-weight: 600;
}
</style>
```

Do not paste it into your project yet. Read it first, in a fixed order: the imports and inputs, the state and logic, the helper functions, and the template. For each part, ask "which concept from the course is this?"

### Step 1: Read the Imports and the Inputs

```javascript
import { ref, watch } from "vue";
import { useBoardStore } from "@/stores/board";

const props = defineProps({
  limit: {
    type: Number,
    default: 3,
  },
});
```

- `ref` and `watch` are the reactivity tools from Lessons 9 and 13. Seeing `watch` here is a hint that the component reacts to changes by doing something, which you will question in Step 2.
- `@/stores/board` uses the `@` alias. In Lesson 2's tour, `jsconfig.json` and `vite.config.js` defined `@` as a shortcut for `src`, so this import does point to `src/stores/board.js`. The `.js` extension is missing, which Vite allows for JavaScript files. Tasklane's own code uses relative paths with extensions, so this is a style difference, not a bug.
- `defineProps` with `type` and `default` is Lesson 5. The component accepts an optional `limit` prop, as the prompt asked.

### Step 2: Read the State and the Logic

```javascript
const board = useBoardStore();
const upcoming = ref([]);

watch(
  () => board.cards,
  (cards) => {
    upcoming.value = cards
      .filter((card) => card.dueDate && card.status !== "done")
      .sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate))
      .slice(0, props.limit);
  },
  { immediate: true, deep: true },
);
```

- `useBoardStore()` is Lesson 19, used correctly: the store is kept as one object, not destructured.
- `upcoming` is a ref that starts empty, and the watcher fills it. The source `() => board.cards` is a **getter function**, a form of `watch` source you have not used yet: Vue watches whatever the function returns. `immediate: true` runs the callback once right away, so the list is filled before the first render, and `deep: true` reacts to changes inside the cards.
- The chain inside is plain JavaScript from Lessons 1 and 12: `filter` keeps open cards with a due date (an empty string counts as false), `sort` orders them by date, and `slice` keeps the first `limit` items. `sort` is called on the new array that `filter` returned, so it does not reorder the store.

Now ask the key question from Lesson 12: **is `upcoming` derived state?** Yes. It can always be calculated from `board.cards` and `props.limit`. That is the job of `computed`, not of a watcher that copies results into a ref. The watcher version works, but it is longer, it needs two options to behave correctly, and it does not react when the `limit` prop changes, because the watcher only watches `board.cards`. This is one of the most common patterns in AI-generated Vue code. Mark it as "simplify".

### Step 3: Read the Helper Functions

```javascript
function daysLeft(dueDate) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const due = new Date(dueDate + "T00:00:00");
  return Math.round((due - today) / 86400000);
}

function label(days) {
  if (days < 0) return `${Math.abs(days)} days overdue`;
  if (days === 0) return "due today";
  if (days === 1) return "due tomorrow";
  return `in ${days} days`;
}
```

- `daysLeft` counts whole days between today and the due date. `setHours(0, 0, 0, 0)` moves "now" to midnight, and adding `"T00:00:00"` makes JavaScript read the due date as local midnight too. Subtracting two dates gives milliseconds, and `86400000` is the number of milliseconds in a day (24 × 60 × 60 × 1000). Tasklane already has a `today()` helper in `utils/dates.js`, so a similar `daysUntil` helper belongs there.
- `label` turns a number of days into text. Read each branch with a concrete value, and one stands out: for `-1`, it returns `1 days overdue`. Mark it as "fix".
- The one-line `if` statements without braces are valid JavaScript. Tasklane's style always uses braces.

### Step 4: Read the Template

```vue
<li v-for="card in upcoming" :key="card.id" :class="{ late: daysLeft(card.dueDate) < 0 }">
  <router-link :to="`/cards/${card.id}`">{{ card.title }}</router-link>
  <span>{{ label(daysLeft(card.dueDate)) }}</span>
</li>
```

- `v-if` and `v-else` for the empty message, `v-for` with a `:key`, and a class object binding: Lessons 6 and 7.
- `<router-link>` is `RouterLink` from Lesson 17 written in kebab-case. It works because `app.use(router)` registers `RouterLink` as a global component, so it does not need an import. Tasklane imports it and uses PascalCase, so you will align it.
- `` :to="`/cards/${card.id}`" `` builds the path by hand. Your prompt mentioned the named route `card`, and Lesson 17 explained why named routes survive path changes. Mark it as "align with the project".

The reading gave you a short review list: one simplification (watch to computed), one bug (`1 days`), and a few convention changes (imports, `RouterLink`, the named route, braces, a date helper in `utils`).

---

## 4. Check It Against Your Project

Reading tells you what the code does. Running it tells you whether it is right. Add the component exactly as received first, so you can compare it with your improved version later.

### Step 1: Try the Code as Received

Create `src/components/UpcomingDeadlines.vue` with the complete code from Section 3. Then show it on the home page. Update `src/views/HomeView.vue`:

```vue
<script setup>
import { RouterLink } from "vue-router";
import UpcomingDeadlines from "../components/UpcomingDeadlines.vue";
import { useBoardStore } from "../stores/board.js";

const board = useBoardStore();
</script>
```

```vue
<p class="summary">You have {{ board.openCount }} open cards on your board.</p>
<UpcomingDeadlines />
<RouterLink to="/board" class="button-link">Open the board</RouterLink>
```

Save both files, delete the `tasklane-cards` key in the Application tab, and open `http://localhost:5173`. The outputs below were captured on 2026-10-30.

The date of the test, and the text of the panel:

```text
TODAY: 2026-10-30
Upcoming deadlines
Set up hosting
2 days overdue
Write project brief
in 4 days
Design home page
in 8 days
```

The happy path works: three open cards with due dates, soonest first, and "Set up hosting" is red. Its links point to `/cards/4`, `/cards/1`, and `/cards/3`. Run `npm run lint`; it reports no problems. Linters check syntax and common mistakes, not whether the labels make sense.

### Step 2: Test the Edge Cases

AI-generated code is usually tested on the obvious case only. Your job is to try the boundaries. On the board, edit three due dates: "Set up hosting" to yesterday (2026-10-29 in this test), "Write project brief" to today, and "Design home page" to tomorrow. Then open the home page:

```text
Upcoming deadlines
Set up hosting
1 days overdue
Write project brief
due today
Design home page
due tomorrow
```

There is the bug you found while reading: `1 days overdue`. "Due today" and "due tomorrow" are correct. Now move "Set up hosting" to Done and open the home page again:

```text
-- after moving card 4 to Done
Upcoming deadlines
Write project brief
due today
Design home page
due tomorrow
```

Done cards disappear from the list, as they should, thanks to the deep watcher. Only two rows remain, because the other open card, "Collect logo files", has no due date. Use your own dates when you test; what matters is yesterday, today, and tomorrow relative to the day you run it.

---

## 5. Improve the Component

You have a review list and test results. Now rewrite only what needs it, and keep everything else.

### Step 1: Add a daysUntil Helper

Date logic belongs with the other date helpers. Add this function at the end of `src/utils/dates.js`:

```javascript
export function daysUntil(dateText) {
  const due = new Date(`${dateText}T00:00:00`);
  const start = new Date(`${today()}T00:00:00`);
  return Math.round((due - start) / 86400000);
}
```

It does the same calculation as the AI's `daysLeft`, but builds both dates the same way, from `YYYY-MM-DD` text at local midnight, and reuses `today()` from Lesson 7. `Math.round` absorbs the one-hour difference that daylight saving time can add or remove between two dates.

### Step 2: Rewrite the Script and the Template

Replace the `<script setup>` and `<template>` blocks of `src/components/UpcomingDeadlines.vue`, and keep the styles:

```vue
<script setup>
import { computed } from "vue";
import { RouterLink } from "vue-router";
import { useBoardStore } from "../stores/board.js";
import { daysUntil } from "../utils/dates.js";

const props = defineProps({
  limit: {
    type: Number,
    default: 3,
  },
});

const board = useBoardStore();

const upcoming = computed(() =>
  board.cards
    .filter((card) => card.dueDate !== "" && card.status !== "done")
    .sort((a, b) => a.dueDate.localeCompare(b.dueDate))
    .slice(0, props.limit),
);

function dueLabel(dueDate) {
  const days = daysUntil(dueDate);
  if (days < -1) {
    return `${-days} days overdue`;
  }
  if (days === -1) {
    return "1 day overdue";
  }
  if (days === 0) {
    return "due today";
  }
  if (days === 1) {
    return "due tomorrow";
  }
  return `in ${days} days`;
}
</script>

<template>
  <div class="upcoming">
    <h3>Upcoming deadlines</h3>
    <p v-if="upcoming.length === 0">Nothing due soon. Nice work!</p>
    <ul v-else>
      <li v-for="card in upcoming" :key="card.id" :class="{ late: daysUntil(card.dueDate) < 0 }">
        <RouterLink :to="{ name: 'card', params: { id: card.id } }">{{ card.title }}</RouterLink>
        <span>{{ dueLabel(card.dueDate) }}</span>
      </li>
    </ul>
  </div>
</template>
```

Here is what changed, and why:

- **Watch to computed.** `upcoming` is now a computed property. It needs no `immediate` or `deep` option, it is never out of date, and it also reacts when `props.limit` changes. The filter, sort, and slice chain is the same idea as before.
- **The sort compares text.** Dates in `YYYY-MM-DD` format sort correctly as strings, as you learned in Lesson 1, so `localeCompare` replaces creating two `Date` objects per comparison. Both versions give the same order.
- **The empty check is explicit.** `card.dueDate !== ""` says exactly what it means, in the same style as the rest of Tasklane.
- **The bug is fixed.** `dueLabel` handles `-1` separately, so it says `1 day overdue`. Taking the date instead of the number of days also makes the template shorter.
- **Project conventions.** The imports use relative paths with extensions, `RouterLink` is imported and written in PascalCase, the link uses the named route, and every `if` has braces.
- **What stayed.** The prop, the store usage, the template structure, the empty message, the class binding, and all the styles were already good, so they were kept. Reviewing is not rewriting everything.

Save both files.

---

## 6. Run and Test

Delete the `tasklane-cards` key and open the home page:

```text
TODAY: 2026-10-30
Upcoming deadlines
Set up hosting
2 days overdue
Write project brief
in 4 days
Design home page
in 8 days
```

The result is identical to the AI version for the normal case, with the same red highlight and the same links. Now repeat the edge-case test with yesterday, today, and tomorrow:

```text
Upcoming deadlines
Set up hosting
1 day overdue
Write project brief
due today
Design home page
due tomorrow
-- after moving card 4 to Done
Upcoming deadlines
Write project brief
due today
Design home page
due tomorrow
```

The singular form is correct now, and moving a card to Done still updates the list. Run the linters:

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

## 7. Fix the Errors in Your Code

These are integration errors: mistakes that appear when generated code meets your real project, because the assistant guessed something about it.

**Error 1: A guessed import path.**

Assistants often guess folder names from common conventions.

```javascript
// Wrong
import { useBoardStore } from "@/store/board";

// Correct
import { useBoardStore } from "../stores/board.js";
```

With the wrong version, the browser shows this overlay:

```text
[plugin:vite:import-analysis] Failed to resolve import "@/store/board" from "src/components/UpcomingDeadlines.vue". Does the file exist?
```

Tasklane's folder is `stores`, plural, which is also what the Pinia documentation uses, but `store` is common in other projects. Whenever generated code imports something, check that the file really exists at that path.

**Error 2: Treating store state as a ref.**

```javascript
// Wrong
const upcoming = computed(() =>
  board.cards.value
    .filter((card) => card.dueDate !== "" && card.status !== "done")
    .sort((a, b) => a.dueDate.localeCompare(b.dueDate))
    .slice(0, props.limit),
);

// Correct
const upcoming = computed(() =>
  board.cards
    .filter((card) => card.dueDate !== "" && card.status !== "done")
    .sort((a, b) => a.dueDate.localeCompare(b.dueDate))
    .slice(0, props.limit),
);
```

With the wrong version, the home page goes blank, and the console shows warnings followed by:

```text
TypeError: Cannot read properties of undefined (reading 'filter')
```

Inside the store's setup function, `cards` is a ref and needs `.value`. Outside, Pinia unwraps it, so `board.cards` is the array itself and `board.cards.value` is `undefined`. Assistants mix these up because both forms are common. Remember Lesson 19: in components, read store state without `.value`.

**Error 3: Using a prop name without `props.`.**

```javascript
// Wrong
.slice(0, limit),

// Correct
.slice(0, props.limit),
```

With the wrong version, the page goes blank with:

```text
ReferenceError: limit is not defined
```

The template can use a prop by its name, but `<script setup>` cannot: there it lives on the object returned by `defineProps`. The linter catches it, together with the now-unused `props`:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/UpcomingDeadlines.vue
   7:7   error  'props' is assigned a value but never used  no-unused-vars
  20:15  error  'limit' is not defined                      no-undef

✖ 2 problems (2 errors, 0 warnings)
```

Run `npm run lint` on every piece of generated code before you open the browser. It finds this kind of mistake in seconds.

---

## 8. Exercises

**Exercise 1:** Pass `:limit="2"` to `UpcomingDeadlines` on the home page. Then show a small line `and 1 more` under the list (with the real number) when there are more open cards with due dates than the limit allows. Hint: split `upcoming` into two computed properties, one for all matching cards and one for the sliced list.

**Exercise 2:** An assistant gives you this component, written in the Options API. Add it to `src/components/OverdueNotice.vue`, show it on the home page above the deadlines, and check that it works. Then rewrite it with `<script setup>`, so it matches the rest of Tasklane, and check that the output is the same.

```vue
<script>
import { useBoardStore } from "../stores/board.js";
import { isOverdue } from "../utils/dates.js";

export default {
  name: "OverdueNotice",
  computed: {
    overdueCards() {
      return useBoardStore().cards.filter((card) => isOverdue(card));
    },
  },
};
</script>

<template>
  <p v-if="overdueCards.length > 0" class="notice">
    Overdue: {{ overdueCards.map((card) => card.title).join(", ") }}
  </p>
</template>
```

**Exercise 3:** Without running any code, review this line from another generated component and explain the problem: `const { cards } = useBoardStore();`. Which lesson's error does it repeat, and what are two correct ways to write it?

---

## 9. Solutions

**Solution for Exercise 1:**

In `src/views/HomeView.vue`, pass the prop:

```vue
<UpcomingDeadlines :limit="2" />
```

In `src/components/UpcomingDeadlines.vue`, replace `upcoming` with three computed properties:

```javascript
const withDueDate = computed(() =>
  board.cards
    .filter((card) => card.dueDate !== "" && card.status !== "done")
    .sort((a, b) => a.dueDate.localeCompare(b.dueDate)),
);
const upcoming = computed(() => withDueDate.value.slice(0, props.limit));
const remaining = computed(() => withDueDate.value.length - upcoming.value.length);
```

And add the line after the list:

```vue
<p v-if="remaining > 0" class="more">and {{ remaining }} more</p>
```

The panel with the sample cards:

```text
Upcoming deadlines
Set up hosting
2 days overdue
Write project brief
in 4 days

and 1 more
```

Three open cards have a due date, two are shown, and one is left. Computed properties built on other computed properties, as in Lesson 12, keep each step simple. With the original AI version, changing `limit` while the page is open would not have updated the list, because its watcher did not watch the prop.

**Solution for Exercise 2:**

With the Options API version added and `<OverdueNotice />` placed before `<UpcomingDeadlines />` (with its import), the notice reads:

```text
NOTICE: Overdue: Set up hosting
```

Here is the same component with `<script setup>`:

```vue
<script setup>
import { computed } from "vue";
import { useBoardStore } from "../stores/board.js";
import { isOverdue } from "../utils/dates.js";

const board = useBoardStore();
const overdueCards = computed(() => board.cards.filter((card) => isOverdue(card)));
</script>

<template>
  <p v-if="overdueCards.length > 0" class="notice">
    Overdue: {{ overdueCards.map((card) => card.title).join(", ") }}
  </p>
</template>
```

The output is identical:

```text
NOTICE: Overdue: Set up hosting
```

The translation is mechanical: each entry in `computed: { ... }` becomes a `computed(() => ...)`, the store is created once with `useBoardStore()` instead of inside the getter, and `export default` with `name` disappears, because `<script setup>` takes the name from the file. The template does not change at all. Remove the notice afterward if you want your project to match the next lesson; the course does not use it.

**Solution for Exercise 3:**

`const { cards } = useBoardStore();` destructures state from the store, which copies the current array into a plain variable and breaks the connection to the store. It repeats Lesson 19's Error 1, which itself repeats Lesson 9's Error 2 with `reactive`. The component would show the cards from the moment it was created, but replacing the array, for example after deleting a card, would leave it with the old array. Two correct ways:

```javascript
const board = useBoardStore();
// then use board.cards
```

```javascript
const { cards } = storeToRefs(useBoardStore());
// then use cards.value in the script, cards in the template
```

---

## 10. A Method for Reading Any Code

The order you used in Section 3 works for any Vue component, from an AI tool, a colleague, or an open-source project:

1. **Imports and inputs.** What does it depend on, and what does it receive? Check that every import path exists in your project.
2. **State and logic.** For each `ref`, ask "is this real state, or could it be computed?" For each `watch`, ask "is this a side effect, or is it copying derived data?"
3. **Helper functions.** Run each branch in your head with concrete values, especially boundaries such as 0, -1, 1, empty strings, and empty arrays.
4. **Template.** Map each directive to its lesson, and check keys, conditions, and links.
5. **Run it, then test the edges.** The happy path is rarely where bugs hide.

AI tools also often produce the **Options API**, the style Vue used before the Composition API, because there is so much older Vue code online. You do not need to write it, but you should recognize it:

| Options API | Composition API with `<script setup>` |
| --- | --- |
| `data() { return { count: 0 } }` | `const count = ref(0)` |
| `computed: { double() { return this.count * 2 } }` | `const double = computed(() => count.value * 2)` |
| `methods: { increment() { this.count++ } }` | `function increment() { count.value++ }` |
| `watch: { count(newValue) { ... } }` | `watch(count, (newValue) => { ... })` |
| `mounted() { ... }` | `onMounted(() => { ... })` |
| `props: { limit: Number }` and `this.limit` | `const props = defineProps({ limit: Number })` and `props.limit` |
| `this.$emit("save", data)` | `const emit = defineEmits(["save"])` and `emit("save", data)` |

Both styles are official and fully supported, and they can even live in the same project, as in Exercise 2. When an assistant gives you Options API code, you can ask it to rewrite the code with `<script setup>`, or translate it yourself with this table.

---

## Next Up - Lesson 21

In this lesson you practiced reading AI-generated Vue code. You wrote a prompt with context, task, and constraints, read the response in a fixed order, mapped each part to a lesson, ran it, tested its edges, found a pluralization bug, simplified a watcher into a computed property, and aligned the code with Tasklane's conventions. You also learned to recognize and translate the Options API.

In Lesson 21, the code will be more broken. You will add a generated "Statistics" page that contains several of the bugs AI tools produce most often, find them with the linter, the console, and your knowledge of Vue, fix them one at a time, and finish with a review checklist you can use on any generated code.
