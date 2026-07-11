## 1. Before You Begin

Two common workflow interruptions that basic Git commands do not handle smoothly arise regularly in real development. The first: you are midway through building a feature when an urgent bug report comes in. You need to switch branches immediately, but you have uncommitted changes scattered across several files that are not ready to be committed. **Stashing** saves your entire working directory state temporarily without creating a commit, giving you a clean slate to switch branches and handle the emergency. The second: you made a commit on the wrong branch, or a bug fix you applied to a feature branch needs to go directly into `main` without waiting for the entire feature. **Cherry-picking** copies one specific commit from any branch onto your current branch.

This lesson teaches `git stash` for temporarily shelving in-progress work and `git cherry-pick` for copying individual commits between branches. Both are tools for real situations that arise in any active development workflow.

### What You'll Build

You will simulate an emergency interruption scenario: start working on a gallery feature, stash it, apply an urgent bug fix on `main`, push the fix, and then return to the gallery feature with the stash restored. You will also practice cherry-picking by copying an isolated bug fix commit from a feature branch to `main`.

### What You'll Learn

- ✅ `git stash` to save uncommitted changes temporarily
- ✅ `git stash pop` to restore stashed changes
- ✅ `git stash list` to see all saved stashes
- ✅ `git cherry-pick <hash>` to copy a specific commit to the current branch
- ✅ When to use stash vs commit
- ✅ When to use cherry-pick vs merge

### What You'll Need

- Lesson 14 completed

---

## 2. Git Stash

Stash is a temporary holding area outside the normal commit workflow. When you stash, Git records the current state of your working directory and staging area, then resets both to match the last commit. The saved state goes onto a stack of stashes that you can restore at any time from any branch.

### Step 1: Create the Interruption Scenario

Start working on a gallery feature.

```bash
git switch -c feature/gallery
```

Open `index.html` and add a gallery section after the skills section.

```html
<section>
    <h2>Photo Gallery</h2>
    <p>Coming soon...</p>
</section>
```

Save the file but do not run `git add` or `git commit`. The change is in the working directory only. Confirm with `git status`.

```bash
git status
```

You should see `index.html` listed as modified but not staged. Now imagine an urgent bug report arrives: a broken navigation link on the live site needs an immediate fix. You need to be on `main` to apply the fix, but the gallery section you are working on is half-built and not commit-ready.

### Step 2: Stash the In-Progress Changes

Save the working directory state to the stash stack.

```bash
git stash
```

You should see: `Saved working directory and index state WIP on feature/gallery: abc1234 Last commit message`. The stash command captured everything from the working directory and staging area, reset both to match the last commit, and stored the saved state. Run `git status` to confirm.

```bash
git status
```

The output shows "nothing to commit, working tree clean." Open `index.html` and verify the gallery section is no longer there. The changes are safely stored - they have not been lost, just temporarily removed from view. You can now switch branches freely.

### Step 3: Apply the Urgent Bug Fix

Switch to `main`, apply the fix, commit, and push.

```bash
git switch main
```

Open `index.html` and correct the navigation link (for example, change `<a href="projets.html">` to `<a href="projects.html">`). Save the file, stage, commit, and push.

```bash
git add index.html
git commit -m "Fix broken navigation link to projects page"
git push
```

The urgent fix is live. The emergency is resolved. Now return to the feature work.

### Step 4: Return to the Feature and Restore the Stash

Switch back to the feature branch and restore the stashed changes.

```bash
git switch feature/gallery
git stash pop
```

`git stash pop` takes the most recent stash from the top of the stack, applies it to the current working directory, and removes it from the stash list. Open `index.html` and verify the gallery section is back exactly as you left it.

```bash
git status
```

`index.html` should appear as modified again. The in-progress gallery section has been restored as if the interruption never happened. You can continue building the feature from exactly where you stopped.

---

## 3. Git Cherry-Pick

Cherry-picking copies the changes from one specific commit and applies them to the current branch as a new commit. The new commit has the same file changes as the original but a different hash, because its parent commit is different.

### Step 1: Create a Commit Worth Cherry-Picking

While still on the gallery feature branch, fix a typo in `about.html` as a separate, unrelated change.

```bash
git switch feature/gallery
```

Open `about.html` and correct a typo (for example, fix "Wellcome" to "Welcome" in the heading). Save the file, stage, and commit it.

```bash
git add about.html
git commit -m "Fix typo in about page heading"
```

This fix is on the `feature/gallery` branch. But it is an independent correction that `main` should have right now, not after the entire gallery feature is merged. Note the commit hash.

```bash
git log --oneline -1
```

The output shows the hash and message on one line. Copy the 7-character hash.

### Step 2: Cherry-Pick the Commit onto Main

Switch to `main` and apply just the typo fix.

```bash
git switch main
git cherry-pick d4e5f6a
```

Replace `d4e5f6a` with your actual hash from Step 1. You should see:

```
[main g7h8i9j] Fix typo in about page heading
 1 file changed, 1 insertion(+), 1 deletion(-)
```

The typo fix is now on `main` as a new commit `g7h8i9j` with a different hash than the original `d4e5f6a`. The original commit on `feature/gallery` is unchanged. Both branches now have the fix, applied independently from the same content changes.

---

## 4. Verify Stash and Cherry-Pick Results

Before moving on, confirm both operations produced the expected results.

### Step 1: Verify the Stash List is Empty

After using `git stash pop`, the stash entry is removed from the stack.

```bash
git stash list
```

If you used `pop`, the list should be empty. If you used `git stash apply` instead of `pop`, the stash entry remains in the list and must be cleaned up manually with `git stash drop`. The `pop` command is equivalent to `apply` followed by `drop` in one step, which is why it is the more common choice.

### Step 2: Verify the Cherry-Picked Commit on Main

Switch to `main` and inspect the recent history.

```bash
git switch main
git log --oneline -3
```

The cherry-picked commit should appear at the top with its new hash. Switch to the feature branch and confirm the original commit is still there with its original hash.

```bash
git switch feature/gallery
git log --oneline -3
```

Both branches now contain the same file change at the same location in `about.html`, but recorded as two distinct commits with different hashes and different parent pointers.

### Step 3: Practice Stashing Multiple Entries

Stash works as a stack where the most recently stashed item pops first. Practice the multi-stash behavior.

```bash
git switch main
```

Edit `index.html` slightly without staging or committing, then stash it.

```bash
git stash
```

Edit `style.css` slightly without staging or committing, then stash it.

```bash
git stash
git stash list
```

You should see two entries: `stash@{0}` (the most recent) and `stash@{1}` (the earlier one). Pop them in reverse order to restore each in sequence.

```bash
git stash pop
git stash pop
```

Last in, first out. Understanding the stack order prevents surprises when restoring from multiple stashes.

---

## 5. Fix the Errors in Your Code

These are the most common problems when using stash and cherry-pick.

**Error 1: `git stash pop` causes a conflict.**

If the branch changed since you stashed (for example, because you applied a fix on `main` and the stash also touched `main`), restoring the stash may conflict with the current branch state.

```bash
# Wrong: assuming stash pop always restores cleanly
git stash pop
# CONFLICT (content): Merge conflict in index.html
# The stash could not be applied cleanly.

# Correct: resolve the conflict markers, then drop the stash manually
# Open index.html, remove the conflict markers, write the correct content, save
git add index.html
git stash drop
```

After a stash conflict, the stash entry is NOT automatically removed even though the changes were partially applied. You must run `git stash drop` manually after resolving the conflict to remove the stash entry from the list.

**Error 2: Cherry-pick produces a conflict.**

When the target branch has changes that conflict with the commit being cherry-picked, Git pauses the cherry-pick in the same way as a merge conflict.

```bash
# Wrong: assuming cherry-pick always applies cleanly
git cherry-pick d4e5f6a
# CONFLICT (content): Merge conflict in about.html
# error: could not apply d4e5f6a...

# Correct option A: resolve the conflict and complete the cherry-pick
# Edit about.html, remove conflict markers, write correct content
git add about.html
git cherry-pick --continue

# Correct option B: abort if the cherry-pick is too complex
git cherry-pick --abort
```

`git cherry-pick --continue` (not `git commit`) is the correct command for finalizing a cherry-pick after resolving conflicts. Git already knows the commit message from the original commit and applies it to the new commit automatically.

**Error 3: Cherry-picking creates duplicate history.**

Cherry-pick creates a new copy of the commit with a new hash. When the feature branch is eventually merged into `main`, Git may apply the same file change twice if it does not recognize the cherry-picked version as equivalent.

```bash
# Wrong: cherry-picking frequently as a substitute for proper branching
git cherry-pick feature-branch-commit-1
git cherry-pick feature-branch-commit-2
git cherry-pick feature-branch-commit-3
# Later, merging the whole branch creates duplicates or unexpected conflicts

# Correct: use cherry-pick sparingly for truly isolated, urgent fixes
# For regular integration, use merge or rebase
git merge feature/branch
```

Cherry-pick should be used for targeted, isolated fixes - a single commit that contains one focused change that needs to be elsewhere. If you find yourself cherry-picking many commits regularly, the branching structure probably needs adjustment.

---

## 6. Exercises

**Exercise 1:** Stash three separate changes (make a change, stash, make another change, stash, and one more). Use `git stash list` to see all three. Pop them one by one and verify each restores the correct content.

**Exercise 2:** Cherry-pick two commits from the `feature/gallery` branch onto `main`. Verify both appear in `main`'s log with new hashes that differ from the originals on the feature branch.

**Exercise 3:** Try `git stash -m "gallery WIP: halfway through gallery section"` to add a descriptive message to your stash instead of the default "WIP" message. Run `git stash list` and observe how the description appears.

---

## 7. Solutions

**Solution for Exercise 1:**

Create three separate changes and stash each.

```bash
git switch main
```

Edit `index.html` slightly, then stash without committing.

```bash
git stash -m "index.html change 1"
```

Edit `style.css` slightly, then stash.

```bash
git stash -m "style.css change 2"
```

Edit `README.md` slightly, then stash.

```bash
git stash -m "README.md change 3"
git stash list
```

Three entries should appear, numbered `stash@{0}` through `stash@{2}`. Pop the most recent first.

```bash
git stash pop
git status
```

`README.md` should appear as modified. Pop the next.

```bash
git stash pop
git status
```

`style.css` should now also appear as modified. Pop the last.

```bash
git stash pop
git status
```

`index.html` joins the other two in the modified list. `git stash list` should now be empty.

**Solution for Exercise 2:**

Identify two commit hashes on the feature branch.

```bash
git switch feature/gallery
git log --oneline -5
```

Note two hash values from the output. Switch to `main` and cherry-pick each.

```bash
git switch main
git cherry-pick <hash1>
git cherry-pick <hash2>
git log --oneline -4
```

Both cherry-picked commits appear at the top of `main`'s log with new hash values. Switch back to `feature/gallery` and run `git log --oneline -5` to confirm the original commits are still there with their original hashes. The two branches now share the same file changes but recorded under different commit identities.

---

## 8. Understanding Stash and Cherry-Pick

Stash is fundamentally a clipboard for the working directory and staging area. The stash command "cuts" the current uncommitted changes (saving them to the stash stack) and restores the directory to the last committed state. The pop command "pastes" them back. Unlike commits, stashes are not part of any branch's history and are accessible from any branch. This makes stash the right tool for interruptions when you need to context-switch without creating an incomplete commit.

Cherry-pick is a targeted, surgical merge. Instead of merging an entire branch with all of its commits and its full history, you select one specific commit and apply its changes to the current branch. The resulting commit is new: it has a different hash because it has a different parent, but the line-level changes to the affected files are identical to the original commit.

Both tools should be used intentionally and occasionally, not as a routine workflow. If you stash constantly, it may be a sign that you should commit work-in-progress with a "WIP" prefix and amend or squash it later (Lesson 16 covers this). If you cherry-pick frequently, the work that needs to be shared across branches probably belongs on its own shared branch that can be properly merged.

---

## Next Up - Lesson 16

`git stash` saves uncommitted changes temporarily, giving you a clean working directory to switch branches for emergencies. `git stash pop` restores the saved changes and removes the stash entry. `git stash list` shows all saved stashes on the stack, which operates last-in-first-out. `git cherry-pick <hash>` copies a specific commit to the current branch as a new commit with a new hash. Use stash for short-term interruptions and cherry-pick for copying truly isolated fixes that are urgently needed on a different branch. On conflicts: resolve markers, then `git add` and `git stash drop` for stash conflicts; resolve markers, then `git add` and `git cherry-pick --continue` for cherry-pick conflicts.

In Lesson 16, you will learn how to rewrite Git history: using `git commit --amend` to fix the last commit, `git rebase` to replay commits on a new base for a linear history, interactive rebase to squash multiple commits into one, and `git reset` to undo commits in three different modes.