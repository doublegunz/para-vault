## 1. Before You Begin

A team of five developers each creating branches named `test`, `fix`, `new-stuff`, and `my-branch` quickly becomes chaotic. Nobody knows which branch does what, which is ready for deployment, or which should be deleted. **Branch strategies** bring order by defining rules for how branches are named, when they are created, and how they flow through the system. The most popular strategy is **Gitflow**, but simpler and faster alternatives exist for teams that deploy continuously or prefer minimal overhead.

This lesson covers three branch strategies at different complexity levels: the feature branch workflow (simplest and what you have been practising throughout this course), Gitflow (most structured, for teams with scheduled releases), and trunk-based development (fastest, for mature teams with strong automated testing). You will understand when each fits, how they are implemented in practice, and which to choose based on your team's context.

### What You'll Learn

- ✅ Feature branch workflow: one branch per feature, merged into main via PR
- ✅ Gitflow: main, develop, feature, release, and hotfix branches
- ✅ Trunk-based development: small, frequent merges to main
- ✅ Naming conventions for branches
- ✅ Choosing the right strategy for your team size and release cadence

### What You'll Need

- Lesson 13 completed

---

## 2. Feature Branch Workflow

This is the simplest and most widely applicable strategy. It is what you have been practising throughout this course, and it is a fully professional approach used by many successful teams. Every feature, bug fix, or task gets its own branch created from `main`. When the work is done, a pull request is opened, reviewed, and merged back into `main`. The entire workflow fits on a single-level branching structure.

The rules are simple and consistent. The `main` branch is always deployable - it should never contain broken or incomplete code. Every new unit of work starts by branching from the latest `main`. Branches are kept short-lived (days, not weeks). Pull requests are required for all merges into `main`, providing code review and a history of intent. After merging, branches are deleted.

```
main:   A---B---C-------F---G
              \       /
feature:       D---E
```

This diagram shows the typical flow: commits A, B, C are on `main`; the feature branch splits off after C with commits D and E; a PR is merged back into `main` as commit F; and work continues with G. The feature branch disappears after the merge, keeping the structure clean.

This workflow works well for small to medium teams of two to five developers and for projects that deploy frequently. It is the right first choice for most new teams.

---

## 3. Gitflow

Gitflow adds formal structure for teams that need controlled, versioned releases. It was defined by Vincent Driessen in 2010 and has been widely adopted in enterprise and open-source projects. Instead of a single long-lived branch, Gitflow defines five branch types with specific roles and flow rules.

**main** holds only production-ready code. Every commit on `main` represents a deployed release. It is never committed to directly - all changes arrive via release or hotfix branches.

**develop** is the integration branch where features accumulate before a release. Feature branches are merged into `develop`, not `main`. When `develop` has enough features for a release, a release branch is cut from it.

**feature/** branches are created from `develop` for individual features and merge back into `develop` when done. They follow the same PR-review pattern as the feature branch workflow.

**release/** branches are created from `develop` when preparing a release. Bug fixes and final adjustments go on the release branch. When ready, it merges into both `main` (to deploy the release) and `develop` (to keep the fixes from being lost).

**hotfix/** branches are created directly from `main` for urgent production bugs that cannot wait for the next release cycle. They merge into both `main` and `develop`.

```
main:      A-----------D---E (releases)
           |           |   |
release:   |       C---D   |
           |      /        |
develop:   A---B---C---D---E---F
               |       |
feature:       B       |
                       E (hotfix)
```

Gitflow works well for teams with scheduled release cycles such as monthly or quarterly releases tied to version numbers. It adds significant overhead, including maintaining two long-lived branches and following the exact merge directions. For teams that deploy multiple times per day, this overhead is counterproductive.

---

## 4. Trunk-Based Development

Trunk-based development is the opposite philosophy from Gitflow: fewer branches, faster merges, shorter feedback cycles. Developers work on very short-lived branches (hours to a maximum of one or two days) or commit directly to `main` (the "trunk"). Incomplete features are hidden from users using feature flags, which are toggles in the code that enable or disable functionality at runtime without a separate deployment.

The rules are intentionally minimal. Everyone works on or very near `main`. Branches live for hours, not days. Continuous integration runs the full test suite automatically on every push. Feature flags allow incomplete code to be merged safely without exposing it to users. This strategy requires strong automated testing and a mature CI/CD pipeline as prerequisites.

```
main:   A---B---C---D---E---F---G---H
            |       |           |
short:      B       D           H
```

Short branches branch and merge within the same day, keeping the trunk constantly moving forward. The diagram shows that no branch ever lives long enough to accumulate significant divergence from `main`.

Trunk-based development works well for experienced teams with high test coverage and continuous deployment infrastructure. It minimizes merge conflicts through frequency rather than structure.

---

## 5. Choosing a Strategy

The right strategy depends on three main factors: how large the team is, how often releases happen, and how mature the team's testing and automation practices are. Choosing the wrong strategy causes friction in the wrong direction - too much overhead for a small team, or too little structure for a large one.

| Factor | Feature Branch | Gitflow | Trunk-Based |
|--------|---------------|---------|-------------|
| Team size | 1 to 5 | 5 to 20 | 5 or more (experienced) |
| Release cadence | Continuous | Scheduled (weekly or monthly) | Continuous |
| Complexity | Low | High | Low (but needs CI/CD) |
| Branching overhead | Minimal | Significant | Minimal |
| Best for | Startups, small teams | Enterprise, versioned products | Mature teams with strong CI |

Most teams start with the feature branch workflow and adopt Gitflow or trunk-based development as they grow. Starting with Gitflow before the team or codebase is ready adds process without adding value; starting with trunk-based development without test coverage invites broken deployments.

---

## 6. Naming Conventions

Consistent branch naming is a small investment with a large return in team readability. When everyone follows the same prefix patterns, a `git branch -a` listing immediately communicates what each branch is for without needing to open it.

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New feature | `feature/user-profile` |
| `fix/` | Bug fix | `fix/login-redirect` |
| `hotfix/` | Urgent production fix | `hotfix/payment-crash` |
| `release/` | Release preparation | `release/v2.1.0` |
| `docs/` | Documentation update | `docs/api-guide` |
| `refactor/` | Code restructuring | `refactor/auth-module` |

The slash creates visual grouping in the `git branch` output, making all `feature/` branches appear together, all `fix/` branches together, and so on. Some teams extend the convention with ticket numbers from their issue tracker, for example `feature/JIRA-123-user-profile`, which creates a direct link between the branch and the work item it implements.

---

## 7. Practice the Branch Workflow

Before ending this lesson, practice the complete feature branch cycle end-to-end to solidify the workflow as a habit.

### Step 1: Run the Full Feature Branch Cycle

Create a feature branch, add a testimonials page, push, open a PR on GitHub, merge, pull locally, and delete the branch.

```bash
git switch -c feature/testimonials
```

Create a `testimonials.html` file with at least two short testimonial quotes. Save it, stage, and commit.

```bash
git add testimonials.html
git commit -m "Add testimonials page"
git push -u origin feature/testimonials
```

Open a PR on GitHub, merge it, then return to the terminal and clean up.

```bash
git switch main
git pull
git branch -d feature/testimonials
```

Running through this sequence until it feels automatic is the goal. The commands become faster with repetition.

### Step 2: Visualize the Branching Pattern with Git Graph

After several merged PRs, the graph log reveals the branching pattern your workflow produces.

```bash
git log --oneline --graph --all
```

Each diamond shape in the graph corresponds to one merged pull request. A clean project with a consistent feature branch workflow shows a regular pattern of small diamonds. A project with long-lived branches shows wide, sprawling divergences that are harder to read.

### Step 3: Audit the Branch List

Inspect the full list of local and remote branches.

```bash
git branch -a
```

In a well-managed project, the only long-lived branch is `main` (and `develop` if using Gitflow). If you see many remote branches that were merged weeks ago and never deleted, that is a sign the team needs to clean up after merges. Stale branches create confusion about what is currently active work. Delete any locally that are already merged, and encourage teammates to delete remote branches promptly after their PRs are merged.

---

## 8. Fix the Errors in Your Code

These are the most common mistakes in branch management and workflow adoption.

**Error 1: Long-lived feature branches that drift far from main.**

The longer a branch lives without merging, the more `main` changes under it. When the branch is finally merged, the conflict surface is large and the merge takes significant time to resolve correctly.

```bash
# Wrong: a branch that has been open for three weeks
git log --oneline main..feature/enormous-feature
# 47 commits ahead, and main has moved 63 commits since branching
# Merging this will produce many conflicts

# Correct: break large work into small, independently mergeable pieces
# Each piece gets its own branch and PR
git switch -c feature/user-profile-form
# Merge when done
git switch -c feature/user-profile-avatar
# Merge when done
```

Keep branches small. If a feature naturally takes weeks, break it into parts that can each be reviewed and merged independently. Feature flags can hide incomplete parts from users while the subsequent pieces are merged.

**Error 2: Pushing commits directly to main without a pull request.**

Direct commits to `main` skip the code review step, meaning no second pair of eyes checks the change before it reaches production. On a team, this erodes trust and creates risk.

```bash
# Wrong: committing and pushing directly to main
git switch main
git add .
git commit -m "Quick fix"
git push
# Change goes live immediately with no review

# Correct: use branch protection rules on GitHub to enforce the PR requirement
# GitHub Settings > Branches > Add rule for 'main'
# Enable: "Require a pull request before merging"
# Now direct pushes to main are rejected by GitHub
```

GitHub's branch protection rules enforce the PR requirement at the server level. Even if someone attempts a direct push, GitHub rejects it. Enable these rules for any shared repository from the beginning of the project.

---

## 9. Exercises

**Exercise 1:** Enable branch protection on your portfolio repository's `main` branch. Go to GitHub Settings, then Branches, then "Add branch ruleset" for `main`. Enable "Require a pull request before merging." Attempt a direct `git push` to `main` and observe the rejection message.

**Exercise 2:** Practice the Gitflow structure. Create a `develop` branch from `main`. Create a `feature/new-section` from `develop`. Make two commits on it. Merge the feature into `develop` with a PR. Create a `release/v1.1` from `develop`. Merge the release into both `main` and `develop`.

**Exercise 3:** Create two feature branches at the same time: `feature/header-update` and `feature/footer-update`. Work on each with one commit. Merge both into `main` sequentially via PRs. Run `git log --oneline --graph` and observe the resulting two-diamond history.

---

## 10. Solutions

**Solution for Exercise 2:**

Create the develop branch from main.

```bash
git switch main
git switch -c develop
git push -u origin develop
```

Create the feature branch from develop.

```bash
git switch develop
git switch -c feature/new-section
```

Add a new section file, save, and commit twice with meaningful changes.

```bash
git add new-section.html
git commit -m "Add new section page"
git add style.css
git commit -m "Add styles for new section"
git push -u origin feature/new-section
```

Open a PR on GitHub to merge `feature/new-section` into `develop` (not `main`). Merge it. Then create the release branch from develop.

```bash
git switch develop
git pull
git switch -c release/v1.1
git push -u origin release/v1.1
```

Open a PR to merge `release/v1.1` into `main`. Merge it. Open a second PR to merge `release/v1.1` back into `develop`. Merge that too. Pull both branches locally and delete the feature and release branches.

**Solution for Exercise 3:**

Create both feature branches from main before merging either one.

```bash
git switch main
git switch -c feature/header-update
git add index.html
git commit -m "Update header layout"
git push -u origin feature/header-update
git switch main
git switch -c feature/footer-update
git add index.html
git commit -m "Update footer content"
git push -u origin feature/footer-update
```

Merge `feature/header-update` via PR first, then `git pull` on main locally. Then merge `feature/footer-update` via PR. The second merge may require conflict resolution if both branches edited the same line. After both merges, run:

```bash
git switch main
git pull
git log --oneline --graph
```

The graph shows two separate diamonds converging into main, one for each feature branch PR. This is the visual signature of the feature branch workflow applied consistently.

---

## 11. Understanding Branch Strategies

Branch strategies are team agreements, not technical requirements. Git does not enforce any branching model. You can name branches anything and merge in any direction Git will allow. The strategy provides shared expectations so that everyone on the team follows the same patterns without needing to ask how on each new task.

The fundamental principle across all three strategies is identical: `main` should always be in a deployable state. Features are developed in isolation on branches and integrated through a controlled process involving code review, automated testing, and deliberate merges. The strategies differ only in how many layers of isolation they provide, how formal the process is, and how quickly changes flow from development to production.

Choosing well means the workflow feels natural. Choosing poorly means the team spends more time managing branches than writing code. Revisit the strategy decision when the team size doubles, when the release cadence changes significantly, or when merge conflicts become a recurring complaint.

---

## Next Up - Lesson 15

Feature branch workflow is the simplest: one branch per feature, merged into main via pull request. Gitflow adds `develop`, `release`, and `hotfix` branches for structured versioned releases. Trunk-based development uses very short-lived branches with continuous integration and feature flags. Choose based on team size and release cadence. Use consistent naming conventions with prefixes like `feature/`, `fix/`, and `hotfix/`. Protect the `main` branch with GitHub's branch protection rules to enforce pull requests and prevent direct pushes.

In Lesson 15, you will learn stashing and cherry-picking: how to save uncommitted work temporarily so you can switch branches without losing it, and how to copy a specific commit from one branch to another without merging the entire branch.