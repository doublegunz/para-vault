## 1. Before You Begin

Imagine writing a 50-page research paper. You make changes, realize the previous version was better, but you already saved over it. Now imagine doing this with thousands of lines of code, across multiple files, with five teammates making changes simultaneously. Without a system to track every change, recover old versions, and merge everyone's work together, software development would be chaos. **Git** is that system.

This lesson explains what version control is, why Git was created, how it works conceptually, and what you will build throughout this course. There is no coding in this lesson. The focus is on understanding the ideas that make every future lesson click.

### What You'll Build

In this lesson, you will not write any code. Instead, you will build a clear mental model of what Git is, how it stores data, and how it differs from other version control systems. This mental model is the foundation for every command you will run from Lesson 2 onward.

### What You'll Learn

- ✅ What version control is and what problems it solves
- ✅ The history of Git: why Linus Torvalds created it
- ✅ How Git stores data: snapshots, not diffs
- ✅ Distributed vs centralized version control
- ✅ The three areas: working directory, staging area, repository
- ✅ What you will build in this course

### What You'll Need

- No software required for this lesson
- Curiosity about how professional developers manage code

---

## 2. What Is Version Control?

Version control is a system that records changes to files over time so you can recall specific versions later. Think of it as an "undo history" for your entire project, but far more powerful. You can see exactly what changed, when it changed, who changed it, and why. You can jump back to any previous state. You can create parallel versions of the project and merge them together.

Without version control, developers resort to naming files like `index_v2_final_FINAL_really_final.html`. With version control, you have one file and a complete history of every version it has ever been.

---

## 3. Why Git?

Git was created to solve a real, large-scale problem. Before Git, developers used centralized systems like SVN (Subversion). In a centralized system, there is one server that holds the entire history. Every developer connects to that server to commit changes. If the server goes down, nobody can work. If the server's hard drive fails, the entire history is lost.

In 2005, Linus Torvalds (the creator of Linux) needed a version control system for the Linux kernel: thousands of developers, millions of lines of code, distributed across the world. He created Git with three goals: speed, support for distributed development, and the ability to handle large projects. Git achieved all three and became the dominant version control system in the industry.

---

## 4. How Git Stores Data

Understanding how Git stores data internally helps explain why it behaves the way it does. Most version control systems store changes as a list of differences (diffs): "line 42 changed from X to Y." Git takes a fundamentally different approach: it stores **snapshots**. Every time you commit, Git takes a picture of what all your files look like at that moment and stores a reference to that snapshot.

If a file has not changed since the last commit, Git does not store the file again. It stores a link to the previous identical file. This makes Git extremely fast and efficient.

```
Traditional (diffs):
  Version 1: full file
  Version 2: changes from v1
  Version 3: changes from v2
  To get v3: apply v1 + changes + changes (slow for long history)

Git (snapshots):
  Commit 1: snapshot of all files
  Commit 2: snapshot of all files (unchanged files are links)
  Commit 3: snapshot of all files
  To get v3: just load commit 3 (fast, regardless of history length)
```

The diagram above shows why the snapshot model gives Git a speed advantage. To reconstruct any version in the traditional diff model, Git would need to replay every change from the beginning. With snapshots, Git simply loads the stored state for that commit directly, no reconstruction needed. This is why Git is so fast at switching between branches and viewing old versions.

---

## 5. Distributed vs Centralized

The difference between distributed and centralized version control is one of the most important concepts to understand before you start using Git. Git is a **distributed** version control system. Every developer has a complete copy of the entire repository, including the full history. You can commit, branch, merge, and view history without any network connection. The remote server (like GitHub) is a convenience for sharing, not a requirement for working.

| Feature | Centralized (SVN) | Distributed (Git) |
|---------|-------------------|-------------------|
| History location | Server only | Every developer's machine |
| Work offline | No (need server connection) | Yes (full history locally) |
| Single point of failure | Server is the single point | No single point of failure |
| Speed | Network-dependent | Local operations are instant |
| Branching | Expensive (copies files) | Cheap (moves a pointer) |

The table above makes clear why Git's distributed model is a significant improvement. Because every developer holds the full repository locally, there is no single point of failure and no network bottleneck for everyday operations.

---

## 6. The Three Areas

Git organizes your work into three areas. Understanding these three areas is the key to understanding every Git command you will learn in this course.

**Working Directory** is where you edit files. This is the folder on your computer where you write code. Git watches this folder for changes but does not automatically record them.

**Staging Area** (also called the "index") is a preparation zone. When you are happy with a change, you add it to the staging area. This is like putting items in a shopping cart before checkout. You can add multiple changes to the staging area before committing them all at once.

**Repository** (the `.git` folder) is the permanent record. When you commit, Git takes everything in the staging area and stores it as a snapshot in the repository. This snapshot is permanent and can be recalled at any time.

```
Working Directory    →    Staging Area    →    Repository
  (edit files)         (git add)           (git commit)
  (your workspace)     (shopping cart)     (permanent record)
```

Every Git workflow follows this flow: edit files in the working directory, stage the changes you want to keep, and commit them to the repository. You will use this three-step cycle in every lesson from here on.

---

## 7. What You Will Build

This course is structured around a real project so that every Git command has a practical context. Throughout this course, you will build a **personal portfolio website** using HTML and CSS. The project is intentionally simple so you can focus on Git, not on web development. Each lesson adds or modifies files, and you use Git to track every change.

The project will go through these stages:

**Lessons 1-5:** Create the project, make your first commits, learn to view history.

**Lessons 6-9:** Add features on branches (an about page, a contact page), merge them, and resolve conflicts.

**Lessons 10-12:** Push to GitHub, pull changes, clone and fork repositories.

**Lessons 13-14:** Collaborate with pull requests and learn professional workflows.

**Lessons 15-17:** Use advanced tools: stash, cherry-pick, rebase, tags.

By the end, you will have a complete Git history showing how a project evolves, with branches, merges, and tagged releases.

---

## 8. Key Terminology

The following terms appear throughout the course. You do not need to memorize them now; they will become natural as you use them in practice. Refer back to this section whenever you encounter an unfamiliar term.

**Repository (repo):** A project folder tracked by Git. Contains all files and the complete history.

**Commit:** A snapshot of the project at a specific point in time. Every commit has a unique ID (hash), an author, a date, and a message describing the change.

**Branch:** A parallel line of development. The default branch is called `main`. You create branches to work on features without affecting `main`.

**Merge:** Combining changes from one branch into another.

**Remote:** A copy of the repository on another machine (usually GitHub). Your local repo connects to the remote to share changes.

**Clone:** Downloading a complete copy of a remote repository to your machine.

**Push:** Sending your local commits to the remote repository.

**Pull:** Downloading new commits from the remote repository to your local machine.

---

## 9. The Mental Model to Carry Forward

Before moving on, there is one mental model worth internalizing because it will make every future lesson easier. Version control is not just about saving files. It is a system for managing change over time. Every commit is a checkpoint that you can return to. Every branch is an experiment that you can abandon or integrate. Every merge is a decision about which changes to keep.

Git does not store "files." Git stores "snapshots of your project at specific moments." Each commit captures the entire state of every tracked file. When you switch branches, Git replaces the files in your working directory with the snapshot from that branch. When you merge, Git combines snapshots from two branches into one.

This snapshot-based model explains why Git is fast (loading a snapshot is one operation, not replaying hundreds of diffs), why branching is cheap (a branch is just a pointer to a commit, not a copy of files), and why distributed repos are possible (each clone has the complete history of snapshots).

---

## Next Up - Lesson 2

Git is a distributed version control system that tracks changes to your project using snapshots. It was created by Linus Torvalds for the Linux kernel and is now used by virtually every software team. Git organizes work into three areas: the working directory where you edit, the staging area where you prepare, and the repository where changes are permanently recorded. The snapshot model makes Git fast and efficient, and the distributed design means every developer holds the full project history locally.

In Lesson 2, you will install Git on your machine and configure it with your name and email so your commits are properly identified.