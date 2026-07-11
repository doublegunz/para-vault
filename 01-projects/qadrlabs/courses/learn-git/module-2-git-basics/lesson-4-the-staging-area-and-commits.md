## 1. Before You Begin

In the previous lesson, you used `git add` and `git commit` as a simple two-step process, staging one file at a time and committing it immediately. But the staging area is more powerful than a simple "save" button. It lets you choose exactly which changes to include in each commit from a group of modified files, stage multiple files selectively, unstage changes you added by mistake, and craft commits that tell a clear story. Mastering the staging area is what separates beginners from confident Git users.

This lesson goes deeper into staging and committing. You will learn to stage specific files when multiple files have changed, unstage files without losing your work, write meaningful commit messages, and create atomic commits that group only related changes together. These skills make your Git history readable and useful to your future self and to any teammate who reads it.

### What You'll Build

You will add a stylesheet link and navigation to the portfolio project from Lesson 3, then commit each logical change separately to demonstrate how the staging area enables focused, purposeful commits.

### What You'll Learn

- ✅ `git add <file>` for staging specific files
- ✅ `git add .` for staging everything (and when not to use it)
- ✅ `git restore --staged <file>` for unstaging
- ✅ Writing good commit messages
- ✅ Atomic commits: one logical change per commit
- ✅ `git commit -am "message"` shortcut for tracked files

### What You'll Need

- Lesson 3 completed with a portfolio repository containing at least two commits

---

## 2. Staging Specific Files

When you change multiple files during a working session, you do not have to stage them all at once. The ability to stage specific files lets you create focused commits that each represent one logical change, even when the working directory contains many mixed edits.

### Step 1: Make Multiple Changes

Open `index.html` and update it to add a stylesheet link in the `<head>` section and a navigation element in the `<body>`.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Portfolio</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav>
        <a href="index.html">Home</a>
    </nav>
    <h1>Welcome to My Portfolio</h1>
    <p>This is my portfolio. I am learning Git!</p>
</body>
</html>
```

Save the file. The new `<link>` tag connects the HTML page to the external stylesheet, and the `<nav>` element adds a navigation bar. Now open `style.css` and add navigation styles below the existing body styles.

```css
body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    color: #333;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

nav {
    background: #1e293b;
    padding: 12px 20px;
    border-radius: 6px;
    margin-bottom: 20px;
}

nav a {
    color: #93c5fd;
    text-decoration: none;
    margin-right: 16px;
}
```

Save the file. Now create a new file called `about.html` as a separate page for the portfolio.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>About Me</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
    </nav>
    <h1>About Me</h1>
    <p>I am a developer learning Git and version control.</p>
</body>
</html>
```

Save the file. You now have three changes in the working directory: two modified files and one new file.

### Step 2: Check What Changed

Before staging anything, inspect the current state of the working directory.

```bash
git status
```

You should see two modified files (`index.html`, `style.css`) and one new untracked file (`about.html`). All three changes sit in the working directory, and none are staged. This is the moment where the staging area's value becomes clear - you have three changes, but they represent two different logical concerns.

### Step 3: Stage and Commit in Logical Groups

The navigation bar and its stylesheet are one logical change: they were built together and only make sense together. The about page is a separate feature. Commit them separately so that each commit tells a single, focused story.

Stage the navigation-related files and commit them first.

```bash
git add index.html style.css
git commit -m "Add navigation bar and link stylesheet"
```

By passing both filenames to `git add`, you add exactly those two files to the staging area while leaving `about.html` in the working directory untouched. Now stage and commit the about page as its own commit.

```bash
git add about.html
git commit -m "Add about page"
```

Run `git log --oneline` to confirm the two separate commits are recorded. Each commit contains one logical change, making the history easy to read and each change easy to revert independently if needed.

---

## 3. Unstaging Files

Sometimes you stage a file by accident, perhaps by running `git add .` when you only intended to stage one file. The `git restore --staged` command moves a file back from the staging area to the working directory without discarding any of your actual edits.

### Step 1: Stage a File, Then Unstage It

Make a small change to `README.md` (or any file in the repository). Stage it to simulate the accidental staging scenario.

```bash
git add README.md
git status
```

The file appears under "Changes to be committed." This means it would be included in the next `git commit`. Now unstage it.

```bash
git restore --staged README.md
git status
```

The file moves back to "Changes not staged for commit." Your edits to the file are still present - `git restore --staged` only changes where the file sits in Git's three areas. Nothing was lost. If you run `git diff README.md` now, you will see the changes still exist in the working directory, waiting to be staged again when you are ready.

---

## 4. Writing Good Commit Messages

A commit message explains why a change was made, not just what changed. Git already records what changed in the diff - the message is your opportunity to provide context that the diff cannot show. Good messages make the history useful for your future self and for teammates reviewing changes.

Good messages follow a clear convention: start with a verb in imperative mood (writing the message as if you are giving a command to the codebase), keep the first line under 72 characters, and capitalize the first letter. The imperative mood reads naturally when prefixed with the phrase "If applied, this commit will..."

| Good Message | Bad Message |
|-------------|------------|
| Add navigation bar to homepage | added stuff |
| Fix broken link on about page | fix |
| Update stylesheet with responsive layout | changes to css |
| Remove unused contact form | deleted some files |

"If applied, this commit will **add navigation bar to homepage**" reads as a complete, meaningful sentence. "If applied, this commit will **added stuff**" does not. The imperative verb makes the message precise and consistent across a team.

---

## 5. The `git add .` Shortcut

`git add .` is a convenient shortcut that stages everything in the current directory and all subdirectories at once: all modified files, all new files, and all deleted files. It is useful when you know every change in the working directory belongs in the same commit, but it requires care.

Use `git add .` only when you have already checked `git status` and confirmed that every listed file should go into the next commit.

```bash
git add .
```

`git add .` does not filter by file type or content. It stages everything without exception, including temporary files, editor backup files, and any secrets (environment variables, passwords, API keys) that happen to exist in the folder. Always run `git status` and review the staged file list before running `git commit`. Use `git add <file>` when you need precise control over which changes go into a commit. In Lesson 17, you will learn how `.gitignore` can automatically exclude certain files from `git add .`.

---

## 6. Verify the History

Before moving on, confirm that all the changes you made in this lesson were recorded correctly. This step also introduces the habit of checking the log after each working session.

### Step 1: Verify the Commit Log

Read the compact log to see all your commits in order.

```bash
git log --oneline
```

You should see at least your two new commits at the top: "Add about page" and "Add navigation bar and link stylesheet." These appear before the commits from Lesson 3. The newest commit is always at the top. This clean history tells a story: first the base was established, then the navigation was added, then the about page was built.

### Step 2: Verify the File Contents

Open `index.html` in a browser by double-clicking the file (or running `open index.html` on macOS). You should see the heading with a dark navigation bar at the top containing a "Home" link. Open `about.html` to verify it has the same navigation style and its own heading.

### Step 3: Test Unstaging

Stage any file in the repository, verify with `git status` that it appears under "Changes to be committed," then unstage it with `git restore --staged`, and verify again with `git status`. The file should move between staged and unstaged states without any change to the file's actual content.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when working with the staging area and commits.

**Error 1: Forgetting the `-m` flag and getting stuck in an editor.**

Running `git commit` without `-m` causes Git to open the configured text editor so you can write a commit message. This is intentional behavior, but it surprises beginners who expect the commit to happen immediately.

```bash
# Wrong: no message flag opens the editor
git commit
# Opens VS Code, Vim, or Nano depending on your config

# Correct: always provide the message inline
git commit -m "Add navigation bar and link stylesheet"
```

If you find yourself inside Vim unexpectedly, press `Escape` to enter normal mode, type `:q!`, and press `Enter` to quit without creating a commit. Then re-run the command with `-m`. If you are in Nano, press `Ctrl+X` and then `N` to cancel.

**Error 2: Staging sensitive files with `git add .`.**

`git add .` stages every file in the directory, including environment files, configuration files with passwords, or any other sensitive data that should never enter version history.

```bash
# Wrong: git add . stages everything including secrets
git add .
git status
# Changes to be committed:
#   new file: .env          (contains API keys!)
#   new file: index.html

# Correct: unstage the sensitive file immediately
git restore --staged .env
git status
# Changes to be committed:
#   new file: index.html
```

After unstaging `.env`, create a `.gitignore` file and add `.env` to it so it is automatically excluded from all future `git add .` calls. Lesson 17 covers `.gitignore` in detail.

**Error 3: Creating a single "kitchen sink" commit with unrelated changes.**

Staging all modified files at once and committing them together with a vague message creates a commit that is impossible to understand or partially revert later.

```bash
# Wrong: all changes in one giant unrelated commit
git add .
git commit -m "Update everything"
# One commit mixing navigation changes, a new page, a bug fix, and a style update.

# Correct: stage and commit related changes separately
git add index.html style.css
git commit -m "Add navigation bar and link stylesheet"

git add about.html
git commit -m "Add about page"
```

A commit that mixes unrelated changes becomes a problem when you need to revert one specific change. Reverting the "Update everything" commit undoes all four changes at once. Reverting "Add about page" undoes only the about page, leaving navigation untouched. Keep commits atomic: one logical change per commit.

---

## 8. Exercises

**Exercise 1:** Update the navigation in both `index.html` and `about.html` to include an "About" link on both pages. Stage both files together in a single commit with the message "Add About link to navigation on all pages."

**Exercise 2:** Practice unstaging: modify three files, stage all three with `git add .`, then unstage one specific file with `git restore --staged <file>`. Verify with `git status` that exactly two files remain staged. Commit the two staged files, then commit the third file separately.

**Exercise 3:** Write good commit messages (following the imperative mood convention) for these three scenarios: (a) you added a footer section to every page, (b) you fixed a typo in the about page heading, (c) you removed an unused image file from the folder.

---

## 9. Solutions

**Solution for Exercise 1:**

Edit `index.html` and `about.html` to add the About link inside the `<nav>` element on each page. Then stage both files together and commit.

```bash
git add index.html about.html
git commit -m "Add About link to navigation on all pages"
```

Both files are in the same commit because the change is one logical unit - updating the navigation consistently across all pages. A user navigating to the About page but not finding the link on the Home page would be a broken experience, so both changes belong together.

**Solution for Exercise 2:**

Modify three files in the repository (for example, `index.html`, `about.html`, and `style.css`). Then stage all three.

```bash
git add .
git status
```

Confirm all three appear under "Changes to be committed." Then unstage one file.

```bash
git restore --staged style.css
git status
```

Confirm that `index.html` and `about.html` remain staged while `style.css` has moved back to "Changes not staged for commit." Commit the two staged files first.

```bash
git commit -m "Update navigation on index and about pages"
```

Then stage and commit the remaining file separately.

```bash
git add style.css
git commit -m "Update navigation styles"
```

This produces two commits that each represent one focused logical change, even though all three files were modified at the same time.

**Solution for Exercise 3:**

(a) "Add footer section to all pages"

(b) "Fix typo in about page heading"

(c) "Remove unused hero image"

Each message opens with an imperative verb, describes the single change clearly, stays under 72 characters, and would complete the sentence "If applied, this commit will..." naturally.

---

## 10. Understanding Atomic Commits

The principle of atomic commits states that each commit should contain exactly one logical change. If you add a feature and fix a bug in the same coding session, those are two commits. If you update the CSS across three files to implement the same visual design change, that is one commit containing three files. The unit is the logical change, not the number of files.

Atomic commits matter for three practical reasons. First, they make the history readable: a list of commits like "Add navigation," "Add about page," and "Fix nav link color" tells a clear story that anyone can follow. Second, they make reverting safe: if the navigation change introduces a layout bug, you can revert that one commit without touching the about page or the color fix. Third, they make code review easier: a reviewer examining a small, focused change can understand it quickly and give precise feedback.

The staging area is the tool that makes atomic commits possible. You might have changed five files in a working session, but only two are related to the feature you want to commit. Staging only those two lets you commit them with a focused message, then stage and commit the others with their own message. Without the staging area, every commit would include all changes present in the working directory - no selective control, no atomic commits.

---

## Next Up - Lesson 5

The staging area gives you precise control over what goes into each commit. `git add <file>` stages specific files. `git add .` stages everything in the directory and should always be followed by a `git status` review before committing. `git restore --staged <file>` moves a file back to the working directory without losing your changes. Good commit messages start with an imperative verb, stay under 72 characters, and describe why the change was made. Atomic commits - one logical change per commit - make history readable, reverting safe, and code review tractable.

In Lesson 5, you will learn to view history and differences: reading the commit log in detail, comparing file versions between commits, and understanding what `git diff` shows you about what changed and where.