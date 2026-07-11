## 1. Before You Begin

Your portfolio project has reached a milestone: all pages are built, the history is clean, and the site is live on GitHub. This is version 1.0. You need a way to permanently mark this point in the history so you can always return to exactly this state, whether for deployment, comparison, or archival. **Tags** are immutable labels on specific commits. Unlike branches, they never move forward when new commits are made. They are fixed forever, and version numbers like `v1.0` or `v2.3.1` are their most common use.

At the same time, your project likely accumulates files that should never be tracked: your operating system creates invisible metadata files, your text editor saves configuration in hidden directories, and future dependencies will generate massive `node_modules` folders. **.gitignore** tells Git to ignore these files permanently, keeping `git status` and `git add .` focused on source code rather than noise.

This lesson covers creating annotated tags, pushing them to GitHub, publishing a GitHub Release based on a tag, and building a comprehensive `.gitignore` file.

### What You'll Build

You will tag the current state of the portfolio as `v1.0`, push the tag to GitHub, publish a GitHub Release with a changelog description, and add a `.gitignore` file that excludes OS metadata, editor settings, dependency directories, environment files, and build output.

### What You'll Learn

- ✅ `git tag` for lightweight and annotated tags
- ✅ `git push --tags` to push tags to GitHub
- ✅ GitHub Releases for versioned, distributable downloads
- ✅ `.gitignore` syntax and common patterns
- ✅ Global gitignore for personal editor and OS files
- ✅ Removing already-tracked files from Git without deleting them from disk

### What You'll Need

- Lesson 16 completed

---

## 2. Creating Tags

Tags serve a different purpose than branches. Branches are for ongoing work and move forward with every new commit. Tags are milestones - they are attached to a specific commit and remain there permanently. When you create `v1.0`, that label will always point to the same snapshot, regardless of how many commits you make afterward.

There are two types of tags. A lightweight tag is simply a named pointer to a commit, stored as a file with no additional metadata. An annotated tag is recommended for releases: it stores the tagger's name, email, the date it was created, and a message, making it a fuller record of the release event.

### Step 1: Create an Annotated Tag

Tag the current commit as version 1.0 with a descriptive release message.

```bash
git tag -a v1.0 -m "Release version 1.0: portfolio website with all pages"
```

The `-a` flag creates an annotated tag. The `-m` flag provides the tag message inline, similar to `git commit -m`. If you omit `-m`, Git opens your editor to write a longer message. Annotated tags are the recommended choice for any tag that represents a release because the stored metadata creates an auditable record of who tagged the release and when.

### Step 2: View Tags

List all tags in the repository.

```bash
git tag
```

You should see `v1.0` listed. To inspect the full details of the tag, including the tagger metadata and the commit it points to, use `git show`.

```bash
git show v1.0
```

The output shows the tag name, tagger, date, and message at the top, followed by the full commit information and diff. This is the additional metadata that annotated tags preserve over lightweight tags.

### Step 3: Push Tags to GitHub

Tags are intentionally not pushed by default when you run `git push`. This design prevents accidental tag creation on the remote. Push specific tags or all tags explicitly.

```bash
git push origin v1.0
```

Or push every local tag that the remote does not have yet.

```bash
git push --tags
```

After pushing, visit your GitHub repository. Click the "Tags" link next to the "Branches" button at the top of the file list. The `v1.0` tag should be listed with the commit it points to and the option to download the source at that exact state.

### Step 4: Tag an Earlier Commit

Tags can be applied retroactively to any commit in history, not only the current one. Find the hash of the first commit you ever made on this project.

```bash
git log --oneline
```

Copy the hash of the earliest commit (the one at the bottom of the list). Create a `v0.1` tag on it.

```bash
git tag -a v0.1 a1b2c3d -m "Initial version with homepage only"
```

Replace `a1b2c3d` with the actual hash. This retroactively marks that point in history as version 0.1. Push the new tag.

```bash
git push origin v0.1
```

Both tags are now visible on GitHub's Tags page, each pointing to its respective commit.

---

## 3. GitHub Releases

A GitHub Release is a published event built on top of a Git tag. It adds a human-readable title, a changelog or description, and optionally attaches downloadable files such as compiled binaries or packaged distributions. For source code projects, GitHub automatically generates ZIP and `.tar.gz` downloads of the source at the tag's commit.

### Step 1: Create a Release on GitHub

Navigate to your repository on GitHub and click "Releases" in the right sidebar. Click "Create a new release." In the "Choose a tag" dropdown, select `v1.0`. Fill in the release title as "v1.0 - Portfolio Website" and write a description in the text area.

A good release description lists the features included in this version, any known limitations, and instructions for viewing or using the project. For this portfolio, the description might list all pages that exist (home, about, contact, projects, skills), the styling choices made, and a link to the live GitHub Pages URL if you have one.

Click "Publish release." The release page is now publicly accessible at a permanent URL and GitHub's "latest release" badge will point to it.

---

## 4. The .gitignore File

A `.gitignore` file placed in the project root (or any directory) tells Git to permanently exclude matching files and directories from tracking. Excluded files do not appear in `git status`, are not staged by `git add .`, and are never committed to the repository unless explicitly added with `git add --force`.

### Step 1: Create the .gitignore File

Create `.gitignore` in the portfolio project root with the following content.

```
# Operating system files
.DS_Store
Thumbs.db

# Editor settings
.vscode/
.idea/
*.swp
*.swo

# Dependency directories
node_modules/
vendor/

# Environment files (contain secrets)
.env
.env.local
.env.production

# Build output
dist/
build/

# Log files
*.log

# Compiled files
*.min.css
*.min.js
```

Save the file. Each line is a pattern. `*` matches any sequence of characters within a path segment. Trailing `/` means match only directories, not files. Lines starting with `#` are comments. Lines starting with `!` negate the pattern, causing previously ignored files to be tracked. For example, `!important.log` would un-ignore a file even though `*.log` ignores all log files.

### Step 2: Stage and Commit the .gitignore File

Add the `.gitignore` file to the repository so it applies to everyone who clones the project.

```bash
git add .gitignore
git commit -m "Add .gitignore for OS, editor, and dependency files"
git push
```

From this point forward, any file matching the listed patterns will be invisible to Git on your machine and on every other machine where this repository is cloned. Files that already exist on disk and match a pattern will not be staged by `git add .`, which keeps the repository focused entirely on source code.

---

## 5. Global Gitignore

Some ignore patterns are personal preferences that belong on your machine rather than in the project's `.gitignore`. Adding `.vscode/` to a shared `.gitignore` makes assumptions about every contributor's editor. A developer using JetBrains IDEs will need `.idea/` ignored instead. The right place for personal patterns is a global gitignore that applies to all repositories on your system without any project-specific file.

Configure Git to use a global gitignore file.

```bash
git config --global core.excludesFile ~/.gitignore_global
```

Create the file with patterns that match your personal setup.

```
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Windows
Thumbs.db
desktop.ini

# VS Code
.vscode/

# JetBrains IDEs
.idea/

# Vim temporary files
*.swp
*.swo

# Node.js debug logs
npm-debug.log
```

Save the file. These patterns apply to every Git repository on your machine without appearing in any project's `.gitignore`. Each contributor maintains their own global gitignore for their own editor and OS, which keeps the project's `.gitignore` exclusively for project-specific patterns like `node_modules/`, `dist/`, and `.env`.

---

## 6. Removing Already-Tracked Files

`.gitignore` only affects files that Git has never seen before. If a file was committed to the repository before the corresponding pattern was added to `.gitignore`, Git continues tracking it regardless of the pattern. Adding the pattern prevents future changes from being noticed, but the file remains in the index (Git's internal tracking list) and will be pushed to remotes.

To stop tracking a file without deleting it from your disk, use `git rm --cached`.

```bash
git rm --cached .env
git commit -m "Remove .env from tracking - move to gitignore"
```

`--cached` removes the file from Git's index (staging area / tracking list) but leaves it on your local filesystem. Without `--cached`, `git rm` deletes the file from both the index and the disk. After committing this change, `.env` will no longer be in the repository's history going forward. Future clones will not receive the file. Existing clones will see Git's indication that the file was removed.

For an entire ignored directory that was accidentally committed, use the recursive flag.

```bash
git rm --cached -r node_modules/
git commit -m "Remove accidentally committed node_modules directory"
```

---

## 7. Verify Tags, Release, and .gitignore

Confirm all three parts of this lesson are working correctly before moving to Lesson 18.

### Step 1: Verify Tags Locally and on GitHub

List all local tags and inspect the annotated tag content.

```bash
git tag
git show v1.0
```

The tag entry should show the tagger name, email, date, and message above the commit details. Visit `github.com/yourusername/portfolio` and click the Tags link to confirm `v1.0` and `v0.1` both appear on GitHub.

### Step 2: Verify the GitHub Release

Navigate to the Releases page of your GitHub repository. The `v1.0` release should appear with the title, description, and two automatically generated download links: `Source code (zip)` and `Source code (tar.gz)`. Click the ZIP download link to confirm it downloads a snapshot of the project at the `v1.0` tag.

### Step 3: Verify .gitignore in Action

Create a file matching one of the ignore patterns.

```bash
touch test.log
git status
```

`test.log` should not appear in the `git status` output. Git is ignoring it because of the `*.log` pattern. Delete the file after testing.

```bash
rm test.log
```

Create a file that does NOT match any pattern and confirm it does appear in `git status`.

```bash
touch new-page.html
git status
```

`new-page.html` appears as an untracked file because it does not match any pattern in `.gitignore`. Delete it after the test.

```bash
rm new-page.html
```

---

## 8. Fix the Errors in Your Code

These are the most common mistakes with tags and `.gitignore`.

**Error 1: `.gitignore` does not ignore a file that was already committed.**

Adding a pattern to `.gitignore` after the file has already been committed has no effect on the tracked file. Git continues tracking it because `.gitignore` applies only to untracked files.

```bash
# Wrong: expecting .gitignore to automatically untrack an already-committed file
echo ".env" >> .gitignore
git status
# Changes: .gitignore (new file)
# But .env is STILL being tracked by Git

# Correct: remove from tracking first, then the ignore pattern takes effect
git rm --cached .env
git add .gitignore
git commit -m "Add .gitignore and stop tracking .env"
```

After `git rm --cached .env` and committing, `.env` is removed from the repository's tracked files. The `.gitignore` pattern then prevents future versions of the file from being accidentally added.

**Error 2: Tags not appearing on GitHub after creating them locally.**

`git push` sends commits but never sends tags by default. Tags must be pushed separately.

```bash
# Wrong: creating a tag locally and expecting it to appear on GitHub automatically
git tag -a v1.0 -m "Release"
git push
# (no tag appears on GitHub)

# Correct: push the tag explicitly
git push origin v1.0

# Or push all local tags that the remote does not have
git push --tags
```

Make pushing tags part of the release process checklist: create the tag, push commits, push the tag, create the GitHub Release.

**Error 3: Sensitive data is in the git history even after removing the file.**

Removing `.env` from tracking and adding it to `.gitignore` does not remove the credential data from past commits. Anyone with access to the repository can still read the secret by checking out an earlier commit.

```bash
# Wrong: assuming git rm --cached removes data from history
git rm --cached .env
git commit -m "Remove .env"
# The .env content is still visible in earlier commits

# Correct: treat exposed credentials as compromised immediately
# Step 1: Rotate the credentials (change the API key, password, or token)
# Step 2 (advanced): Remove the file from history if needed
# Use git filter-repo or BFG Repo-Cleaner to purge the file from all commits
```

Whenever credentials are committed to a public repository, rotate them immediately - assume they have been seen by automated credential crawlers that continuously scan public GitHub repositories. Removing from history is a secondary concern after rotation.

---

## 9. Exercises

**Exercise 1:** Create tags `v0.1`, `v0.5`, and `v1.0` on three different commits in your portfolio history. Use meaningful messages for each. Push all three with `git push --tags`. Visit GitHub's Tags page and verify all three appear.

**Exercise 2:** Create a GitHub Release for `v1.0`. Write a release description that lists all five pages the portfolio contains (home, about, projects, contact, skills or testimonials), the technologies used (HTML, CSS, Git, GitHub), and any known limitations. Publish the release and download the auto-generated ZIP to verify it contains a working snapshot.

**Exercise 3:** Intentionally commit a file called `secrets.txt` with the content "password=test123". Then add `secrets.txt` to `.gitignore`. Observe that `git status` still tracks the file. Run `git rm --cached secrets.txt`, commit, and verify the file is gone from `git status` but still exists on disk. Run `git log --oneline` and note that the earlier commit that added the file still exists in history.

---

## 10. Solutions

**Solution for Exercise 1:**

Find three different commit hashes in the history.

```bash
git log --oneline
```

Identify commits at meaningful points: the first commit (initial homepage), a middle commit (after adding the about page), and the current tip (after all pages are complete).

```bash
git tag -a v0.1 <first-hash> -m "Initial portfolio with homepage"
git tag -a v0.5 <middle-hash> -m "Portfolio with homepage and about page"
git tag -a v1.0 -m "Release v1.0: complete portfolio with all pages"
```

The last `git tag -a v1.0` without a hash tags the current `HEAD` commit. Push all tags.

```bash
git push --tags
```

Visit GitHub's Tags page and confirm all three appear, each linking to their respective commit.

**Solution for Exercise 3:**

Create and commit the file.

```bash
echo "password=test123" > secrets.txt
git add secrets.txt
git commit -m "Add secrets (testing gitignore)"
```

Add the pattern to `.gitignore` and observe that it has no immediate effect.

```bash
echo "secrets.txt" >> .gitignore
git status
```

`secrets.txt` still appears as tracked. Remove it from tracking.

```bash
git rm --cached secrets.txt
git add .gitignore
git commit -m "Stop tracking secrets.txt and add gitignore pattern"
git status
```

`secrets.txt` no longer appears in `git status`. Verify it still exists on disk.

```bash
ls secrets.txt
cat secrets.txt
```

The file is present and readable locally. But checking `git log --oneline` reveals the earlier commit "Add secrets (testing gitignore)" is still in the history. The content can still be recovered from that commit with `git show <hash>:secrets.txt`. This demonstrates why credential rotation is the critical first step after any sensitive data exposure.

---

## 11. Understanding Tags, Releases, and .gitignore

Tags and branches are both labels that point to commits, but they behave differently by design. Branches move forward with every new commit because they represent active, ongoing work. Tags are immutable by intention: once you tag `v1.0`, that label always points to the same commit, and Git treats moving a tag as an explicit, rare operation. This immutability is what makes tags reliable for release marking - you can always check out `v1.0` six months later and get exactly the state of the project at that version.

Semantic versioning (`major.minor.patch`) is the dominant convention for version numbers. The major number increments for breaking changes incompatible with previous versions. The minor number increments for new backwards-compatible features. The patch number increments for backwards-compatible bug fixes. For a portfolio site, this distinction is less critical, but learning the convention prepares you for any project that users or systems depend on.

`.gitignore` patterns follow a dialect of glob matching with a few Git-specific rules. Patterns without a slash match anywhere in the repository tree. Patterns with a leading slash are anchored to the root. Trailing slash matches only directories. `!` negates a pattern. The order matters: a later `!` rule can override an earlier ignore rule, but a later ignore rule cannot override an earlier `!` rule. Understanding these rules prevents the common confusion of "why is Git still tracking this file when I added it to `.gitignore`?" - which is almost always caused by the file already being tracked before the pattern was added.

---

## Next Up - Lesson 18

`git tag -a v1.0 -m "message"` creates an annotated tag that permanently marks the current commit. Push tags explicitly with `git push --tags` or `git push origin v1.0`. GitHub Releases build on tags by adding a description, changelog, and automatic source code downloads. `.gitignore` patterns exclude files from tracking using glob-style syntax. The global gitignore (`~/.gitignore_global`) handles personal editor and OS patterns so the project's `.gitignore` stays focused on project-specific files. `git rm --cached <file>` removes an already-tracked file from Git's index without deleting it from disk, making it responsive to `.gitignore` patterns going forward. Sensitive data committed to history must be treated as exposed and the credentials rotated immediately.

Lesson 18 is the final lesson. It reviews everything covered in the course, presents the complete mental model for how all concepts connect, maps out the path to advanced Git topics, and provides a daily workflow reference you can use as a starting template for any new project or team.