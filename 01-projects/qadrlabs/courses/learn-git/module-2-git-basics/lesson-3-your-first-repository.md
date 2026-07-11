## 1. Before You Begin

A Git repository is a project folder that Git is tracking. Once you initialize a repository, Git watches every file inside it for changes. It does not record changes automatically - you decide what to track and when to save a snapshot. This lesson creates your first repository, introduces `git init` and `git status`, and walks through your very first commit. Everything you do in subsequent lessons builds on the three-step workflow you learn here: edit, stage, commit.

This lesson creates the portfolio website project that you will use throughout the course. You will initialize a Git repository, create the first HTML file, stage it, and commit it. By the end, you will have a repository with at least two commits and a clear understanding of why the staging step exists.

### What You'll Build

You will create a folder called `portfolio`, initialize it as a Git repository, write an `index.html` file, and make your first commit. You will then make a second change and commit it separately, so you end the lesson with a two-entry history that shows Git tracking real changes.

### What You'll Learn

- ✅ `git init` to create a repository
- ✅ The `.git` folder: where Git stores everything
- ✅ `git status` to check the state of your files
- ✅ `git add` to stage files
- ✅ `git commit -m "message"` to save a snapshot
- ✅ The difference between tracked and untracked files

### What You'll Need

- Lesson 2 completed with Git installed and configured
- A terminal and a text editor (VS Code recommended)

---

## 2. Create the Project Folder

Every Git project starts as a regular folder. You create the folder first using standard terminal commands, then tell Git to start tracking it. Git does not require any special folder structure - any directory can become a repository.

### Step 1: Create the Folder

Open your terminal and navigate to where you keep your projects (for example, your home directory or a `projects` folder). Then create the project directory and move into it.

```bash
mkdir portfolio
cd portfolio
```

`mkdir portfolio` creates an empty folder called `portfolio`. `cd portfolio` moves the terminal's working directory into it. At this point, Git knows nothing about this folder. It is just a regular directory on your computer, no different from any other.

### Step 2: Initialize the Repository

Now tell Git to start tracking this folder by initializing a repository.

```bash
git init
```

You should see output similar to:

```
Initialized empty Git repository in /home/budi/portfolio/.git/
```

This command creates a hidden `.git` folder inside `portfolio`. This folder is where Git stores the entire history of your project: every commit, every branch, every configuration. The `.git` folder is the repository itself. Everything else in the `portfolio` folder is your working directory, the place where you edit files normally.

### Step 3: Verify the Repository

Confirm the `.git` folder was created by listing all files including hidden ones.

```bash
ls -la
```

On Windows PowerShell, use `ls -Force` instead. You should see the `.git` folder listed among the directory contents. Never manually edit or delete anything inside `.git` unless you know exactly what you are doing. Deleting the `.git` folder removes the entire Git history and turns the folder back into a plain directory.

---

## 3. Create the First File

With the repository initialized, you can now create files and ask Git to start tracking them. Until you explicitly tell Git to track a file, Git sees it but ignores it.

### Step 1: Create index.html

Open your text editor and create a file called `index.html` inside the `portfolio` folder. Write the following content into it.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Portfolio</title>
</head>
<body>
    <h1>Welcome to My Portfolio</h1>
    <p>This is my personal website. More content coming soon!</p>
</body>
</html>
```

Save the file. This is a minimal HTML page with a heading and a paragraph. The content does not matter for learning Git - what matters is that you now have a real file in the working directory for Git to observe.

### Step 2: Check the Status

Before staging or committing anything, ask Git what it currently sees.

```bash
git status
```

You should see:

```
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        index.html

nothing added to commit but untracked files present (use "git add" to track)
```

Git sees the file but is not tracking it yet. The label "Untracked" means Git knows the file exists in the working directory but has not been told to include it in any snapshot. The output also helpfully tells you exactly what to do next: use `git add` to start tracking.

---

## 4. Stage and Commit

Staging and committing are the two steps that move your changes from the working directory into the permanent Git history. You must always stage changes before you can commit them - this two-step design is intentional and gives you precise control over what each commit contains.

### Step 1: Stage the File

Move `index.html` from the working directory into the staging area.

```bash
git add index.html
```

A successful `git add` produces no output. Silent success is the normal behavior. Verify that the file moved to the staging area by checking the status again.

```bash
git status
```

You should now see:

```
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   index.html
```

The file has moved from "Untracked files" to "Changes to be committed." It is now in the staging area, ready to be captured in the next commit. Nothing is permanent yet - you could still unstage it without losing your changes.

### Step 2: Commit

Save the staged snapshot permanently to the repository.

```bash
git commit -m "Add initial index.html with welcome message"
```

You should see:

```
[main (root-commit) a1b2c3d] Add initial index.html with welcome message
 1 file changed, 12 insertions(+)
 create mode 100644 index.html
```

The commit is done. Git has taken a snapshot of everything in the staging area and stored it permanently in the repository. The `-m` flag lets you provide the commit message directly on the command line - without it, Git would open your configured text editor. The hash `a1b2c3d` (yours will be different) is the unique ID for this commit. The phrase "root-commit" tells you this is the very first commit in the repository, meaning it has no parent.

### Step 3: Check the Status Again

Confirm the repository is in a clean state after committing.

```bash
git status
```

You should see:

```
On branch main
nothing to commit, working tree clean
```

"Working tree clean" means there are no changes since the last commit. Every tracked file matches its committed snapshot exactly. This is the state you will see regularly after a successful commit.

---

## 5. Verify and Extend

Now that you have one commit, verify the history is correct and then add a second commit to see how multiple commits build up over time.

### Step 1: View the Commit History

Read the full commit log to confirm your commit was recorded correctly.

```bash
git log
```

You should see one commit with your name, email, timestamp, and the message "Add initial index.html with welcome message." Press `q` to exit the log viewer when you are done reading.

### Step 2: View the Short Log

For a more compact view of the history, use the `--oneline` flag.

```bash
git log --oneline
```

This shows a compact format:

```
a1b2c3d (HEAD -> main) Add initial index.html with welcome message
```

`HEAD -> main` tells you that the currently active position (HEAD) is on the `main` branch, and `main` is pointing at this commit. Every time you make a new commit, `main` will automatically move forward to point to it.

### Step 3: Make a Second Change and Commit It

Edit `index.html` and change the `<p>` text from "More content coming soon!" to "This is my portfolio. I am learning Git!"

Save the file, then check the status.

```bash
git status
```

You should see:

```
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
        modified:   index.html
```

Git detected the change. The file is listed as "modified" because Git is now tracking it (it was committed in the previous step), and the current version on disk does not match the stored snapshot. The change exists only in the working directory. Stage and commit it.

```bash
git add index.html
git commit -m "Update welcome message"
```

Run `git log --oneline` to see both commits:

```
b2c3d4e (HEAD -> main) Update welcome message
a1b2c3d Add initial index.html with welcome message
```

You now have two commits in your history. Each one is an independent snapshot that you can return to at any time.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when creating a first repository and making commits.

**Error 1: Running `git init` in the wrong directory.**

If you run `git init` while your terminal is in the home directory or a parent folder instead of the project folder, Git starts tracking your entire home directory, including documents, downloads, and photos.

```bash
# Wrong: initializing from the home directory
cd /home/budi
git init
# Initialized empty Git repository in /home/budi/.git/

# Correct: navigate into the project folder first
cd /home/budi/portfolio
git init
# Initialized empty Git repository in /home/budi/portfolio/.git/
```

If you made this mistake, remove the incorrectly created `.git` folder from the home directory with `rm -rf /home/budi/.git`, then navigate to the correct project folder and re-run `git init`.

**Error 2: Forgetting to stage before committing.**

Trying to commit without first staging anything produces a confusing message instead of creating a commit. This is one of the most common stumbling points for beginners.

```bash
# Wrong: attempting to commit without staging
git commit -m "My changes"
# On branch main
# nothing to commit, working tree clean
# (or: nothing added to commit but untracked files present)

# Correct: stage first, then commit
git add index.html
git commit -m "My changes"
```

`git commit` only captures what is currently in the staging area. If nothing is staged, there is nothing to capture. Always run `git status` before committing to confirm that the files you intend to commit are listed under "Changes to be committed."

**Error 3: Getting stuck in Vim when forgetting the `-m` flag.**

If you run `git commit` without the `-m` flag, Git opens the configured text editor for you to type the message. On many Linux and macOS systems, the default editor is Vim, which has a steep learning curve.

```bash
# Wrong: forgetting -m opens the editor (possibly Vim)
git commit
# Opens Vim or another terminal editor unexpectedly

# Correct: always include -m with the message
git commit -m "Add initial index.html with welcome message"
```

If you find yourself inside Vim without intending to, press `Escape` to ensure you are in normal mode, then type `:q!` and press `Enter` to quit without saving. Git will then report that the commit was aborted. Re-run the command with the `-m` flag.

---

## 7. Exercises

**Exercise 1:** Create a `style.css` file with basic styling (a body font and a background color). Stage it and commit with the message "Add stylesheet". Verify with `git log --oneline` that you now have three commits.

**Exercise 2:** Create a `README.md` file with one line: `# My Portfolio`. Stage and commit it. Then modify it to add a second line: `A personal website built while learning Git.` Stage and commit the modification as a separate commit. You should now have five commits total.

**Exercise 3:** Run `git status` at each stage of the workflow: after creating a file, after staging with `git add`, and after committing. Write down what the output says at each point. This builds your intuition for the three areas.

---

## 8. Solutions

**Solution for Exercise 1:**

Create the stylesheet with the following content in a new file called `style.css`.

```css
body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    color: #333;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
```

Save the file, then stage and commit it.

```bash
git add style.css
git commit -m "Add stylesheet"
git log --oneline
```

You should see three commits listed, newest first. The `git log --oneline` output confirms the commit was recorded and that all three snapshots are present in the history.

**Solution for Exercise 2:**

Create the `README.md` file and commit the initial version.

```bash
echo "# My Portfolio" > README.md
git add README.md
git commit -m "Add README"
```

Then open `README.md` in your editor, add the second line, save the file, and commit the change as a separate commit.

```bash
git add README.md
git commit -m "Update README with project description"
git log --oneline
```

Five commits should now be visible in the log. Each commit is a separate snapshot created at a distinct moment, and each tells a clear story about what changed and why. The two README commits are separate by design: the first establishes the file, the second adds meaningful content - these are two distinct logical changes.

---

## 9. Understanding Repositories and Commits

A Git repository is not a special type of folder. It is a regular folder with a `.git` subdirectory that holds all the version control data. The `.git` directory contains the entire database of commits, branches, and configuration. Everything outside `.git` is the working directory where you edit files as you normally would.

A commit is a permanent snapshot of the staging area at the exact moment you run `git commit`. Once created, a commit cannot be changed (though Git provides tools to amend or revert commits, which you will learn later). Each commit holds four pieces of information: a unique hash (like `a1b2c3d`), the author name and email from your configuration, a timestamp, and a message you provide. Commits form a chain: each commit points to its parent (the previous commit). This chain is the project's complete history.

The staging area exists to give you control over what each commit contains. You might have changed five files in a working session, but only two changes are logically related to the same feature. Staging only those two files lets you commit them with a focused message, then commit the other three separately with their own message. This approach creates a clean, readable history instead of one large "changed stuff" commit that mixes unrelated changes.

Run `git status` often. It tells you exactly where every change currently lives: in the working directory (not staged), in the staging area (ready to commit), or committed (clean). Reading the status output becomes second nature within a few days of practice.

---

## Next Up - Lesson 4

`git init` creates a repository by adding a `.git` folder to your project directory. `git status` shows the current state of all files across the three areas. `git add <file>` moves changes into the staging area. `git commit -m "message"` saves a permanent snapshot to the repository. The working directory, staging area, and repository together give you precise control over what each commit contains. `git log` shows the complete, permanent commit history.

In Lesson 4, you will go deeper into the staging area and commits: staging specific files from a multi-file change, unstaging by mistake, writing meaningful commit messages, and understanding why atomic commits make your history more useful.