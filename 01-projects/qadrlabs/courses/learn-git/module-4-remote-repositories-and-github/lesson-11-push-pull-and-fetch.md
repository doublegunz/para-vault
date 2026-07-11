## 1. Before You Begin

Your local repository and GitHub are now connected, but they are not automatically synchronized. When you commit locally, GitHub does not know about it until you explicitly send the changes. When changes appear on GitHub (from a teammate or through the web interface), your local repository does not know until you explicitly download them. This lesson covers the three synchronization commands: `git push` sends local commits to the remote, `git pull` downloads remote commits and merges them into your current branch, and `git fetch` downloads remote commits without merging so you can inspect them first.

This lesson teaches the daily workflow of keeping local and remote repositories in sync. You will push new commits, make a change on GitHub directly to simulate a teammate's push, pull it to your local machine, and understand the practical difference between fetch and pull through hands-on practice.

### What You'll Build

You will practice the complete push-pull cycle by making changes both locally and on GitHub in the same lesson, then syncing them in both directions. By the end, you will have run all three sync commands and understand when to use each one.

### What You'll Learn

- ✅ `git push` to send local commits to GitHub
- ✅ `git pull` to download and merge remote commits
- ✅ `git fetch` to download without merging
- ✅ `origin/main` tracking branch and what it represents
- ✅ Handling rejected pushes when the remote has new commits

### What You'll Need

- Lesson 10 completed with portfolio pushed to GitHub

---

## 2. Push Local Changes

Pushing sends commits from your local branch to the corresponding branch on the remote repository. Any commits you made locally that GitHub does not yet have will be uploaded.

### Step 1: Make a Local Change

Open `index.html` and add a skills section below the existing paragraph content.

```html
<section>
    <h2>My Skills</h2>
    <ul>
        <li>HTML & CSS</li>
        <li>JavaScript</li>
        <li>Git & GitHub</li>
    </ul>
</section>
```

Save the file. Stage and commit the change.

```bash
git add index.html
git commit -m "Add skills section to homepage"
```

This commit exists only on your local machine. GitHub's copy of `main` does not have it yet. If you visit the repository on GitHub right now, the skills section will not be visible.

### Step 2: Push to GitHub

Send the local commit to GitHub.

```bash
git push
```

Since you already set the upstream tracking relationship with `-u` in Lesson 10, `git push` without any arguments knows to send local `main` to `origin/main`. You should see output showing the objects being transferred followed by a success message. Visit your GitHub repository to verify the new "Add skills section to homepage" commit appears in the commit history.

---

## 3. Pull Remote Changes

Pulling downloads commits from the remote branch and merges them into your current local branch. This is how you receive work that teammates have pushed, or changes you made directly through the GitHub web interface.

### Step 1: Make a Change on GitHub

Simulate a remote change by editing a file directly on GitHub. Go to your repository on GitHub, click on `README.md`, and click the pencil icon to open the editor. Add a line at the bottom: "Built while learning Git and GitHub." Click "Commit changes" and write a message like "Update README with course context."

This commit now exists on GitHub but not on your local machine. Your local `README.md` is behind by one commit.

### Step 2: Pull the Remote Change

Download and merge the remote commit into your local branch.

```bash
git pull
```

You should see output showing the download and merge:

```
Updating f8a9b0c..g9h0i1j
Fast-forward
 README.md | 1 +
 1 file changed, 1 insertion(+)
```

The "Fast-forward" message means your local `main` moved forward to include the new commit from GitHub. Git can fast-forward here because your local `main` had no new commits since the divergence point - the remote's commit simply extended the same straight line. Open `README.md` in your editor to confirm the new line is now present locally.

---

## 4. Fetch vs Pull

`git fetch` downloads new commits from the remote and updates the remote tracking branch (`origin/main`) but does not merge anything into your local working branch. This gives you time to inspect what changed before deciding to integrate it.

`git fetch` is useful when you want to see what your teammates have pushed before incorporating their changes, or when you are in the middle of your own work and do not want an automatic merge to disrupt your current state.

```bash
git fetch
```

After fetching, `origin/main` is updated to reflect GitHub's current state, but your local `main` has not changed. You can inspect what was downloaded before merging it.

```bash
git log --oneline main..origin/main
```

`main..origin/main` means "show commits that are in `origin/main` but not yet in `main`." This is a preview of what `git pull` would merge. If you decide you want to integrate those commits, merge them explicitly.

```bash
git merge origin/main
```

`git pull` is exactly equivalent to running `git fetch` and then `git merge origin/main` as two separate commands. Most developers use `git pull` for brevity in their daily workflow, but `git fetch` gives you a review step before the merge happens. During active collaboration, the fetch-then-inspect habit can prevent surprises.

---

## 5. Handling Rejected Pushes

A rejected push is one of the most common situations in collaborative Git work. It happens when the remote has commits that your local branch does not have yet. Git refuses the push to protect those remote commits from being overwritten.

```bash
git push
# ! [rejected]        main -> main (fetch first)
# error: failed to push some refs to 'git@github.com:...'
# hint: Updates were rejected because the remote contains work that you do not have locally.
```

This message is not an error in the sense of something broken. It is Git preventing a potentially destructive operation. The solution is to pull the remote commits first, which brings your local branch up to date, and then push your combined history.

```bash
git pull
git push
```

After `git pull`, your local branch contains both the remote commits and your own commits. Git may create a merge commit if the two lines diverged, or a fast-forward if they did not. After the pull succeeds, `git push` sends the complete history, including the remote commits it just downloaded. This ensures that no commits are lost.

Always pull before pushing at the start of a working session if you are on a shared branch where teammates may have pushed while you were away.

---

## 6. Verify the Sync State

After a push-pull session, it is good practice to confirm that the local and remote branches are fully synchronized before ending the session.

### Step 1: Check the Log for Sync Status

Run the compact log and look at the labels on the most recent commit.

```bash
git log --oneline
```

The most recent commit should show `(HEAD -> main, origin/main)`. Both labels on the same commit mean your local `main` and the remote `origin/main` are pointing at identical history. When they diverge, one label appears on a different commit than the other, which is your signal to push or pull.

### Step 2: Practice the Full Cycle

Make another local change, commit it, and push it. Then make another change directly on GitHub via the web editor, and pull it locally. Run `git log --oneline` after each action to watch the history grow from both sides. This builds the muscle memory of the push-pull rhythm.

### Step 3: Test the Fetch Workflow

Make a change on GitHub but do not pull it yet. Run `git fetch` to download it without merging. Run `git log --oneline main..origin/main` to see the fetched commit listed as pending. Then run `git merge origin/main` to apply it. Verify with `git log --oneline` that the commit is now in your local history.

---

## 7. Fix the Errors in Your Code

These are the most common problems when synchronizing local and remote repositories.

**Error 1: Push rejected because the remote is ahead.**

This happens whenever the remote has at least one commit that your local branch does not have. It frequently occurs when working with teammates or when you made a change via GitHub's web interface and forgot to pull.

```bash
# Wrong: pushing before pulling when remote has new commits
git push
# ! [rejected]        main -> main (fetch first)
# error: failed to push some refs

# Correct: pull first to integrate the remote commits, then push
git pull
git push
```

The `git pull` downloads the remote commits and merges them with yours. After the merge, `git push` succeeds because your local branch now contains everything the remote has, plus your new commits.

**Error 2: `git pull` produces a merge conflict.**

When you and a teammate both changed the same lines in the same file, pulling triggers a merge conflict instead of a clean fast-forward.

```bash
# Wrong: ignoring the conflict message and trying to push
git pull
# CONFLICT (content): Merge conflict in index.html
# Automatic merge failed; fix conflicts and then commit the result.
git push
# error: failed to push some refs (unresolved conflict)

# Correct: resolve the conflict using the same process from Lesson 9
# Edit index.html to remove conflict markers and write the correct content
git add index.html
git commit -m "Merge remote changes: resolve heading conflict"
git push
```

A conflict during `git pull` follows the exact same resolution process as a conflict from `git merge`. Open the conflicted file, remove the `<<<<<<<`, `=======`, and `>>>>>>>` markers, write the correct final content, stage the file, commit, and then push.

**Error 3: "There is no tracking information for the current branch."**

This happens when you push a branch without the `-u` flag on the first push, so Git never recorded the upstream tracking relationship.

```bash
# Wrong: pulling on a branch with no upstream set
git pull
# There is no tracking information for the current branch.
# Please specify which branch you want to merge with.

# Correct: either specify the remote explicitly for this pull
git pull origin main

# Or set the tracking relationship permanently
git branch --set-upstream-to=origin/main main
git pull
```

`git branch --set-upstream-to` stores the tracking relationship in `.git/config` permanently. After running it, plain `git push` and `git pull` work without arguments, the same as if you had used `-u` during the original push.

---

## 8. Exercises

**Exercise 1:** Make three separate local commits (each changing something different in the portfolio). Push all three at once with a single `git push`. Verify on GitHub that all three commits appear in the history, all pushed in one operation.

**Exercise 2:** Make two separate changes on GitHub using the web editor (two different commits, not just one). Pull both with a single `git pull`. Verify with `git log --oneline` that both commits are now in your local history.

**Exercise 3:** Make a change on GitHub but do not pull it. Run `git fetch`, then `git log --oneline main..origin/main` to list the pending commit. Inspect the commit with `git show origin/main`. Finally, merge with `git merge origin/main` and verify the merge succeeded.

---

## 9. Solutions

**Solution for Exercise 1:**

Make three changes to any three files (or the same file three times with different content) and commit each separately.

```bash
git add index.html
git commit -m "Add intro paragraph to homepage"

git add style.css
git commit -m "Add link hover color to stylesheet"

git add README.md
git commit -m "Add setup instructions to README"
```

Then push all three in one command.

```bash
git push
```

`git push` sends every local commit that GitHub does not yet have, regardless of how many there are. It is not limited to one commit per push. Visit GitHub and click "Commits" to confirm all three messages appear.

**Solution for Exercise 3:**

Make a change on GitHub via the web editor and commit it there. Without pulling, run fetch locally.

```bash
git fetch
git log --oneline main..origin/main
```

The pending commit should appear in the log. Inspect its content.

```bash
git show origin/main
```

`git show origin/main` displays the commit message, author, and diff of the most recent commit on the remote tracking branch. If the change looks correct, merge it.

```bash
git merge origin/main
git log --oneline
```

The merged commit now appears in your local history with `(HEAD -> main, origin/main)` on the same commit, confirming the local and remote are synchronized.

---

## 10. Understanding Push, Pull, and Fetch

The three sync commands reflect a simple mental model. `push` moves commits from your local branch to the remote. `pull` moves commits from the remote to your local branch and applies them immediately. `fetch` moves commits from the remote into the tracking reference (`origin/main`) without touching your local branch. Think of it this way: push is "send," pull is "receive and apply immediately," fetch is "receive but hold for inspection."

The tracking branch `origin/main` is a local reference that Git maintains as a mirror of where `main` is on GitHub. It updates whenever you run `git fetch` or `git pull`. After a `git fetch`, `origin/main` reflects GitHub's current state while your local `main` is unchanged. After a `git merge origin/main` (or `git pull`), your local `main` moves forward to match `origin/main`.

The rejected push situation is Git's safety mechanism for preventing history loss. If your push were allowed when the remote has unrecognized commits, those remote commits would be effectively overwritten and lost. By requiring you to pull first, Git ensures that every commit from every contributor is preserved in the final history before the combined result is pushed back.

---

## Next Up - Lesson 12

`git push` sends local commits to GitHub. `git pull` downloads remote commits and merges them into the current branch. `git fetch` downloads remote commits without merging, updating the `origin/main` tracking reference so you can inspect before integrating. When a push is rejected, the solution is always to pull first and then push. Check `git log --oneline` for the `(HEAD -> main, origin/main)` label to confirm that local and remote are fully in sync.

In Lesson 12, you will learn cloning and forking: how to download any public repository to your machine with `git clone`, how to create your own copy of any repository on GitHub with Fork, and when to use each approach in real collaboration scenarios.