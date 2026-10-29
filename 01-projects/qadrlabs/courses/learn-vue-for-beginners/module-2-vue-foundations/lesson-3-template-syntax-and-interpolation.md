## 1. Before You Begin

In Lesson 2, you created the Tasklane project, toured its files, and replaced the starter page with a heading and a tagline. That page is pure HTML: nothing in it comes from JavaScript yet. A real Tasklane board shows data, such as card titles, priorities, and due dates, and that data lives in JavaScript.

In this lesson you will connect the two. You will learn Vue's template syntax: how to show JavaScript values in the page with double curly braces, which JavaScript expressions are allowed inside them, and how to put values into HTML attributes with `v-bind`. You will use these tools to display Tasklane's first real card.

### What You'll Build

Tasklane's first card, displayed from a JavaScript object in `App.vue`: its priority in capital letters, its title, its description (or a fallback message when it is empty), its due date inside a `<time>` element, and a status message. The card's `id` and `title` attributes also come from the data.

### What You'll Learn

- ✅ How the `<script setup>` block makes variables available to the template
- ✅ How to show values with text interpolation, `{{ }}`
- ✅ Which JavaScript expressions you can write inside `{{ }}`, and which you cannot
- ✅ How to bind attributes with `v-bind` and its shorthand `:`
- ✅ Why Vue escapes HTML inside `{{ }}`, and what `v-html` does
- ✅ How to read Vue's warnings and template errors

### What You'll Need

- The Tasklane project from Lesson 2, with the development server running (`npm run dev`)
- Your browser open at `http://localhost:5173`

---

## 2. Show Data with Text Interpolation

A Vue template is HTML with a few extra features. The most common one is **text interpolation**: you write a JavaScript value between double curly braces, `{{ }}`, and Vue replaces it with the value. You already used it in Lesson 1's counter, `Cards done: {{ count }}`. Now you will use it in a real component.

### Step 1: Show the Board Name

Every Tasklane board has a name. Open `src/App.vue` and replace its contents with this code.

```vue
<script setup>
const boardName = "Website Redesign";
const cardCount = 5;
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>
    <p>This board has {{ cardCount }} cards.</p>
  </main>
</template>
```

Here is what the code does:

- `const boardName = "Website Redesign";` and `const cardCount = 5;` are ordinary JavaScript constants inside `<script setup>`.
- Every top-level variable, function, and import in `<script setup>` is automatically available in the template. You do not need to `return` anything, as you did with `setup()` in Lesson 1.
- `<h2>{{ boardName }}</h2>` shows the value of `boardName` inside the heading.
- `{{ cardCount }}` sits in the middle of a sentence. Interpolation can be mixed freely with normal text.

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

This board has 5 cards.
```

The browser shows the values, not the curly braces. Vue read the template, found each `{{ }}`, and replaced it with the matching value from `<script setup>`.

### Step 2: Show a Card from an Object

A card is not one value but an object with six properties, the shape you met in Lesson 1. You can store the whole object in a constant and reach its properties with a dot, exactly as in plain JavaScript. Replace `App.vue` with this version.

```vue
<script setup>
const boardName = "Website Redesign";
const card = {
  id: 3,
  title: "Design home page",
  description: "Create the first layout for the home page.",
  status: "in-progress",
  priority: "medium",
  dueDate: "2026-11-07",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>

    <article>
      <p>{{ card.priority }}</p>
      <h3>{{ card.title }}</h3>
      <p>{{ card.description }}</p>
      <p>Due {{ card.dueDate }}</p>
    </article>
  </main>
</template>
```

Here is what changed:

- `cardCount` is gone, and `card` is a new constant that holds one card object.
- `<article>` wraps everything that belongs to the card. `article` is the right HTML element for a self-contained piece of content such as a card.
- `{{ card.priority }}`, `{{ card.title }}`, `{{ card.description }}`, and `{{ card.dueDate }}` each read one property of the object.

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

medium

Design home page

Create the first layout for the home page.

Due 2026-11-07
```

The card's data is on the screen. It does not look like a card yet; you will style it in Lesson 7. For now, the goal is to get the right values in the right places.

---

## 3. Use JavaScript Expressions in the Template

The value inside `{{ }}` does not have to be a plain variable. It can be any single JavaScript **expression**, that is, any piece of code that produces a value. Calling a method, doing math, and choosing between two values with a ternary are all expressions. That lets you format data right where it is displayed.

### Step 1: Format the Priority and Add Fallbacks

Some cards have no description or no due date. Showing an empty paragraph or "Due " with nothing after it looks broken. Replace `App.vue` with this version, which formats the priority and adds fallback text.

```vue
<script setup>
const boardName = "Website Redesign";
const card = {
  id: 3,
  title: "Design home page",
  description: "Create the first layout for the home page.",
  status: "in-progress",
  priority: "medium",
  dueDate: "2026-11-07",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>

    <article>
      <p>{{ card.priority.toUpperCase() }}</p>
      <h3>{{ card.title }}</h3>
      <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
      <p>Due {{ card.dueDate === "" ? "anytime" : card.dueDate }}</p>
      <p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
    </article>
  </main>
</template>
```

Here is what each expression does:

- `card.priority.toUpperCase()` calls a string method, so `"medium"` becomes `"MEDIUM"`. Priority labels are easier to scan in capital letters.
- `card.description === "" ? "No description yet." : card.description` is a ternary expression: if the description is empty, show a fallback message, otherwise show the description.
- `card.dueDate === "" ? "anytime" : card.dueDate` does the same for the due date, so a card without a deadline reads "Due anytime".
- `card.status === "done" ? "Finished" : "Not finished yet"` turns the status into a friendly message.

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

MEDIUM

Design home page

Create the first layout for the home page.

Due 2026-11-07

Not finished yet
```

This card has a description and a due date, so the fallbacks do not appear. You will see them in action in Exercise 2, when you display a card that has neither.

Keep expressions in the template short. A ternary is fine; ten lines of logic are not. When the logic grows, it belongs in `<script setup>`, and in Lesson 12 you will learn computed properties, Vue's tool for exactly that.

---

## 4. Bind Attributes with v-bind

Curly braces work only for text between tags. They do not work inside an HTML attribute: writing `id="{{ card.id }}"` does not do what you might expect. To put a JavaScript value into an attribute, Vue uses a **directive** called `v-bind`. A directive is a special attribute that starts with `v-` and tells Vue to do something with the element.

### Step 1: Bind the Card's id, title, and datetime

Replace `App.vue` with this version.

```vue
<script setup>
const boardName = "Website Redesign";
const card = {
  id: 3,
  title: "Design home page",
  description: "Create the first layout for the home page.",
  status: "in-progress",
  priority: "medium",
  dueDate: "2026-11-07",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>

    <article :id="`card-${card.id}`" :title="card.title">
      <p>{{ card.priority.toUpperCase() }}</p>
      <h3>{{ card.title }}</h3>
      <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
      <p>
        Due
        <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
      </p>
      <p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
    </article>
  </main>
</template>
```

Here is what is new:

- `` :id="`card-${card.id}`" `` binds the `id` attribute. The colon at the start is the shorthand for `v-bind:`, so this is the same as `v-bind:id="..."`. The value between the quotes is a JavaScript expression, here a template literal that builds the text `card-3`.
- `:title="card.title"` binds the `title` attribute, which browsers show as a tooltip when you hover over the card.
- `<time :datetime="card.dueDate">` wraps the date in a `<time>` element. Its `datetime` attribute holds the date in a format that browsers, search engines, and screen readers understand.

The rule to remember: **a value without a colon is plain text; a value with a colon is JavaScript**. `title="card.title"` would set the tooltip to the literal words "card.title", while `:title="card.title"` sets it to the card's actual title.

Save the file.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

MEDIUM

Design home page

Create the first layout for the home page.

Due 2026-11-07

Not finished yet
```

The visible text is the same as before, because attributes are not shown on the page. Hover over the card and the tooltip "Design home page" appears. To see the attributes themselves, right-click the card, choose **Inspect**, and look at the Elements panel.

The `<article>` element in the Elements panel:

```html
<article id="card-3" title="Design home page"><p>MEDIUM</p><h3>Design home page</h3><p>Create the first layout for the home page.</p><p> Due <time datetime="2026-11-07">2026-11-07</time></p><p>Not finished yet</p></article>
```

Vue replaced every bound attribute with its value: `id="card-3"`, `title="Design home page"`, and `datetime="2026-11-07"`. The colons and expressions exist only in your template; the browser receives normal HTML. You will bind many more attributes in this course, including `class` and `style` in Lesson 7 and form values in Lesson 10.

---

## 5. Run and Test

Check the finished lesson from a fresh start. Make sure `App.vue` matches the code from Section 4, stop the server with `Ctrl+C`, and start it again.

```bash
npm run dev
```

Open `http://localhost:5173` and check the following:

1. The board name "Website Redesign" appears under the tagline.
2. The card shows `MEDIUM`, the title, the description, `Due 2026-11-07`, and `Not finished yet`.
3. Hovering over the card shows the tooltip "Design home page".
4. Inspecting the card shows `id="card-3"` on the `<article>` and `datetime="2026-11-07"` on the `<time>` element.

Next, try changing the data. In `<script setup>`, change `priority: "medium"` to `priority: "high"` and save. The page now shows `HIGH`. Change it back to `"medium"` before you continue.

Finally, run the linters in a second terminal.

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

No problems are reported. Notice that changing the data in `<script setup>` updated the page only because Vite reloaded the component when you saved. The constants in this lesson are not reactive: if some code changed `card.priority` while the app was running, the page would not update. You will make the data reactive in Lesson 9.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes with template syntax.

**Error 1: Using a name that does not exist in `<script setup>`.**

The template can only use names declared in `<script setup>`. A typo, or a name from another file, gives Vue nothing to show.

```vue
<!-- Wrong -->
<h2>{{ boardTitle }}</h2>

<!-- Correct -->
<h2>{{ boardName }}</h2>
```

With the wrong version, the heading is simply missing from the page, and the browser console shows this warning:

```text
[Vue warn]: Property "boardTitle" was accessed during render but is not defined on instance. 
  at <App>
```

"Accessed during render but is not defined" means the template asked for `boardTitle`, but `<script setup>` never declared it. The line `at <App>` tells you which component the problem is in. Whenever part of the page is mysteriously empty, open the console first and look for a `[Vue warn]` message.

**Error 2: Writing a statement instead of an expression.**

`{{ }}` accepts a single expression, something that produces a value. Statements such as `if`, `for`, or `const` do not produce a value, so they are not allowed.

```vue
<!-- Wrong -->
<p>{{ if (card.status === "done") { "Finished" } }}</p>

<!-- Correct -->
<p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
```

The wrong version stops the whole component from compiling. The browser shows a red error overlay with this message:

```text
[plugin:vite:vue] Error parsing JavaScript expression: Unexpected token (1:1)
```

The terminal shows the same error with the file and position, `src/App.vue:28:49`, pointing to the `{{` that contains the `if`. Replace the `if` statement with a ternary expression. If you need several choices, such as a different element for each case, you will learn `v-if` and `v-else` in Lesson 6.

**Error 3: Forgetting the colon on a bound attribute.**

Without the colon, Vue treats the attribute value as plain text and does not run it as JavaScript.

```vue
<!-- Wrong -->
<article :id="`card-${card.id}`" title="card.title">

<!-- Correct -->
<article :id="`card-${card.id}`" :title="card.title">
```

The wrong version shows no error at all. The page looks the same, but hovering over the card shows the tooltip "card.title", and the Elements panel shows the literal text:

```html
<article id="card-3" title="card.title"><p>MEDIUM</p><h3>Design home page</h3><p>Create the first layout for the home page.</p><p> Due <time datetime="2026-11-07">2026-11-07</time></p><p>Not finished yet</p></article>
```

If an attribute shows the name of a variable instead of its value, look for a missing colon.

---

## 7. Exercises

**Exercise 1:** Add a constant `ownerName` with the value `"Alex"` to `<script setup>`, and show `Owner: Alex` in a paragraph under the board name. Then add a paragraph under the card title that shows how many characters the title has, in the format `Title length: 16 characters`. Use the `length` property of the string.

**Exercise 2:** Change the `card` object to card 2 from Lesson 1: id `2`, title `"Collect logo files"`, an empty description, status `"done"`, priority `"low"`, and an empty due date. Do not change the template. What does the page show for the description, the due date, and the status, and why?

**Exercise 3:** Add a constant `helpUrl` with the value `"https://vuejs.org/guide/essentials/template-syntax.html"`. Under the card, add a link with the text `Read the template syntax guide` whose `href` comes from `helpUrl`. The link should open in a new tab.

---

## 8. Solutions

**Solution for Exercise 1:**

```vue
<script setup>
const boardName = "Website Redesign";
const ownerName = "Alex";
const card = {
  id: 3,
  title: "Design home page",
  description: "Create the first layout for the home page.",
  status: "in-progress",
  priority: "medium",
  dueDate: "2026-11-07",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>
    <p>Owner: {{ ownerName }}</p>

    <article :id="`card-${card.id}`" :title="card.title">
      <p>{{ card.priority.toUpperCase() }}</p>
      <h3>{{ card.title }}</h3>
      <p>Title length: {{ card.title.length }} characters</p>
      <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
      <p>
        Due
        <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
      </p>
      <p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
    </article>
  </main>
</template>
```

`ownerName` is a new constant, so the template can use it right away. `card.title.length` is an expression that reads the `length` property of the title string.

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

Owner: Alex

MEDIUM

Design home page

Title length: 16 characters

Create the first layout for the home page.

Due 2026-11-07

Not finished yet
```

**Solution for Exercise 2:**

Replace only the `card` object in `<script setup>`.

```vue
<script setup>
const boardName = "Website Redesign";
const card = {
  id: 2,
  title: "Collect logo files",
  description: "",
  status: "done",
  priority: "low",
  dueDate: "",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>

    <article :id="`card-${card.id}`" :title="card.title">
      <p>{{ card.priority.toUpperCase() }}</p>
      <h3>{{ card.title }}</h3>
      <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
      <p>
        Due
        <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
      </p>
      <p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
    </article>
  </main>
</template>
```

What you see in the browser:

```text
Tasklane

Plan your work, one card at a time.

Website Redesign

LOW

Collect logo files

No description yet.

Due anytime

Finished
```

The description is empty, so the first ternary shows `No description yet.` The due date is empty, so the second ternary shows `anytime`. The status is `"done"`, so the last ternary shows `Finished`. The template did not change at all; only the data did. That is the idea behind declarative templates: you describe every case once, and the data decides what appears. Change the card back to card 3 before the next lesson.

**Solution for Exercise 3:**

```vue
<script setup>
const boardName = "Website Redesign";
const helpUrl = "https://vuejs.org/guide/essentials/template-syntax.html";
const card = {
  id: 3,
  title: "Design home page",
  description: "Create the first layout for the home page.",
  status: "in-progress",
  priority: "medium",
  dueDate: "2026-11-07",
};
</script>

<template>
  <main>
    <h1>Tasklane</h1>
    <p>Plan your work, one card at a time.</p>

    <h2>{{ boardName }}</h2>

    <article :id="`card-${card.id}`" :title="card.title">
      <p>{{ card.priority.toUpperCase() }}</p>
      <h3>{{ card.title }}</h3>
      <p>{{ card.description === "" ? "No description yet." : card.description }}</p>
      <p>
        Due
        <time :datetime="card.dueDate">{{ card.dueDate === "" ? "anytime" : card.dueDate }}</time>
      </p>
      <p>{{ card.status === "done" ? "Finished" : "Not finished yet" }}</p>
    </article>

    <a :href="helpUrl" target="_blank">Read the template syntax guide</a>
  </main>
</template>
```

`:href="helpUrl"` binds the link's address to the constant. `target="_blank"` has no colon because its value is fixed text, not JavaScript. Inspecting the link shows the final HTML:

```html
<a href="https://vuejs.org/guide/essentials/template-syntax.html" target="_blank">Read the template syntax guide</a>
```

Clicking the link opens Vue's guide to template syntax in a new tab. Remove the link afterward if you want your project to match the next lesson.

---

## 9. What Can Go Inside the Curly Braces

You have used several expressions in this lesson. Here is a summary of what is allowed in `{{ }}` and in bound attributes, and what is not.

| Allowed (expressions) | Not allowed (statements) |
| --- | --- |
| `{{ boardName }}` | `{{ const name = "Tasklane" }}` |
| `{{ card.title.length }}` | `{{ if (ok) { "yes" } }}` |
| `{{ card.priority.toUpperCase() }}` | `{{ for (const c of cards) { c.title } }}` |
| `{{ ok ? "yes" : "no" }}` | `{{ return card.title }}` |
| `{{ cardCount * 2 }}` | Several lines of code |

A simple test: if you could put the code on the right side of `const result = ...`, it is an expression and it works in a template.

There is one more thing to know about interpolation: it is **safe by default**. If a value contains HTML, such as a description with `<strong>`, Vue shows the tags as plain text instead of turning them into real HTML. This protects your app from cross-site scripting (XSS) attacks, where someone types HTML or JavaScript into a form hoping it will run in other people's browsers. Vue does have a directive named `v-html` that inserts a value as real HTML, but you should only use it with content you fully control, never with text that users type. Tasklane does not need `v-html` at all.

---

## Next Up - Lesson 4

In this lesson you displayed JavaScript data in a Vue template. You used text interpolation with `{{ }}`, wrote expressions such as method calls and ternaries inside it, and bound attributes with `v-bind` and its `:` shorthand. You also learned to read Vue's warnings and template errors, and why interpolation is safe by default.

In Lesson 4, `App.vue` will start to get crowded, so you will split Tasklane into single-file components: `AppHeader`, `BoardColumn`, and `TaskCard`. You will learn how the `<template>`, `<script setup>`, and `<style>` blocks of each component work together, and how to import one component into another.
