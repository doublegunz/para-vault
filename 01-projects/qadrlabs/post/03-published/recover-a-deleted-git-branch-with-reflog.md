# Recover a Deleted Git Branch with Reflog

You delete a local Git branch, then realize it contained work you never merged or pushed. The branch has disappeared, the files are missing from your working directory, and nobody else has a copy. Have you lost those commits for good?

You may still be able to recover them. In this walkthrough, you will create a small project, deliberately delete an unmerged branch, and use the local HEAD reflog to find its last commit and recreate the branch. You will then verify that both commits and the complete file contents have returned.

## Overview {#overview}

The experiment uses a Markdown reading list so you can focus on Git. There is no remote repository or backup branch to recover from. All terminal output below comes from a local run with Git 2.53.0; your hashes, absolute paths, and some Git messages may differ.

### What You'll Build

- A standalone repository with a `main` branch and a `feature/reading-list` branch containing two additional commits.
- A reproducible deletion and recovery exercise, ending with the feature branch restored at its original commit.

### What You'll Learn

- Reproduce the deletion of an unmerged branch with `git branch -D`.
- Find a candidate commit in `git reflog show HEAD` and inspect its changes.
- Recreate a branch at the correct commit and verify its history and files.
- Recognize the limits of recovery when reflog entries or Git objects are no longer available.

### What You'll Need

- Git 2.28 or later for the `git init -b main` syntax used here.
- Bash, available on Linux, macOS, or through Git Bash on Windows.
- Basic familiarity with staging files, making commits, and switching branches.
- A disposable directory for the experiment. No previous tutorial or application framework is required.

## Step 1: Create a Small Git Project {#step-1-create-a-small-git-project}

Start inside a directory where you keep experiments. In the test run, this was the vault's `sandbox/` directory. Create a new project there:

```bash
mkdir git-branch-recovery-demo
cd git-branch-recovery-demo
```

These commands create an empty directory and enter it. If that name already exists, choose another unused name for both commands. Keep the deletion exercise inside this new repository.

```bash
git init -b main
```

```text
Initialized empty Git repository in /home/gun-gun-priatna/obsidian-vault/sandbox/git-branch-recovery-demo/.git/
```

The `-b main` option names the initial branch explicitly. The path in the output is the location used for this test.

```bash
git config user.name "Tutorial Developer"
git config user.email "developer@example.com"
```

These commands set an example commit identity only for this repository. They produce no output on success.

Create and save `README.md` with the following command:

```bash
cat > README.md <<'EOF'
# Reading Notes

A small project for collecting development reading notes.
EOF
```

The quoted heredoc writes the complete file, including its heading and description, without expanding shell variables inside the content. It produces no terminal output.

```bash
git add README.md
git commit -m "add project readme"
```

```text
[main (root-commit) 91d587d] add project readme
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
```

`git add` stages the new file, and `git commit` records the initial project snapshot on `main`.

```bash
git status
```

```text
On branch main
nothing to commit, working tree clean
```

The clean working tree confirms the README is committed and there are no pending changes.

```bash
git remote -v
```

This command produces no output because the repository has no remotes. The exercise will use only the local Git data.

## Step 2: Add Two Commits on a Feature Branch {#step-2-add-two-commits-on-a-feature-branch}

Build a small feature with two distinct commits. Recovering its tip should bring back both commits through their existing parent relationship.

```bash
git switch -c feature/reading-list
```

```text
Switched to a new branch 'feature/reading-list'
```

`git switch -c` creates the branch from the current commit and switches to it.

Create and save `reading-list.md`:

```bash
cat > reading-list.md <<'EOF'
# Reading List

- Read about Git branches.
EOF
```

This writes the first version of the list. Record it as a commit:

```bash
git add reading-list.md
git commit -m "add git reading list"
```

```text
[feature/reading-list 077d79e] add git reading list
 1 file changed, 3 insertions(+)
 create mode 100644 reading-list.md
```

The commit adds a new file that exists on the feature branch. Next, replace and save `reading-list.md` with the complete updated contents:

```bash
cat > reading-list.md <<'EOF'
# Reading List

- Read about Git branches.
- Practice recovering a deleted branch.
EOF
```

The second version adds a recovery exercise while preserving the original reading item. Commit that change:

```bash
git add reading-list.md
git commit -m "add branch recovery exercise"
```

```text
[feature/reading-list 908d621] add branch recovery exercise
 1 file changed, 1 insertion(+)
```

Git records one additional line in a second commit. Check the history that belongs to this branch but is absent from `main`:

```bash
git log --oneline main..feature/reading-list
```

```text
908d621 add branch recovery exercise
077d79e add git reading list
```

The range `main..feature/reading-list` selects commits reachable from the feature branch but not from `main`. The newest commit appears first. Both commits are still unmerged, and neither has been pushed.

```bash
git rev-parse feature/reading-list
```

```text
908d621138c6e7c8815226c2d2eae2554c680db4
```

Record this full hash as a baseline for the final verification. The recovery procedure will locate the candidate through the reflog rather than depend on this saved value.

## Step 3: Delete the Unmerged Branch {#step-3-delete-the-unmerged-branch}

Now reproduce the mistake. First, leave the feature branch so Git can delete it:

```bash
git switch main
```

```text
Switched to branch 'main'
```

Switching to `main` updates the working directory to its snapshot. The reading list disappears from the working directory at this point because it has never been added to `main`.

Try the ordinary deletion command:

```bash
git branch -d feature/reading-list
```

```text
error: the branch 'feature/reading-list' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature/reading-list'
hint: Disable this message with "git config set advice.forceDeleteBranch false"
```

This failure is expected. The branch has no upstream, so Git checks whether its commits have been merged into the current `HEAD`, which is `main`. They have not. The lowercase `-d` option therefore refuses the deletion. See the [Git branch documentation](https://git-scm.com/docs/git-branch).

For this disposable exercise, deliberately override that check:

```bash
git branch -D feature/reading-list
```

```text
Deleted branch feature/reading-list (was 908d621).
```

The uppercase `-D` forces the deletion. Git prints the former tip's abbreviated hash, which could itself be useful if you still had this terminal output during a real incident. We will assume that clue is unavailable and find the commit through the reflog instead.

```bash
git branch
```

```text
* main
```

Only `main` remains in the branch list. Check its tracked files:

```bash
git ls-files
```

```text
README.md
```

Only the README appears. Then inspect the history visible from the remaining references:

```bash
git log --all --oneline
```

```text
91d587d add project readme
```

Even with `--all`, this log shows only the initial commit. The two feature commits are no longer reachable from the remaining branches or other ordinary references. This output does not establish that their underlying objects have been erased.

## Step 4: Find the Missing Commits and Restore the Branch {#step-4-find-the-missing-commits-and-restore-the-branch}

Search the local HEAD reflog for the work you recognize:

```bash
git reflog show HEAD
```

```text
91d587d HEAD@{0}: checkout: moving from feature/reading-list to main
908d621 HEAD@{1}: commit: add branch recovery exercise
077d79e HEAD@{2}: commit: add git reading list
91d587d HEAD@{3}: checkout: moving from main to feature/reading-list
91d587d HEAD@{4}: commit (initial): add project readme
```

The entry for `add branch recovery exercise` identifies the candidate tip, `908d621` in this run. The older `add git reading list` entry is also present.

Look carefully at the first line. Its hash belongs to `main`, the destination of the branch switch. Although the message mentions the deleted branch, that line is not its former tip.

In this run, the candidate appears at `HEAD@{1}`. Do not assume that position in your own repository: subsequent commits and branch switches change the reflog positions. Find the relevant entry and copy its hash.

Inspect the candidate before creating a branch. Replace `908d621` in the following commands with the hash you found:

```bash
git show --format=oneline 908d621 -- reading-list.md
```

```text
908d621138c6e7c8815226c2d2eae2554c680db4 add branch recovery exercise
diff --git a/reading-list.md b/reading-list.md
index cda28ac..093bc20 100644
--- a/reading-list.md
+++ b/reading-list.md
@@ -1,3 +1,4 @@
 # Reading List
 
 - Read about Git branches.
+- Practice recovering a deleted branch.
```

`git show` displays the commit and its patch for `reading-list.md`. The added recovery exercise matches our second feature change. Also inspect the candidate's history relative to `main`:

```bash
git log --oneline main..908d621
```

```text
908d621 add branch recovery exercise
077d79e add git reading list
```

Both expected feature commits appear. This helps distinguish the final tip from the earlier commit that contains only the first reading item.

Recreate the original branch name at that candidate:

```bash
git branch feature/reading-list 908d621
```

This command succeeds silently. It creates a branch reference pointing to the existing commit; it does not make a new commit or switch branches. Check the result:

```bash
git branch
```

```text
  feature/reading-list
* main
```

The feature branch exists again. The asterisk still marks `main` as the current branch.

## Step 5: Try It Out {#step-5-try-it-out}

Verify the restored files and history before treating recovery as complete. The following checks cover the contents, both feature commits, the original tip, and the unchanged base branch.

### Check the Recovered File

```bash
git switch feature/reading-list
```

```text
Switched to branch 'feature/reading-list'
```

Switching to the restored branch checks out its snapshot. Read the file:

```bash
cat reading-list.md
```

```text
# Reading List

- Read about Git branches.
- Practice recovering a deleted branch.
```

Both reading items are present, including the line introduced by the second commit.

### Check Both Commits and the Original Tip

```bash
git log --oneline main..feature/reading-list
```

```text
908d621 add branch recovery exercise
077d79e add git reading list
```

The history contains the same two commits shown before deletion. Confirm the count:

```bash
git rev-list --count main..feature/reading-list
```

```text
2
```

The result is two commits ahead of `main`. Now compare the full tip hash with the baseline from Step 2:

```bash
git rev-parse feature/reading-list
```

```text
908d621138c6e7c8815226c2d2eae2554c680db4
```

It is exactly the same hash as before deletion. We restored the branch at its original commit, preserving the existing history.

### Check the Working Tree and Main Branch

```bash
git status
```

```text
On branch feature/reading-list
nothing to commit, working tree clean
```

The working tree is clean, so the recovered contents are committed. Inspect `main` separately:

```bash
git rev-parse main
```

```text
91d587d59bf2cc89b446183baf17fc6814b8edf9
```

This is the initial README commit, whose abbreviated hash was `91d587d` in Step 1. Recovery has not moved `main` or merged the feature into it. The local validation also compared the complete reading-list file before deletion and after recovery; its bytes matched exactly.

## Why Recovery Works and When It Fails {#why-recovery-works-and-when-it-fails}

The experiment succeeds because the objects needed to restore the feature still exist. Deleting a branch removes its named reference. Recreating that reference at the surviving tip makes the feature's history accessible by its branch name again.

### The HEAD Reflog Supplies the Missing Clue

A reflog records local reference updates, and the HEAD reflog also records branch switches. In this experiment, it retained the feature commit entries after the branch was removed. The [reflog documentation](https://git-scm.com/docs/git-reflog) describes these records and their selectors.

Deleting a branch also deletes that branch's own reflog, if it has one. That is why this walkthrough reads `HEAD`, rather than asking for the deleted branch's reflog. Recreating the branch restores access to the commits; it does not reconstruct the old branch-specific reflog. See the [branch deletion documentation](https://git-scm.com/docs/git-branch).

### Recovery Has No Guaranteed Deadline

Reflog records are local and temporary. Git's default expiration settings are 90 days for ordinary entries and 30 days for entries unreachable from the current tip. These are configurable expiration thresholds, not a promise that your deleted branch can be recovered for a fixed number of days. See the [reflog expiration options](https://git-scm.com/docs/git-reflog#_options).

Expiration of a reflog entry and removal of an object are separate events. Once objects are no longer protected by references or reflogs, garbage collection can eventually remove eligible objects. Configuration and maintenance timing affect what remains. Avoid forcing reflog expiration or object pruning while investigating lost work. The [Git garbage collection documentation](https://git-scm.com/docs/git-gc) explains these retention settings.

### If the Reflog Does Not Contain the Commit

Git's object database may still contain the missing work. The `git fsck` command can report unreachable objects; its `--no-reflogs` option excludes reflogs as reachability roots when searching. Finding a candidate still requires inspecting its contents and history before creating a branch. This is a separate recovery path, described in the [Git fsck documentation](https://git-scm.com/docs/git-fsck).

If the required objects have already been pruned and no other copy exists, Git cannot reconstruct them from a hash alone. This walkthrough also concerns committed work: changes that were never committed are outside the recovery demonstrated here.

## Conclusion {#conclusion}

The deleted branch in this experiment came back with both commits and its complete file contents. The decisive check was the identical tip hash before deletion and after recovery.

- **A deleted branch can be recoverable.** Removing the reference does not immediately erase the commit objects needed to restore its history.
- **Search the HEAD reflog.** Find the relevant commit entry, inspect its patch, and verify its history before choosing the tip.
- **Recreate the reference.** Use `git branch <branch-name> <commit-hash>` to give the surviving commit a branch name again.
- **Verify the result.** Check the file contents, expected commits, tip hash, and working-tree status.
- **Object availability is the limit.** Reflog expiration and garbage collection can close the recovery window; a surviving hash alone is insufficient.
