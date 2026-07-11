## 1. Before You Begin

In a team environment, developers do not push changes directly to `main`. Instead, they create a feature branch, push it to GitHub, and open a **pull request** (PR). A pull request is a formal proposal: "I made these changes on this branch. Please review and merge them into main." Teammates review the code, leave comments, suggest improvements, and either approve or request changes. Only after approval are the changes merged into `main`. This process catches bugs before they reach production, shares knowledge across the team, and creates a documented record of why each change was made.

This lesson covers creating pull requests on GitHub, participating in the review process, merging PRs, and understanding the three merge strategies GitHub offers. You will go through the complete PR lifecycle using the portfolio project.

### What You'll Build

You will create a `feature/projects-page` branch, build a projects page on it, push the branch to GitHub, open a PR with a descriptive write-up, merge it through the GitHub interface, and then sync the merged result back to your local machine.

### What You'll Learn

- ✅ Creating a feature branch and pushing it to GitHub
- ✅ Opening a pull request on GitHub with a clear description
- ✅ The review process: comments, approval, and requesting changes
- ✅ Merging a PR: merge commit, squash, and rebase options
- ✅ Deleting the branch after merge
- ✅ Pulling the merged changes back to your local repository

### What You'll Need

- Lesson 12 completed

---

## 2. Create a Feature Branch

The PR workflow always starts locally: create a branch, do the work, and commit. The branch is then pushed to GitHub, where it becomes the source of the pull request. Never commit the feature directly to `main` before opening the PR - the branch is what GitHub compares against `main` to produce the diff.

### Step 1: Create the Branch and Build the Feature

Navigate to the portfolio project folder, create the feature branch, and switch to it.

```bash
cd portfolio
git switch -c feature/projects-page
```

Create a new file `projects.html` with a page listing your portfolio projects.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Projects</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <nav>
        <a href="index.html">Home</a>
        <a href="about.html">About</a>
        <a href="projects.html">Projects</a>
        <a href="contact.html">Contact</a>
    </nav>
    <h1>My Projects</h1>
    <div>
        <h3>Portfolio Website</h3>
        <p>A personal website built while learning Git and GitHub.</p>
    </div>
    <div>
        <h3>To-Do App</h3>
        <p>A task management application built with JavaScript.</p>
    </div>
</body>
</html>
```

Save the file. Stage and commit it to the feature branch.

```bash
git add projects.html
git commit -m "Add projects page with portfolio and to-do app"
```

This commit is on `feature/projects-page` only. `main` does not have it, which is exactly the condition that makes the PR meaningful - the diff GitHub shows will be everything in this commit.

### Step 2: Push the Feature Branch to GitHub

Push the branch to GitHub so it becomes available for a pull request. This is the first time this branch name exists on the remote.

```bash
git push -u origin feature/projects-page
```

The `-u` flag sets up the tracking relationship between your local `feature/projects-page` and `origin/feature/projects-page` on GitHub. After this, future pushes to this branch (if you continue adding commits before merging) can use plain `git push`. GitHub now has both `main` and `feature/projects-page`, which is what the PR form needs to create the comparison.

---

## 3. Open a Pull Request

After pushing the feature branch, GitHub recognizes it as a new branch with recent activity and surfaces it in the repository interface. The PR creation form is where you explain what you changed and why.

### Step 1: Navigate to the PR Creation Form

Visit your repository on GitHub. You should see a yellow banner near the top: "feature/projects-page had recent pushes - Compare & pull request." Click the "Compare & pull request" button to open the PR form.

If the banner has disappeared (it expires after a few minutes), go to the "Pull requests" tab and click "New pull request." Set the base branch to `main` and the compare branch to `feature/projects-page`, then click "Create pull request."

### Step 2: Fill in the PR Details

The PR form has a title field and a description text area. Both matter for team communication. A well-written PR description helps reviewers understand the purpose, scope, and testing approach without having to read every line of code.

Fill in the title and description as follows.

**Title:** Add projects page

**Description:**

```
## What this PR does
Adds a projects page (`projects.html`) that lists portfolio projects.

## Changes
- Created `projects.html` with two project entries
- Each project has a title and description

## Testing
Open `projects.html` in a browser and verify the content displays correctly.
```

Click "Create pull request." The PR page now shows the commits included in this PR, a "Files changed" tab with the complete diff, and a conversation area where reviewers can leave comments.

---

## 4. Review and Merge

The review phase is where the code quality conversation happens. In a real team, you would wait for teammates to review before merging. In this solo practice, you will review your own PR and then merge it.

### Step 1: Review the Changes in the Files Tab

Click the "Files changed" tab on the PR page. This view shows every line that was added (highlighted green with a `+`) or removed (highlighted red with a `-`). Click on any line number to leave an inline comment on that specific line. This is how reviewers ask questions, flag potential bugs, or suggest alternative approaches.

Scan through the diff to verify the `projects.html` content is correct and the navigation links are present. In a team setting, you would leave an approval comment ("Looks good, ship it!") or request changes ("The heading structure should be updated for accessibility"). For now, proceed to merge.

### Step 2: Merge the Pull Request

Scroll down to the merge section at the bottom of the PR conversation view. GitHub offers three merge strategies in the "Merge pull request" dropdown.

**Create a merge commit** preserves the complete branch history by creating a merge commit with two parents, identical to what `git merge` does locally. Choose this option for now - it is the default and most transparent.

**Squash and merge** combines every commit on the feature branch into a single commit on `main`. Useful when the branch has many "WIP" or "fix typo" commits that clutter the history.

**Rebase and merge** replays each commit from the branch on top of the current tip of `main`, producing a linear history without a merge commit. Useful for teams that prefer a clean, straight-line history.

Click "Merge pull request," then "Confirm merge." The PR status changes to "Merged" and a purple badge appears, indicating the changes are now in `main` on GitHub.

### Step 3: Delete the Branch on GitHub

After merging, GitHub shows a "Delete branch" button directly on the PR page. Click it. The branch served its purpose, its commits are now in `main`, and keeping the label around creates unnecessary noise in the branch list. GitHub also keeps the PR page permanently - you can always return to the closed PR to see the full conversation and diff even after the branch is deleted.

---

## 5. Update Your Local Repository

After merging on GitHub, your local `main` does not automatically update. You need to pull the merged changes down from the remote. This is a mandatory step after every PR merge - skipping it means the next `git push` will fail with a rejected error because the remote is ahead.

### Step 1: Switch to Main and Pull

Switch to your local `main` branch and pull the merged changes.

```bash
git switch main
git pull
```

`git pull` downloads the merge commit from GitHub and fast-forwards your local `main` to include it. Running `git log --oneline` immediately after will show the merge commit at the top with `(HEAD -> main, origin/main)`, confirming that local and remote are synchronized.

### Step 2: Delete the Local Feature Branch

The feature branch is merged and no longer needed locally either.

```bash
git branch -d feature/projects-page
```

`git branch -d` succeeds here because the feature branch commits are now reachable from `main` through the merge commit. The `-d` flag is the safe version that only deletes merged branches. Nothing is lost.

### Step 3: Verify the Result

Confirm the project file is now present on `main` and the history reflects the merge.

```bash
git log --oneline --graph
ls
```

`projects.html` should appear in the file listing. `git log --oneline --graph` should show the merge commit at the top with two converging lines below it, one for the feature branch commits and one for `main`'s line before the merge.

---

## 6. Review the PR Record on GitHub

A merged PR creates a permanent record that is valuable even after the branch and the project itself have moved on. Visit the PR page to see this record.

### Step 1: Find the Closed PR

On your GitHub repository page, click the "Pull requests" tab and then click "Closed" to switch from open to closed PRs. Click the PR you just merged to open the full page.

### Step 2: Read the Permanent Record

The PR page shows the entire history of the change: the description you wrote, every commit included, every file diff, and the merge event with a timestamp. This is why PR descriptions matter - the description you wrote explains the "why" of the change in a way that the commit message and diff alone cannot. When someone looks at this code six months later and asks "why does this page exist?", the PR record provides the complete context.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes in the pull request workflow.

**Error 1: PR targets the wrong base branch.**

The "base" branch is where your changes will be merged into. If it is set to a branch other than `main` (for example, another feature branch), the PR will miss the intended target.

```bash
# Wrong: PR base branch set to 'feature/other-branch' instead of 'main'
# (no terminal command - this is set in the GitHub UI when creating the PR)
# The PR merges your branch into the wrong target

# Correct: check the base dropdown before clicking "Create pull request"
# Base: main        (the branch you want to merge INTO)
# Compare: feature/projects-page   (the branch with your changes)
```

If you already created the PR with the wrong base, GitHub allows you to edit the base branch from the PR page: click "Edit" next to the title or use the base branch dropdown. Change it to `main` and the diff will update accordingly.

**Error 2: The PR shows conflicts that cannot be automatically merged.**

When `main` has received new commits since you created your feature branch, the two branches may have conflicting changes. GitHub shows a "This branch has conflicts that must be resolved" warning, and the merge button is disabled.

```bash
# Wrong: trying to merge on GitHub when conflicts exist
# The "Merge pull request" button is greyed out, and GitHub shows conflict warnings.

# Correct: resolve the conflict locally by merging main into the feature branch
git switch feature/projects-page
git merge main
```

Resolve the conflict markers in any affected files, then stage and commit the resolution.

```bash
git add index.html
git commit -m "Merge main into feature/projects-page: resolve nav conflict"
git push
```

After pushing, GitHub re-evaluates the PR. If the conflict is resolved, the merge button becomes available again.

**Error 3: Forgetting to pull after merging the PR.**

After clicking "Confirm merge" on GitHub, the remote `main` has the new merge commit. Your local `main` does not. This causes the next push to fail with a rejected error.

```bash
# Wrong: continuing to work and push without pulling after a PR merge
git add style.css
git commit -m "Add new styles"
git push
# ! [rejected] main -> main (non-fast-forward)

# Correct: always pull main immediately after merging a PR
git switch main
git pull
# Now local main includes the merge commit
# Continue working from this updated state
```

Make pulling `main` after every PR merge a non-negotiable habit. It takes five seconds and prevents a confusing rejected push situation every time.

---

## 8. Exercises

**Exercise 1:** Create another feature branch called `feature/skills-page`. Add a `skills.html` page with a list of technical and soft skills. Commit and push the branch. Open a PR with a clear title and a short description following the template from this lesson. Merge the PR and pull the result locally.

**Exercise 2:** On the PR you created in Exercise 1, navigate to "Files changed" before merging. Click on a specific line of `skills.html` and leave a review comment on that line. Then submit the review and merge the PR. Read the final conversation on the closed PR page to see how comments appear in context.

**Exercise 3:** Create a branch with two commits: one that adds a file and one that updates an existing file. Open a PR, choose "Squash and merge," and merge it. Check `git log --oneline` on `main` after pulling and confirm that the two commits appear as a single combined commit instead of two separate entries.

---

## 9. Solutions

**Solution for Exercise 1:**

Create the feature branch and add the skills page.

```bash
git switch -c feature/skills-page
```

Create `skills.html` with a heading and two lists - one for technical skills and one for soft skills. Save the file, stage, and commit.

```bash
git add skills.html
git commit -m "Add skills page with technical and soft skills"
git push -u origin feature/skills-page
```

Visit GitHub and click "Compare & pull request." Fill in the PR with:

- Title: "Add skills page"
- Description: what the page contains, what changed, and how to test it.

Click "Create pull request." Verify the "Files changed" tab shows `skills.html` as a new file with all lines marked as additions. Click "Merge pull request," "Confirm merge," delete the branch on GitHub, then pull locally.

```bash
git switch main
git pull
git branch -d feature/skills-page
git log --oneline
```

The merge commit should be visible at the top and `skills.html` should appear when you run `ls`.

**Solution for Exercise 3:**

Create the branch and make two separate commits.

```bash
git switch -c feature/two-commits
```

Create a new file, save, and commit it.

```bash
git add new-page.html
git commit -m "Add new empty page"
```

Edit an existing file and commit the change.

```bash
git add index.html
git commit -m "Add link to new page in navigation"
git push -u origin feature/two-commits
```

Open a PR on GitHub. In the PR merge dropdown, select "Squash and merge" instead of "Create a merge commit." Confirm the merge and delete the branch on GitHub. Pull locally.

```bash
git switch main
git pull
git log --oneline
```

Instead of two separate commits ("Add new empty page" and "Add link to new page in navigation"), the log shows a single combined commit. GitHub's squash merge combines the commit messages into one and creates a single commit on `main`. This is the intended behavior for keeping the `main` history clean when a feature branch contains many small, incremental commits.

---

## 10. Understanding Pull Requests

A pull request is not a Git feature. It is a feature built by GitHub (and similarly by GitLab and Bitbucket) on top of Git's branching capability. Technically, a PR is a request to run the equivalent of `git merge feature/branch` on the server, but wrapped in a review interface. Git itself handles the merge; GitHub handles the conversation, approval gates, and automation triggers around it.

The PR process serves three distinct purposes. Code review catches bugs, enforces standards, and ensures that more than one person understands each change. Documentation creates a permanent, searchable record of why each change was made, written at the moment the change was freshest in the author's mind. Quality gating allows automated tests (CI/CD) to run against the branch before merging, preventing failures from reaching `main`.

The three merge strategies affect the shape of the history. Merge commits preserve the complete branching record - it is clear when a feature started, when it finished, and which commits belonged to it. Squash merges produce a cleaner `main` history at the cost of losing the individual commit granularity from the branch. Rebase merges produce a linear history with no merge commits at all, but they rewrite commit hashes, which can cause issues in shared branches. Most teams pick one strategy and apply it consistently so the history has a predictable shape.

---

## Next Up - Lesson 14

Pull requests are the standard mechanism for proposing and reviewing changes on GitHub. The workflow is: create a feature branch locally, push it to GitHub with `git push -u origin <branch>`, open a PR with a clear title and description, get reviews and approval, merge using the appropriate strategy (merge commit, squash, or rebase), delete the branch on GitHub, and pull the result to your local `main`. PRs provide code review, documentation, and quality gating. Always pull immediately after merging a PR to keep your local `main` synchronized.

In Lesson 14, you will learn branch strategies and Gitflow: the professional workflows that teams use to organize their branches, coordinate releases, and manage hotfixes in a structured and predictable way.