## 1. Before You Begin

So far, all your work has been on a single line of commits on the `main` branch. But real projects need parallel lines of development. You might be building a new feature while a teammate fixes a bug. Both of you are changing the same codebase, but your changes should not interfere with each other until they are ready to be integrated. **Branches** solve this by creating separate lines of development that can be combined back together when the work is complete.

This lesson is conceptual. It explains what branches actually are in Git at the data level (they are just pointers to commits), what `HEAD` means, why branching is nearly instant in Git compared to other systems, and how branches enable safe experimentation. Lesson 7 covers the commands for creating and using branches.

### What You'll Build

In this lesson, you will not write code or run Git commands. Instead, you will build a precise mental model of how branches work internally. This model will make every branch-related command in Lessons 7, 8, and 9 immediately understandable rather than mysterious.

### What You'll Learn

- ✅ What a branch really is (a pointer to a commit, not a copy of files)
- ✅ What `HEAD` is (a pointer to the current branch)
- ✅ Why branching is cheap in Git (no file copying)
- ✅ The mental model for parallel development
- ✅ Common branching use cases: features, fixes, experiments

### What You'll Need

- Lesson 5 completed

---

## 2. What Is a Branch?

Before understanding commands, you need to understand the data structure. A branch in Git is not a copy of your files. It is a lightweight, movable pointer to a single commit. When you create a new branch, Git creates a tiny 41-byte file containing the hash of the commit it points to. That is the entire operation. No files are copied, no directories are duplicated, no history is cloned.

Think of commits as a chain of train cars, each connected to the one before it. A branch is simply a label attached to one specific car. The `main` branch is a label on the latest commit of the main line. When you create a new branch called `feature-about`, Git attaches another label to that same commit. As you make new commits on `feature-about`, only that label moves forward to the newest car. The `main` label stays exactly where it was.

```
Before branching:
  a1b -- b2c -- c3d  (main, HEAD)

After creating feature-about:
  a1b -- b2c -- c3d  (main, feature-about, HEAD)

After two commits on feature-about:
  a1b -- b2c -- c3d  (main)
                  \
                   d4e -- e5f  (feature-about, HEAD)
```

The diagram shows that `main` has not moved at all. The `feature-about` branch now points to a different commit further along a separate chain. Both branches share the history up to `c3d`, then diverge. Switching back to `main` would restore your working directory to the state at `c3d`, and the `d4e` and `e5f` commits would temporarily disappear from view - but they are still safely stored in the repository.

---

## 3. What Is HEAD?

`HEAD` is a special pointer that tells Git which branch you are currently working on. It answers the question: "If I commit right now, which branch label moves forward?"

When you commit, the branch that `HEAD` is pointing to moves forward to the new commit. If `HEAD` points to `main`, your commits extend the `main` branch. If `HEAD` points to `feature-about`, your commits extend `feature-about` without touching `main`.

When you switch branches (in Lesson 7), Git performs two actions: it moves `HEAD` to point to the new branch, and it updates every file in your working directory to match the state recorded in that branch's latest commit. This is why switching branches can feel like the files in your folder change - because they do. Git is replacing the working directory contents with the snapshot from the target branch.

---

## 4. Why Branching Is Cheap

Understanding why Git branching is fast matters because it changes how you work. In centralized systems like SVN, creating a branch physically copies the entire project directory on the server. A project with 10,000 files takes significant time and disk space to branch. Developers avoid creating branches because the cost is high.

In Git, creating a branch writes 41 bytes (the commit hash) to a new file inside the `.git` folder. The operation completes in milliseconds regardless of the project size. Switching between branches updates only the files that differ between the two branches, which Git knows from comparing the two commit snapshots. This is why experienced Git developers create branches for every individual task: a branch for each feature, each bug fix, each experiment, each refactoring. The cost is negligible, and the isolation benefit is large.

---

## 5. Common Use Cases

Branches are used for several recurring patterns in professional development. Each pattern takes advantage of the same property: changes on one branch do not affect other branches until a deliberate merge happens.

**Feature branches** contain the work for a single feature. You create a branch from `main`, build the feature committing as you go, and merge back when the feature is complete and tested. If the feature is cancelled mid-way, you delete the branch and `main` is completely unaffected.

**Bug fix branches** isolate a specific fix from ongoing feature work. You branch from the current production state, apply the fix, test it in isolation, and merge it back. This ensures a bug fix does not accidentally include half-finished feature code.

**Experiment branches** let you try risky or uncertain changes without any fear of breaking the working codebase. If the experiment succeeds, you merge it. If it fails, you delete the branch. No harm done, no cleanup required.

**Release branches** prepare a specific version for production deployment. Bug fixes can be applied to the release branch while new features continue developing on their own branches, keeping the release version stable.

---

## 6. Understanding Branches Visually

The key insight that simplifies all of Git branching is this: branches are nothing more than labels on commits. They do not create copies of files or separate project directories. The commit chain is the real structure that Git maintains. Branches are human-friendly names for specific points in that chain.

When two branches diverge (each has commits after a common ancestor), Git tracks both lines independently using their respective labels. When you merge them in Lesson 8, Git examines three commits: the common ancestor, the tip of one branch, and the tip of the other. It combines the changes from both sides into a single new merge commit. This merge commit has two parents instead of one, which is how the history records that two parallel lines of development came together.

The mental model to carry into Lessons 7, 8, and 9: a branch is a movable sticky note on the commit timeline. `HEAD` marks which sticky note is currently "active." Making a commit moves the active sticky note forward to the new commit. Switching branches moves the active status from one sticky note to another and restores the working directory to match. Merging creates a new commit that connects two sticky notes back into one line.

---

## 7. Exercises

**Exercise 1:** Draw the following scenario on paper. You have a repository with four commits labeled A, B, C, and D on `main`, with `HEAD` pointing at D. You create a branch called `feature/nav`. You make two more commits, E and F, on `feature/nav`. Draw the commit chain, show where each branch label sits, and show where `HEAD` is. Then draw what the diagram looks like after you switch back to `main`.

**Exercise 2:** Answer the following questions in your own words without looking at the lesson: (a) What is a Git branch at the data level? (b) What does `HEAD` track? (c) Why is creating a branch in Git faster than in SVN? (d) If you delete a branch label, do the commits disappear?

**Exercise 3:** Think about a project you have worked on (or imagine one). Describe three separate changes you would make using three separate branches. Name each branch using the naming convention `feature/short-description` and explain what work each branch would contain.

---

## 8. Solutions

**Solution for Exercise 1:**

The initial state after four commits on `main`:

```
A -- B -- C -- D  (main, HEAD)
```

After creating `feature/nav` (no commits yet, both labels point to D):

```
A -- B -- C -- D  (main, feature/nav, HEAD)
```

After two commits on `feature/nav`:

```
A -- B -- C -- D  (main)
                \
                 E -- F  (feature/nav, HEAD)
```

After switching back to `main` (HEAD moves, working directory restores to D's snapshot):

```
A -- B -- C -- D  (main, HEAD)
                \
                 E -- F  (feature/nav)
```

The `feature/nav` commits E and F still exist in the repository. They are simply not visible in the default `git log` because `HEAD` is on `main`. Running `git log --all --oneline` would show all commits from all branches.

**Solution for Exercise 2:**

(a) A Git branch is a 41-byte file inside `.git/refs/heads/` containing the hash of the commit it points to. It is a movable label, not a copy of files.

(b) `HEAD` tracks which branch is currently active - the branch that will move forward when you make the next commit.

(c) Creating a branch in Git writes one small file (41 bytes). SVN branches copy the entire project directory on the server, which takes time proportional to the project size.

(d) No. Deleting a branch label removes the label file but leaves all the commits intact. The commits become unreachable from named branches, and Git's garbage collector will eventually remove them, but they persist for at least 30 days and can be recovered with `git reflog`.

---

## Next Up - Lesson 7

A branch in Git is a lightweight pointer to a commit, not a copy of files or directories. Creating a branch writes a 41-byte file and completes instantly regardless of project size. `HEAD` is a pointer to the currently active branch - it moves forward with every commit and changes branch when you switch. Feature branches, bug fix branches, and experiment branches all follow the same principle: isolated development on a separate label that merges back when ready. The commit chain is the permanent record; branch labels are just human-readable names for specific points in that chain.

In Lesson 7, you will put this mental model into practice by creating branches with `git switch -c`, switching between them, making commits on each, and listing all branches in the repository.