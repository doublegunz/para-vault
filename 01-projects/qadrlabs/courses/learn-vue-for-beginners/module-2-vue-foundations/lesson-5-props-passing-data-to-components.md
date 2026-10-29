## 1. Before You Begin

In Lesson 4, you split Tasklane into `AppHeader`, `BoardColumn`, and `TaskCard`. The page is organized, but the components are stuck: `BoardColumn` always says "To Do", and every `TaskCard` shows the same hard-coded card. A component that can only ever show one thing is not reusable.

This lesson fixes that with **props**, short for properties. Props are how a parent component passes data to a child component, in the same way that attributes pass information to an HTML element. With props, one component can show different data each time it is used. You will give `BoardColumn` a title, give `AppHeader` a tagline with a default value, move Tasklane's sample cards into their own data file, and make `TaskCard` display whichever card it receives.

### What You'll Build

A board with three columns, To Do, In Progress, and Done, each with a card count in its title and two real cards from Tasklane's sample data. All six cards are different, and they all use the same `TaskCard` component.

### What You'll Learn

- ✅ What props are and how they flow from a parent to a child
- ✅ How to declare props with `defineProps`, including `type`, `required`, and `default`
- ✅ How to pass static text props and dynamic props with `:`
- ✅ How to keep sample data in a separate JavaScript module and import it
- ✅ Why props are read-only, and how Vue warns you when a prop has the wrong type or is missing

### What You'll Need

- The Tasklane project from Lesson 4, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Pass Your First Prop

The simplest prop is a piece of text. `BoardColumn` needs to know its title, so the title will become a prop that `App.vue` passes in.

### Step 1: Give BoardColumn a title Prop

Open `src/components/BoardColumn.vue` and replace its contents with this code.

```vue
<script setup>
import TaskCard from "./TaskCard.vue";

defineProps({
  title: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <section>
    <h3>{{ title }}</h3>
    <TaskCard />
    <TaskCard />
  </section>
</template>

<style scoped>
section {
  max-width: 320px;
  padding: 12px;
  background-color: #e5e7eb;
  border-radius: 12px;
}

h3 {
  margin: 0 0 12px;
}
</style>
```

If you did not do Exercise 2 of Lesson 4, the `<style scoped>` block is new; it turns the column into a grey lane. Here is what the code does:

- `defineProps({ ... })` declares the props this component accepts. It is a special function, called a **compiler macro**, that works only inside `<script setup>`. You do not need to import it.
- `title: { type: String, required: true }` declares a prop named `title`. `type: String` says it must be text, and `required: true` says the parent must always pass it.
- `<h3>{{ title }}</h3>` uses the prop in the template, just like a variable. Every declared prop is available in the template by its name.

### Step 2: Pass a Different Title to Each Column

Now use the column three times in `src/App.vue`, each with its own title.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";

const boardName = "Website Redesign";
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <BoardColumn title="To Do" />
    <BoardColumn title="In Progress" />
    <BoardColumn title="Done" />
  </main>
</template>
```

`title="To Do"` passes a prop exactly like an HTML attribute. Because there is no colon, the value is plain text. Save both files.

The headings on the page, from top to bottom:

```text
Tasklane
Plan your work, one card at a time.
Website Redesign
To Do
In Progress
Done
```

One component, three different titles. The columns still contain the same hard-coded card, six copies in total; you will fix that in Section 4. The columns are stacked on top of each other for now; Lesson 7 places them side by side.

### Step 3: Give a Prop a Default Value

Some props are optional. If the parent does not pass them, the component should use a sensible default. The tagline in `AppHeader` is a good example: most pages use the standard tagline, but a page could replace it. Open `src/components/AppHeader.vue` and replace its contents with this code.

```vue
<script setup>
defineProps({
  tagline: {
    type: String,
    default: "Plan your work, one card at a time.",
  },
});
</script>

<template>
  <header>
    <h1>Tasklane</h1>
    <p>{{ tagline }}</p>
  </header>
</template>

<style scoped>
p {
  margin-top: 0;
  color: #6b7280;
}
</style>
```

Here is what changed:

- `tagline` is declared with `default` instead of `required`. If the parent does not pass a tagline, Vue uses the default text.
- `<p>{{ tagline }}</p>` shows the prop instead of fixed text.

`App.vue` still uses `<AppHeader />` without any props, so the page looks exactly the same:

```text
Tasklane
Plan your work, one card at a time.
```

To check that the prop works, temporarily change the tag in `App.vue` to `<AppHeader tagline="Your board for the website project." />` and save.

The header now shows:

```text
Tasklane
Your board for the website project.
```

Change it back to `<AppHeader />` before you continue.

---

## 3. Move the Sample Cards into a Data File

Before `TaskCard` can receive different cards, the cards need to live somewhere. Putting six card objects inside `App.vue` would bury the template under data. Instead, you will create a plain JavaScript module, a `.js` file that exports values, and import the data wherever you need it.

### Step 1: Create the Data File

Create a folder named `data` inside `src`, and inside it create a file named `board.js` with this code.

```javascript
export const sampleCards = [
  {
    id: 1,
    title: "Write project brief",
    description: "Summarize the goals and scope of the website redesign.",
    status: "todo",
    priority: "high",
    dueDate: "2026-11-03",
  },
  {
    id: 2,
    title: "Collect logo files",
    description: "Ask the client for SVG versions of the logo.",
    status: "todo",
    priority: "low",
    dueDate: "",
  },
  {
    id: 3,
    title: "Design home page",
    description: "Create the first layout for the home page.",
    status: "in-progress",
    priority: "medium",
    dueDate: "2026-11-07",
  },
  {
    id: 4,
    title: "Set up hosting",
    description: "",
    status: "in-progress",
    priority: "high",
    dueDate: "2026-10-28",
  },
  {
    id: 5,
    title: "Pick color palette",
    description: "Choose the primary and accent colors.",
    status: "done",
    priority: "medium",
    dueDate: "2026-10-25",
  },
  {
    id: 6,
    title: "Write About page text",
    description: "Draft a short text about the company.",
    status: "done",
    priority: "low",
    dueDate: "2026-10-27",
  },
];
```

These are the six cards you modeled in the browser console in Lesson 1, now written with one property per line so they are easier to read and edit. `export const sampleCards` creates a **named export**: other files can import it with `import { sampleCards } from "..."`, with curly braces, because they ask for a specific name. The file is plain JavaScript, not a component, so it uses the `.js` extension.

---

## 4. Make TaskCard Reusable

Now `TaskCard` will stop reading its own constant and receive a whole card object as a prop instead. Passing the whole object is simpler than passing six separate props, and the card's template barely changes.

### Step 1: Give TaskCard a card Prop

Replace the contents of `src/components/TaskCard.vue` with this code.

```vue
<script setup>
defineProps({
  card: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <article :id="`card-${card.id}`" :title="card.title">
    <p>{{ card.priority.toUpperCase() }}</p>
    <h4>{{ card.title }}</h4>
    <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
    <p>
      Due
      <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
    </p>
  </article>
</template>

<style scoped>
article {
  margin-bottom: 12px;
  padding: 12px 16px;
  background-color: #ffffff;
  border-radius: 8px;
}
</style>
```

The only change is in `<script setup>`: the `const card = { ... }` object is gone, and `card` is now a required prop of type `Object`. The template still reads `card.title`, `card.priority`, and so on. It does not care whether `card` is a constant or a prop.

### Step 2: Pass Each Column Its Cards

`BoardColumn` needs to know which cards belong to it, so it gets a second prop, `cards`, an array. It then passes each card on to a `TaskCard`. Replace the contents of `src/components/BoardColumn.vue` with this code.

```vue
<script setup>
import TaskCard from "./TaskCard.vue";

defineProps({
  title: {
    type: String,
    required: true,
  },
  cards: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <section>
    <h3>{{ title }} ({{ cards.length }})</h3>
    <TaskCard :card="cards[0]" />
    <TaskCard :card="cards[1]" />
  </section>
</template>

<style scoped>
section {
  max-width: 320px;
  padding: 12px;
  background-color: #e5e7eb;
  border-radius: 12px;
}

h3 {
  margin: 0 0 12px;
}
</style>
```

Here is what changed:

- `cards: { type: Array, required: true }` declares the new prop.
- `<h3>{{ title }} ({{ cards.length }})</h3>` adds the number of cards after the title, so the column header reads like "To Do (2)".
- `<TaskCard :card="cards[0]" />` passes the first card of the array to a `TaskCard`, and the next line passes the second one. The colon is essential: `:card="cards[0]"` passes the object, while `card="cards[0]"` would pass the text "cards[0]".

Then replace the contents of `src/App.vue` so it imports the sample data and gives each column its own cards.

```vue
<script setup>
import AppHeader from "./components/AppHeader.vue";
import BoardColumn from "./components/BoardColumn.vue";
import { sampleCards } from "./data/board.js";

const boardName = "Website Redesign";
const todoCards = sampleCards.filter((card) => card.status === "todo");
const inProgressCards = sampleCards.filter((card) => card.status === "in-progress");
const doneCards = sampleCards.filter((card) => card.status === "done");
</script>

<template>
  <AppHeader />

  <main>
    <h2>{{ boardName }}</h2>
    <BoardColumn title="To Do" :cards="todoCards" />
    <BoardColumn title="In Progress" :cards="inProgressCards" />
    <BoardColumn title="Done" :cards="doneCards" />
  </main>
</template>
```

Here is what is new:

- `import { sampleCards } from "./data/board.js";` imports the named export from the data file.
- The three `filter` calls split the cards by status, the same technique you used in the console in Lesson 1. Each constant holds a new array with two cards.
- `:cards="todoCards"` passes an array, so it needs the colon. `title="To Do"` is plain text, so it does not.

Save all three files.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign
To Do (2)

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

LOW

Collect logo files

Ask the client for SVG versions of the logo.

Due anytime

In Progress (2)

MEDIUM

Design home page

Create the first layout for the home page.

Due 2026-11-07

HIGH

Set up hosting

No description yet.

Due 2026-10-28

Done (2)

MEDIUM

Pick color palette

Choose the primary and accent colors.

Due 2026-10-25

LOW

Write About page text

Draft a short text about the company.

Due 2026-10-27
```

All six sample cards are on the board, each in its own column, and every one of them uses the same `TaskCard` component. Notice that "Set up hosting" shows "No description yet." and "Collect logo files" shows "Due anytime": the fallbacks you wrote in Lesson 3 now work for any card.

There is one weakness left. `BoardColumn` always renders exactly two cards, `cards[0]` and `cards[1]`. That works today only because every column happens to have two cards. In Lesson 6 you will replace those two lines with a list that renders however many cards the column has, including none.

---

## 5. Run and Test

Restart the development server and open `http://localhost:5173`. Check the following:

1. The three column titles read `To Do (2)`, `In Progress (2)`, and `Done (2)`.
2. Each column shows its own two cards, and no card appears twice.
3. The tagline is the default one, because `App.vue` does not pass a `tagline` prop.

Then open the browser console. It should be empty, without any `[Vue warn]` messages. Vue checks every prop against its declaration while the app runs in development, so an empty console means every prop arrived with the right type.

Finally, run the linters.

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

No problems are reported. Your project now looks like this:

```text
src/
├── assets/
│   └── main.css
├── components/
│   ├── AppHeader.vue
│   ├── BoardColumn.vue
│   └── TaskCard.vue
├── data/
│   └── board.js
├── App.vue
└── main.js
```

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with props.

**Error 1: Forgetting the colon on a dynamic prop.**

Without the colon, a prop value is plain text, no matter what it looks like.

```vue
<!-- Wrong -->
<BoardColumn title="To Do" cards="todoCards" />

<!-- Correct -->
<BoardColumn title="To Do" :cards="todoCards" />
```

With the wrong version, the page goes blank and the console shows several messages. The first one explains the problem:

```text
[Vue warn]: Invalid prop: type check failed for prop "cards". Expected Array, got String with value "todoCards". 
  at <BoardColumn title="To Do" cards="todoCards" > 
  at <App>
```

The column received the string `"todoCards"` instead of the array. Then `cards[0]` became the first letter of that string, `"t"`, which was passed on to `TaskCard`, and the template crashed when it tried to read `card.priority.toUpperCase()`:

```text
TypeError: Cannot read properties of undefined (reading 'toUpperCase')
```

When an error appears deep inside a child component, read the first warning in the console: the real cause is often a prop that arrived with the wrong type. The type declaration in `defineProps` is what makes Vue print that helpful first warning.

**Error 2: Forgetting a required prop.**

`TaskCard` declares `card` as required. Using it without the prop leaves `card` undefined.

```vue
<!-- Wrong -->
<TaskCard :card="cards[0]" />
<TaskCard />

<!-- Correct -->
<TaskCard :card="cards[0]" />
<TaskCard :card="cards[1]" />
```

With the wrong version, the page goes blank, and the console starts with this warning:

```text
[Vue warn]: Missing required prop: "card" 
  at <TaskCard > 
  at <BoardColumn title="To Do" cards= Array(2) > 
  at <App>
```

It is followed by `TypeError: Cannot read properties of undefined (reading 'id')`, because the template reads `card.id` first. The warning names the prop and the component chain, `TaskCard` inside `BoardColumn` inside `App`, so you know exactly which tag to fix.

**Error 3: Changing a prop inside the child.**

Props belong to the parent. A child component can read them, but it must not change them.

```vue
<!-- Wrong -->
<script setup>
import TaskCard from "./TaskCard.vue";

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  cards: {
    type: Array,
    required: true,
  },
});

props.title = props.title.toUpperCase();
</script>

<!-- Correct -->
<script setup>
import TaskCard from "./TaskCard.vue";

defineProps({
  title: {
    type: String,
    required: true,
  },
  cards: {
    type: Array,
    required: true,
  },
});
</script>
```

`const props = defineProps(...)` stores the props in a variable so the script can read them. Reading is fine, but assigning to `props.title` is not. The page still shows the original titles, and the console shows one warning per column:

```text
[Vue warn] Set operation on key "title" failed: target is readonly.
```

The linter catches the mistake before you even open the browser. `npm run lint` reports:

```text
/home/gun-gun-priatna/obsidian-vault/sandbox/tasklane/src/components/BoardColumn.vue
  15:1  error  Unexpected mutation of "title" prop  vue/no-mutating-props

✖ 1 problem (1 error, 0 warnings)
```

If you want to display a prop differently, do it in the template, for example `{{ title.toUpperCase() }}`, without changing the prop itself. If the value really needs to change, the parent that owns the data must change it. You will learn how a child asks its parent to change data in Lesson 8.

---

## 7. Exercises

**Exercise 1:** Pass the tagline `Your board for the website project.` to `AppHeader` from `App.vue`, check the page, and then explain what would be shown if you removed the `default` from the `tagline` prop declaration and removed the prop from `App.vue` again.

**Exercise 2:** Create a small component named `PriorityBadge` with one required prop, `priority` (a string), that renders the priority in capital letters inside a `<p>`. Use it in `TaskCard` instead of the current `<p>{{ card.priority.toUpperCase() }}</p>` line.

**Exercise 3:** Add a seventh card to `sampleCards` in `board.js`, right after card 2: id `7`, title `"Write SEO checklist"`, description `"List the pages that need titles and descriptions."`, status `"todo"`, priority `"medium"`, and due date `"2026-11-10"`. What does the To Do column header say, how many cards are on the whole board, and why? Remove the card again afterward.

---

## 8. Solutions

**Solution for Exercise 1:**

Change the header tag in `App.vue`:

```vue
<AppHeader tagline="Your board for the website project." />
```

The header shows:

```text
Tasklane
Your board for the website project.
```

The passed value replaces the default. If the prop had no `default` and `App.vue` did not pass it, `tagline` would be `undefined`, and `{{ tagline }}` renders `undefined` as an empty string, so the header would show an empty paragraph under the heading. A default value makes an optional prop safe to leave out.

**Solution for Exercise 2:**

Create `src/components/PriorityBadge.vue`:

```vue
<script setup>
defineProps({
  priority: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <p>{{ priority.toUpperCase() }}</p>
</template>
```

Then import it in `src/components/TaskCard.vue` and use it in the template:

```vue
<script setup>
import PriorityBadge from "./PriorityBadge.vue";

defineProps({
  card: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <article :id="`card-${card.id}`" :title="card.title">
    <PriorityBadge :priority="card.priority" />
    <h4>{{ card.title }}</h4>
    <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
    <p>
      Due
      <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
    </p>
  </article>
</template>

<style scoped>
article {
  margin-bottom: 12px;
  padding: 12px 16px;
  background-color: #ffffff;
  border-radius: 8px;
}
</style>
```

The beginning of the page in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign
To Do (2)

HIGH

Write project brief

Summarize the goals and scope of the website redesign.

Due 2026-11-03

LOW
```

The page looks the same as before, because `PriorityBadge` renders the same `<p>`. The difference is that the badge is now its own component, which `TaskCard` passes data to. Props can be passed down through as many levels as you need: `App` to `BoardColumn` to `TaskCard` to `PriorityBadge`. The course continues with the version without `PriorityBadge`, so you can undo this change before Lesson 6.

**Solution for Exercise 3:**

Add the new object to the array in `src/data/board.js`, after the card with id `2`:

```javascript
  {
    id: 7,
    title: "Write SEO checklist",
    description: "List the pages that need titles and descriptions.",
    status: "todo",
    priority: "medium",
    dueDate: "2026-11-10",
  },
```

The column headers on the page:

```text
To Do (3) | In Progress (2) | Done (2)
```

The To Do header correctly says `(3)`, because `cards.length` counts every card in the array. But the board still shows only six cards, and "Write SEO checklist" is missing, because `BoardColumn` renders exactly `cards[0]` and `cards[1]`. The third card, `cards[2]`, is never used. Hard-coding positions only works when you know exactly how many items there will be, which is never true for real data. In Lesson 6 you will use `v-for` to render every card in the array, however many there are. Remove card 7 again so your data matches the next lesson.

---

## 9. How Props Work

You have used props in several places now. Here are the rules behind them.

**Data flows one way, from parent to child.** `App` passes `title` and `cards` to `BoardColumn`, and `BoardColumn` passes `card` to `TaskCard`. A child can read its props, but it cannot send data back up through them. This one-way flow makes Vue apps predictable: to find out where a value comes from, you look at the parent. In Lesson 8 you will learn the other direction, where a child **emits an event** to ask its parent to do something.

**Props are read-only.** As you saw in Error 3, Vue refuses to let a child assign a new value to a prop. The parent owns the data, so only the parent may change it.

**Declarations document and check your components.** The object you pass to `defineProps` is a small contract. Anyone who opens `TaskCard.vue` can see that it needs a `card` object. During development, Vue checks every prop against its `type` and `required` options and prints a warning when something does not match. The most common types are `String`, `Number`, `Boolean`, `Array`, `Object`, and `Function`.

**Defaults for objects and arrays use a function.** For text and numbers, `default: "..."` or `default: 0` is fine. For an array or object, write `default: () => []` or `default: () => ({})`, so that each component instance gets its own fresh copy instead of sharing one.

**Static and dynamic values.** `title="To Do"` passes the text `To Do`. `:cards="todoCards"` evaluates the expression `todoCards` and passes the result. Numbers and booleans need the colon too: `:count="5"` passes the number 5, while `count="5"` passes the text "5".

**Names in templates.** In `<script setup>`, props are written in camelCase, such as `dueDate`. In templates you may also write them in kebab-case, such as `:due-date="..."`, which Vue converts automatically. This course uses camelCase for one-word and short names to keep things simple.

---

## Next Up - Lesson 6

In this lesson you learned props, the way data flows from a parent component to its children. You declared props with `defineProps`, made them required or gave them default values, passed static and dynamic values, moved the sample cards into `src/data/board.js`, and made `TaskCard` display whichever card it receives. You also learned that props are read-only and saw how Vue warns you about wrong or missing props.

In Lesson 6, you will remove the hard-coded `cards[0]` and `cards[1]` from `BoardColumn`. You will render every card with `v-for`, learn why each item in a list needs a `key`, show or hide parts of a card with `v-if`, `v-else`, and `v-show`, and display a friendly message when a column is empty.
