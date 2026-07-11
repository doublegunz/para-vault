## 1. Before You Begin

You understand what branches are conceptually: movable pointers to commits that enable parallel lines of development. Now you will use them. This lesson covers the commands for creating branches, switching between them, listing all branches, and deleting branches you no longer need. You will create a feature branch for a contact page, build the feature on it, and observe firsthand how `main` stays completely unaffected by the work on your feature branch.

This lesson teaches the practical Git commands for branch management. You will create a branch, switch to it, make commits on it, switch back to `main` to verify it is unchanged, and then see the diverged history in the graph log. The pattern you practice here - create, commit, switch, compare - is the daily rhythm of professional Git usage.

### What You'll Build

You will create a `feature/contact` branch and build a complete contact page on it, with two commits: one for the page itself and one for updating the navigation on all existing pages. Meanwhile, `main` will remain unchanged, demonstrating branch isolation in action.

### What You'll Learn

- ✅ `git branch` to list branches
- ✅ `git branch <name>` to create a branch
- ✅ `git switch <name>` to switch branches
- ✅ `git switch -c <name>` to create and switch in one command
- ✅ How switching branches changes your working directory files
- ✅ `git branch -d <name>` to delete a branch

### What You'll Need

- Lesson 6 completed

---

## 2. Create and Switch to a Branch

Before creating any new branch, it is useful to see what branches already exist. Then you can create the feature branch and switch to it in a single command.

### Step 1: See the Current Branches

List all local branches to see the starting state.

```bash
git branch
```

You should see:

```
* main
```

The asterisk `*` marks the currently active branch. Right now, `main` is the only branch in the repository. Any commit you make at this point would go onto `main`.

### Step 2: Create and Switch to a New Branch

Create the feature branch and switch to it in one step using `git switch -c`.

```bash
git switch -c feature/contact
```

You should see: `Switched to a new branch 'feature/contact'`. The `-c` flag means "create" - it creates the branch and immediately moves `HEAD` to point at it. Without `-c`, `git switch` only switches to an existing branch; it does not create one. Verify the switch worked correctly.

```bash
git branch
```

You should see:

```
  main
* feature/contact
```

The asterisk has moved to `feature/contact`. Any commits you make now will be recorded on this branch. The `main` label will not move until you explicitly switch back to it and make a commit there.

---

## 3. Work on the Feature Branch

With the feature branch active, you can now build the contact page without any risk of affecting `main`. Even if you make breaking changes, `main` remains untouched until you deliberately merge.

### Step 1: Create the Contact Page

Create a new file called `contact.html` in the portfolio folder with the following content.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Contact Me</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
        <a href="contact.html">Contact</a>
    </nav>
    <h1>Contact Me</h1>
    <p>Email: budi@example.com</p>
    <p>GitHub: github.com/budi</p>
</body>
</html>
```

Save the file. This is a complete HTML page for the contact section of the portfolio. The navigation already includes the Contact link so the page connects to the rest of the site.

### Step 2: Stage and Commit the New Page

Stage the new file and record it as the first commit on this feature branch.

```bash
git add contact.html
git commit -m "Add contact page with email and GitHub link"
```

This commit happens on `feature/contact` only. `main` does not have it and will not have it until you merge in Lesson 8.

### Step 3: Update Navigation on Other Pages

The contact page has a Contact link in its own navigation, but the existing pages (`index.html` and `about.html`) do not yet link to it. Open both files and update their `<nav>` elements to include the Contact link.

```html
<nav>
    <a href="index.html">Home</a>
    <a href="about.html">About</a>
    <a href="contact.html">Contact</a>
</nav>
```

Save both files. Now stage and commit both changes as a single logical unit, because updating the navigation consistently across all pages is one change, not two.

```bash
git add index.html about.html
git commit -m "Add contact link to navigation on all pages"
```

The feature branch now has two commits that `main` does not have. The contact page feature is complete and self-contained on this branch.

---

## 4. Compare with Main

The most convincing demonstration of branch isolation is switching back to `main` and observing that the files you just created are gone. This is not data loss - it is Git restoring the working directory to match `main`'s snapshot.

Switch back to `main` and observe the result.

```bash
git switch main
```

You should see: `Switched to branch 'main'`. Now examine the folder contents.

```bash
ls
```

The `contact.html` file has disappeared from the directory listing. Open `index.html` in your text editor and the Contact link is not in the navigation. This is Git in action: when you switch branches, Git replaces the files in your working directory with the exact snapshot stored in that branch's latest commit. The `main` branch snapshot does not include the contact page or the updated navigation, so those files are not on disk.

Switch back to the feature branch to restore the contact page.

```bash
git switch feature/contact
ls
```

`contact.html` reappears. The navigation links in `index.html` and `about.html` are back. Git swapped the entire working directory seamlessly in both directions. This is the fundamental power of Git branching: completely isolated environments that share a common history.

---

## 5. View the Branch History

With two branches that have diverged from a common point, the graph log becomes meaningful. It shows exactly where the branches split.

```bash
git log --oneline --graph --all
```

You should see something like:

```
* e5f6a7b (HEAD -> feature/contact) Add contact link to navigation on all pages
* d4e5f6a Add contact page with email and GitHub link
* c3d4e5f (main) Add second paragraph to homepage
* b2c3d4e Add about page
* a1b2c3d Add navigation bar and link stylesheet
```

`feature/contact` is ahead of `main` by two commits. `main` is still pointing at "Add second paragraph to homepage." The two branches share commits up to `c3d4e5f` and then diverge: only `feature/contact` has the two newest commits. The `--all` flag ensures Git shows commits from every branch, not just the currently active one.

---

## 6. Delete a Branch

After merging a feature branch (which you will do in Lesson 8), you typically delete it to keep the branch list clean. Undeleted feature branches accumulate over time and make the list difficult to read.

The safe way to delete is with the lowercase `-d` flag, which checks that the branch has been fully merged before deleting it. Do not run this command yet - you will merge first in Lesson 8.

```bash
git switch main
git branch -d feature/contact
```

`git branch -d feature/contact` removes the branch label from the repository but does not delete any commits. The commits are still in the history and reachable from `main` after the merge. The `-d` flag refuses to delete the branch if its commits are not yet reachable from another branch, preventing accidental loss of unmerged work. To force-delete an unmerged branch, use `-D` (uppercase), but be certain the work can be discarded before using it.

**Do not delete the branch yet.** You will merge `feature/contact` into `main` in Lesson 8. This section is reference for when you are ready.

---

## 7. Verify Branch Behavior

Before moving on to Lesson 8, verify that the branch setup is correct and run through the file-swapping behavior one more time to build confidence.

### Step 1: Switch Back and Forth to See File Changes

Starting from the feature branch, switch to `main` and observe the contact page disappears, then switch back and confirm it returns.

```bash
git switch main
ls
```

Confirm `contact.html` is absent from the listing. Then switch back.

```bash
git switch feature/contact
ls
```

Confirm `contact.html` is present again. This back-and-forth demonstrates that branches are not just labels - they actively change what you see in the working directory.

### Step 2: Verify with git log

Check that the branch labels are on the correct commits.

```bash
git log --oneline --all --graph
```

Confirm that `main` and `feature/contact` point to different commits in the graph. The two-commit gap you made on the feature branch should be clearly visible.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes when creating and switching branches.

**Error 1: Uncommitted changes block switching.**

Git refuses to switch branches if you have uncommitted changes in the working directory that would be overwritten by the switch. This is a safety check to prevent losing work.

```bash
# Wrong: trying to switch with unsaved changes
git switch main
# error: Your local changes to the following files would be overwritten by checkout:
#         index.html
# Please commit your changes or stash them before you switch branches.

# Correct: commit your work first, then switch
git add index.html
git commit -m "Update navigation"
git switch main
```

If you are not ready to commit, you can temporarily save your changes with `git stash` (covered in Lesson 15) and restore them after switching back.

**Error 2: Branch name already exists.**

The `-c` flag creates a new branch. If a branch with that name already exists, Git refuses to create a duplicate.

```bash
# Wrong: using -c on an existing branch
git switch -c feature/contact
# fatal: a branch named 'feature/contact' already exists

# Correct: switch to the existing branch without -c
git switch feature/contact
```

If you genuinely need a second branch for the same feature, use a different name such as `feature/contact-v2` or `feature/contact-redesign`.

**Error 3: Trying to delete the currently active branch.**

Git does not allow you to delete the branch you are currently on. You must switch to a different branch first.

```bash
# Wrong: deleting the branch you are standing on
git branch -d feature/contact
# error: Cannot delete branch 'feature/contact' checked out at '/home/budi/portfolio'

# Correct: switch to another branch first, then delete
git switch main
git branch -d feature/contact
```

This restriction exists because deleting your current branch would leave `HEAD` pointing at nothing, which is an invalid state.

---

## 9. Exercises

**Exercise 1:** Create a branch called `feature/projects` and add a `projects.html` page. Make two commits on the branch: one to create the file and one to add content inside it. Switch back to `main` and verify that `projects.html` does not appear in the directory listing.

**Exercise 2:** With both `feature/projects` and `feature/contact` existing, run `git log --oneline --all --graph` and draw the resulting branch diagram on paper. Label which commits belong to which branch and identify the common ancestor.

**Exercise 3:** Create a branch called `experiment/dark-theme`. Change the `background-color` value in `style.css` to a dark color and commit. Switch back to `main` and open `style.css` to confirm the original background color has been restored.

---

## 10. Solutions

**Solution for Exercise 1:**

Create the branch and switch to it in one step.

```bash
git switch -c feature/projects
```

Create a `projects.html` file with basic HTML structure and save it. Commit the initial file.

```bash
git add projects.html
git commit -m "Add projects page"
```

Open the file and add a list of project names or descriptions. Save and commit the updated content.

```bash
git add projects.html
git commit -m "Add project list to projects page"
```

Switch back to `main` and verify the file is not visible.

```bash
git switch main
ls
```

`projects.html` should not appear in the listing. Git has restored the working directory to `main`'s snapshot, which does not include the projects page. The file still exists safely on the `feature/projects` branch.

**Solution for Exercise 3:**

Create the experiment branch and switch to it.

```bash
git switch -c experiment/dark-theme
```

Open `style.css` and change the `background-color` property on the `body` rule from `#f5f5f5` to a dark value such as `#1a1a2e`. Save the file and commit.

```bash
git add style.css
git commit -m "Switch to dark background theme"
```

Switch back to `main` and open `style.css`.

```bash
git switch main
```

The `background-color` value in `style.css` returns to `#f5f5f5`. Git replaced the working directory files with `main`'s snapshot, which does not have the dark theme change. The dark theme commit remains safely on `experiment/dark-theme` and can be merged or discarded later.

---

## 11. Understanding Branch Workflow

The typical branch workflow follows four steps: create, work, merge, delete. You create a branch for a specific purpose. You work on it with one or more commits. You merge it back into `main` when it is ready and tested. You delete the branch because its work is now part of `main` and the label is no longer needed.

This workflow keeps `main` stable. At any point, the `main` branch should contain working, tested code. Feature branches contain work-in-progress that might be incomplete or broken. The separation means that a team of twenty developers can each be working on their own branch simultaneously, none of them affecting each other until they are ready to merge.

The naming convention `feature/`, `fix/`, `experiment/` is not enforced by Git. Git does not interpret the `/` as anything special. But it is a widespread industry convention because it creates visual grouping in the branch list and immediately communicates the purpose of each branch to anyone reading it.

---

## Next Up - Lesson 8

`git branch` lists all branches with an asterisk on the current one. `git switch -c <name>` creates a new branch and switches to it in one command. `git switch <name>` switches to an existing branch, updating the working directory to match that branch's snapshot. Commits on a feature branch do not affect other branches. `git branch -d <name>` deletes a merged branch safely. Use `git log --oneline --all --graph` to visualize the diverging branch structure.

In Lesson 8, you will merge the `feature/contact` branch into `main`, learn the difference between fast-forward and three-way merges, and use `git log --graph` to see the resulting history.