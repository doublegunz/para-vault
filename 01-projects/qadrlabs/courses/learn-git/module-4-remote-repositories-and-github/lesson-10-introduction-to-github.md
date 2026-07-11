## 1. Before You Begin

Everything so far has been local: your repository lives entirely on your computer. But software development is fundamentally collaborative. You need a way to share your code with teammates, back it up in case your machine fails, and let others view or contribute to your work. **GitHub** is the most popular platform for hosting Git repositories online. It stores your repository on its servers and adds collaboration features like pull requests, issues, code review, and project boards on top of Git's core version control functionality.

This lesson covers creating a GitHub account, setting up SSH keys for secure authentication, creating a remote repository, and connecting your local portfolio project to GitHub. By the end, your code will be backed up online, publicly visible, and accessible from any machine in the world.

### What You'll Build

You will push the portfolio project you have been building since Lesson 3 to GitHub, making the full commit history - every snapshot from every lesson - available online at a public URL.

### What You'll Learn

- ✅ Creating a GitHub account
- ✅ Setting up SSH keys for password-free authentication
- ✅ Creating a repository on GitHub
- ✅ Adding a remote with `git remote add`
- ✅ Understanding the `origin` convention
- ✅ Pushing your first code with `git push`

### What You'll Need

- Lesson 9 completed with the portfolio project
- An internet connection
- An email address for GitHub registration

---

## 2. Create a GitHub Account

A GitHub account is free and required to create repositories, push code, and collaborate with others. If you already have an account, skip this section and proceed to Section 3.

### Step 1: Sign Up

Go to `https://github.com` in your browser and click "Sign up." Follow the registration flow by entering your email address, choosing a username, and creating a password. Select the free plan when prompted about pricing.

Your username becomes the first part of your profile URL (`github.com/yourusername`) and appears on every commit you push to GitHub. Choose something professional and memorable, since it will be visible to future employers and collaborators.

---

## 3. Set Up SSH Keys

SSH keys provide secure, cryptographic authentication between your machine and GitHub. Instead of typing a username and password for every `git push` or `git pull`, your system presents a private key that matches the public key registered on GitHub. The handshake happens automatically in the background.

The key pair consists of two files: a private key that stays on your machine and must never be shared, and a public key that you upload to GitHub. GitHub uses the public key to verify that you hold the corresponding private key, without ever seeing the private key itself.

### Step 1: Check for Existing Keys

Before generating a new key pair, check whether one already exists on your machine.

```bash
ls -la ~/.ssh
```

If you see files named `id_ed25519` and `id_ed25519.pub`, you already have an Ed25519 key pair. Skip to Step 3 to add the existing public key to GitHub. If the directory is empty or does not exist, proceed to Step 2.

### Step 2: Generate a New Key

Create a new Ed25519 key pair, which is the algorithm GitHub recommends for new keys.

```bash
ssh-keygen -t ed25519 -C "budi@example.com"
```

Replace the email address with the one you used to register on GitHub. The `-t ed25519` flag specifies the key algorithm. The `-C` flag adds a comment (your email) to the public key, making it identifiable in GitHub's key list. Press Enter three times to accept the default file location (`~/.ssh/id_ed25519`) and skip setting a passphrase (or set one for additional security if you prefer).

The command creates two files: `~/.ssh/id_ed25519` (the private key - never share or move this file) and `~/.ssh/id_ed25519.pub` (the public key - this is the file you upload to GitHub).

### Step 3: Add the Public Key to GitHub

Read the public key file so you can copy it to your clipboard.

```bash
cat ~/.ssh/id_ed25519.pub
```

The output is a single long line starting with `ssh-ed25519` followed by a string of characters and then your email comment. Select and copy the entire line. Now go to GitHub: click your profile picture in the top right, select "Settings," then click "SSH and GPG keys" in the left sidebar, then "New SSH key." Give the key a descriptive title (such as "My Laptop" or "Work Machine"), paste the copied key into the "Key" field, and click "Add SSH key."

### Step 4: Test the SSH Connection

Verify that GitHub recognizes your key by attempting an SSH connection.

```bash
ssh -T git@github.com
```

The first time you connect to a new host, SSH asks you to confirm the host's fingerprint. Type `yes` and press Enter. You should then see a message like: "Hi yourusername! You've successfully authenticated, but GitHub does not provide shell access." This message confirms the SSH handshake succeeded and your key is correctly configured. The "does not provide shell access" part is expected - GitHub allows Git operations over SSH but does not give you an interactive shell.

---

## 4. Create a Remote Repository

A remote repository is the GitHub-hosted copy of your project. It starts empty and receives your local history when you push. Creating it on GitHub gives you the URL that your local Git needs to connect to.

### Step 1: Create the Repository on GitHub

Navigate to `https://github.com/new` in your browser to open the new repository form. Fill in the repository name as `portfolio`. Leave the visibility set to Public. Crucially, do not check "Add a README file," "Add .gitignore," or "Choose a license" - because you already have a local repo with a full commit history, initializing GitHub's copy with any files would create a conflict. Click "Create repository."

GitHub shows a page with setup instructions for several scenarios. Look for the section titled "push an existing repository from the command line" - this is the one you need.

### Step 2: Connect Your Local Repository

Navigate to the portfolio project in your terminal and add the GitHub repository as a remote named `origin`.

```bash
cd portfolio
git remote add origin git@github.com:yourusername/portfolio.git
```

Replace `yourusername` with your actual GitHub username. `git remote add` registers a remote connection and stores it in `.git/config`. The name `origin` is a convention: it is not required by Git, but it is universally expected by the entire Git community. Deviating from it would confuse every collaborator who works with your repository. Verify the remote was registered correctly.

```bash
git remote -v
```

You should see:

```
origin  git@github.com:yourusername/portfolio.git (fetch)
origin  git@github.com:yourusername/portfolio.git (push)
```

Git stores separate URLs for fetching and pushing. In typical setups both are the same, but they can differ in specialized workflows. Confirming both URLs are correct before the first push prevents pushing to the wrong repository.

### Step 3: Push Your Code to GitHub

Upload your entire local history to the remote repository.

```bash
git push -u origin main
```

The `-u` flag (short for `--set-upstream`) creates a permanent tracking relationship between your local `main` branch and `origin/main` on GitHub. This means that after this first push, you can run `git push` and `git pull` without specifying the remote name and branch name every time - Git will already know where to send and receive changes. You only need `-u` on the first push. All subsequent pushes use plain `git push`.

You should see output showing the progress of the transfer, ending with a success message and a URL to your repository.

---

## 5. Verify the Push

After the first push, verify that everything arrived correctly on GitHub before considering the lesson complete.

### Step 1: Visit Your Repository on GitHub

Open `https://github.com/yourusername/portfolio` in your browser. You should see all your project files listed: `index.html`, `about.html`, `contact.html`, `style.css`, `README.md`, and any others you created during the exercises. The repository shows the most recent commit message next to each file.

### Step 2: Verify the Commit History

Click "Commits" on the GitHub repository page (the number above the file list). You should see every commit you made locally across all the lessons, with the correct messages, author names, and timestamps. The complete history was transferred from your machine to GitHub in a single push.

### Step 3: Verify the Remote Branch Locally

Confirm that the local repository now knows about the remote branch.

```bash
git log --oneline
```

The most recent commit should now show `(HEAD -> main, origin/main)`, indicating that both your local `main` branch and the remote `origin/main` branch are pointing at the same commit. When these two labels match, your local history and GitHub's history are synchronized.

---

## 6. Fix the Errors in Your Code

These are the most common problems when setting up GitHub and pushing for the first time.

**Error 1: Permission denied (publickey).**

The push fails with an authentication error because GitHub does not recognize the SSH key being presented. This happens when the key was not added to GitHub, the SSH agent is not running, or the wrong key is being used.

```bash
# Wrong: pushing before SSH is configured correctly
git push -u origin main
# git@github.com: Permission denied (publickey).
# fatal: Could not read from remote repository.

# Correct: verify SSH works first, then push
ssh -T git@github.com
# Hi yourusername! You've successfully authenticated...
git push -u origin main
```

If `ssh -T git@github.com` also fails, re-run the SSH setup steps: check that `~/.ssh/id_ed25519.pub` exists, that its contents are added to GitHub Settings under "SSH and GPG keys," and that you used the SSH URL (starting with `git@github.com`) rather than the HTTPS URL.

**Error 2: Remote `origin` already exists.**

Running `git remote add origin` a second time on the same repository produces an error because a remote named `origin` was already registered.

```bash
# Wrong: adding origin when it already exists
git remote add origin git@github.com:user/repo.git
# error: remote origin already exists.

# Correct: update the URL of the existing remote instead
git remote set-url origin git@github.com:user/correct-repo.git
git remote -v
```

`git remote set-url` changes the URL stored for an existing remote without removing and re-creating it. After running it, verify with `git remote -v` that the correct URL is now listed.

**Error 3: Rejected push because GitHub's copy has commits your local copy does not.**

This happens when you initialized GitHub's repository with a README or other file (by checking the "Add a README file" box during creation), creating a commit on GitHub that is not in your local history.

```bash
# Wrong: trying to push after a divergence was created during repo setup
git push -u origin main
# ! [rejected]        main -> main (fetch first)
# error: failed to push some refs

# Correct: pull the remote's commit first, then push
git pull origin main --allow-unrelated-histories
git push -u origin main
```

The `--allow-unrelated-histories` flag allows Git to merge two histories that have no common ancestor. After pulling, resolve any conflicts, then push the merged result. This situation is entirely avoidable by not initializing GitHub's repository with any files when you already have local history.

---

## 7. Exercises

**Exercise 1:** Add a `README.md` file (or update the existing one) with a short description of the portfolio project, your name, and a list of technologies used. Stage, commit, and push the change. Visit your GitHub repository page and verify the README renders below the file list.

**Exercise 2:** Navigate the GitHub interface: click on `index.html` to view its contents. Click the "History" button to see which commits modified that file. Click a specific commit to see the diff view showing exactly what changed.

**Exercise 3:** Try connecting via HTTPS instead of SSH. Run `git remote set-url origin https://github.com/yourusername/portfolio.git`. Attempt a push (GitHub will require a personal access token instead of a password). After testing, switch back to the SSH URL with `git remote set-url origin git@github.com:yourusername/portfolio.git`.

---

## 8. Solutions

**Solution for Exercise 1:**

Create or update `README.md` with the following content (adjust the details to your own).

```markdown
# My Portfolio

A personal portfolio website built while learning Git and version control.

**Technologies:** HTML, CSS

**Author:** Budi Santoso
```

Stage, commit, and push the file.

```bash
git add README.md
git commit -m "Update README with project description and author"
git push
```

Because you set the upstream with `-u` during the initial push, `git push` (without arguments) knows to send local `main` to `origin/main`. Visit `https://github.com/yourusername/portfolio` and confirm the README text appears below the file list at the bottom of the repository page. GitHub automatically renders Markdown, so your headings and bold text will be formatted.

**Solution for Exercise 3:**

Change the remote URL to HTTPS.

```bash
git remote set-url origin https://github.com/yourusername/portfolio.git
git remote -v
```

Attempt a push. GitHub no longer accepts your account password for HTTPS authentication. Instead, generate a personal access token: go to GitHub Settings, then "Developer settings," then "Personal access tokens," then "Tokens (classic)," and click "Generate new token." Give it a name, set an expiry, and check the "repo" scope. Copy the token and use it as the password when Git prompts you. After testing, switch back to SSH.

```bash
git remote set-url origin git@github.com:yourusername/portfolio.git
git remote -v
```

Confirm the SSH URL is restored.

---

## 9. Understanding Remotes

A remote is a named bookmark pointing to another copy of your repository. When you run `git remote add origin <url>`, you are telling Git: "There is another version of this repository at this URL. I want to refer to it as `origin`." The name `origin` is a universal convention recognized by every Git tool and every collaborator you will work with. You could name it anything, but `origin` is what every developer expects.

Your local repository and the remote are independent. Commits you make locally do not automatically appear on GitHub. You must explicitly `push` them. Changes made on GitHub by teammates or through the browser interface do not automatically appear locally. You must explicitly `pull` them. This explicit synchronization is a deliberate design choice: it lets you work completely offline for hours or days, then sync everything at once. No network connection is needed for committing, branching, merging, or viewing history.

The `-u` flag on the first push creates a tracking relationship stored in `.git/config` under the branch's configuration. After this relationship exists, Git knows that your local `main` corresponds to `origin/main`. This is why `git push` and `git pull` without arguments work correctly: Git reads the tracking configuration and fills in the remote and branch names automatically.

---

## Next Up - Lesson 11

GitHub hosts Git repositories online for backup, sharing, and collaboration. SSH keys provide secure password-free authentication by matching a private key on your machine with a public key registered on GitHub. `git remote add origin <url>` connects your local repository to GitHub. `git push -u origin main` uploads your local commits and establishes the tracking relationship so future pushes and pulls work without specifying the remote or branch name. The complete local history is transferred to GitHub on the first push and visible through the GitHub interface.

In Lesson 11, you will learn push, pull, and fetch in depth: how to keep your local and remote repositories synchronized, what happens when the remote has changes you do not have, and the difference between `git fetch` and `git pull`.