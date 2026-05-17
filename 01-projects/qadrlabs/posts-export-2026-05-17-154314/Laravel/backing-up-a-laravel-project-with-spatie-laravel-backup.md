---
title: "Backing Up a Laravel Project with Spatie Laravel Backup"
slug: "backing-up-a-laravel-project-with-spatie-laravel-backup"
category: "Laravel"
date: "2026-04-09"
status: "published"
---

Most Laravel projects run for months before anyone thinks seriously about backups.
Then one day a deployment goes wrong, a database row gets deleted by accident, or a server disk fails, and suddenly the absence of a working backup strategy becomes very real.
Setting up backups after an incident is always harder and more stressful than doing it beforehand.

Spatie Laravel Backup gives you a complete backup solution that covers your files and database, stores archives on one or more disks, cleans up old backups on a schedule, monitors backup health, and sends notifications when something goes wrong.

This tutorial walks through the full setup from installation to automation, so you have a working backup strategy in place before you need it.

## Overview {#overview}
This tutorial covers the end-to-end process of configuring Spatie Laravel Backup v10 in a [Laravel project](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step).
Each section builds on the previous one, starting with installation and ending with scheduled automation, health monitoring, and notifications.
By the end you will have a backup system that runs automatically, cleans up after itself, and alerts you if something is wrong.

### What You'll Build

- A working installation of `spatie/laravel-backup` configured for your project
- A backup disk that stores zipped archives of your files and database
- A scheduled job that runs backups and cleanup automatically every day
- Health monitoring that checks backup age and storage usage
- Email notifications for successful backups, failures, and health warnings

### What You'll Learn

- How to install and publish the package configuration
- How to locate the correct path for database dump binaries on your system
- How to configure which files and databases to include or exclude from backups
- How to set up a local backup disk and an external disk like S3 for off-site storage
- How to run backup commands manually and what each command does
- How to schedule backups and cleanup using Laravel's scheduler
- How to configure health monitoring and notifications

### What You'll Need

- A Laravel 13 project with a database connection already configured
- PHP 8.3 or newer with the ZIP extension enabled
- Composer
- `mysqldump` installed on your server if you use MySQL, or `pg_dump` for PostgreSQL (SQLite works without any additional binary)
- An S3-compatible storage bucket or another external filesystem (recommended, not required for the basic setup)

> This package is not compatible with Windows servers.

## Why Backups Need a Strategy, Not Just a Command {#why-backups-need-a-strategy}

Running a backup command once gives you one backup.
That is better than nothing, but it is not a backup strategy.
A real strategy means backups happen automatically on a schedule, old backups are cleaned up before they fill your disk, the health of existing backups is checked regularly, and you are notified when anything goes wrong.

Spatie Laravel Backup addresses all of these concerns in a single package.
It integrates with Laravel's scheduler so backups run without manual intervention, uses Laravel's filesystem abstraction so you can store archives on any supported disk, and sends notifications through Laravel's notification system so you are never the last to know about a problem.
The rest of this tutorial shows you how to wire all of it together.

## Step 1: Installation {#installation}

Before configuring anything, the package needs to be installed and its configuration file published into your project.

### Install the package via Composer

Run the following command in the root of your Laravel project.

```bash
composer require spatie/laravel-backup
```

This installs version 10.2 of the package, which is the current stable release for Laravel 13 projects. The package registers its service provider automatically through Laravel's package auto-discovery, so you do not need to add anything to `config/app.php`.

### Publish the configuration file

Publish the default configuration to `config/backup.php` so you can edit it directly.

```bash
php artisan vendor:publish --provider="Spatie\Backup\BackupServiceProvider" --tag=backup-config
```

You should see output confirming the file was copied.

```
  INFO  Publishing [backup-config] assets.

 Copying file [vendor/spatie/laravel-backup/config/backup.php] to [config/backup.php]  DONE
```

You can also publish the translation files if you need to customize the language strings used in notifications.

```bash
php artisan vendor:publish --provider="Spatie\Backup\BackupServiceProvider" --tag=backup-translations
```

After publishing, open `config/backup.php`. This file is the central place for everything: what gets backed up, where it goes, how old backups are cleaned up, what gets monitored, and how notifications are delivered. The following sections walk through each part of it.

## Step 2: Configuring the Database Dump Binary {#configuring-database-dump-binary}

Before touching `config/database.php`, you need to know where `mysqldump` (or `pg_dump`) is installed on your system.
The package requires the path to the directory containing the binary, not the binary itself.
If you provide the wrong path, the database dump will fail silently and your backup archive will be incomplete.

SQLite databases do not require this step because the package reads the database file directly without any external binary.

### Find the binary path on your system

Run the following command to locate `mysqldump`.

```bash
which mysqldump
```

```
/usr/bin/mysqldump
```

The value you need is the directory portion of that path, without the binary name at the end. In the example above, the correct value for `dump_binary_path` is `/usr/bin`. If you are using PostgreSQL, run `which pg_dump` instead.

### Configure the database dump settings

Open `config/database.php` and add a `dump` key to the connection you want to back up.

```php
// config/database.php

'connections' => [
    'mysql' => [
        'driver' => 'mysql',
        // ... other connection settings
        'dump' => [
            'dump_binary_path' => '/usr/bin',  // use the path from `which mysqldump`
            'use_single_transaction' => true,   // avoids table locking on InnoDB
            'timeout' => 60 * 5,                // 5 minute timeout
            'exclude_tables' => [
                'telescope_entries',
                'jobs',
                'failed_jobs',
            ],
        ],
    ],
],
```

The `use_single_transaction` option is worth enabling if your MySQL database uses InnoDB tables exclusively, because it prevents tables from being locked during the dump.
The `exclude_tables` array is useful for tables that contain transient data you do not need to restore, such as queue jobs or debug logs.

If you are on a MySQL or MariaDB server that uses a self-signed SSL certificate and you see a `TLS/SSL error: self-signed certificate` message during the dump, add `'skip_ssl' => true` to the `dump` array to bypass that check.

## Step 3: Configuring What Gets Backed Up {#configuring-what-gets-backed-up}

The `backup.source` section of `config/backup.php` controls which files and databases are included in each backup archive.
Getting this right is important: include too much and your archives are unnecessarily large, include too little and your backup is incomplete.

### Configure file inclusions and exclusions

The default configuration includes the entire project root with `base_path()` and excludes directories that do not need to be backed up because they can be regenerated.

```php
// config/backup.php

'source' => [
    'files' => [
        'include' => [
            base_path(),
        ],

        'exclude' => [
            base_path('vendor'),
            base_path('node_modules'),
            storage_path('framework'),
        ],

        'follow_links' => false,

        'ignore_unreadable_directories' => false,

        'relative_path' => null,
    ],

    'databases' => [
        env('DB_CONNECTION', 'mysql'),
    ],
],
```

The `vendor` and `node_modules` directories are excluded by default because they can be restored with `composer install` and `npm install`. The `storage/framework` directory contains cached views and sessions that do not belong in a backup.

If your project stores user-uploaded files in `storage/app/public`, verify that `storage_path()` is either included explicitly or not covered by an exclude rule, because user uploads are data you need to restore in a disaster scenario.

The `databases` array reads the value of `DB_CONNECTION` from your `.env` file by default, so for most projects no change is needed here. If you have multiple database connections and need to back them all up, add each connection name to this array.

## Step 4: Setting Up the Backup Destination Disk {#setting-up-backup-destination}

By default, backups are stored in `storage/app/Laravel/` using the `local` filesystem disk.
This is enough to get started, but storing backups only on the same server as your application means a server failure could take both your application and its backups offline at the same time.
Adding a remote disk like S3 as a second destination gives you off-site storage with minimal extra configuration.

### Create a dedicated backup disk

Add a `backups` disk to `config/filesystems.php`. Using a dedicated disk for backups makes it easy to control where archives are stored without affecting the rest of your filesystem configuration.

```php
// config/filesystems.php

'disks' => [

    'local' => [
        'driver' => 'local',
        'root' => storage_path('app'),
    ],

    'backups' => [
        'driver' => 'local',
        'root' => storage_path('app/backups'),
    ],

],
```

### Point the backup config to your disk

Update the `destination.disks` array in `config/backup.php` to use the disk you just created.

```php
// config/backup.php

'destination' => [
    'disks' => [
        'backups',
    ],
],
```

When you are ready to add an external disk for off-site storage, add it to this array alongside `backups`. The package will copy each archive to all listed disks, and if one destination fails it will still attempt the remaining ones.

## Step 5: Running Your First Backup {#running-your-first-backup}

With the source and destination configured, you can run a backup manually to verify everything is working before setting up the scheduler.

### Run the backup command

```bash
php artisan backup:run
```

Output:
```
Starting backup..
Dumping database /path/to/your/project/database/database.sqlite..
Determining files to backup..
Zipping 421 files and directories..
Created zip containing 421 files and directories. Size is 584.51 KB
Copying zip to disk named backups..
Successfully copied zip to disk named backups.
Backup completed!
```

The package dumps the configured database, zips it together with the included files, and copies the archive to each configured destination disk. The archive name contains your application name and a timestamp, for example `2026-04-09-12-55-26.zip`.

You can also run a backup that includes only the database without zipping your project files. This is useful if you need a quick database snapshot between scheduled full backups.

```bash
php artisan backup:run --only-db
```

Output:
```
Starting backup..
Dumping database /path/to/your/project/database/database.sqlite..
Determining files to backup..
Zipping 1 files and directories..
Created zip containing 1 files and directories. Size is 936 B
Copying zip to disk named backups..
Successfully copied zip to disk named backups.
Backup completed!
```

Be careful with `--only-db` and `--only-files` as your primary backup approach. The monitoring system does not distinguish between full backups and partial ones, so relying on partial backups as your main strategy means you may not be able to fully restore from them.

### Verify the backup files on disk

After running one or more backups, confirm that the archive files are landing in the expected location.

```bash
ls storage/app/backups/Laravel/
```

```
2026-04-09-12-55-26.zip  2026-04-09-12-56-17.zip
```

Each zip file corresponds to one backup run. You can unzip any of these files manually to inspect its contents and verify that both the database dump and project files are present inside the archive.

## Step 6: Configuring Backup Cleanup {#configuring-backup-cleanup}

Without cleanup, backups accumulate indefinitely.
The `backup:clean` command removes old archives according to a tiered retention strategy that keeps more backups in the recent past and fewer as time goes on.

### Review and adjust the cleanup strategy

The default retention settings in `config/backup.php` follow a tiered approach.

```php
// config/backup.php

'cleanup' => [
    'strategy' => \Spatie\Backup\Tasks\Cleanup\Strategies\DefaultStrategy::class,

    'default_strategy' => [
        'keep_all_backups_for_days' => 7,
        'keep_daily_backups_for_days' => 16,
        'keep_weekly_backups_for_weeks' => 8,
        'keep_monthly_backups_for_months' => 4,
        'keep_yearly_backups_for_years' => 2,
        'delete_oldest_backups_when_using_more_megabytes_than' => 5000,
    ],
],
```

The strategy works in layers. For the first 7 days, every backup is kept. Beyond that, only one backup per day is kept for the next 16 days, then one per week for 8 weeks, one per month for 4 months, and one per year for 2 years. The newest backup is never deleted regardless of any of these settings.

Adjust these numbers to match your recovery requirements and storage budget. A project with a large database on a small disk might reduce `keep_all_backups_for_days` to 3 and lower the storage cap. A project with strict data retention requirements might extend the yearly window.

To run cleanup manually and confirm it works before scheduling it.

```bash
php artisan backup:clean
```

## Step 7: Setting Up the Scheduler {#setting-up-scheduler}

Running backups and cleanup manually is useful for testing, but the real value comes from automation.
Laravel's scheduler can run these commands daily without any additional infrastructure beyond a single cron entry.

### Schedule backup and cleanup commands

Open `routes/console.php` and add the following schedule definitions.

```php
// routes/console.php

use Illuminate\Support\Facades\Schedule;

Schedule::command('backup:clean')->daily()->at('01:00');
Schedule::command('backup:run')->daily()->at('01:30');
```

Running `backup:clean` before `backup:run` ensures old archives are removed before a new one is added, which keeps storage usage from spiking at the moment a fresh archive lands on disk. The 30-minute gap between the two commands gives cleanup enough time to finish before the new backup starts.

Avoid scheduling both commands in the 02:00 to 03:00 window in regions that observe daylight saving time, because the clock change at that hour can cause a backup to run twice or not at all.

### Add the cron entry for the scheduler

For the scheduled commands to execute, Laravel's scheduler itself must be triggered every minute by a system cron job. Add the following entry to your server's crontab.

```bash
* * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
```

If you manage your server through a platform like Laravel Forge or Vapor, the scheduler cron entry is configured through the platform dashboard instead of the crontab directly.

## Step 8: Configuring Health Monitoring {#configuring-health-monitoring}

Having backups run on a schedule is not enough if you never find out when the schedule breaks.
The `backup:monitor` command checks whether your backups meet a set of health criteria and fires a notification if they do not.

### Configure the monitor settings

The `monitor_backups` array in `config/backup.php` defines which applications and disks to monitor, and what conditions constitute an unhealthy backup.

```php
// config/backup.php

'monitor_backups' => [
    [
        'name' => env('APP_NAME', 'laravel-backup'),
        'disks' => ['backups'],
        'health_checks' => [
            \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumAgeInDays::class => 1,
            \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumStorageInMegabytes::class => 5000,
        ],
    ],
],
```

The `MaximumAgeInDays` check marks the backup as unhealthy if the most recent archive is older than the specified number of days. Setting this to `1` means that if yesterday's backup did not arrive for any reason, you will be notified today.

The `MaximumStorageInMegabytes` check flags the backup as unhealthy if all archives together exceed the specified storage limit. This is a safety valve that ensures you notice before disk usage becomes a problem.

The `name` value must match the `backup.name` key in the configuration file of the application being monitored. Add the monitor command to your scheduler alongside the existing entries.

```php
// routes/console.php

Schedule::command('backup:clean')->daily()->at('01:00');
Schedule::command('backup:run')->daily()->at('01:30');
Schedule::command('backup:monitor')->daily()->at('03:00');
```

Running the monitor at 03:00 gives the backup process at 01:30 enough time to complete before the health check runs.

## Step 9: Configuring Notifications {#configuring-notifications}

The package sends notifications for every significant event: successful backups, failed backups, successful cleanup, failed cleanup, and the results of health checks.
All of these are routed through Laravel's notification system, which means the same channels you already use for other notifications in your application work here too.

### Set up mail notifications

The simplest channel to configure is mail. Update the `notifications` section in `config/backup.php` with the recipient address.

```php
// config/backup.php

'notifications' => [
    'notifications' => [
        \Spatie\Backup\Notifications\Notifications\BackupHasFailedNotification::class => ['mail'],
        \Spatie\Backup\Notifications\Notifications\UnhealthyBackupWasFoundNotification::class => ['mail'],
        \Spatie\Backup\Notifications\Notifications\CleanupHasFailedNotification::class => ['mail'],
        \Spatie\Backup\Notifications\Notifications\BackupWasSuccessfulNotification::class => ['mail'],
        \Spatie\Backup\Notifications\Notifications\HealthyBackupWasFoundNotification::class => ['mail'],
        \Spatie\Backup\Notifications\Notifications\CleanupWasSuccessfulNotification::class => ['mail'],
    ],

    'notifiable' => \Spatie\Backup\Notifications\Notifiable::class,

    'mail' => [
        'to' => 'devops@yourproject.com',

        'from' => [
            'address' => env('MAIL_FROM_ADDRESS', 'hello@example.com'),
            'name' => env('MAIL_FROM_NAME', 'Backup Monitor'),
        ],
    ],
],
```

Each notification class maps to an array of channels. If you only want failure notifications by email and prefer not to receive a message after every successful backup, remove `BackupWasSuccessfulNotification` and `HealthyBackupWasFoundNotification` from the list.

### Add a Slack or Discord notification channel (optional)

If your team uses Slack, install the Slack notification channel package first.

```bash
composer require laravel/slack-notification-channel
```

Then add `'slack'` to the channels array for whichever notifications you want to receive there, and fill in your Slack webhook URL.

```php
// config/backup.php

'notifications' => [
    'notifications' => [
        \Spatie\Backup\Notifications\Notifications\BackupHasFailedNotification::class => ['mail', 'slack'],
        \Spatie\Backup\Notifications\Notifications\UnhealthyBackupWasFoundNotification::class => ['mail', 'slack'],
        // ...
    ],

    'slack' => [
        'webhook_url' => env('BACKUP_SLACK_WEBHOOK_URL', ''),
        'channel' => '#deployments',
        'username' => 'Backup Bot',
        'icon' => null,
    ],
],
```

Discord is also supported out of the box using the `discord` key and a Discord webhook URL. For other platforms like Mattermost or Microsoft Teams, the `webhook` key accepts a URL that receives a generic JSON POST request.

## Verifying the Full Setup {#verifying-the-full-setup}

After completing all the steps above, it is worth running the full command sequence manually to confirm everything works end to end before relying on the scheduler.

### Run the full command sequence

```bash
php artisan backup:run
php artisan backup:clean
php artisan backup:list
php artisan backup:monitor
```

A healthy output from `backup:list` will show at least one recent archive on each configured disk, with the age and file size visible in the table. A healthy output from `backup:monitor` will confirm that the backup meets the age and storage criteria you configured.

If you receive a notification email or Slack message after running these commands, your notification pipeline is also working correctly.

## Understanding the Backup Disk Strategy {#understanding-backup-disk-strategy}

The single most important decision in your backup configuration is where archives are stored.
Saving backups only on the same server that runs your application creates a single point of failure.
If the server goes offline or the disk fails, both your application and its backups disappear at the same time.

A robust strategy uses at least two destinations: a local disk for fast access during a routine restore, and a remote disk like S3 or Dropbox for off-site durability.
The package handles multi-disk destinations transparently, so adding a second disk to `destination.disks` is all you need to do.

For teams that run multiple Laravel applications, Spatie recommends running `backup:monitor` on a separate Laravel installation on a separate server.
If the application being backed up goes down and takes its scheduler with it, a monitor running elsewhere will still catch that the backups have become stale and send a notification.
This separation is especially important for production applications where downtime and data loss carry real business consequences.

## Conclusion {#conclusion}

A backup system that runs once and is never checked again is almost as risky as no backup system at all.
Disks fill up, cron jobs get removed during deployments, credentials expire, and external storage buckets get misconfigured.
The scheduler, health monitor, and notification system in Spatie Laravel Backup are designed to turn backup management from a manual inspection task into something that only requires your attention when something has actually gone wrong.

The setup in this tutorial covers the full lifecycle: daily automated backups, tiered retention cleanup, health checks that catch missed or oversized backups, and notifications delivered through the channels your team already uses.
Start with a local disk to get the basics working, then add an external disk as a second destination to remove the single point of failure before you go to production.

- Spatie Laravel Backup handles file and database backups, cleanup, health monitoring, and notifications in a single package with no custom infrastructure. It requires PHP 8.3 or higher with the ZIP extension and is not compatible with Windows servers.
- The package supports MySQL, PostgreSQL, and SQLite. For MySQL and PostgreSQL, run `which mysqldump` or `which pg_dump` to find the correct `dump_binary_path` value before configuring `config/database.php`.
- Backups are stored as timestamped zip archives on one or more Laravel filesystem disks. Using both a local disk and a remote disk like S3 removes the single point of failure.
- The `backup:run` command creates a new archive, `backup:clean` removes old ones according to a tiered retention strategy, and `backup:monitor` checks whether backups are recent enough and within storage limits.
- All three commands should be scheduled in `routes/console.php`, with cleanup running before the backup and the monitor running afterward to catch any failures.
- Notifications are delivered through Laravel's native notification system and support mail, Slack, Discord, and generic webhooks out of the box.
- The newest backup is never deleted by the cleanup strategy regardless of age or storage limits, which ensures you always have at least one restore point.