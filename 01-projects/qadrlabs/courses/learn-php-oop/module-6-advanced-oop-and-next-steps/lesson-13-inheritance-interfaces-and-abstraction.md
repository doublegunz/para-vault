## 1. Before You Begin

### Introduction

Catatku is fully functional. But if you look at the code, you will notice patterns repeating. Both `EntryRepository` and `UserRepository` create a PDO connection in their constructor. Both `EntryController` and `AuthController` share similar patterns for CSRF checks, auth verification, and redirects. This lesson introduces three OOP features that eliminate that repetition and create contracts between classes.

### What You'll Build

You will refactor Catatku with an abstract `BaseRepository`, an abstract `BaseController`, and an interface that defines contracts. These are the exact patterns that framework base classes use.

### What You'll Learn

- ✅ **Inheritance**: how child classes extend parent classes to reuse code
- ✅ **Abstract classes**: classes that cannot be instantiated, only extended
- ✅ **Abstract methods**: contracts that child classes must fulfill
- ✅ **Interfaces**: contracts that any class can implement
- ✅ How these patterns map directly to framework base classes

### What You'll Need

- The complete Catatku application from Lesson 12
- The development server running

---

## 2. Create an Abstract BaseRepository

This section creates an abstract base class to handle the database connection and shared logic for all child repositories.

### Step 1: Create the File

Right-click on the `src/Repositories` folder, select **New File**, type `BaseRepository.php`, and press Enter.

### Step 2: Write the Code

Open `src/Repositories/BaseRepository.php` and type the following code:

```php
<?php

namespace App\Repositories;

use App\Database;
use PDO;

abstract class BaseRepository
{
    protected PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::getConnection();
    }

    abstract protected function getTable(): string;

    public function deleteById(int $id): void
    {
        $stmt = $this->pdo->prepare("DELETE FROM {$this->getTable()} WHERE id = :id");
        $stmt->execute(['id' => $id]);
    }
}
```

**`abstract class`** means you cannot write `new BaseRepository()`. It can only be extended by child classes. A base repository without a specific table name makes no sense, so preventing direct instantiation is the correct design.

**`abstract protected function getTable(): string;`** declares a method that every child class *must* implement. This is a contract: if you extend `BaseRepository`, you must define which table you work with.

**`protected`** means child classes can access `$this->pdo` directly, but code outside the class hierarchy cannot.

### Step 3: Save the File

Press **Ctrl+S**.

---

## 3. Refactor the Repositories

With the `BaseRepository` in place, this section refactors the current repositories to inherit from it, eliminating redundant code.

### Step 1: Update EntryRepository

Open `src/Repositories/EntryRepository.php` and replace the entire content:

```php
<?php

namespace App\Repositories;

use App\Models\Entry;
use PDO;

class EntryRepository extends BaseRepository
{
    protected function getTable(): string
    {
        return 'entries';
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
        $stmt->execute(['id' => $id, 'title' => $data['title'], 'content' => $data['content']]);
    }

    public function delete(int $id): void
    {
        $this->deleteById($id);
    }

    private function mapRow(object $row): Entry
    {
        return new Entry(
            id: $row->id, title: $row->title, content: $row->content,
            userId: $row->user_id, createdAt: $row->created_at,
            updatedAt: $row->updated_at ?? null,
        );
    }

    private function mapRows(array $rows): array
    {
        return array_map(fn($row) => $this->mapRow($row), $rows);
    }
}
```

Notice that the constructor is gone because `BaseRepository` handles the PDO connection. `$this->pdo` is available through inheritance. `getTable()` returns `'entries'` to fulfill the abstract contract. `delete()` now delegates to the inherited `deleteById()`.

### Step 2: Save the File

Press **Ctrl+S**.

### Step 3: Update UserRepository

Open `src/Repositories/UserRepository.php` and add the `extends BaseRepository` and `getTable()`:

```php
<?php

namespace App\Repositories;

use App\Models\User;
use PDO;

class UserRepository extends BaseRepository
{
    protected function getTable(): string
    {
        return 'users';
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
        $stmt->execute(['name' => $data['name'], 'email' => $data['email'], 'password' => $data['password']]);
        return (int) $this->pdo->lastInsertId();
    }

    private function mapRow(object $row): User
    {
        return new User(
            id: $row->id, name: $row->name, email: $row->email,
            password: $row->password, createdAt: $row->created_at,
        );
    }
}
```

Similarly, `UserRepository` extends the base class and provides its table name, immediately gaining access to the database connection without needing its own constructor.

### Step 4: Save the File

Press **Ctrl+S**.

---

## 4. Create an Interface

An **interface** defines a contract: a set of methods that any implementing class must provide. This section adds an interface to enforce repository consistency.

### Step 1: Create the File

Right-click on `src/Repositories`, select **New File**, type `RepositoryInterface.php`.

### Step 2: Write the Code

Open `src/Repositories/RepositoryInterface.php` and type:

```php
<?php

namespace App\Repositories;

interface RepositoryInterface
{
    public function findById(int $id): mixed;
    public function deleteById(int $id): void;
}
```

The interface declares the methods and their signatures but contains zero implementation logic.

### Step 3: Update BaseRepository

Open `src/Repositories/BaseRepository.php` and change the class declaration to:

```php
abstract class BaseRepository implements RepositoryInterface
```

`implements RepositoryInterface` tells PHP: "This class promises to provide all the methods defined in `RepositoryInterface`." If you forget to implement a method, PHP throws a fatal error.

Interfaces are different from abstract classes. A class can only extend **one** parent (`extends`), but it can implement **multiple** interfaces (`implements`). Interfaces define *what* a class can do. Abstract classes define *how* to do it with partial implementation.

### Step 4: Save Both Files

Press **Ctrl+S** for both files.

---

## 5. Create an Abstract BaseController

This section creates an abstract base controller to centralize repetitive authentication and CSRF checks.

### Step 1: Create the File

Right-click on `src/Controllers`, select **New File**, type `BaseController.php`.

### Step 2: Write the Code

Open `src/Controllers/BaseController.php` and type:

```php
<?php

namespace App\Controllers;

use App\Helpers;

abstract class BaseController
{
    protected function requireAuth(): void
    {
        if (!isset($_SESSION['user_id'])) {
            header('Location: /login');
            exit;
        }
    }

    protected function verifyCsrf(): void
    {
        if (!Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            exit;
        }
    }

    protected function getCurrentUserId(): int
    {
        return (int) ($_SESSION['user_id'] ?? 0);
    }

    protected function redirect(string $path): never
    {
        header('Location: ' . $path);
        exit;
    }
}
```

### Step 3: Save the File

Press **Ctrl+S**.

### Step 4: Update EntryController

Open `src/Controllers/EntryController.php` and change the class declaration to:

```php
class EntryController extends BaseController
```

Now you can simplify methods. For example, replace:

```php
if (!isset($_SESSION['user_id'])) { header('Location: /login'); exit; }
```

with:

```php
$this->requireAuth();
```

And replace:

```php
if (!\App\Helpers::verifyCsrfToken($_POST['csrf_token'] ?? '')) { ... }
```

with:

```php
$this->verifyCsrf();
```

And replace `header('Location: /entries'); exit;` with `$this->redirect('/entries');`.

By extending `BaseController`, all controllers instantly inherit these helper methods, making their core logic much shorter and easier to read.

### Step 5: Update Other Controllers

Apply the same pattern to `AuthController` and `HomeController`: extend `BaseController` and use the inherited helper methods.

### Step 6: Save All Files

Press **Ctrl+S** for each modified file. Run `composer dump-autoload`. Test at:

```
http://localhost:8080/entries
```

Everything should work exactly as before, but the code is cleaner.

---

## 6. The Class Hierarchy

```
RepositoryInterface (interface)
    |
    └── BaseRepository (abstract, implements RepositoryInterface)
            |
            ├── EntryRepository (extends BaseRepository)
            └── UserRepository (extends BaseRepository)

BaseController (abstract)
    |
    ├── EntryController (extends BaseController)
    ├── AuthController (extends BaseController)
    └── HomeController (extends BaseController)
```

**Interface** says: "You must have these methods."
**Abstract class** says: "Here is shared code, and you must implement the rest."
**Concrete class** says: "I provide the complete implementation."

---

## 7. How This Maps to Frameworks

| This Course | Laravel | Symfony | CodeIgniter |
|-------------|---------|---------|-------------|
| `BaseRepository` | `Eloquent\Model` | `ServiceEntityRepository` | `CodeIgniter\Model` |
| `BaseController` | `Controller` | `AbstractController` | `BaseController` |
| `RepositoryInterface` | Eloquent contracts | Doctrine `ObjectRepository` | N/A (convention) |
| `extends BaseController` | `extends Controller` | `extends AbstractController` | `extends BaseController` |

---

## 8. Fix the Errors in Your Code

Read the following code and identify the three mistakes before reading the explanations below.

```php
<?php
// Error 1: Trying to instantiate an abstract class
$repo = new BaseRepository();  // Fatal error!

// Error 2: Forgetting to implement abstract method
class ProductRepository extends BaseRepository {
    // Missing getTable() — fatal error!
}

// Error 3: Implementing interface but missing a method
class BadRepo implements RepositoryInterface {
    public function findById(int $id): mixed { return null; }
    // Missing deleteById() — fatal error!
}
```

**Error 1: Cannot instantiate abstract class.** Abstract classes are blueprints for other classes. Use `new EntryRepository()` instead.

**Error 2: Must implement all abstract methods.** If you extend `BaseRepository`, you must implement `getTable()`. PHP enforces this at compile time.

**Error 3: Must implement all interface methods.** Implementing `RepositoryInterface` requires both `findById()` and `deleteById()`. Missing either one causes a fatal error.

---

## 9. Exercises

**Exercise 1:** Add an abstract method `mapRow(object $row): mixed` to `BaseRepository`. Implement it in both `EntryRepository` (returns `Entry`) and `UserRepository` (returns `User`). Change the visibility from `private` to `protected` so the base class can call it.

**Exercise 2:** Create an interface `Renderable` in `src/Contracts/Renderable.php` with one method: `toArray(): array`. Make both `Entry` and `User` implement this interface. Verify that both classes have the `toArray()` method.

**Exercise 3:** Add a method `count(): int` to `BaseRepository` that returns the number of rows using `SELECT COUNT(*) FROM {$this->getTable()}`. Test it in a scratch file `public/test-count.php` that calls `$entryRepo->count()` and `$userRepo->count()` (the same pattern as `public/test-db.php` from Lesson 6). Note that `public/index.php` is now the front controller, so it is no longer the place for quick experiments.

---

## 10. Solutions

**Solution for Exercise 1:**

In `BaseRepository`, add:

```php
    abstract protected function mapRow(object $row): mixed;
```

By moving `mapRow` into the abstract base class and marking it `protected`, the base class guarantees its availability for internal data transformation while letting each child class define its exact entity mapping.

Change `mapRow()` in both repositories from `private` to `protected`. They already implement the correct signature.

**Solution for Exercise 2:**

Create `src/Contracts/Renderable.php`:

```php
<?php

namespace App\Contracts;

interface Renderable
{
    public function toArray(): array;
}
```

Update `Entry`:

```php
use App\Contracts\Renderable;

class Entry implements Renderable
{
    // ... existing code
    public function toArray(): array { return [...]; }
}
```

Interfaces are excellent for promising that an object can be serialized to an array, allowing external systems to safely demand `toArray()` on both models. Same applies for `User`.

**Solution for Exercise 3:**

Add to `BaseRepository`:

```php
    public function count(): int
    {
        return (int) $this->pdo->query("SELECT COUNT(*) as total FROM {$this->getTable()}")->fetch()->total;
    }
```

Implementing generic SQL logic inside the base class automatically grants a `count()` method to every repository within the application without writing additional methods.

Create `public/test-count.php` to try it:

```php
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\Repositories\EntryRepository;
use App\Repositories\UserRepository;

$entryRepo = new EntryRepository();
$userRepo  = new UserRepository();

echo 'Entries: ' . $entryRepo->count() . '<br>';
echo 'Users: ' . $userRepo->count();
```

Run at: `http://localhost:8080/test-count.php`. Both repositories expose `count()` even though it is defined only once in `BaseRepository`.

---

## 11. Conclusion

Inheritance lets child classes reuse code from a parent class. Abstract classes cannot be instantiated directly and can require child classes to implement specific methods. Interfaces define contracts that any class can implement. These patterns are the foundation of every PHP framework's base classes. Extract shared logic into base classes to keep concrete classes focused on their specific responsibilities.

---

## Next Up - Lesson 14: Conclusion and Review

In the final lesson you will:

1. Review everything built in this course
2. See how every OOP pattern maps directly to framework concepts
3. Plan your next steps in your PHP development journey