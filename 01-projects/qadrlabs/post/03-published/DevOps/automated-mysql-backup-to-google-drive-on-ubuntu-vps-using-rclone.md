---
title: "Automated MySQL Backup to Google Drive on Ubuntu VPS Using Rclone"
slug: "automated-mysql-backup-to-google-drive-on-ubuntu-vps-using-rclone"
category: "DevOps"
date: "2026-05-16"
status: "draft"
---

Your production database is one bad moment away from permanent loss. A full disk, an accidental `DROP DATABASE`, a failed upgrade, or a provider outage can wipe out months of data in seconds. Most developers know they should have backups, but setting one up that actually runs reliably, offsite, every night, without manual intervention, is where good intentions usually fall apart.

This article fixes that. You will set up a real database with sample data, practice backing it up manually with `mysqldump`, configure Rclone to connect to Google Drive, and then wrap everything into a single bash script that cron runs automatically every night. By the end, your data will be safely stored offsite in Google Drive without you having to think about it again.

## Overview {#overview}

This guide walks you through building a complete, automated MySQL backup pipeline from scratch on an Ubuntu VPS, using only tools that are free and widely available.

### What You'll Build

- A sample MySQL database named `store_db` with two tables and dummy data to use as a realistic backup target.
- A bash script that dumps the database, compresses it with gzip, uploads it to Google Drive via Rclone, and cleans up local files older than seven days.
- A cron job that runs the backup script automatically every day at 02:00.

### What You'll Learn

- How to use `mysqldump` to create compressed, timestamped database backups.
- How to install Rclone and configure it to authenticate with Google Drive from a headless VPS.
- How to write a production-ready bash backup script with proper logging.
- How to schedule automated tasks with crontab.

### What You'll Need

- An Ubuntu VPS (20.04 or later) with SSH access and sudo privileges.
- MySQL 8.0 or later installed and running.
- A Google account with Google Drive access.
- A local machine with a browser (needed once for the Google OAuth step).
- Basic comfort with the Linux terminal and running commands over SSH.

## Step 1: Prepare the Database {#step-1-prepare-database}

Before anything else, you need a database worth backing up. In a real project you would already have one, but for this tutorial you will create a small database called `store_db` with two tables and a handful of rows. This gives you something concrete to dump, upload, and verify throughout the rest of the steps.

Start by opening the MySQL prompt as the root user:

```bash
mysql -u root -p
```

MySQL will ask for the root password. Once you are inside the prompt, create the database and switch to it:

```sql
CREATE DATABASE store_db;
USE store_db;
```

Now create the `products` table. This table represents a simple product catalog with a name, price, and stock count:

```sql
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Next, create the `orders` table. Each order references a product and records how many units were purchased:

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

Now insert some dummy data into both tables:

```sql
INSERT INTO products (name, price, stock) VALUES
    ('Wireless Mouse', 29.99, 150),
    ('Mechanical Keyboard', 89.99, 75),
    ('USB-C Hub', 45.00, 200),
    ('Monitor Stand', 35.50, 60),
    ('Webcam 1080p', 59.99, 90);

INSERT INTO orders (product_id, quantity, total_price) VALUES
    (1, 2, 59.98),
    (3, 1, 45.00),
    (2, 1, 89.99),
    (5, 3, 179.97),
    (4, 2, 71.00);
```

Verify that the data was inserted correctly:

```sql
SELECT * FROM products;
SELECT * FROM orders;
```

You should see five rows in each table. Once you confirm the data is there, exit the MySQL prompt:

```sql
EXIT;
```

Your database is ready. In the next step, you will back it up manually to understand what `mysqldump` produces before you automate it.

## Step 2: Backup MySQL Manually with `mysqldump` {#step-2-manual-backup}

`mysqldump` is the standard tool for exporting a MySQL database into a plain SQL file. That file contains all the `CREATE TABLE` and `INSERT` statements needed to fully reconstruct your database from scratch. When you pipe that output through `gzip`, you get a compressed archive that is typically 60-80% smaller than the raw SQL, which matters a lot when you are storing months of backups in Google Drive.

First, create a folder on your VPS to store local backups temporarily:

```bash
mkdir -p ~/backups
```

The `-p` flag tells `mkdir` to create parent directories if they do not exist yet and to not complain if the folder already exists.

Now run the backup command. Notice the date format in the filename: it uses `$(date +%F)` which expands to the current date in `YYYY-MM-DD` format (for example, `2026-05-12`). This makes every backup file uniquely named and easy to sort chronologically:

```bash
mysqldump -u root -p store_db | gzip > ~/backups/store_db_$(date +%F).sql.gz
```

Here is what each part does. `mysqldump -u root -p store_db` connects to MySQL as the root user, prompts for the password, and dumps the entire `store_db` database to standard output. The pipe `|` passes that output directly into `gzip`, which compresses it on the fly. The `>` redirects the compressed output into the timestamped file inside `~/backups/`.

After running the command and entering your password, verify the file was created:

```bash
ls -lh ~/backups/
```

You should see output similar to this:

```
-rw-rw-r-- 1 ubuntu ubuntu 1.2K May 12 10:23 store_db_2026-05-12.sql.gz
```

The file is small because your dummy data is small, but the process is identical for a database with gigabytes of real data. The backup is compressed and ready. Next, you will install Rclone so you can send this file to Google Drive.

## Step 3: Install Rclone {#step-3-install-rclone}

Rclone is a command-line tool that can sync files between your server and over 70 cloud storage providers, including Google Drive. There are three ways to install it on Ubuntu, and the right choice depends on what you prioritize.

The first option is installing via APT. It is the simplest method but the version in Ubuntu's package repository is often several major versions behind:

```bash
sudo apt install -y rclone
```

The second option is using the official Rclone install script. This always pulls the latest stable release directly from Rclone's servers and is the recommended approach for production use:

```bash
curl -fsSL https://rclone.org/install.sh | sudo bash
```

The flags `-fsSL` tell `curl` to follow redirects silently and fail with an error if the download does not succeed. The script detects your system architecture automatically and installs the correct binary.

The third option is Snap, which also stays up to date but does not support `rclone mount` due to Snap's filesystem sandboxing. If you only need copy and sync operations (which is all this tutorial requires), Snap works fine, but the official script is still the better default:

```bash
sudo snap install rclone
```

After installing using your preferred method, verify the installation succeeded:

```bash
rclone version
```

```
rclone v1.68.2
- os/version: ubuntu 22.04 (64 bit)
- os/kernel: 5.15.0-113-generic (x86_64)
- os/type: linux
- os/arch: amd64
- go/version: go1.23.4
- go/linking: static
- go/tags: none
```

As long as you see a version number, Rclone is installed and ready to configure.

## Step 4: Configure Rclone for Google Drive {#step-4-configure-rclone}

Rclone connects to cloud storage through "remotes," which are named configurations that store the credentials and settings for a specific service. You will create one remote named `gdrive` that points to your Google Drive account.

Run the configuration wizard:

```bash
rclone config
```

Rclone will show an interactive menu. Follow these steps through the wizard:

**Choose `n` to create a new remote:**

```
No remotes found, make a new one?
n) New remote
q) Quit config
n/q> n
```

**Enter the name `gdrive`:**

```
name> gdrive
```

**Choose Google Drive from the storage type list.** The list is long; type the number that corresponds to "Google Drive" (the number may vary by Rclone version, but it is typically around 18-20):

```
Storage> drive
```

**Leave the client ID and client secret blank** by pressing Enter twice. This tells Rclone to use its own built-in OAuth credentials, which is perfectly fine for personal use:

```
client_id>
client_secret>
```

**Choose scope `1` for full access** to all files in your Google Drive:

```
scope> 1
```

**Leave the root folder ID blank** (press Enter) unless you want to restrict Rclone to a specific subfolder. Leave service account credentials blank as well.

**When asked about advanced config, choose `n`:**

```
Edit advanced config? (y/n)
y) Yes
n) No (default)
n/q> n
```

**This is the critical step for a headless VPS.** Rclone will ask if you want to use auto-config. Since your VPS has no browser, answer `n`:

```
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes (default)
n) No
y/n> n
```

Rclone will then print a long URL. Copy that entire URL, paste it into a browser on your **local machine**, and log in with your Google account. Google will show an authorization page; click Allow. Google will then show you a verification code. Copy that code and paste it back into your VPS terminal:

```
Enter verification code> 4/0AX4XfWh...
```

**Confirm the remote is not a shared drive** (unless yours is) by choosing `n`, then confirm the configuration with `y`.

Once the wizard finishes, test that the connection works:

```bash
rclone lsd gdrive:
```

This command lists the top-level folders in your Google Drive. You should see your existing folders printed to the terminal. If you see them, authentication is working correctly.

Now create the destination folder in Google Drive where backups will live:

```bash
rclone mkdir gdrive:BACKUP
```

## Step 5: Upload a Backup to Google Drive {#step-5-upload-backup}

With Rclone configured, try uploading the backup file you created in Step 2 manually. This confirms that the `gdrive` remote works end-to-end before you put it inside a script.

```bash
rclone copy ~/backups/store_db_$(date +%F).sql.gz gdrive:BACKUP/ --progress
```

`rclone copy` copies the source file to the destination without deleting anything at the source. The `--progress` flag shows a live transfer rate and completion percentage, which is helpful for large files.

You should see output like this:

```
Transferred:        1.234 KiB / 1.234 KiB, 100%, 0 B/s, ETA -
Transferred:        1 / 1, 100%
Elapsed time:       2.1s
```

Now verify the file actually arrived in Google Drive:

```bash
rclone lsl gdrive:BACKUP/
```

`rclone lsl` lists files with their size and last-modified timestamp, which is more useful than `rclone ls` alone:

```
     1264 2026-05-12 10:35:02.000000000 store_db_2026-05-12.sql.gz
```

The file is there. You have now confirmed every individual piece of the pipeline works: `mysqldump` produces a valid compressed file, and Rclone can upload it to Google Drive. The next step is combining these pieces into a single script.

## Step 6: Create the Backup Script {#step-6-backup-script}

A bash script ties everything together and makes the process repeatable without any manual input. Create the script file in your home directory:

```bash
nano ~/backup.sh
```

Paste in the following script:

```bash
#!/bin/bash

# ─────────────────────────────────────────────
# Configuration
# Edit these variables to match your setup.
# ─────────────────────────────────────────────

DB_USER="root"
DB_PASS="your_mysql_password"
DB_NAME="store_db"

BACKUP_DIR="$HOME/backups"
RCLONE_REMOTE="gdrive"
RCLONE_DEST="BACKUP"

RETENTION_DAYS=7
DATE=$(date +%F)
FILENAME="${DB_NAME}_${DATE}.sql.gz"
LOG_FILE="$HOME/backup.log"

# ─────────────────────────────────────────────
# Start
# ─────────────────────────────────────────────

echo "[$DATE $(date +%T)] Starting backup for $DB_NAME" >> "$LOG_FILE"

# Step 1: Create the backup directory if it does not exist
mkdir -p "$BACKUP_DIR"

# Step 2: Dump the database and compress it with gzip.
# The -h localhost flag forces TCP connection instead of a socket,
# which avoids permission issues in some MySQL configurations.
mysqldump -u "$DB_USER" -p"$DB_PASS" -h localhost "$DB_NAME" \
    | gzip > "$BACKUP_DIR/$FILENAME"

# Check if the dump succeeded before proceeding
if [ $? -ne 0 ]; then
    echo "[$DATE $(date +%T)] ERROR: mysqldump failed. Aborting." >> "$LOG_FILE"
    exit 1
fi

echo "[$DATE $(date +%T)] Dump created: $FILENAME" >> "$LOG_FILE"

# Step 3: Upload the compressed backup to Google Drive.
# rclone copy uploads the file without deleting anything at the destination.
# --quiet suppresses transfer progress so the log stays clean.
rclone copy "$BACKUP_DIR/$FILENAME" "$RCLONE_REMOTE:$RCLONE_DEST/" --quiet

if [ $? -ne 0 ]; then
    echo "[$DATE $(date +%T)] ERROR: rclone upload failed." >> "$LOG_FILE"
    exit 1
fi

echo "[$DATE $(date +%T)] Uploaded to $RCLONE_REMOTE:$RCLONE_DEST/$FILENAME" >> "$LOG_FILE"

# Step 4: Delete local backup files older than RETENTION_DAYS.
# -mtime +7 matches files last modified more than 7 days ago.
# -name matches only .sql.gz files so you do not accidentally delete other files.
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "[$DATE $(date +%T)] Cleaned up local backups older than $RETENTION_DAYS days" >> "$LOG_FILE"
echo "[$DATE $(date +%T)] Backup complete." >> "$LOG_FILE"
```

After pasting, save and exit with `Ctrl+X`, then `Y`, then `Enter`.

There are two important things to note about this script. First, the password is written directly in the file as `DB_PASS`. This is acceptable for a private VPS where you control file permissions, but you should restrict access to the script so only your user can read it. Second, the `if [ $? -ne 0 ]` checks after each major step catch failures early; `$?` holds the exit code of the last command, and a non-zero value means something went wrong.

Make the script executable:

```bash
chmod 700 ~/backup.sh
```

Using `700` instead of `755` means only the file owner can read, write, and execute it. Nobody else on the system can read the file, which keeps your database password private.

## Step 7: Automate with Cron Job {#step-7-cron}

Cron is the built-in Linux task scheduler. Each user has their own crontab file that lists commands to run on a schedule. Open yours for editing:

```bash
crontab -e
```

If this is your first time editing crontab, it will ask you to choose an editor. Choose `nano` if you are unsure.

Add this line at the bottom of the file:

```
0 2 * * * /bin/bash /home/ubuntu/backup.sh >> /home/ubuntu/backup.log 2>&1
```

Replace `ubuntu` with your actual username. The five fields before the command follow the cron schedule format: `minute hour day-of-month month day-of-week`. In this case, `0 2 * * *` means "at minute 0 of hour 2, every day, every month, every day of the week," which translates to 02:00 every night.

The `>> /home/ubuntu/backup.log 2>&1` part appends both standard output and standard error to the log file. This means if cron itself has trouble running the script, you will see the error in the log rather than losing it silently.

Save and exit. Cron will confirm the new job:

```
crontab: installing new crontab
```

Verify the crontab was saved correctly:

```bash
crontab -l
```

```
0 2 * * * /bin/bash /home/ubuntu/backup.sh >> /home/ubuntu/backup.log 2>&1
```

The job is now scheduled. Cron runs it automatically every night at 02:00 without any further action from you.

## Step 8: Try It Out {#step-8-try-it-out}

Do not wait until 02:00 to find out if everything works. Trigger the script manually right now:

```bash
bash ~/backup.sh
```

The script runs silently because all output goes to the log file. Once it finishes (usually within a few seconds for a small database), check the log:

```bash
cat ~/backup.log
```

You should see output like this:

```
[2026-05-12 11:05:01] Starting backup for store_db
[2026-05-12 11:05:02] Dump created: store_db_2026-05-12.sql.gz
[2026-05-12 11:05:04] Uploaded to gdrive:BACKUP/store_db_2026-05-12.sql.gz
[2026-05-12 11:05:04] Cleaned up local backups older than 7 days
[2026-05-12 11:05:04] Backup complete.
```

Each line is timestamped, which makes it easy to confirm when the backup ran and whether it succeeded. If you see an `ERROR` line instead, the message will tell you exactly which step failed.

Now verify the file is in Google Drive:

```bash
rclone lsl gdrive:BACKUP/
```

```
     1264 2026-05-12 11:05:03.000000000 store_db_2026-05-12.sql.gz
```

The backup is in Google Drive. You can also open Google Drive in your browser and navigate to the `BACKUP` folder to confirm visually.

As days pass and the script runs nightly, you will see new files appear with each day's date. Files older than seven days will be cleaned up automatically from your local `~/backups/` folder, but they will remain in Google Drive, giving you a growing offsite archive.

## How the Backup Script Works {#how-it-works}

Now that the script is running, it is worth understanding each part in more depth so you can adapt it confidently for your own projects.

### Variables at the Top

Grouping all configuration into variables at the top of the script is a deliberate practice. It means you can adapt the script for a different database or a different Rclone remote by changing only the top section, without touching the logic below. The `DATE=$(date +%F)` variable is evaluated once when the script starts, so every reference to `$DATE` throughout the script uses the same consistent timestamp.

### Why `-h localhost` in `mysqldump`

MySQL on Linux can connect in two ways: via a Unix socket file or via TCP on localhost. When you run `mysqldump` without `-h localhost`, MySQL defaults to the socket connection, which sometimes has different permission rules than TCP. Adding `-h localhost` forces the TCP path and avoids subtle authentication mismatches, particularly on servers where MySQL's `root` account is bound to socket-only authentication.

### `rclone copy` vs `rclone sync`

Rclone has two similar but importantly different commands. `rclone copy` copies files from source to destination but never deletes anything at the destination. `rclone sync` makes the destination an exact mirror of the source, which means it will delete destination files that are not in the source. For backups, `copy` is always the safer choice because it ensures your Google Drive folder accumulates backups over time rather than being wiped clean each night to match whatever is currently on your VPS.

### The `find` Cleanup Command

The line `find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete` searches the local backup folder for files ending in `.sql.gz` that were last modified more than seven days ago and deletes them. The `+7` in `-mtime +7` means "strictly more than 7 days," so a file created exactly 7 days ago is kept; only files from day 8 and beyond are deleted. This keeps your VPS disk from filling up while preserving recent local copies for fast recovery if needed.

### Exit Code Checking with `$?`

After each major operation, the script checks `$?`, which is a special shell variable that holds the exit code of the most recently executed command. A value of `0` means success; anything else means failure. By checking this after `mysqldump` and after `rclone copy`, the script stops immediately if either step fails rather than continuing and silently producing a broken or missing backup.

## Conclusion {#conclusion}

You now have a fully automated MySQL backup pipeline that runs every night and stores compressed, timestamped backups in Google Drive. Here are the key things to take away from this tutorial.

- **`mysqldump` with gzip compression** is the simplest and most portable way to back up a MySQL database. Piping directly into `gzip` creates a compressed archive on the fly without writing an uncompressed intermediate file to disk.
- **Timestamped filenames** using `$(date +%F)` make backups self-organizing and easy to retrieve by date without any additional indexing or metadata.
- **Rclone's headless authentication** via the browser-on-local-machine flow lets you connect a VPS to Google Drive even without a display or browser on the server itself.
- **`rclone copy` over `rclone sync`** is the correct choice for backup destinations because it accumulates files rather than mirroring and potentially deleting older backups.
- **Exit code checking** in bash scripts ensures that a failure in one step stops the script immediately rather than silently continuing and producing a misleading "success" log entry.
- **`chmod 700` on the script file** restricts read access to the file owner only, which is essential when the script contains a plain-text database password.
- **Cron with full absolute paths** avoids the most common cron failure mode, where a script works perfectly when run manually but fails under cron because cron uses a minimal environment without the user's `PATH` variables.
- **The seven-day local retention policy** balances disk usage on the VPS with the convenience of having recent backups available locally for fast restoration, while Google Drive holds the long-term archive.