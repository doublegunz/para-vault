# How to Recover Deleted Production Data with MySQL Binary Log

You asked your AI coding agent to "clean up the test orders" before a demo. It found the database credentials in `.env`, opened a connection, and ran `DELETE FROM orders;`. No `WHERE` clause. No confirmation prompt. The problem is that `.env` pointed at production, and every real order your customers placed is now gone.

This is not a hypothetical fear. In July 2025, an AI agent on Replit deleted the production database of SaaStr founder Jason Lemkin in the middle of an explicit code freeze, and similar stories keep appearing as more teams let agents run commands on their behalf. Your last nightly backup is from 02:00 this morning, which means restoring it alone throws away every order, payment, and status change that happened since then. For a busy shop, those hours are exactly the data you cannot afford to lose.

The good news is that MySQL has probably been recording every change the whole time. The **binary log** (binlog) stores each write as an event with a position and a timestamp. By combining your last full backup with a careful replay of the binary log, you can rebuild the database up to the exact event before the destructive `DELETE`, skip that single transaction, and then replay everything that came after it. This technique is called **point-in-time recovery**, and in this article you will practice it end to end on a realistic incident.

## Overview {#overview}

This article is a hands-on case study. You will set up a small shop database, take a backup the way a nightly job would, generate some normal traffic, and then reproduce the kind of mistake an AI agent makes when it has production credentials. After the damage is done, you will walk through the full recovery process: isolating the logs, locating the destructive event, restoring the backup, and replaying the binary log around the mistake.

Everything runs on a single MySQL server with the command line client, so you can follow along regardless of the framework your application uses.

### What You'll Build

- A `shop_demo` database with an `orders` table that plays the role of production data.
- A full backup created with `mysqldump` that records the exact binary log coordinates at backup time.
- A simulated incident where an AI agent runs `DELETE FROM orders;` against production.
- A fully recovered `orders` table that contains the backup rows, the orders created after the backup, and the order created after the incident, with only the destructive transaction skipped.

### What You'll Learn

- How to check whether binary logging is enabled and which format it uses.
- How `mysqldump --source-data` links a backup to a binary log position.
- How to read decoded binary log events with `mysqlbinlog` and find the start and end of a specific transaction.
- How to replay the binary log with `--start-position` and `--stop-position` to skip one bad transaction.
- How to rebuild deleted rows from the binary log when no full backup exists.
- Which guardrails keep AI agents from touching production data in the first place.

### What You'll Need

- MySQL 8.4 LTS or newer (MySQL 8.0 works too; the differences are noted where relevant).
- Shell access to the database server, including `sudo` to read the binary log files.
- The `mysql`, `mysqldump`, and `mysqlbinlog` command line tools, which ship with the MySQL server package.
- A MySQL account with administrative privileges such as `root`.
- Basic SQL knowledge: `CREATE TABLE`, `INSERT`, `UPDATE`, and `SELECT`.

Please run this practice on a local or disposable server, never on a real production instance.

## Step 1: Make Sure Binary Logging Is Enabled {#step-1-make-sure-binary-logging-is-enabled}

Point-in-time recovery only works if the binary log was already running before the incident. You cannot turn it on afterward and expect it to remember the past, so the first thing to do on any server you care about is to confirm it is enabled.

Log in to MySQL as an administrative user:

```bash
mysql -u root -p
```

Then check the binary log settings:

```sql
SHOW VARIABLES LIKE 'log_bin%';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
```

```text
<!-- TODO: paste real output -->
```

Here is what each variable tells you:

- `log_bin` must be `ON`. Since MySQL 8.0, binary logging is enabled by default, so a fresh installation usually already has it.
- `log_bin_basename` shows where the log files live and what they are called, typically `/var/lib/mysql/binlog`. The actual files are named `binlog.000001`, `binlog.000002`, and so on.
- `binlog_format` should be `ROW`, the default since MySQL 8.0. In row format, MySQL records the actual before and after values of every changed row, which is what makes precise recovery possible.
- `binlog_expire_logs_seconds` controls how long MySQL keeps old log files. The default `2592000` equals 30 days. Your recovery window can never be longer than this retention period.

Next, look at the current binary log file and position:

```sql
SHOW BINARY LOG STATUS;
```

```text
<!-- TODO: paste real output -->
```

The `File` column is the log file MySQL is currently writing to, and `Position` is the byte offset where the next event will be written. On MySQL 8.0, use `SHOW MASTER STATUS;` instead, because `SHOW BINARY LOG STATUS` was introduced in 8.2 and the old statement was removed in 8.4.

If `log_bin` shows `OFF` on your server, enable it in the MySQL configuration file (for example `/etc/mysql/mysql.conf.d/mysqld.cnf` on Ubuntu) under the `[mysqld]` section:

```ini
[mysqld]
# Enable the binary log and name the files binlog.000001, binlog.000002, ...
log_bin = binlog
# Server ID must be set when binary logging is on
server_id = 1
# Record actual row changes, required for precise recovery
binlog_format = ROW
# Keep 7 days of logs, adjust to be longer than your backup interval
binlog_expire_logs_seconds = 604800
```

Save the file and restart MySQL with `sudo systemctl restart mysql`, then run the `SHOW VARIABLES` queries again to confirm the change. The important rule is that the retention period must be longer than the gap between your full backups; otherwise, the logs needed to bridge a backup and an incident may already be purged.

## Step 2: Create the Sample Production Database {#step-2-create-the-sample-production-database}

With the binary log confirmed, create a small database that plays the role of production. It has one `orders` table with a status column, so you can later see that both inserts and updates survive the recovery.

Create a file called `shop_demo.sql`:

```sql
-- shop_demo.sql
-- A tiny "production" database for the recovery case study.
CREATE DATABASE IF NOT EXISTS shop_demo;
USE shop_demo;

CREATE TABLE orders (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer VARCHAR(100) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Orders that already exist when the nightly backup runs
INSERT INTO orders (customer, total, status) VALUES
    ('Alice Johnson', 150.00, 'paid'),
    ('Budi Santoso', 89.50, 'pending'),
    ('Chen Wei', 230.00, 'paid'),
    ('Dewi Lestari', 45.25, 'shipped'),
    ('Evan Wright', 310.75, 'paid');
```

Save the file and load it:

```bash
mysql -u root -p < shop_demo.sql
```

The `CREATE TABLE` and `INSERT` statements are written to the binary log as they execute, just like any other change on the server.

Verify the data:

```bash
mysql -u root -p -e "SELECT * FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

You should see five orders. Think of them as the data that existed when the nightly backup job started.

## Step 3: Take a Full Backup {#step-3-take-a-full-backup}

A binary log on its own is a list of changes, so it needs a starting point to apply those changes to. That starting point is a full backup, and it must record exactly where in the binary log it was taken. `mysqldump` does this for you with the `--source-data` option.

Run the backup:

```bash
mysqldump -u root -p \
    --single-transaction \
    --source-data=2 \
    --routines \
    --triggers \
    --databases shop_demo > shop_demo_backup.sql
```

Here is why each option matters:

- `--single-transaction` takes a consistent snapshot of InnoDB tables without locking them for the whole dump, so a live application can keep running.
- `--source-data=2` writes the binary log file name and position at the moment of the snapshot into the dump as a SQL comment. The value `2` makes it a comment, so it does not execute during restore. On MySQL versions before 8.0.26, the same option is called `--master-data=2`.
- `--routines` and `--triggers` include stored procedures, functions, and triggers, so the restore is complete.
- `--databases shop_demo` adds `CREATE DATABASE` and `USE` statements to the dump, so it restores into the right database.

Now read the coordinates recorded in the backup:

```bash
grep "CHANGE REPLICATION SOURCE TO" shop_demo_backup.sql
```

```text
<!-- TODO: paste real output -->
```

The line contains `SOURCE_LOG_FILE`, the binary log file that was active during the backup, and `SOURCE_LOG_POS`, the position right after the last change included in the backup. Every change after this position is not in the backup and must come from the binary log.

Store both values in shell variables so the recovery commands later are easier to read. Replace the values with the ones from your own output:

```bash
# Replace with SOURCE_LOG_FILE and SOURCE_LOG_POS from your backup
export BACKUP_BINLOG=binlog.000001
export BACKUP_POS=1234
```

These variables only live in the current terminal session, so keep that terminal open for the rest of the article, or export them again if you open a new one.

## Step 4: Simulate Activity After the Backup {#step-4-simulate-activity-after-the-backup}

In a real shop, the day continues after the backup finishes. Customers place orders, and staff update statuses. These changes exist only in the binary log, which is exactly why restoring the backup alone is not enough.

Log in to MySQL and run some normal business activity:

```sql
USE shop_demo;

-- Two new customers place orders during the day
INSERT INTO orders (customer, total, status) VALUES
    ('Fatimah Zahra', 120.00, 'paid'),
    ('George Miller', 67.80, 'pending');

-- Budi's order gets paid and shipped
UPDATE orders SET status = 'shipped' WHERE id = 2;
```

Then check the table:

```sql
SELECT * FROM orders;
```

```text
<!-- TODO: paste real output -->
```

You now have seven orders, and order `2` has the status `shipped`. None of this is in `shop_demo_backup.sql`. Keep this output in mind, because the recovered table must look exactly like this, plus one more order you will add after the incident.

## Step 5: The Incident: An AI Agent Deletes the Orders {#step-5-the-incident-an-ai-agent-deletes-the-orders}

Now reproduce the incident. Imagine a developer working with an AI coding agent in the terminal and writing a prompt like this:

> The orders table is full of junk from my testing. Clean it up so I can start the demo with an empty list.

The agent reads `.env`, which still contains the production credentials, connects to the database, and executes the most literal interpretation of the request:

```sql
USE shop_demo;
DELETE FROM orders;
```

The statement succeeds without any warning, because a `DELETE` without `WHERE` is perfectly valid SQL. Every row in the table is gone.

Real incidents are rarely noticed immediately. Before anyone realizes what happened, a real customer places a new order on the production site:

```sql
INSERT INTO orders (customer, total, status) VALUES
    ('Hana Putri', 199.99, 'paid');
```

Check the damage:

```sql
SELECT * FROM orders;
```

```text
<!-- TODO: paste real output -->
```

Only Hana's order remains. The seven orders from before the incident are gone, and the backup cannot help with the two orders and the status update that happened after it was taken. This is the situation you will now recover from: bring back everything except the `DELETE`, and keep Hana's order too.

## Step 6: Stop the Bleeding {#step-6-stop-the-bleeding}

Before you restore anything, protect the evidence. The binary log files are the only record of the changes made after the backup, so they must not be purged, overwritten, or buried under new writes during recovery.

In a real incident, the first action is to stop writes from the application, for example by putting it into maintenance mode, and to revoke the credentials the agent used. For this practice, there is no application, so you can go straight to rotating the binary log. Run this in MySQL:

```sql
FLUSH BINARY LOGS;
SHOW BINARY LOGS;
```

```text
<!-- TODO: paste real output -->
```

`FLUSH BINARY LOGS` closes the current log file and starts a new one. This gives you a clean boundary: the incident and everything before it are in the closed files, and any write made during recovery goes into the new file. `SHOW BINARY LOGS` lists every file MySQL still has, together with its size.

Next, copy the binary logs to a safe working directory. Find the data directory first if you are not sure where the logs are:

```sql
SHOW VARIABLES LIKE 'log_bin_basename';
```

Then copy the files from the shell:

```bash
mkdir -p ~/binlog-recovery
sudo cp /var/lib/mysql/binlog.0* ~/binlog-recovery/
sudo chown "$USER":"$USER" ~/binlog-recovery/binlog.0*
ls -l ~/binlog-recovery
```

```text
<!-- TODO: paste real output -->
```

Working on copies protects you from two risks: MySQL purging old files during a long investigation, and an accidental edit to the live files. The `chown` lets you read the copies with `mysqlbinlog` without `sudo`.

Finally, set a variable that points to the log file containing the incident. Because nothing rotated the log between the backup and the incident in this practice, it is the same file as `BACKUP_BINLOG`:

```bash
export INCIDENT_BINLOG=~/binlog-recovery/$BACKUP_BINLOG
```

If your backup and your incident are in different files, you will pass every file from the backup file to the incident file to `mysqlbinlog` in order. The same commands work; only the file list changes.

## Step 7: Find the Destructive Event in the Binary Log {#step-7-find-the-destructive-event-in-the-binary-log}

To skip the bad transaction, you need two numbers: the position where it starts and the position where it ends. `mysqlbinlog` turns the binary format into readable text so you can find them.

Decode everything from the backup position onward into a text file:

```bash
mysqlbinlog \
    --base64-output=DECODE-ROWS \
    --verbose \
    --start-position=$BACKUP_POS \
    "$INCIDENT_BINLOG" > ~/binlog-recovery/decoded.txt
```

Here is what the options do:

- `--base64-output=DECODE-ROWS` hides the raw base64 blobs that row events are stored as.
- `--verbose` rewrites those row events as commented pseudo SQL, such as `### DELETE FROM`, followed by the values of each row.
- `--start-position=$BACKUP_POS` skips everything already included in the backup.

Search for the delete:

```bash
grep -n "### DELETE FROM" ~/binlog-recovery/decoded.txt
```

```text
<!-- TODO: paste real output -->
```

In row format, one `DELETE` statement produces a single transaction that contains row images for every deleted row. Now look at the events just before that line to find where the transaction begins:

```bash
grep -n -B 20 -m 1 "### DELETE FROM" ~/binlog-recovery/decoded.txt
```

```text
<!-- TODO: paste real output -->
```

Every event in the decoded output starts with a line like `# at 2345`, which is the position of that event. A transaction in MySQL 8 starts with a GTID event (shown as `Anonymous_GTID` when GTID mode is off, or `GTID` when it is on), followed by a `Query` event containing `BEGIN`, then a `Table_map` event, then the `Delete_rows` event. The start position of the bad transaction is the `# at` value of that GTID event, not the `Delete_rows` event. If you start the cut at `Delete_rows`, you leave a half transaction behind.

Next, find where the transaction ends:

```bash
sed -n '/### DELETE FROM/,/COMMIT/p' ~/binlog-recovery/decoded.txt | tail -n 5
```

```text
<!-- TODO: paste real output -->
```

The transaction ends with an `Xid` event followed by `COMMIT/*!*/;`. The `Xid` event header shows `end_log_pos`, which is the position right after the commit. That is where the next transaction, Hana's order, begins.

While you are here, confirm that Hana's `INSERT` comes after the delete:

```bash
grep -n "### INSERT INTO" ~/binlog-recovery/decoded.txt
```

```text
<!-- TODO: paste real output -->
```

You should see the inserts from Step 4 before the delete line number and Hana's insert after it. Store the two positions you found:

```bash
# Replace with the positions from your own decoded output
export BAD_START=2345   # "# at" of the GTID event that opens the DELETE transaction
export BAD_END=3456     # end_log_pos of the Xid event that commits it
```

Double check these numbers before moving on. Every later step depends on them.

## Step 8: Restore the Full Backup {#step-8-restore-the-full-backup}

With the positions identified, you can start rebuilding. The first layer is the full backup, which brings the table back to the state it had at 02:00 in our story.

Restore the dump:

```bash
mysql -u root -p --init-command="SET SESSION sql_log_bin = 0" < shop_demo_backup.sql
```

The dump contains `DROP TABLE IF EXISTS`, `CREATE TABLE`, and `INSERT` statements, so it replaces the damaged table completely, including Hana's lonely row. That row is not lost; it is still in the binary log and will return in Step 10.

The `--init-command="SET SESSION sql_log_bin = 0"` part tells MySQL not to write the restore itself into the binary log. Without it, the restore would be logged as new events, and if the server had replicas, they would receive and apply the restore a second time on top of their own data.

Verify the result:

```bash
mysql -u root -p -e "SELECT * FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

You should see the original five orders, with order `2` still `pending`. This is the backup state, before the day's activity.

## Step 9: Replay the Binary Log Up to the Mistake {#step-9-replay-the-binary-log-up-to-the-mistake}

The second layer is every change between the backup and the incident. These are the two new orders and the status update from Step 4.

Replay that range of the binary log:

```bash
mysqlbinlog \
    --disable-log-bin \
    --start-position=$BACKUP_POS \
    --stop-position=$BAD_START \
    "$INCIDENT_BINLOG" | mysql -u root -p
```

Here is how the command works:

- `mysqlbinlog` without the decoding options outputs executable SQL, which is piped into the `mysql` client.
- `--start-position=$BACKUP_POS` begins right after the last change included in the backup, so nothing is applied twice.
- `--stop-position=$BAD_START` stops right before the event that opens the destructive transaction. Events at or after that position are not included.
- `--disable-log-bin` adds `SET sql_log_bin = 0` to the output, so the replayed events are not logged again, for the same reason as in Step 8.

Verify:

```bash
mysql -u root -p -e "SELECT * FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

You should now have seven orders, with order `2` marked `shipped`. The table matches the moment right before the agent ran its `DELETE`.

## Step 10: Replay Everything After the Mistake {#step-10-replay-everything-after-the-mistake}

The final layer is everything after the destructive transaction. In this case study, that is Hana's order. Many recovery guides stop at Step 9, but that silently loses legitimate data created between the incident and its discovery, which in real life can be hours of orders.

Replay the rest of the log, starting right after the bad transaction:

```bash
mysqlbinlog \
    --disable-log-bin \
    --start-position=$BAD_END \
    "$INCIDENT_BINLOG" | mysql -u root -p
```

Starting at `$BAD_END` means the replay begins exactly at the event after the `DELETE` transaction commits. Without a `--stop-position`, `mysqlbinlog` reads to the end of the file, which is the point where you ran `FLUSH BINARY LOGS` in Step 6. If more files were written between the incident and the flush, list them after the first file in the same command, for example `"$INCIDENT_BINLOG" ~/binlog-recovery/binlog.000002`. The `--start-position` only applies to the first file.

There are two alternatives worth knowing:

- **Time based cuts.** If you know when the mistake happened but not the exact position, `mysqlbinlog` accepts `--stop-datetime="2026-09-28 14:03:00"` and `--start-datetime="2026-09-28 14:03:01"`. This is convenient but less precise, because several transactions can share the same second. Positions are always the safer choice.
- **GTID mode.** If your server runs with `gtid_mode=ON`, each transaction has a unique ID such as `3E11FA47-71CA-11E1-9E33-C80AA9429562:23`. You can replay all remaining transactions in one command and skip only the bad one with `--exclude-gtids='3E11FA47-71CA-11E1-9E33-C80AA9429562:23'`. You will find the GTID in the `SET @@SESSION.GTID_NEXT` line right above the delete in the decoded output.

## Step 11: Try It Out {#step-11-try-it-out}

The recovery is complete, so it is time to prove it. A recovery that is not verified is only a hope, so check the result from several angles.

### Scenario 1: All Orders Are Back

Compare the table with the state you recorded in Step 4, plus Hana's order:

```bash
mysql -u root -p -e "SELECT * FROM shop_demo.orders ORDER BY id;"
```

```text
<!-- TODO: paste real output -->
```

You should see eight orders: the five from the backup, the two from the day's activity, and Hana's order with ID `8`. The IDs are the same as before because the row events in the binary log carry the original values, including auto increment keys.

### Scenario 2: The Update Survived

The status change on order `2` only existed in the binary log, so it is a good signal that Step 9 worked:

```bash
mysql -u root -p -e "SELECT id, customer, status FROM shop_demo.orders WHERE id = 2;"
```

```text
<!-- TODO: paste real output -->
```

The status should be `shipped`, not `pending` as in the backup.

### Scenario 3: The Totals Add Up

Row counts can hide subtle problems, such as one row applied twice and another missing. A quick checksum of the business numbers catches those cases:

```bash
mysql -u root -p -e "SELECT COUNT(*) AS orders, SUM(total) AS revenue FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

You should get `8` orders and a revenue of `1213.29`, which is the sum of every order created in this article. If the numbers differ, go back to Step 7 and recheck `BAD_START` and `BAD_END`.

## How the MySQL Binary Log Works {#how-the-mysql-binary-log-works}

Now that you have used the binary log to rescue data, it helps to understand what it actually stores. This explains why the recovery steps are ordered the way they are and why the positions matter so much.

### Events, Positions, and Files

The binary log is a sequence of **events** written to numbered files. Every committed change produces events such as `Query` (statements like `BEGIN` or `CREATE TABLE`), `Table_map` (which table the next row event touches), `Write_rows`, `Update_rows`, `Delete_rows`, and `Xid` (the commit). Each event has a byte position within its file. That is the number you saw after `# at`, and the header also shows `end_log_pos`, where the next event starts.

MySQL writes a whole transaction to the binary log at commit time, so events from different transactions never interleave. This is why cutting at transaction boundaries, from the GTID event to the `Xid` event, removes exactly one transaction and nothing else. A new file starts when the current one reaches `max_binlog_size` (1 GB by default), when the server restarts, or when you run `FLUSH BINARY LOGS`.

### ROW, STATEMENT, and MIXED Formats

MySQL can log changes in three formats:

- **STATEMENT** logs the SQL text, for example `DELETE FROM orders`. It is compact, but replaying it only works if the data is in exactly the same state, and it records nothing about which rows were affected.
- **ROW** logs the actual row values. A `DELETE` of seven rows produces seven row images, each with every column value. This is larger, but it is deterministic and it tells you exactly what was lost.
- **MIXED** uses statements by default and switches to rows when a statement is unsafe to replay.

`ROW` has been the default since MySQL 8.0, and it is the format that makes the next section possible. The related setting `binlog_row_image=FULL`, also the default, ensures that every column is recorded, not only the changed ones.

### Why the Backup Needs the Log Position

Replaying the binary log is only correct when it starts from the exact state it was recorded against. If you replay from a position that is too early, some changes are applied twice. If you start too late, some changes are missing. `--source-data` removes the guesswork by writing the precise position into the backup, taken inside the same consistent snapshot. Without it, you would have to estimate the position from timestamps, which is how recoveries go wrong.

## Recovering Without a Full Backup {#recovering-without-a-full-backup}

Sometimes there is no usable backup at all. If the binary log is in `ROW` format with full row images, the deleted rows are still sitting inside the `Delete_rows` event, because MySQL recorded every column of every row it removed. You can turn those row images back into `INSERT` statements.

Decode only the bad transaction and convert each deleted row to an `INSERT`:

```bash
mysqlbinlog \
    --base64-output=DECODE-ROWS \
    --verbose \
    --start-position=$BAD_START \
    --stop-position=$BAD_END \
    "$INCIDENT_BINLOG" \
| awk '
    # A new "### DELETE FROM `db`.`table`" line starts a new row image
    /^### DELETE FROM/ {
        if (vals != "") print "INSERT INTO " tbl " VALUES (" vals ");"
        tbl = $4; vals = ""; next
    }
    # Column lines look like "###   @1=7"; keep only the value after "="
    /^###   @[0-9]+=/ {
        sub(/^###   @[0-9]+=/, "")
        vals = (vals == "" ? $0 : vals ", " $0)
    }
    END { if (vals != "") print "INSERT INTO " tbl " VALUES (" vals ");" }
' > ~/binlog-recovery/recovered_orders.sql
```

The `mysqlbinlog` part reads just the range between `BAD_START` and `BAD_END`, which is the delete transaction and nothing else. With `--verbose`, each deleted row appears as a `### DELETE FROM` line followed by one `###   @N=value` line per column, where `N` is the column number. The `awk` script collects those values in column order and prints one `INSERT` per deleted row, using the table name from the `DELETE FROM` line.

Inspect the generated file:

```bash
cat ~/binlog-recovery/recovered_orders.sql
```

```text
<!-- TODO: paste real output -->
```

You should see seven `INSERT` statements, one for every order the agent deleted, with the original IDs, totals, and statuses. In a real incident without a backup, you would review this file and run it against the damaged table with `mysql -u root -p < recovered_orders.sql`. In this practice, the rows are already back, so running it would fail with duplicate key errors, which is itself a nice confirmation that the recovered rows match.

Keep a few limits in mind with this approach:

- It only covers rows removed by `DELETE`. For a `DROP TABLE` or `TRUNCATE`, MySQL logs only the statement, not the rows, so you need a backup plus the log from the time the table was created.
- The values are printed in column order without column names, so the script assumes the table structure has not changed since the delete.
- Some types print differently from how you would write them in SQL, for example `TIMESTAMP` columns appear as Unix epoch numbers, so always review the file before running it.

If you run MariaDB instead of MySQL, the equivalent tool is `mariadb-binlog`, and it has a built-in `--flashback` option that generates the reverse of every row event in a range automatically. On MariaDB, `SHOW BINLOG STATUS` replaces `SHOW BINARY LOG STATUS`.

## Guardrails for AI Agents Touching Databases {#guardrails-for-ai-agents-touching-databases}

Recovery is the safety net, but the better outcome is never needing it. The incident in this article happened because an agent had production credentials and nothing stopped a destructive statement. Both are fixable.

### Keep Production Credentials Away from Agents

An agent can only damage what it can connect to. Keep production credentials out of the `.env` file in your local project, and use a separate local or staging database for development. If an agent truly needs to inspect production, give it a dedicated read only account:

```sql
CREATE USER 'agent_readonly'@'localhost' IDENTIFIED BY 'change-this-password';
GRANT SELECT ON shop_demo.* TO 'agent_readonly'@'localhost';
```

Then try to repeat the incident with that account:

```bash
mysql -u agent_readonly -p -e "DELETE FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

MySQL rejects the statement because the account only has `SELECT`. The worst the agent can do now is read data, which is still sensitive, but it is recoverable in a way that deleted data is not.

### Turn On Safe Updates

MySQL has a safety switch that blocks `UPDATE` and `DELETE` statements that have no `WHERE` clause using a key column. The `mysql` client enables it with `--safe-updates`:

```bash
mysql -u root -p --safe-updates -e "DELETE FROM shop_demo.orders;"
```

```text
<!-- TODO: paste real output -->
```

The statement fails with error `1175`, and no rows are deleted. You can also set `SET SESSION sql_safe_updates = 1;` at the start of any session an agent or a script uses. It will not stop a determined `WHERE id > 0`, but it blocks the most common accident.

### Make Recovery Boring

The rest of the defense is routine. Take full backups with `--source-data` on a schedule, keep `binlog_expire_logs_seconds` longer than the backup interval, copy binary logs to separate storage, and practice a restore at least once a quarter, just like you did in this article. Require human approval in your agent's settings before it runs any command that writes to a database. When a recovery has been rehearsed, an incident becomes a checklist instead of a crisis.

## Conclusion {#conclusion}

In this article, you reproduced a realistic vibe coding incident where an AI agent wiped a production table, and then recovered every legitimate change around it. You restored a full backup, replayed the binary log up to the destructive transaction, skipped exactly that transaction, and replayed everything after it, ending with a table that matches what production should look like. You also saw how to rebuild deleted rows when no backup exists and which guardrails keep agents away from production data in the first place.

- **Binary log.** MySQL records every committed change as an event with a position and a timestamp, which lets you rebuild the database at any point in time as long as the logs are retained.
- **Backup coordinates.** `mysqldump --source-data=2` writes the exact binary log file and position into the backup, which tells you precisely where the replay must start.
- **Transaction boundaries.** The bad transaction starts at the `# at` position of its GTID event and ends at the `end_log_pos` of its `Xid` event; cutting anywhere else leaves partial changes behind.
- **Two replays, not one.** Replaying up to the mistake and then again from right after it keeps the legitimate data created between the incident and its discovery.
- **Do not log the recovery.** `sql_log_bin = 0` during the restore and `--disable-log-bin` during the replay keep the recovery itself out of the binary log and away from replicas.
- **Row format saves you.** With `binlog_format=ROW` and full row images, deleted rows can be reconstructed from the log even without a full backup.
- **Guardrails first.** Read only accounts, safe updates, and keeping production credentials out of agent environments prevent the incident, while regular restore drills make recovery routine.
