## 1. Before You Begin

Sometimes the commit history is not clean. You notice a typo in a commit message immediately after committing. You committed a file you should not have included. Your feature branch has fifteen tiny "fix" and "WIP" commits that belong together as one clean commit, not as fifteen entries in the repository's permanent record. Git provides three tools for rewriting history: **amend** modifies the last commit in place, **rebase** replays a series of commits onto a new base point, and **reset** moves the branch pointer backward to a specified commit.

These tools are powerful but require care. The critical rule that governs all history rewriting: commits that have been pushed to a shared branch and pulled by teammates should never be rewritten. Rewriting rewrites the hashes, and different hashes for the same logical commit mean the local and remote histories have diverged in a way that produces confusing push failures and phantom merge conflicts.

This lesson covers three ways to rewrite history, each serving a different purpose with different safety implications. The golden rule is revisited explicitly so it can guide every decision you make with these tools.

### What You'll Build

You will practice amending a commit message and a forgotten file, rebasing a feature branch onto `main` to produce a linear history, using `git reset` in all three modes to observe what each preserves, and running an interactive rebase to squash three commits into one.

### What You'll Learn

- ✅ `git commit --amend` to modify the last commit's message or content
- ✅ `git rebase main` to replay branch commits on top of the current main
- ✅ `git reset` in soft, mixed, and hard modes
- ✅ Interactive rebase for squashing and reordering commits
- ✅ The golden rule: never rewrite history that has been pushed to a shared branch

### What You'll Need

- Lesson 15 completed

---

## 2. Amending the Last Commit

`git commit --amend` modifies the most recent commit by replacing it with a new commit that has the corrected content. It can fix the message, add a forgotten file, or both at once. The old commit is replaced immediately - it is as if the mistake never happened, as long as the commit has not been pushed.

### Step 1: Fix a Commit Message

Create a commit with a deliberate typo in the message.

```bash
echo "test line" >> README.md
git add README.md
git commit -m "Update READEM"
```

The message contains a typo. Fix it immediately with `--amend`.

```bash
git commit --amend -m "Update README"
```

Run `git log --oneline -1` before and after the amend to observe the change. The message is corrected. The hash also changed from whatever it was to a new value. This is expected and unavoidable: because the commit's content (including its message) changed, SHA-1 produces a completely different hash. The old hash no longer exists.

```bash
git log --oneline -1
```

Only one commit appears at the tip, with the corrected message and a new hash.

### Step 2: Add a Forgotten File

Commit something and then realize you forgot to include a related file.

```bash
git add README.md
git commit -m "Update README with setup instructions"
```

Immediately notice that `CONTRIBUTING.md` should have been included in the same commit. Create or edit the file, stage it, and amend without changing the message.

```bash
git add CONTRIBUTING.md
git commit --amend --no-edit
```

`--no-edit` tells Git to keep the existing commit message unchanged. The amended commit now contains both `README.md` and `CONTRIBUTING.md` as if both were staged in the original commit. Run `git show HEAD` to confirm both files are listed in the diff.

```bash
git show HEAD
```

Both files appear in the diff output of the single amended commit. The commit history has exactly the same number of entries as before the amend. Only the tip commit has changed.

**Important:** Amending changes the commit hash. If the commit was already pushed to a remote, the remote has the old hash and your local branch has the new one. Your next `git push` will be rejected because the histories have diverged. Only amend commits that have NOT been pushed to a shared branch.

---

## 3. Git Rebase

Rebase replays your branch's commits on top of another branch's latest commit. The effect is a linear history that looks as if the feature branch was created from the very latest commit on `main`, even when it was not. This makes the eventual merge a simple fast-forward with no merge commit needed.

### Step 1: Create a Diverged Scenario

Start from `main` and create a feature branch.

```bash
git switch main
git switch -c feature/footer-update
```

Edit `index.html` to add a footer element and commit.

```bash
git add index.html
git commit -m "Add footer to homepage"
```

Now switch back to `main` and simulate a teammate's commit arriving on `main` while you were working on the feature.

```bash
git switch main
```

Edit `style.css` to add a heading color rule and commit it to `main`.

```bash
git add style.css
git commit -m "Add heading color to stylesheet"
```

Both branches have now diverged. `feature/footer-update` has one commit that `main` does not have, and `main` has one commit that `feature/footer-update` does not have.

### Step 2: Rebase the Feature Branch onto Main

Switch to the feature branch and run `git rebase main`.

```bash
git switch feature/footer-update
git rebase main
```

Git performs the rebase in three stages. First, it identifies the common ancestor commit shared by both branches. Second, it temporarily removes the feature branch's commits. Third, it advances the feature branch's base to the tip of `main` and replays the removed commits one by one on top.

```
Before rebase:
main:    A---B---C
              \
feature:       D---E

After rebase:
main:    A---B---C
                  \
feature:           D'---E'
```

The commits D and E become D' and E' because their parent pointer changed. Their content changes are identical, but they are technically new commits with new hashes. Now when you merge the feature branch into `main`, Git can fast-forward because `main` is a direct ancestor of the rebased feature branch.

### Step 3: Merge with a Clean Fast-Forward

Switch to `main` and merge the rebased feature branch.

```bash
git switch main
git merge feature/footer-update
```

The merge produces "Fast-forward" in the output. No merge commit was created. `main`'s history is a clean straight line containing all commits from both branches in sequence.

```bash
git log --oneline --graph
```

The graph shows a straight vertical line with no diamond shapes, which is the visual result of rebase followed by fast-forward merge.

---

## 4. Git Reset

Reset moves the branch pointer backward to a specified commit. This effectively "undoes" the commits between the current tip and the target. The three modes control what happens to the changes that were recorded in those undone commits.

**Soft reset** moves the branch pointer back but preserves all the changes from the undone commits in the staging area, ready to be recommitted.

```bash
git reset --soft HEAD~1
```

After a soft reset, running `git status` shows the changes staged and waiting. You can commit them as-is, modify them first, or combine them with additional changes. This is useful when you want to restructure what went into the last commit without losing any work.

**Mixed reset** (the default when no flag is specified) moves the branch pointer back and unstages the changes, putting them back into the working directory as untracked modifications.

```bash
git reset HEAD~1
```

After a mixed reset, running `git status` shows the changes as modified but unstaged. The files are on disk and intact. You can re-stage them selectively, choosing which changes go into your next commit. This is the most common mode for reorganizing commits before pushing.

**Hard reset** moves the branch pointer back and discards all changes from the undone commits entirely. There is no staging area copy and no working directory copy.

```bash
git reset --hard HEAD~1
```

After a hard reset, running `git status` shows a clean working tree. The changes made in the undone commit are gone from your working directory. This is destructive and should be used with deliberate intent. The safety net is `git reflog`, described in Section 7.

`HEAD~1` means "one commit before HEAD." `HEAD~3` means three commits back. You can also use a specific commit hash instead of a relative reference.

---

## 5. Interactive Rebase

Interactive rebase opens your text editor with a list of commits and an action keyword next to each one. You can change the action to squash commits together, reorder them, edit their messages, or drop them entirely. This is the standard way to clean up a feature branch before opening a pull request.

```bash
git rebase -i HEAD~3
```

This opens an interactive session covering the last 3 commits. Your editor shows something like:

```
pick a1b2c3d Add gallery section
pick b2c3d4e Fix gallery typo
pick c3d4e5f Add gallery images
```

Each line has an action keyword followed by the hash and message. The available actions are listed in the comments at the bottom of the editor file. Change `pick` to `squash` (or `s`) on the commits you want to combine with the commit above them.

```
pick a1b2c3d Add gallery section
squash b2c3d4e Fix gallery typo
squash c3d4e5f Add gallery images
```

Save the file and close the editor. Git combines the three commits into one and opens the editor again to write a combined commit message. Replace the three individual messages with one clean, descriptive message.

```
Add photo gallery with images and typo corrections
```

Save and close. The result: three messy commits become a single clean commit on the branch's history. Run `git log --oneline` to confirm only one commit appears where there were three before.

---

## 6. Verify Each History Rewriting Tool

Before moving to the golden rule section, verify each tool produced the expected result.

### Step 1: Verify Amend

Create a commit with a deliberate mistake. Run `git log --oneline -1` to see the original hash and message. Amend with `--amend -m`. Run `git log --oneline -1` again. Confirm the message changed and the hash is different. Verify that the total number of commits in `git log` did not increase - amend replaces, it does not add.

### Step 2: Verify Reset Modes

Make two commits. Run `git log --oneline -2` to see them. Run `git reset --soft HEAD~1`. Check `git log` (one fewer commit), then `git status` (changes are staged). Run `git commit -m "Recommit"` to put them back. Run `git reset HEAD~1` (mixed). Check `git log` and `git status` (changes unstaged but on disk). Stage and recommit. Keep the two original commits for the next step.

### Step 3: Verify Interactive Rebase

Create three small commits (each adding one sentence to the `README.md`). Run `git rebase -i HEAD~3`. Squash the second and third into the first with the `squash` action. Write a unified message. Run `git log --oneline` and confirm three commits became one.

---

## 7. The Golden Rule

The golden rule of history rewriting must be stated clearly: **never rewrite commits that have been pushed to a branch other developers have pulled from.** When you amend, rebase, or hard-reset commits that exist on the remote, the remote retains the original hashes while your local branch has new ones. From Git's perspective, these are entirely different commits. The next developer who pulls gets both the original and the rewritten version, creating confusing duplicates and merge conflicts that are difficult to diagnose.

It is safe to rewrite history on branches that exist only on your local machine and have never been pushed. It is generally safe to rewrite your own feature branch if you are the only person working on it - but even then, coordinate with teammates first. If you must rewrite a branch that has already been pushed, use `git push --force-with-lease` (safer than `--force`) as it checks whether anyone else has pushed new commits to the branch since your last fetch, and refuses the force-push if they have.

The safety net for accidental history rewriting is `git reflog`. Every time `HEAD` moves - from a commit, reset, switch, cherry-pick, or rebase - Git records the previous position in the reflog. Even after a hard reset to `HEAD~5`, the "deleted" commits remain in the repository's object store for approximately 30 days before Git's garbage collector removes them. To recover after an accidental hard reset, run `git reflog` to find the hash of the state before the reset, then `git reset --hard <that-hash>` to return to it.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes when rewriting history.

**Error 1: Amending a commit that has already been pushed.**

After amending, the local and remote branch hashes diverge. The next `git push` is rejected because the remote has a commit the local no longer has.

```bash
# Wrong: amending and then expecting a normal push to work
git commit --amend -m "Fixed message"
git push
# ! [rejected] main -> main (non-fast-forward)
# hint: Updates were rejected because the tip of your current branch is behind its remote counterpart.

# Correct: use force-with-lease ONLY on your own personal feature branch
git push --force-with-lease
```

`--force-with-lease` is safer than `--force` because it rejects the force-push if the remote has commits you have not fetched yet, which prevents accidentally overwriting a teammate's push. Never use `--force` or `--force-with-lease` on `main` or `develop`.

**Error 2: Rebasing a shared branch.**

Rebasing `main` or `develop` rewrites every commit on that branch and force-pushes new hashes to the remote. Every developer who has pulled from that branch now has a local history that diverges from the rewritten remote history.

```bash
# Wrong: rebasing main onto another branch
git switch main
git rebase some-feature-branch
git push --force
# Now EVERYONE who has pulled main is out of sync.

# Correct: use merge on shared long-lived branches; rebase only on your own feature branches
git switch main
git merge some-feature-branch
```

Rebase is for personal feature branches that you alone are developing. Merge is for integrating changes between shared branches like `main`, `develop`, or `release/`.

**Error 3: Hard reset discards work unintentionally.**

Running `git reset --hard HEAD~5` removes five commits and all their file changes from the working directory. If you did not intend to lose that work, the recovery path is `git reflog`.

```bash
# Wrong: running hard reset by accident
git reset --hard HEAD~5
# 5 commits and all changes are gone from the working directory

# Correct: recover using git reflog
git reflog
# HEAD@{0}: reset: moving to HEAD~5   <- the reset you just ran
# HEAD@{1}: commit: Add gallery images  <- the state just before the reset
git reset --hard HEAD@{1}
# All five commits are restored
```

`git reflog` shows every position `HEAD` has occupied, in reverse chronological order. The entry immediately before the reset is the state you want to recover. Reset hard to that entry's reference and the working directory restores completely.

---

## 9. Exercises

**Exercise 1:** Create three commits with messages "WIP: start gallery", "WIP: add images", and "WIP: fix gallery layout". Use `git rebase -i HEAD~3` to squash all three into a single commit with the message "Add complete photo gallery section with images." Verify with `git log --oneline`.

**Exercise 2:** Make a commit. Use `git commit --amend` to add a file you forgot and fix the message at the same time (not using `--no-edit`). Verify with `git show HEAD` that the amended commit contains both files and has the corrected message.

**Exercise 3:** Make three separate commits. Run `git reset --soft HEAD~2`. Check `git status` (two commits now staged). Run `git reset HEAD~1` (mixed). Check `git status` (the staged commit is now unstaged). Run `git reset --hard HEAD~1`. Check `git status` (all changes gone). Verify with `git log --oneline` that you are back to the original single commit.

---

## 10. Solutions

**Solution for Exercise 1:**

Create the three WIP commits.

```bash
echo "gallery start" >> index.html
git add index.html
git commit -m "WIP: start gallery"

echo "gallery images" >> index.html
git add index.html
git commit -m "WIP: add images"

echo "gallery layout" >> index.html
git add index.html
git commit -m "WIP: fix gallery layout"
```

Begin the interactive rebase.

```bash
git rebase -i HEAD~3
```

Change the editor content so only the first commit uses `pick` and the second and third use `squash`.

```
pick <hash1> WIP: start gallery
squash <hash2> WIP: add images
squash <hash3> WIP: fix gallery layout
```

Save and close. Git opens a second editor for the combined commit message. Delete the individual WIP messages and write the unified message.

```
Add complete photo gallery section with images.
```

Save and close. Verify the result.

```bash
git log --oneline -3
```

The three WIP commits are gone. One clean commit with the unified message appears in their place.

**Solution for Exercise 3:**

Make an initial commit so you have something to return to, then add three more.

```bash
git add index.html && git commit -m "Base commit"
git add style.css && git commit -m "Commit A"
git add about.html && git commit -m "Commit B"
git add contact.html && git commit -m "Commit C"
```

Soft reset removes two commits (B and C) but keeps changes staged.

```bash
git reset --soft HEAD~2
git status
```

Changes from commits B and C appear under "Changes to be committed." Mixed reset (one step further back) unstages them.

```bash
git reset HEAD~1
git status
```

Changes from commits A, B, and C appear under "Changes not staged for commit." Hard reset discards all of them.

```bash
git reset --hard HEAD~1
git status
git log --oneline
```

The working directory is clean. Only the base commit remains. All files modified by commits A, B, and C have been restored to their pre-commit state.

---

## 11. Understanding History Rewriting

Rewriting history changes commit hashes. A commit's hash is a SHA-1 digest of its entire contents: the file snapshots, the author, the timestamp, the message, and the parent pointer. Changing any of these values produces a completely different hash. This is why `git commit --amend` produces a new hash (the message changed), and why `git rebase` produces new hashes for every replayed commit (the parent changed).

The immutability of hashes is what makes Git history trustworthy. When two developers have the same hash, they have exactly the same commit with exactly the same history leading up to it. When hashes diverge because of rewriting, Git cannot reconcile the two timelines without manual intervention, which is why rewriting shared history causes problems.

The reflog is the emergency recovery system for any accidental rewrite. Every operation that moves `HEAD` is recorded in the reflog, along with the previous hash. This means that even after a hard reset or a destructive rebase, the original commits remain in the object store for 30 days and can be restored by resetting to the reflog entry taken just before the destructive operation. The practical guideline: rewrite freely on local unpushed branches; treat shared branches as immutable.

---

## Next Up - Lesson 17

`git commit --amend` modifies the last commit by replacing it with a new one that has an updated message, updated content, or both. `git rebase main` replays the current branch's commits on top of `main`'s latest commit, producing a linear history that enables a clean fast-forward merge. `git reset --soft HEAD~N` moves the branch pointer back while keeping changes staged. `git reset HEAD~N` (mixed) moves the pointer back and unstages changes. `git reset --hard HEAD~N` moves the pointer back and discards all changes permanently. Interactive rebase (`git rebase -i HEAD~N`) lets you squash, reorder, or edit commits before a merge. The golden rule: never rewrite history that has been pushed to a branch other developers are using.

In Lesson 17, you will mark significant milestones with Git tags, publish versioned releases on GitHub, and configure `.gitignore` to prevent OS metadata, editor settings, and dependency files from entering the repository.