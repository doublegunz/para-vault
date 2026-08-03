---
title: "tmux Tutorial: A Terminal Multiplexer Guide for Developers"
slug: "tmux-tutorial-a-terminal-multiplexer-guide-for-developers"
category: "Tools"
date: "2026-08-03"
status: "draft"
---

It was almost midnight when I finally ran the command. A long database migration on a staging server, the kind that takes forever and makes you stare at a blinking cursor while praying nothing breaks. I was connected over SSH from my laptop, coffee going cold beside me, feeling productive.

Then my WiFi hiccuped. Just for a second. But that second was enough. The SSH connection dropped, the terminal froze, and my migration, the one that was already halfway done, went with it. Gone. I had to start over.

If you have ever left your laptop lid open all night just so a remote task would not die, or opened five terminal tabs for one project (editor here, server there, logs somewhere, database over there), then you already feel the pain I am talking about.

*"How do you keep a terminal session alive even when the connection drops? And how do you juggle a bunch of terminal windows without drowning in tabs?"* That question had been nagging me for a while. The answer, it turns out, is a small tool that has been around for years and quietly runs on almost every developer's server: **tmux**. So I turned that idea into this article, a friendly walkthrough of what tmux is and how we can actually use it day to day.

## Overview{#overview}
In this article we'll get to know **tmux**, short for *terminal multiplexer*. Think of it as a window manager that lives inside your terminal. With one tmux session you can run many windows and split each window into panes, so a single terminal can hold your editor, your dev server, and your logs all at once. Even better, a tmux session keeps running on its own. You can detach from it, close your terminal, walk away, and when you come back everything is exactly where you left it. That is the part that would have saved my migration.

We'll cover three big wins that make tmux worth learning: **session persistence** (your work survives disconnects), **windows and panes** (many things on one screen), and a **tidy workflow** (one named session per project). By the end you'll be able to install tmux, run your first session, split your screen, and set up a real workflow for working on a remote server. There is even a little `.tmux.conf` customization at the end to make it feel like home.

So, what are the steps to get comfortable with tmux? *Check this out!*

**Table of Contents**
- [Overview](#overview)
- [Step 1 - Installing tmux](#step-1-installing-tmux)
- [Step 2 - Your first session and the prefix key](#step-2-first-session)
- [Step 3 - Named sessions for multiple projects](#step-3-named-sessions)
- [Step 4 - Windows: tabs inside one session](#step-4-windows)
- [Step 5 - Panes: splitting the screen](#step-5-panes)
- [Step 6 - A real-world workflow for developers](#step-6-real-world)
- [Step 7 - A little .tmux.conf customization](#step-7-customization)
- [Wrap Up](#wrap-up)
- [References](#references)

## Step 1 - Installing tmux {#step-1-installing-tmux}
Before we start, let's say a little prayer so the coding goes smoothly. :)

Done?

Alright, first things first, let's make sure tmux is installed. tmux runs on Linux, macOS, and Windows via WSL. On a Debian or Ubuntu based system (this also covers most VPS setups and WSL), we install it with `apt`:

```bash
sudo apt update
sudo apt install tmux
```

The `apt update` refreshes the package list first, then `apt install tmux` pulls in the package. If you are on macOS and using Homebrew, the command is even shorter:

```bash
brew install tmux
```

Once it finishes, let's confirm the install by checking the version:

```bash
tmux -V
```

On my machine that prints:

```
tmux 3.6
```

If you see a version number like that, *yay!* tmux is ready. The exact number may differ on your system, and that is totally fine. Anything reasonably recent will follow along with this tutorial just fine.

## Step 2 - Your first session and the prefix key {#step-2-first-session}
Now for the fun part. Let's start our very first tmux session. Just type:

```bash
tmux
```

And like magic, your terminal repaints itself with a green status bar at the bottom. That bar is tmux telling you, *"hey, you are inside a session now."* You are still in a normal shell, so you can run any command you like. The difference is that this shell is now living inside tmux.

Here is the single most important concept in tmux, so read this part slowly. tmux listens for a special keystroke called the **prefix key** before it accepts a command. By default that prefix is `Ctrl+b`. You press `Ctrl+b`, let go, and then press one more key to tell tmux what to do.

So when this tutorial says `prefix c`, it means: press `Ctrl+b`, release, then press `c`. Simple once you get the rhythm.

Now, remember my dead midnight migration? This is where tmux fixes it. Inside your session, let's pretend we started something important. Run a little counter so we can see it survive:

```bash
watch -n 1 date
```

That command reprints the date every second, a stand-in for any long running task. Now let's do the trick that changes everything. Press the prefix, then `d`:

```
prefix d
```

The `d` stands for **detach**. Your screen jumps back to your normal terminal and you'll see a line like this:

```
[detached (from session 0)]
```

Your `watch` command did not stop. It is still running, safely tucked away inside the tmux session. You could close this terminal, log out, lose your WiFi, and it would keep going. Let's prove it. Ask tmux which sessions are alive:

```bash
tmux ls
```

```
work: 1 windows (created Mon Aug  3 10:44:34 2026)
```

*Note:* if you started with a plain `tmux`, your session will be named with a number like `0` instead of `work`. We'll give it a proper name in the next step.

To jump back into the session and pick up right where we left off, we **attach** to it:

```bash
tmux attach
```

*Tadaaa!!!* Your `watch` command is still ticking away, second by second, as if you never left. :D That right there, session persistence, is the reason tmux is worth every minute of learning it.

To stop the `watch` command, press `Ctrl+c`. And whenever you want to close a session completely, just type `exit` inside it like you would in any shell.

## Step 3 - Named sessions for multiple projects {#step-3-named-sessions}
Working on more than one thing at a time? Yeah, me too. This is where named sessions shine. Instead of a plain `tmux`, we can give each session a name that tells us what it is for:

```bash
tmux new -s work
```

The `new` subcommand creates a session and `-s work` names it `work`. Open another one for a different project without leaving the first, detach with `prefix d`, then create a second session:

```bash
tmux new -s server
```

Now let's list them again:

```bash
tmux ls
```

```
server: 1 windows (created Mon Aug  3 10:44:34 2026)
work: 1 windows (created Mon Aug  3 10:44:34 2026)
```

Two independent workspaces, each remembering its own state. To hop into a specific one, we attach by name with `-t` (for *target*):

```bash
tmux attach -t work
```

And when a project is done and you want to clean up, kill just that session by name:

```bash
tmux kill-session -t server
```

```
work: 1 windows (created Mon Aug  3 10:44:34 2026)
```

Only `work` is left. One session per project keeps everything mentally sorted, and nothing leaks between them. :)

## Step 4 - Windows: tabs inside one session {#step-4-windows}
So far each session has had a single screen. But inside one session you can open many **windows**, which behave a lot like tabs in your browser or editor. Attach to your `work` session first, then create a new window with:

```
prefix c
```

The `c` stands for **create**. A fresh window opens with its own shell, and the status bar at the bottom grows a new entry. Every window has a number, starting at `0`, and you switch between them with the prefix and that number:

```
prefix 0    switch to window 0
prefix 1    switch to window 1
```

You can also step through them one at a time. `prefix n` moves to the **next** window and `prefix p` moves to the **previous** one.

Naming your windows makes a long day much calmer. Press `prefix ,` (that is prefix, then a comma) to rename the current window, type a name like `editor`, and hit Enter. Let's say you set up an `editor`, a `server`, and a `logs` window. Here is what tmux reports when we list them:

```bash
tmux list-windows -t work
```

```
0: bash (1 panes) [80x24] [layout b25d,80x24,0,0,0] @0
1: editor (1 panes) [80x24] [layout b25f,80x24,0,0,2] @2
2: server- (1 panes) [80x24] [layout b260,80x24,0,0,3] @3
3: logs* (1 panes) [80x24] [layout b261,80x24,0,0,4] @4 (active)
```

See that `*` next to `logs`? That marks the window you are currently in. The `-` next to `server` marks the last window you visited, so `prefix l` (lowercase L) can bounce you back to it. Handy for ping-ponging between two windows. :D

## Step 5 - Panes: splitting the screen {#step-5-panes}
Windows are great, but sometimes you want to see two things side by side without switching at all. That is what **panes** are for. A pane is a split of the current window, and each pane is its own independent shell.

To split the current pane left and right (a vertical divider), press:

```
prefix %
```

To split it top and bottom (a horizontal divider), press:

```
prefix "
```

Yeah, the symbols are a little quirky to remember at first. A trick that helped me: `%` looks tall and skinny like the vertical divider it makes, and `"` sits up high like the horizontal one. Once you split a window a couple of times, tmux can show you the layout. Here is a window I split into three panes:

```bash
tmux list-panes -t work:editor
```

```
0: [40x24] [history 0/2000, 960 bytes] %2
1: [39x12] [history 0/2000, 480 bytes] %5
2: [39x11] [history 0/2000, 440 bytes] %6 (active)
```

Three panes, one on the left and two stacked on the right, each with its own size. To move between them, hold the prefix and use the arrow keys:

```
prefix left / right / up / down
```

And when one pane needs your full attention, say your test output is scrolling and you want a bigger view, press `prefix z` to **zoom** it to fill the whole window. Press `prefix z` again to pop it back into the layout. Nothing is lost, the other panes are just hidden for a moment.

To close a pane, you can type `exit` in it or press `prefix x` and confirm with `y`.

## Step 6 - A real-world workflow for developers {#step-6-real-world}
Alright, let's put it all together the way you would actually use it on the job. This is our try-it-out step, and it is the exact scenario that burned me at the start.

Imagine you SSH into a remote server to deploy a project. First thing after logging in, start a named session so everything you do is safe from disconnects:

```bash
tmux new -s deploy
```

Inside that session, set up your workspace. Split the window into panes, one for each job:

```
prefix %      split for a second pane
prefix "      split the right side again
```

Now you have a little cockpit. In the left pane, open your editor. In the top right pane, run the dev server or the deploy command. In the bottom right pane, tail the logs so you can watch things happen live:

```bash
tail -f storage/logs/laravel.log
```

Kick off the long task, the migration or the build that scared me earlier. Then, here is the payoff. Instead of babysitting it, detach and go get more coffee:

```
prefix d
```

```
[detached (from session deploy)]
```

Close your laptop. Lose your WiFi on the train. Come back an hour later, SSH back into the server, and reattach:

```bash
tmux attach -t deploy
```

*Tadaaa!!!* Everything is exactly as you left it. The migration finished while you were away, the logs are all there in the bottom pane, and your editor still has the file open. :D No more all-nighters with the lid propped open. That, my friends, is the whole point of tmux.

\* \* \*

Bonus points: because a tmux session lives on the server, a teammate who SSHes into the same machine can `tmux attach -t deploy` and see the very same screen you do. Instant pair debugging, no screen sharing needed. Pretty neat, right?

## Step 7 - A little .tmux.conf customization {#step-7-customization}
tmux works great out of the box, but a few small tweaks make it feel like *yours*. Configuration lives in a file called `.tmux.conf` in your home directory. Open it in your favorite text editor:

```bash
nano ~/.tmux.conf
```

Then type this config:

```
# Use Ctrl+a as the prefix instead of Ctrl+b
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Turn on mouse support (click panes, drag borders, scroll)
set -g mouse on

# Start numbering windows at 1 instead of 0
set -g base-index 1

# Keep more scrollback history
set -g history-limit 10000
```

Let's walk through what each line does. The first block remaps the prefix from `Ctrl+b` to `Ctrl+a`, which many people find easier to reach with one hand. The `send-prefix` line means you can still send a literal `Ctrl+a` to a program by pressing it twice. Turning `mouse on` lets you click a pane to focus it, drag borders to resize, and scroll with your wheel, which is lovely when you are still learning the keybindings. Setting `base-index 1` makes window numbers line up with the keys on your keyboard. And `history-limit 10000` gives each pane a much longer scrollback so you do not lose output.

Save the file with `Ctrl+o` then Enter, and exit nano with `Ctrl+x`. For the changes to take effect in a running session, reload the config with the prefix followed by a colon to open the command prompt, then type:

```
source-file ~/.tmux.conf
```

If you remapped the prefix to `Ctrl+a`, remember your commands now start with that instead. *voila!~* tmux now behaves the way you like. ^^

## Wrap Up{#wrap-up}
So, in this walkthrough we went from "what even is tmux" to running a full remote workflow inside it. We installed tmux, learned the all important prefix key, and saw the killer feature up close: sessions that keep running even after we detach or lose the connection. We organized our work with named sessions, split things across windows and panes, and finally tied it all together in a real deploy scenario, then made it comfortable with a tiny `.tmux.conf`.

Of course, we have only scratched the surface here. tmux has a whole world of copy mode for scrolling and selecting text with the keyboard, session scripting, and a rich plugin ecosystem. If you enjoyed this, a great next step is the Tmux Plugin Manager (TPM) for adding plugins, plus tools like tmuxinator for saving entire project layouts you can launch with one command. And if you live in Neovim like a lot of us do, seamless tmux and Neovim pane navigation is a game changer worth setting up.

Do not feel like you have to memorize every keybinding today. Start with just detach and attach, then add windows and panes as they become useful. Muscle memory shows up faster than you think.

Keep it up! Happy learning.. Hope it's fun.. :D

## References:{#references}
* [tmux GitHub repository](https://github.com/tmux/tmux)
* [tmux wiki and getting started guide](https://github.com/tmux/tmux/wiki/Getting-Started)
* [tmux manual page (man tmux)](https://man.openbsd.org/OpenBSD-current/man1/tmux.1)
* [Tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/tpm)
