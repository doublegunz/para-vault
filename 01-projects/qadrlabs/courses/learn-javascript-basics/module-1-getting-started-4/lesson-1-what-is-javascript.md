## 1. Before You Begin

HTML provides structure. CSS provides style. JavaScript provides behavior. It is the third pillar of web development and the only programming language that runs natively in every web browser. When you click a button and a menu appears, when a form validates your email before you submit, when content loads without refreshing the page - that is JavaScript at work.

This lesson has no code. The focus is on understanding what JavaScript does, where it runs, and what you will build throughout this course. Getting this mental model right from the start will make every following lesson much easier to understand.

### What You'll Build

This lesson is conceptual - there is no file to create yet. By the end, you will have a clear picture of what JavaScript is, how it differs from HTML and CSS, and a preview of the complete to-do list application you will build by Lesson 13.

### What You'll Learn

- ✅ What JavaScript is and what it does
- ✅ Where JavaScript runs (browser and server)
- ✅ The difference between JavaScript, HTML, and CSS
- ✅ What you will build in this course
- ✅ The course roadmap

### What You'll Need

- A computer with a web browser (Chrome recommended)
- HTML and CSS knowledge recommended (but not strictly required)

---

## 2. What Is JavaScript?

JavaScript is a programming language that makes web pages interactive. Unlike HTML, which defines structure, and CSS, which defines appearance, JavaScript defines behavior: what happens when a user clicks, types, scrolls, or submits a form. Every modern website uses JavaScript, and it is not optional - it is essential.

Here are concrete examples of JavaScript in action:

- A dropdown menu that opens when you click a hamburger icon
- A form that shows "Password too short" as you type
- An image carousel that slides automatically
- A shopping cart that updates without refreshing the page
- A dark mode toggle that switches the entire color scheme

Each of these behaviors requires JavaScript because neither HTML nor CSS can respond to user input, store state, or change the page after it has loaded.

---

## 3. Where JavaScript Runs

JavaScript does not run exclusively in the browser. Understanding its environments helps you see why it is such a versatile language and what this course covers versus what is left for later.

**In the browser (client-side).** Every browser - Chrome, Firefox, Safari, and Edge - has a built-in JavaScript engine. When a web page includes JavaScript, the browser downloads and executes it. Chrome uses an engine called V8. Firefox uses SpiderMonkey. The result is the same: JavaScript runs locally on the user's machine, directly inside the browser tab. This is the environment this course focuses on.

**On the server (server-side).** Node.js lets you run JavaScript outside the browser, on a web server. This enables building backend APIs and full-stack applications entirely in JavaScript. Server-side JavaScript is covered in advanced courses and is not required for this one.

**On mobile and desktop.** Frameworks like React Native (mobile) and Electron (desktop) use JavaScript to build native-feeling applications. These are specialized topics built on top of the fundamentals you will learn here.

For this course, you only need a browser. No server, no installation, no configuration beyond a text editor.

---

## 4. JavaScript vs HTML vs CSS

The three core technologies of the web each have a single, well-defined responsibility. Confusing their roles is one of the most common sources of frustration for beginners, so it is worth being precise about what each one does.

| Technology | Role | Example |
|-----------|------|---------|
| HTML | Structure | `<button>Click me</button>` |
| CSS | Style | `button { background: blue; color: white; }` |
| JavaScript | Behavior | `button.addEventListener('click', () => alert('Clicked!'))` |

All three work together on every page. HTML creates the button element. CSS makes it blue with white text. JavaScript makes something happen when you click it. Remove any one of the three and the experience degrades: no HTML means no button, no CSS means an unstyled button, no JavaScript means a button that does nothing when clicked.

---

## 5. What You Will Build

Every lesson in this course builds toward a single, complete project. Rather than practicing isolated skills in exercises that go nowhere, each concept you learn immediately applies to a real, working application.

Throughout this course, you will build an interactive to-do list application with the following features:

- Add a new task by typing and pressing Enter
- Mark a task as complete with a strikethrough style
- Delete a task with a single click
- Filter tasks by view: All, Active, or Completed
- Save tasks to localStorage so they persist after a page refresh
- Show a live count of remaining tasks

This project uses every concept from every lesson: variables, functions, arrays, objects, DOM manipulation, events, and forms. By Lesson 13, you will have a finished, working application you built from scratch.

---

## 6. Course Roadmap

This course is organized across fourteen lessons that move from concepts to hands-on code to a finished project. Each group of lessons focuses on one area of the language.

**Lessons 1 and 2** cover what JavaScript is and how to write and run your first script in the browser.

**Lessons 3 and 4** teach the fundamentals: variables and data types, operators, and control flow with conditionals.

**Lessons 5 and 6** cover functions and loops, the two tools you will use in nearly every program you write.

**Lessons 7 and 8** teach collections: arrays for ordered lists of values and objects for structured data.

**Lessons 9 and 10** introduce the DOM - the browser's representation of the HTML document - including how to select, create, and modify elements with JavaScript.

**Lessons 11 and 12** cover events and forms: how to listen for user interactions and handle form submissions and input validation.

**Lessons 13 and 14** bring everything together in the complete to-do list project and map out your next steps after this course.

---

## Next Up - Lesson 2

JavaScript is the programming language of the web. It runs inside the browser, makes pages interactive, and is the only language natively supported by all browsers without any installation. HTML defines structure, CSS defines style, and JavaScript defines behavior. Together, these three technologies form the complete web development toolkit that powers every website you use.

In Lesson 2, you will write your first JavaScript program using the browser console and a script file linked to an HTML page.