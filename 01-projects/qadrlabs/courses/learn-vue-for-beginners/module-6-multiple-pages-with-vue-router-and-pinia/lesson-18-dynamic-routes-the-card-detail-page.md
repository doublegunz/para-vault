## 1. Before You Begin

In Lesson 17, Tasklane got real pages: Home, Board, About, and a "not found" page, each with its own address. Every one of those routes has a fixed path. But some pages come in many versions: a web shop does not have one route per product; it has one product page that shows whichever product the address names, such as `/products/42`.

In this lesson every Tasklane card gets its own page in exactly that way. You will create a **dynamic route**, `/cards/:id`, read the id from the address with `useRoute`, and build a card detail page that shows the card's column, priority, due date, and description, with buttons to mark it as done or delete it. Clicking a card on the board will open its page, using `useRouter` to navigate in code. At the end, you will add an open-cards counter to the header and discover a problem with how the pages share data, which Lesson 19 will solve.

### What You'll Build

Clicking anywhere on a card (except its buttons) opens `/cards/<id>`, for example `/cards/4` for "Set up hosting". The page shows the card's details in a white panel, with "Mark as done" and "Delete card" buttons and a link back to the board. Deleting a card returns you to the board automatically. An address with an id that does not exist shows "Card not found". The header shows a small "4 open" badge.

### What You'll Learn

- ✅ What dynamic routes and route parameters are
- ✅ How to read route parameters with `useRoute`
- ✅ Why route parameters are strings, and how to compare them with numeric ids
- ✅ How to navigate in code with `useRouter` and `router.push`
- ✅ How to link to a named route with parameters
- ✅ How to handle a parameter that does not match any data

### What You'll Need

- The Tasklane project from Lesson 17, with the development server running
- Your browser open at `http://localhost:5173/board`

---

## 2. Create the Card Detail Page

A dynamic route has a **parameter** in its path, written with a colon: `/cards/:id`. The route matches `/cards/1`, `/cards/4`, or `/cards/anything`, and the matched part is available to the page as `id`.

### Step 1: Create CardDetailView

Create `src/views/CardDetailView.vue` with this code.

```vue
<script setup>
import { computed } from "vue";
import { RouterLink, useRoute, useRouter } from "vue-router";
import { useLocalStorage } from "../composables/useLocalStorage.js";
import { columns, sampleCards } from "../data/board.js";
import { isOverdue } from "../utils/dates.js";

const route = useRoute();
const router = useRouter();
const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));

const card = computed(() => cards.value.find((card) => card.id === Number(route.params.id)));
const columnTitle = computed(
  () => columns.find((column) => column.status === card.value.status).title,
);

function markAsDone() {
  card.value.status = "done";
}

function deleteCard() {
  cards.value = cards.value.filter((item) => item.id !== card.value.id);
  router.push({ name: "board" });
}
</script>

<template>
  <section class="detail">
    <RouterLink to="/board">&larr; Back to the board</RouterLink>

    <template v-if="card">
      <h2>{{ card.title }}</h2>
      <dl>
        <dt>Column</dt>
        <dd>{{ columnTitle }}</dd>
        <dt>Priority</dt>
        <dd class="priority">{{ card.priority }}</dd>
        <dt>Due date</dt>
        <dd>
          {{ card.dueDate === "" ? "No due date" : card.dueDate }}
          <strong v-if="isOverdue(card)">(overdue)</strong>
        </dd>
        <dt>Description</dt>
        <dd>{{ card.description === "" ? "No description." : card.description }}</dd>
      </dl>
      <div class="actions">
        <button v-if="card.status !== 'done'" type="button" class="primary" @click="markAsDone">
          Mark as done
        </button>
        <button type="button" class="danger" @click="deleteCard">Delete card</button>
      </div>
    </template>

    <template v-else>
      <h2>Card not found</h2>
      <p>There is no card with the id {{ route.params.id }}. It may have been deleted.</p>
    </template>
  </section>
</template>

<style scoped>
.detail {
  max-width: 640px;
  padding: 16px 24px;
  background-color: #ffffff;
  border-radius: 12px;
}

dl {
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 8px 16px;
}

dt {
  font-weight: 600;
}

dd {
  margin: 0;
}

.priority {
  text-transform: capitalize;
}

strong {
  color: #dc2626;
}

.actions {
  display: flex;
  gap: 8px;
}

.danger {
  color: #b91c1c;
}
</style>
```

There are two new functions from Vue Router at the top of the script:

- `useRoute()` returns the **current route**: a reactive object with information about the address, such as `route.path` and `route.params`. For the address `/cards/4`, `route.params.id` is `"4"`.
- `useRouter()` returns the **router** itself, the object that can change pages. It is the same router you created in `router/index.js`.

They are easy to mix up, so remember: `route` describes where you are, `router` takes you somewhere else.

The rest of the script:

- `cards` reads the saved board with `useLocalStorage`, exactly like the home page does.
- `card` finds the card whose id matches the parameter. `Number(route.params.id)` matters: parameters always arrive as **strings**, because they come from text in the address, while the card ids are numbers. `"4" === 4` is false. Section 6 shows what happens without the conversion.
- Because `card` is computed and reads `route.params.id`, it updates by itself if the parameter changes while the page is open. You will use that in Exercise 1.
- `columnTitle` turns the card's status into its column title.
- `markAsDone()` changes the card's status. The card object lives inside the `cards` ref, so the change is reactive and saved by `useLocalStorage`.
- `deleteCard()` removes the card and then calls `router.push({ name: "board" })`, which navigates to the board in code, like clicking a `RouterLink` would. There is nothing left to show on this page after deleting, so leaving it is the natural next step.

In the template, `<template v-if="card">` shows the details when the card exists, and `<template v-else>` shows "Card not found" when it does not, for example after the card was deleted or when someone types a wrong id. The details use a **description list**: `<dl>` with pairs of `<dt>` (term) and `<dd>` (description), the HTML element for label and value pairs. The `dl` rule lays the pairs out in a two-column grid.

### Step 2: Add the Route

Open `src/router/index.js`, import the new view, and add a route between `/board` and `/about`:

```javascript
import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import BoardView from "../views/BoardView.vue";
import AboutView from "../views/AboutView.vue";
import CardDetailView from "../views/CardDetailView.vue";
import NotFoundView from "../views/NotFoundView.vue";

const routes = [
  { path: "/", name: "home", component: HomeView },
  { path: "/board", name: "board", component: BoardView },
  { path: "/cards/:id", name: "card", component: CardDetailView },
  { path: "/about", name: "about", component: AboutView },
  { path: "/:pathMatch(.*)*", name: "not-found", component: NotFoundView },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});
```

`/cards/:id` is the dynamic route. Its name, `"card"`, lets other code navigate to it without building the path by hand. Save both files and open `http://localhost:5173/cards/4` directly. The detail page for "Set up hosting" appears.

---

## 3. Open a Card from the Board

In Lesson 8, clicking a card ran `showDetails()`, which only printed the card's id and title in the console. Now it can open the card's page.

### Step 1: Navigate with router.push

In `src/components/TaskCard.vue`, import `useRouter`, create the router, and replace `showDetails`. Here is the complete `<script setup>` block:

```vue
<script setup>
import { useRouter } from "vue-router";
import { isOverdue } from "../utils/dates.js";

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["move", "edit", "delete"]);
const router = useRouter();

function showDetails() {
  router.push({ name: "card", params: { id: props.card.id } });
}
</script>
```

`router.push({ name: "card", params: { id: props.card.id } })` navigates to the route named `card` and fills in its `id` parameter, producing the address `/cards/4` for card 4. You could also write `` router.push(`/cards/${props.card.id}`) ``, but the named form keeps working even if the path changes later.

The card's buttons still use `@click.stop` from Lesson 8, so clicking "Next →" moves the card without opening its page. To make it obvious that the rest of the card is clickable, add `cursor: pointer;` to the `.card` rule in the style block:

```css
.card {
  cursor: pointer;
  margin-bottom: 12px;
  padding: 12px 16px;
  background-color: #ffffff;
  border-radius: 8px;
  border-left: 4px solid transparent;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.08);
}
```

Save the file.

### Step 2: Try the Whole Flow

Delete the `tasklane-cards` key in the Application tab, open `http://localhost:5173/board`, and click the title of "Set up hosting".

The address and the text of the page:

```text
-- clicked card 4: URL /cards/4
← Back to the board
Set up hosting
Column
In Progress
Priority
High
Due date
2026-10-28 (overdue)
Description
No description.
Mark as done
Delete card
```

Click "Mark as done":

```text
-- after Mark as done:
← Back to the board
Set up hosting
Column
Done
Priority
High
Due date
2026-10-28
Description
No description.
Delete card
```

The column changed to Done, the overdue warning disappeared because done cards are never overdue, and the "Mark as done" button is gone. Click "Back to the board":

```text
-- back to board: URL /board | To Do (2) | In Progress (1) | Done (3)
```

The board shows the change, because it loaded the saved cards when it was created. Now click "Next →" on "Collect logo files". The card moves, and the address stays the same, because `.stop` keeps the click away from the card:

```text
-- clicked Next on card 2: URL /board
```

Open `http://localhost:5173/cards/2` and click "Delete card":

```text
-- after Delete card: URL /board | To Do (1) | In Progress (1) | Done (3)
```

`router.push` took you back to the board, and the card is gone. Finally, press the browser's back button, which returns to `/cards/2`:

```text
-- back button: URL /cards/2
← Back to the board
Card not found

There is no card with the id 2. It may have been deleted.
```

The page handles a missing card gracefully instead of crashing.

---

## 4. Spot a Problem with Separate Copies

The home page, the board, and now the detail page each call `useLocalStorage("tasklane-cards", ...)`, and each call creates **its own** ref. So far that worked, because only one of those pages is on the screen at a time, and each new page reads the latest saved data when it is created. Something always visible, like the header, breaks that assumption.

### Step 1: Add an Open Count to the Header

Users would like to see how many cards are still open from any page. Update the `<script setup>` block of `src/components/AppHeader.vue`:

```vue
<script setup>
import { computed } from "vue";
import { RouterLink } from "vue-router";
import { useLocalStorage } from "../composables/useLocalStorage.js";
import { sampleCards } from "../data/board.js";

defineProps({
  tagline: {
    type: String,
    default: "Plan your work, one card at a time.",
  },
});

const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));
const openCount = computed(() => cards.value.filter((card) => card.status !== "done").length);
</script>
```

Add a badge at the end of the `<nav>`:

```vue
<nav>
  <RouterLink to="/">Home</RouterLink>
  <RouterLink to="/board">Board</RouterLink>
  <RouterLink to="/about">About</RouterLink>
  <span class="open-count">{{ openCount }} open</span>
</nav>
```

And a style for it, before the `nav a.router-link-exact-active` rule:

```css
.open-count {
  align-self: center;
  margin-left: 8px;
  padding: 2px 10px;
  border-radius: 999px;
  background-color: #e0e7ff;
  color: #3730a3;
  font-size: 14px;
  font-weight: 600;
}
```

Save the file.

### Step 2: Watch the Badge Fall Behind

Delete the `tasklane-cards` key, open `http://localhost:5173/board`, and compare the header badge with the board's stats line while you move cards to Done.

The header badge and the stats line after each step:

```text
start                              | header: 4 open | stats: 2 of 6 cards done (33%), 1 overdue
after moving card 3 to Done        | header: 4 open | stats: 3 of 6 cards done (50%), 1 overdue
after moving card 4 to Done        | header: 4 open | stats: 4 of 6 cards done (67%), 0 overdue
after a page refresh               | header: 2 open | stats: 4 of 6 cards done (67%), 0 overdue
```

The board's stats update with every move, but the header stays at "4 open" until you refresh the page. `AppHeader` and `BoardView` each have their own `cards` ref. The board changes its ref and saves it to `localStorage`, but nothing tells the header's ref that the saved data changed. `localStorage` is storage, not a messenger.

This is a classic problem in growing apps: several components need the **same** state, at the same time, and must stay in sync. Passing it down with props from `App.vue` would work, but `App.vue` only renders `RouterView`, and threading props through the router to every page gets messy fast. The proper tool is a **store**: one shared place for state that every component can use directly. You will create one with Pinia in Lesson 19, and the badge will follow every move. Leave the badge as it is for now.

---

## 5. Run and Test

Restart the development server and check the following:

1. Clicking a card's title or body on the board opens `/cards/<id>` with the right details.
2. Clicking a card's buttons does not open its page.
3. "Mark as done" moves the card to Done and hides itself.
4. "Delete card" removes the card and returns to the board.
5. An unknown id, such as `/cards/99`, shows "Card not found".
6. The header badge shows the number of open cards when the page loads (and falls behind after changes, which Lesson 19 fixes).

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

## 6. Fix the Errors in Your Code

These are the most common mistakes with dynamic routes.

**Error 1: Comparing a string parameter with a number.**

```javascript
// Wrong
const card = computed(() => cards.value.find((card) => card.id === route.params.id));

// Correct
const card = computed(() => cards.value.find((card) => card.id === Number(route.params.id)));
```

With the wrong version, every card page says the card does not exist:

```text
URL: /cards/4
← Back to the board
Card not found

There is no card with the id 4. It may have been deleted.
```

`route.params.id` is the string `"4"`, and `4 === "4"` is false, so `find` never matches. Convert parameters to the type of your data before comparing. This bug is especially sneaky because the message shows "4", which looks exactly like the id you expect.

**Error 2: Using `useRouter` where you need `useRoute`.**

```javascript
// Wrong
const route = useRouter();

// Correct
const route = useRoute();
```

With the wrong version, opening `/cards/4` shows a blank page, and the console reports:

```text
[Vue warn]: Unhandled error during execution of render function 
  at <CardDetailView onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouterView > 
  at <App>
[Vue warn]: Unhandled error during execution of component update 
  at <RouterView > 
  at <App>
TypeError: Cannot read properties of undefined (reading 'id')
```

The router object has no `params`, so `route.params` is `undefined`, and reading `.id` from it fails. The names differ by a single letter, which makes this one of the most common Vue Router mistakes, by people and AI tools alike. `useRoute` for reading the current address, `useRouter` for going somewhere.

**Error 3: Passing the parameter outside `params`.**

```javascript
// Wrong
router.push({ name: "card", id: props.card.id });

// Correct
router.push({ name: "card", params: { id: props.card.id } });
```

With the wrong version, clicking a card does nothing visible, and the console shows:

```text
[Vue warn]: Unhandled error during execution of native event handler 
  at <TaskCard key=4 card= Object onMove=fn  ... > 
  at <BoardColumn key="in-progress" title="In Progress" color="#f59e0b"  ... > 
  at <BoardView onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouterView > 
  at <App>
Error: Missing required param "id"
```

The route `/cards/:id` cannot be built without an `id`, and Vue Router only looks for it inside the `params` object. The same applies to `RouterLink`'s `:to` object.

---

## 7. Exercises

**Exercise 1:** Add "previous" and "next" links at the bottom of the card detail page, which lead to the card before and after the current one in the `cards` array, showing their titles. Hide a link when there is no card in that direction. When you click one, the address changes but Vue reuses the same `CardDetailView`. Does the page update?

**Exercise 2:** On the home page, show a "Most urgent" line with a link to the first open card with high priority, for example `Most urgent: Write project brief`. Hide the line when there is no such card.

**Exercise 3:** At the moment, `/cards/abc` matches the card route and shows "Card not found". Restrict the parameter to digits by writing the path as `/cards/:id(\\d+)`, so that addresses with a non-numeric id show the "Page not found" page instead.

---

## 8. Solutions

**Solution for Exercise 1:**

Add three computed properties to `src/views/CardDetailView.vue`, after `columnTitle`:

```javascript
const cardIndex = computed(() =>
  cards.value.findIndex((item) => item.id === Number(route.params.id)),
);
const previousCard = computed(() => cards.value[cardIndex.value - 1]);
const nextCard = computed(() => cards.value[cardIndex.value + 1]);
```

Add the links after the actions, still inside `<template v-if="card">`:

```vue
<nav class="pager">
  <RouterLink v-if="previousCard" :to="{ name: 'card', params: { id: previousCard.id } }">
    &larr; {{ previousCard.title }}
  </RouterLink>
  <RouterLink v-if="nextCard" :to="{ name: 'card', params: { id: nextCard.id } }">
    {{ nextCard.title }} &rarr;
  </RouterLink>
</nav>
```

And a style rule:

```css
.pager {
  display: flex;
  justify-content: space-between;
  margin-top: 16px;
}
```

`findIndex` returns the position of the current card. Reading position `-1` or one past the end of an array gives `undefined`, so `v-if` hides the link at either end. On `/cards/3`, the links read:

```text
← Collect logo files
Set up hosting →
```

Clicking "Set up hosting →":

```text
after clicking next: URL /cards/4 | title: Set up hosting | pager: ← Design home page
Pick color palette →
```

The page did update. Vue Router reused the same `CardDetailView` instance, because the route is the same and only the parameter changed, so `onMounted` would not run again. But `card`, `cardIndex`, `previousCard`, and `nextCard` are computed properties that read `route.params.id`, and `route` is reactive, so they all recalculated. Reading parameters in computed properties, instead of copying them once into a variable, is what makes this work.

**Solution for Exercise 2:**

In `src/views/HomeView.vue`, add a computed property after `openCount`:

```javascript
const urgentCard = computed(() =>
  cards.value.find((card) => card.priority === "high" && card.status !== "done"),
);
```

And a paragraph before the "Open the board" link:

```vue
<p v-if="urgentCard">
  Most urgent:
  <RouterLink :to="{ name: 'card', params: { id: urgentCard.id } }">
    {{ urgentCard.title }}
  </RouterLink>
</p>
```

With the sample cards, the paragraphs of the home page read:

```text
Tasklane keeps your work in three columns: To Do, In Progress, and Done. Add a card for every task, move it forward as you work, and watch the board empty out. / You have 4 open cards on your board. / Most urgent: Write project brief
```

Clicking the link opens `/cards/1`. `find` returns the first match in the array, or `undefined` when there is none, which hides the paragraph.

**Solution for Exercise 3:**

Change the route in `src/router/index.js`:

```javascript
{ path: "/cards/:id(\\d+)", name: "card", component: CardDetailView },
```

The part in parentheses is a regular expression that the parameter must match. `\d+` means "one or more digits", and the backslash is doubled because it sits inside a JavaScript string. Now `/cards/abc` no longer matches this route and falls through to the catch-all:

```text
-- Ex3 /cards/abc: Page not found
/cards/99: Card not found
```

`/cards/99` is a valid address for a card that does not exist, so it still shows the friendlier "Card not found". Undo these exercise changes before the next lesson, so your code matches Lesson 19.

---

## 9. Reading the Current Route

`useRoute()` gives you more than `params`. These are the properties you will use most:

| Property | For the address `/cards/4?tab=notes#top` |
| --- | --- |
| `route.path` | `"/cards/4"` |
| `route.params` | `{ id: "4" }` |
| `route.query` | `{ tab: "notes" }`, from the part after `?` |
| `route.hash` | `"#top"` |
| `route.name` | `"card"` |
| `route.fullPath` | `"/cards/4?tab=notes#top"` |

And these are the most common ways to navigate with `useRouter()`:

| Code | Effect |
| --- | --- |
| `router.push("/board")` | Go to a path, adding an entry to the history |
| `router.push({ name: "card", params: { id: 4 } })` | Go to a named route with parameters |
| `router.replace({ name: "board" })` | Go somewhere without adding a history entry, so "back" skips the current page |
| `router.back()` | Go back one page, like the browser's back button |

Two habits keep dynamic pages robust: always convert parameters to the type your data uses, and always handle the case where no data matches the parameter, because anyone can type any address.

---

## Next Up - Lesson 19

In this lesson you gave every card its own page. You created the dynamic route `/cards/:id`, read the parameter with `useRoute`, converted it to a number, navigated in code with `router.push`, and handled missing cards. You also added an open-cards badge to the header and saw it fall behind the board, because each component kept its own copy of the cards.

In Lesson 19, you will fix that for good. You will install Pinia, Vue's official state management library, and move the cards and every action on them into a single store that the board, the detail page, the home page, and the header all share.
