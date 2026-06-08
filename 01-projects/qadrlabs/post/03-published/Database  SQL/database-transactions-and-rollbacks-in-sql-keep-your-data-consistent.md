---
title: "Database Transactions and Rollbacks in SQL: Keep Your Data Consistent"
slug: "database-transactions-and-rollbacks-in-sql-keep-your-data-consistent"
category: "Database & SQL"
date: "2026-04-21"
status: "published"
---

Imagine you are building a bank transfer feature. The process has two steps: deduct the balance from the sender, then add it to the recipient. Now imagine the server crashes after the first step but before the second. The sender's money is gone, and the recipient never received it. The data is now in a broken, inconsistent state, and there is no automatic way to recover it.

This problem gets worse in e-commerce. A checkout process might need to deduct product stock, create an order record, and log a payment entry, all at once. If any single step fails, the other completed steps leave ghost data behind: stock is gone but no order exists, or an order is created but inventory is never reduced.

Database transactions solve this exactly. A transaction groups multiple SQL statements into a single atomic unit. Either every statement succeeds and the changes are saved permanently, or any failure triggers a rollback that undoes everything back to the state before the transaction started. No partial writes, no broken data.

## Overview {#overview}

This article walks you through database transactions in MySQL using two realistic scenarios: a balance transfer between bank accounts, and a product checkout that touches multiple tables. You will run every query directly in MySQL, see what broken data looks like without transactions, then fix it with proper transaction control.

### What You'll Build

- A `txn_demo` database with tables for accounts, products, and orders
- A simulated balance transfer that demonstrates both the broken state (without transactions) and the safe state (with transactions and rollback)
- A checkout scenario that keeps stock and order data consistent using transactions
- A partial rollback example using `SAVEPOINT` to undo only part of a transaction

### What You'll Learn

- How `BEGIN`, `COMMIT`, and `ROLLBACK` work together
- What "broken data" actually looks like when a multi-step operation fails midway
- How to verify data integrity with `SELECT` after each scenario
- How `SAVEPOINT` lets you roll back to a specific point without canceling the entire transaction
- Why MySQL's InnoDB engine is required for transaction support

### What You'll Need

- MySQL 8.0 or higher with InnoDB as the default storage engine (this is the default for MySQL 8.0)
- Access to MySQL CLI (`mysql`), or a GUI tool such as DBeaver, TablePlus, or MySQL Workbench
- Basic familiarity with `SELECT`, `INSERT`, and `UPDATE` statements

## Step 1: Prepare the Database and Tables {#step-1-prepare}

Before running any transaction scenario, you need a clean database with some seed data. Open your MySQL client and run the following statements one section at a time.

First, create the database and select it:

```sql
CREATE DATABASE IF NOT EXISTS txn_demo;
USE txn_demo;
```

Next, create the `accounts` table. This will be used for the balance transfer scenario:

```sql
CREATE TABLE accounts (
    id      INT PRIMARY KEY AUTO_INCREMENT,
    name    VARCHAR(100) NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;
```

Notice the `ENGINE=InnoDB` clause. InnoDB is MySQL's transactional storage engine. If you use `MyISAM` instead, MySQL will silently ignore `BEGIN`, `COMMIT`, and `ROLLBACK`, so transactions will not work at all. In MySQL 8.0, InnoDB is already the default, so this clause is mainly here to be explicit.

Now create the `products` and `orders` tables for the checkout scenario:

```sql
CREATE TABLE products (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    name  VARCHAR(100) NOT NULL,
    stock INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE orders (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;
```

Finally, insert the seed data:

```sql
-- Two bank accounts
INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob',   500.00);

-- One product with limited stock
INSERT INTO products (name, stock) VALUES
    ('Mechanical Keyboard', 3);
```

Verify everything was inserted correctly:

```sql
SELECT * FROM accounts;
SELECT * FROM products;
```

You should see output similar to this:

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice | 1000.00 |
|  2 | Bob   |  500.00 |
+----+-------+---------+

+----+---------------------+-------+
| id | name                | stock |
+----+---------------------+-------+
|  1 | Mechanical Keyboard |     3 |
+----+---------------------+-------+
```

The database is ready. Keep this seed data in mind because you will be comparing against it throughout the article.

## Step 2: The Problem Without a Transaction {#step-2-no-transaction}

To understand why transactions matter, you need to see what goes wrong without them. This step deliberately produces broken data so the problem is concrete, not just theoretical.

The scenario: Alice wants to transfer 200.00 to Bob. The operation has two steps. Step one deducts from Alice. Step two adds to Bob. Run only the first UPDATE:

```sql
-- Step one: deduct from Alice
UPDATE accounts SET balance = balance - 200.00 WHERE id = 1;
```

Now simulate a failure before step two ever runs. In a real application this could be a network timeout, an application crash, or a constraint violation. Here, you simply stop and check the data:

```sql
SELECT * FROM accounts;
```

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice |  800.00 |  -- Alice lost 200
|  2 | Bob   |  500.00 |  -- Bob received nothing
+----+-------+---------+
```

This is "data belang": Alice's balance is already reduced, but Bob's balance is unchanged. The 200.00 has effectively disappeared from the system. Because there was no transaction, MySQL committed the first `UPDATE` immediately and permanently. There is nothing to undo.

Before continuing, reset the data to the original state so the next steps start clean:

```sql
UPDATE accounts SET balance = 1000.00 WHERE id = 1;
UPDATE accounts SET balance =  500.00 WHERE id = 2;
```

## Step 3: Transfer With a Transaction and ROLLBACK {#step-3-transfer-transaction}

Now repeat the same transfer scenario, but this time wrapped inside a transaction. The key difference is that changes inside a transaction are held in a temporary state. They are visible within your current session, but they are not permanently written to disk until you call `COMMIT`. If anything goes wrong, `ROLLBACK` discards all of them.

### Scenario A: The Transfer Fails, ROLLBACK Saves the Data

Start the transaction and run the first UPDATE:

```sql
BEGIN;

-- Deduct from Alice
UPDATE accounts SET balance = balance - 200.00 WHERE id = 1;
```

Check the data mid-transaction. Within your session, you will see the change:

```sql
SELECT * FROM accounts;
```

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice |  800.00 |  -- change is visible in this session
|  2 | Bob   |  500.00 |
+----+-------+---------+
```

Now simulate the failure. Maybe the application could not find Bob's account, or a network error occurred before the second UPDATE ran. Call `ROLLBACK`:

```sql
ROLLBACK;
```

Verify the data:

```sql
SELECT * FROM accounts;
```

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice | 1000.00 |  -- fully restored
|  2 | Bob   |  500.00 |  -- untouched
+----+-------+---------+
```

Alice's balance is back to 1000.00. The rollback erased the incomplete change entirely. No money was lost.

### Scenario B: The Transfer Succeeds, COMMIT Makes It Permanent

Now run the happy path, where both steps complete successfully:

```sql
BEGIN;

-- Deduct from Alice
UPDATE accounts SET balance = balance - 200.00 WHERE id = 1;

-- Add to Bob
UPDATE accounts SET balance = balance + 200.00 WHERE id = 2;

-- Both steps succeeded, make the changes permanent
COMMIT;
```

Verify:

```sql
SELECT * FROM accounts;
```

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice |  800.00 |  -- correctly reduced
|  2 | Bob   |  700.00 |  -- correctly increased
+----+-------+---------+
```

The transfer is now permanent. Even if the server restarts after this `COMMIT`, the data will still reflect the transfer.

Before moving on, reset the accounts again:

```sql
UPDATE accounts SET balance = 1000.00 WHERE id = 1;
UPDATE accounts SET balance =  500.00 WHERE id = 2;
```

## Step 4: Checkout Order With a Transaction {#step-4-checkout-transaction}

The balance transfer had two operations touching one table. A checkout scenario is more complex because it touches two tables: `products` (to reduce stock) and `orders` (to create the order record). Both must succeed together or fail together.

### Without a Transaction (Broken Checkout)

First, simulate a broken checkout without a transaction. Deduct the stock, then try to insert an order that references a non-existent product:

```sql
-- Reduce stock for product id 1
UPDATE products SET stock = stock - 1 WHERE id = 1;

-- Try to insert an order for a product that does not exist (id = 999)
-- This will fail due to the foreign key constraint
INSERT INTO orders (product_id, quantity) VALUES (999, 1);
```

The `INSERT` fails with a foreign key error. But the `UPDATE` already ran and was committed automatically. Check the stock:

```sql
SELECT * FROM products;
SELECT * FROM orders;
```

```
+----+---------------------+-------+
| id | name                | stock |
+----+---------------------+-------+
|  1 | Mechanical Keyboard |     2 |  -- stock reduced
+----+---------------------+-------+

Empty set  -- no order was created
```

Stock went from 3 to 2, but no order was recorded. This is the same class of broken data as before, just across two tables this time.

Reset the stock:

```sql
UPDATE products SET stock = 3 WHERE id = 1;
```

### With a Transaction (Safe Checkout)

Now wrap the same operations inside a transaction. This time, the failed INSERT will trigger a rollback that undoes the stock reduction as well:

```sql
BEGIN;

-- Reduce stock
UPDATE products SET stock = stock - 1 WHERE id = 1;

-- Try the bad INSERT again (product_id 999 does not exist)
INSERT INTO orders (product_id, quantity) VALUES (999, 1);

-- This point is never reached because the INSERT above fails
COMMIT;
```

When the `INSERT` fails, MySQL raises an error. You must now explicitly call `ROLLBACK`:

```sql
ROLLBACK;
```

Verify:

```sql
SELECT * FROM products;
SELECT * FROM orders;
```

```
+----+---------------------+-------+
| id | name                | stock |
+----+---------------------+-------+
|  1 | Mechanical Keyboard |     3 |  -- fully restored
+----+---------------------+-------+

Empty set  -- no orphan order
```

Both tables are back to their original state. Now run the happy path with a valid product:

```sql
BEGIN;

UPDATE products SET stock = stock - 1 WHERE id = 1;

INSERT INTO orders (product_id, quantity) VALUES (1, 1);

COMMIT;
```

Verify:

```sql
SELECT * FROM products;
SELECT * FROM orders;
```

```
+----+---------------------+-------+
| id | name                | stock |
+----+---------------------+-------+
|  1 | Mechanical Keyboard |     2 |  -- stock correctly reduced
+----+---------------------+-------+

+----+------------+----------+---------------------+
| id | product_id | quantity | created_at          |
+----+------------+----------+---------------------+
|  1 |          1 |        1 | 2025-04-20 10:00:00 |
+----+------------+----------+---------------------+
```

Stock and order are now in sync. The checkout is atomically complete.

## Step 5: Partial Rollback With SAVEPOINT {#step-5-savepoint}

So far, `ROLLBACK` has always canceled the entire transaction. But sometimes you want more surgical control. What if a transaction has three steps and only the third one fails? You might want to undo just that last step, keep the first two, and then decide whether to retry or continue.

`SAVEPOINT` gives you that control. You can place a named checkpoint anywhere inside a transaction, and then use `ROLLBACK TO SAVEPOINT` to undo only the operations that happened after that checkpoint.

### How SAVEPOINT Works

The syntax involves three commands:

```sql
SAVEPOINT savepoint_name;           -- set a checkpoint
ROLLBACK TO SAVEPOINT savepoint_name; -- undo back to the checkpoint
RELEASE SAVEPOINT savepoint_name;   -- remove the checkpoint (optional cleanup)
```

### Example: Three-Step Transaction With Partial Rollback

First, reset the data to a clean state:

```sql
UPDATE accounts SET balance = 1000.00 WHERE id = 1;
UPDATE accounts SET balance =  500.00 WHERE id = 2;
DELETE FROM orders;
UPDATE products SET stock = 3 WHERE id = 1;
```

Now run a transaction with three logical steps: transfer 100 from Alice to Bob, set a savepoint, then attempt a second transfer that you decide to cancel:

```sql
BEGIN;

-- Step A: Transfer 100 from Alice to Bob
UPDATE accounts SET balance = balance - 100.00 WHERE id = 1;
UPDATE accounts SET balance = balance + 100.00 WHERE id = 2;

-- Set a savepoint after Step A is complete
SAVEPOINT after_first_transfer;

-- Step B: Transfer another 100 from Alice to Bob
-- (Imagine this is a duplicate request you caught later in the process)
UPDATE accounts SET balance = balance - 100.00 WHERE id = 1;
UPDATE accounts SET balance = balance + 100.00 WHERE id = 2;

-- You detect the duplicate. Roll back only to the savepoint.
-- Step A remains. Step B is undone.
ROLLBACK TO SAVEPOINT after_first_transfer;

-- Clean up the savepoint
RELEASE SAVEPOINT after_first_transfer;

-- Commit only Step A
COMMIT;
```

Verify:

```sql
SELECT * FROM accounts;
```

```
+----+-------+---------+
| id | name  | balance |
+----+-------+---------+
|  1 | Alice |  900.00 |  -- only 100 was deducted, not 200
|  2 | Bob   |  600.00 |  -- only 100 was added, not 200
+----+-------+---------+
```

The first transfer (Step A) is committed. The duplicate second transfer (Step B) was rolled back. The savepoint acted as a precise undo marker inside the transaction, without throwing away the work done before it.

## Understanding How Transactions Work Under the Hood {#how-transactions-work}

Now that you have seen transactions in action, it helps to understand the mechanics behind them so you can reason about edge cases and avoid common mistakes.

### ACID Properties

Every database transaction is designed around four guarantees, commonly abbreviated as ACID.

**Atomicity** means all operations in a transaction are treated as a single unit. Either all of them succeed, or none of them do. This is the core property that prevents partial writes.

**Consistency** means the database moves from one valid state to another. Constraints like foreign keys, `NOT NULL`, and `UNIQUE` are still enforced inside transactions. A transaction that violates a constraint cannot be committed.

**Isolation** means changes made inside an open transaction are not visible to other sessions until a `COMMIT` is issued. This is why, in Step 3, Alice's deducted balance was visible within your own session but would appear as 1000.00 to any other concurrent session until you committed.

**Durability** means once a `COMMIT` is issued, the changes survive permanently, even if the server loses power immediately afterward. InnoDB achieves this through a write-ahead log called the redo log.

### Autocommit Mode in MySQL

MySQL has a setting called `autocommit`, which is enabled by default (`autocommit = 1`). In autocommit mode, every single SQL statement that you run outside of an explicit `BEGIN` block is automatically wrapped in its own transaction and immediately committed. This is why, in Step 2, the first `UPDATE` was permanently written even though you never typed `COMMIT`: MySQL committed it automatically.

When you type `BEGIN`, MySQL temporarily disables autocommit for that block, and the transaction only ends when you type `COMMIT` or `ROLLBACK`.

You can check your current autocommit setting with:

```sql
SELECT @@autocommit;
```

```
+--------------+
| @@autocommit |
+--------------+
|            1 |
+--------------+
```

You can disable autocommit globally for a session with `SET autocommit = 0`, but this is generally not recommended unless you have a specific reason. It is safer and more explicit to use `BEGIN` and `COMMIT` to mark your transaction boundaries intentionally.

### What InnoDB Does Internally

When you call `BEGIN`, InnoDB starts tracking all row-level changes in an internal structure called the **undo log**. The undo log stores enough information to reverse every change you make during the transaction. When you call `ROLLBACK`, InnoDB reads the undo log and applies the reverse operations in the opposite order, restoring each row to its pre-transaction state.

When you call `COMMIT`, InnoDB writes the final changes to the **redo log** and marks the transaction as complete. From that point, the undo log entries for the transaction can eventually be cleaned up by a background process called the **purge thread**.

This is why rollbacks in long transactions can be slow: the longer the transaction, the larger the undo log, and the more work the rollback has to do to reverse everything.

### A Practical Warning About Long Transactions

A transaction that stays open for a long time holds row-level locks on the rows it has modified. Other sessions that try to update the same rows will be blocked until the transaction is committed or rolled back. In a high-traffic application, a transaction that runs for several seconds can cause a cascade of blocked queries that degrades the entire system. Always aim to keep your transactions as short as possible: open them late, close them early.

## Conclusion {#conclusion}

You have now seen database transactions from the problem all the way through to the underlying mechanics. Here are the key takeaways from this article.

- **Without transactions, partial writes are permanent.** Any multi-step operation that fails midway leaves the database in a broken, inconsistent state, and there is no automatic recovery. This is what inconsistent data looks like in practice.
- **`BEGIN`, `COMMIT`, and `ROLLBACK` form the core transaction boundary.** `BEGIN` opens a transaction, `COMMIT` makes all changes permanent, and `ROLLBACK` discards all changes made since `BEGIN`.
- **InnoDB is required for MySQL transactions.** MyISAM ignores transaction commands silently, which is a common source of confusion. Always use InnoDB for any table where data integrity matters.
- **`SAVEPOINT` enables partial rollbacks.** You can place named checkpoints inside a transaction and roll back to any of them without discarding the entire transaction. This is useful for complex workflows with multiple independent sub-steps.
- **Autocommit wraps every standalone statement in its own transaction.** This is why a single `UPDATE` without `BEGIN` is immediately permanent. Using explicit `BEGIN ... COMMIT` blocks is always clearer and safer for multi-step operations.
- **Keep transactions short.** Long-running transactions hold locks and block other sessions. Open a transaction as late as possible, do the minimum work needed, and close it immediately.
- **The next step is application-level integration.** In a real project, you would not write raw SQL transaction blocks by hand. The next article in this series covers how Laravel and CodeIgniter wrap these same `BEGIN`, `COMMIT`, and `ROLLBACK` commands in a clean, framework-native API so your application code stays readable and safe.