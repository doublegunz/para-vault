## 1. Before You Begin

Merge conflicts are not errors. They are Git asking for your help with a decision it cannot make on its own. When two branches modify the same lines in the same file, Git cannot determine which version you want to keep. Rather than silently choosing one and discarding the other, Git pauses the merge, marks the conflicting sections with special markers, and waits for you to resolve each one manually. Every developer encounters conflicts regularly, and knowing how to resolve them calmly and correctly is an essential production skill.

This lesson teaches you to create a conflict intentionally so you can practice in a controlled environment, read the conflict markers to understand what each branch contributed, resolve the conflict by editing the file to the desired final state, and complete the merge. You will also learn to abort a merge entirely if you need to step back and start over.

### What You'll Build

You will create a deliberate conflict by editing the same heading line on two different branches, then resolve it by combining elements from both versions into a single final heading. By the end, the merge will be complete and the repository history will show the merge commit.

### What You'll Learn

- ✅ What causes merge conflicts and why Git pauses
- ✅ Reading conflict markers: `<<<<<<<`, `=======`, `>>>>>>>`
- ✅ Resolving conflicts by manually editing the file
- ✅ Completing the merge with `git add` and `git commit`
- ✅ Aborting a merge with `git merge --abort`
- ✅ VS Code's visual conflict resolution interface

### What You'll Need

- Lesson 8 completed

---

## 2. Create a Conflict Intentionally

The best way to learn conflict resolution is to practice it in a situation you control. This section deliberately creates a conflict so you know exactly what caused it and can focus on the resolution process without stress.

### Step 1: Create a Branch and Change a Line

Create a new branch for an updated hero heading and switch to it immediately.

```bash
git switch -c feature/hero-text
```

Open `index.html` and change the `<h1>` text to a personal introduction style.

```html
<h1>Hi, I'm Budi - Web Developer</h1>
```

Save the file. Now stage and commit this change on the feature branch.

```bash
git add index.html
git commit -m "Update hero heading with personal introduction"
```

The `feature/hero-text` branch now has one commit that changes the `<h1>` line in a specific way.

### Step 2: Switch to Main and Change the Same Line

Switch back to `main` and change the exact same `<h1>` line to something different.

```bash
git switch main
```

Open `index.html` and change the same `<h1>` line to a portfolio branding style.

```html
<h1>Welcome to Budi's Portfolio</h1>
```

Save the file. Stage and commit this change on `main`.

```bash
git add index.html
git commit -m "Update hero heading with portfolio branding"
```

Both branches have now changed the same line in different ways. `main` has one version of the heading. `feature/hero-text` has a different version of the same heading. Git has no way to know which version you prefer, or how to combine them.

### Step 3: Attempt the Merge

With `main` checked out, merge the feature branch to trigger the conflict.

```bash
git merge feature/hero-text
```

You should see:

```
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
```

Git tried to merge automatically but could not resolve the `<h1>` line because both branches changed it differently. The merge is now paused in an unfinished state. The conflicting file has been modified to include both versions with markers separating them. Running `git status` at this point would show `index.html` listed under "Unmerged paths."

---

## 3. Read the Conflict Markers

Open `index.html` in your editor. In the area where the conflict exists, Git has inserted special marker lines that divide the file into sections.

```
<<<<<<< HEAD
    <h1>Welcome to Budi's Portfolio</h1>
=======
    <h1>Hi, I'm Budi - Web Developer</h1>
>>>>>>> feature/hero-text
```

The three marker types each have a specific meaning. The `<<<<<<< HEAD` line opens the conflict block and marks the beginning of the version from the current branch (in this case, `main`). Everything between `<<<<<<< HEAD` and `=======` is what exists on `main`. The `=======` line separates the two competing versions. Everything between `=======` and `>>>>>>> feature/hero-text` is what exists on the incoming branch. The `>>>>>>> feature/hero-text` line closes the conflict block.

Everything in the file outside these marker blocks is not in conflict and will be preserved exactly as-is in the merge result.

---

## 4. Resolve the Conflict

Resolving a conflict means editing the file to contain the exact content you want in the final merged version. There is no special command for this - you simply open the file, decide what it should say, write that content, and remove every conflict marker line.

### Option A: Keep One Version

If you want to keep only the `main` version, delete everything except that line and the markers.

```html
    <h1>Welcome to Budi's Portfolio</h1>
```

If you want to keep only the `feature/hero-text` version instead, keep that line.

```html
    <h1>Hi, I'm Budi - Web Developer</h1>
```

In both cases, after choosing your line, make sure no marker lines (`<<<<<<<`, `=======`, `>>>>>>>`) remain anywhere in the file.

### Option B: Combine Both (Most Common)

Write a new version that incorporates ideas or wording from both branches.

```html
    <h1>Hi, I'm Budi - Welcome to My Portfolio</h1>
```

This option is the most common in real teams, where both changes represent valid intent and the best result is a synthesis of the two. Choose this option for practice. After writing the combined heading, verify that all three marker lines have been removed from the file and save it.

### Step 1: Stage the Resolved File

Tell Git that you have finished resolving the conflict in this file by staging it.

```bash
git add index.html
```

Staging a previously conflicted file signals to Git that the conflict in that file is resolved. If there were multiple conflicting files, you would need to resolve and stage each one before completing the merge.

### Step 2: Complete the Merge

Finalize the merge by creating the merge commit.

```bash
git commit -m "Merge feature/hero-text: combine hero heading styles"
```

You can provide a custom message with `-m` as shown, or omit `-m` to have Git open your editor with a pre-filled merge message that you can accept by saving and closing. Either approach produces a valid merge commit.

### Step 3: Verify the Completed Merge

Confirm the merge is fully complete and the repository is in a clean state.

```bash
git status
```

The output should show "nothing to commit, working tree clean." The merge is done. Now check the history.

```bash
git log --oneline --graph
```

The merge commit appears at the top with two parent lines converging below it, exactly like the three-way merge from Lesson 8. The difference is that this merge commit required manual conflict resolution before it could be created.

---

## 5. Aborting a Merge

Sometimes you start a merge, encounter conflicts, and realize you are not ready to resolve them right now. Perhaps the conflict is more complex than expected and you need to discuss the correct resolution with a teammate first. In those situations, you can abandon the entire merge and return to the state before you ran `git merge`.

```bash
git merge --abort
```

`git merge --abort` discards all conflict resolution progress, removes the conflict markers from every file, and restores the working directory and staging area to exactly the state they were in before the merge began. You can then try the merge again at any time when you are ready. This command only works while the merge is still in progress - before you run the final `git commit`.

---

## 6. VS Code Conflict Resolution

VS Code detects conflict markers automatically when you open a conflicted file and displays a visual interface above each conflict block. Four clickable options appear: "Accept Current Change" keeps the `HEAD` version and discards the incoming branch version. "Accept Incoming Change" keeps the incoming branch version and discards `HEAD`'s version. "Accept Both Changes" keeps both versions one after the other. "Compare Changes" opens a side-by-side diff view.

Clicking any of these options edits the file automatically, removing the three marker lines and keeping the selected content. VS Code also highlights conflicted files in the Source Control sidebar with a "C" indicator, making them easy to find in a large repository. After using VS Code to resolve conflicts, you still need to run `git add` on each resolved file and `git commit` to finalize the merge. VS Code automates the editing step, but the Git staging and committing steps remain your responsibility.

---

## 7. Verify and Clean Up

After completing the merge, verify the result is correct and clean up the no-longer-needed branch.

### Step 1: Verify the Resolved File

Open `index.html` in a browser. The heading should display whatever content you chose during resolution. If you see the text `<<<<<<<` or `=======` rendered visibly on the page, that means a conflict marker was left inside the HTML and was not removed before committing. In that case, edit the file to remove the remaining markers, stage, and commit a follow-up fix.

### Step 2: Verify the History

Run the graph log to confirm the merge appears correctly.

```bash
git log --oneline --graph --all
```

The merge commit should appear at the top with two parent lines converging below it. The commit message you wrote should be visible next to the merge commit's hash.

### Step 3: Delete the Merged Branch

The feature branch has done its job and can be removed.

```bash
git branch -d feature/hero-text
```

Because the branch commits are now reachable from `main` through the merge commit, the safe `-d` flag will succeed. The commits remain in the history - only the branch label is removed.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes when resolving merge conflicts.

**Error 1: Forgetting to remove all conflict markers before staging.**

If you stage and commit a file that still contains conflict marker lines, those markers become permanent content in the file. In an HTML file, they will appear as raw text visible in the browser.

```html
<!-- Wrong: markers left in the file -->
<<<<<<< HEAD
    <h1>Welcome to Budi's Portfolio</h1>
=======
    <h1>Hi, I'm Budi - Web Developer</h1>
>>>>>>> feature/hero-text

<!-- Correct: only the chosen content remains, no markers -->
    <h1>Hi, I'm Budi - Welcome to My Portfolio</h1>
```

Before staging a resolved file, always open it in a browser or preview to confirm no markers are visible. Many editors also provide a search function - searching for `<<<<<<<` in the file is a reliable way to catch any remaining markers.

**Error 2: Trying to commit while conflicts still exist.**

Git refuses to accept a commit while any file in the repository still has unresolved conflicts. This prevents accidentally recording a broken state.

```bash
# Wrong: committing without resolving all conflicts
git commit -m "Merge"
# error: Committing is not possible because you have unmerged paths.
# hint: Fix them up in the work tree, and then use 'git add/rm <file>'

# Correct: resolve each conflicted file, stage it, then commit
git add index.html
git commit -m "Merge feature/hero-text: combine hero heading styles"
```

Run `git status` to see which files are still listed under "Unmerged paths." Each one needs to be opened, conflict markers removed, and then staged with `git add` before the merge can be committed.

**Error 3: Deleting the conflicted file in frustration.**

When a conflict is confusing, it can be tempting to delete the file and start fresh. But deleting a conflicted file does not resolve the conflict in Git's view - it simply removes the file from both branches' versions, which is usually not the intended outcome.

```bash
# Wrong: deleting the conflicted file
rm index.html
git status
# You still have unmerged paths. Stage the deletion to mark it resolved.

# Correct option A: abort the merge and start fresh
git merge --abort

# Correct option B: restore the file from the merge state and resolve properly
git restore index.html
```

`git merge --abort` is always the safest escape route. It returns the repository to a clean pre-merge state so you can try again when ready.

---

## 9. Exercises

**Exercise 1:** Create a new branch called `feature/bg-color`. Change the `background-color` value in `style.css` from `#f5f5f5` to `#dbeafe` (light blue). Commit. Switch to `main` and change the same `background-color` to `#fef9c3` (light yellow). Commit. Merge `feature/bg-color` into `main`. When the conflict appears, resolve it by choosing a third color (`#f0fdf4`, a light green). Verify the final color in the browser.

**Exercise 2:** Create a conflict, read the markers carefully, then run `git merge --abort`. Verify with `git status` that the working directory returned to its pre-merge state and no conflict markers remain in any file.

**Exercise 3:** Create a conflict with two separate conflicting sections in the same file: change the `<h1>` on one branch and change the `<p>` text on the other branch in the same file. Attempt a merge. Read both conflict blocks, resolve each one independently, then complete the merge in a single `git commit`.

---

## 10. Solutions

**Solution for Exercise 1:**

Create the branch and make the first color change.

```bash
git switch -c feature/bg-color
```

Open `style.css` and change `background-color: #f5f5f5;` to `background-color: #dbeafe;`. Save and commit.

```bash
git add style.css
git commit -m "Change background to light blue"
```

Switch to `main` and make the competing change.

```bash
git switch main
```

Change the same `background-color` to `#fef9c3`. Save and commit.

```bash
git add style.css
git commit -m "Change background to light yellow"
```

Trigger the merge.

```bash
git merge feature/bg-color
```

Open `style.css`, find the conflict block in the `body` rule, and replace both versions and all markers with the resolution color:

```css
background-color: #f0fdf4;
```

Stage and complete the merge.

```bash
git add style.css
git commit -m "Merge feature/bg-color: resolve background color conflict"
```

Open the portfolio in a browser and confirm the background is the light green color you chose.

**Solution for Exercise 2:**

Create any conflict following the same two-branch, same-line pattern, then trigger the merge.

```bash
git merge feature/some-branch
```

After seeing the `CONFLICT` message, immediately abort.

```bash
git merge --abort
```

Check the status to confirm the working directory is clean.

```bash
git status
```

The output should say "nothing to commit, working tree clean" and `git log --oneline` should not show any new merge commit. Opening the conflicted file in an editor should reveal no `<<<<<<<` markers - the file is back to the state it was in before `git merge` was run.

---

## 11. Understanding Merge Conflicts

A conflict occurs when Git's merge algorithm finds that both branches modified the same lines, or adjacent lines, in the same file since they diverged. Changes to completely different files or to different non-adjacent sections of the same file are merged automatically without any conflict. This is why most merges in practice succeed without needing manual resolution.

The conflict markers are Git's way of presenting both versions side by side. The `HEAD` section shows what exists on the current branch. The other section shows what the incoming branch has. The `=======` separator divides them. Your task is to replace the entire block, including all three marker lines, with the single correct final version of that section.

Most conflicts in real teams are straightforward: one person changed a variable name and another changed the same variable's value, or one person added a line and another deleted it. The resolution is usually obvious once you understand what each branch was trying to accomplish. Occasionally, conflicts arise from architectural decisions, where two people rewrote the same function in different ways. In those cases, you may need to manually rewrite the section combining logic from both versions.

The key mindset is that conflicts are a normal, expected part of collaborative development. They happen in every active codebase. The resolution process is repeatable and mechanical: read the markers, understand what each branch intended, write the correct final state, remove the markers, stage, commit. With practice, resolving a typical conflict takes under two minutes.

---

## Next Up - Lesson 10

Merge conflicts happen when two branches modify the same lines in the same file. Git marks each conflict with `<<<<<<<` (current branch version), `=======` (separator), and `>>>>>>>` (incoming branch version). Resolving a conflict means editing the file to the desired final content and removing all marker lines. Stage each resolved file with `git add`, then complete the merge with `git commit`. If resolution becomes too complex, `git merge --abort` returns the repository to the pre-merge state. VS Code's visual interface simplifies the editing step but does not eliminate the need to stage and commit.

In Lesson 10, you will connect the portfolio project to GitHub: creating an account, setting up SSH authentication, creating a remote repository, and pushing your complete local history online for the first time.