# Git Tags Explained: Annotated vs Lightweight, Versioning, and Remote Tags

A user reports a bug in version 1.0.0 of your application, and you need to reproduce it on exactly the code that was shipped. You open `git log` and start scrolling, looking for a commit message that sounds like a release. Was it the commit that updated the changelog, or the one right after it that fixed a typo?

Guessing is expensive here. `main` has moved on for weeks, branches get deleted after merge, and a commit hash on its own tells you nothing about which version it belongs to. Every time you need to compare, patch, or rebuild a released version, you pay that search cost again, and a wrong guess sends you debugging code that was never in production.

Git tags solve this by giving a commit a permanent, human readable name. In this walkthrough you will build a small repository, create annotated and lightweight tags, tag a commit you already made, publish tags to a remote, delete and move them safely, and check out a released version to branch a hotfix from it. Every command below was run locally with Git 2.53.0, and the output is reproduced exactly as the terminal printed it.

## Overview {#overview}

The demo project is a few Markdown files, so nothing distracts from Git itself. Instead of a GitHub repository, you will create a bare repository on your own machine and use it as `origin`, which means every push, delete, and clone in this tutorial is real and verifiable without an account anywhere. Your commit hashes and dates will differ from the ones shown here.

### What You'll Build

- A local repository with four commits and a small set of release tags.
- A bare repository acting as `origin`, with tags pushed, deleted, and force updated on it.
- A fresh clone that proves which tags travel with a repository and which ones go stale.

### What You'll Learn

- Create annotated tags and lightweight tags, and tell them apart by the objects Git stores.
- Tag a commit that was made earlier, without rewriting history.
- List, filter, sort, and inspect tags from the command line.
- Push tags to a remote, delete them on both sides, and understand why moving a published tag is risky.
- Check out a tag, recognize detached HEAD, and branch a hotfix from a released version.

### What You'll Need

- Git 2.28 or later, because `git init -b main` and `git switch` are used throughout.
- Bash on Linux, macOS, or Git Bash on Windows.
- Basic familiarity with staging files and making commits.
- A disposable directory for the experiment. No framework, language runtime, or previous tutorial is required.

## Step 1: Set Up the Demo Repository {#step-1-set-up-the-demo-repository}

Start in a directory where you keep experiments. In the test run this was the vault's `sandbox/` directory. Create the project and initialize Git in it:

```bash
mkdir git-tag-demo
cd git-tag-demo
git init -b main
```

```text
Initialized empty Git repository in /home/gun-gun-priatna/obsidian-vault/sandbox/git-tag-demo/.git/
```

The `-b main` option names the initial branch explicitly, so the branch name does not depend on your Git configuration. The path in the output is the location used for this test run.

```bash
git config user.name "Tutorial Developer"
git config user.email "developer@example.com"
```

These two commands set an example commit identity for this repository only. They print nothing on success. The identity matters more than usual here, because an annotated tag records a tagger name and email inside the tag object.

Create the first file and commit it:

```bash
cat > README.md <<'EOF'
# Release Notes Demo

A small project for practicing Git tags.
EOF
git add README.md
git commit -m "add project readme"
```

```text
[main (root-commit) 6f91c7e] add project readme
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
```

The quoted heredoc writes the file exactly as shown without expanding shell variables, then `git add` stages it and `git commit` records the first snapshot on `main`.

Now add a changelog that represents an early preview of the project:

```bash
cat > CHANGELOG.md <<'EOF'
# Changelog

## 0.9.0

- First preview of the note exporter.
EOF
git add CHANGELOG.md
git commit -m "add changelog for the 0.9.0 preview"
```

```text
[main dffd78e] add changelog for the 0.9.0 preview
 1 file changed, 5 insertions(+)
 create mode 100644 CHANGELOG.md
```

This commit is the state of the project at its 0.9.0 preview. You will come back and tag it in Step 4, which is a realistic situation: the release happened before anyone thought about tagging it.

Add two more commits that bring the project to its 1.0.0 state:

```bash
cat > export.md <<'EOF'
# Export Formats

- Markdown
- HTML
EOF
git add export.md
git commit -m "document the supported export formats"
```

```text
[main 3c74c64] document the supported export formats
 1 file changed, 4 insertions(+)
 create mode 100644 export.md
```

```bash
cat > CHANGELOG.md <<'EOF'
# Changelog

## 1.0.0

- Stable export to Markdown and HTML.

## 0.9.0

- First preview of the note exporter.
EOF
git add CHANGELOG.md
git commit -m "record the 1.0.0 release in the changelog"
```

```text
[main 77a03f2] record the 1.0.0 release in the changelog
 1 file changed, 4 insertions(+)
```

The second command overwrites `CHANGELOG.md` with a new 1.0.0 section on top, so Git records a modification rather than a new file. That is why the output mentions no `create mode` line this time.

Confirm the history and the current tag list:

```bash
git log --oneline
git tag
```

```text
77a03f2 record the 1.0.0 release in the changelog
3c74c64 document the supported export formats
dffd78e add changelog for the 0.9.0 preview
6f91c7e add project readme
```

`git log --oneline` prints four commits, and `git tag` prints nothing at all, because the repository has no tags yet. An empty listing is the normal output of `git tag` in a fresh repository, not an error.

## Step 2: Create Your First Annotated Tag {#step-2-create-your-first-annotated-tag}

The tip of `main` is the state you want to call version 1.0.0. An annotated tag is the right tool for a release, because it stores a message, a tagger, and a timestamp as a real object in the Git database.

```bash
git tag -a v1.0.0 -m "Release 1.0.0: stable Markdown and HTML export"
```

The `-a` flag asks for an annotated tag and `-m` supplies its message, exactly like committing. Without `-m`, Git opens your editor so you can write a longer release note. The command prints nothing on success.

```bash
git tag
```

```text
v1.0.0
```

The tag now exists locally. Note that tagging did not create a commit and did not change your working directory; it only attached a name to the commit that `HEAD` pointed at.

```bash
git show v1.0.0
```

```text
tag v1.0.0
Tagger: Tutorial Developer <developer@example.com>
Date:   Sat Sep 19 12:35:24 2026 +0700

Release 1.0.0: stable Markdown and HTML export

commit 77a03f2dc48a2840740930e835cb7505424dd430
Author: Tutorial Developer <developer@example.com>
Date:   Sat Sep 19 12:35:16 2026 +0700

    record the 1.0.0 release in the changelog

diff --git a/CHANGELOG.md b/CHANGELOG.md
index ae25634..b4fa24c 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 1.0.0
+
+- Stable export to Markdown and HTML.
+
 ## 0.9.0
 
 - First preview of the note exporter.
```

Read this output in two halves. The first half is the tag itself, with its own tagger, date, and message. The second half is the commit the tag points to, shown with its diff. That first half is what makes an annotated tag worth using: months later, the tag still answers who cut the release and when.

## Step 3: Add a Lightweight Tag and Compare It {#step-3-add-a-lightweight-tag-and-compare-it}

Git has a second kind of tag that stores no metadata at all. Creating one takes the same command without `-a`, and comparing the two is the fastest way to understand the difference.

```bash
git tag v1.0.0-lw
```

This creates a lightweight tag on the same commit. The name ends in `-lw` only so you can tell the two apart in this experiment; it is not a convention you should copy.

```bash
git tag
```

```text
v1.0.0
v1.0.0-lw
```

Both names appear in the listing, which is the point: from the outside, a lightweight tag looks just like an annotated one. The difference is in what Git stored.

```bash
git cat-file -t v1.0.0
git cat-file -t v1.0.0-lw
```

```text
tag
commit
```

`git cat-file -t` prints the type of the object a name resolves to. The annotated tag resolves to a `tag` object, which is a real object holding the message and tagger. The lightweight tag resolves straight to a `commit`, because it is nothing more than a file under `.git/refs/tags/` containing a commit hash.

```bash
git show v1.0.0-lw | head -12
```

```text
commit 77a03f2dc48a2840740930e835cb7505424dd430
Author: Tutorial Developer <developer@example.com>
Date:   Sat Sep 19 12:35:16 2026 +0700

    record the 1.0.0 release in the changelog

diff --git a/CHANGELOG.md b/CHANGELOG.md
index ae25634..b4fa24c 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
```

Compare this with the output in Step 2. There is no tagger block and no tag message, because there is no tag object to print. `git show` jumps directly to the commit. The `head -12` part only trims the output for readability.

## Step 4: Tag a Commit You Already Made {#step-4-tag-a-commit-you-already-made}

Releases are often tagged after the fact, once someone notices the tag is missing. Tagging an older commit is a normal operation and does not rewrite history, because a tag is just a name pointing at a commit that already exists.

First find the commit you want to name:

```bash
git log --oneline
```

```text
77a03f2 record the 1.0.0 release in the changelog
3c74c64 document the supported export formats
dffd78e add changelog for the 0.9.0 preview
6f91c7e add project readme
```

The commit `dffd78e` is the one where the changelog described the 0.9.0 preview, so that is the 0.9.0 release state. Use your own hash from this listing in the next command.

```bash
git tag -a v0.9.0 dffd78e -m "Release 0.9.0: first exporter preview"
```

Passing a commit hash after the tag name tells Git where to attach the tag. Without that argument, Git would have tagged `HEAD` instead, which is the wrong commit here.

```bash
git tag
git log --oneline --decorate
```

```text
v0.9.0
v1.0.0
v1.0.0-lw
```

```text
77a03f2 (HEAD -> main, tag: v1.0.0-lw, tag: v1.0.0) record the 1.0.0 release in the changelog
3c74c64 document the supported export formats
dffd78e (tag: v0.9.0) add changelog for the 0.9.0 preview
6f91c7e add project readme
```

The `--decorate` option prints refs next to the commits they point at, and it makes the whole model visible in one screen. Two tags and the branch `main` sit on `77a03f2`, while `v0.9.0` sits two commits back. Nothing about the commits themselves changed when you tagged them.

## Step 5: List, Filter, and Inspect Tags {#step-5-list-filter-and-inspect-tags}

A real project accumulates dozens or hundreds of tags, so plain `git tag` stops being useful quickly. These options are the ones worth remembering.

```bash
git tag -l "v1.*"
```

```text
v1.0.0
v1.0.0-lw
```

The `-l` option filters by a shell style pattern, which is how you pull one release line out of a long list. Quote the pattern so your shell passes the asterisk to Git instead of expanding it against filenames.

```bash
git tag --sort=-v:refname
```

```text
v1.0.0-lw
v1.0.0
v0.9.0
```

By default Git sorts tags alphabetically, which puts `v1.10.0` before `v1.9.0` and confuses everyone. The `v:refname` sort key understands version numbers, and the leading minus reverses the order so the newest release is on the first line.

```bash
git tag -n
```

```text
v0.9.0          Release 0.9.0: first exporter preview
v1.0.0          Release 1.0.0: stable Markdown and HTML export
v1.0.0-lw       record the 1.0.0 release in the changelog
```

`git tag -n` prints each tag with its annotation, and this output shows the practical cost of lightweight tags. The two annotated tags show their release messages. The lightweight tag has no message of its own, so Git falls back to the subject of the commit it points at, which says nothing about the release.

```bash
git show v0.9.0 --stat
```

```text
tag v0.9.0
Tagger: Tutorial Developer <developer@example.com>
Date:   Sat Sep 19 12:35:38 2026 +0700

Release 0.9.0: first exporter preview

commit dffd78ecd0c218868e41db15a680d20c27ae7419
Author: Tutorial Developer <developer@example.com>
Date:   Sat Sep 19 12:35:10 2026 +0700

    add changelog for the 0.9.0 preview

 CHANGELOG.md | 5 +++++
 1 file changed, 5 insertions(+)
```

Adding `--stat` replaces the full diff with a summary of changed files, which is far more readable when a release commit touches many files. The tagger date here is later than the commit date, and that is expected: the tag was created in Step 4, long after the commit was made.

## Step 6: Publish Tags to a Remote {#step-6-publish-tags-to-a-remote}

Tags are local until you push them, and `git push` alone does not carry them. To see this properly you need a remote, so create a bare repository next to your project and use it as `origin`. A bare repository has no working directory, which is exactly what a server side repository looks like.

```bash
cd ..
git init --bare -b main git-tag-demo-origin.git
cd git-tag-demo
```

```text
Initialized empty Git repository in /home/gun-gun-priatna/obsidian-vault/sandbox/git-tag-demo-origin.git/
```

The `--bare` flag creates the repository without a checkout, and `-b main` sets its initial branch name so it matches your project. Everything you do against this repository behaves like a real remote, including rejections and forced updates.

```bash
git remote add origin ../git-tag-demo-origin.git
git push -u origin main
```

```text
To ../git-tag-demo-origin.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

`git remote add` registers the bare repository under the name `origin`, and `git push -u` publishes `main` and sets up tracking. Now check whether your three tags went with it:

```bash
git ls-remote --tags origin
```

This command prints nothing. `git ls-remote` asks the remote which refs it has, and the empty result proves the point that trips people up in real projects: pushing a branch does not push tags. The release you just published has no version marker on the server.

```bash
git push origin v1.0.0
```

```text
To ../git-tag-demo-origin.git
 * [new tag]         v1.0.0 -> v1.0.0
```

Pushing a single tag by name is the safest habit, because you publish exactly the release you intend to publish.

```bash
git ls-remote --tags origin
```

```text
5caa4e373bee1eddfce1fb9c1e09e640ffa47518	refs/tags/v1.0.0
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0^{}
```

The annotated tag produces two lines. The first is the hash of the tag object itself, and the second, marked with `^{}`, is the commit that tag object finally resolves to. That second hash matches commit `77a03f2` from Step 1, which confirms the remote tag points at the right snapshot.

```bash
git push --tags origin
```

```text
To ../git-tag-demo-origin.git
 * [new tag]         v0.9.0 -> v0.9.0
 * [new tag]         v1.0.0-lw -> v1.0.0-lw
```

`--tags` pushes every local tag that the remote does not have yet. It is convenient, and it is also how experiment tags and personal markers leak into a shared repository, which is exactly what happened here with `v1.0.0-lw`.

```bash
git ls-remote --tags origin
```

```text
442fd5d38f8c708655e57211e8df922613fd893c	refs/tags/v0.9.0
dffd78ecd0c218868e41db15a680d20c27ae7419	refs/tags/v0.9.0^{}
5caa4e373bee1eddfce1fb9c1e09e640ffa47518	refs/tags/v1.0.0
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0^{}
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0-lw
```

Compare the shapes of these entries. The two annotated tags each produce a pair of lines, while the lightweight tag `v1.0.0-lw` produces a single line that points straight at the commit. The difference from Step 3 survives the trip to the remote.

## Step 7: Delete and Replace a Tag {#step-7-delete-and-replace-a-tag}

The experiment tag does not belong on the remote, so remove it. Deleting a tag is two separate operations, one local and one remote, and forgetting the second one is why deleted tags keep coming back for the rest of the team.

```bash
git tag -d v1.0.0-lw
```

```text
Deleted tag 'v1.0.0-lw' (was 77a03f2)
```

The `-d` flag deletes the local tag and reports the commit it pointed at, which is a useful safety net if you delete the wrong name.

```bash
git tag
git ls-remote --tags origin
```

```text
v0.9.0
v1.0.0
```

```text
442fd5d38f8c708655e57211e8df922613fd893c	refs/tags/v0.9.0
dffd78ecd0c218868e41db15a680d20c27ae7419	refs/tags/v0.9.0^{}
5caa4e373bee1eddfce1fb9c1e09e640ffa47518	refs/tags/v1.0.0
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0^{}
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0-lw
```

The tag is gone locally but still present on the remote, and anyone who clones or fetches will pull it back into their repository. Delete it on the remote as well:

```bash
git push origin --delete v1.0.0-lw
git ls-remote --tags origin
```

```text
To ../git-tag-demo-origin.git
 - [deleted]         v1.0.0-lw
```

```text
442fd5d38f8c708655e57211e8df922613fd893c	refs/tags/v0.9.0
dffd78ecd0c218868e41db15a680d20c27ae7419	refs/tags/v0.9.0^{}
5caa4e373bee1eddfce1fb9c1e09e640ffa47518	refs/tags/v1.0.0
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0^{}
```

Now both sides agree. Next, see what happens when you try to reuse a tag name that already exists:

```bash
git tag -a v1.0.0 -m "Release 1.0.0 again"
```

```text
fatal: tag 'v1.0.0' already exists
```

Git refuses, and that refusal is a feature. A release tag is a promise that a given version always means the same code, so Git makes you be explicit before breaking it.

Some projects still need a moving tag, for example a `latest` marker that always follows the newest build. Create one on an older commit first, so you can watch it move:

```bash
git tag latest dffd78e
git push origin latest
```

```text
To ../git-tag-demo-origin.git
 * [new tag]         latest -> latest
```

This lightweight tag now points at the 0.9.0 commit on both sides. Move it to the current commit:

```bash
git tag -f latest
```

```text
Updated tag 'latest' (was dffd78e)
```

The `-f` flag overwrites an existing tag locally, and Git reports the commit it moved away from. Try to publish that move the normal way:

```bash
git push origin latest
```

```text
To ../git-tag-demo-origin.git
 ! [rejected]        latest -> latest (already exists)
error: failed to push some refs to '../git-tag-demo-origin.git'
hint: Updates were rejected because the tag already exists in the remote.
```

The remote rejects it. Unlike branches, tags are not fast forwarded automatically, so a tag that already exists on the server will not be quietly repointed by an ordinary push.

```bash
git push --force origin latest
git ls-remote --tags origin
```

```text
To ../git-tag-demo-origin.git
 + dffd78e...77a03f2 latest -> latest (forced update)
```

```text
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/latest
442fd5d38f8c708655e57211e8df922613fd893c	refs/tags/v0.9.0
dffd78ecd0c218868e41db15a680d20c27ae7419	refs/tags/v0.9.0^{}
5caa4e373bee1eddfce1fb9c1e09e640ffa47518	refs/tags/v1.0.0
77a03f2dc48a2840740930e835cb7505424dd430	refs/tags/v1.0.0^{}
```

The forced push moves the remote `latest` from `dffd78e` to `77a03f2`, and the plus sign in the output marks it as a non fast forward update. Keep this for deliberately moving markers only; the section on moving published tags later in this article shows what it does to people who already cloned.

## Step 8: Check Out a Tag and Branch From It {#step-8-check-out-a-tag-and-branch-from-it}

This is the payoff for tagging at all: going back to a released version without hunting for its commit hash.

```bash
git checkout v0.9.0
```

```text
Note: switching to 'v0.9.0'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at dffd78e add changelog for the 0.9.0 preview
```

That long message is not an error. A tag names a commit rather than a branch, so there is no branch for `HEAD` to follow and Git detaches it. Your files are now exactly as they were at 0.9.0.

```bash
git status
ls
```

```text
HEAD detached at v0.9.0
nothing to commit, working tree clean
```

```text
CHANGELOG.md
README.md
```

The status line confirms where you are, and the directory listing is the real evidence: `export.md` is missing, because it did not exist yet at version 0.9.0. You are looking at the released code, not at `main`.

In detached HEAD state any commit you make belongs to no branch, so if you need to fix something in a released version, start a branch from the tag:

```bash
git switch -c hotfix/0.9.1 v0.9.0
git status
```

```text
Switched to a new branch 'hotfix/0.9.1'
```

```text
On branch hotfix/0.9.1
nothing to commit, working tree clean
```

`git switch -c <name> <tag>` creates a branch at the tagged commit and moves onto it in one step, which is the normal way to start a patch release for a version that has already shipped. Commits you make here are safely attached to `hotfix/0.9.1`.

```bash
git switch main
ls
```

```text
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```

```text
CHANGELOG.md
README.md
export.md
```

Switching back to `main` restores the current state of the project, and `export.md` reappears. The tag never moved during any of this, because checking out a tag reads it and does not change it.

## Step 9: Try It Out {#step-9-try-it-out}

With the tags in place, try the three things tags make easy. Start by adding a commit after the 1.0.0 release, so the repository has work that is not part of any version yet:

```bash
cat >> export.md <<'EOF'
- CSV
EOF
git add export.md
git commit -m "add csv to the export formats"
```

```text
[main a247c02] add csv to the export formats
 1 file changed, 1 insertion(+)
```

The `>>` operator appends to the existing file instead of replacing it, which keeps the earlier lines intact.

### Scenario 1: Ask Git Which Version You Are On

```bash
git describe --tags
```

```text
v1.0.0-1-ga247c02
```

Read the answer in three parts: the most recent tag reachable from `HEAD` is `v1.0.0`, you are `1` commit past it, and the current commit is `a247c02`, with `g` marking it as a Git hash. This string is a common source for build version numbers, because it is unique and readable at the same time. When `HEAD` sits exactly on a tag, `git describe` prints just the tag name.

### Scenario 2: See What Went Into a Release

```bash
git log v0.9.0..v1.0.0 --oneline
```

```text
77a03f2 record the 1.0.0 release in the changelog
3c74c64 document the supported export formats
```

The `v0.9.0..v1.0.0` range means the commits reachable from `v1.0.0` but not from `v0.9.0`, which is exactly the set of changes released in 1.0.0. This is where release notes come from, and it works only because both versions carry tags.

```bash
git diff --stat v0.9.0 v1.0.0
```

```text
 CHANGELOG.md | 4 ++++
 export.md    | 4 ++++
 2 files changed, 8 insertions(+)
```

Tags can be used anywhere a commit is expected, so `git diff` accepts two tag names and summarizes the file level difference between two published versions.

### Scenario 3: Prove Tags Travel With a Clone

Publish the new commit, then clone the bare repository into a separate directory:

```bash
git push origin main
```

```text
To ../git-tag-demo-origin.git
   77a03f2..a247c02  main -> main
```

```bash
cd ..
git clone git-tag-demo-origin.git git-tag-demo-clone
cd git-tag-demo-clone
git tag
```

```text
Cloning into 'git-tag-demo-clone'...
done.
```

```text
latest
v0.9.0
v1.0.0
```

A clone downloads every tag the remote has, without any extra flag. The tag `v1.0.0-lw` is absent because you deleted it from the remote in Step 7, which confirms that the cleanup actually worked.

```bash
git describe --tags
```

```text
v1.0.0-1-ga247c02
```

The fresh clone describes itself exactly like your working repository does. Anyone on the team, and any build server, can now answer the question this article started with: which commit is version 1.0.0.

## How Git Stores Tags {#how-git-stores-tags}

Tags feel special, but their storage is plain. Return to your working repository and look at the refs directly.

```bash
cd ../git-tag-demo
git show-ref --tags
```

```text
77a03f2dc48a2840740930e835cb7505424dd430 refs/tags/latest
442fd5d38f8c708655e57211e8df922613fd893c refs/tags/v0.9.0
5caa4e373bee1eddfce1fb9c1e09e640ffa47518 refs/tags/v1.0.0
```

Every tag is a ref under `refs/tags/`, in the same way that every branch is a ref under `refs/heads/`. The one meaningful difference is that Git never moves a tag ref on its own, while it moves a branch ref on every commit.

```bash
git cat-file -p v1.0.0
```

```text
object 77a03f2dc48a2840740930e835cb7505424dd430
type commit
tag v1.0.0
tagger Tutorial Developer <developer@example.com> 1789796124 +0700

Release 1.0.0: stable Markdown and HTML export
```

`git cat-file -p` prints an object in readable form, and this is the annotated tag object in full. Notice that the hash in `refs/tags/v1.0.0` above is `5caa4e3`, not the commit hash: the ref points at this tag object, and the tag object points at the commit. That indirection is what lets a tag carry its own message and author.

```bash
git cat-file -p latest | head -5
```

```text
tree 65fb658e41cf61ad1fd221483d97334b1756b5fa
parent 3c74c64454a3f6b8af7b332af5ef210701c9c14d
author Tutorial Developer <developer@example.com> 1789796116 +0700
committer Tutorial Developer <developer@example.com> 1789796116 +0700
```

The lightweight tag has no object of its own, so printing it prints a commit. This single fact explains every difference you saw earlier: the missing tagger in `git show`, the commit subject in `git tag -n`, and the single line in `git ls-remote`.

## Annotated vs Lightweight Tags {#annotated-vs-lightweight-tags}

Both kinds work everywhere a commit reference is accepted, so the choice is about what you want recorded, not about what Git can do.

- **Use an annotated tag for anything you publish.** Releases, deployments, and audit points benefit from a stored message, tagger, and date, and tools such as `git describe` prefer them by default.
- **Use a lightweight tag for private, temporary markers.** A quick bookmark before a risky rebase costs nothing and needs no metadata, and you can delete it with `git tag -d` when you are done.
- **Prefer annotated tags when the tag might be signed later.** Signing with `git tag -s` requires a tag object, so a lightweight tag cannot carry a signature.
- **Do not rely on the name to tell them apart.** As Step 3 showed, `git tag` lists both identically. `git cat-file -t <name>` is the reliable check.

## Naming Tags with Semantic Versioning {#naming-tags-with-semantic-versioning}

Tag names are free text, which means the discipline has to come from you. Semantic versioning, written as MAJOR.MINOR.PATCH, is the convention most tooling already understands: raise PATCH for fixes, MINOR for backward compatible features, and MAJOR for breaking changes. Pre-release versions add a suffix such as `-rc.1`.

```bash
git tag -a v1.1.0-rc.1 -m "Release candidate for 1.1.0"
git tag --sort=-v:refname
```

```text
v1.1.0-rc.1
v1.0.0
v0.9.0
latest
```

The version sort understands the numeric parts and places the release candidate above 1.0.0, while `latest` falls to the bottom because it carries no version number at all. That ordering is a practical argument for the `v` prefix and for keeping non version markers out of your release naming scheme.

```bash
git tag -l "v1.1.*"
```

```text
v1.1.0-rc.1
```

Consistent names also make filtering trivial, which matters once a repository holds hundreds of tags. A pattern like this is what release scripts use to find every candidate of an upcoming version.

## Why Moving a Published Tag Is Risky {#why-moving-a-published-tag-is-risky}

Step 7 showed that a forced push can move a tag on the remote. What it could not show yet is what that does to a repository somebody already cloned. You have such a clone now, so move `latest` again and watch the two repositories disagree.

```bash
git tag -f latest
git push --force origin latest
```

```text
Updated tag 'latest' (was 77a03f2)
```

```text
To ../git-tag-demo-origin.git
 + 77a03f2...a247c02 latest -> latest (forced update)
```

The tag moves from the 1.0.0 commit to the newest commit, locally and then on the remote.

```bash
git rev-parse latest
```

```text
a247c0201df28ee3f2439347b8b1ca83e8b29766
```

`git rev-parse` prints the commit a name resolves to, so your local `latest` now points at the newest commit, and so does the remote. Check the clone:

```bash
cd ../git-tag-demo-clone
git rev-parse latest
```

```text
77a03f2dc48a2840740930e835cb7505424dd430
```

The clone still resolves `latest` to the old commit. Nothing is broken there and no warning appeared, which is precisely the danger: two developers running the same command against the same tag name get different code.

```bash
git fetch --tags
git rev-parse latest
```

```text
From /home/gun-gun-priatna/obsidian-vault/sandbox/git-tag-demo-origin
 ! [rejected]        latest     -> latest  (would clobber existing tag)
```

```text
77a03f2dc48a2840740930e835cb7505424dd430
```

Even an explicit `git fetch --tags` refuses to update it. Git protects local tags from being silently replaced, so the stale value survives a normal fetch and keeps surviving until somebody notices.

```bash
git fetch --tags --force
git rev-parse latest
```

```text
From /home/gun-gun-priatna/obsidian-vault/sandbox/git-tag-demo-origin
 t [tag update]      latest     -> latest
```

```text
a247c0201df28ee3f2439347b8b1ca83e8b29766
```

Only `--force` accepts the new value, and now the clone agrees with the remote again. The lesson for release tags is simple: once a version tag is pushed, treat it as immutable and ship a new version number instead of moving the old one. If you need a name that moves, make that explicit with a marker such as `latest` or `nightly`, and make sure everyone knows it is not a release.

## Conclusion {#conclusion}

Tags cost one command and repay it every time somebody asks which code shipped. You created them, published them, deleted them, moved one on purpose, and went back to a released version to branch a hotfix from it, all against a real remote.

- **Annotated tags are the default for releases.** `git tag -a` stores a message, tagger, and date as a real object, so the tag explains itself long after everyone forgot the details.
- **Lightweight tags are just refs.** They point straight at a commit with no metadata, which makes them fine as private bookmarks and weak as release markers.
- **Tagging is not committing.** Tags name commits that already exist, so you can tag an old commit with `git tag -a <name> <hash>` without rewriting any history.
- **Tags do not travel with `git push`.** Publish them explicitly with `git push origin <tag>`, and verify the result with `git ls-remote --tags origin`.
- **Deleting a tag is two operations.** `git tag -d` removes it locally and `git push origin --delete <tag>` removes it on the remote; skipping the second brings the tag back on the next fetch.
- **Checking out a tag detaches HEAD.** That is expected, and `git switch -c <branch> <tag>` is the way to turn a released version into a branch you can commit on.
- **A published tag should never move.** Clones keep the old value even through `git fetch --tags`, so release a new version instead, and reserve moving names like `latest` for markers everyone recognizes as mutable.
- **Consistent version names make tags searchable.** Semantic versioning with a `v` prefix works with `git tag -l "v1.*"` and `--sort=-v:refname`, which is what release tooling relies on.
