## 1. Before You Begin

In Lesson 15, Tasklane imported tasks from a public API, with a loading state, an error state, and `try`, `catch`, and `finally`. The feature works, but look at what `App.vue` has become: it manages cards, a form, filters, stats, a modal, saving to `localStorage`, and network requests, all in one script. Some of that logic has nothing to do with a Kanban board. "Keep a value in `localStorage`" or "fetch some JSON and track loading and errors" could be useful in any app.

Vue's answer is the **composable**: a plain JavaScript function that uses Vue's reactivity APIs, such as `ref`, `computed`, `watch`, and lifecycle hooks, to bundle state and logic so they can be reused. In this lesson you will extract two composables from `App.vue`, `useLocalStorage` and `useFetchJson`, and learn the conventions every composable follows.

### What You'll Build

Two new files in `src/composables/`. `useLocalStorage(key, defaultValue)` returns a ref that loads its value from `localStorage` and saves every change automatically. `useFetchJson()` returns `loading` and `error` refs plus a `fetchJson(url)` function. `App.vue` uses both, becomes shorter, and works exactly as before: the board survives a refresh, and "Import tasks" shows the same loading and error states.

### What You'll Learn

- ✅ What a composable is and why it is useful
- ✅ The conventions composables follow: the `use` prefix, a `composables` folder, and returning refs
- ✅ How to move a ref and its watcher into a composable
- ✅ How to wrap a request's loading and error state in a composable
- ✅ Why composables must be called at the top level of `<script setup>`
- ✅ Why destructuring refs from a composable is safe, unlike destructuring a `reactive` object

### What You'll Need

- The Tasklane project from Lesson 15, with the development server running
- Your browser open at `http://localhost:5173`

---

## 2. Extract useLocalStorage

Look at the code that saves the board. It is spread over three places in `App.vue`: the `STORAGE_KEY` constant, the `loadCards` function, and the deep `watch`. Together they implement one idea: "this ref lives in `localStorage`." A composable can wrap that idea into a single function call.

### Step 1: Create the Composable

Create a folder named `composables` inside `src`, and inside it a file named `useLocalStorage.js` with this code.

```javascript
import { ref, watch } from "vue";

export function useLocalStorage(key, defaultValue) {
  const saved = localStorage.getItem(key);
  const data = ref(saved === null ? defaultValue : JSON.parse(saved));

  watch(
    data,
    (newValue) => {
      localStorage.setItem(key, JSON.stringify(newValue));
    },
    { deep: true },
  );

  return data;
}
```

This is the same logic you wrote in Lesson 13, made general:

- `useLocalStorage(key, defaultValue)` takes the storage key and the value to use when nothing is saved yet. Nothing in it mentions cards, so it works for any value that can be turned into JSON.
- `const data = ref(...)` creates a ref with either the saved value or the default.
- The `watch` saves the ref whenever it changes, with `deep` so changes inside arrays and objects count.
- `return data;` hands the ref to whoever called the composable.

The function name starts with `use`. That is the convention for composables: it tells every reader that the function creates reactive state and must be called like a composable, as you will see in Section 5. The file is plain `.js`, not `.vue`, because a composable has no template.

### Step 2: Use It in App.vue

Open `src/App.vue`. Import the composable next to the other imports:

```javascript
import { useLocalStorage } from "./composables/useLocalStorage.js";
```

Delete the `STORAGE_KEY` constant and the whole `loadCards` function, and replace the line that creates `cards`:

```javascript
const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));
```

Then delete the deep `watch` that saved the cards. The composable does that now. Finally, `watch` is no longer used in `App.vue`, so remove it from the Vue import:

```javascript
import { computed, ref, watchEffect } from "vue";
```

Notice what did not change: every function that uses `cards.value`, every computed property, and the whole template. `useLocalStorage` returns a normal ref, so the rest of the component cannot tell the difference. Save both files.

---

## 3. Extract useFetchJson

The import logic mixes two different concerns. One is general: send a request, track `loading` and `error`, check `response.ok`, parse JSON. The other is specific to Tasklane: turn to-dos into cards and add them to the board. The general part can become a composable.

### Step 1: Create the Composable

Create `src/composables/useFetchJson.js` with this code.

```javascript
import { ref } from "vue";

export function useFetchJson() {
  const loading = ref(false);
  const error = ref("");

  async function fetchJson(url) {
    loading.value = true;
    error.value = "";

    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`The server answered with status ${response.status}.`);
      }
      return await response.json();
    } catch (err) {
      error.value = err.message;
      return null;
    } finally {
      loading.value = false;
    }
  }

  return { loading, error, fetchJson };
}
```

Here is what it contains:

- `loading` and `error` are the same two refs you had in `App.vue` as `importing` and `importError`, with general names.
- `fetchJson(url)` is the `try`, `catch`, and `finally` structure from Lesson 15, without anything about cards. On success, it returns the parsed data. On failure, it stores the error message and returns `null`, so the caller can tell that something went wrong without its own `try`.
- The `catch` parameter is named `err` so it does not hide the `error` ref, which the block needs to set.
- `return { loading, error, fetchJson };` returns an object with the state and the function. Composables that provide several things usually return a plain object of refs and functions.

### Step 2: Use It in App.vue

Import the composable in `src/App.vue`:

```javascript
import { useFetchJson } from "./composables/useFetchJson.js";
```

Replace the two refs `importing` and `importError` with a single line:

```javascript
const { loading: importing, error: importError, fetchJson } = useFetchJson();
```

And replace the whole `importTasks` function with this much shorter version:

```javascript
async function importTasks() {
  const data = await fetchJson(TODOS_URL);
  if (data === null) {
    return;
  }

  for (const todo of data.todos) {
    cards.value.push({ id: nextId(), ...todoToCard(todo) });
  }
  message.value = `Imported ${data.todos.length} tasks from DummyJSON.`;
}
```

Here is what changed:

- The destructuring line takes the three values out of the returned object. `loading: importing` renames `loading` to `importing`, and `error: importError` renames `error` to `importError`, so the template does not need to change. Renaming while destructuring is plain JavaScript.
- `importTasks` now only contains Tasklane's part of the job: get the data, stop if it is `null`, convert and add the cards, and report.

The composable stores only the error itself, such as `The server answered with status 404.`, so the error paragraph in the template adds the "Could not import tasks." part:

```vue
<p v-if="importError !== ''" class="error">Could not import tasks. {{ importError }}</p>
```

Here is the beginning of the `<script setup>` block of `App.vue` after both extractions:

```javascript
import { computed, ref, watchEffect } from "vue";
import AppHeader from "./components/AppHeader.vue";
import BaseModal from "./components/BaseModal.vue";
import BoardColumn from "./components/BoardColumn.vue";
import CardForm from "./components/CardForm.vue";
import FilterBar from "./components/FilterBar.vue";
import { useFetchJson } from "./composables/useFetchJson.js";
import { useLocalStorage } from "./composables/useLocalStorage.js";
import { columns, sampleCards } from "./data/board.js";
import { isOverdue } from "./utils/dates.js";

const TODOS_URL = "https://dummyjson.com/todos?limit=3";

const boardName = "Website Redesign";
const cards = useLocalStorage("tasklane-cards", structuredClone(sampleCards));
const message = ref("Use the buttons on a card to move, edit, or delete it.");
const showForm = ref(false);
const editingCard = ref(null);
const search = ref("");
const priorityFilter = ref("all");
const { loading: importing, error: importError, fetchJson } = useFetchJson();
```

The computed properties, the `watchEffect` for the tab title, and the other functions stay as they were. Save both files.

---

## 4. Run and Test

A refactoring like this one should change how the code is organized, not what the app does. So the test is: everything works exactly as before. Restart the development server, open `http://localhost:5173`, delete the `tasklane-cards` key in the Application tab, and refresh.

First, persistence. Move "Write project brief" to In Progress, add a card titled `Write SEO checklist`, delete "Set up hosting", and refresh the page. The tab title, the column headers, and the cards after the refresh:

```text
TITLE: Tasklane (4 open)
H3s: To Do (2) | In Progress (2) | Done (2)
COLS: Collect logo files, Write SEO checklist || Write project brief, Design home page || Pick color palette, Write About page text
```

This is the same result as in Lesson 13: `useLocalStorage` saved every change.

Next, the import. Clean the board again, refresh, and click "Import tasks":

```text
BUTTON before: Import tasks / + New card
BUTTON right after click: Importing... (disabled) / + New card
BUTTON after: Import tasks / + New card
4 of 9 cards done (44%), 1 overdue
Imported 3 tasks from DummyJSON.
H3s: To Do (3) | In Progress (2) | Done (4)
```

The same loading state and the same result as in Lesson 15. Finally, change `TODOS_URL` to `https://dummyjson.com/todoz?limit=3`, refresh with a clean board, and import:

```text
Could not import tasks. The server answered with status 404.
Use the buttons on a card to move, edit, or delete it.
H3s: To Do (2) | In Progress (2) | Done (2)
```

The error message is identical too, now assembled from the template's text and the composable's `error`. Change the address back. Your `src` folder now looks like this:

```text
src/
├── assets/
│   └── main.css
├── components/
│   ├── AppHeader.vue
│   ├── BaseModal.vue
│   ├── BoardColumn.vue
│   ├── CardForm.vue
│   ├── FilterBar.vue
│   └── TaskCard.vue
├── composables/
│   ├── useFetchJson.js
│   └── useLocalStorage.js
├── data/
│   └── board.js
├── utils/
│   └── dates.js
├── App.vue
└── main.js
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

No problems are reported.

---

## 5. Fix the Errors in Your Code

These are the most common mistakes when writing and using composables.

**Error 1: Returning the value instead of the ref.**

```javascript
// Wrong
return data.value;

// Correct
return data;
```

With the wrong version, the page is blank, and the console shows errors that end with:

```text
TypeError: Cannot read properties of undefined (reading 'length')
```

`App.vue` received the array itself, not a ref. Every `cards.value` in `App.vue` is now `undefined`, because an array has no `value` property, and the first computed property that reads `cards.value.length` crashes. A composable should return refs, so the caller keeps a live connection to the state. That is also why `.value` stays the same in the calling code.

**Error 2: Calling a composable inside a function.**

It can look tidy to call a composable only where it is needed:

```javascript
// Wrong
const importing = ref(false);
const importError = ref("");

async function importTasks() {
  const { fetchJson } = useFetchJson();
  const data = await fetchJson(TODOS_URL);
  // ...
}

// Correct
const { loading: importing, error: importError, fetchJson } = useFetchJson();

async function importTasks() {
  const data = await fetchJson(TODOS_URL);
  // ...
}
```

With the wrong version, the import still adds cards, but the loading state is gone. Right after clicking, the button reads:

```text
BUTTON right after click: Import tasks / + New card
```

And with a wrong address, no error appears at all:

```text
Use the buttons on a card to move, edit, or delete it.
```

Every call to `useFetchJson()` creates **new** `loading` and `error` refs. The ones created inside `importTasks` change correctly, but nothing in the template is connected to them, and they are thrown away when the function ends. Composables must be called at the top level of `<script setup>`, once, when the component is created. That is the same rule as for lifecycle hooks such as `onMounted`, which many composables use internally.

**Error 3: Forgetting to return something from the composable.**

```javascript
// Wrong
return { loading, error };

// Correct
return { loading, error, fetchJson };
```

With the wrong version, the page loads, but clicking "Import tasks" shows:

```text
[Vue warn]: Unhandled error during execution of native event handler 
  at <App>
TypeError: fetchJson is not a function
```

Destructuring a property that does not exist gives `undefined`, and calling `undefined` fails. Everything a caller needs must be in the returned object.

---

## 6. Exercises

**Exercise 1:** Use `useLocalStorage` for the priority filter as well, under the key `tasklane-priority`, so the selected priority survives a refresh. Compare the amount of code with Lesson 13's Exercise 2. What does the saved value look like in the Application tab, and why?

**Exercise 2:** Create a composable `useDocumentTitle(getTitle)` in `src/composables/useDocumentTitle.js` that sets `document.title` to the result of `getTitle()` and keeps it up to date with `watchEffect`. Use it in `App.vue` to replace the existing `watchEffect`.

**Exercise 3:** Create a composable `useOnlineStatus()` that returns a ref which is `true` while the browser is online and `false` while it is offline. Use `navigator.onLine` for the starting value, and the `online` and `offline` events of `window` to update it, added in `onMounted` and removed in `onUnmounted`. Show `You are offline. Importing tasks needs a connection.` in red while the browser is offline.

---

## 7. Solutions

**Solution for Exercise 1:**

Replace the `priorityFilter` line in `src/App.vue`:

```javascript
const priorityFilter = useLocalStorage("tasklane-priority", "all");
```

That is all. One line replaces the starting value and the extra watcher from Lesson 13's Exercise 2. After choosing "High" and refreshing:

```text
-- Exercise 1: SELECT after reload: high | saved: "high"
```

The dropdown still shows "High", and the saved value is `"high"` **with** double quotes. `useLocalStorage` always uses `JSON.stringify`, and the JSON form of a string includes its quotes. `JSON.parse` removes them again when loading, so this is correct; it just looks different from a value saved with plain `setItem`.

**Solution for Exercise 2:**

Create `src/composables/useDocumentTitle.js`:

```javascript
import { watchEffect } from "vue";

export function useDocumentTitle(getTitle) {
  watchEffect(() => {
    document.title = getTitle();
  });
}
```

In `src/App.vue`, import it, replace the `watchEffect` block with one line, and remove `watchEffect` from the Vue import:

```javascript
import { useDocumentTitle } from "./composables/useDocumentTitle.js";
```

```javascript
useDocumentTitle(() => `Tasklane (${cards.value.length - doneCount.value} open)`);
```

The composable takes a **function** rather than a string. `watchEffect` tracks the reactive values that `getTitle()` reads when it runs, so the title updates whenever the cards change. Passing a plain string would freeze the title at its first value. This composable returns nothing, which is fine: some composables only set up an effect. The tab title before and after moving "Design home page" to Done:

```text
-- Exercise 2: TITLE: Tasklane (4 open)
TITLE after moving card 3 to Done: Tasklane (3 open)
```

**Solution for Exercise 3:**

Create `src/composables/useOnlineStatus.js`:

```javascript
import { onMounted, onUnmounted, ref } from "vue";

export function useOnlineStatus() {
  const isOnline = ref(navigator.onLine);

  function update() {
    isOnline.value = navigator.onLine;
  }

  onMounted(() => {
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
  });

  onUnmounted(() => {
    window.removeEventListener("online", update);
    window.removeEventListener("offline", update);
  });

  return isOnline;
}
```

A composable can register lifecycle hooks. They attach to the component that called the composable, so the listeners are added when `App.vue` mounts and removed when it unmounts. In `src/App.vue`, import it, create the ref at the top level, and show the message before the import error:

```javascript
import { useOnlineStatus } from "./composables/useOnlineStatus.js";
```

```javascript
const isOnline = useOnlineStatus();
```

```vue
<p v-if="!isOnline" class="error">You are offline. Importing tasks needs a connection.</p>
```

To test it, switch the Network tab's throttling to "Offline". The red line appears:

```text
-- Exercise 3: offline: You are offline. Importing tasks needs a connection.
```

Switch back to "No throttling", and it disappears again. Undo these exercise changes before the next lesson, so your code matches Lesson 17.

---

## 8. Composable Conventions

You will find composables everywhere in Vue code, including popular collections such as VueUse, which offers hundreds of them. They follow a few conventions that make them easy to recognize and use:

- **The name starts with `use`**, such as `useLocalStorage` or `useFetchJson`. It signals "this creates reactive state, call it at the top level of `<script setup>`".
- **They live in `src/composables/`**, one composable per file, with a named export.
- **They return refs**, usually a single ref or a plain object of refs and functions. A plain object of refs can be destructured safely, because each ref keeps its own connection to the state. Compare that with Lesson 9's Error 2, where destructuring a `reactive` object copied plain values and lost reactivity.
- **Each call creates its own state.** Two components that call `useFetchJson()` get two independent `loading` refs. That is usually what you want; when you want state **shared** between components, you need something else, which is the topic of Lesson 19.
- **They can use anything Vue offers**: `ref`, `computed`, `watch`, `watchEffect`, and lifecycle hooks, which attach to the component that called them.

And a rule of thumb for when to write one: when a piece of logic is not really about the component it sits in, or when two components need the same logic, extract it into a composable. When a function does not use any reactivity, like `isOverdue` in `utils/dates.js`, it is just a normal utility function and does not need the `use` prefix.

---

## Next Up - Lesson 17

In this lesson you learned composables. You extracted `useLocalStorage`, which turns any value into a ref that lives in `localStorage`, and `useFetchJson`, which wraps a JSON request with its loading and error state. `App.vue` got shorter and more focused on the board, and the app works exactly as before. You also learned why composables must be called at the top level and why they return refs. That completes Module 5.

In Module 6, Tasklane grows beyond a single page. In Lesson 17, you will install Vue Router, create Home, Board, and About pages, navigate between them with `RouterLink`, render them with `RouterView`, and add a "not found" page for unknown addresses.
