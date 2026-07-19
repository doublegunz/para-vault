---
title: "How to Rotate Backup Logs with Logrotate on Ubuntu 26.04"
slug: "how-to-rotate-backup-logs-with-logrotate-on-ubuntu-26-04"
category: "DevOps"
date: "2026-07-11"
status: "draft"
---

# How to Rotate Backup Logs with Logrotate on Ubuntu 26.04

In [Automated MySQL Backup to Google Drive on Ubuntu VPS Using Rclone](https://qadrlabs.com/post/automated-mysql-backup-to-google-drive-on-ubuntu-vps-using-rclone), you created a cron job that appends the output of every database backup to `/home/ubuntu/backup.log`. That log is useful when you need to audit a successful run or diagnose a failed upload, but an append-only file never stops growing. Given enough time, it can waste disk space and become inconvenient to inspect.

Ubuntu includes logrotate to solve this problem. Logrotate can rename an active log, compress the archived copy, create a secure replacement, and remove old archives according to a retention policy. In this tutorial, you will configure it for the database backup log and verify the complete rotation process without waiting for the daily schedule.

## Overview {#overview}

You will add a dedicated logrotate rule without changing the backup script or its cron schedule. The finished setup keeps the current log available at the same path while maintaining a limited collection of dated, compressed archives.

### What You'll Build

- A logrotate rule in `/etc/logrotate.d/database-backup`.
- Daily rotation for `/home/ubuntu/backup.log`, with earlier rotation when it exceeds 10 MB.
- Up to 30 compressed archives with names such as `backup.log-2026-07-11.gz`.
- A replacement log owned by `ubuntu:ubuntu` with `0600` permissions.
- Automatic checks through Ubuntu's `logrotate.timer`.

### What You'll Learn

- How to inspect an application log before managing it with logrotate.
- How `daily`, `maxsize`, and `rotate` work together.
- Why logs inside a non-root user's home directory need the `su` directive.
- How to validate a rule without rotating any files.
- How to force a rotation and inspect a compressed archive.
- How to confirm that systemd schedules logrotate automatically.

### What You'll Need

- An Ubuntu 26.04 VPS with SSH access and sudo privileges.
- The backup script from the [previous tutorial](https://qadrlabs.com/automated-mysql-backup-to-google-drive-on-ubuntu-vps-using-rclone), or another scheduled command that writes to a log file.
- A log at `/home/ubuntu/backup.log` containing at least one line.
- Basic familiarity with Linux commands and editing files with Nano.

This tutorial uses `ubuntu` as the server username. If your VPS uses another username, replace `ubuntu` in the path, owner, and group throughout the configuration.

## Step 1: Inspect the Existing Backup Log {#step-1-inspect-backup-log}

Before creating a rotation policy, confirm that the log exists and identify its current owner. Logrotate must be able to access the parent directory, rename the existing file, and create its replacement with ownership that still allows the backup job to write.

Inspect the file:

```bash
ls -lh /home/ubuntu/backup.log
```

You should see a regular file owned by the user that runs the backup cron job. A result may look like this:

```text
-rw------- 1 ubuntu ubuntu 18K Jul 11 18:00 /home/ubuntu/backup.log
```

Use `stat` to display the exact permission mode, owner, and group:

```bash
stat -c '%A %a %U %G %n' /home/ubuntu/backup.log
```

The expected values are the `ubuntu` owner and group. The existing mode does not have to be `0600` yet because the rule will enforce that mode on the replacement file.

Check the most recent messages without printing the entire log:

```bash
tail -n 10 /home/ubuntu/backup.log
```

If you followed the previous tutorial, you should see timestamped messages from the backup script. If the file does not exist yet, run the backup script once:

```bash
/bin/bash /home/ubuntu/backup.sh
```

Inspect the file again before continuing. A non-empty log gives you something concrete to archive during the forced rotation test.

If your script uses a different location, keep that location. Substitute its absolute path everywhere this tutorial uses `/home/ubuntu/backup.log`, and use the account that actually runs the script for both ownership fields.

## Step 2: Verify Logrotate on Ubuntu 26.04 {#step-2-verify-logrotate}

Ubuntu 26.04 provides logrotate through the `logrotate` package. Verify the command before installing anything:

```bash
logrotate --version
```

On Ubuntu 26.04, the first line identifies logrotate 3.22.0:

```text
logrotate 3.22.0
```

If the shell reports that the command is missing, update the package index and install it:

```bash
sudo apt update
sudo apt install -y logrotate
```

The Ubuntu package includes both `logrotate.service` and `logrotate.timer`. Check the timer:

```bash
systemctl status logrotate.timer --no-pager
```

Look for `Loaded: loaded` and `Active: active (waiting)`. The waiting state means systemd has scheduled the next activation. It does not mean a rotation is currently running.

You can display the previous and next activation times in a compact form:

```bash
systemctl list-timers logrotate.timer --no-pager
```

If the timer is installed but inactive, enable it immediately:

```bash
sudo systemctl enable --now logrotate.timer
```

Run the status command again and confirm that it is active before continuing.

## Step 3: Create the Backup Log Rotation Rule {#step-3-create-rotation-rule}

Files in `/etc/logrotate.d` define policies for individual applications or jobs. You will keep the backup policy separate from the global configuration so it is easy to review and maintain.

Open a new configuration file:

```bash
sudo nano /etc/logrotate.d/database-backup
```

Add the complete rule:

```conf
/home/ubuntu/backup.log {
    daily
    rotate 30
    maxsize 10M

    compress
    missingok
    notifempty

    dateext
    dateformat -%Y-%m-%d

    create 0600 ubuntu ubuntu
    su ubuntu ubuntu
}
```

The first line selects the exact log file. `daily` makes it eligible for rotation once per day, while `maxsize 10M` allows an earlier rotation if the file exceeds 10 MB when logrotate checks it. `rotate 30` retains no more than 30 archived files, and `compress` uses gzip to reduce their disk usage.

The next directives make the rule tolerant of normal conditions. `missingok` prevents a missing log from failing the complete logrotate run, while `notifempty` leaves an empty file alone. `dateext` and `dateformat` produce a sortable date suffix such as `-2026-07-11`.

Finally, `create 0600 ubuntu ubuntu` creates a new active log immediately after the old one is renamed. Only its owner can read or write it. The `su` directive performs rotation as `ubuntu:ubuntu`, which is important because the log is inside a directory controlled by a non-root user.

Save the file by pressing `Ctrl+O`, press `Enter`, then exit Nano with `Ctrl+X`.

This rule does not use `copytruncate`. The backup script opens the log only while a backup is running, so logrotate can rename the file and create a replacement. It also does not need a `postrotate` script because there is no long-running process that must be told to reopen its log.

## Step 4: Validate the Configuration Safely {#step-4-validate-configuration}

Always validate a new rule before allowing it to modify files. The debug option reads the configuration, evaluates the selected log, and prints its decision without rotating the log or updating the state file.

Run the debug check against only the new rule:

```bash
sudo logrotate --debug /etc/logrotate.d/database-backup
```

The output starts with a clear reminder that debug mode does not make changes. It should then report one handled log and show the daily, 10 MB, and 30-rotation policy. The key lines resemble these:

```text
warning: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.

Handling 1 logs

rotating pattern: /home/ubuntu/backup.log after 1 days empty log files are not rotated, log files >= 10485760 are rotated earlier, (30 rotations), old logs are removed
```

Do not continue if the command reports a syntax error, an unknown user or group, or insecure parent-directory permissions. Check that the opening path is absolute, every directive is inside the braces, and both occurrences of `ubuntu` match the real account.

The debug output may say that the log does not need rotating. That is not an error. It only means the time and size conditions are not currently satisfied. You will override those conditions once for testing in the next step.

## Step 5: Force and Verify the First Rotation {#step-5-force-and-verify-rotation}

A forced rotation proves that logrotate can rename the file, compress it, and create a writable replacement. Run this test while the backup script is not executing:

```bash
sudo logrotate --force --verbose /etc/logrotate.d/database-backup
```

The `--force` option ignores the normal time and size conditions. The `--verbose` option prints the actions instead of suppressing them. A successful run reports that the log needs rotating, shows a date suffix, renames the log, creates a new file, and invokes gzip.

List the log directory:

```bash
ls -lah /home/ubuntu/
```

You should now find both files:

```text
backup.log
backup.log-2026-07-11.gz
```

The date in your archive name will match the day on which you run the command. Verify the replacement file's security attributes:

```bash
stat -c '%A %a %U %G %n' /home/ubuntu/backup.log
```

The result should show mode `600` and ownership `ubuntu:ubuntu`:

```text
-rw------- 600 ubuntu ubuntu /home/ubuntu/backup.log
```

Use `zcat` to read the compressed archive without extracting it to disk. Replace the date with the actual suffix shown by `ls`:

```bash
sudo zcat /home/ubuntu/backup.log-2026-07-11.gz
```

You should see the messages that were in `backup.log` before rotation.

Finally, run the backup script again:

```bash
/bin/bash /home/ubuntu/backup.sh
```

Check the new active log:

```bash
tail -n 10 /home/ubuntu/backup.log
```

New backup messages confirm that the replacement file has the correct owner and remains writable by the cron job.

## Step 6: Try It Out {#step-6-try-it-out}

The following test session demonstrates the full behavior with logrotate 3.22.0 in an isolated directory. The rule used the same rotation directives as the VPS configuration, but omitted `su` and explicit ownership because the test ran without root privileges.

### Validate Without Changing the Log

The debug command inspected the rule and left the original log untouched. This is the captured output:

```text
warning: logrotate in debug mode does nothing except printing debug messages!  Consider using verbose mode (-v) instead if this is not what you want.

reading config file sandbox/logrotate-article/database-backup
Reading state from file: sandbox/logrotate-article/status
state file sandbox/logrotate-article/status does not exist
Allocating hash table for state file, size 64 entries

Handling 1 logs

rotating pattern: /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log after 1 days empty log files are not rotated, log files >= 10485760 are rotated earlier, (30 rotations), old logs are removed
considering log /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log
Creating new state
  Now: 2026-07-11 22:20
  Last rotated at 2026-07-11 22:00
  log does not need rotating (log has already been rotated)
```

The important evidence is in the policy summary. Logrotate recognized the daily interval, empty-log protection, 10 MB early-rotation threshold, and 30-archive retention policy.

### Force a Non-Empty Log to Rotate

The forced run renamed the active log, created its replacement with mode `0600`, and compressed the archive:

```text
rotating log /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log, log->rotateCount is 30
Converted '-%Y-%m-%d' -> '-%Y-%m-%d'
dateext suffix '-2026-07-11'
glob pattern '-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
glob finding old rotated logs failed
renaming /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log to /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log-2026-07-11
creating new /home/gun-gun-priatna/obsidian-vault/sandbox/logrotate-article/backup.log mode = 0600 uid = 1000 gid = 1000
compressing log with: /bin/gzip
```

The message about finding old rotated logs is expected on a first run because no previous archives exist.

The permission check returned:

```text
-rw------- 600 gun-gun-priatna gun-gun-priatna sandbox/logrotate-article/backup.log
```

Reading the archive with `zcat` returned its original contents:

```text
[2026-07-11 18:00:01] Starting backup for store_db
[2026-07-11 18:00:04] Backup complete.
```

### Confirm Empty Logs Are Skipped

The forced rotation created an empty replacement. Run the forced command again without writing anything to that file:

```bash
sudo logrotate --force --verbose /etc/logrotate.d/database-backup
```

Because `notifempty` is enabled, logrotate reports that the log does not need rotating. This prevents empty dated archives from accumulating between backup runs.

### Confirm Automatic Scheduling

Return to the systemd timer after completing the manual tests:

```bash
systemctl is-enabled logrotate.timer
systemctl is-active logrotate.timer
```

The expected results are `enabled` and `active`. Your custom file is inside `/etc/logrotate.d`, so the standard service reads it during scheduled runs. You do not need to add another cron job for logrotate.

## How the Logrotate Rule Works {#how-the-logrotate-rule-works}

The practical test confirms that the rule works. Understanding the relationship between its directives will help you adjust it safely for logs with different growth patterns.

### Daily Rotation and the 10 MB Limit

`daily` makes a non-empty log eligible once a day. `maxsize 10M` adds an early condition, so a file larger than 10 MB can rotate before a full day has passed. However, logrotate does not watch the file continuously. The size is evaluated only when the logrotate service runs. A daily timer therefore cannot guarantee that the file will never temporarily exceed 10 MB.

If a high-volume application needs a stricter size ceiling, logrotate itself must be invoked more frequently. The backup script in this tutorial writes only a small number of lines per run, so the standard timer is appropriate.

### Archive Count and Compression

`rotate 30` retains at most 30 old copies. It is a file count, not an absolute 30-day promise. Daily runs normally produce approximately 30 days of history, but an early size-based rotation can create an additional archive.

`compress` passes rotated files through gzip. Text logs usually compress well, so this greatly reduces the cost of retaining diagnostic history. The active `backup.log` stays uncompressed and can still receive normal shell redirection.

### Dated Archive Names

`dateext` replaces numeric suffixes such as `.1` with a date. The custom `dateformat -%Y-%m-%d` produces filenames that are readable and lexically sortable. The year-first order is important because logrotate sorts dated filenames when deciding which old archives to remove.

For a log that can rotate more than once per day, a date-only suffix can collide with an archive created earlier on the same date. This tutorial's daily systemd schedule and low-volume backup log avoid that condition. A more frequent schedule should include time components in `dateformat`.

### Secure Ownership and Permissions

`create 0600 ubuntu ubuntu` controls the replacement log, not the archived file. Mode `0600` allows only the owner to read and write it, which is appropriate because backup logs can contain database names, paths, remote names, and error details.

The [Ubuntu 26.04 logrotate manual](https://manpages.ubuntu.com/manpages/resolute/en/man8/logrotate.8.html) recommends `su` when root rotates files inside directories controlled by non-privileged users. Setting `su ubuntu ubuntu` lets logrotate perform file operations with the same account that owns the backup log directory.

## Common Logrotate Problems {#common-logrotate-problems}

Most logrotate failures come from paths, permissions, or assumptions about its schedule. The debug command usually identifies the cause before any file changes occur.

### The Parent Directory Has Insecure Permissions

Logrotate may reject a log inside a directory writable by a non-root user when no `su` directive is present. Keep `su ubuntu ubuntu` in this rule and ensure both names match the actual owner and group shown by `stat`.

### The Archive Was Not Created

If the active log is empty, `notifempty` intentionally skips it. Write a real backup entry by running the script, then repeat the forced test. Without `--force`, the state file may also show that the log was already rotated during the current interval.

### The Backup Script Cannot Write After Rotation

Check the replacement file with `stat`. Its owner must match the account that owns the crontab. Correct both values in `create`, validate the file, force another rotation after adding test content, then run the backup script again.

### A Forced Test Reports an Existing Destination

With a date-only archive name, two forced rotations on the same date can target the same filename. Avoid repeated forced rotations on production logs. If you need another test, move the existing test archive to a safe temporary name first, or wait until the next date. Do not delete an archive until you have confirmed that you no longer need its contents.

### The Timer Is Active but the File Keeps Growing

Inspect the service result and the shared state file:

```bash
systemctl status logrotate.service --no-pager
sudo grep '/home/ubuntu/backup.log' /var/lib/logrotate/status
```

The timer only starts the service. A configuration error, empty log, recent rotation timestamp, or file below the configured conditions can still cause the rule to skip rotation.

## Conclusion {#conclusion}

Your backup job can now keep useful diagnostic history without allowing one append-only file to grow forever. The backup script continues writing to the same path, while Ubuntu handles rotation, compression, secure file creation, and retention automatically.

- **Automatic rotation.** Ubuntu's `logrotate.timer` checks the rules in `/etc/logrotate.d` without requiring another custom cron entry.
- **Bounded retention.** `rotate 30` limits the number of archived logs instead of allowing them to accumulate indefinitely.
- **Size protection.** `maxsize 10M` permits early rotation when the file is already large at check time.
- **Compressed archives.** `compress` reduces disk usage while keeping old backup messages accessible through tools such as `zcat` and `zless`.
- **Secure permissions.** `create 0600 ubuntu ubuntu` and `su ubuntu ubuntu` preserve the access required by the backup job without exposing its log to other users.
- **Safe validation.** `--debug` catches configuration and permission problems without rotating files, while one controlled `--force` run verifies the complete workflow.
