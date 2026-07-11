## 1. Before You Begin

You have been creating commits, but how do you look back at what you have done? How do you see exactly what changed between two versions of a file? Git provides powerful tools for inspecting history: `git log` shows the timeline of commits with author, date, and message, and `git diff` shows exactly what changed line by line between any two states. These tools are essential for understanding a project's evolution, finding when a bug was introduced, and reviewing your own work before pushing it to a team.

This lesson covers `git log` with various formatting options, `git diff` for comparing versions across the three areas, and `git show` for inspecting individual commits. You will use these commands on the portfolio project to explore the history you have been building since Lesson 3.

### What You'll Build

You will make additional changes to the portfolio project and use Git's history and comparison tools to examine every change at each stage of the workflow - before staging, after staging, and after committing.

### What You'll Learn

- ✅ `git log` with formatting options: `--oneline`, `--graph`, `--stat`
- ✅ `git diff` for comparing the working directory to the staging area
- ✅ `git diff --staged` for comparing the staging area to the last commit
- ✅ `git show <hash>` for inspecting a specific commit
- ✅ Reading diff output: `+` for additions, `-` for deletions

### What You'll Need

- Lesson 4 completed with several commits in the portfolio repository

---

## 2. Exploring git log

The `git log` command shows the commit history in reverse chronological order, with the newest commit at the top. It accepts many formatting flags that control how much detail is displayed, making it useful for everything from a quick overview to a detailed audit of the project timeline.

### Step 1: Full Log

Run `git log` with no flags to see the complete information for every commit.

```bash
git log
```

This shows the full log with hash, author, date, and message for each commit. Press `Space` to scroll down one page, `b` to scroll up, and `q` to quit. The output looks like:

```
commit b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1
Author: Budi Santoso <budi@example.com>
Date:   Mon Apr 14 10:30:00 2026 +0700

    Add about page
```

Each commit shows its full 40-character hash, the author's name and email, the date, and the message. The hash uniquely identifies this commit - no two commits anywhere in any Git repository share the same hash.

### Step 2: Compact Log

For a quicker overview, use the `--oneline` flag to condense each commit to a single line.

```bash
git log --oneline
```

This shows one line per commit with an abbreviated 7-character hash:

```
b2c3d4e (HEAD -> main) Add about page
a1b2c3d Add navigation bar and link stylesheet
9f8e7d6 Update welcome message
3c2b1a0 Add initial index.html with welcome message
```

The `(HEAD -> main)` label on the first line tells you that `HEAD` (your current position in the history) is on the `main` branch, which is pointing at the most recent commit. You will see this label move as you create new commits or switch branches.

### Step 3: Log with Stats

To see which files changed in each commit without reading the full diff, use `--stat`.

```bash
git log --oneline --stat
```

`--stat` appends a short summary below each commit showing which files were modified and how many lines were added or removed. This is useful for quickly gauging the scope of each change without reading the full diff output.

### Step 4: Log with Graph

To visualize the branch structure alongside the commit history, combine `--graph` and `--all`.

```bash
git log --oneline --graph --all
```

`--graph` draws a text-based diagram of branch relationships to the left of each commit line. `--all` includes commits from all branches, not just the current one. Right now with only one branch, it shows a straight vertical line. In Lesson 8, when you have multiple branches and merges, the graph becomes a diamond shape and is invaluable for understanding how branches relate to each other.

---

## 3. Comparing Changes with git diff

`git diff` shows the exact lines that changed between two states. Understanding which two states are being compared is the key to using it correctly. Without flags, it compares the working directory to the staging area. With `--staged`, it compares the staging area to the last commit.

### Step 1: Make a Change Without Staging

Edit `index.html` and add a new paragraph below the existing one so the body section looks like this.

```html
<p>This is my portfolio. I am learning Git!</p>
<p>I am building this site to practice version control.</p>
```

Save the file but do not run `git add` yet. The change exists only in the working directory.

### Step 2: Diff Working Directory vs Staging Area

Run `git diff` to see what has changed in the working directory compared to the staging area.

```bash
git diff
```

The output looks like:

```diff
diff --git a/index.html b/index.html
--- a/index.html
+++ b/index.html
@@ -11,5 +11,6 @@
     </nav>
     <h1>Welcome to My Portfolio</h1>
     <p>This is my portfolio. I am learning Git!</p>
+    <p>I am building this site to practice version control.</p>
 </body>
 </html>
```

Lines starting with `+` (displayed in green in most terminals) were added. Lines starting with `-` (displayed in red) were removed. Lines without either prefix are unchanged context lines included to show where the change is located in the file. The `@@` header indicates which lines in the file the diff chunk covers.

### Step 3: Stage the Change and Diff Staged vs Last Commit

Stage the file, then compare the staging area against the last commit.

```bash
git add index.html
git diff --staged
```

After staging, running plain `git diff` shows nothing - because the working directory and the staging area now contain identical content. `git diff --staged` compares the staging area against the last commit, showing you exactly what will be recorded when you run `git commit`. This is a useful habit to run before every commit to confirm you are capturing the right change.

### Step 4: Commit and Verify

Commit the staged change and then run both diff commands to confirm the clean state.

```bash
git commit -m "Add second paragraph to homepage"
git diff
git diff --staged
```

Both diff commands should return no output. This confirms that the working directory, staging area, and last commit are all identical - a "working tree clean" state.

---

## 4. Inspecting a Specific Commit

`git show` lets you examine the full details of any single commit: its message, author, date, and the complete diff of every change it introduced. This is useful when you want to understand what one specific commit did without reading the entire log.

```bash
git show a1b2c3d
```

Replace `a1b2c3d` with an actual hash from your `git log --oneline` output. The command shows the commit metadata followed by the full diff of that commit's changes. Press `q` to exit the viewer.

You can also use relative references instead of copying a hash. `git show HEAD` inspects the most recent commit. `git show HEAD~1` inspects the commit one step before the most recent. `git show HEAD~2` goes back two steps, and so on. These relative references work anywhere Git accepts a commit identifier.

---

## 5. Verify the History

Before moving on, confirm that the history is in the state you expect and practice all three diff comparisons in sequence. Running through this verification after each working session becomes a professional habit.

### Step 1: Verify the Log

Count the commits to confirm your entire history is intact.

```bash
git log --oneline
```

You should see several commits, each on its own line. Each one is a distinct snapshot of the project that you can return to at any time.

### Step 2: Practice the Three Diffs in One Sequence

Make a small change to any file but do not stage it. Run `git diff` to see the unstaged change. Stage it with `git add`. Run `git diff` again (now shows nothing, because working directory matches staging area) and `git diff --staged` (shows the staged change). Commit it. Run both diff commands again (both show nothing). This cycle through all three states reinforces the three-area model you learned in Lesson 1.

### Step 3: Compare Two Specific Commits

To see all changes introduced between two points in history, pass two commit hashes to `git diff`.

```bash
git diff a1b2c3d b2c3d4e
```

Replace both hashes with actual values from your `git log --oneline` output. This shows every line-level difference between those two commits, regardless of what is currently in your working directory or staging area. This is how you compare any two snapshots in the project's history.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when working with `git log` and `git diff`.

**Error 1: `git diff` shows nothing after staging.**

After running `git add`, `git diff` returns no output, which beginners interpret as a bug. This is correct behavior: `git diff` compares the working directory to the staging area, and they are now identical because you just staged the working directory's content.

```bash
# Wrong: expecting git diff to always show staged changes
git add index.html
git diff
# (no output - beginners think the change was lost)

# Correct: use git diff --staged to see what will be committed
git diff --staged
# diff --git a/index.html b/index.html
# +    <p>I am building this site to practice version control.</p>
```

`git diff --staged` is the right tool to review staged changes before committing. Make it a habit to run `git diff --staged` before every `git commit` to confirm you are committing exactly what you intend.

**Error 2: Getting stuck in the log pager.**

`git log` pipes its output through a pager program (usually `less`) when the output is longer than the terminal window. The terminal appears frozen because the pager is waiting for a navigation command.

```bash
# Wrong: pressing Ctrl+C or Ctrl+Z to exit (leaves terminal in a broken state)
git log
# (output stops, cursor sits at the bottom - pressing Ctrl+C may not work cleanly)

# Correct: use the pager's own quit key
# Press Space to scroll down one page
# Press b to scroll up one page
# Press q to exit the pager cleanly
```

If you ever exit the pager improperly and the terminal behaves strangely, type `reset` and press `Enter` to restore it to a normal state.

**Error 3: "fatal: bad object" when using `git show`.**

Passing a hash that does not exist in the repository produces a fatal error. This usually happens when the hash was typed manually with a typo, or copied from a different repository.

```bash
# Wrong: using a hash that does not exist in this repository
git show xyz123abc
# fatal: bad object xyz123abc

# Correct: copy the hash directly from git log --oneline output
git log --oneline
# b2c3d4e (HEAD -> main) Add about page   <-- copy this
git show b2c3d4e
```

Only the first 7 characters of the hash are needed. Git uses those 7 characters as a prefix and finds the full hash automatically. If two commits in the repository share the same 7-character prefix (extremely rare), Git will ask for more characters.

---

## 7. Exercises

**Exercise 1:** Run `git log --oneline --stat` and examine which files changed in each commit. Identify the commit that changed the most lines.

**Exercise 2:** Make changes to two files simultaneously. Run `git diff` to see both changes. Stage only one file. Run `git diff` (shows only the unstaged file) and `git diff --staged` (shows only the staged file). Commit the staged file. Repeat the process for the second file.

**Exercise 3:** Use `git show HEAD~2` to view the commit two steps back. Compare its output to `git show HEAD` to observe how the project changed over those two commits.

---

## 8. Solutions

**Solution for Exercise 2:**

Edit both `index.html` and `style.css` with any change, then work through the staging process one file at a time.

```bash
git diff
git add index.html
git diff
git diff --staged
git commit -m "Update homepage content"
git add style.css
git commit -m "Update stylesheet"
```

`git diff` after the first `git add` shows only `style.css` - the file still in the working directory. `git diff --staged` shows only `index.html` - the file in the staging area. After committing `index.html`, the cycle repeats for `style.css`. This exercise demonstrates that `git diff` and `git diff --staged` each look at a specific boundary in the three-area model, not at "all changes."

**Solution for Exercise 3:**

Run the two `git show` commands and compare their diff sections.

```bash
git show HEAD~2
git show HEAD
```

`HEAD~2` displays the commit two steps behind the current tip. The diff section shows what that specific commit added or removed. `HEAD` shows the most recent commit. Comparing them reveals how the project evolved between those two points. The commit messages tell you the intent; the diff shows the exact implementation.

---

## 9. Understanding Git History

Git history is a chain of commits, each pointing to its parent. When you run `git log`, Git walks this chain backward from the current commit (`HEAD`) to the very first commit (the root commit). This chain is immutable: once created, a commit's content and its parent pointer never change, which is what makes Git history trustworthy.

The `git diff` command is a comparison tool that always operates on exactly two states. The three most common comparisons are: working directory against staging area (`git diff`), staging area against last commit (`git diff --staged`), and any two specific commits (`git diff <hash1> <hash2>`). Knowing which two states you are comparing is the single most important concept for using diff correctly.

The commit hash is a SHA-1 checksum calculated from the commit's entire content: the file snapshots, the parent pointer, the author information, the timestamp, and the message. If any part of this data changes, the hash changes. This design means you cannot alter a historical commit without producing a completely different hash, which breaks the chain and is immediately detectable. This is why Git history is reliable even in large distributed teams.

---

## Next Up - Lesson 6

`git log` shows the commit history. Use `--oneline` for compact output, `--stat` for file change summaries, and `--graph --all` for a visual diagram of branch relationships. `git diff` compares the working directory to the staging area. `git diff --staged` compares the staging area to the last commit, showing exactly what will be captured in the next commit. `git show <hash>` inspects any specific commit's details and diff. In diff output, lines starting with `+` were added and lines starting with `-` were removed.

In Lesson 6, you will learn about branches: what they really are at the data level, why creating a branch in Git is nearly instant, and how branches enable multiple lines of development to exist in parallel without interfering with each other.