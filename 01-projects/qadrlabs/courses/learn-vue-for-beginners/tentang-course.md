---
title: "Learn Vue for Beginners: Build a Kanban Board Step by Step"
slug: "learn-vue-for-beginners"
status: "draft"
---

# Learn Vue for Beginners: Build a Kanban Board Step by Step

## Deskripsi
```
Learn Vue from zero by building Tasklane, a Kanban task board. Master components, props, events, reactivity, forms, computed, watchers, composables, Vue Router, and Pinia, then fix AI-generated Vue code.
```


## Konten

```
Vue is one of the most popular JavaScript frameworks for building user interfaces. It is known for being approachable: its templates look like the HTML you already know, and you can add it to a single page or use it to build a complete app. Vue powers dashboards, admin panels, and online tools around the world, and it is also a framework that AI coding assistants write often. That makes Vue a great skill to learn today, but it also creates a new problem: many people now have Vue code they did not write and cannot fix when something breaks.

This course teaches Vue from the beginning, one concept at a time, through a single case study. Instead of isolated examples, you will build Tasklane, a Kanban task board, from an empty folder to a finished multi-page app. Each lesson adds one feature to Tasklane: first the board layout, then the columns and cards, a form to add cards, editing, deleting, and moving cards between To Do, In Progress, and Done, live counts with filters and search, saving data in the browser, importing tasks from an API, separate pages with Vue Router, and shared state with Pinia. Every lesson also includes common mistakes to fix, exercises, and full solutions.

The course closes with a module on coding Vue with AI. You will learn how to read AI-generated Vue code using the concepts from this course, spot the bugs AI tools often produce (lost reactivity, mutated props, missing keys, watchers that never stop), and fix them with confidence. The goal is not to replace AI tools, but to make you the developer who understands and controls the code they produce.

The project uses Vite, Vue 3 with the Composition API and script setup, Vue Router, Pinia, and plain CSS, with JavaScript (no TypeScript). You do not need to know React or any other framework. If you have never written code before, the free courses "[Learn HTML and CSS](https://qadrlabs.com/course/learn-html-and-css-build-your-first-website-from-scratch)" and "[Learn JavaScript Basics](https://qadrlabs.com/course/learn-javascript-basics-from-zero-to-interactive-web-pages)" on qadrlabs are the recommended first steps.

**Prerequisites:**
- Basic HTML and CSS: tags, attributes, classes, and simple styling
- Basic JavaScript: variables, functions, arrays, objects, and arrow functions (covered in the qadrlabs JavaScript Basics course)
- A computer running Windows, macOS, or Linux with terminal access
- A modern web browser such as Chrome or Firefox, and a text editor such as Visual Studio Code
- An internet connection to install Node.js and project packages

**By the end, you will have:**
- A working Vue development setup with Node.js, npm, and Vite, and a clear picture of how a Vue project is organized
- A solid grasp of template syntax, single-file components, props, list rendering, and conditional rendering
- The ability to handle events, emit events to parent components, manage reactive state with ref and reactive, and build forms with v-model
- Experience with computed properties, watchers, lifecycle hooks, and slots
- Practice with localStorage, fetching data from an API, and writing your own composables
- A multi-page app built with Vue Router, dynamic routes, and shared state with Pinia
- The skills to read, review, and fix AI-generated Vue code instead of copying it blindly
- Tasklane, a complete Kanban task board built for production with npm run build, ready for your portfolio
```

## Daftar Modul

### 1. `Module 1 - Getting to Know Tasklane`

```
Understand what Vue is and why it matters in the age of AI coding tools, see the Tasklane board you will build, and set up your first Vue project with Vite.
```


- Lesson 1 - What Is Vue and What We Will Build
    lesson short description
    ```
    Learn what Vue is, how it differs from plain JavaScript DOM code, why AI tools generate so much Vue, and take a tour of the finished Tasklane Kanban board.
    
    ```
- Lesson 2 - Setting Up Your Vue Project with Vite
    lesson short description
    ```
    Install Node.js and npm, create the Tasklane project with create-vue, run the development server, and explore the folders and files you will work with.
    
    ```

### 2. `Module 2 - Vue Foundations`

```
Learn the building blocks of every Vue app: template syntax, single-file components, props, lists, conditional rendering, and bindings, and use them to build the static Tasklane board.
```


- Lesson 3 - Template Syntax and Interpolation
    lesson short description
    ```
    Display data in a Vue template with double curly braces, bind attributes with v-bind, and learn which JavaScript expressions are allowed inside a template.
    
    ```
- Lesson 4 - Single-File Components
    lesson short description
    ```
    Split the Tasklane page into .vue components such as AppHeader, BoardColumn, and TaskCard, and learn how the template, script setup, and style blocks work together.
    
    ```
- Lesson 5 - Props: Passing Data to Components
    lesson short description
    ```
    Pass data from parent to child components with defineProps, declare prop types and default values, and make the column and card components reusable.
    
    ```
- Lesson 6 - Rendering Lists and Conditional Content
    lesson short description
    ```
    Render cards from an array with v-for and a key, show or hide content with v-if, v-else, and v-show, and display an empty state when a column has no cards.
    
    ```
- Lesson 7 - Class and Style Bindings
    lesson short description
    ```
    Style Tasklane with scoped CSS, apply classes dynamically with :class, use :style where it fits, and color cards by priority and due date.
    
    ```

### 3. `Module 3 - Making Tasklane Interactive`

```
Bring Tasklane to life with events and reactive state, build a form to add cards, and let users edit, delete, and move cards between columns.
```


- Lesson 8 - Handling Events and Emitting to Parents
    lesson short description
    ```
    Respond to clicks with v-on and event modifiers, send events from child to parent with defineEmits, and learn how data flows down and events flow up.
    
    ```
- Lesson 9 - Reactive State with ref and reactive
    lesson short description
    ```
    Store changing data with ref and reactive, see how Vue updates the page automatically, and understand why plain variables do not update the user interface.
    
    ```
- Lesson 10 - Forms with v-model: Adding a Card
    lesson short description
    ```
    Build a form for new cards with text, textarea, select, and date inputs bound with v-model, handle submission, validate input, and add the card to the board.
    
    ```
- Lesson 11 - Editing, Deleting, and Moving Cards
    lesson short description
    ```
    Delete cards, edit them by reusing the form, and move cards between To Do, In Progress, and Done with buttons, while keeping one source of truth for the board.
    
    ```

### 4. `Module 4 - Computed, Watchers, and Slots`

```
Calculate counts, filters, and search results with computed properties, save the board with watchers, and build flexible components with slots.
```


- Lesson 12 - Computed Properties: Counts, Filters, and Search
    lesson short description
    ```
    Derive column counts, progress, overdue cards, priority filters, and search results with computed, and learn why computed is better than a method or extra state.
    
    ```
- Lesson 13 - Watchers and Lifecycle Hooks: Saving to localStorage
    lesson short description
    ```
    Save the board to localStorage with watch, load it again when the app starts, and learn when to use watch, watchEffect, and lifecycle hooks such as onMounted.
    
    ```
- Lesson 14 - Slots: A Reusable Modal and Column
    lesson short description
    ```
    Pass template content into components with default and named slots, and build a reusable modal for the card form and a flexible column layout.
    
    ```

### 5. `Module 5 - Data and Composables`

```
Load tasks from a real API with loading and error states, then move reusable logic into composables so components stay small and readable.
```


- Lesson 15 - Fetching Data from an API
    lesson short description
    ```
    Import sample tasks from a public API with fetch and async/await, show loading and error states, and convert the API data into Tasklane cards.
    
    ```
- Lesson 16 - Composables: Reusing Logic
    lesson short description
    ```
    Extract reusable logic such as fetching data and syncing with localStorage into composables, and learn the naming and structure conventions they follow.
    
    ```

### 6. `Module 6 - Multiple Pages with Vue Router and Pinia`

```
Turn Tasklane into a multi-page app with Vue Router, give every card its own detail page, and share state across pages with a Pinia store.
```


- Lesson 17 - Setting Up Vue Router
    lesson short description
    ```
    Install Vue Router, define routes for the home, board, and about pages, navigate with RouterLink, render pages with RouterView, and add a not found page.
    
    ```
- Lesson 18 - Dynamic Routes: The Card Detail Page
    lesson short description
    ```
    Create a dynamic route with a param, /cards/:id, read it with useRoute, navigate in code with useRouter, and build a card detail page that opens from the board.
    
    ```
- Lesson 19 - Shared State with Pinia
    lesson short description
    ```
    Install Pinia, move boards and cards into a store with state, getters, and actions, and use the same data on every page without passing props through layers.
    
    ```

### 7. `Module 7 - Coding Vue with AI`

```
Use everything you learned to read, review, and fix AI-generated Vue code, so you stay in control of the code that AI tools produce.
```


- Lesson 20 - Reading AI-Generated Vue Code
    lesson short description
    ```
    Read an AI-generated Vue component piece by piece, map each part to concepts from this course, and decide what to keep, simplify, or rewrite.
    
    ```
- Lesson 21 - Reviewing and Fixing AI-Generated Code
    lesson short description
    ```
    Spot and fix common bugs in AI-generated Vue code, such as lost reactivity, mutated props, missing keys, and runaway watchers, using a repeatable review checklist.
    
    ```

### 8. `Module 8 - Finishing Tasklane`

```
Polish Tasklane, build it for production, preview the result, and plan your next steps, including adding drag and drop on your own.
```


- Lesson 22 - Building for Production and What's Next
    lesson short description
    ```
    Build Tasklane with npm run build, preview the production version, review what you built, and get ideas for next steps such as drag and drop and deployment.
    
    ```
