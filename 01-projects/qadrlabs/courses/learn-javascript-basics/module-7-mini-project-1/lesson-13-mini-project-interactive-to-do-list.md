## 1. Before You Begin

Every concept in this course has been building toward this lesson. Variables store state. Functions encapsulate logic. Arrays hold collections of tasks. Objects represent individual tasks with multiple properties. DOM manipulation renders the interface. Events respond to user input. Forms capture new task text. localStorage persists data across page refreshes. This project uses all of them working together.

Building a complete application from scratch teaches something that no isolated exercise can: how individual concepts connect into a coherent design and how changes in one part of the system need to be reflected in another.

### What You'll Build

A fully functional to-do list application with the following features: adding a new task by typing and pressing Enter or clicking a button, marking a task as complete by clicking a checkbox or the task text, deleting a task with a delete button, filtering tasks by All, Active, or Completed, a live count of remaining active tasks, a Clear Completed button, and localStorage persistence so tasks survive page refreshes.

### What You'll Learn

- ✅ How to combine all JavaScript concepts in one project
- ✅ How to structure a small JavaScript application
- ✅ How to use localStorage for data persistence
- ✅ Event delegation for dynamic elements
- ✅ Rendering UI from a data array (data-driven approach)

### What You'll Need

- All previous lessons completed (Lessons 1 through 12)
- VS Code with the `learn-javascript` folder open

---

## 2. Setup

Before writing any code, create a dedicated folder for this lesson. In VS Code, right-click on the `learn-javascript` folder, select **New Folder**, and type `lesson-13`. Inside it, create three files: `index.html`, `style.css`, and `app.js`.

---

## 3. The Complete Application

The application is built in three files. Each file has a single responsibility: `index.html` defines the structure, `style.css` defines the appearance, and `app.js` defines all behavior.

### index.html

Add the following to `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>To-Do List</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>To-Do List</h1>
        <div class="input-group">
            <input type="text" id="task-input" placeholder="Add a new task..." autofocus>
            <button id="add-btn">Add</button>
        </div>
        <div class="filters">
            <button class="filter-btn active" data-filter="all">All</button>
            <button class="filter-btn" data-filter="active">Active</button>
            <button class="filter-btn" data-filter="completed">Completed</button>
        </div>
        <ul id="task-list"></ul>
        <div class="footer">
            <span id="task-count">0 tasks</span>
            <button id="clear-completed">Clear Completed</button>
        </div>
    </div>
    <script src="app.js"></script>
</body>
</html>
```

The HTML contains no task items. The `<ul id="task-list">` is intentionally empty - every task card will be created by JavaScript at runtime. The three filter buttons each have a `data-filter` attribute containing the filter name. JavaScript reads this attribute to know which filter was selected, which avoids the need for separate `id` attributes on each button. The `autofocus` attribute on the input places the cursor there automatically when the page loads.

### style.css

Add the following to `style.css`:

```css
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: Arial, sans-serif; background: #f0f2f5; display: flex; justify-content: center; padding: 40px 16px; }
.container { background: white; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.1); width: 100%; max-width: 500px; padding: 24px; }
h1 { text-align: center; margin-bottom: 20px; color: #1e293b; }
.input-group { display: flex; gap: 8px; margin-bottom: 16px; }
.input-group input { flex: 1; padding: 10px 14px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 1em; }
.input-group button { padding: 10px 18px; background: #2563eb; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; }
.filters { display: flex; gap: 6px; margin-bottom: 12px; }
.filter-btn { flex: 1; padding: 6px; border: 1px solid #d1d5db; background: white; border-radius: 4px; cursor: pointer; font-size: 0.85em; }
.filter-btn.active { background: #2563eb; color: white; border-color: #2563eb; }
ul { list-style: none; }
li { display: flex; align-items: center; gap: 10px; padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
li .task-text { flex: 1; cursor: pointer; }
li.completed .task-text { text-decoration: line-through; color: #9ca3af; }
li .delete-btn { background: none; border: none; color: #dc2626; cursor: pointer; font-size: 1.1em; opacity: 0.5; }
li .delete-btn:hover { opacity: 1; }
.footer { display: flex; justify-content: space-between; align-items: center; margin-top: 12px; padding-top: 12px; border-top: 1px solid #f0f0f0; font-size: 0.85em; color: #6b7280; }
#clear-completed { background: none; border: none; color: #6b7280; cursor: pointer; text-decoration: underline; }
```

The CSS uses `li.completed .task-text` to apply a strikethrough style to the task text when the parent `<li>` has the `"completed"` class. This means JavaScript only needs to toggle a class on the `<li>` element and the visual change happens automatically. The `.filter-btn.active` rule highlights whichever filter button is currently selected.

### app.js

Add the following to `app.js`:

```javascript
let tasks = JSON.parse(localStorage.getItem("tasks")) || [];
let currentFilter = "all";

const taskInput = document.getElementById("task-input");
const addBtn = document.getElementById("add-btn");
const taskList = document.getElementById("task-list");
const taskCount = document.getElementById("task-count");
const clearCompletedBtn = document.getElementById("clear-completed");
const filterBtns = document.querySelectorAll(".filter-btn");

function saveTasks() {
    localStorage.setItem("tasks", JSON.stringify(tasks));
}

function render() {
    const filtered = tasks.filter(task => {
        if (currentFilter === "active") return !task.completed;
        if (currentFilter === "completed") return task.completed;
        return true;
    });

    taskList.innerHTML = "";

    filtered.forEach(task => {
        const li = document.createElement("li");
        if (task.completed) li.classList.add("completed");

        const checkbox = document.createElement("input");
        checkbox.type = "checkbox";
        checkbox.checked = task.completed;

        const span = document.createElement("span");
        span.className = "task-text";
        span.textContent = task.text;

        const deleteBtn = document.createElement("button");
        deleteBtn.className = "delete-btn";
        deleteBtn.textContent = "x";

        li.appendChild(checkbox);
        li.appendChild(span);
        li.appendChild(deleteBtn);

        checkbox.addEventListener("change", () => {
            task.completed = !task.completed;
            saveTasks();
            render();
        });

        span.addEventListener("click", () => {
            task.completed = !task.completed;
            saveTasks();
            render();
        });

        deleteBtn.addEventListener("click", () => {
            tasks = tasks.filter(t => t !== task);
            saveTasks();
            render();
        });

        taskList.appendChild(li);
    });

    const activeCount = tasks.filter(t => !t.completed).length;
    taskCount.textContent = `${activeCount} task${activeCount !== 1 ? "s" : ""} remaining`;
}

function addTask() {
    const text = taskInput.value.trim();
    if (!text) return;
    tasks.push({ text, completed: false, id: Date.now() });
    taskInput.value = "";
    taskInput.focus();
    saveTasks();
    render();
}

addBtn.addEventListener("click", addTask);
taskInput.addEventListener("keydown", e => { if (e.key === "Enter") addTask(); });

filterBtns.forEach(btn => {
    btn.addEventListener("click", () => {
        filterBtns.forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        currentFilter = btn.dataset.filter;
        render();
    });
});

clearCompletedBtn.addEventListener("click", () => {
    tasks = tasks.filter(t => !t.completed);
    saveTasks();
    render();
});

render();
```

`tasks` is the single source of truth for the entire application. It is initialized by reading from `localStorage` using `JSON.parse`. If nothing is stored yet, `|| []` provides an empty array as the fallback. Every time the task list changes, `saveTasks()` converts the array back to a JSON string and saves it to `localStorage`, so the data persists across page refreshes.

`render()` is the central function that rebuilds the visible task list from the `tasks` array every time the state changes. It first filters the array based on `currentFilter`, then clears the `<ul>` by setting `taskList.innerHTML = ""`, and then loops through the filtered tasks to create and append a `<li>` element for each one. Rebuilding the entire list on each change is intentional: it keeps the UI in sync with the data without tracking which specific elements need updating.

Each `<li>` is built from DOM elements created with `document.createElement()`. The checkbox, task text, and delete button are separate nodes, then `appendChild()` inserts them into the list item. The task text is assigned with `textContent`, not `innerHTML`, so anything the user types is treated as plain text instead of HTML. Event listeners are attached directly to the element variables. The listeners use closures to reference the `task` object directly, which makes the delete handler simple: `tasks = tasks.filter(t => t !== task)` removes the specific object by reference from the array.

`addTask` reads the input, trims whitespace, and returns early if the result is empty. Otherwise it pushes a new task object with a `text` property, a `completed` property set to `false`, and an `id` generated from `Date.now()` (the current timestamp in milliseconds). After pushing, it clears the input, saves, and calls `render()`.

`btn.dataset.filter` reads the `data-filter` attribute from each filter button. When a filter button is clicked, its `dataset.filter` value (`"all"`, `"active"`, or `"completed"`) is assigned to `currentFilter`, and `render()` applies the new filter.

---

## 4. How All Concepts Connect

Every feature of this application maps directly to specific lessons in this course. Understanding these connections reinforces why each lesson existed.

| Feature | Concepts Used | Lesson |
|---------|---------------|--------|
| Task data | Objects in an array | Lessons 7 and 8 |
| Add and delete tasks | `push`, `filter`, arrow functions | Lessons 5 and 7 |
| Rendering UI | `createElement`, `textContent`, `appendChild` | Lessons 9 and 10 |
| User interactions | `addEventListener`, event object | Lesson 11 |
| Form input | `.value`, `keydown`, `trim()` | Lesson 12 |
| Persistence | `JSON.stringify`, `JSON.parse`, `localStorage` | Lesson 8 |
| Filtering | Array `filter`, `data-` attributes | Lessons 4 and 7 |
| Toggle complete | `classList`, conditional logic | Lessons 4 and 9 |

The overall architecture - a state array, a save function, and a render function that rebuilds the UI from the array - is the same pattern used by frameworks like React and Vue. The specific syntax differs, but the concept is identical.

---

## 5. Exercises

**Exercise 1:** Add an inline edit feature. When the user double-clicks a task's text, replace the `<span>` with an `<input>` pre-filled with the current text. When the user presses Enter or clicks elsewhere (the `blur` event), save the new text back to the task object, call `saveTasks()`, and call `render()`.

**Exercise 2:** Add a due date field to the Add Task form. Store the due date as a property on each task object. In the `render` function, display the due date next to each task and apply a red color to the task text if the due date has already passed (compare with `new Date()`).

**Exercise 3:** Add a task priority feature. When adding a task, display three color-coded buttons (`Low`, `Medium`, `High`) and store the selected priority on the task object. In `render`, display a colored dot or badge next to each task indicating its priority level.

---

## 6. Solutions

**Solution for Exercise 1:**

In the `render` function, after attaching the existing click listener to `.task-text`, add the following:

```javascript
li.querySelector(".task-text").addEventListener("dblclick", () => {
    const editInput = document.createElement("input");
    editInput.type = "text";
    editInput.value = task.text;
    editInput.style.cssText = "flex: 1; padding: 2px 6px; border: 1px solid #2563eb; border-radius: 4px;";

    const span = li.querySelector(".task-text");
    li.replaceChild(editInput, span);
    editInput.focus();

    function saveEdit() {
        const newText = editInput.value.trim();
        if (newText) task.text = newText;
        saveTasks();
        render();
    }

    editInput.addEventListener("blur", saveEdit);
    editInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") saveEdit();
        if (e.key === "Escape") render();
    });
});
```

`li.replaceChild(editInput, span)` replaces the span with a text input in one DOM operation. The `blur` event fires when the input loses focus, which handles the case where the user clicks elsewhere. The `saveEdit` function is defined inside the handler so it can close over both `task` and `editInput`.

**Solution for Exercise 2:**

Modify `addTask` to also read a date input, and update `render` to display and color the date:

```javascript
function addTask() {
    const text = taskInput.value.trim();
    const dateVal = document.getElementById("due-date").value;
    if (!text) return;
    tasks.push({
        text,
        completed: false,
        id: Date.now(),
        dueDate: dateVal || null
    });
    taskInput.value = "";
    saveTasks();
    render();
}
```

In the `render` function, after creating the task text span, create and append a due date span:

```javascript
if (task.dueDate) {
    const dateSpan = document.createElement("span");
    dateSpan.className = "due-date";
    dateSpan.textContent = task.dueDate;

    const isOverdue = new Date(task.dueDate) < new Date() && !task.completed;
    dateSpan.style.color = isOverdue ? "#dc2626" : "#6b7280";

    li.appendChild(dateSpan);
}
```

`new Date(task.dueDate) < new Date()` compares the stored date string to the current date. When the due date is in the past and the task is not yet completed, the date is displayed in red.

---

## Next Up - Lesson 14

This project demonstrates the data-driven rendering pattern: the `tasks` array is the source of truth, `saveTasks()` persists it, and `render()` rebuilds the UI from it on every change. This same pattern is the foundation of React, Vue, and other modern frameworks. `localStorage` stores only strings, so objects must be converted with `JSON.stringify` before saving and parsed with `JSON.parse` when loading. `Date.now()` generates a unique numeric ID based on the current timestamp. Event listeners inside `render` close over the task object directly, enabling clean and precise manipulation without querying the DOM for a matching element.

In Lesson 14, you will review everything you have learned, explore what this course did not cover, and chart a clear path to advanced JavaScript, frontend frameworks, and backend development.
