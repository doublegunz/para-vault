Up until now, the journal entries displayed in the browser have been a hardcoded array written directly inside the controller. This lesson is the turning point. From here on, we will work with a real database.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the `entries` table will exist in your database with the right columns: `id`, `user_id`, `title`, `content`, `created_at`, and `updated_at`. We will not be inserting data from the application yet, but the database foundation will be fully ready.

### What You'll Learn

- How to connect CodeIgniter to a MySQL database through the `.env` file
- What migrations are and why they are better than creating tables manually
- How to generate a migration using Spark
- How to define table columns using CodeIgniter's Forge class
- How to run migrations with `php spark migrate`
- How to roll back migrations when something goes wrong

### What You'll Need

- MySQL running (click **Start All** in Laragon)
- Your MySQL credentials (default: username `root`, empty password)

---

## Step 1: Configure the Database Connection {#step-1-configure-the-database-connection}

Open the `.env` file and find the database configuration section. Uncomment and update these lines:

```
database.default.hostname = localhost
database.default.database = db_catatku
database.default.username = root
database.default.password = 
database.default.DBDriver = MySQLi
database.default.DBPrefix =
database.default.port = 3306
```

You need to create the database `db_catatku` manually. Open HeidiSQL from Laragon (or any MySQL client) and create a new database named `db_catatku`.

> **Note:** Unlike some frameworks, CodeIgniter does not offer to create the database automatically during migration. You need to create it beforehand.

---

## Step 2: Create the Users Migration {#step-2-create-the-users-migration}

Before we create the entries table, we need a users table. CodeIgniter does not include a default users migration, so we will create one ourselves:

```bash
php spark make:migration CreateUsersTable
```

Open the generated file in `app/Database/Migrations/` and update it:

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateUsersTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'name' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
            ],
            'email' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
            ],
            'password' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addUniqueKey('email');
        $this->forge->createTable('users');
    }

    public function down()
    {
        $this->forge->dropTable('users');
    }
}
```

The `up()` method creates the table. The `down()` method drops it for rollback. `addKey('id', true)` sets `id` as the primary key. `addUniqueKey('email')` ensures no two users can share the same email.

---

## Step 3: Create the Entries Migration {#step-3-create-the-entries-migration}

```bash
php spark make:migration CreateEntriesTable
```

Update the generated file:

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateEntriesTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'title' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
            ],
            'content' => [
                'type' => 'TEXT',
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('entries');
    }

    public function down()
    {
        $this->forge->dropTable('entries');
    }
}
```

`addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE')` creates a foreign key relationship. The first `CASCADE` means that if a user is updated, the change cascades. The second `CASCADE` means that if a user is deleted, all their entries are also deleted.

---

## Step 4: Run the Migrations {#step-4-run-the-migrations}

```bash
php spark migrate
```

Output:

```
Running all new migrations...

Running: App\Database\Migrations\CreateUsersTable
Running: App\Database\Migrations\CreateEntriesTable

2 migration(s) were run.
```

---

## Step 5: Verify the Tables {#step-5-verify-the-tables}

Open HeidiSQL from Laragon and check the `db_catatku` database. You should see `users`, `entries`, and `migrations` tables.

You can also verify from the command line:

```bash
php spark db:table entries
```

---

## What is a Migration? {#what-is-a-migration}

Before migrations, developers created tables manually through phpMyAdmin or raw SQL. This approach has real problems: no record of changes, manual replication across environments, and difficult rollbacks.

**Migrations** solve this. A migration is a PHP file that defines a database structure change. With migrations, every change is tracked in code, and setting up the database from scratch requires a single command.

To roll back if something goes wrong:

```bash
php spark migrate:rollback
```

> **Important**: Rolling back is only safe in development. In production, it can cause data loss.

---

## Conclusion {#conclusion}

This lesson moved Catatku from fake data to a real database foundation. Here are the key takeaways:

- The **`.env`** file stores database connection details.
- **Migrations** are PHP files that define database structure changes, tracked in code.
- CodeIgniter's `Forge` class provides methods like `addField()`, `addKey()`, and `addForeignKey()` to define table columns and relationships.
- `php spark migrate` runs all pending migrations. `php spark migrate:rollback` undoes the most recent batch.
- We created both `users` and `entries` tables because CodeIgniter does not include default migrations.
- The `CASCADE` option on foreign keys ensures that deleting a user also deletes all their entries.

In the next lesson, we will learn how to talk to these tables using **CodeIgniter Models**.