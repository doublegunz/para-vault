## 1. Before You Begin

Tasklane is complete. Over twenty-one lessons it grew from a heading in `App.vue` to a multi-page Kanban app: components and props, events and reactive state, forms with `v-model`, computed stats and filters, saved data, a reusable modal, an API import, composables, Vue Router, a Pinia store, and two pages you reviewed and fixed after an AI tool "wrote" them. So far, though, Tasklane only runs on your computer, through the development server.

In this final lesson you will prepare Tasklane for the world. You will build it for production with `npm run build`, look at the files Vite produces, preview the production version, and learn what a web server needs in order to host a single-page app that uses Vue Router. You will also write a README that presents Tasklane as a portfolio project, and you will close the course with a map of where to go next, including how to add drag and drop to the board yourself.

### What You'll Build

A production build of Tasklane in the `dist` folder: one HTML file, one JavaScript file, and one CSS file, ready to upload to any static hosting service. You will check that every page works in the production preview, including addresses opened directly, and replace the template README with a description of your project.

### What You'll Learn

- ✅ What a production build is and how it differs from the development server
- ✅ How to build Tasklane with `npm run build` and read Vite's output
- ✅ How to preview the production build with `npm run preview`
- ✅ Why a server must answer every address with `index.html` for Vue Router to work
- ✅ How to present Tasklane as a portfolio project
- ✅ Where to go next with Vue, and how to start adding drag and drop

### What You'll Need

- The Tasklane project from Lesson 21
- A terminal in the `tasklane` folder

---

## 2. Build for Production

The development server you have used since Lesson 2 is built for working: it translates files on demand, reloads the page when you save, and includes Vue's helpful warnings. A real website needs the opposite: as few and as small files as possible, without development tools. Creating those files is called **building**.

### Step 1: Run the Build

Stop the development server if it is running, and run:

```bash
npm run build
```

Output:

```text

> tasklane@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 55 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.43 kB │ gzip:  0.28 kB
dist/assets/index-CNA9lTFC.css    5.60 kB │ gzip:  1.60 kB
dist/assets/index-B5efegjp.js   115.49 kB │ gzip: 44.08 kB

✓ built in 201ms
```

Here is what Vite did:

- **55 modules transformed.** Every `.vue` file, every `.js` file, and every package Tasklane imports, such as Vue, Vue Router, and Pinia, counts as a module. Vite translated all of them.
- **Rendering chunks.** It combined the modules into a few output files, called chunks, removed code that is never used, and **minified** the result: shortened names, removed spaces and comments.
- **The file list.** `index.html` is the page. All the JavaScript, including Vue itself, is in one file of about 115 kB, and all the CSS, global and scoped, is in one file of about 5.6 kB.
- **gzip.** Web servers usually compress files before sending them. The second column shows the compressed size: about 44 kB of JavaScript travels over the network.

The names contain a **hash**, such as `index-B5efegjp.js`, a code calculated from the file's contents. When you change your code and build again, the hash changes, so browsers know they must download the new file instead of using an old copy from their cache. Your hashes and exact sizes will differ.

### Step 2: Look Inside dist

The build writes everything into a new folder named `dist`, short for distribution:

```text
dist/
├── assets/
│   ├── index-B5efegjp.js
│   └── index-CNA9lTFC.css
├── favicon.ico
└── index.html
```

`favicon.ico` was copied from the `public` folder, as Lesson 2 explained. Open `dist/index.html` in your editor:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tasklane</title>
    <script type="module" crossorigin src="/assets/index-B5efegjp.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-CNA9lTFC.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

It is your `index.html` from Lesson 2, with the `<script>` pointing to `/src/main.js` replaced by the built JavaScript and CSS files. The body still contains only `<div id="app"></div>`; Vue builds everything else in the browser.

These three files are the whole app. You can upload them to any web server or static hosting service; no Node.js is needed to run Tasklane. The `dist` folder is listed in `.gitignore`, because it can always be recreated with `npm run build`.

---

## 3. Preview the Production Build

Before uploading anything, check that the built version works. Vite can serve the `dist` folder locally.

### Step 1: Start the Preview Server

```bash
npm run preview
```

Output:

```text
> tasklane@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

The preview server uses port `4173`, so it does not collide with the development server on `5173`. It serves the files from `dist` as they are, without translating anything, so what you see is exactly what visitors will get. Notice that there are no Vue DevTools lines: development tools are not part of the build.

### Step 2: Test Every Page

Open `http://localhost:4173`, delete the `tasklane-cards` key in the Application tab (the preview has its own storage, because it runs on a different port), and refresh. Then open each page by typing its address directly into the address bar.

The heading of the main area for each address, and the header badge on the home page:

```text
/ : Welcome to Tasklane | badge: 4 open
/board : Website Redesign
/cards/3 : Design home page
/stats : Statistics
/nope : Page not found
```

Every route works, including the card detail page and the "not found" page. Try the features as well: move, add, edit, and delete cards, filter the board, import tasks, and refresh. Then stop the preview server with `Ctrl+C`.

---

## 4. Prepare for Hosting

Typing `/board` into the address bar worked in the preview, but that is not automatic. When you type an address, the browser asks the **server** for that path. There is no file named `board` in `dist`; the page only exists inside Vue Router, which runs after `index.html` has loaded.

The Vite servers, both the development server and the preview server, know about single-page apps: when no file matches the path, they answer with `index.html`, and Vue Router takes it from there. This behavior is called a **fallback** (or "SPA fallback", or "history fallback"). Many simple web servers do not do this by default.

### Step 1: See What Happens Without a Fallback

If you have Python installed, you can try a basic static server yourself. In the `dist` folder, run:

```bash
python3 -m http.server 8099
```

Then open `http://localhost:8099`. The home page works. Click the navigation links, and every page works too, because Vue Router changes pages without asking the server. But type an address directly, or refresh on any page except the home page:

```text
/ : Welcome to Tasklane | badge: 4 open
/board : Error response

Error code: 404

Message: File not found.

Error code explanatio
```

The text is cut off by the test after 80 characters. The server looked for a file named `board`, found none, and returned "404 Not Found". Stop the server with `Ctrl+C`. If you do not have Python, you can skip this step; the point is what happens, not the tool.

### Step 2: Know What to Configure

Every hosting service has a way to set up the fallback. You only need to tell it: "for any path that is not a file, return `/index.html`". The most common options are:

| Hosting | How to set up the fallback |
| --- | --- |
| Netlify | A file named `_redirects` with the line `/*    /index.html   200` (Exercise 2) |
| Vercel | A `vercel.json` file with a rewrite of all paths to `/index.html` |
| Cloudflare Pages | Serves `index.html` for unknown paths by default when there is no `404.html` |
| GitHub Pages | No server rules; a common workaround is to copy `index.html` to `404.html` |
| nginx | `try_files $uri $uri/ /index.html;` in the site configuration |

Hosting services change their settings and defaults over time, so check the current documentation of the one you choose. The idea stays the same everywhere.

If you host Tasklane in a subfolder instead of at the root of a domain, for example `https://example.com/tasklane/`, also set Vite's `base` option to `/tasklane/` in `vite.config.js` and pass it to the router with `createWebHistory(import.meta.env.BASE_URL)`, so that both the file paths and the routes include the subfolder.

---

## 5. Make Tasklane Portfolio-Ready

Tasklane is a real project you built from an empty folder, which makes it a good portfolio piece. A portfolio project needs two things besides the code: a clear description, and a place where people can see it.

### Step 1: Write the README

The `README.md` in your project still contains the text from the create-vue template. Replace it with a description of Tasklane:

````markdown
# Tasklane

Tasklane is a Kanban task board built with Vue 3. Cards move through three columns,
To Do, In Progress, and Done, and the board is saved in the browser.

## Features

- Add, edit, delete, and move cards between columns
- Priorities, due dates, and overdue warnings
- Progress stats, search, and a priority filter
- Import sample tasks from the DummyJSON API
- Card detail pages, a statistics page, and upcoming deadlines
- Data saved in localStorage

## Built with

Vue 3 (Composition API with `<script setup>`), Vite, Vue Router, and Pinia.

## Run it locally

```sh
npm install
npm run dev
```

## Build for production

```sh
npm run build
npm run preview
```
````

A good README answers, in order: what is this, what can it do, what is it built with, and how do I run it. GitHub and similar sites show it on the project's front page, so it is the first thing a visitor or a recruiter reads. Add a screenshot of the board, and once Tasklane is online, a link to the live version.

### Step 2: Publish the Code and the App

If you have used Git throughout the course, push the project to a repository on GitHub or a similar service. Then connect the repository to a hosting service such as Netlify, Vercel, or Cloudflare Pages. They all follow the same pattern for a Vite project:

- **Build command:** `npm run build`
- **Output directory:** `dist`
- **Fallback:** set up as described in Section 4

After every push, the service runs the build and publishes the new `dist` folder. In your portfolio, link to both the live app and the code, and write two or three sentences about what you learned building it. Mention that you can review and fix AI-generated code; Module 7 gave you real examples to talk about.

---

## 6. Run and Test

Do a final check of the whole project from a clean state:

1. Run `npm run lint`. Both linters pass.
2. Run `npm run build`. The build finishes without errors.
3. Run `npm run preview` and open `http://localhost:4173`.
4. Delete the `tasklane-cards` key and refresh. The home page shows `You have 4 open cards on your board.`
5. Open `/board`, `/cards/3`, `/stats`, `/about`, and an unknown address directly. Each shows the right page.
6. Use every feature once: add, edit, move, delete, filter, import, mark as done, and finish all in-progress cards on the Stats page. The header badge follows every change.
7. Refresh on a page other than the home page. Your data is still there.

The linter run:

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

No problems are reported. If every step passes, Tasklane is ready to publish.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when building and publishing a Vue app.

**Error 1: Opening `dist/index.html` directly.**

It is tempting to double-click `dist/index.html` to see the built app. The browser shows a blank page. The text of the page body:

```text
BODY: ""
```

The page loads its files from `/assets/...`, an address that starts at the root of a web server. Opened as a file, `/assets/` points to the root folder of your disk instead, where the files do not exist, so the JavaScript never runs. Always look at a build through a server: `npm run preview` locally, or a hosting service online.

**Error 2: A server without a fallback.**

If your published app works when you click through it, but shows "404 Not Found" when you refresh a page or open a shared link such as `/cards/3`, the server has no fallback to `index.html`:

```text
curl /board -> 404
```

This line comes from asking the Python server in Section 4 for `/board` with the command-line tool `curl`. Configure the fallback for your hosting service as shown in the table in Section 4. Test it by opening a deep link in a new tab, not by clicking links, because clicking never asks the server.

**Error 3: Editing files in `dist`.**

```text
Wrong:   fix a typo in dist/assets/index-B5efegjp.js and upload it
Correct: fix the typo in src/, run npm run build, and upload the new dist
```

The `dist` folder is generated. The next `npm run build` deletes it and creates it again from `src`, so any change made directly in `dist` disappears. The minified code is also very hard to edit safely. Always change the source and rebuild.

---

## 8. Exercises

**Exercise 1:** The Stats and About pages are not needed on the first page load. Load them lazily, as in Lesson 17's Exercise 2, with `component: () => import(...)`, and run `npm run build` again. What changes in the build output?

**Exercise 2:** Prepare Tasklane for Netlify. Create a file named `_redirects` (with no extension) in the `public` folder, containing the line `/*    /index.html   200`. Build again and check where the file ends up.

**Exercise 3:** Add drag and drop as a first step toward moving cards with the mouse. Use the browser's built-in HTML Drag and Drop API: make every `TaskCard` draggable and put its id into the drag data on `dragstart`; make every `BoardColumn` accept drops with `@dragover.prevent` and emit a `drop-card` event with the card id and the column's status on `drop`; and let `BoardView` update the card's status through the store, with the usual status message. You will need to pass each column its `status` as a new prop.

---

## 9. Solutions

**Solution for Exercise 1:**

Replace the static imports of `AboutView` and `StatsView` in `src/router/index.js` with lazy imports:

```javascript
import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import BoardView from "../views/BoardView.vue";
import CardDetailView from "../views/CardDetailView.vue";
import NotFoundView from "../views/NotFoundView.vue";

const routes = [
  { path: "/", name: "home", component: HomeView },
  { path: "/board", name: "board", component: BoardView },
  { path: "/cards/:id", name: "card", component: CardDetailView },
  { path: "/stats", name: "stats", component: () => import("../views/StatsView.vue") },
  { path: "/about", name: "about", component: () => import("../views/AboutView.vue") },
  { path: "/:pathMatch(.*)*", name: "not-found", component: NotFoundView },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});
```

The build output:

```text

> tasklane@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 56 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                       0.43 kB │ gzip:  0.28 kB
dist/assets/AboutView-Ca500mgL.css    0.04 kB │ gzip:  0.06 kB
dist/assets/StatsView-fiCrpLJh.css    0.14 kB │ gzip:  0.14 kB
dist/assets/index-CRCoGrv8.css        5.41 kB │ gzip:  1.56 kB
dist/assets/AboutView-PZgafz_J.js     0.52 kB │ gzip:  0.37 kB
dist/assets/StatsView-CsPfBQ5e.js     1.29 kB │ gzip:  0.71 kB
dist/assets/index-DSSF2kLv.js       115.84 kB │ gzip: 44.43 kB

✓ built in 232ms
```

Each lazy page now has its own small JavaScript and CSS files, which the browser downloads only when someone opens that page. In Tasklane the savings are tiny, because Vue itself makes up most of the main file, but in an app with dozens of pages, lazy loading keeps the first visit fast. The main file is slightly larger here because of the small amount of extra code that loads chunks on demand.

**Solution for Exercise 2:**

Create `public/_redirects` with this single line:

```text
/*    /index.html   200
```

It tells Netlify: for every path (`/*`), serve `/index.html` with the status `200 OK`, unless a real file matches. After `npm run build`, the files in `dist` are:

```text
dist/assets/AboutView-Ca500mgL.css
dist/assets/AboutView-PZgafz_J.js
dist/assets/index-CRCoGrv8.css
dist/assets/index-DSSF2kLv.js
dist/assets/StatsView-CsPfBQ5e.js
dist/assets/StatsView-fiCrpLJh.css
dist/favicon.ico
dist/index.html
dist/_redirects
```

(This listing includes the lazy chunks from Exercise 1.) Everything in `public` is copied into `dist` unchanged, which is exactly where Netlify looks for `_redirects`.

**Solution for Exercise 3:**

In `src/components/TaskCard.vue`, add a function to the script:

```javascript
function startDrag(event) {
  event.dataTransfer.setData("text/plain", String(props.card.id));
}
```

And make the `<article>` draggable, keeping its other attributes:

```vue
<article
  :id="`card-${card.id}`"
  :title="card.title"
  class="card"
  :class="{ overdue: isOverdue(card), done: card.status === 'done' }"
  draggable="true"
  @dragstart="startDrag"
  @click="showDetails"
>
```

`draggable="true"` lets the user drag the element. On `dragstart`, `event.dataTransfer.setData` stores the card's id as text in the drag data, which travels with the drag until the drop.

In `src/components/BoardColumn.vue`, store the props in a variable, add a `status` prop, declare the new event, and handle the drop:

```javascript
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  cards: {
    type: Array,
    required: true,
  },
  color: {
    type: String,
    default: "#9ca3af",
  },
  status: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["move", "edit", "delete", "drop-card"]);

function handleDrop(event) {
  const cardId = Number(event.dataTransfer.getData("text/plain"));
  emit("drop-card", cardId, props.status);
}
```

```vue
<section
  class="column"
  :style="{ borderTopColor: color }"
  @dragover.prevent
  @drop="handleDrop"
>
```

By default, elements refuse drops. `@dragover.prevent` cancels the `dragover` event's default behavior, which is how an element says "you may drop here"; the `.prevent` modifier does it without any handler code. On `drop`, the column reads the id back, converts it to a number (drag data is always text, like route parameters), and emits it with its own status.

In `src/views/BoardView.vue`, pass the status to each column, listen to the event, and add the handler:

```vue
<BoardColumn
  v-for="column in columns"
  :key="column.status"
  :title="column.title"
  :status="column.status"
  :color="column.color"
  :cards="cardsFor(column.status)"
  @move="moveCard"
  @edit="openEditForm"
  @delete="deleteCard"
  @drop-card="dropCard"
>
```

```javascript
function dropCard(cardId, status) {
  const card = board.findCard(cardId);
  if (card.status === status) {
    return;
  }
  const from = columnTitle(card.status);
  board.updateCard(cardId, { status });
  message.value = `Moved "${card.title}" from ${from} to ${columnTitle(status)}.`;
}
```

Dropping a card on its own column does nothing. Otherwise the store changes the status, and the status line reports the move. Dragging "Write project brief" onto Done, then "Pick color palette" onto To Do, gives:

```text
dragover prevented: true
after dragging card 1 to Done: To Do (1) | In Progress (2) | Done (3) | Moved "Write project brief" from To Do to Done.
after dragging card 5 to To Do: To Do (2) | In Progress (2) | Done (2) | Moved "Pick color palette" from Done to To Do.
URL: /board
```

The first line confirms that the column accepted the drop; the last line shows that dragging did not open the card's page. This is a working starting point, not a finished feature. Ideas to take it further on your own: highlight a column while a card is dragged over it, choose the position of the card within a column instead of always following the array order, and support touch screens, where the HTML Drag and Drop API does not work. Libraries such as SortableJS, or Vue wrappers built on it, solve those problems once you understand what they do for you.

---

## 10. What You Built and What's Next

You started this course with a counter in a single HTML file and finished with Tasklane, a complete application you can publish and show. Along the way you learned the core of Vue:

- **Templates and components:** interpolation, `v-bind`, single-file components, props, `v-for` with keys, `v-if` and `v-show`, class and style bindings, and slots
- **Interactivity:** events and `defineEmits`, reactive state with `ref` and `reactive`, forms with `v-model`, and `defineModel` for your own components
- **Derived data and side effects:** computed properties, `watch` and `watchEffect`, lifecycle hooks, and template refs
- **Data and reuse:** `fetch` with loading and error states, `localStorage`, and composables
- **Applications:** Vue Router with dynamic routes, and shared state with Pinia
- **Working with AI:** writing prompts with context, reading generated code in a fixed order, testing edge cases, recognizing the Options API, and fixing the bugs AI tools produce most often

Here are good next steps, roughly in order:

1. **Finish drag and drop.** Start from Exercise 3 and add the improvements listed there. It is a great feature to show in your portfolio.
2. **Build a second app on your own.** A habit tracker, a recipe book, or a reading list. Building without step-by-step instructions is where the knowledge settles.
3. **Add tests.** Vitest and Vue Test Utils let you test components and stores automatically. `npm create vue@latest` can add them to a new project with the `--vitest` option.
4. **Learn TypeScript with Vue.** Types catch many of the errors from this course before the code runs. create-vue supports it with `--ts`.
5. **Explore the ecosystem.** VueUse offers hundreds of ready-made composables, and Nuxt is a framework built on Vue for server rendering, file-based routing, and full-stack apps.
6. **Keep using AI, critically.** Use the review checklist from Lesson 21 every time. The better you know Vue, the more an AI assistant can help you, because you can tell good suggestions from bad ones.

Thank you for building Tasklane all the way to the end. You are no longer someone who copies Vue code and hopes it works; you are a developer who can write it, read it, and fix it.
