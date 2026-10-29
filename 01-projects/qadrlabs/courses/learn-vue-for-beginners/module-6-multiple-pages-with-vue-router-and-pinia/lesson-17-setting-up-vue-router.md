## 1. Before You Begin

At the end of Module 5, Tasklane is a capable single-page board: it saves its data, imports tasks from an API, and keeps its logic in components and composables. But everything lives on one screen, at one address. Real apps have several pages, such as a home page, a dashboard, and an about page, and each page has its own address that you can bookmark, share, or open in a new tab. The browser's back and forward buttons work between them.

In a single-page application, those pages are not separate HTML files. The app swaps components in and out depending on the address in the browser. The official tool for this in Vue is **Vue Router**. In this lesson you will install it, move the board into its own page component, add Home, About, and "not found" pages, navigate between them with `RouterLink`, and render the current page with `RouterView`.

### What You'll Build

Tasklane with a navigation bar on the right of the header: Home, Board, and About. The Home page at `/` welcomes the user and shows how many open cards they have, with a button to open the board. The board lives at `/board`, and an About page at `/about` explains the app. The active link is highlighted. Any other address, such as `/boards`, shows a "Page not found" page with a link back home. The back and forward buttons of the browser work between pages.

### What You'll Learn

- ✅ What client-side routing is, and how a single-page app shows several pages
- ✅ How to install Vue Router and register it with `app.use(router)`
- ✅ How to define routes that map paths to page components
- ✅ How to render the current page with `RouterView` and link to pages with `RouterLink`
- ✅ How to highlight the active link with the classes Vue Router adds
- ✅ How to catch unknown addresses with a "not found" route

### What You'll Need

- The Tasklane project from Lesson 16, with the development server running
- An internet connection to install Vue Router

---

## 2. Install Vue Router

Vue Router is a separate package maintained by the Vue team. It was not added when you created the project in Lesson 2, so you will install it now.

### Step 1: Install the Package

Stop the development server with `Ctrl+C`, or open a second terminal in the `tasklane` folder, and run:

```bash
npm install vue-router
```

Output:

```text
added 29 packages, and audited 252 packages in 4s

67 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`npm install vue-router` downloads the package, adds it to `node_modules`, and records it in the `dependencies` section of `package.json`:

```json
"dependencies": {
  "vue": "^3.5.42",
  "vue-router": "^5.4.0"
},
```

This course uses Vue Router 5. The basic routing API you will use, `createRouter`, `RouterLink`, `RouterView`, `useRoute`, and `useRouter`, is the same one Vue Router 4 introduced, so tutorials and documentation for version 4 still apply. Your version number may be newer. Start the development server again with `npm run dev`.

---

## 3. Create the Pages and the Router

Components that represent a whole page are usually called **views** and live in a `src/views` folder, separate from the smaller, reusable pieces in `src/components`. Vue Router's job is to decide which view to show for the current address.

### Step 1: Move the Board into BoardView

Everything in `App.vue` except the header is the board, so the board becomes a page. Create a folder named `views` inside `src`, and create `src/views/BoardView.vue` by copying the **whole** contents of `src/App.vue` into it. Then make three changes in the new file:

1. Delete the `AppHeader` import line, because the header stays in `App.vue`.
2. Every import that starts with `./` must start with `../` instead, because the file is now one folder deeper. For example:

```javascript
import BaseModal from "../components/BaseModal.vue";
import BoardColumn from "../components/BoardColumn.vue";
import CardForm from "../components/CardForm.vue";
import FilterBar from "../components/FilterBar.vue";
import { useFetchJson } from "../composables/useFetchJson.js";
import { useLocalStorage } from "../composables/useLocalStorage.js";
import { columns, sampleCards } from "../data/board.js";
import { isOverdue } from "../utils/dates.js";
```

3. In the template, delete `<AppHeader />` and change the `<main>` wrapper to a `<section>`. The beginning and end of the template look like this:

```vue
<template>
  <section>
    <div class="toolbar">
      <h2>{{ boardName }}</h2>
```

```vue
      </BoardColumn>
    </div>
  </section>
</template>
```

The `<main>` element now belongs to `App.vue`, which wraps every page in it. The script, the rest of the template, and the styles of `BoardView.vue` stay exactly as they were in `App.vue`.

### Step 2: Create the Other Views

Create `src/views/HomeView.vue`:

```vue
<script setup>
import { computed } from "vue";
import { RouterLink } from "vue-router";
import { useLocalStorage } from "../composables/useLocalStorage.js";
import { sampleCards } from "../data/board.js";

const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));
const openCount = computed(() => cards.value.filter((card) => card.status !== "done").length);
</script>

<template>
  <section class="home">
    <h2>Welcome to Tasklane</h2>
    <p>
      Tasklane keeps your work in three columns: To Do, In Progress, and Done. Add a card for
      every task, move it forward as you work, and watch the board empty out.
    </p>
    <p class="summary">You have {{ openCount }} open cards on your board.</p>
    <RouterLink to="/board" class="button-link">Open the board</RouterLink>
  </section>
</template>

<style scoped>
.home {
  max-width: 640px;
}

.summary {
  font-weight: 600;
}

.button-link {
  display: inline-block;
  padding: 8px 16px;
  border-radius: 6px;
  background-color: #4f46e5;
  color: #ffffff;
  text-decoration: none;
}

.button-link:hover {
  background-color: #4338ca;
}
</style>
```

Here is what it does:

- `useLocalStorage("tasklane-cards", ...)` reads the same saved cards as the board, thanks to the composable from Lesson 16. The home page only needs to count them.
- `openCount` counts the cards that are not done.
- `RouterLink` is a component from Vue Router that renders a link. `to="/board"` is the address it leads to. The class `button-link` makes it look like a button. It is imported explicitly here, like any other component.

Create `src/views/AboutView.vue`:

```vue
<template>
  <section class="about">
    <h2>About Tasklane</h2>
    <p>
      Tasklane is a Kanban board built step by step in the qadrlabs course "Learn Vue for
      Beginners". It uses Vue 3, Vite, Vue Router, and the browser's localStorage.
    </p>
    <p>Your cards are saved in this browser only. Nothing is sent to a server.</p>
  </section>
</template>

<style scoped>
.about {
  max-width: 640px;
}
</style>
```

And create `src/views/NotFoundView.vue`:

```vue
<script setup>
import { RouterLink } from "vue-router";
</script>

<template>
  <section>
    <h2>Page not found</h2>
    <p>There is no page at this address.</p>
    <RouterLink to="/">Go to the home page</RouterLink>
  </section>
</template>
```

Both are plain components; nothing about them is special until the router connects them to addresses.

### Step 3: Define the Routes

Create a folder named `router` inside `src`, and inside it a file named `index.js`:

```javascript
import { createRouter, createWebHistory } from "vue-router";
import HomeView from "../views/HomeView.vue";
import BoardView from "../views/BoardView.vue";
import AboutView from "../views/AboutView.vue";
import NotFoundView from "../views/NotFoundView.vue";

const routes = [
  { path: "/", name: "home", component: HomeView },
  { path: "/board", name: "board", component: BoardView },
  { path: "/about", name: "about", component: AboutView },
  { path: "/:pathMatch(.*)*", name: "not-found", component: NotFoundView },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});
```

Here is what it does:

- Each object in `routes` is a **route**: it maps a `path` to the `component` that should be shown there. The `name` is optional, but it lets you refer to a route without repeating its path, as you will do in Exercise 1.
- `/:pathMatch(.*)*` is the **catch-all** route. `:pathMatch` is a route parameter, and `(.*)*` is a pattern that matches any path, including ones with several slashes. Vue Router checks routes from the most specific to the least specific, so this route only matches when no other route does. You will learn route parameters properly in Lesson 18.
- `createRouter({ ... })` creates the router with the list of routes.
- `createWebHistory()` makes the router use normal-looking addresses such as `/board`, through the browser's History API. The Vite development server is already configured to answer every address with `index.html`, so opening `http://localhost:5173/board` directly works. A production server needs the same setting, which Lesson 22 covers.
- `export const router` makes the router available to `main.js`.

### Step 4: Register the Router and Render the Pages

Open `src/main.js` and register the router with the app:

```javascript
import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router/index.js'
import './assets/main.css'

createApp(App).use(router).mount('#app')
```

`.use(router)` installs the router as a **plugin**: it makes `RouterLink` and `RouterView` work, and lets every component reach the router. The file keeps the single quotes of the generated code.

Now replace the contents of `src/App.vue` with this much shorter version:

```vue
<script setup>
import { RouterView } from "vue-router";
import AppHeader from "./components/AppHeader.vue";
</script>

<template>
  <AppHeader />

  <main>
    <RouterView />
  </main>
</template>
```

`RouterView` is a placeholder: the router renders the view that matches the current address in its place. `App.vue` is now the **layout** shared by every page: the header on top, and the current page below it.

### Step 5: Add Navigation Links to the Header

Replace the contents of `src/components/AppHeader.vue` with this code:

```vue
<script setup>
import { RouterLink } from "vue-router";

defineProps({
  tagline: {
    type: String,
    default: "Plan your work, one card at a time.",
  },
});
</script>

<template>
  <header>
    <div>
      <h1>Tasklane</h1>
      <p>{{ tagline }}</p>
    </div>
    <nav>
      <RouterLink to="/">Home</RouterLink>
      <RouterLink to="/board">Board</RouterLink>
      <RouterLink to="/about">About</RouterLink>
    </nav>
  </header>
</template>

<style scoped>
header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 8px;
}

h1 {
  margin: 0;
}

p {
  margin: 0;
  color: #6b7280;
}

nav {
  display: flex;
  gap: 4px;
}

nav a {
  padding: 6px 12px;
  border-radius: 6px;
  color: #374151;
  text-decoration: none;
}

nav a:hover {
  background-color: #e5e7eb;
}

nav a.router-link-exact-active {
  background-color: #4f46e5;
  color: #ffffff;
}
</style>
```

Here is what is new:

- The heading and tagline are wrapped in a `<div>`, and a `<nav>` with three `RouterLink`s sits next to them. The flexbox rules on `header` put the navigation on the right.
- `RouterLink` renders an ordinary `<a>` element, so the `nav a` rules style it.
- Vue Router adds the class `router-link-exact-active` to the link whose address exactly matches the current page. The last rule highlights it in indigo. It also adds `router-link-active` to links whose address is the start of the current one, which is useful for menus with sub-pages.

Save all files.

---

## 4. Run and Test

Restart the development server if needed, delete the `tasklane-cards` key in the Application tab, and open `http://localhost:5173`. The Home page appears, with the "Home" link highlighted.

The address, the highlighted link, and the text of the page:

```text
-- home  URL: /  ACTIVE: Home
Welcome to Tasklane

Tasklane keeps your work in three columns: To Do, In Progress, and Done. Add a card for every task, move it forward as you work, and watch the board empty out.

You have 4 open cards on your board.

Open the board
```

Click "Open the board". The address changes to `/board`, and the board appears with all its features:

```text
-- after Open the board: URL /board | H3s: To Do (2) | In Progress (2) | Done (2)
```

Move "Write project brief" and "Design home page" forward, then click "About":

```text
-- about  URL: /about  ACTIVE: About
About Tasklane

Tasklane is a Kanban board built step by step in the qadrlabs course "Learn Vue for Beginners". It uses Vue 3, Vite, Vue Router, and the browser's localStorage.

Your cards are saved in this browser only. Nothing is sent to a server.
```

Now click "Home". The count reflects the moves you just made on the board:

```text
-- home again  URL: /  ACTIVE: Home
Welcome to Tasklane

Tasklane keeps your work in three columns: To Do, In Progress, and Done. Add a card for every task, move it forward as you work, and watch the board empty out.

You have 3 open cards on your board.

Open the board
```

"Design home page" is now done, so three cards are open. The home page read the saved board from `localStorage` when it was created. Press the browser's back button, and you are on `/about` again:

```text
-- back button: URL /about
```

Next, type an address that does not exist, `http://localhost:5173/boards`, into the address bar:

```text
-- typed /boards  URL: /boards  ACTIVE: 
Page not found

There is no page at this address.

Go to the home page
```

No link is highlighted, because none matches. Finally, open `http://localhost:5173/board` directly. The board appears with your moves still in place:

```text
-- direct /board: H3s To Do (1) | In Progress (2) | Done (3)
```

Inspect the navigation bar on the board page:

```html
<nav data-v-48a13218=""><a data-v-48a13218="" href="/" class="">Home</a><a data-v-48a13218="" href="/board" class="router-link-active router-link-exact-active" aria-current="page">Board</a><a data-v-48a13218="" href="/about" class="">About</a></nav>
```

Each `RouterLink` became an `<a>` with a real `href`, so right-clicking "Open link in new tab" works. The active link has both classes, plus `aria-current="page"`, which tells screen readers which page is current.

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

## 5. Fix the Errors in Your Code

These are the most common mistakes when setting up Vue Router.

**Error 1: Forgetting to register the router.**

```javascript
// Wrong
createApp(App).mount('#app')

// Correct
createApp(App).use(router).mount('#app')
```

With the wrong version, the page is blank, and the console shows:

```text
[Vue warn]: injection "Symbol(router)" not found. 
  at <RouterLink to="/" > 
  at <AppHeader > 
  at <App>
[Vue warn]: injection "Symbol(route location)" not found. 
  at <RouterLink to="/" > 
  at <AppHeader > 
  at <App>
[Vue warn]: Unhandled error during execution of setup function 
  at <RouterLink to="/" > 
  at <AppHeader > 
  at <App>
TypeError: Cannot read properties of undefined (reading 'resolve')
```

`RouterLink` looks for the router that `app.use(router)` normally provides to all components, and finds nothing. "Injection not found" warnings almost always mean a plugin was not installed. Add `.use(router)`.

**Error 2: Using a plain `<a href>` instead of `RouterLink`.**

```vue
<!-- Wrong -->
<a href="/board">Board</a>

<!-- Correct -->
<RouterLink to="/board">Board</RouterLink>
```

The wrong version seems to work: clicking "Board" shows the board. But to see what really happened, set a variable in the console with `window.marker = "still here"` and then click the link. With the plain `<a>`:

```text
URL: /board | marker: undefined
```

With `RouterLink`:

```text
URL: /board | marker: still here
```

The plain link made the browser load the whole page again from the server, which wiped every JavaScript variable and restarted the app. The page flashes, takes longer, and any state that was not saved, such as an open form, is lost. `RouterLink` intercepts the click and lets Vue Router switch the view without reloading. Use `RouterLink` for every link inside your app, and plain `<a>` only for links to other websites.

**Error 3: Using the old `*` catch-all syntax.**

Tutorials for older versions of Vue Router write the catch-all route as `*`.

```javascript
// Wrong
{ path: "*", name: "not-found", component: NotFoundView },

// Correct
{ path: "/:pathMatch(.*)*", name: "not-found", component: NotFoundView },
```

With the wrong version, the page is blank, and the console shows:

```text
Error: Catch all routes ("*") must now be defined using a param with a custom regexp.
See more at https://router.vuejs.org/guide/migration/#Removed-star-or-catch-all-routes.
```

AI tools trained on older code still produce the `*` form. The error message tells you exactly what to do, and links to the migration guide.

---

## 6. Exercises

**Exercise 1:** Change the three links in `AppHeader.vue` to use the route names instead of paths, with `:to="{ name: 'home' }"` and so on. Check in the Elements panel that the rendered `href` values are unchanged. Why can named routes be safer than paths?

**Exercise 2:** The About page is rarely visited, so there is no need to load its code before someone opens it. Change its route to load the component lazily with `component: () => import("../views/AboutView.vue")`, and remove the static import. Check in the Network tab when `AboutView.vue` is requested.

**Exercise 3:** Some users will type `/home`. Add a route that **redirects** `/home` to `/`, so typing `http://localhost:5173/home` lands on the home page with the address `/`.

---

## 7. Solutions

**Solution for Exercise 1:**

Change the navigation in `src/components/AppHeader.vue`:

```vue
<nav>
  <RouterLink :to="{ name: 'home' }">Home</RouterLink>
  <RouterLink :to="{ name: 'board' }">Board</RouterLink>
  <RouterLink :to="{ name: 'about' }">About</RouterLink>
</nav>
```

`:to` is bound with a colon now, because its value is an object. The navigation bar on the home page:

```html
<nav data-v-48a13218=""><a data-v-48a13218="" href="/" class="router-link-active router-link-exact-active" aria-current="page">Home</a><a data-v-48a13218="" href="/board" class="">Board</a><a data-v-48a13218="" href="/about" class="">About</a></nav>
```

The `href` values are the same. The advantage appears when a path changes: if you rename `/board` to `/my-board` in `router/index.js`, every link that uses `{ name: 'board' }` follows automatically, while every hard-coded `"/board"` would have to be found and changed by hand.

**Solution for Exercise 2:**

In `src/router/index.js`, delete the `import AboutView ...` line and change the route:

```javascript
{ path: "/about", name: "about", component: () => import("../views/AboutView.vue") },
```

`() => import(...)` is a function that loads the file only when it is called. Vue Router calls it the first time someone navigates to `/about`. Open the Network tab, load the home page, and you see no request for `AboutView.vue`. Click "About", and the request appears at that moment; the page shows "About Tasklane" as before. In the production build of Lesson 22, Vite puts lazily loaded views into separate files, so the first page of the app loads faster. Large apps load most of their pages this way.

**Solution for Exercise 3:**

Add one route to the `routes` array, before the catch-all:

```javascript
{ path: "/home", redirect: "/" },
```

A route with `redirect` has no component; it sends the user to another address. Typing `http://localhost:5173/home`:

```text
typed /home -> URL: / | Welcome to Tasklane
```

The address bar shows `/`, not `/home`, so there is only ever one address for the home page. Undo these exercise changes before the next lesson, so your code matches Lesson 18.

---

## 8. How Client-Side Routing Works

In a traditional website, every page is a separate HTML file. Clicking a link sends a request to the server, which sends back a whole new page, and the browser throws away the old one, including all of its JavaScript state.

In a single-page application with Vue Router, the server always sends the same `index.html`. From then on:

1. When you click a `RouterLink`, Vue Router stops the browser from loading a new page.
2. It changes the address in the address bar with the browser's History API, so the back button and bookmarks keep working.
3. It looks up the matching route and tells `RouterView` which component to show.
4. Vue unmounts the old view and mounts the new one, while everything outside `RouterView`, such as the header, stays in place.

Step 4 has a consequence you should remember: when you leave a page, its component is destroyed, and its local state is gone. That is why the home page counted the cards again from `localStorage` instead of seeing the board's `cards` ref. The board and the home page each have their own copy of the data, connected only through storage. That works for now, but it becomes a problem as soon as two parts of the screen are visible at the same time and must stay in sync. You will hit exactly that problem in Lesson 18 and solve it with Pinia in Lesson 19.

---

## Next Up - Lesson 18

In this lesson you turned Tasklane into a multi-page app. You installed Vue Router, moved the board into `BoardView`, created Home, About, and "not found" views, defined routes with `createRouter` and `createWebHistory`, rendered the current page with `RouterView`, linked between pages with `RouterLink`, and highlighted the active link.

In Lesson 18, every card gets its own page. You will create a dynamic route, `/cards/:id`, read the id with `useRoute`, navigate in code with `useRouter`, and build a card detail page that opens when you click a card on the board.
