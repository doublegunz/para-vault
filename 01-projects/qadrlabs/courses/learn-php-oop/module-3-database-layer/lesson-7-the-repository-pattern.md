## 1. Before You Begin

### Introduction

In the previous lesson, we connected to MySQL and created our tables. But writing SQL queries scattered throughout the application quickly becomes unmanageable. This lesson introduces the **Repository pattern**: a dedicated class whose only job is to talk to the database for a specific entity.

### What You'll Build

You will create `EntryRepository` and `UserRepository` classes that encapsulate all database queries, insert seed data for testing, and display entries from the database.

### What You'll Learn

- ✅ What the Repository pattern is and why it matters
- ✅ How to build a repository that converts database rows into Entry objects
- ✅ How to create methods for finding, inserting, updating, and deleting records
- ✅ How repositories map to Eloquent models, Doctrine repositories, and CI4 models

### What You'll Need

- The Database class and tables from Lesson 6
- Seed data inserted (or ready to insert)
- The development server running

---

## 2. Setup

In VS Code, right-click on the `src` folder, select **New Folder**, type `Repositories`, and press Enter.

---

## 3. Create the EntryRepository

In this section you will create the main repository class that handles all database operations for journal entries. Every SQL query for the `entries` table will live in this one class.

### Step 1: Create the File

Right-click on the `src/Repositories` folder, select **New File**, type `EntryRepository.php`, and press Enter.

### Step 2: Write the Code

Open `src/Repositories/EntryRepository.php` and type the following code:

```php
<?php

namespace App\Repositories;

use App\Database;
use App\Models\Entry;
use PDO;

class EntryRepository
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::getConnection();
    }

    public function findAll(): array
    {
        $stmt = $this->pdo->query("SELECT * FROM entries ORDER BY created_at DESC");
        return $this->mapRows($stmt->fetchAll());
    }

    public function findByUserId(int $userId): array
    {
        $stmt = $this->pdo->prepare("SELECT * FROM entries WHERE user_id = :user_id ORDER BY created_at DESC");
        $stmt->execute(['user_id' => $userId]);
        return $this->mapRows($stmt->fetchAll());
    }

    public function findById(int $id): ?Entry
    {
        $stmt = $this->pdo->prepare("SELECT * FROM entries WHERE id = :id");
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row ? $this->mapRow($row) : null;
    }

    public function create(array $data): int
    {
        $stmt = $this->pdo->prepare("
            INSERT INTO entries (user_id, title, content, created_at)
            VALUES (:user_id, :title, :content, NOW())
        ");
        $stmt->execute([
            'user_id' => $data['user_id'],
            'title'   => $data['title'],
            'content' => $data['content'],
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, array $data): void
    {
        $stmt = $this->pdo->prepare("
            UPDATE entries SET title = :title, content = :content, updated_at = NOW()
            WHERE id = :id
        ");
        $stmt->execute([
            'id'      => $id,
            'title'   => $data['title'],
            'content' => $data['content'],
        ]);
    }

    public function delete(int $id): void
    {
        $stmt = $this->pdo->prepare("DELETE FROM entries WHERE id = :id");
        $stmt->execute(['id' => $id]);
    }

    private function mapRow(object $row): Entry
    {
        return new Entry(
            id: $row->id,
            title: $row->title,
            content: $row->content,
            userId: $row->user_id,
            createdAt: $row->created_at,
            updatedAt: $row->updated_at ?? null,
        );
    }

    private function mapRows(array $rows): array
    {
        return array_map(fn($row) => $this->mapRow($row), $rows);
    }
}
```

### Step 3: Save the File

Press **Ctrl+S**.

### Code Breakdown

The `mapRow()` method converts a raw database object into an `Entry` instance. This is the same conversion that Eloquent, Doctrine, and CI4 models do automatically. We do it by hand so you understand what happens under the hood.

`findAll()` uses `query()` (no user data). `findByUserId()` uses `prepare()` with a parameter (user data). Both return arrays of `Entry` objects.

`create()` returns the new ID. `update()` and `delete()` return nothing (`void`).

---

## 4. Create the UserRepository

Following the same pattern, this section creates a repository for user records. It provides methods to find users by ID or email, and to insert new users.

### Step 1: Create the File

Right-click on the `src/Repositories` folder, select **New File**, type `UserRepository.php`, and press Enter.

### Step 2: Write the Code

Open `src/Repositories/UserRepository.php` and type the following code:

```php
<?php

namespace App\Repositories;

use App\Database;
use App\Models\User;
use PDO;

class UserRepository
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::getConnection();
    }

    public function findById(int $id): ?User
    {
        $stmt = $this->pdo->prepare("SELECT * FROM users WHERE id = :id");
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row ? $this->mapRow($row) : null;
    }

    public function findByEmail(string $email): ?User
    {
        $stmt = $this->pdo->prepare("SELECT * FROM users WHERE email = :email");
        $stmt->execute(['email' => $email]);
        $row = $stmt->fetch();

        return $row ? $this->mapRow($row) : null;
    }

    public function create(array $data): int
    {
        $stmt = $this->pdo->prepare("
            INSERT INTO users (name, email, password, created_at)
            VALUES (:name, :email, :password, NOW())
        ");
        $stmt->execute([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => $data['password'],
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    private function mapRow(object $row): User
    {
        return new User(
            id: $row->id,
            name: $row->name,
            email: $row->email,
            password: $row->password,
            createdAt: $row->created_at,
        );
    }
}
```

The `findById()` and `findByEmail()` methods both return `?User` (nullable): if no row matches, `fetch()` returns `false`, and the ternary `$row ? ... : null` returns `null`. The `create()` method accepts an array of data, binds each value to a named placeholder, and returns the auto-incremented ID of the newly inserted user.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 5. Insert Seed Data

With both repositories ready, this section creates a seed script to populate the database with test data for development.

### Step 1: Create the File

Right-click on the `config` folder, select **New File**, type `seed.php`, and press Enter. (If you already created this in L6, replace its content.)

### Step 2: Write the Code

Open `config/seed.php` and type the following code:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Repositories\UserRepository;
use App\Repositories\EntryRepository;

$userRepo  = new UserRepository();
$entryRepo = new EntryRepository();

$userId = $userRepo->create([
    'name'     => 'Budi',
    'email'    => 'budi@example.com',
    'password' => password_hash('password123', PASSWORD_DEFAULT),
]);
echo "User created with ID: $userId\n";

$entryRepo->create(['user_id' => $userId, 'title' => 'My first entry', 'content' => 'This is my very first journal entry. Feels great to get started!']);
$entryRepo->create(['user_id' => $userId, 'title' => 'Learning PHP OOP', 'content' => 'Today I learned about the Repository pattern. It keeps database code clean and organized.']);
$entryRepo->create(['user_id' => $userId, 'title' => 'Weekend plans', 'content' => 'Planning to finish the PHP OOP course this weekend and maybe start learning a framework.']);

echo "3 entries created.\n";
echo "Seed complete!\n";
```

The seed script instantiates both repositories and uses their `create()` methods directly. `$userRepo->create()` inserts one user and returns the new ID, which is then passed as `user_id` to three `$entryRepo->create()` calls. Each call translates to a single prepared statement executed against the database.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Run in the terminal:

```bash
php config/seed.php
```

> **Note:** Only run this once. Running it again will fail because the email `budi@example.com` already exists (UNIQUE constraint).

---

## 6. Test the Repository

This section updates `public/index.php` to use `EntryRepository` to fetch all entries from the database and display them as cards.

### Step 1: Open the File

Open `public/index.php`.

### Step 2: Replace the Code

Replace the entire content with:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Repositories\EntryRepository;

$entryRepo = new EntryRepository();
$entries   = $entryRepo->findAll();

echo '<h1>Catatku</h1>';
echo '<p>' . count($entries) . ' entries found</p>';

foreach ($entries as $entry) {
    echo '<div style="border: 1px solid #ccc; padding: 10px; margin: 10px 0;">';
    echo '<h3>' . htmlspecialchars($entry->getTitle()) . '</h3>';
    echo '<p>' . htmlspecialchars($entry->getExcerpt(80)) . '</p>';
    echo '<small>Created: ' . htmlspecialchars($entry->getCreatedAt()) . '</small>';
    echo '</div>';
}
```

`new EntryRepository()` instantiates the repository, which calls `Database::getConnection()` in its constructor. `findAll()` executes the query and returns an array of `Entry` objects. The `foreach` loop iterates over each object and calls getter methods, passing the values through `htmlspecialchars()` before output.

### Step 3: Save and Run

Save the file (**Ctrl+S**). Run `composer dump-autoload` (for the new Repositories folder). Open:

```
http://localhost:8080
```

You should see all entries from the database displayed as cards.

---

## 7. The Repository Pattern Explained

The Repository pattern separates *what* data you need from *how* it is retrieved. Your controller asks: "Give me all entries for user 1." It does not care whether the data comes from MySQL, PostgreSQL, or an API. The repository handles the details.

| This Course | Laravel | Symfony | CodeIgniter |
|-------------|---------|---------|-------------|
| `EntryRepository` | `Entry` (Eloquent Model) | `EntryRepository` (Doctrine) | `EntryModel` |
| `->findByUserId($id)` | `->where('user_id', $id)->get()` | `->findBy(['user' => $user])` | `->where('user_id', $id)->findAll()` |
| `->create($data)` | `Entry::create($data)` | `$em->persist($entity)` | `$model->insert($data)` |

---

## 8. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: Repository without constructor
class BadRepo {
    public function findAll(): array {
        $stmt = $this->pdo->query("SELECT * FROM entries");
        return $stmt->fetchAll();
    }
}

// Error 2: Returning raw database objects instead of typed models
public function findById(int $id): ?Entry {
    $stmt = $this->pdo->prepare("SELECT * FROM entries WHERE id = :id");
    $stmt->execute(['id' => $id]);
    return $stmt->fetch();  // Returns stdClass, not Entry!
}

// Error 3: SQL injection in repository
public function search(string $keyword): array {
    $stmt = $this->pdo->query("SELECT * FROM entries WHERE title LIKE '%$keyword%'");
    return $stmt->fetchAll();
}
```

**Error 1: No PDO connection.** The repository needs `$this->pdo` but never initializes it. The constructor must call `Database::getConnection()` and store the result.

**Error 2: Returning raw objects.** `$stmt->fetch()` returns a `stdClass`, not an `Entry`. Use `mapRow()` to convert: `return $row ? $this->mapRow($row) : null;`.

**Error 3: SQL injection.** `$keyword` is inserted directly into the query. Use prepared statements: `$stmt = $this->pdo->prepare("SELECT * FROM entries WHERE title LIKE :keyword"); $stmt->execute(['keyword' => "%$keyword%"]);`.

---

## 9. Exercises

**Exercise 1:** Add a method `countByUserId(int $userId): int` to `EntryRepository` that returns the number of entries for a specific user. Use `SELECT COUNT(*) as total`. Test it in `public/index.php`.

**Exercise 2:** Add a method `findRecent(int $limit = 5): array` to `EntryRepository` that returns the N most recent entries. Use `LIMIT` in the query. Test it by displaying only the 2 most recent entries.

**Exercise 3:** Create `public/test-repo.php` that uses both `UserRepository` and `EntryRepository` to display: the user's name and email, the number of their entries, and a list of their entry titles. Use `findByEmail('budi@example.com')` to find the user.

---

## 10. Solutions

**Solution for Exercise 1:**

Add to `src/Repositories/EntryRepository.php`:

```php
    public function countByUserId(int $userId): int
    {
        $stmt = $this->pdo->prepare("SELECT COUNT(*) as total FROM entries WHERE user_id = :uid");
        $stmt->execute(['uid' => $userId]);
        return (int) $stmt->fetch()->total;
    }
```

`fetch()->total` retrieves the single result row as an object and reads the `total` column. The `(int)` cast converts PDO's string return value to a proper integer. The `:uid` placeholder keeps the user ID safely separated from the SQL structure.

Test in `public/index.php`:

```php
echo '<p>Entries by user 1: ' . $entryRepo->countByUserId(1) . '</p>';
```

**Solution for Exercise 2:**

Add to `src/Repositories/EntryRepository.php`:

```php
    public function findRecent(int $limit = 5): array
    {
        $stmt = $this->pdo->prepare("SELECT * FROM entries ORDER BY created_at DESC LIMIT :limit");
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $this->mapRows($stmt->fetchAll());
    }
```

`LIMIT :limit` restricts how many rows MySQL returns. `bindValue('limit', $limit, PDO::PARAM_INT)` is used instead of passing the value through `execute()` because PDO treats `LIMIT` values as strings by default, which causes MySQL to reject the query. `PDO::PARAM_INT` forces the correct integer type binding.

Test: `$recent = $entryRepo->findRecent(2);`

**Solution for Exercise 3:**

Create `public/test-repo.php`:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Repositories\UserRepository;
use App\Repositories\EntryRepository;

$userRepo  = new UserRepository();
$entryRepo = new EntryRepository();

$user = $userRepo->findByEmail('budi@example.com');
if (!$user) { echo 'User not found'; exit; }

$entries = $entryRepo->findByUserId($user->getId());

echo '<h2>' . htmlspecialchars($user->getName()) . '</h2>';
echo '<p>Email: ' . htmlspecialchars($user->getEmail()) . '</p>';
echo '<p>Entries: ' . count($entries) . '</p>';
echo '<ul>';
foreach ($entries as $e) {
    echo '<li>' . htmlspecialchars($e->getTitle()) . '</li>';
}
echo '</ul>';
```

`findByEmail('budi@example.com')` returns either a `User` object or `null`. The `if (!$user)` guard handles the `null` case by exiting early. `$user->getId()` provides the ID for `findByUserId()`, which returns an array of `Entry` objects. Both repositories work together without either knowing about the other's implementation.

Run at: `http://localhost:8080/test-repo.php`

---

## 11. Conclusion

The Repository pattern gives each entity a dedicated class for database queries. Repositories convert raw database rows into typed objects. All SQL uses prepared statements. The standard CRUD methods (`findAll`, `findById`, `create`, `update`, `delete`) provide a clean interface that the rest of the application uses without knowing the SQL details.

---

## Next Up - Lesson 8: The Front Controller and Routing

In the next lesson you will:

1. Build a single entry point that handles all incoming HTTP requests
2. Create a `Router` class that maps URLs to controller methods
3. Stop serving every page from a separate PHP file