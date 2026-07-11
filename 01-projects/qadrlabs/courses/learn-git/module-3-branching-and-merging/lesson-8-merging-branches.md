## 1. Before You Begin

You have created feature branches and made commits on them. Now you need to integrate that work back into `main`. **Merging** takes the changes from one branch and combines them into another. There are two types of merges: fast-forward merges, which happen when the branches have not diverged, and three-way merges, which happen when both branches have made new commits since they split. Both types preserve the complete history and leave `main` in a state that contains the work from both lines of development.

This lesson covers merging feature branches into `main`. You will perform a fast-forward merge, then deliberately create a diverged scenario to trigger a three-way merge. You will learn to read merge output and use `git log --graph` to visualize the resulting history.

### What You'll Build

You will merge the `feature/contact` branch into `main`, then create a second feature branch and a diverged merge scenario, resulting in a `main` branch that contains the combined output of two parallel lines of development.

### What You'll Learn

- ✅ `git merge <branch>` to merge into the current branch
- ✅ Fast-forward merge: when `main` has no new commits
- ✅ Three-way merge: when both branches have new commits
- ✅ Merge commits: a commit with two parents
- ✅ `git log --graph` to see the merge history

### What You'll Need

- Lesson 7 completed with a `feature/contact` branch unmerged into `main`

---

## 2. Fast-Forward Merge

A fast-forward merge is the simplest type of merge. It happens when the target branch (`main`) has no new commits since the feature branch was created. Because the history is a straight line with no divergence, Git does not need to invent a new commit to combine anything. It simply moves the `main` pointer forward to the tip of the feature branch, as if `main` had been on that branch all along.

### Step 1: Switch to Main

Before merging, you must be on the branch you want to merge into. Switch to `main` so that `git merge` will bring the feature branch's commits into `main`.

```bash
git switch main
```

Running `git switch main` moves `HEAD` from wherever it was to point at `main`, and updates your working directory to match the snapshot at `main`'s latest commit. Always verify you are on the correct target branch before running a merge command.

### Step 2: Merge the Feature Branch

With `main` checked out, merge the feature branch into it.

```bash
git merge feature/contact
```

If `main` has had no new commits since you branched off it, Git performs a fast-forward and shows output like:

```
Updating c3d4e5f..e5f6a7b
Fast-forward
 contact.html | 18 ++++++++++++++++++
 index.html   |  1 +
 about.html   |  1 +
 3 files changed, 20 insertions(+)
 create mode 100644 contact.html
```

The "Fast-forward" label confirms that Git simply moved the `main` pointer forward to match the feature branch's latest commit. No new merge commit was needed because there was no divergence to reconcile - the history remained a single straight line.

### Step 3: Verify the Merged State

Confirm the files from the feature branch are now present in `main`.

```bash
ls
```

`contact.html` should appear in the listing. Open `index.html` in your text editor or browser to confirm the Contact link is present in the navigation. The feature branch's changes are now fully part of `main`.

Now inspect the visual log to see the fast-forward signature.

```bash
git log --oneline --graph
```

The graph shows a straight vertical line with both `main` and `feature/contact` pointing at the same commit. When two branch labels share the same commit, it is the visual signature of a completed fast-forward merge - no diamond shape, no merge commit, just a single clean timeline.

---

## 3. Three-Way Merge

A three-way merge happens when both the target branch and the source branch have made new commits since they diverged. Git cannot simply move a pointer because the two branches represent genuinely different histories. Instead, Git finds the common ancestor commit, examines what each branch changed relative to that ancestor, and combines those changes into a new "merge commit" that has two parents.

To practice this, you will create a diverged scenario deliberately.

### Step 1: Create and Commit on a New Feature Branch

Create a new feature branch for a footer section and switch to it immediately.

```bash
git switch -c feature/footer
```

`git switch -c` is the shorthand for creating a new branch and switching to it in a single step. Now edit `index.html` and add a footer element before the closing `</body>` tag.

```html
    <footer>
        <p>Copyright 2026 Budi Santoso</p>
    </footer>
</body>
```

Save the file and commit the change to the feature branch.

```bash
git add index.html
git commit -m "Add footer to homepage"
```

The `feature/footer` branch now has one commit that `main` does not have. This is the beginning of a diverged state.

### Step 2: Switch to Main and Make a Different Change

Switch back to `main` and make an unrelated change so that `main` also has a commit that `feature/footer` does not have.

```bash
git switch main
```

Edit `style.css` and add a heading style at the end of the file.

```css
h1 {
    color: #1e293b;
    border-bottom: 2px solid #2563eb;
    padding-bottom: 8px;
}
```

Save the file and commit it to `main`.

```bash
git add style.css
git commit -m "Add heading style to stylesheet"
```

`main` and `feature/footer` have now both moved forward from their shared common ancestor. The two branches have diverged. Neither branch contains the other's commit, which is exactly the condition that triggers a three-way merge.

### Step 3: Merge

With `main` checked out, merge the feature branch.

```bash
git merge feature/footer
```

Git detects that both branches have new commits and cannot fast-forward. It opens your configured text editor with a pre-filled merge commit message: "Merge branch 'feature/footer'". Accept the message by saving the file and closing the editor tab (in VS Code) or by saving and exiting (in Nano or another terminal editor).

You should see:

```
Merge made by the 'ort' strategy.
 index.html | 3 +++
 1 file changed, 3 insertions(+)
```

Git created a merge commit that pulls together the changes from both branches. The "ort" strategy is Git's default merge algorithm for three-way merges, designed to handle complex cases reliably.

### Step 4: Inspect the Graph

Visualize the merge with the graph log.

```bash
git log --oneline --graph
```

You should see a diamond-shaped graph:

```
*   f8a9b0c (HEAD -> main) Merge branch 'feature/footer'
|\
| * d7e8f9a (feature/footer) Add footer to homepage
* | e6f7a8b Add heading style to stylesheet
|/
* e5f6a7b Add contact link to navigation on all pages
```

The merge commit (`f8a9b0c`) is at the top, connected by lines to two parent commits: the heading style commit on `main` and the footer commit on the feature branch. The `|/` convergence shows where the two parallel lines of history joined into one. This diamond shape is the visual signature of a three-way merge.

---

## 4. Clean Up Merged Branches

After merging, the feature branch labels are no longer needed because their work is now part of `main`. Deleting them keeps the branch list clean and makes it clear which branches represent active, ongoing work.

```bash
git branch -d feature/contact
git branch -d feature/footer
```

`git branch -d` (lowercase d) is a safe delete: it only removes the branch label if Git confirms the branch's commits are already reachable from another branch (in this case, `main`). If the branch had unmerged commits, `-d` would refuse to delete it. The commits themselves are not removed - they remain in the history. Only the branch label file is deleted from `.git/refs/heads/`.

---

## 5. Verify the Complete Merge Result

Before moving on, confirm that both merges completed correctly and the repository is in the expected state.

### Step 1: Inspect the Merged Working Directory

Open `index.html` in a browser. You should see the heading with the blue underline style from `main`'s stylesheet change, and the footer section at the bottom from the `feature/footer` branch. Both changes exist in the same file, combined by the three-way merge.

### Step 2: View the Full History with Graph

Run the graph log including all branches to see the complete picture.

```bash
git log --oneline --graph --all
```

The graph should show the merge point where the two branches converged. Every commit from both branches is present in the final history. Nothing was lost.

### Step 3: Confirm Branch Cleanup

Verify that the repository now has only the branches you intend to keep.

```bash
git branch
```

Only `main` should appear in the list (plus any branches you created during exercises). The deleted feature branches no longer appear, confirming a clean workspace.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when merging branches.

**Error 1: Merging in the wrong direction.**

The branch you are on when you run `git merge` is the branch that receives the changes. If you are on `feature/footer` when you run `git merge main`, you merge `main` into `feature/footer`, not the other way around.

```bash
# Wrong: on the feature branch, merging main into it
git switch feature/footer
git merge main
# This brings main's changes INTO feature/footer, not into main.

# Correct: switch to the target branch first, then merge the source
git switch main
git merge feature/footer
# Now feature/footer's changes are merged INTO main.
```

The pattern to remember: "I am on the branch I want to update. I merge the branch that has the work I want to bring in." Always run `git branch` to confirm which branch you are on before executing a merge.

**Error 2: A merge conflict appears.**

When both branches have modified the same lines in the same file, Git cannot automatically determine which version to keep. This produces a conflict that requires manual resolution.

```bash
# Wrong: assuming all merges succeed automatically
git merge feature/footer
# CONFLICT (content): Merge conflict in index.html
# Automatic merge failed; fix conflicts and then commit the result.

# Correct: resolve the conflict manually, then complete the merge
# Open index.html, look for <<<<<< ======= >>>>>>> markers
# Edit the file to the correct final state
# Then:
git add index.html
git commit
```

Conflicts are normal and expected whenever two branches edit the same location. Lesson 9 covers conflict resolution in full detail, including how to read conflict markers and use editor tools to resolve them.

**Error 3: Trying to delete an unmerged branch.**

The safe `-d` flag refuses to delete a branch that has unmerged commits. This is a safety check, not an error.

```bash
# Wrong: using -d when the branch has unmerged work
git branch -d experiment/dark-theme
# error: The branch 'experiment/dark-theme' is not fully merged.
# If you are sure you want to delete it, run 'git branch -D experiment/dark-theme'.

# Correct option A: merge the branch before deleting
git switch main
git merge experiment/dark-theme
git branch -d experiment/dark-theme

# Correct option B: force-delete if you intentionally want to discard the work
git branch -D experiment/dark-theme
```

Use `-D` (uppercase) only when you are certain the work on that branch can be discarded permanently. The commits become unreachable and will eventually be cleaned up by Git's garbage collector.

---

## 7. Exercises

**Exercise 1:** Create a `feature/skills` branch from `main`. Add a `skills.html` page with a list of three skills. Commit the new file. Switch to `main`, add a footer style to `style.css`, and commit. Merge `feature/skills` into `main` (this will be a three-way merge since both branches have new commits). Delete the feature branch afterward.

**Exercise 2:** Run `git log --oneline --graph` after the Exercise 1 merge is complete. Identify the merge commit, its two parent commits, and the common ancestor commit. Describe what each of the three commits contains.

**Exercise 3:** Create a new branch `feature/experiment`, make two commits on it, switch to `main`, and then try to delete `feature/experiment` with `git branch -d`. Read the error message. Then delete it with `git branch -D`. Verify with `git branch` that it is gone.

---

## 8. Solutions

**Solution for Exercise 1:**

Create the feature branch and add the new page.

```bash
git switch -c feature/skills
```

Create `skills.html` with at least three skills listed in an HTML page, save it, then commit.

```bash
git add skills.html
git commit -m "Add skills page with technical skills list"
```

Switch to `main` and make a separate change to trigger a three-way merge.

```bash
git switch main
```

Open `style.css` and add a footer style, save, and commit.

```bash
git add style.css
git commit -m "Add footer style to stylesheet"
```

Now merge the feature branch into `main`. Git will open your editor for the merge commit message because a three-way merge is required.

```bash
git merge feature/skills
git branch -d feature/skills
git log --oneline --graph
```

The log should show the diamond-shaped merge graph with three commits visible: the merge commit at the top, the skills page commit on one line, the footer style commit on the other line, and the common ancestor below them.

**Solution for Exercise 2:**

In a typical `git log --oneline --graph` output after the Exercise 1 merge, the three relevant commits are:

- The merge commit at the top: contains both branches' changes combined and has two parents.
- The `feature/skills` parent: contains `skills.html` and whatever was staged on that branch.
- The `main` parent: contains the footer style added to `style.css`.
- The common ancestor (one step below the merge diamond): this is the commit where both branches shared the same history before they diverged.

The common ancestor is the baseline Git uses to determine what each branch changed. Anything added by one branch that is absent from the ancestor is brought into the merge automatically. Anything both branches changed in the same place produces a conflict.

---

## 9. Understanding Merging

Merging is how parallel work comes together in a shared history. Git's merge algorithm examines three commits: the common ancestor (the most recent commit that both branches share), the tip of the current branch, and the tip of the branch being merged. It compares both branch tips against the ancestor to determine what changed on each side.

If a file was changed on only one branch, Git takes that branch's version automatically. If a file was changed on both branches but in different locations, Git combines both sets of changes automatically. If a file was changed on both branches at the same lines, Git cannot decide which version is correct and marks a conflict for the developer to resolve manually. This distinction is important: most merges succeed automatically because parallel development naturally touches different files or different sections of the same file.

Fast-forward merges are the simplest outcome: the target branch has no new commits, so Git moves its pointer forward with no new commit needed. Three-way merges create a merge commit with two parent pointers, preserving the full branching history in the graph. The `--no-ff` flag forces a merge commit even when a fast-forward is possible, which some teams prefer because it makes every feature's integration explicitly visible in the graph.

---

## Next Up - Lesson 9

`git merge <branch>` combines changes from the named branch into your current branch. A fast-forward merge occurs when the target branch has no new commits and results in a simple pointer advancement with no new commit. A three-way merge occurs when both branches have diverged and results in a new merge commit with two parents. Always switch to the target branch before merging. Delete merged branches with `git branch -d` to keep the workspace clean. Use `git log --oneline --graph` to visualize how branches converge.

In Lesson 9, you will learn to resolve merge conflicts: what to do when both branches have edited the same lines, how to read Git's conflict markers, and how to complete the merge after resolving each conflict manually.