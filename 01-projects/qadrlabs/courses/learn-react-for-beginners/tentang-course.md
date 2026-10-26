---
title: "Learn React for Beginners: Build a Real App Step by Step"
slug: "learn-react-for-beginners"
status: "draft"
---

# Learn React for Beginners: Build a Real App Step by Step

## Deskripsi
```
Learn React from zero by building Spendly, an expense tracker. Master components, props, state, forms, effects, API data, and React Router, then learn to read and fix AI-generated React code.
```


## Konten

```
React is the most popular JavaScript library for building user interfaces. It powers the dashboards, online stores, and social apps you use every day, and it is also the code that AI coding assistants write most often. Ask an AI tool to "build me a web app" and there is a good chance you will get a React project back. That makes React a great skill to learn today, but it also creates a new problem: many people now have React code they did not write and cannot fix when something breaks.

This course teaches React from the beginning, one concept at a time, through a single case study. Instead of isolated examples, you will build Spendly, a personal expense tracker, from an empty folder to a finished multi-page app. Each lesson adds one feature to Spendly: first the layout, then a transaction list, a form to add transactions, editing and deleting, a live balance summary, filters and search, saving data in the browser, loading data from an API, and separate pages with React Router. Every lesson also includes common mistakes to fix, exercises, and full solutions.

The course closes with a module on coding React with AI. You will learn how to read AI-generated React code using the concepts from this course, spot the bugs AI tools often produce (missing keys, mutated state, endless effects, stale values), and fix them with confidence. The goal is not to replace AI tools, but to make you the developer who understands and controls the code they produce.

The project uses Vite, React, React Router, and plain CSS, with JavaScript (no TypeScript). If you have never written code before, the free courses "[Learn HTML and CSS](https://qadrlabs.com/course/learn-html-and-css-build-your-first-website-from-scratch)" and "[Learn JavaScript Basics](https://qadrlabs.com/course/learn-javascript-basics-from-zero-to-interactive-web-pages)" on qadrlabs are the recommended first steps.

**Prerequisites:**
- Basic HTML and CSS: tags, attributes, classes, and simple styling
- Basic JavaScript: variables, functions, arrays, objects, and arrow functions (covered in the qadrlabs JavaScript Basics course)
- A computer running Windows, macOS, or Linux with terminal access
- A modern web browser such as Chrome or Firefox, and a text editor such as Visual Studio Code
- An internet connection to install Node.js and project packages

**By the end, you will have:**
- A working React development setup with Node.js, npm, and Vite, and a clear picture of how a React project is organized
- A solid grasp of JSX, components, props, list rendering, and conditional rendering
- The ability to handle events, manage state with useState, and build controlled forms
- Experience lifting state up, calculating derived data, and keeping state updates immutable
- Practice with useEffect, localStorage, fetching data from an API, and writing custom hooks
- A multi-page app built with React Router, dynamic routes, and shared state with Context
- The skills to read, review, and fix AI-generated React code instead of copying it blindly
- Spendly, a complete expense tracker app built for production with npm run build
```

## Daftar Modul

### 1. `Module 1 - Getting to Know Spendly`

```
Understand what React is and why it matters in the age of AI coding tools, see the Spendly app you will build, and set up your first React project with Vite.
```


- Lesson 1 - What Is React and What We Will Build
    lesson short description
    ```
    Learn what React is, how it differs from plain JavaScript DOM code, why AI tools generate so much React, and take a tour of the finished Spendly expense tracker.
    
    ```
- Lesson 2 - Setting Up Your React Project with Vite
    lesson short description
    ```
    Install Node.js and npm, create the Spendly project with Vite, run the development server, and explore the project folders and files you will work with.
    
    ```

### 2. `Module 2 - React Foundations`

```
Learn the building blocks of every React app: JSX, components, props, lists, conditional rendering, and styling, and use them to build the static Spendly layout.
```


- Lesson 3 - JSX: Writing HTML in JavaScript
    lesson short description
    ```
    Write JSX to describe the user interface, embed JavaScript expressions with curly braces, and learn the JSX rules that differ from HTML, such as className and closing tags.
    
    ```
- Lesson 4 - Components: The Building Blocks of Spendly
    lesson short description
    ```
    Split the Spendly page into small function components such as Header, Summary, and TransactionList, and organize them into separate files with import and export.
    
    ```
- Lesson 5 - Props: Passing Data to Components
    lesson short description
    ```
    Pass data from parent to child components with props, destructure them, set default values, and make Spendly components reusable for different transactions.
    
    ```
- Lesson 6 - Rendering Lists and Conditional Content
    lesson short description
    ```
    Render the transaction list from an array with map and keys, show different content with conditions, and display an empty state when there are no transactions.
    
    ```
- Lesson 7 - Styling Components with CSS
    lesson short description
    ```
    Style Spendly with plain CSS files, apply classes with className, use inline styles where they fit, and change styles based on data such as income and expense.
    
    ```

### 3. `Module 3 - Making Spendly Interactive`

```
Bring Spendly to life with events and state, build a form to add transactions, and let users edit and delete them while keeping state updates correct.
```


- Lesson 8 - Handling Events
    lesson short description
    ```
    Respond to clicks and other user actions with event handlers, pass functions as props, and learn the difference between passing a function and calling it.
    
    ```
- Lesson 9 - State with useState
    lesson short description
    ```
    Store changing data with the useState hook, update it to re-render the screen, and understand why normal variables do not update the user interface.
    
    ```
- Lesson 10 - Forms: Adding a Transaction
    lesson short description
    ```
    Build a controlled form for new transactions with text, number, select, and date inputs, handle submission, validate input, and add the result to the list.
    
    ```
- Lesson 11 - Editing and Deleting Transactions
    lesson short description
    ```
    Delete transactions with filter, edit them with map, reuse the form for editing, and learn why React state must be updated immutably instead of changed directly.
    
    ```

### 4. `Module 4 - Organizing State`

```
Decide where state should live as Spendly grows, share it between components, and calculate totals, filters, and search results from existing data.
```


- Lesson 12 - Lifting State Up
    lesson short description
    ```
    Move shared state to the closest common parent, pass data down and callbacks up, and connect the form, list, and summary components to one source of truth.
    
    ```
- Lesson 13 - Derived Data: Totals, Filters, and Search
    lesson short description
    ```
    Calculate income, expense, and balance from the transaction list, filter by category, search by text, and learn why derived values should not be stored in state.
    
    ```

### 5. `Module 5 - Side Effects and Data`

```
Work with the world outside React: save transactions in the browser, load data from an API with loading and error states, and package logic into custom hooks.
```


- Lesson 14 - useEffect: Saving Transactions to localStorage
    lesson short description
    ```
    Understand side effects and the useEffect hook, use the dependency array correctly, and save and load Spendly transactions with localStorage so data survives a refresh.
    
    ```
- Lesson 15 - Fetching Data from an API
    lesson short description
    ```
    Fetch categories from a JSON file and exchange rates from a free public API with fetch and async/await, and show loading and error states while data arrives.
    
    ```
- Lesson 16 - Custom Hooks: Reusing Logic
    lesson short description
    ```
    Extract repeated logic into custom hooks such as useLocalStorage and useFetch, follow the rules of hooks, and make Spendly components shorter and easier to read.
    
    ```

### 6. `Module 6 - Multiple Pages with React Router`

```
Turn Spendly into a multi-page app with React Router, add a detail page for each transaction, and share state across pages with React Context.
```


- Lesson 17 - Setting Up React Router
    lesson short description
    ```
    Install React Router, define routes for the Dashboard, Transactions, and Add pages, build a shared layout with navigation links, and handle unknown URLs.
    
    ```
- Lesson 18 - Dynamic Routes: The Transaction Detail Page
    lesson short description
    ```
    Create a detail page with a dynamic route, read the transaction id with useParams, navigate in code with useNavigate, and show a not found message for missing data.
    
    ```
- Lesson 19 - Sharing State with Context
    lesson short description
    ```
    Avoid passing props through many layers by creating a TransactionsContext, providing it at the top of the app, and reading it from any page with useContext.
    
    ```

### 7. `Module 7 - Coding React with AI`

```
Use AI coding assistants with confidence: read AI-generated React code with the concepts you learned, spot common bugs, and fix them before they reach users.
```


- Lesson 20 - Reading AI-Generated React Code
    lesson short description
    ```
    Write clear prompts for a new Spendly feature, then read the AI-generated code line by line, mapping each part to components, props, state, and effects you already know.
    
    ```
- Lesson 21 - Reviewing and Fixing AI-Generated Code
    lesson short description
    ```
    Find and fix the bugs AI tools often produce in React code, such as missing keys, mutated state, endless effect loops, and stale state, using a simple review checklist.
    
    ```

### 8. `Module 8 - Finishing Spendly`

```
Prepare Spendly for production, review everything you built across the course, and plan your next steps as a React developer.
```


- Lesson 22 - Building for Production and What's Next
    lesson short description
    ```
    Build Spendly for production with npm run build, preview the result, review the concepts used in each feature, and explore next steps such as TypeScript and Next.js.
    
    ```
