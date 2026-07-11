## 1. Before You Begin

So far, you have worked only with a repository you created yourself. But a large part of Git's value comes from working with other people's code. **Cloning** downloads a complete copy of any public or accessible repository to your local machine, giving you every file, every commit, and every branch in a fully functional local repository. **Forking** is a GitHub feature that creates your own copy of someone else's repository under your GitHub account, which you can then clone, modify, and use as the basis for a pull request back to the original project.

These two operations are the standard starting point for contributing to any open-source project or joining an existing team project.

### What You'll Build

You will clone your own portfolio repository from a different directory to experience what a consumer of your repository would see. You will then fork a public repository on GitHub, clone the fork, and configure the `upstream` remote to keep the fork synchronized with the original.

### What You'll Learn

- ✅ `git clone <url>` to download a complete repository
- ✅ What clone gives you: full history, all branches, remote already configured
- ✅ Forking on GitHub: creating your own copy under your account
- ✅ When to use clone vs when to use fork
- ✅ The fork-clone-branch-PR workflow (introduced here, detailed in Lesson 13)

### What You'll Need

- Lesson 11 completed with push and pull working correctly

---

## 2. Cloning a Repository

Cloning downloads a repository from any URL and copies the complete history, all branches, and the remote configuration to your local machine in a single command. The result is a fully functional repository that is ready to use immediately.

### Step 1: Choose What to Clone

For this exercise, you will clone your own portfolio repository into a different directory to simulate the experience of someone accessing your project for the first time. Navigate to a folder outside your current portfolio project, such as your home directory.

```bash
cd ~
```

Moving to the home directory ensures the clone goes into a separate location and does not nest inside the existing portfolio folder.

### Step 2: Clone the Repository

Run `git clone` with your repository's SSH URL and provide a custom folder name to avoid a naming collision with the original.

```bash
git clone git@github.com:yourusername/portfolio.git portfolio-clone
```

Replace `yourusername` with your actual GitHub username. The last argument `portfolio-clone` is the name Git gives the new folder. Without it, Git uses the repository name from the URL (`portfolio`), which would conflict with the existing folder if you are in the same directory. You should see output like:

```
Cloning into 'portfolio-clone'...
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
Receiving objects: 100% (25/25), 4.20 KiB | 4.20 MiB/s, done.
```

Every object in the repository (commits, file contents, branches) is transferred from GitHub to your machine in this single operation.

### Step 3: Explore the Clone

Move into the cloned directory and inspect what was downloaded.

```bash
cd portfolio-clone
git log --oneline
git remote -v
git branch -a
```

`git log --oneline` shows every commit from the complete history, not just recent ones. `git remote -v` shows that `origin` was automatically configured to point to the URL you cloned from - Git sets this up without any manual configuration. `git branch -a` lists both local branches and remote tracking branches. The `-a` flag means "all," which includes the `remotes/origin/main` reference that tracks GitHub's `main` branch. The clone is a fully functional repository that is operationally identical to the original.

---

## 3. Forking a Repository

A fork is a GitHub-side operation, not a Git command. When you fork a repository on GitHub, GitHub creates a complete server-side copy under your account, with full connection to the original. You then clone your fork to your local machine as you would any other repository.

The key distinction is ownership: after forking, `github.com/yourusername/forked-repo` belongs to you. You cannot push to `github.com/originalowner/forked-repo` unless the owner grants you permission, but you can push freely to your own fork. This is how open-source contributions work: you propose changes by pushing to your fork and then opening a pull request.

### Step 1: Fork on GitHub

Navigate to any public repository on GitHub that you want to fork - for practice, you can use a friend's portfolio or any public learning repository. Click the "Fork" button in the upper right corner of the repository page. GitHub creates a copy under your account: `github.com/yourusername/forked-repo`. The copy is independent - your changes to the fork do not affect the original, and the original owner's changes do not automatically appear in your fork.

### Step 2: Clone Your Fork

Once the fork is created on GitHub, clone it to your local machine the same way you would clone any repository.

```bash
git clone git@github.com:yourusername/forked-repo.git
cd forked-repo
```

The clone points `origin` at your fork (`github.com/yourusername/forked-repo`), not at the original. This means `git push` sends commits to your fork, not to the original owner's repository.

### Step 3: Add the Original as Upstream

To keep your fork synchronized with future changes to the original repository, register the original as an additional remote named `upstream`.

```bash
git remote add upstream git@github.com:originalowner/forked-repo.git
git remote -v
```

You should now see two remotes in the output: `origin` pointing at your fork, and `upstream` pointing at the original repository. This setup is the standard for all fork-based contribution workflows. When the original project releases new commits, you can download them with `git fetch upstream` and merge them into your local branch, keeping your fork up to date without losing your own changes.

---

## 4. Clone vs Fork

Understanding when to use each approach prevents confusion about where commits end up and whether you have permission to push.

| Aspect | Clone | Fork |
|--------|-------|------|
| What it does | Downloads the repo to your machine | Creates a copy under your GitHub account |
| Where it lives | Your local machine | GitHub (then clone to local) |
| Remote `origin` | Points to the original repo | Points to your fork |
| Can you push? | Only if you have write access | Yes, it is your fork |
| Use case | Your own repos or team repos with write access | Contributing to repos you do not own |

Use **clone** when you have direct write access to the repository: your own projects, or a team repository where an admin added you as a collaborator. Use **fork** when you want to contribute to someone else's project without direct write access. Fork creates your own copy, gives you full push access to that copy, and provides the mechanism (pull request) to propose your changes back to the original.

---

## 5. Verify the Clone and Fork Setup

Before moving to Lesson 13, confirm both the clone and fork setups are working correctly.

### Step 1: Verify the Clone History

Move into the cloned portfolio and confirm the full history is present.

```bash
cd ~/portfolio-clone
git log --oneline
```

Every commit from the original portfolio repository should be listed. The clone contains a complete, independent copy of that history, meaning you could make commits here without affecting the original repository.

### Step 2: Test Pushing from the Clone

Make a small change in `portfolio-clone`, commit it, and push. Because you cloned your own portfolio, you have write access and the push will succeed.

```bash
git add index.html
git commit -m "Test push from clone"
git push
```

After pushing from the clone, visit your GitHub repository to confirm the commit appears. This demonstrates that the clone's `origin` correctly points to the same GitHub repository as your original local copy.

### Step 3: Verify Fork Remote Configuration

Navigate to your forked repository and confirm both remotes are in place.

```bash
cd ~/forked-repo
git remote -v
```

You should see both `origin` (your fork's URL) and `upstream` (the original repository's URL). If `upstream` is missing, add it with `git remote add upstream git@github.com:originalowner/forked-repo.git`.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when cloning and forking.

**Error 1: Permission denied when cloning a private repository.**

A private repository requires you to be listed as a collaborator and to have your SSH key registered with GitHub. Public repositories should clone without authentication issues.

```bash
# Wrong: cloning a private repo without proper SSH access
git clone git@github.com:someuser/private-repo.git
# git@github.com: Permission denied (publickey).

# Correct option A: use HTTPS with a personal access token if SSH is not set up
git clone https://github.com/someuser/private-repo.git

# Correct option B: verify SSH key is added to GitHub and test
ssh -T git@github.com
# Hi yourusername! You've successfully authenticated...
git clone git@github.com:someuser/private-repo.git
```

If `ssh -T git@github.com` fails, follow the SSH key setup steps from Lesson 10 before attempting to clone.

**Error 2: Trying to push to a repository you do not own.**

When you clone someone else's public repository directly (without forking first), `origin` points to their repository. Pushing to it fails because you are not a collaborator.

```bash
# Wrong: pushing to a cloned repo you do not own
git push
# remote: Permission to originalowner/repo.git denied to yourusername.
# fatal: unable to access: The requested URL returned error: 403

# Correct: fork the repo on GitHub first, then change origin to your fork
git remote set-url origin git@github.com:yourusername/repo.git
git push
```

Alternatively, remove the cloned directory, fork the repository on GitHub, and clone your fork from the beginning. The fork-first workflow avoids this situation entirely.

**Error 3: Cannot sync fork with the original because `upstream` is missing.**

Without the `upstream` remote, you have no way to pull in changes the original repository owner has made since you forked.

```bash
# Wrong: trying to fetch from upstream without it being registered
git fetch upstream
# fatal: 'upstream' does not appear to be a git repository

# Correct: add the upstream remote first, then fetch
git remote add upstream git@github.com:originalowner/forked-repo.git
git fetch upstream
git merge upstream/main
```

After merging, push to your fork with `git push origin main` to make your fork current with the original. This routine - `git fetch upstream` then `git merge upstream/main` - is how you keep a fork updated over a long contribution period.

---

## 7. Exercises

**Exercise 1:** Find a public repository on GitHub that interests you (a library, a learning project, or a friend's work). Clone it to your machine. Explore its history with `git log --oneline --graph --all`. Note how many branches exist and how old the project is based on the first commit's date.

**Exercise 2:** Fork a friend's repository (or any public practice repository). Clone your fork locally. Make a small, meaningful change, commit it, and push to your fork. Visit GitHub to confirm the change appears on your fork's repository page, not on the original.

**Exercise 3:** On your fork, add the `upstream` remote. Run `git fetch upstream` to download the original repository's latest commits. Run `git log --oneline HEAD..upstream/main` to see commits in the original that are ahead of your fork. Merge them with `git merge upstream/main`.

---

## 8. Solutions

**Solution for Exercise 1:**

Navigate to any public repository page on GitHub and copy the SSH clone URL from the "Code" dropdown button. Clone it locally.

```bash
git clone git@github.com:someuser/some-repo.git
cd some-repo
git log --oneline --graph --all
```

The `--graph --all` flags show the branching structure across every branch in the repository. The first commit listed at the very bottom of the log (the root commit) has no parent and shows the date the project started. The number of branch labels visible in the output indicates how many active branches exist. Reading another project's history this way is an excellent way to learn how experienced teams organize their work.

**Solution for Exercise 2:**

After forking on GitHub and cloning the fork, make a visible change to the repository.

```bash
git switch -c feature/my-contribution
```

Edit any file, add a meaningful line, and save. Stage and commit.

```bash
git add README.md
git commit -m "Add contributor note to README"
```

Push the branch to your fork.

```bash
git push -u origin feature/my-contribution
```

On GitHub, visit `github.com/yourusername/forked-repo` and confirm the new commit appears on the `feature/my-contribution` branch. The original repository at `github.com/originalowner/forked-repo` should show no change, demonstrating full isolation between fork and original.

**Solution for Exercise 3:**

Add the upstream remote and fetch its current state.

```bash
git remote add upstream git@github.com:originalowner/forked-repo.git
git fetch upstream
git log --oneline HEAD..upstream/main
```

`HEAD..upstream/main` shows commits that are in `upstream/main` but not yet in your current branch. Each line represents a commit you would receive if you merged. To bring your fork up to date, merge the upstream changes.

```bash
git merge upstream/main
git push origin main
```

After pushing, your fork on GitHub is now fully synchronized with the original repository.

---

## 9. Understanding Clone and Fork

Cloning and forking both produce working copies of a repository, but they serve fundamentally different purposes in the collaboration model. Cloning is a local Git operation: it downloads a repository to your machine. The result is a local folder with a `.git` directory, a configured `origin` remote, and the full history. Forking is a server-side GitHub operation: it duplicates the repository at the GitHub layer, creating a new URL under your account. You then clone the fork to get it locally.

The fork-clone workflow is the standard for open-source contribution because it respects access control. The original project owner does not need to trust you with direct push access. You work in your own fork, making whatever changes you like. When a change is ready, you open a pull request, which is a proposal the owner can review, accept, or decline. This model allows thousands of contributors to work on the same project without the project owner needing to manage individual permissions.

The `upstream` remote is a convention that names the relationship between your fork and the original. It lets you stay current with the original project's development: `git fetch upstream` downloads their new commits, and `git merge upstream/main` incorporates them into your local branch. Without this setup, your fork gradually falls behind the original as the original project continues evolving, which eventually makes your contributions harder to merge.

---

## Next Up - Lesson 13

`git clone <url>` downloads a complete repository with full history, all branches, and a preconfigured `origin` remote. Forking creates a personal copy on GitHub that you own and can push to freely. Clone for repositories you have write access to; fork for repositories you want to contribute to without direct access. Add `upstream` as a remote on forks to keep them synchronized with the original project via `git fetch upstream` and `git merge upstream/main`. The fork-clone-branch-push-PR workflow is the universal standard for open-source contribution.

In Lesson 13, you will complete that workflow by learning pull requests and code review: how to open a formal change proposal on GitHub, how the review and approval process works, and how to merge a PR and sync the result to your local machine.