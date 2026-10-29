## 1. Before You Begin

Module 4 made Tasklane smart and comfortable: computed stats and filters, a board that survives a refresh, and a reusable modal. But all of its data still comes from two places: the sample cards in `board.js` and whatever the user types. Most real apps also load data from a **server** through an **API** (Application Programming Interface): a web address that returns data instead of a web page.

In this lesson Tasklane talks to the outside world for the first time. You will add an "Import tasks" button that loads to-do items from DummyJSON, a free public API for testing and learning. You will fetch the data with `fetch` and `async`/`await`, convert the API's format into Tasklane cards, and handle the three states every network request has: loading, success, and error.

### What You'll Build

An "Import tasks" button in the toolbar. Clicking it disables the button and changes its label to "Importing...". When the response arrives, three new cards appear on the board, the stats update, and the status line reads `Imported 3 tasks from DummyJSON.` If the request fails, for example because the address is wrong or the computer is offline, a red message explains what went wrong, and the board stays as it was.

### What You'll Learn

- ✅ What an API and JSON are, and how to explore an API response in the browser
- ✅ How to request data with `fetch` and wait for it with `async` and `await`
- ✅ Why you must check `response.ok`, and how to read the body with `response.json()`
- ✅ How to convert data from an API's format into your app's format
- ✅ How to track loading and error states with refs
- ✅ How `try`, `catch`, and `finally` handle failures

### What You'll Need

- The Tasklane project from Lesson 14, with the development server running
- Your browser open at `http://localhost:5173`, with the developer tools console open
- An internet connection, to reach `https://dummyjson.com`

---

## 2. Explore the API

Before writing any Vue code, look at the data you are going to load. A good habit with any API is to call it by hand first, so you know exactly what it returns.

### Step 1: Open the API in the Browser

Open this address in a new browser tab:

```text
https://dummyjson.com/todos?limit=3
```

The part after `?` is a **query string**: `limit=3` asks the API for only three items. The browser shows the response as text:

```text
{"todos":[{"id":1,"todo":"Do something nice for someone you care about","completed":false,"userId":152},{"id":2,"todo":"Memorize a poem","completed":true,"userId":13},{"id":3,"todo":"Watch a classic movie","completed":true,"userId":68}],"total":254,"skip":0,"limit":3}
```

This is **JSON**, the same format `JSON.stringify` produced for `localStorage` in Lesson 13. Read it as a JavaScript object: it has a `todos` array with three objects, plus `total` (the API has 254 to-dos), `skip`, and `limit`. Each to-do has an `id`, the text in `todo`, a boolean `completed`, and a `userId`. Some browsers format the JSON nicely or show a tree view; the data is the same.

Notice that a DummyJSON to-do does not look like a Tasklane card. It has `todo` instead of `title`, `completed` instead of `status`, and no `description`, `priority`, or `dueDate`. You will have to convert it.

### Step 2: Fetch the Data in the Console

Go back to the Tasklane tab and paste this code into the console.

```javascript
const response = await fetch("https://dummyjson.com/todos?limit=3");
console.log(response.status, response.ok);
const data = await response.json();
console.log(data.total, data.todos.length);
console.log(JSON.stringify(data.todos[0]));
```

Here is what each line does:

- `fetch(url)` sends a request to the address and returns a **promise**: an object that represents a result that will arrive later. Network requests take time, and JavaScript does not stop the whole page while it waits.
- `await` pauses this code until the promise is settled and gives you its result, here a `Response` object. The browser console allows `await` at the top level; in your own functions, you will need `async`.
- `response.status` is the HTTP status code, and `response.ok` is `true` for codes from 200 to 299, which mean success.
- `response.json()` reads the body of the response and parses it as JSON. Reading the body also takes time, so it returns a promise too, which is why it needs its own `await`.
- The last two lines print the total and the first to-do.

Output in the console:

```text
200 true
254 3
{"id":1,"todo":"Do something nice for someone you care about","completed":false,"userId":152}
```

Status 200 means "OK". The data arrived, and `data.todos` holds the three objects you saw in the browser tab. Now you know what to expect, so it is time to bring it into Tasklane.

---

## 3. Import Tasks into Tasklane

The import has three parts: a function that converts one to-do into a card, an `async` function that fetches the data and adds the cards, and state that tells the user what is happening.

### Step 1: Add the Import State and Functions

Open `src/App.vue`. Add a constant for the API address under `STORAGE_KEY`:

```javascript
const STORAGE_KEY = "tasklane-cards";
const TODOS_URL = "https://dummyjson.com/todos?limit=3";
```

Add two refs after `priorityFilter`:

```javascript
const priorityFilter = ref("all");
const importing = ref(false);
const importError = ref("");
```

Then add two functions before `moveCard`:

```javascript
function todoToCard(todo) {
  return {
    title: todo.todo,
    description: "Imported from DummyJSON.",
    status: todo.completed ? "done" : "todo",
    priority: "medium",
    dueDate: "",
  };
}

async function importTasks() {
  importing.value = true;
  importError.value = "";

  try {
    const response = await fetch(TODOS_URL);
    if (!response.ok) {
      throw new Error(`The server answered with status ${response.status}.`);
    }
    const data = await response.json();

    for (const todo of data.todos) {
      cards.value.push({ id: nextId(), ...todoToCard(todo) });
    }
    message.value = `Imported ${data.todos.length} tasks from DummyJSON.`;
  } catch (error) {
    importError.value = `Could not import tasks. ${error.message}`;
  } finally {
    importing.value = false;
  }
}
```

Take the state first:

- `importing` is `true` while a request is running. The template will use it to disable the button and change its label.
- `importError` holds an error message, or an empty string when everything is fine.

`todoToCard(todo)` converts one DummyJSON to-do into Tasklane's card format. The to-do's text becomes the title, a finished to-do goes into Done and the others into To Do, and the fields the API does not have get sensible defaults. It does not set an `id`, because Tasklane's ids come from `nextId()`, not from DummyJSON. Keeping this conversion in its own small function means that if the API ever changes, only one function needs to change.

`importTasks()` does the work:

- `async function` marks the function as asynchronous, which allows `await` inside it. An async function always returns a promise.
- The first two lines set the loading state and clear any old error.
- `try { ... }` contains the code that might fail. A request can fail for many reasons: no internet, a wrong address, a server error.
- `if (!response.ok)` checks the status code. `fetch` only throws an error when the request cannot be sent at all, for example when you are offline. A "404 Not Found" or "500 Server Error" response still counts as a successful request, so you must check `ok` yourself. `throw new Error(...)` jumps straight to `catch` with a helpful message.
- `const data = await response.json();` reads and parses the body.
- The `for...of` loop converts each to-do and adds it with a fresh id. `nextId()` runs again for every card, and because each `push` adds a card with a higher id, the three cards get three different ids.
- `catch (error)` runs if anything inside `try` threw an error. `error.message` describes what went wrong.
- `finally` runs in every case, success or failure, so `importing` is always switched off again. Without it, a failed request would leave the button disabled forever.

You do not need to save the imported cards yourself. They are pushed into `cards`, and the deep watcher from Lesson 13 saves them to `localStorage` automatically.

### Step 2: Add the Button and the Error Message

In the template, wrap the toolbar's "+ New card" button in a `<div>` together with the new import button:

```vue
<div class="toolbar">
  <h2>{{ boardName }}</h2>
  <div>
    <button type="button" :disabled="importing" @click="importTasks">
      {{ importing ? "Importing..." : "Import tasks" }}
    </button>
    <button type="button" class="primary" @click="openNewForm">+ New card</button>
  </div>
</div>
```

`:disabled="importing"` prevents a second click while the first request is still running, and the label tells the user that something is happening. Then add the error message just before the status paragraph:

```vue
<p v-if="importError !== ''" class="error">{{ importError }}</p>
<p class="status">{{ message }}</p>
```

Add a rule for it to the style block of `App.vue`, before `.board`:

```css
.error {
  margin: 0 0 16px;
  font-size: 14px;
  color: #dc2626;
}
```

Finally, give every disabled button a clear look. Add this rule at the end of `src/assets/main.css`:

```css
button:disabled {
  opacity: 0.6;
  cursor: wait;
}
```

`cursor: wait` shows the "busy" cursor over a disabled button. In Lesson 10's exercise you used `not-allowed` for a disabled submit button; for a button that is disabled because something is loading, `wait` is the better hint. Save both files.

---

## 4. Run and Test

Restart the development server and open `http://localhost:5173`. Delete the `tasklane-cards` key in the Application tab and refresh, so you start from the six sample cards.

The toolbar buttons before importing:

```text
Import tasks / + New card
```

Click "Import tasks". Immediately after the click, while the request is on its way, the buttons read:

```text
Importing... (disabled) / + New card
```

The request usually takes well under a second, so you may only see "Importing..." flash. To watch it longer, open the **Network** tab of the developer tools and change the throttling from "No throttling" to "Slow 4G" before clicking. When the response has arrived, the button is back to `Import tasks`, and the stats, the status line, and the column headers read:

```text
4 of 9 cards done (44%), 1 overdue
Imported 3 tasks from DummyJSON.
To Do (3) | In Progress (2) | Done (4)
```

The three new cards, ids 7, 8, and 9:

```text
MEDIUM / Do something nice for someone you care about / Imported from DummyJSON. / No due date / Next → / Edit / Delete
MEDIUM / Memorize a poem / Imported from DummyJSON. / No due date / Completed / ← Back / Edit / Delete
MEDIUM / Watch a classic movie / Imported from DummyJSON. / No due date / Completed / ← Back / Edit / Delete
```

The first to-do was not completed, so it went to To Do; the other two went to Done. They behave like any other card: you can move, edit, and delete them, and they survive a refresh.

Now test the error state. Change `TODOS_URL` to an address that does not exist, `https://dummyjson.com/todoz?limit=3`, refresh with a clean board, and click "Import tasks":

```text
Could not import tasks. The server answered with status 404.
Use the buttons on a card to move, edit, or delete it.
To Do (2) | In Progress (2) | Done (2)
```

The server answered, but with 404 Not Found, so the `response.ok` check threw an error, and no cards were added. Next, try a host that does not exist at all, `https://dummyjson.invalid/todos?limit=3`:

```text
Could not import tasks. Failed to fetch
Use the buttons on a card to move, edit, or delete it.
To Do (2) | In Progress (2) | Done (2)
```

This time `fetch` itself failed, because the request could not reach any server. "Failed to fetch" is Chrome's message; Firefox says "NetworkError when attempting to fetch resource." You get the same result when you switch the Network tab's throttling to "Offline". Change `TODOS_URL` back to `https://dummyjson.com/todos?limit=3` when you are done.

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

These are the most common mistakes when fetching data.

**Error 1: Forgetting `await` before `response.json()`.**

```javascript
// Wrong
const data = response.json();

// Correct
const data = await response.json();
```

With the wrong version, clicking "Import tasks" shows:

```text
Could not import tasks. data.todos is not iterable
```

Without `await`, `data` is a promise, not the parsed object. A promise has no `todos` property, so `data.todos` is `undefined`, and a `for...of` loop cannot iterate over `undefined`. Both `fetch` and `response.json()` return promises, so both need `await`.

**Error 2: Skipping the `response.ok` check.**

```javascript
// Wrong
const response = await fetch(TODOS_URL);
const data = await response.json();

// Correct
const response = await fetch(TODOS_URL);
if (!response.ok) {
  throw new Error(`The server answered with status ${response.status}.`);
}
const data = await response.json();
```

With the wrong version and a wrong address, the error message is confusing:

```text
Could not import tasks. Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

For an unknown address, DummyJSON answers with a 404 status and an HTML error page. Without the `ok` check, the code tries to parse that HTML as JSON, and the parser chokes on the first character, `<`. The real problem, a wrong address, is hidden behind a parsing error. Checking `response.ok` first turns it into a clear message about status 404.

**Error 3: Using `await` in a function that is not `async`.**

```javascript
// Wrong
function importTasks() {
  // ...
  const response = await fetch(TODOS_URL);
  // ...
}

// Correct
async function importTasks() {
  // ...
  const response = await fetch(TODOS_URL);
  // ...
}
```

The wrong version does not compile. The browser shows an overlay starting with:

```text
[plugin:vite:vue] [vue/compiler-sfc] Unexpected reserved word 'await'. (130:21)
```

And the linter explains the rule:

```text
src/App.vue:130:22: error: `await` is only allowed within async functions and at the top levels of modules help: Either remove this `await` or add the `async` keyword to the enclosing function
src/App.vue:134:18: error: `await` is only allowed within async functions and at the top levels of modules help: Either remove this `await` or add the `async` keyword to the enclosing function
ERROR: "lint:oxlint" exited with 1.
```

Add `async` in front of `function`. Vue calls `importTasks` from the click handler without waiting for it, which is fine: the function updates reactive state as it goes, and the page follows.

---

## 6. Exercises

**Exercise 1:** Every click on "Import tasks" loads the same three to-dos. Use the API's `skip` parameter to load the next three each time: add a ref `importSkip` that starts at `0`, request `https://dummyjson.com/todos?limit=3&skip=<importSkip>`, and increase `importSkip` by the number of imported to-dos after a successful import.

**Exercise 2:** While a request is running, show a status line `Loading tasks from DummyJSON...` above the message, so users who look at the board instead of the button also see that something is happening.

**Exercise 3:** When an import fails, give the user a way to try again without hunting for the toolbar button: add a "Try again" button at the end of the error message that calls `importTasks` again.

---

## 7. Solutions

**Solution for Exercise 1:**

Change the constant so it holds only the base address, and add the ref:

```javascript
const TODOS_URL = "https://dummyjson.com/todos";
```

```javascript
const importSkip = ref(0);
```

In `importTasks`, build the address with both parameters, and increase the counter after the loop:

```javascript
const response = await fetch(`${TODOS_URL}?limit=3&skip=${importSkip.value}`);
```

```javascript
for (const todo of data.todos) {
  cards.value.push({ id: nextId(), ...todoToCard(todo) });
}
importSkip.value += data.todos.length;
message.value = `Imported ${data.todos.length} tasks from DummyJSON.`;
```

`skip=3` tells the API to leave out the first three to-dos. After two imports, starting from a clean board, the titles of cards 7 to 12 are:

```text
Do something nice for someone you care about | Memorize a poem | Watch a classic movie | Watch a documentary | Invest in cryptocurrency | Contribute code or a monetary donation to an open-source software project
```

The second import brought three new to-dos instead of repeating the first three. Notice the last title: it is 74 characters long, longer than the 60 characters `CardForm` allows. Imported data skips your form's validation, so if you edit that card, the form will ask you to shorten the title before saving. Real apps validate data from APIs too. Also note that `importSkip` starts at `0` again after every refresh; saving it in `localStorage` would be a good extra exercise.

**Solution for Exercise 2:**

Add the paragraph before the error message in `src/App.vue`:

```vue
<p v-if="importing" class="status">Loading tasks from DummyJSON...</p>
```

It reuses the `status` style and appears only while `importing` is true. Right after clicking "Import tasks", the status lines read:

```text
Loading tasks from DummyJSON... / Use the buttons on a card to move, edit, or delete it.
```

The same `importing` ref now drives two places, the button label and the loading line, and both switch back together in `finally`.

**Solution for Exercise 3:**

Put the button inside the error paragraph:

```vue
<p v-if="importError !== ''" class="error">
  {{ importError }}
  <button type="button" @click="importTasks">Try again</button>
</p>
```

With a wrong address, the error line reads:

```text
Could not import tasks. The server answered with status 404. Try again
```

Clicking "Try again" calls the same function as the toolbar button. `importTasks` clears the old error at the start, so if the second attempt succeeds, the red line disappears. A retry button is most useful for temporary problems, such as a moment without internet. Undo these exercise changes before the next lesson, so your code matches Lesson 16.

---

## 8. Requests, Promises, and the Three States

Every piece of data that comes over the network has a life cycle, and good apps show each stage:

| State | What the user should see | Tasklane |
| --- | --- | --- |
| Loading | That something is happening, and that clicking again is not needed | "Importing..." on a disabled button |
| Success | The data, and confirmation that it arrived | New cards and `Imported 3 tasks from DummyJSON.` |
| Error | What went wrong, without losing what they already had | A red message, and an unchanged board |

A few facts help you read data-loading code with confidence, whether you or an AI tool wrote it:

- **`await` only pauses the current function.** While `importTasks` waits for the response, Vue keeps rendering and the user can keep moving cards.
- **`fetch` rejects only for network failures.** HTTP errors such as 404 and 500 arrive as normal responses with `ok` set to `false`. Code that never checks `ok` is a common source of confusing bugs.
- **APIs are not under your control.** They can be slow, change their format, or go offline. Converting the data in one place, like `todoToCard`, and handling errors in `catch` keeps those problems contained.
- **Some APIs need more.** DummyJSON allows requests from any website and needs no key. Many real APIs require an API key or a login, and some only accept requests from their own domain. Never put a secret API key in front-end code: anyone can read it in the browser.

In the next lesson you will see that `importing`, `importError`, and the try/catch/finally structure are the same for almost every request. That makes them a perfect candidate for reuse.

---

## Next Up - Lesson 16

In this lesson you loaded real data from a public API. You explored the DummyJSON response in the browser and the console, fetched it with `fetch` and `async`/`await`, checked `response.ok`, converted each to-do into a Tasklane card with `todoToCard`, and tracked the loading and error states with refs and `try`, `catch`, and `finally`.

`App.vue` is now long, and some of its logic, such as syncing with `localStorage` and fetching data, is not about the board at all. In Lesson 16, you will move that logic into **composables**: reusable functions such as `useLocalStorage` and `useFetch` that bundle reactive state and logic, so components stay small and readable.
