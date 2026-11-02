## 1. Before You Begin

Up until now, the journal entries in Catatku have been a hardcoded array sitting inside the controller. This lesson is the turning point. From here on, every piece of data in the application lives in a real database, and Symfony communicates with it through Doctrine ORM.

Doctrine ORM is Symfony's default database layer. Instead of writing raw SQL queries, you define PHP classes called entities that map to database tables. Doctrine handles the translation between PHP objects and database rows, and a tool called migrations manages changes to the database schema over time.

This lesson covers three things: connecting Symfony to MySQL, creating the `User` and `Entry` entities, and generating and running your first migrations. By the end, the two tables your application needs will exist in the database, ready to store real data.

### What You'll Build

By the end of this lesson, the `entry` and `user` tables will exist in your MySQL database, created through Doctrine migrations. The controller still uses the hardcoded array for now. In Lesson 6, you will replace it with real database queries.

### What You'll Learn

- ✅ How to connect Symfony to a MySQL database through the `.env` file
- ✅ What Doctrine ORM is and how it differs from writing raw SQL
- ✅ How to create entities using `make:entity` and `make:user`
- ✅ How Doctrine uses PHP attributes like `#[ORM\Column]` for table mapping
- ✅ How to generate and run database migrations
- ✅ How to roll back a migration if something goes wrong

### What You'll Need

- MySQL running (click **Start All** in Laragon)
- Your MySQL credentials (Laragon default: username `root`, empty password)

---

## 2. Connecting to the Database

Before creating any entities, Symfony needs to know how to reach the database. This connection is configured in a single line inside the `.env` file.

### Step 1: Update the DATABASE_URL

Open `.env` in the project root and find the `DATABASE_URL` line. Replace it with the following:

```env
DATABASE_URL="mysql://root:@127.0.0.1:3306/db_catatku?serverVersion=8.0&charset=utf8mb4"
```

The format of the connection string is `mysql://username:password@host:port/database_name`. In this string, `root` is the username, the password is empty (nothing between `:` and `@`), `127.0.0.1:3306` is the local MySQL address and port, and `db_catatku` is the database name Doctrine will use. The `serverVersion=8.0` parameter helps Doctrine generate SQL that is compatible with your MySQL version.

If your MySQL installation has a password, add it after `root:` (for example, `root:mypassword@127.0.0.1:3306/db_catatku`).

### Step 2: Create the Database

Now ask Doctrine to create the database itself:

```bash
php bin/console doctrine:database:create
```

Output:

```text
Created database `db_catatku` for connection named default
```

Unlike some frameworks that expect the database to exist before running migrations, Symfony provides this command to create it first. If you see an error about connection refused, Laragon's MySQL service is not running. Click **Start All** in Laragon and try again.

---

## 3. Creating the User Entity

Symfony's Security component requires the user entity to implement specific interfaces. Instead of creating it by hand, use the dedicated `make:user` command, which generates the correct class structure automatically.

### Step 1: Run make:user

Run the following command:

```bash
php bin/console make:user
```

When prompted, answer the questions as follows:

- Name of the security user class: `User`
- Store user data in the database: `yes`
- Property for unique display name: `email`
- Hash and check user passwords: `yes`

Output:

```text

 The name of the security user class (e.g. User) [User]:
 > User

 Do you want to store user data in the database (via Doctrine)? (yes/no) [yes]:
 > yes

 Enter a property name that will be the unique "display" name for the user (e.g. email, username, uuid) [email]:
 > email

 Will this app need to hash/check user passwords? Choose No if passwords are not needed or will be checked/hashed by some other system (e.g. a single sign-on server).

 Does this app need to hash/check user passwords? (yes/no) [yes]:
 > yes

 created: src/Entity/User.php
 created: src/Repository/UserRepository.php
 updated: src/Entity/User.php
 updated: config/packages/security.yaml


  Success!


 Next Steps:
   - Review your new App\Entity\User class.
   - Use make:entity to add more fields to your User entity and then run make:migration.
   - Create a way to authenticate! See https://symfony.com/doc/current/security.html
```

This generates `src/Entity/User.php`. The class is annotated with `#[ORM\Entity]` and implements both `UserInterface` and `PasswordAuthenticatedUserInterface`, which are required by Symfony's Security component. Without these interfaces, Symfony would not be able to use this class for authentication.

### Step 2: Add the name Property

The generated User entity has `id`, `email`, `roles`, and `password`. Catatku also needs a `name` field to display the logged-in user's name in the navigation. Add it using `make:entity`:

```bash
php bin/console make:entity User
```

When prompted, add:

- Property name: `name`
- Type: `string`
- Length: `255`
- Nullable: `no`

Press Enter on the empty property prompt to finish.

Output:

```text
 Your entity already exists! So let's add some new fields!

 New property name (press <return> to stop adding fields):
 > name

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/User.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 >



  Success!


 Next: When you're ready, create a migration with php bin/console make:migration

```

After this step, the User entity has `id`, `email`, `roles`, `password`, and `name` properties. Doctrine will create a database column for each one.

---

## 4. Creating the Entry Entity

With the User entity done, you can create the Entry entity. This is the central data model for Catatku: every journal entry belongs to one user.

### Step 1: Create the Base Properties

Run `make:entity` to generate the Entry class:

```bash
php bin/console make:entity Entry
```

Add the following properties when prompted:

- `title` (type: string, length: 255, not nullable)
- `content` (type: text, not nullable)
- `createdAt` (type: datetime_immutable, not nullable)
- `updatedAt` (type: datetime_immutable, nullable: yes)

Press Enter on the empty property prompt to finish.

Output:

```text
 created: src/Entity/Entry.php
 created: src/Repository/EntryRepository.php

 Entity generated! Now let's add some fields!
 You can always add more fields later manually or by re-running this command.

 New property name (press <return> to stop adding fields):
 > title

 Field type (enter ? to see all types) [string]:
 > string

 Field length [255]:
 > 255

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Entry.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > content

 Field type (enter ? to see all types) [string]:
 > text

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Entry.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > createdAt

 Field type (enter ? to see all types) [datetime_immutable]:
 > datetime_immutable

 Can this field be null in the database (nullable) (yes/no) [no]:
 > no

 updated: src/Entity/Entry.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 > updatedAt

 Field type (enter ? to see all types) [datetime_immutable]:
 > datetime_immutable

 Can this field be null in the database (nullable) (yes/no) [no]:
 > yes

 updated: src/Entity/Entry.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 >



  Success!


 Next: When you're ready, create a migration with php bin/console make:migration

```

Doctrine maps each property to a database column. `string` becomes `VARCHAR(255)`, `text` becomes `TEXT`, and `datetime_immutable` becomes `DATETIME`. The `nullable: yes` on `updatedAt` means the column allows `NULL`, which is important because a new entry has not been updated yet.

### Step 2: Add the Relationship to User

Run `make:entity` again to add the relationship:

```bash
php bin/console make:entity Entry
```

When prompted, configure the relationship:

- Property name: `user`
- Type: `relation`
- Related class: `User`
- Relation type: `ManyToOne`
- Is the property nullable: `no`
- Add a new property to User to access entries: `yes`
- Property name in User: `entries`
- Orphan removal: `yes`

Output:

```text
 Your entity already exists! So let's add some new fields!

 New property name (press <return> to stop adding fields):
 > user

 Field type (enter ? to see all types) [string]:
 > relation

 What class should this entity be related to?:
 > User

What type of relationship is this?
 ------------ ------------------------------------------------------------------
  Type         Description
 ------------ ------------------------------------------------------------------
  ManyToOne    Each Entry relates to (has) one User.
               Each User can relate to (can have) many Entry objects.

  OneToMany    Each Entry can relate to (can have) many User objects.
               Each User relates to (has) one Entry.

  ManyToMany   Each Entry can relate to (can have) many User objects.
               Each User can also relate to (can also have) many Entry objects.

  OneToOne     Each Entry relates to (has) exactly one User.
               Each User also relates to (has) exactly one Entry.
 ------------ ------------------------------------------------------------------

 Relation type? [ManyToOne, OneToMany, ManyToMany, OneToOne]:
 > ManyToOne

 Is the Entry.user property allowed to be null (nullable)? (yes/no) [yes]:
 > no

 Do you want to add a new property to User so that you can access/update Entry objects from it - e.g. $user->getEntries()? (yes/no) [yes]:
 > yes

 A new property will also be added to the User class so that you can access the related Entry objects from it.

 New field name inside User [entries]:
 > entries

 Do you want to activate orphanRemoval on your relationship?
 A Entry is "orphaned" when it is removed from its related User.
 e.g. $user->removeEntry($entry)

 NOTE: If a Entry may *change* from one User to another, answer "no".

 Do you want to automatically delete orphaned App\Entity\Entry objects (orphanRemoval)? (yes/no) [no]:
 > yes

 updated: src/Entity/Entry.php
 updated: src/Entity/User.php

 Add another property? Enter the property name (or press <return> to stop adding fields):
 >



  Success!


 Next: When you're ready, create a migration with php bin/console make:migration

```

`ManyToOne` means many entries can belong to one user. Doctrine will add a `user_id` foreign key column to the `entry` table. `orphanRemoval: yes` means an entry that is removed from its user's `entries` collection is deleted from the database instead of being left without an owner. Doctrine also removes a user's entries when the user itself is removed through the entity manager, so no entry is ever left pointing to a user that no longer exists.

### Step 3: Review the Generated Entity

Open `src/Entity/Entry.php` to verify the result:

```php
<?php

namespace App\Entity;

use App\Repository\EntryRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: EntryRepository::class)]
class Entry
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    private ?string $title = null;

    #[ORM\Column(type: Types::TEXT)]
    private ?string $content = null;

    #[ORM\Column]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(nullable: true)]
    private ?\DateTimeImmutable $updatedAt = null;

    #[ORM\ManyToOne(inversedBy: 'entries')]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    // Getters and setters generated below...
}
```

Each PHP attribute instructs Doctrine how to handle that property. `#[ORM\Entity(repositoryClass: EntryRepository::class)]` marks the class as a database entity and links it to its query class. `#[ORM\Id]` and `#[ORM\GeneratedValue]` tell Doctrine that `id` is the primary key and should be auto-incremented by the database. `#[ORM\ManyToOne(inversedBy: 'entries')]` defines the relationship: each Entry belongs to one User, and the User's `entries` property holds the reverse collection.

### Step 4: Add the Constructor

Add a constructor to set `createdAt` automatically every time a new Entry object is created. Place it inside the `Entry` class, right after the properties and before the getters and setters. The complete `src/Entity/Entry.php` now looks like this:

```php
<?php

namespace App\Entity;

use App\Repository\EntryRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: EntryRepository::class)]
class Entry
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    private ?string $title = null;

    #[ORM\Column(type: Types::TEXT)]
    private ?string $content = null;

    #[ORM\Column]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(nullable: true)]
    private ?\DateTimeImmutable $updatedAt = null;

    #[ORM\ManyToOne(inversedBy: 'entries')]
    #[ORM\JoinColumn(nullable: false)]
    private ?User $user = null;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getTitle(): ?string
    {
        return $this->title;
    }

    public function setTitle(string $title): static
    {
        $this->title = $title;

        return $this;
    }

    public function getContent(): ?string
    {
        return $this->content;
    }

    public function setContent(string $content): static
    {
        $this->content = $content;

        return $this;
    }

    public function getCreatedAt(): ?\DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function setCreatedAt(\DateTimeImmutable $createdAt): static
    {
        $this->createdAt = $createdAt;

        return $this;
    }

    public function getUpdatedAt(): ?\DateTimeImmutable
    {
        return $this->updatedAt;
    }

    public function setUpdatedAt(?\DateTimeImmutable $updatedAt): static
    {
        $this->updatedAt = $updatedAt;

        return $this;
    }

    public function getUser(): ?User
    {
        return $this->user;
    }

    public function setUser(?User $user): static
    {
        $this->user = $user;

        return $this;
    }
}
```

The only line you typed by hand is the `__construct()` method; everything else was generated by `make:entity`. Without this constructor, you would need to manually call `$entry->setCreatedAt(new \DateTimeImmutable())` every time you create an entry. By setting it in the constructor, the timestamp is always populated automatically, reducing the chance of a forgotten field.

---

## 5. Generating and Running Migrations

With both entities defined, the next step is to create the database tables that match them. Doctrine compares your entity definitions to the current database schema and generates the exact SQL needed to bring the database up to date.

### Step 1: Generate the Migration File

```bash
php bin/console make:migration
```

Output:

```text
 created: src/Migrations/Version20261102000811.php


  Success!


 Review the new migration then run it with php bin/console doctrine:migrations:migrate
 See https://symfony.com/doc/current/bundles/DoctrineMigrationsBundle/index.html
```

This creates a new file inside the `src/Migrations/` directory. The number in the file name is a timestamp of when you ran the command, so your file name will be different. The file contains two methods, `up()` and `down()`. `up()` holds the SQL to apply the change (creating the tables). `down()` holds the SQL to reverse it (dropping the tables). Open the generated file and review the SQL before running it. Besides `CREATE TABLE user` and `CREATE TABLE entry`, you will also see `CREATE TABLE messenger_messages`. That table belongs to the Messenger component, which the `webapp` package configured to store queued messages in the database. Catatku does not use it, but it is harmless to keep.

### Step 2: Run the Migration

```bash
php bin/console doctrine:migrations:migrate
```

Doctrine will ask for confirmation before running. Type `yes` and press Enter.

Output:

```text

 WARNING! You are about to execute a migration in database "db_catatku" that could result in schema changes and data loss. Are you sure you wish to continue? (yes/no) [yes]:
 > yes

[notice] Migrating up to App\Migrations\Version20261102000811
[notice] finished in 34.3ms, used 58.5M memory, 1 migrations executed, 4 sql queries

 [OK] Successfully migrated to version: App\Migrations\Version20261102000811

```

The `user` and `entry` tables are now created in `db_catatku`. Doctrine also creates a `doctrine_migration_versions` table to track which migrations have already been applied, so you can safely run this command again without re-applying the same changes.

To roll back the last migration if something went wrong:

```bash
php bin/console doctrine:migrations:migrate prev
```

Output:

```text

 WARNING! You are about to execute a migration in database "db_catatku" that could result in schema changes and data loss. Are you sure you wish to continue? (yes/no) [yes]:
 > yes

[notice] Migrating down to 0
[notice] finished in 23.1ms, used 24M memory, 1 migrations executed, 4 sql queries

 [OK] Successfully migrated to version: 0

```

Because this is the first migration, rolling back returns the database to version `0` and drops the tables again. If you tried the rollback, run `php bin/console doctrine:migrations:migrate` once more before continuing, so the tables exist for the rest of the course.

Rollbacks are only safe in development. In production, rolling back a migration that has already affected live data can result in data loss.

---

## 6. Verify the Tables

After running the migration, confirm that the tables exist in the database. Open HeidiSQL from inside Laragon and browse to the `db_catatku` database. You should see four tables: `user`, `entry`, `messenger_messages`, and `doctrine_migration_versions`.

You can also verify directly from the command line using Doctrine's schema validation tool:

```bash
php bin/console doctrine:schema:validate
```

Output:

```text

```

If all entity mappings are correct and the schema is synchronized, Doctrine reports that the mapping and database are valid. If you see an error, it usually means the migration was not run or an entity attribute has a typo.

---

## 7. What is Doctrine ORM?

Doctrine ORM maps PHP classes to database tables. Instead of writing raw SQL queries like `SELECT * FROM entry WHERE user_id = 1`, you work with PHP objects. Each entity class corresponds to one table, each property corresponds to one column, and each instance corresponds to one row.

The key difference from simpler database tools is that Doctrine uses a **Data Mapper** pattern. Your entity classes are plain PHP objects with no database code inside them. They only have properties, getters, and setters. All database operations go through two other classes: the `EntityManager` (for saving and deleting) and `Repository` classes (for querying). This separation keeps your entities clean and focused on representing data, not interacting with the database.

---

## 8. Fix the Errors in Your Code

**Error 1: DATABASE_URL connection refused.**

This error means PHP cannot reach MySQL. The database server is not running.

```bash
# Wrong: running a Doctrine command while MySQL is stopped
php bin/console doctrine:database:create
```

Output:

```text
Could not create database `db_catatku` for connection named default
An exception occurred in the driver: SQLSTATE[HY000] [2002] Connection refused
```

The text after `[2002]` depends on your operating system. On Windows it says that no connection could be made because the target machine actively refused it, but the `[2002]` code means the same thing: nothing is listening on the MySQL port.

```bash
# Correct: click "Start All" in Laragon first, then run the command again
php bin/console doctrine:database:create
```

Every Doctrine command requires MySQL to be running. In Laragon, click **Start All** to start both Nginx/Apache and MySQL before running any `doctrine:` commands.

**Error 2: Entity property is nullable but database column is NOT NULL.**

This mismatch produces a database error when you try to save an entity without setting a required field.

```php
// Wrong: mark a required field as nullable in the entity
#[ORM\Column(nullable: true)]
private ?string $title = null;

// Correct: required fields must not be nullable
#[ORM\Column(length: 255)]
private ?string $title = null;
```

The PHP type hint `?string` means the PHP property can hold null before it is saved, which is fine. The `nullable: true` option in the Doctrine attribute is what controls the database column. If a field must always have a value in the database, omit `nullable: true` (the default is `NOT NULL`). After changing a property's nullable setting, generate a new migration to synchronize the schema.

**Error 3: Forgetting to add the constructor for createdAt.**

Without the constructor, `createdAt` is null by default, and saving an entry without setting it causes a NOT NULL constraint violation.

```php
// Wrong: no constructor, createdAt will be null when Entry is created
class Entry
{
    #[ORM\Column]
    private ?\DateTimeImmutable $createdAt = null;
}

// Correct: set createdAt automatically in the constructor
class Entry
{
    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
    }
}
```

Doctrine does not set timestamps automatically. You are responsible for setting `createdAt` before persisting. The constructor is the right place because it runs every time a new `Entry` object is created, making it impossible to forget.

---

## 9. Exercises

**Exercise 1:** Open HeidiSQL (or any MySQL client) and inspect the `entry` table. How many columns does it have? What are their names and data types? Write down whether each column is nullable or not.

**Exercise 2:** The `updatedAt` column is nullable in the database. Why? Write a one-paragraph explanation of when this column will have a value and when it will be `NULL`.

**Exercise 3:** Run `php bin/console doctrine:schema:validate`. What does the output say? Now intentionally introduce an error by changing one `#[ORM\Column]` attribute in `Entry.php` (for example, change the type of `content` from `Types::TEXT` to something invalid). Run the validation again and observe the error message. Then revert your change.

---

## 10. Solutions

**Solution for Exercise 1:**

The `entry` table should have six columns:

| Column | Type | Nullable |
|---|---|---|
| id | INT (AUTO_INCREMENT) | NO |
| title | VARCHAR(255) | NO |
| content | LONGTEXT | NO |
| created_at | DATETIME | NO |
| updated_at | DATETIME | YES |
| user_id | INT (foreign key) | NO |

The column names are snake_case in the database even though the PHP property names are camelCase. Doctrine performs this conversion automatically. `createdAt` in PHP becomes `created_at` in the database.

**Solution for Exercise 2:**

`updatedAt` is nullable because a brand-new entry has never been edited. When a user first writes and saves an entry, only `createdAt` is set. The `updatedAt` column remains `NULL` until the user opens the edit form and saves changes. At that point, the controller sets `$entry->setUpdatedAt(new \DateTimeImmutable())` before calling `flush()`. This design allows the application to distinguish between entries that have never been edited and entries that have been modified at least once.

**Solution for Exercise 3:**

When the schema is valid, `doctrine:schema:validate` reports two `[OK]` results, one for the mapping and one for the database:

Output:

```text

```

To break the mapping, change `#[ORM\Column(type: Types::TEXT)]` on `$content` to `#[ORM\Column(type: 'texxt')]` and run the command again.

Output:

```text

Mapping
-------

 [FAIL] The entity-class App\Entity\Entry mapping is invalid:
 * The field 'App\Entity\Entry#content' uses a non-existent type 'texxt'.


Database
--------


In UnknownColumnType.php line 15:

  Unknown column type "texxt" requested. Any Doctrine type that you use has t
  o be registered with \Doctrine\DBAL\Types\Type::addType(). You can get a li
  st of all the known types with \Doctrine\DBAL\Types\Type::getTypesMap(). If
   this error occurs during database introspection then you might have forgot
  ten to register all database types for a Doctrine Type. Use AbstractPlatfor
  m#registerDoctrineTypeMapping() or have your custom types implement Type#ge
  tMappedDatabaseTypes(). If the type name is empty you might have a problem
  with the cache or forgot some mapping information.


doctrine:schema:validate [--em EM] [--skip-mapping] [--skip-sync] [--skip-property-types]
```

The `Mapping` section now shows `[FAIL]` and names the exact property with the unknown type. The `Database` section cannot be checked at all, because Doctrine does not know how to turn `texxt` into a column, so the command stops with an `Unknown column type` exception. Revert the change and run the command again to get both `[OK]` lines back. This command is useful during development to check whether you need to generate a new migration after modifying an entity.

---

## Next Up - Lesson 6

In this lesson, you connected Symfony to MySQL, created the `User` and `Entry` entities with all their properties and a ManyToOne relationship, and generated and ran your first Doctrine migrations. The `user` and `entry` tables now exist in the database. You also understand what Doctrine ORM is and how the Data Mapper pattern keeps entity classes clean.

In Lesson 6, you will learn how to query data from the database using the Repository pattern, update the controller to use real entries, and insert seed data using Doctrine Fixtures so you have something to see in the browser.