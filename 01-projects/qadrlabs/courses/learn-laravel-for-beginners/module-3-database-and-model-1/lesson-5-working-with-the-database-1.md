Up until now, the journal entries displayed in the browser have been a hardcoded array written directly inside the controller. We used that fake data on purpose so we could focus on understanding routing, views, and MVC first. This lesson is the turning point. From here on, we will work with a real database, and the entries we store will be truly persistent. They will not disappear when the server restarts.

## Overview {#overview}

### What You'll Build

By the end of this lesson, the `entries` table will exist in your database with the right columns: `id`, `user_id`, `title`, `content`, `created_at`, and `updated_at`. We will not be inserting data from the application yet (that comes in later lessons), but the database foundation will be fully ready.

### What You'll Learn

- How to connect Laravel to a MySQL database through the `.env` file
- What migrations are and why they are far better than creating tables manually
- How to generate a model and migration together using a single Artisan command
- How to define table columns using Laravel's Schema Builder
- How to run migrations with `php artisan migrate`
- How to roll back migrations when something goes wrong
- Common Blueprint column types you will use in real projects

### What You'll Need

- The `catatku` project open in VS Code with the development server running
- MySQL running (if you are using Laragon, click **Start All**)
- Your MySQL credentials: database name, username, and password. If you are using Laragon with the default configuration, the username is `root` and the password is empty

---

## Step 1: Configure the Database Connection {#step-1-configure-the-database-connection}

Before Laravel can talk to a database, we need to tell it where the database is. Open the `.env` file in the root of your project and find the database configuration section:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_catatku
DB_USERNAME=root
DB_PASSWORD=
```

Update `DB_USERNAME` and `DB_PASSWORD` to match the MySQL credentials on your machine. If you are using Laragon or XAMPP with the default configuration, the username is `root` and the password is empty (leave `DB_PASSWORD=` blank).

The `DB_DATABASE` value is `db_catatku`. This is the name of the database Laravel will use. You do not need to create it manually. Laravel will offer to create it for you when we run the migrations in a later step.

> **Security note**: The `.env` file is already included in Laravel's default `.gitignore`. This means it will never be committed to Git, which is the correct practice because this file contains sensitive information like database passwords.

---

## Step 2: Create the Entry Model and Migration {#step-2-create-the-entry-model-and-migration}

Laravel lets you generate a model and its migration file in a single command. Run the following in your terminal:

```bash
php artisan make:model Entry -m
```

The `-m` flag means "also create a migration file for this model." You should see this output:

```
$ php artisan make:model Entry -m

   INFO  Model [app/Models/Entry.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_29_080101_create_entries_table.php] created successfully. 
```

Two files are created at once: the model `Entry.php` at `app/Models/Entry.php` and a migration file inside `database/migrations/`. We will come back to the model in the next lesson. For now, let us focus on the migration.

Notice how Laravel automatically figured out that a model called `Entry` should correspond to a table called `entries`. This is one of Laravel's conventions: model names are singular (`Entry`), and table names are the plural form (`entries`). You never need to specify this mapping manually.

---

## Step 3: Define the Table Structure {#step-3-define-the-table-structure}

Open the migration file that was just created inside `database/migrations/`. The filename starts with a timestamp, for example `2026_03_29_080101_create_entries_table.php`.

Here is what it looks like:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('entries', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('entries');
    }
};
```

Laravel provides two methods in every migration. The `up()` method runs when you execute `php artisan migrate`. This is where you define what to create. The `down()` method runs when you roll back the migration. It should undo whatever `up()` did. In this case, `up()` creates the `entries` table and `down()` drops it.

The default migration only includes `id()` and `timestamps()`. We need to add columns for our journal entry data. Update the `up()` method to look like this:

```php
public function up(): void
{
    Schema::create('entries', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->string('title');
        $table->text('content');
        $table->timestamps();
    });
}
```

Here is what each column does:

`$table->id()` creates an auto-incrementing `id` column as the primary key. This was already included in the default migration. Every entry will get a unique numeric ID automatically.

`$table->foreignId('user_id')->constrained()->cascadeOnDelete()` creates a `user_id` column that is a foreign key pointing to the `users` table. The `constrained()` method automatically sets up the relationship to `users.id`. The `cascadeOnDelete()` part means that if a user is deleted, all of their journal entries are automatically deleted too. This prevents orphaned records from lingering in the database.

`$table->string('title')` creates a `title` column of type VARCHAR(255), suitable for short text like entry titles.

`$table->text('content')` creates a `content` column of type TEXT, which can hold much longer text than VARCHAR. This is appropriate for the body of a journal entry, which could be several paragraphs long.

`$table->timestamps()` creates two columns: `created_at` and `updated_at`. Laravel fills these in automatically whenever a record is created or updated, so you never need to manage them manually.

---

## Step 4: Run the Migration {#step-4-run-the-migration}

With the migration file ready, run the following command to create the table in the database:

```bash
php artisan migrate
```

If the `db_catatku` database does not exist yet, Laravel will ask if you want to create it automatically:

```
WARN  The database 'db_catatku' does not exist on the 'mysql' connection.

┌ Would you like to create it? ──────────────────────────────┐
│ ● Yes / ○ No                                               │
└────────────────────────────────────────────────────────────┘
```

Select `Yes`. Laravel will create the database and run all pending migrations:

```
INFO  Running migrations.

  0001_01_01_000000_create_users_table .............. DONE
  0001_01_01_000001_create_cache_table .............. DONE
  0001_01_01_000002_create_jobs_table ............... DONE
  xxxx_xx_xx_create_entries_table .................. DONE
```

Notice that Laravel also runs several built-in migrations. The `create_users_table` migration is especially important because we will need the `users` table when we build the authentication feature later. The `user_id` foreign key in our `entries` table already points to this table.

---

## Step 5: Verify the Table {#step-5-verify-the-table}

To confirm that the migration worked, you can check the database using Laragon's built-in database manager or any MySQL client. The `entries` table should have six columns: `id`, `user_id`, `title`, `content`, `created_at`, and `updated_at`.

You can also verify from the terminal by opening Laravel's Tinker REPL:

```bash
php artisan tinker
```

Then run:

```php
Schema::getColumnListing('entries');
```

Output:
```
$ php artisan tinker
Psy Shell v0.12.22 (PHP 8.4.5 — cli) by Justin Hileman
New PHP manual is available (latest: 3.0.2). Update with `doc --update-manual`

> Schema::getColumnListing('entries');

= [
    "id",
    "user_id",
    "title",
    "content",
    "created_at",
    "updated_at",
  ]


```

This will return an array of column names, confirming that the table was created with the correct structure.

Type `exit` to leave Tinker.

---

## What is a Migration? {#what-is-a-migration}

Now that you have created and run a migration, let us step back and understand why this approach matters.

Before migrations existed, developers created database tables manually through phpMyAdmin or by running raw SQL statements:

```sql
CREATE TABLE entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

This approach has real problems. There is no record of who created or changed what. Other developers on the team have to run the same SQL statements manually on their own machines. And if something goes wrong, rolling back has to be done by hand.

**Migrations** solve all of these problems. A migration is a PHP file that defines a database structure change. With migrations, every change to the database is tracked in Git just like regular code changes. Setting up the database from scratch requires a single command (`php artisan migrate`). And rolling back is just as easy (`php artisan migrate:rollback`).

This is one of the most valuable features of Laravel in a professional setting. It is not just a framework convenience. It is a real solution to a real problem that every development team faces.

---

## Rolling Back Migrations {#rolling-back-migrations}

If you made a mistake in a migration and need to redo it, you can roll back:

```bash
php artisan migrate:rollback
```

This command runs the `down()` method of the most recently executed migrations. In our case, it would drop the `entries` table. After fixing the migration file, you can run `php artisan migrate` again to recreate the table.

> **Important**: Rolling back is only safe in a development environment. In production, rolling back can cause real data loss. Always double-check your migrations before running them in production.

---

## Blueprint Column Types Reference {#blueprint-column-types-reference}

Laravel's Schema Builder provides many column types through the `Blueprint` class. Here are the ones you will encounter most often:

```php
$table->string('title');            // VARCHAR(255) for short text
$table->string('title', 100);      // VARCHAR(100) with a custom length
$table->text('content');            // TEXT for long, unbounded text
$table->integer('page_count');      // INTEGER
$table->decimal('price', 10, 2);   // DECIMAL for precise numbers like prices
$table->boolean('is_published');    // TINYINT(1) for true/false values
$table->foreignId('user_id');       // UNSIGNED BIGINT for foreign keys
```

You do not need to memorize all of these right now. We will introduce each type as we need it throughout the course. The key takeaway is that Laravel provides a PHP method for every common column type, so you never need to write raw SQL to define your table structure.

---

## Conclusion {#conclusion}

This lesson moved Catatku from fake data to a real database foundation. Here are the key takeaways:

- The **`.env`** file stores your database connection details. Laravel reads these values to connect to MySQL. This file should never be committed to Git.
- **Migrations** are PHP files that define database structure changes. They are tracked in Git, can be run with a single command, and can be rolled back when needed.
- `php artisan make:model Entry -m` creates both a model and a migration file in one step. Laravel automatically maps the singular model name (`Entry`) to the plural table name (`entries`).
- The **`up()`** method defines what happens when the migration runs. The **`down()`** method undoes it.
- `foreignId('user_id')->constrained()->cascadeOnDelete()` creates a foreign key relationship to the `users` table and ensures that deleting a user also deletes all of their entries.
- `$table->string()` is for short text, `$table->text()` is for long text, and `$table->timestamps()` automatically adds `created_at` and `updated_at` columns.
- `php artisan migrate` runs all pending migrations. `php artisan migrate:rollback` undoes the most recent batch.
- Rolling back is safe in development but dangerous in production because it can cause data loss.

In the next lesson, we will learn how to talk to the `entries` table we just created using **Eloquent**, Laravel's ORM. Instead of writing raw SQL, you will write expressive PHP code like `auth()->user()->entries()->latest()->get()`, and you will quickly see why that is a much more enjoyable way to work with data.