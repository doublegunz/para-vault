## 1. Before You Begin

In Lesson 8, clicking "Next →" or "← Back" on a card sent a `move` event all the way up to `App.vue`, which calculated where the card should go and printed it in the console. The obvious next step is to actually change the card's `status`. In Lesson 1 you did exactly that in the browser console with one line, `card.status = "done"`. So why do the cards still not move?

This lesson answers that question. You will first try the plain JavaScript approach and watch it fail in an instructive way. Then you will learn Vue's **reactivity system**: `ref` and `reactive` create values that Vue tracks, so that every change to them updates the page automatically. With one small change, the cards will start moving between columns, and a status line will tell you what just happened.

### What You'll Build

A working Kanban board. Clicking "Next →" moves a card to the next column, and clicking "← Back" moves it to the previous one. The column counts update instantly. Above the board, a status line describes the last move, for example `Moved "Design home page" from In Progress to Done.`

### What You'll Learn

- ✅ Why changing a normal variable does not update the page
- ✅ What reactive state is, and how Vue re-renders when it changes
- ✅ How to create reactive state with `ref`, and when to use `.value`
- ✅ How to create a reactive object with `reactive`
- ✅ The differences between `ref` and `reactive`, and which one to choose
- ✅ Common ways to lose reactivity by accident

### What You'll Need

- The Tasklane project from Lesson 8, with the development server running
- Your browser open at `http://localhost:5173`, with the developer tools console open

---

## 2. Try Changing the Data Directly

Before learning the solution, it is worth seeing the problem with your own eyes. In this section you will change a card's status the plain JavaScript way.

### Step 1: Change the Status in moveCard

Open `src/App.vue` and replace the `moveCard` function with this version. Leave the rest of the file as it is.

```javascript
function moveCard(cardId, direction) {
  const card = sampleCards.find((card) => card.id === cardId);
  const statuses = columns.map((column) => column.status);
  const index = statuses.indexOf(card.status);
  const newStatus = direction === "next" ? statuses[index + 1] : statuses[index - 1];
  card.status = newStatus;
  console.log(`"${card.title}" is now ${card.status}`);
}
```

The only changes are the last two lines: `card.status = newStatus;` changes the card object, and `console.log` prints the new status to prove it.

### Step 2: Click Next Twice

Save the file, then click "Next →" on "Write project brief" once.

Output in the console:

```text
"Write project brief" is now in-progress
```

The console says the card is in progress. But the board has not changed: "Write project brief" is still in the To Do column, and the headers still read:

```text
To Do (2) | In Progress (2) | Done (2)
```

Now click the same "Next →" button again.

Output in the console:

```text
"Write project brief" is now done
```

The data moved the card to Done, while the screen still shows it in To Do. The data and the page have drifted apart. `sampleCards` is an ordinary JavaScript array. When you change one of its objects, nothing tells Vue that something happened, so Vue has no reason to render the page again. This is the same problem you saw with the plain JavaScript counter in Lesson 1, where forgetting `countText.textContent = count;` left the page out of date.

Refresh the browser to reset the data before you continue.

---

## 3. Make the Cards Reactive with ref

Vue's answer is **reactive state**: values wrapped in a way that lets Vue notice when they are read and when they change. When a template reads reactive state during rendering, Vue remembers that connection. Later, when the state changes, Vue re-renders exactly the components that used it. You do not call any "update" function yourself.

The most common way to create reactive state is `ref`. You already used it in Lesson 1's counter: `const count = ref(0);`.

### Step 1: Wrap the Cards in ref

Replace the `<script setup>` block of `src/App.vue` with this code. The template and styles stay the same.

```vue
<script setup>
import { ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);

function cardsFor(status) {
  return cards.value.filter((card) => card.status === status);
}

function handleNewCard() {
  console.log("New card button clicked");
}

function moveCard(cardId, direction) {
  const card = cards.value.find((card) => card.id === cardId);
  const statuses = columns.map((column) => column.status);
  const index = statuses.indexOf(card.status);
  const newStatus = direction === "next" ? statuses[index + 1] : statuses[index - 1];
  card.status = newStatus;
}
</script>
```

Here is what changed:

- `import { ref } from "vue";` imports `ref` from Vue. Unlike `defineProps` and `defineEmits`, `ref` is a normal function, so it must be imported.
- `const cards = ref(sampleCards);` creates a reactive reference that holds the cards array. From now on, `cards` is Tasklane's **state**: the data that can change while the app runs.
- In `<script setup>`, the array inside a ref is reached through `.value`. That is why `cardsFor` uses `cards.value.filter(...)` and `moveCard` uses `cards.value.find(...)`.
- `card.status = newStatus;` looks exactly like the plain JavaScript version. The difference is that `card` now comes from `cards.value`, so it is a reactive object. Vue sees the assignment.
- The `console.log` is gone, because the board itself now shows the result.

Why `.value`? JavaScript cannot detect when a plain variable is reassigned. So `ref` puts your value inside a small object with a `value` property, and Vue watches that property. When you put an object or an array into a ref, Vue also makes everything inside it reactive, all the way down. That is why changing `card.status`, a property of an object inside the array, is noticed too.

### Step 2: Move Some Cards

Save the file and click "Next →" on "Write project brief" twice, then "← Back" on "Pick color palette". After each click, look at the column headers.

The column headers and the cards in each column, after each click:

```text
-- Next on card 1
To Do (1) | In Progress (3) | Done (2)
Collect logo files || Write project brief, Design home page, Set up hosting || Pick color palette, Write About page text
-- Next on card 1
To Do (1) | In Progress (2) | Done (3)
Collect logo files || Design home page, Set up hosting || Write project brief, Pick color palette, Write About page text
-- Back on card 5
To Do (1) | In Progress (3) | Done (2)
Collect logo files || Design home page, Set up hosting, Pick color palette || Write project brief, Write About page text
```

The cards move, and the counts follow them. Notice that cards appear in each column in the order of the array, not in the order they arrived, which is why "Write project brief" is the first card in Done.

Look at what you did not have to write: no code that finds the right column, no code that removes the card element from one place and inserts it in another, and no code that updates the counts. You changed one property, and Vue figured out the rest by running `cardsFor` again for each column and comparing the result with what was on the screen.

Notice also that the template did not change. In templates, Vue unwraps refs for you, so you never write `.value` there. The rule is simple: **`.value` in `<script setup>`, no `.value` in `<template>`**.

---

## 4. Group Related State with reactive

Tasklane should also tell the user what just happened, for example `Moved "Design home page" from In Progress to Done.` That message needs three pieces of data that belong together: the card title, the old column, and the new column. For a group of related values, Vue offers a second tool: `reactive`.

### Step 1: Create the lastMove Object

Replace the `<script setup>` block of `src/App.vue` again:

```vue
<script setup>
import { reactive, ref } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import { columns, sampleCards } from "./data/board.js";

const boardName = "Website Redesign";
const cards = ref(sampleCards);
const lastMove = reactive({
  title: "",
  from: "",
  to: "",
});

function cardsFor(status) {
  return cards.value.filter((card) => card.status === status);
}

function handleNewCard() {
  console.log("New card button clicked");
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

Here is what is new:

- `reactive` is imported next to `ref`.
- `const lastMove = reactive({ ... })` creates a reactive object with three properties, all starting as empty strings. Unlike a ref, a reactive object is used directly: there is no `.value`. You read and write `lastMove.title` like any normal object.
- `function columnTitle(status)` turns a status such as `"in-progress"` into a readable title such as `"In Progress"`, using the `columns` data.
- In `moveCard`, the three `lastMove` lines record the move before `card.status` changes, while `card.status` still holds the old value.

### Step 2: Show the Status Line

Add a paragraph between the toolbar and the board in the template, and a rule for it in the style block. Here is the complete template and style of `src/App.vue`:

```vue
<template>
  <AppHeader />

  <main>
    <div class="toolbar">
      <h2>{{ boardName }}</h2>
      <button type="button" class="primary" @click="handleNewCard">+ New card</button>
    </div>
    <p class="status">
      <template v-if="lastMove.title !== ''">
        Moved "{{ lastMove.title }}" from {{ lastMove.from }} to {{ lastMove.to }}.
      </template>
      <template v-else>Use the Back and Next buttons to move cards.</template>
    </p>
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

Here is what the new paragraph does:

- Before any move, `lastMove.title` is empty, so the `v-else` template shows a hint: `Use the Back and Next buttons to move cards.`
- After a move, the `v-if` template shows the message built from the three properties.
- The two `<template>` wrappers let `v-if` and `v-else` switch between pieces of text without adding extra elements.

Save the file. The status line first shows the hint.

The status line before any move:

```text
Use the Back and Next buttons to move cards.
```

Click "Next →" on "Write project brief", then "Next →" on "Design home page".

The column headers and the status line after each click:

```text
-- Next on card 1
To Do (1) | In Progress (3) | Done (2)
Moved "Write project brief" from To Do to In Progress.
-- Next on card 3
To Do (1) | In Progress (2) | Done (3)
Moved "Design home page" from In Progress to Done.
```

The status line updates with every move because the template reads `lastMove`'s properties, and `lastMove` is reactive.

---

## 5. Run and Test

Restart the development server and open `http://localhost:5173`. Check the following:

1. The status line shows the hint before you move anything.
2. "Next →" and "← Back" move cards between columns, and the counts update.
3. A card that reaches Done loses its "Next →" button and becomes faded; a card moved back to To Do loses its "← Back" button.
4. The status line describes the last move with readable column names.
5. Refreshing the page puts every card back where it started.

The last point is expected. The state lives in the browser's memory, and a refresh starts the app from `sampleCards` again. In Lesson 13 you will save the board in the browser's storage so that it survives a refresh.

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

These are the most common mistakes with reactive state.

**Error 1: Forgetting `.value` in `<script setup>`.**

Inside `<script setup>`, a ref is an object that holds your value, not the value itself.

```javascript
// Wrong
function cardsFor(status) {
  return cards.filter((card) => card.status === status);
}

// Correct
function cardsFor(status) {
  return cards.value.filter((card) => card.status === status);
}
```

With the wrong version, the whole page is blank, and the console shows:

```text
[Vue warn]: Unhandled error during execution of render function 
  at <App>
TypeError: cards.filter is not a function
    at Proxy.cardsFor (http://localhost:5199/src/App.vue:36:16)
```

`cards` is the ref wrapper, which has no `filter` method; the array is in `cards.value`. When you see "is not a function" or "undefined" on something you created with `ref`, check for a missing `.value`. The port in the address is different on your computer.

**Error 2: Destructuring a reactive object.**

Destructuring copies the current values into new, plain variables. Those copies are not connected to the reactive object anymore.

```vue
<!-- Wrong -->
<script setup>
const lastMove = reactive({
  title: "",
  from: "",
  to: "",
});
const { title, from, to } = lastMove;
</script>

<template>
  <p class="status">
    <template v-if="title !== ''">
      Moved "{{ title }}" from {{ from }} to {{ to }}.
    </template>
    <template v-else>Use the Back and Next buttons to move cards.</template>
  </p>
</template>

<!-- Correct -->
<script setup>
const lastMove = reactive({
  title: "",
  from: "",
  to: "",
});
</script>

<template>
  <p class="status">
    <template v-if="lastMove.title !== ''">
      Moved "{{ lastMove.title }}" from {{ lastMove.from }} to {{ lastMove.to }}.
    </template>
    <template v-else>Use the Back and Next buttons to move cards.</template>
  </p>
</template>
```

The snippets show only the parts that matter. With the wrong version, there is no error, and the card does move, but the status line never changes. After clicking "Next →" on "Write project brief":

```text
To Do (1) | In Progress (3) | Done (2)
Use the Back and Next buttons to move cards.
```

`title` received the empty string that `lastMove.title` held at the moment of destructuring, and it stays empty forever. Always read reactive objects through the object itself, as in `lastMove.title`. This mistake shows up often in AI-generated code, and you will meet it again with Pinia stores in Lesson 19.

**Error 3: Using `ref` without importing it.**

`defineProps` and `defineEmits` need no import, which makes it easy to forget that `ref` and `reactive` do.

```javascript
// Wrong
import { reactive } from "vue";

// Correct
import { reactive, ref } from "vue";
```

With the wrong version, the page is blank and the console shows:

```text
[Vue warn]: Unhandled error during execution of setup function 
  at <App>
ReferenceError: ref is not defined
```

The linter finds it before you open the browser:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/App.vue
  8:15  error  'ref' is not defined  no-undef

✖ 1 problem (1 error, 0 warnings)

ERROR: "lint:eslint" exited with 1.
```

Add the missing name to the import from `"vue"`.

---

## 7. Exercises

**Exercise 1:** Count the moves. Add a ref named `moveCount` that starts at `0`, increase it by one in `moveCard`, and show `Moves so far: 3` in a second status paragraph under the first one. Remember where `.value` is needed and where it is not.

**Exercise 2:** Add a "Start all" button to the toolbar that moves every card in To Do to In Progress in one click. Hint: loop over `cards.value` and change the `status` of each matching card. What does the To Do column show afterward?

**Exercise 3:** Add a toolbar button that hides or shows the descriptions on every card. Its label should be "Hide descriptions" while descriptions are visible and "Show descriptions" while they are hidden. Store the choice in a boolean ref in `App.vue` and pass it down through `BoardColumn` to `TaskCard` as a prop.

---

## 8. Solutions

**Solution for Exercise 1:**

Create the ref next to the other state in `src/App.vue`:

```javascript
const moveCount = ref(0);
```

Increase it at the end of `moveCard`:

```javascript
  card.status = newStatus;
  moveCount.value++;
```

And show it in the template, after the first status paragraph:

```vue
<p class="status">Moves so far: {{ moveCount }}</p>
```

In the script, `moveCount.value++` changes the number inside the ref. In the template, `{{ moveCount }}` is unwrapped automatically. After moving "Write project brief" forward, "Design home page" forward, and "Pick color palette" back, both status lines read:

```text
Moved "Pick color palette" from Done to In Progress. / Moves so far: 3
```

A number is a single value, so `ref` is the natural choice; `reactive` only works with objects.

**Solution for Exercise 2:**

Add the function to `src/App.vue`:

```javascript
function startAll() {
  for (const card of cards.value) {
    if (card.status === "todo") {
      card.status = "in-progress";
    }
  }
}
```

Then add the button to the toolbar. Wrap the buttons in a `<div>` so they stay together on the right:

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <div>
    <button type="button" @click="startAll">Start all</button>
    <button type="button" class="primary" @click="handleNewCard">+ New card</button>
  </div>
</div>
```

The column headers after a page refresh and one click on "Start all":

```text
To Do (0) | In Progress (4) | Done (2)
```

Every change inside the loop is tracked, and Vue renders the page once after the function finishes, not once per card. The To Do column is now empty, so it shows the "No cards here yet." message you built in Lesson 6.

**Solution for Exercise 3:**

In `src/App.vue`, create the state, add a button whose label depends on it, and pass it to each column:

```javascript
const showDescriptions = ref(true);
```

```vue
<button type="button" @click="showDescriptions = !showDescriptions">
  {{ showDescriptions ? "Hide descriptions" : "Show descriptions" }}
</button>
```

```vue
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :color="column.color"
  :cards="cardsFor(column.status)"
  :show-descriptions="showDescriptions"
  @move="moveCard"
/>
```

`@click="showDescriptions = !showDescriptions"` is an inline handler that flips the boolean. In the template you assign to the ref directly, without `.value`.

In `src/components/BoardColumn.vue`, add a prop and pass it on:

```javascript
showDescriptions: {
  type: Boolean,
  default: true,
},
```

```vue
<TaskCard
  v-for="card in cards"
  :key="card.id"
  :card="card"
  :show-description="showDescriptions"
  @move="(cardId, direction) => emit('move', cardId, direction)"
/>
```

In `src/components/TaskCard.vue`, add a matching prop and use it in the condition:

```javascript
showDescription: {
  type: Boolean,
  default: true,
},
```

```vue
<p v-if="showDescription && card.description !== ''" class="description">{{ card.description }}</p>
```

Before the click, five cards show a description paragraph. After one click, none of them do, and the toolbar buttons read:

```text
Show descriptions / Start all / + New card
```

The button label switched to "Show descriptions", and clicking it again brings the descriptions back. Notice how the value had to pass through `BoardColumn`, which does not use it at all. This is called **prop drilling**, and it gets tiresome as apps grow. In Lesson 19 you will learn how a Pinia store lets any component reach shared state directly. Undo these exercise changes before the next lesson.

---

## 9. ref or reactive?

You have now used both tools. Here is how they compare.

| | `ref` | `reactive` |
| --- | --- | --- |
| Works with | Any value: numbers, strings, booleans, arrays, objects | Objects and arrays only |
| In `<script setup>` | Read and write through `.value` | Read and write properties directly |
| In `<template>` | Unwrapped automatically, no `.value` | Used directly |
| Replace the whole value | `cards.value = newArray` keeps it reactive | Reassigning the variable breaks the connection |
| Destructuring | Not an issue; you pass the ref itself around | Breaks reactivity, as in Error 2 |

The official Vue documentation recommends `ref` as the main tool for declaring reactive state, because it works with every kind of value and can always be replaced as a whole. This course follows that advice and uses `ref` for nearly everything. `reactive` is handy for a group of fields that are always used together through one object, such as `lastMove` here or the form fields you will build in Lesson 10.

Two more facts help you read Vue code with confidence:

- **Reactivity is deep.** An object or array inside a `ref` or `reactive` becomes reactive too, at every level. That is why `card.status = newStatus` works on a card inside `cards.value`.
- **Updates are batched.** When you change many values in one function, as in Exercise 2, Vue waits until the function is finished and then updates the page once.

---

## Next Up - Lesson 10

In this lesson you learned why a plain variable does not update the page, and how Vue's reactivity system fixes that. You made Tasklane's cards reactive with `ref`, used `.value` in the script but not in the template, grouped the details of the last move in a `reactive` object, and learned how reactivity can be lost by destructuring. Cards now really move between columns.

In Lesson 10, the "+ New card" button will finally do something. You will build a form with text, textarea, select, and date inputs, connect each input to reactive state with `v-model`, validate the input, and add new cards to the board.
