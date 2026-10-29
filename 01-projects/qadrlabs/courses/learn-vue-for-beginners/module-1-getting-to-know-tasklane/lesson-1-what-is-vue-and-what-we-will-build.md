## 1. Before You Begin

Many of the web apps you use every day, such as admin dashboards, online stores, and project management tools, are built with a JavaScript framework. Vue is one of the most popular ones. It is famous for being friendly to beginners: a Vue template looks almost like the HTML you already know, and you can start with a single HTML file before moving to a full project. Vue is also a framework that AI coding assistants generate often. Ask an AI tool to "build me a task board" and you may well get a folder full of `.vue` files back. That is exciting, but it also leaves many people holding code they did not write and cannot fix when it breaks.

This course changes that. Instead of copying Vue code, you will learn to write it, read it, and repair it, one concept at a time. Every lesson adds a feature to a single app called Tasklane, a Kanban task board. This first lesson builds the right mental model before you install anything: what Vue is, what problem it solves compared to plain JavaScript, why AI tools generate so much of it, and what Tasklane will look like when you finish. You will also write the first piece of Tasklane today: its data, modeled with plain JavaScript in your browser.

### What You'll Build

Three small things that run directly in your browser, with no installation:

- A counter written with plain HTML and JavaScript.
- The same counter written with Vue, loaded from a single `<script>` tag, so you can compare the two styles side by side.
- The first version of Tasklane's data: a list of cards stored in a JavaScript array, plus a few lines of code that count, print, and move cards in the browser console.

### What You'll Learn

- ✅ What Vue is and what "a progressive framework for building user interfaces" means
- ✅ The difference between updating the page by hand (imperative) and describing what the page should look like (declarative)
- ✅ What reactivity and components are, and why Vue apps are built from them
- ✅ Why AI coding tools generate so much Vue, and why you still need to understand it
- ✅ What a Kanban board is, and the features, pages, and data of Tasklane
- ✅ How to run JavaScript in the browser console
- ✅ The roadmap for the rest of the course

### What You'll Need

- A modern web browser such as Chrome, Edge, or Firefox
- A text editor such as Visual Studio Code
- An internet connection, because the Vue counter loads Vue from a public server
- Basic HTML and JavaScript: tags, variables, arrays, objects, loops, arrow functions, and `addEventListener`. If any of these feel new, the qadrlabs courses Learn HTML and CSS and Learn JavaScript Basics cover them from zero.

---

## 2. What Is Vue?

Vue (pronounced "view") is a JavaScript framework for building user interfaces. It was created by Evan You and released as open source in 2014, and today it is maintained by a team of developers and supported by a large community. A user interface is everything a person sees and touches on the screen: text, buttons, forms, lists, and menus. Vue focuses on that job: keeping what is on the screen in sync with the data in your app.

The official website calls Vue "the progressive JavaScript framework". Progressive means you can adopt it a little at a time. You can drop Vue into one corner of an existing page with a single `<script>` tag, which you will do in this lesson, or you can build a complete single-page application with routing and shared state, which you will do in the rest of the course.

Three ideas make Vue different from writing plain JavaScript.

The first idea is being **declarative**. In plain JavaScript, you change the page step by step: find this element, change its text, add this class, remove that element. That style is called imperative, because you give the browser commands. In Vue, you write a **template** that describes what the page should look like for the current data, and Vue figures out which parts of the page need to change.

The second idea is **reactivity**. Vue watches your data. When a value changes, every part of the page that uses that value updates automatically. You never write `element.textContent = ...` again; you change the data and Vue does the rest.

The third idea is **components**. A Vue app is built from small, reusable pieces of interface. Each component lives in its own `.vue` file that holds its template, its JavaScript, and its CSS together. A task board might have an `AppHeader` component, a `BoardColumn` component, and a `TaskCard` component. You write `TaskCard` once and reuse it for every card on the board.

The fastest way to understand these ideas is to see them, so let's build the same tiny feature twice.

---

## 3. Build a Counter with Plain JavaScript

You will start with something familiar: a counter that shows how many cards are done and a button that increases the number. This version uses only HTML and plain JavaScript.

### Step 1: Create the HTML File

Create a folder named `vue-intro` anywhere on your computer, for example on your desktop. Inside it, create a file named `plain-counter.html` and type this code.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Plain JavaScript Counter</title>
  </head>
  <body>
    <p>Cards done: <span id="count">0</span></p>
    <button id="add">Mark one done</button>

    <script>
      let count = 0;
      const countText = document.getElementById("count");
      const button = document.getElementById("add");

      button.addEventListener("click", () => {
        count = count + 1;
        countText.textContent = count;
      });
    </script>
  </body>
</html>
```

Here is what the code does:

- `<p>Cards done: <span id="count">0</span></p>` shows the label and the starting number. The `span` has an `id` so JavaScript can find it later.
- `<button id="add">` is the button the user clicks.
- `let count = 0;` stores the current number in a variable.
- `document.getElementById("count")` and `document.getElementById("add")` find the two elements in the page.
- `button.addEventListener("click", ...)` runs the arrow function every time the button is clicked.
- Inside the function, `count = count + 1;` increases the number, and `countText.textContent = count;` writes the new number into the page.

### Step 2: Open the File in the Browser

Double-click `plain-counter.html` to open it in your browser, then click the button three times.

What you see in the browser after three clicks:

```text
Cards done: 3

Mark one done
```

It works, but look at how much of the code is about the page rather than the data. You had to give the `span` an `id`, find it, and remember to write the new value into it after every change. Forget the line `countText.textContent = count;` and the variable changes while the page keeps showing `0`. In a small counter that is easy to manage. In a task board with dozens of cards, counts in every column, and a progress bar, keeping every element in sync by hand quickly becomes the hardest part of the job.

---

## 4. The Same Counter in Vue

Now build the same counter with Vue. You do not need to install anything yet: Vue can be loaded from a CDN (a public server that hosts files for websites) with a single `<script>` tag.

### Step 1: Create the Vue Version

In the same `vue-intro` folder, create a file named `vue-counter.html` and type this code.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Vue Counter</title>
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
  </head>
  <body>
    <div id="app">
      <p>Cards done: {{ count }}</p>
      <button @click="count++">Mark one done</button>
    </div>

    <script>
      const { createApp, ref } = Vue;

      createApp({
        setup() {
          const count = ref(0);
          return { count };
        },
      }).mount("#app");
    </script>
  </body>
</html>
```

Here is what is new:

- `<script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>` loads Vue 3 from the unpkg CDN and creates a global variable named `Vue`.
- `<div id="app">` is the part of the page that Vue controls. Everything inside it is a **template**.
- `{{ count }}` is a placeholder. Vue replaces it with the current value of `count`, and keeps it up to date.
- `@click="count++"` tells Vue to run `count++` when the button is clicked. There is no `addEventListener` and no `getElementById`.
- `const { createApp, ref } = Vue;` takes two functions out of the `Vue` object.
- `ref(0)` creates a **reactive** value that starts at `0`. Reactive means Vue tracks it: when it changes, Vue updates every place in the template that uses it.
- `setup()` prepares the data for the template, and `return { count };` makes `count` available inside it.
- `createApp({ ... }).mount("#app")` creates a Vue app and attaches it to the `div` with the id `app`.

### Step 2: Open the File in the Browser

Double-click `vue-counter.html` and click the button three times. The page needs an internet connection the first time, so the browser can download Vue.

What you see in the browser after three clicks:

```text
Cards done: 3

Mark one done
```

The result is identical, but the way you got there is different. Nowhere in the Vue version do you write "find the span and change its text". You described the page once, `Cards done: {{ count }}`, and changed the data with `count++`. Vue noticed that `count` changed and updated the page for you. That is declarative rendering and reactivity working together.

If you open the browser console (you will learn how in Section 7), you will also see this message:

```text
You are running a development build of Vue.
Make sure to use the production build (*.prod.js) when deploying for production.
```

The development build includes helpful warnings for beginners, which makes it a bit larger and slower. That is perfect for learning. In real projects, the build tool you install in Lesson 2 picks the right version automatically.

Loading Vue from a CDN is great for experiments, but real apps are organized into many component files and need a build tool. From Lesson 2 onward you will build Tasklane as a proper Vue project, where the counter's ideas, `{{ }}`, `@click`, and `ref`, appear in every component.

---

## 5. Vue and AI Coding Tools

If you have tried an AI coding assistant or a "vibe coding" tool, where you describe an app in plain language and the tool writes the code, you may have seen Vue already. There are a few reasons AI tools generate it:

- **It is widely used.** Vue has been one of the most popular front-end frameworks for years, with a large amount of public code, documentation, and tutorials. AI models learn from that code.
- **Templates look like HTML.** A component's markup reads almost like a normal web page, which makes Vue a natural choice when a tool turns a description into a working screen.
- **It has an official ecosystem.** Vue Router for pages, Pinia for shared data, and Vite for building are all maintained by the Vue team, so a generated project usually fits together out of the box.

Here is the catch. An AI tool can produce a Vue app in seconds, but it cannot guarantee the app is correct. Generated code often contains small mistakes that are easy to miss: a value that stops updating the screen because it lost its reactivity, a child component that changes data it does not own, a list that shows the wrong card after an item is removed, or a watcher that never stops running. AI tools also mix older and newer ways of writing Vue in the same project. If you do not understand templates, props, events, reactivity, and computed values, every one of those bugs looks like magic, and the only option left is to ask the AI again and hope.

This course gives you the understanding to stay in control. Modules 1 to 6 teach Vue step by step through Tasklane. Module 7 then puts that knowledge to work with AI: you will read AI-generated Vue code line by line, and find and fix the kinds of bugs AI tools commonly produce. The goal is not to avoid AI. The goal is to be the developer who knows what the code is doing.

---

## 6. Meet Tasklane

Tasklane is a Kanban task board. Kanban is a simple way to organize work that started in factories and is now used by software teams, students, and freelancers everywhere. Every task is written on a card, and every card sits in a column that shows its progress. Tasklane uses the three classic columns:

- **To Do**: work that has not started yet
- **In Progress**: work you are doing right now
- **Done**: finished work

As work moves forward, the card moves from left to right. One glance at the board tells you what is waiting, what is happening, and what is finished.

By the end of the course, Tasklane will have these features:

| Feature | What it does | Where you build it |
| --- | --- | --- |
| Board and cards | Three columns with cards showing title, description, priority, and due date | Lessons 3 to 7 |
| Add a card | A form to create new cards | Lessons 8 to 10 |
| Edit, delete, and move | Fix a card, remove it, or move it to the next column with a button | Lesson 11 |
| Counts and progress | Card counts per column, overall progress, and overdue warnings | Lesson 12 |
| Filter and search | Show only one priority or search cards by title | Lesson 12 |
| Saved data | Cards stay in the browser after a page refresh | Lessons 13 and 16 |
| Modal form | The card form opens in a reusable pop-up window | Lesson 14 |
| Import tasks | Load sample tasks from a public API | Lesson 15 |
| Multiple pages | Home, Board, Card Detail, and About pages with shared data | Lessons 17 to 19 |

Cards move between columns with buttons rather than drag and drop. Dragging is a nice extra, but it adds a lot of code that has nothing to do with learning Vue. Once you finish the course, adding drag and drop is a great project to try on your own, and Lesson 22 gives you a starting point.

The board page will look roughly like this sketch:

```text
+==================================================================+
| Tasklane                                Home | Board | About     |
+==================================================================+
| Search: [            ]  Priority: [ All v ]   [+ New card]       |
| 2 of 6 cards done (33%)   1 overdue                              |
+---------------------+----------------------+---------------------+
| To Do (2)           | In Progress (2)      | Done (2)            |
| +-----------------+ | +------------------+ | +-----------------+ |
| | HIGH            | | | MEDIUM           | | | MEDIUM          | |
| | Write project   | | | Design home page | | | Pick color      | |
| | brief           | | | Due 2026-11-07   | | | palette         | |
| | Due 2026-11-03  | | | [<] [>]          | | | [<]             | |
| | [>]             | | +------------------+ | +-----------------+ |
| +-----------------+ | +------------------+ | +-----------------+ |
| +-----------------+ | | HIGH  OVERDUE    | | | LOW             | |
| | LOW             | | | Set up hosting   | | | Write About     | |
| | Collect logo    | | | Due 2026-10-28   | | | page text       | |
| | files           | | | [<] [>]          | | | [<]             | |
| | [>]             | | +------------------+ | +-----------------+ |
| +-----------------+ |                      |                     |
+---------------------+----------------------+---------------------+
```

In Vue, this screen is not one big file. It is a tree of components, each responsible for one part:

```text
App
├── AppHeader          (logo and navigation links)
├── FilterBar          (search box and priority dropdown)
└── BoardColumn        (one column, reused three times)
    └── TaskCard       (one card, reused for every card)
```

You will create each of these components yourself in Module 2 and bring them to life in Module 3.

Behind every screen sits the data. In Tasklane, each card is a JavaScript object with the same six properties:

| Property | Example | Meaning |
| --- | --- | --- |
| `id` | `3` | A unique number that identifies the card |
| `title` | `"Design home page"` | A short name for the task |
| `description` | `"Create the first layout for the home page."` | Optional details, or an empty string |
| `status` | `"in-progress"` | The column: `"todo"`, `"in-progress"`, or `"done"` |
| `priority` | `"medium"` | How important it is: `"low"`, `"medium"`, or `"high"` |
| `dueDate` | `"2026-11-07"` | The deadline in year-month-day format, or an empty string |

The `status` property decides which column a card appears in. Moving a card to another column is nothing more than changing its `status`. You will use this exact shape all the way to the last lesson.

---

## 7. Model Tasklane's Data in the Browser Console

Before writing more Vue, you will create Tasklane's data with plain JavaScript and work with it. Every browser includes a console where you can type JavaScript and see the result immediately, which makes it a perfect place for quick experiments. The code in this section uses only arrays, objects, loops, array methods, and template literals from the JavaScript Basics course.

### Step 1: Open the Browser Console

Open a new browser tab and go to `about:blank`, an empty page. Then open the developer tools console:

- Chrome or Edge: press `Ctrl+Shift+J` on Windows or Linux, or `Cmd+Option+J` on macOS.
- Firefox: press `Ctrl+Shift+K` on Windows or Linux, or `Cmd+Option+K` on macOS.

Type the following line into the console and press `Enter`.

```javascript
console.log("Hello, Tasklane!");
```

Output in the console:

```text
Hello, Tasklane!
```

`console.log` prints a value to the console. You may also see a grey `undefined` on the next line. That is the console showing the return value of `console.log` itself, which returns nothing. You can ignore it.

Each of the next steps is a complete piece of code that starts by creating the cards. If the console shows an error saying that `cards` has already been declared, refresh the page and paste the code again.

### Step 2: Create the Cards Array

Create an array with six cards and print how many there are.

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

console.log(`Tasklane has ${cards.length} cards.`);
```

Here is what the code does:

- `const cards = [ ... ];` creates an array. Each item inside the square brackets is an object in curly braces, separated by commas.
- Every object has the six properties from the table in Section 6. Card 2 has no due date and card 4 has no description, so they use an empty string `""`.
- `cards.length` is the number of items in the array.
- The backticks create a template literal, so `${cards.length}` is replaced by the number.

Output in the console:

```text
Tasklane has 6 cards.
```

These six cards belong to a small website redesign project. They are the same sample cards you will see on the board in the next lessons.

### Step 3: Count the Cards in Each Column

A Kanban board shows how many cards are in each column. Count them with `filter`.

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

const statuses = ["todo", "in-progress", "done"];

for (const status of statuses) {
  const count = cards.filter((card) => card.status === status).length;
  console.log(`${status}: ${count}`);
}
```

Here is what is new:

- `statuses` lists the three possible values of `status`, in the order of the columns.
- `for (const status of statuses)` runs the loop body once for each status.
- `cards.filter((card) => card.status === status)` creates a new array with only the cards whose `status` matches. `filter` does not change `cards`.
- `.length` counts the cards in that new array.

Output in the console:

```text
todo: 2
in-progress: 2
done: 2
```

This is exactly the information each column header will show. In Lesson 12 you will calculate it with a Vue feature called computed properties, and the numbers will update by themselves.

### Step 4: Print Each Card

Print a one-line summary of every card, with the priority in capital letters and a friendly message when there is no due date.

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

for (const card of cards) {
  const due = card.dueDate === "" ? "no due date" : `due ${card.dueDate}`;
  console.log(`[${card.priority.toUpperCase()}] ${card.title} (${due})`);
}
```

Here is what the loop does:

- `for (const card of cards)` visits each card in order.
- `` card.dueDate === "" ? "no due date" : `due ${card.dueDate}` `` is a ternary expression: if the due date is empty, use the text `no due date`, otherwise build the text `due` followed by the date.
- `card.priority.toUpperCase()` turns `"high"` into `"HIGH"`.

Output in the console:

```text
[HIGH] Write project brief (due 2026-11-03)
[LOW] Collect logo files (no due date)
[MEDIUM] Design home page (due 2026-11-07)
[HIGH] Set up hosting (due 2026-10-28)
[MEDIUM] Pick color palette (due 2026-10-25)
[LOW] Write About page text (due 2026-10-27)
```

Each line is a tiny text version of a card on the board. In Lesson 3 you will display the same information in a Vue template, using the same kind of expressions inside `{{ }}`.

### Step 5: Move a Card to Another Column

Moving a card means changing its `status`. Find card 3 and move it to Done.

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

const card = cards.find((card) => card.id === 3);
card.status = "done";

const doneCount = cards.filter((card) => card.status === "done").length;
console.log(`Moved "${card.title}" to done.`);
console.log(`Done: ${doneCount} of ${cards.length} cards`);
```

Here is what the code does:

- `cards.find((card) => card.id === 3)` returns the first card whose `id` is `3`. Unlike `filter`, `find` returns the object itself, not a new array.
- `card.status = "done";` changes the status of that object. Because `card` points to the same object stored in the array, the array now contains the updated card.
- The last three lines count the Done cards again and print a summary.

Output in the console:

```text
Moved "Design home page" to done.
Done: 3 of 6 cards
```

Notice what you had to do after moving the card: count again and print again. In plain JavaScript, nothing updates by itself. In Vue, you will write `card.status = "done"` in exactly the same way, and the card will jump to the Done column while the counts update automatically. That is reactivity, and it is the heart of this course.

---

## 8. How This Course Works

The course is organized into eight modules. Each one builds on the previous one and adds new features to Tasklane.

| Module | Topic | Lessons |
| --- | --- | --- |
| 1 | Getting to Know Tasklane | 1 to 2 |
| 2 | Vue Foundations: templates, components, props, lists, bindings | 3 to 7 |
| 3 | Making Tasklane Interactive: events, reactive state, forms | 8 to 11 |
| 4 | Computed, Watchers, and Slots | 12 to 14 |
| 5 | Data and Composables: APIs and reusable logic | 15 to 16 |
| 6 | Multiple Pages with Vue Router and Pinia | 17 to 19 |
| 7 | Coding Vue with AI | 20 to 21 |
| 8 | Finishing Tasklane | 22 |

Every lesson follows the same rhythm. You start with a short overview of what you will build, then follow numbered steps that each end with code you can run and a result you can check. After that comes a "Fix the Errors in Your Code" section with common mistakes, a set of exercises, and full solutions. Try the exercises before reading the solutions; that is where most of the learning happens.

You will write all the code yourself. Typing it, rather than copying it, feels slower at first, but it is how your fingers and eyes learn to spot a missing bracket or a misspelled name. That skill matters even more when you start reviewing code written by AI. When you finish, Tasklane is a complete project you built from an empty folder, ready to show in your portfolio.

---

## 9. Fix the Errors in Your Code

These are common mistakes when working with arrays of objects like Tasklane's cards. Try each wrong version in the console to see what happens, then fix it.

**Error 1: A missing comma between objects.**

Items in an array must be separated by commas. When a comma is missing between two objects, JavaScript cannot tell where one item ends and the next begins.

```javascript
// Wrong
const cards = [
  { id: 1, title: "Write project brief", status: "todo" }
  { id: 2, title: "Collect logo files", status: "todo" },
];

// Correct
const cards = [
  { id: 1, title: "Write project brief", status: "todo" },
  { id: 2, title: "Collect logo files", status: "todo" },
];
```

The wrong version stops with `SyntaxError: Unexpected token '{'` (Chrome adds the word `Uncaught` in front). JavaScript reached the opening `{` of the second object while still expecting a comma or a closing `]`. As with most syntax errors, the real problem is just before the place the error points to.

**Error 2: A status that does not match exactly.**

Comparisons with `===` are exact. A space instead of a hyphen, or a capital letter, makes two strings different.

```javascript
// Wrong
const count = cards.filter((card) => card.status === "in progress").length;
console.log(`in-progress: ${count} cards`);

// Correct
const count = cards.filter((card) => card.status === "in-progress").length;
console.log(`in-progress: ${count} cards`);
```

With the six cards from Step 2, the wrong version prints this, without any error:

```text
in-progress: 0 cards
```

No card has the status `"in progress"` with a space, so the filter finds nothing. Bugs like this are sneaky because nothing crashes. A card with a misspelled status would simply disappear from the board, because it belongs to no column. That is why Tasklane will always pick the status from a fixed list instead of letting users type it.

**Error 3: Using `=` instead of `===` inside `find`.**

A single `=` assigns a value. Three equal signs, `===`, compare two values.

```javascript
// Wrong
const card = cards.find((card) => card.id = 3);
console.log(card.id, card.title);

// Correct
const card = cards.find((card) => card.id === 3);
console.log(card.id, card.title);
```

With the cards from Step 2, the wrong version prints this:

```text
3 Write project brief
```

The title belongs to card 1, not card 3. `card.id = 3` sets the `id` of the first card to `3`, and the result of that assignment, the number `3`, counts as true, so `find` stops at the very first card. Worse, the code has quietly changed your data: there are now two cards with the id `3`. Duplicate ids cause confusing bugs in Vue lists, as you will see in Lesson 6.

---

## 10. Exercises

**Exercise 1:** In your own words, explain the difference between the plain JavaScript counter in Section 3 and the Vue counter in Section 4. Use the words "imperative", "declarative", and "reactive" in your answer, and name the line in the plain version that Vue makes unnecessary.

**Exercise 2:** Using the six cards from Step 2, write code that prints how many cards have the priority `"high"`, and then prints the title of every card that has no description, in the format `Missing description: <title>`.

**Exercise 3:** A card is overdue when it has a due date, the due date is before today, and it is not done yet. Using the six cards from Step 2 and the fixed date `const today = "2026-10-29";`, print every overdue card in the format `Overdue: <title> (due <date>)`. Hint: dates in the `YYYY-MM-DD` format can be compared as strings with `<`.

---

## 11. Solutions

**Solution for Exercise 1:**

The plain JavaScript counter is imperative: it stores the number in a variable, finds the `span` with `getElementById`, and after every click it has to write the new number into the page itself with `countText.textContent = count;`. If that line is missing, the page stops matching the data. The Vue counter is declarative: the template says once that the paragraph shows `Cards done: {{ count }}`. Because `count` is created with `ref`, it is reactive, so when `count++` runs, Vue notices the change and updates the paragraph by itself. Vue makes the `countText.textContent = count;` line, and the `getElementById` calls before it, unnecessary.

**Solution for Exercise 2:**

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

const highCount = cards.filter((card) => card.priority === "high").length;
console.log(`High priority: ${highCount} cards`);

for (const card of cards) {
  if (card.description === "") {
    console.log(`Missing description: ${card.title}`);
  }
}
```

`filter` keeps the cards whose priority is exactly `"high"`, and `.length` counts them. The loop then checks each card's description and prints only the ones that are empty.

Output in the console:

```text
High priority: 2 cards
Missing description: Set up hosting
```

**Solution for Exercise 3:**

```javascript
const cards = [
  { id: 1, title: "Write project brief", description: "Summarize the goals and scope of the website redesign.", status: "todo", priority: "high", dueDate: "2026-11-03" },
  { id: 2, title: "Collect logo files", description: "Ask the client for SVG versions of the logo.", status: "todo", priority: "low", dueDate: "" },
  { id: 3, title: "Design home page", description: "Create the first layout for the home page.", status: "in-progress", priority: "medium", dueDate: "2026-11-07" },
  { id: 4, title: "Set up hosting", description: "", status: "in-progress", priority: "high", dueDate: "2026-10-28" },
  { id: 5, title: "Pick color palette", description: "Choose the primary and accent colors.", status: "done", priority: "medium", dueDate: "2026-10-25" },
  { id: 6, title: "Write About page text", description: "Draft a short text about the company.", status: "done", priority: "low", dueDate: "2026-10-27" },
];

const today = "2026-10-29";

for (const card of cards) {
  if (card.dueDate !== "" && card.dueDate < today && card.status !== "done") {
    console.log(`Overdue: ${card.title} (due ${card.dueDate})`);
  }
}
```

The condition combines three checks with `&&`, so all of them must be true. `card.dueDate !== ""` skips cards without a due date. `card.dueDate < today` works because dates written as `YYYY-MM-DD` sort in the same order as text and as time. `card.status !== "done"` skips finished work: cards 5 and 6 have old due dates, but they are done, so they are not overdue.

Output in the console:

```text
Overdue: Set up hosting (due 2026-10-28)
```

In the real app you will use today's date instead of a fixed one, and the overdue cards will be highlighted in red on the board.

---

## Next Up - Lesson 2

In this lesson you learned what Vue is and how its declarative templates and reactivity differ from updating the page by hand. You built the same counter twice, once with plain JavaScript and once with Vue loaded from a CDN, saw why AI tools generate so much Vue, met Tasklane and its three columns, and modeled Tasklane's cards in the browser console.

In Lesson 2, you will set up a real Vue project. You will install Node.js and npm, create the Tasklane project with Vue's official project generator, start the development server, and take a tour of every file the generator creates.
