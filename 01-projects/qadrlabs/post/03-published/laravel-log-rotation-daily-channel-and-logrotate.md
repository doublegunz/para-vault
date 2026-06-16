---
title: "How to Rotate Laravel Logs and Stop Them from Filling Your Disk"
slug: "laravel-log-rotation-daily-channel-and-logrotate"
category: "Laravel"
date: "2026-06-16"
status: "draft"
---

# How to Rotate Laravel Logs and Stop Them from Filling Your Disk

Your application suddenly starts throwing errors. Every request returns a 500, the queue stops draining, and nothing obvious changed in the code. You SSH into the server, run a disk usage check, and the disk is sitting at 100 percent. The surprise is what filled it: not user uploads, not the database, but `storage/logs`. A single `laravel.log` file had quietly grown until one file alone was close to a gigabyte, and the directory as a whole had swallowed the entire volume. A quick `ncdu` over `storage/` tells the whole story in one screen: `/logs` holds 23.4 GiB while `/framework`, `/app`, and `/debugbar` together are a rounding error next to it. The reason is simple and easy to miss. Laravel's default `single` log channel appends every line to one file forever and never rotates it, so on a busy app it only ever grows. The fix is log rotation, and you will solve it on two fronts: switch Laravel to its built-in `daily` channel with a capped retention window, then add the operating system's `logrotate` utility as a safety net for the logs Laravel does not manage.

## Overview {#overview}

Log rotation means slicing one endless log file into smaller, dated pieces and automatically deleting the old pieces once you no longer need them. Laravel ships with this capability built in through its `daily` channel, which writes a new file per day and prunes files older than a retention window you control. That covers your application log, but a production box logs in more places than Laravel knows about: queue worker output captured by Supervisor, custom channels still set to `single`, and other long running processes. For those you reach for `logrotate`, the standard Linux utility that rotates and compresses any log file on a schedule. By the end you will have both layers in place and, just as important, you will know how to verify that rotation actually happens instead of assuming it does.

### What You'll Build

- A small Laravel 13 application whose log files rotate automatically, one per day, with a fixed retention window so old logs are deleted instead of accumulating.
- A `logrotate` configuration that rotates and compresses a log file Laravel does not manage, such as a queue worker log, with its own retention count.

### What You'll Learn

- Why the default `single` channel grows without bound and eventually fills the disk.
- The difference between the `single`, `daily`, and `stack` channels in Laravel.
- How `LOG_DAILY_DAYS` controls retention and how Laravel prunes old daily files under the hood.
- How to confirm rotation and pruning really happen, rather than trusting the configuration blindly.
- How to write and test a `logrotate` config for logs that live outside Laravel's logging system.

### What You'll Need

- PHP 8.3 or higher, which is the minimum version for Laravel 13.
- Composer and the Laravel installer available on your machine.
- Basic familiarity with the terminal, `.env` files, and Artisan Tinker.
- A Linux server with `logrotate` installed for the final section. It ships with most distributions by default.

## Step 1: Create the Project {#step-1-create-the-project}

Start with a fresh Laravel 13 application so you have a clean log directory to experiment with. If you already have an app and just want to fix its logs, you can skip straight to Step 3 and apply the same configuration changes there; the only difference is that your `storage/logs` already has history in it.

Run the following commands. The first scaffolds a new project configured for SQLite and Pest, and the second moves you into the project directory.

```bash
laravel new logrotate-demo --no-interaction --database=sqlite --pest --no-boost
cd logrotate-demo
```

The `--database=sqlite` flag points the app at a local SQLite file so you do not need a separate database server, and `--pest` wires up the testing framework. Neither matters much for logging specifically, but they keep the project consistent with the rest of the Laravel 13 tutorials on this site.

Confirm the framework version so you know you are on Laravel 13.

```bash
php artisan --version
```

You should see a 13.x version reported.

```
Laravel Framework 13.15.0
```

## Step 2: Reproduce the Single-File Problem {#step-2-reproduce-the-problem}

Before fixing anything, it helps to see the problem happen on a small scale. A fresh Laravel project logs to the `single` channel by default, and that is exactly the channel that grew to a gigabyte on the broken server. Reproducing it locally makes the fix concrete.

Open your `.env` file and look at the logging block. A new project ships with these values.

```ini
LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug
```

The default channel is `stack`, and `stack` is just a wrapper that forwards everything to the channels named in `LOG_STACK`, which here is `single`. So in practice every log line ends up going through the `single` channel. You can see how that channel is defined by opening `config/logging.php`.

```php
'single' => [
    'driver' => 'single',
    'path' => storage_path('logs/laravel.log'),
    'level' => env('LOG_LEVEL', 'debug'),
    'replace_placeholders' => true,
],
```

The important line is `'path' => storage_path('logs/laravel.log')`. The `single` driver writes every log record to that one fixed file. There is no date in the name and no size limit anywhere in the config, which means the file only ever grows. On a quiet app you might never notice. On an app handling real traffic, with debug-level logging left on, it fills a disk.

Now generate enough log lines to watch the file grow. Open Tinker.

```bash
php artisan tinker
```

Inside the Tinker prompt, write five thousand log entries in a loop to simulate a busy application.

```php
for ($i = 0; $i < 5000; $i++) {
    Log::info('Request handled', ['id' => $i, 'user' => 'demo@example.com']);
}
```

Each call to `Log::info()` appends one structured line to the active channel, which right now is `single`. Five thousand iterations is nothing compared to production traffic, but it is enough to make the file size obvious. Type `exit` to leave Tinker, then list the log directory.

```bash
ls -lh storage/logs/
```

You will see a single file holding everything you just wrote.

```
total 436K
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 434K Jun 16 07:22 laravel.log
```

That is 434 KB from five thousand short lines. Multiply that by months of real traffic, stack traces, and verbose debug output, and the gigabyte file from the incident stops looking surprising. There is one file, it has no rotation, and nothing ever trims it. That is the behavior you are about to change.

## Step 3: Switch to the Daily Channel {#step-3-switch-to-daily}

Laravel already includes a channel built for exactly this problem. The `daily` channel writes a new file each day, names it with the date, and is backed by Monolog's rotating file handler so it can prune old files automatically. Switching to it is a one line change in `.env`.

Open `.env` and change the default channel from `stack` to `daily`.

```ini
LOG_CHANNEL=daily
```

This tells Laravel to send all log output through the `daily` channel instead of the `single` one. If you would rather keep using the `stack` wrapper, you can leave `LOG_CHANNEL=stack` and instead set `LOG_STACK=daily`, which produces the same result by pointing the stack at the daily channel. Either approach works; setting `LOG_CHANNEL=daily` directly is the simplest when you only use one channel.

The `daily` channel is already defined in `config/logging.php`, so you do not need to create anything. It looks like this.

```php
'daily' => [
    'driver' => 'daily',
    'path' => storage_path('logs/laravel.log'),
    'level' => env('LOG_LEVEL', 'debug'),
    'days' => env('LOG_DAILY_DAYS', 14),
    'replace_placeholders' => true,
],
```

Two things are different from the `single` channel. The `driver` is now `daily`, which activates date based rotation, and there is a new `days` key that controls how many days of logs to keep. You will tune that in the next step. The `path` still ends in `laravel.log`, but the `daily` driver inserts the date into the filename automatically, so the actual files on disk will be named `laravel-YYYY-MM-DD.log`.

Whenever you change configuration, clear Laravel's cached config so the new value is picked up, then generate some log output again to see the new file appear.

```bash
php artisan config:clear
php artisan tinker
```

Run the same loop as before inside Tinker.

```php
for ($i = 0; $i < 5000; $i++) {
    Log::info('Request handled', ['id' => $i, 'user' => 'demo@example.com']);
}
```

Exit Tinker and list the directory again.

```bash
ls -lh storage/logs/
```

This time there is a date stamped file alongside the old one.

```
total 872K
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 434K Jun 16 07:22 laravel-2026-06-16.log
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 434K Jun 16 07:22 laravel.log
```

The new entries went into `laravel-2026-06-16.log`, named for today's date. The old `laravel.log` is the leftover from Step 2 while you were still on the `single` channel; nothing writes to it anymore, so you can safely delete it. From here on, each calendar day gets its own file. Tomorrow's logs will land in `laravel-2026-06-17.log`, and so on. That solves the "one giant file" half of the problem. The other half is making sure those daily files do not just accumulate forever, which is what retention is for.

## Step 4: Cap Retention with LOG_DAILY_DAYS {#step-4-retention}

Rotating into daily files only helps if old files eventually go away. A new file every day with no cleanup is still unbounded growth, just spread across many files instead of one. The `days` setting in the `daily` channel is what caps it, and it reads from the `LOG_DAILY_DAYS` environment variable.

Look again at the relevant line in the `daily` channel config.

```php
'days' => env('LOG_DAILY_DAYS', 14),
```

This means Laravel keeps the most recent fourteen daily files by default and deletes anything older. The number is not a hard coded magic value; it comes from `LOG_DAILY_DAYS`, so you can set retention per environment without touching `config/logging.php`. A development machine might keep a couple of days, while production might keep a month for auditing.

Add the variable to your `.env` and set it lower than the default so the cleanup is easy to observe in the next step.

```ini
LOG_DAILY_DAYS=7
```

With this in place, Laravel keeps seven days of logs and removes the rest. The cleanup is not run by a scheduled task or a cron job; it happens inside Monolog's rotating file handler. When Laravel writes a log entry and the handler creates a new day's file, it also scans the directory for existing daily files matching the same pattern and deletes the oldest ones beyond your retention count. You will see that pruning happen for real in the next step.

## Step 5: Try It Out {#step-5-try-it-out}

The best way to trust retention is to watch it delete something. To do that without waiting a week, you can seed the log directory with files dated in the past, then trigger a single write and confirm Laravel prunes the directory back down to your retention window.

First, clear out the directory and create ten backdated log files, one for each of the last ten days. This simulates an app that has been running and rotating for a while.

```bash
rm -f storage/logs/*.log
for d in $(seq 1 10); do
  day=$(date -d "-$d day" +%Y-%m-%d)
  echo "[old log for $day]" > "storage/logs/laravel-$day.log"
done
ls -1 storage/logs/
```

The loop uses `date -d "-$d day"` to compute each past date and writes a tiny placeholder file named exactly the way Laravel names its daily logs. Listing the directory shows ten days of history sitting there.

```
laravel-2026-06-06.log
laravel-2026-06-07.log
laravel-2026-06-08.log
laravel-2026-06-09.log
laravel-2026-06-10.log
laravel-2026-06-11.log
laravel-2026-06-12.log
laravel-2026-06-13.log
laravel-2026-06-14.log
laravel-2026-06-15.log
```

Now write a single new log entry. Because today has no file yet, the rotating handler creates `laravel-2026-06-16.log` and runs its cleanup pass at the same time, which is what deletes the files beyond your seven day window.

```bash
php artisan config:clear
php artisan tinker --execute="Log::info('New entry for today, triggers rotation cleanup');"
ls -1 storage/logs/
```

The `--execute` flag runs one statement in Tinker and exits, which is handy for a quick one off write. After it runs, list the directory one more time.

```
laravel-2026-06-10.log
laravel-2026-06-11.log
laravel-2026-06-12.log
laravel-2026-06-13.log
laravel-2026-06-14.log
laravel-2026-06-15.log
laravel-2026-06-16.log
```

Count them: seven files. You started with ten backdated files, added today's, then the handler pruned the directory down to the seven most recent. The four oldest files, from June 6 through June 9, are gone. This is retention working exactly as configured, and it confirms the disk can never fill from Laravel's own log again, because the total number of files is now bounded by `LOG_DAILY_DAYS`.

## Rotating Logs Laravel Does Not Manage with logrotate {#logrotate}

The `daily` channel solves rotation for Laravel's own application log, but a production server logs in places Laravel has no control over. Queue workers run under Supervisor, which captures their standard output into a log file that grows with every processed job. Scheduled commands, custom channels you deliberately left on `single`, and third party tooling all write their own files. None of those go through Monolog's rotating handler, so they have the exact same unbounded growth problem you just fixed inside Laravel. The standard tool for rotating any file on a Linux server is `logrotate`, and it runs independently of your application.

Create a configuration file for the log you want to manage. On a real server these live in `/etc/logrotate.d/`, and each file describes one or more logs and how to rotate them. The example below targets a queue worker log, but the same block works for any file by changing the path at the top.

```
/var/www/myapp/storage/logs/worker.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

Each directive controls one aspect of rotation. `daily` rotates the file once per day. `rotate 7` keeps seven old copies and deletes anything older, which is the `logrotate` equivalent of `LOG_DAILY_DAYS`. `compress` gzips rotated files so the archive takes a fraction of the space, and `delaycompress` waits one cycle before compressing so the most recently rotated file stays readable as plain text. `missingok` tells `logrotate` not to error if the file is absent, and `notifempty` skips rotation when there is nothing to rotate. The most important line for a long running process is `copytruncate`: instead of renaming the file out from under the worker, `logrotate` copies the current contents to the rotated name and then truncates the original in place. That matters because a process like a queue worker holds the file open and keeps writing to the same file handle; if `logrotate` simply renamed the file, the worker would keep writing to the old, now invisible file and your new log would stay empty.

Before trusting it on a schedule, validate the config with a dry run. The `-d` flag tells `logrotate` to read the configuration and report what it would do without changing anything.

```bash
sudo logrotate -d /etc/logrotate.d/laravel-worker
```

You will see it parse the file and walk through its decision for the log.

```
warning: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.

reading config file worker.conf
Reading state from file: ./logrotate-state
state file ./logrotate-state does not exist
Allocating hash table for state file, size 64 entries

Handling 1 logs

rotating pattern: /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-test/logs/worker.log after 1 days empty log files are not rotated, (7 rotations), old logs are removed
considering log /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-test/logs/worker.log
Creating new state
  Now: 2026-06-16 07:24
  Last rotated at 2026-06-16 07:00
  log does not need rotating (log has already been rotated)
```

The dry run confirms the config is valid and that `logrotate` found the log. Notice the last line: it says the log does not need rotating yet. That is `logrotate` being conservative, because it only rotates once per the configured interval and it has just recorded its baseline state for this file. To verify the behavior immediately rather than waiting for the next daily cycle, force a rotation with `-f`.

```bash
sudo logrotate -f /etc/logrotate.d/laravel-worker
```

The command runs quietly and exits with status zero on success. List the directory to see the result.

```
total 116K
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna    0 Jun 16 07:24 worker.log
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 115K Jun 16 07:24 worker.log.1
```

This is `copytruncate` in action. The original `worker.log` is now zero bytes, ready for the worker to keep writing into the same open handle, while the previous contents were copied to `worker.log.1`. Force a second rotation after the file has filled up again to see compression kick in.

```
total 124K
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna    0 Jun 16 07:25 worker.log
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 115K Jun 16 07:25 worker.log.1
-rw-rw-r-- 1 gun-gun-priatna gun-gun-priatna 5.5K Jun 16 07:24 worker.log.2.gz
```

Now you can see the full lifecycle. The newest rotated file, `worker.log.1`, is still uncompressed because of `delaycompress`, while the older `worker.log.2.gz` has been gzipped down from 115 KB to 5.5 KB. Over time the numbers climb to `worker.log.7.gz`, and anything past that is deleted because of `rotate 7`. On a real server you do not run this by hand; `logrotate` is already wired into a daily cron job or systemd timer, so dropping your config into `/etc/logrotate.d/` is all it takes for it to run automatically every day.

One design choice worth understanding is `copytruncate` versus the default `create` behavior. With `create`, `logrotate` renames the active file and creates a fresh one in its place, which is efficient because it avoids copying data, but it only works for processes that reopen their log file after rotation, such as nginx when sent a signal. A plain queue worker does not reopen its file, so for those you use `copytruncate`, accepting the small cost of copying the file in exchange for the worker continuing to log correctly without a restart.

## Understanding Laravel Log Channels and Levels {#understanding-channels}

Now that both layers are in place, it is worth stepping back to understand the pieces you configured, because the channel names trip up a lot of developers. Laravel logging is built on Monolog, and a channel is simply a named logging configuration that decides where records go and how they are stored.

The `single` channel writes every record to one fixed file with no rotation, which is why it grows without bound and caused the original incident. The `daily` channel writes one file per day and is backed by Monolog's `RotatingFileHandler`, the class that both names files by date and prunes old ones past your `days` count. The `stack` channel is different in kind: it does not write anywhere itself, it fans a single log call out to one or more other channels listed in `LOG_STACK`. That is why a default project logging to `stack` still ends up in a `single` file, because the stack forwards to `single` out of the box. Understanding this is what lets you make sense of `LOG_CHANNEL` and `LOG_STACK` together: one picks the active channel, the other picks what the stack forwards to.

There is a second lever that is easy to overlook, and it attacks the problem from the opposite direction. Rotation limits how much log you keep, but `LOG_LEVEL` limits how much log you generate in the first place. With `LOG_LEVEL=debug`, Laravel records everything down to debug messages, which is enormously verbose and is a common reason production logs balloon. Raising it to `LOG_LEVEL=warning` in production tells Laravel to ignore `debug` and `info` records entirely and only write warnings and above. Rotation and log level work together: the level controls the firehose at the source, and rotation caps whatever still gets through. Using both is what keeps a busy application's logs permanently under control.

## Conclusion {#conclusion}

A full disk that takes down an application is one of those incidents that feels mysterious until you look at `storage/logs` and find a single file the size of a small database. The fix is not complicated, it just has to actually be configured, because the default Laravel project does not rotate anything. By moving to the `daily` channel, capping retention, and adding `logrotate` for everything outside Laravel, you make runaway log growth structurally impossible. Here are the key takeaways.

- **The `single` channel grows forever.** It appends every record to one fixed file with no rotation and no size cap, which is exactly how a `laravel.log` reaches a gigabyte and fills a disk.
- **The `daily` channel rotates by date.** Switching `LOG_CHANNEL` to `daily` gives you one dated file per day automatically, backed by Monolog's rotating file handler.
- **`LOG_DAILY_DAYS` bounds the total.** Retention is what turns daily files from "many small unbounded files" into a fixed window; Laravel prunes the oldest files past the count whenever it rolls a new day.
- **Verify rotation, do not assume it.** Seeding backdated files and watching Laravel prune them, or forcing a `logrotate` run and inspecting the directory, is the only way to know rotation truly works before an incident proves it does not.
- **`logrotate` covers what Laravel cannot.** Queue worker output, custom `single` channels, and other processes need the operating system's rotation, where `copytruncate` keeps long running writers logging correctly through a rotation.
- **`LOG_LEVEL` reduces the volume at the source.** Rotation limits what you keep, but raising the log level in production limits what you write, and the two together keep logs permanently under control.
</content>
