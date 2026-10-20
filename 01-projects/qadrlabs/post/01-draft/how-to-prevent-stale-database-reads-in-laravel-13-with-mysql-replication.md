# How to Prevent Stale Database Reads in Laravel 13 with MySQL Replication

A Laravel application saves an updated article title successfully, redirects to the article page, and displays the old title. The database write succeeded. The next request simply reached a read replica that had not applied the change yet. This replication lag is difficult to spot in development but can make a production application appear to lose updates. Laravel 13.38.0 introduces the opt-in `PreventStaleDatabaseReads` middleware to keep a user's reads on the write connection briefly after a write.

This tutorial builds that failure deliberately, then fixes the user experience. We will run two MySQL servers locally, connect Laravel to a primary and a replica, stop the replica's applier to reproduce stale data, and compare the behavior before and after enabling the middleware. The middleware was introduced in [Laravel framework PR #62078](https://github.com/laravel/framework/pull/62078).

## Overview {#overview}

The finished project is a small, authenticated article manager with a visible database node indicator. The interface stays simple so that the database behavior, not the UI, is the focus. All commands assume that PHP runs on the host computer while MySQL runs in Docker containers.

### What You'll Build

- A Laravel 13.38.0 application with login and basic article create, read, update, and delete operations.
- Two MySQL 8.4 instances in Docker Compose: primary on port `3307` and replica on port `3308`.
- Working MySQL replication with a repeatable way to pause and resume the replica applier.
- A page that identifies which database server served its read query.
- A before-and-after demonstration of `PreventStaleDatabaseReads`, followed by Pest feature tests.

### What You'll Learn

- Why a successful database write can be followed by a stale read on another HTTP request.
- How to configure Laravel's `read`, `write`, and `sticky` database connection options.
- How to confirm replication health and deliberately create replication lag.
- How session-based read-after-write protection works and where its guarantee ends.
- Why implicit route model binding requires care with middleware ordering.
- How `usingWritePdo()` differs from request-based read-after-write protection.

### What You'll Need

- PHP **8.3 or higher**, Composer, the Laravel installer, and the `pdo_mysql` PHP extension.
- Docker Engine or Docker Desktop with Docker Compose v2.
- MySQL 8.4 container images (downloaded automatically by Docker).
- Basic familiarity with Laravel routes, controllers, Eloquent, and terminal commands.
- An available local port `8000` for Laravel and ports `3307` and `3308` for MySQL.
- No earlier QadrLabs tutorial is required. This is a standalone project.

> **Local environment only:** The passwords and database ports in this walkthrough are intentionally simple for a disposable Docker lab. Do not reuse them in production, publish the containers to an external interface, or run the replication stop commands against a real replica.

## Step 1: Create the Laravel Project {#step-1-create-the-laravel-project}

Start with a fresh Laravel application. The Laravel 13 installer can prepare SQLite and Pest automatically; we will switch the application's normal database connection to MySQL after the containers are ready.

Run:

```bash
laravel new repo-demo --no-interaction --database=sqlite --pest --no-boost
cd repo-demo
composer require laravel/framework:13.38.0 --with-all-dependencies
php artisan --version
```

The first command creates the application and installs Pest. The Composer command pins the framework to the version that introduced the middleware, rather than silently using a newer patch release. The final command should report `Laravel Framework 13.38.0`. If Composer cannot resolve the exact version, inspect any additional package constraints before continuing.

Check PHP's MySQL support:

```bash
php -m | grep -i pdo_mysql
```

Expected result: `pdo_mysql` appears in the extension list. On Windows PowerShell, use `php -m | Select-String pdo_mysql` instead.

At this point, keep the default SQLite configuration unchanged. The application project exists, and the next steps will supply its MySQL infrastructure.

## Step 2: Create the MySQL Primary and Replica Containers {#step-2-create-the-mysql-primary-and-replica-containers}

Create `compose.yaml` in the project root. These are two separate MySQL servers with different server IDs and persistent, independent Docker volumes. The primary records binary logs, while the replica receives and applies changes from the primary after we configure replication.

```yaml
services:
  mysql-primary:
    image: mysql:8.4
    command:
      - --server-id=1
      - --log-bin=mysql-bin
      - --binlog-format=ROW
    environment:
      MYSQL_ROOT_PASSWORD: local_root_password
    ports:
      - "127.0.0.1:3307:3306"
    volumes:
      - mysql-primary-data:/var/lib/mysql
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p$$MYSQL_ROOT_PASSWORD --silent"]
      interval: 5s
      timeout: 5s
      retries: 30

  mysql-replica:
    image: mysql:8.4
    command:
      - --server-id=2
      - --relay-log=replica-relay-bin
      - --read-only=ON
      - --skip-replica-start
    environment:
      MYSQL_ROOT_PASSWORD: local_root_password
    ports:
      - "127.0.0.1:3308:3306"
    volumes:
      - mysql-replica-data:/var/lib/mysql
    depends_on:
      mysql-primary:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p$$MYSQL_ROOT_PASSWORD --silent"]
      interval: 5s
      timeout: 5s
      retries: 30

volumes:
  mysql-primary-data:
  mysql-replica-data:
```

The `127.0.0.1` host bindings prevent Docker from publishing the MySQL ports on all network interfaces. `server-id` distinguishes the two MySQL servers. `log-bin` makes the primary's changes available for replication, and `relay-log` gives the replica a place to store events received from the primary. The replica's `read-only` setting protects against ordinary application writes to that server.

Save the file and start the containers:

```bash
docker compose up -d
docker compose ps
```

Expected result: both services are listed as running and eventually healthy. Their startup may take a little longer on the first run because Docker must initialize both data directories.

Open a MySQL shell on each server in separate terminals to verify its identity:

```bash
docker compose exec mysql-primary mysql -uroot -p
```

Enter `local_root_password`, then run:

```sql
SELECT @@server_id AS server_id, @@read_only AS read_only;
```

Expected result on the primary: `server_id` is `1`, and `read_only` is `0`. Leave the client with `exit`.

Repeat on the replica:

```bash
docker compose exec mysql-replica mysql -uroot -p
```

```sql
SELECT @@server_id AS server_id, @@read_only AS read_only;
```

Expected result on the replica: `server_id` is `2`, and `read_only` is `1`. Exit the client. If either service is unhealthy, inspect `docker compose logs mysql-primary` or `docker compose logs mysql-replica` before going further.

## Step 3: Configure and Verify MySQL Replication {#step-3-configure-and-verify-mysql-replication}

Both instances currently run independently. We will connect the replica to the primary using MySQL's binary log file and position. This is sufficient for a fresh, empty lab where the application tables have not yet been created. Existing databases require a consistent snapshot and matching replication coordinates instead.

Open the primary shell again:

```bash
docker compose exec mysql-primary mysql -uroot -p
```

Create a dedicated replication account and grant only its replication privilege:

```sql
CREATE USER 'replicator'@'%' IDENTIFIED BY 'replica_demo_password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
SHOW BINARY LOG STATUS;
```

The final statement shows a **File** and **Position** value. Write those two actual values down. They mark the point after the replication account was created and before any application database changes. Do not copy coordinates from another machine or from an example on the internet.

Keep that point in mind and exit the primary MySQL shell. Open the replica:

```bash
docker compose exec mysql-replica mysql -uroot -p
```

Run the following statement, replacing `YOUR_LOG_FILE` and `YOUR_LOG_POSITION` with the values returned by `SHOW BINARY LOG STATUS`:

```sql
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'mysql-primary',
    SOURCE_PORT = 3306,
    SOURCE_USER = 'replicator',
    SOURCE_PASSWORD = 'replica_demo_password',
    SOURCE_LOG_FILE = 'YOUR_LOG_FILE',
    SOURCE_LOG_POS = YOUR_LOG_POSITION,
    GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;
SHOW REPLICA STATUS\G
```

The replica uses `mysql-primary`, which is the service name resolvable inside Docker's network, rather than the host's `127.0.0.1:3307`. `GET_SOURCE_PUBLIC_KEY = 1` permits RSA public-key exchange for MySQL's default `caching_sha2_password` authentication in this local, non-TLS lab. Real deployments should use encrypted replication connections. The `SHOW REPLICA STATUS\G` output should show `Replica_IO_Running: Yes` and `Replica_SQL_Running: Yes`, with no active connection or SQL error. The exact log coordinates and status output depend on the machine.

Exit the replica shell and return to the primary:

```bash
docker compose exec mysql-primary mysql -uroot -p
```

Only now create the application database and its SQL account:

```sql
CREATE DATABASE repo_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'repo_demo_app'@'%' IDENTIFIED BY 'local_app_password';
GRANT ALL PRIVILEGES ON repo_demo.* TO 'repo_demo_app'@'%';
```

Because replication is already running, these statements are written to the primary's binary log and applied on the replica. Using a separate application user also avoids placing the MySQL root password in Laravel's `.env` file.

Save no additional SQL file for this step. Exit the primary and reconnect to the replica:

```bash
docker compose exec mysql-replica mysql -uroot -p
```

```sql
SHOW DATABASES LIKE 'repo_demo';
SHOW REPLICA STATUS\G
```

Expected result: `repo_demo` appears on the replica, both replication threads are running, and the SQL error field is empty. If the database has not appeared, allow a moment for replication, then inspect the two thread statuses and `Last_SQL_Error` before continuing. Exit the shell.

## Step 4: Configure Laravel's Read and Write Database Connections {#step-4-configure-laravels-read-and-write-database-connections}

Laravel should write to `mysql-primary` and read from `mysql-replica`. The PHP process runs on the host, so it connects through the host-bound ports rather than the Docker service names.

Edit `.env` so these settings are present. Remove any `DB_URL` value, since a URL can override individual connection options.

```ini
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3307
DB_DATABASE=repo_demo
DB_USERNAME=repo_demo_app
DB_PASSWORD=local_app_password
DB_READ_HOST=127.0.0.1
DB_READ_PORT=3308
DB_WRITE_HOST=127.0.0.1
DB_WRITE_PORT=3307

SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
```

`SESSION_DRIVER=file` matters in this demonstration. The middleware stores the last write time in the HTTP session; using a file session also prevents session storage queries from becoming part of our replicated database experiment. `CACHE_STORE=file` and `QUEUE_CONNECTION=sync` keep unrelated services out of the picture.

Open `config/database.php`. Replace only the existing `mysql` entry inside `connections` with the following complete entry. Keep the other connection definitions untouched.

```php
'mysql' => [
    'driver' => 'mysql',
    'url' => env('DB_URL'),

    // Ordinary SELECT queries use the replica.
    'read' => [
        'host' => env('DB_READ_HOST', '127.0.0.1'),
        'port' => env('DB_READ_PORT', 3308),
    ],

    // INSERT, UPDATE, DELETE and forced reads use primary.
    'write' => [
        'host' => env('DB_WRITE_HOST', '127.0.0.1'),
        'port' => env('DB_WRITE_PORT', 3307),
    ],

    // Keeps reads on primary after a write in the SAME request.
    'sticky' => true,

    'host' => env('DB_HOST', '127.0.0.1'),
    'port' => env('DB_PORT', 3307),
    'database' => env('DB_DATABASE', 'repo_demo'),
    'username' => env('DB_USERNAME', 'repo_demo_app'),
    'password' => env('DB_PASSWORD', ''),
    'unix_socket' => env('DB_SOCKET', ''),
    'charset' => env('DB_CHARSET', 'utf8mb4'),
    'collation' => env('DB_COLLATION', 'utf8mb4_unicode_ci'),
    'prefix' => '',
    'prefix_indexes' => true,
    'strict' => true,
    'engine' => null,
    'options' => extension_loaded('pdo_mysql') ? array_filter([
        (PHP_VERSION_ID >= 80400 ? \Pdo\Mysql::ATTR_SSL_CA : \PDO::MYSQL_ATTR_SSL_CA) => env('MYSQL_ATTR_SSL_CA'),
    ]) : [],
],
```

The `read` and `write` arrays override only the hosts and ports; database name and credentials come from the shared connection settings. The `sticky` option protects reads after writes **within the same request only**. It does not carry that protection into the redirect request or a later browser refresh. This is the gap we will demonstrate.

Save both files, then clear Laravel's cached configuration and create its database tables:

```bash
php artisan config:clear
php artisan migrate
```

Expected result: Laravel reports successfully executed migrations, including the default `users`, `password_reset_tokens`, and `sessions` tables where applicable. Migrations write to the primary. The replica should receive the resulting schema through MySQL replication.

Verify that both database servers have the `users` table by opening each server's MySQL client and running:

```sql
USE repo_demo;
SHOW TABLES LIKE 'users';
```

Expected result: the table is present on both servers. If it is missing on the replica, do not continue until replication is healthy.

## Step 5: Create the Article Model, Migration, and Demo Account {#step-5-create-the-article-model-migration-and-demo-account}

Generate the Article model and migration:

```bash
php artisan make:model Article -m
```

Open the new migration in `database/migrations/` whose filename ends with `_create_articles_table.php`. Replace the file contents with:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('articles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

Each article belongs to a user, and deleting a user deletes their articles. This gives the tutorial a clear ownership rule instead of exposing every article to every account.

Open `app/Models/Article.php` and use:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'body'])]
class Article extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

The Laravel 13 `#[Fillable]` attribute allows only `title` and `body` to be assigned from validated input. We will set `user_id` through the authenticated user's Eloquent relationship, rather than trusting a submitted user ID.

Next, open the existing `app/Models/User.php` and replace its contents with:

```php
<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    public function articles(): HasMany
    {
        return $this->hasMany(Article::class);
    }

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
```

This retains the starter application's hashed password cast while adding the `articles()` relationship. The relation makes creating articles for the logged-in user straightforward.

Save these files and migrate:

```bash
php artisan migrate
```

Expected result: the articles migration runs successfully. To avoid publishing a registration workflow unrelated to replication, create one local account with Tinker:

```bash
php artisan tinker
```

```php
$user = \App\Models\User::create([
    'name' => 'Demo Editor',
    'email' => 'editor@example.test',
    'password' => 'local-password-123',
]);

$user->articles()->create([
    'title' => 'First draft',
    'body' => 'This title will change during the replication demonstration.',
]);
```

The User model's `hashed` cast hashes the password before storing it. This password is for the local disposable lab only. Exit Tinker, then confirm the seed article exists on the replica with a MySQL client:

```sql
USE repo_demo;
SELECT id, title FROM articles;
```

Expected result: a row titled `First draft` is present. Note its ID because the browser will open that article in the following steps.

## Step 6: Build Authentication, Article Controllers, and Routes {#step-6-build-authentication-article-controllers-and-routes}

The application needs a login screen and a protected CRUD controller. We will resolve article IDs inside controller actions rather than implicitly binding `Article` models in route signatures. This is intentional: the default `web` group performs route substitution before an appended middleware, so an implicitly bound Article might be loaded from the replica before `PreventStaleDatabaseReads` can change the read connection.

Create the controllers:

```bash
php artisan make:controller LoginController
php artisan make:controller ArticleController
```

Open `app/Http/Controllers/LoginController.php` and replace it with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class LoginController extends Controller
{
    public function create(): View
    {
        return view('auth.login');
    }

    public function store(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            return back()->withErrors([
                'email' => 'The supplied credentials are incorrect.',
            ]);
        }

        $request->session()->regenerate();

        return redirect()->route('articles.index');
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
```

`Auth::attempt()` validates the account against the hashed password. Regenerating the session after login helps protect against session fixation. Using the same general failure response avoids distinguishing unknown email addresses from incorrect passwords.

Open `app/Http/Controllers/ArticleController.php` and use the full controller below:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

#[Middleware('auth')]
class ArticleController extends Controller
{
    public function index(): View
    {
        $articles = Article::query()
            ->where('user_id', auth()->id())
            ->latest()
            ->get();

        return view('articles.index', compact('articles'));
    }

    public function create(): View
    {
        return view('articles.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
        ]);

        $article = $request->user()->articles()->create($data);

        return redirect()->route('articles.show', $article->id);
    }

    public function show(int $article): View
    {
        // Resolve the model after the web middleware has run.
        $record = Article::query()->findOrFail($article);
        abort_unless($record->user_id === auth()->id(), 403);

        // This SELECT uses the same read routing as the article lookup.
        $serverId = (int) DB::selectOne('SELECT @@server_id AS server_id')->server_id;

        return view('articles.show', compact('record', 'serverId'));
    }

    public function edit(int $article): View
    {
        $record = Article::query()->findOrFail($article);
        abort_unless($record->user_id === auth()->id(), 403);

        return view('articles.edit', compact('record'));
    }

    public function update(Request $request, int $article): RedirectResponse
    {
        $record = Article::query()->findOrFail($article);
        abort_unless($record->user_id === auth()->id(), 403);

        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
        ]);

        $record->update($data);

        return redirect()->route('articles.show', $record->id);
    }

    public function destroy(int $article): RedirectResponse
    {
        $record = Article::query()->findOrFail($article);
        abort_unless($record->user_id === auth()->id(), 403);

        $record->delete();

        return redirect()->route('articles.index');
    }
}
```

The `#[Middleware('auth')]` attribute applies Laravel 13's controller middleware convention. The ownership checks prevent an authenticated user from reading or modifying another user's articles. The `show()` method includes a diagnostic `@@server_id` read; it will show `1` when the primary served the query and `2` when the replica served it. This is a teaching aid, not something most production article pages should display.

Open `routes/web.php` and replace it with:

```php
<?php

use App\Http\Controllers\ArticleController;
use App\Http\Controllers\LoginController;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/articles');

Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'create'])->name('login');
    Route::post('/login', [LoginController::class, 'store'])->name('login.store');
});

Route::post('/logout', [LoginController::class, 'destroy'])
    ->middleware('auth')
    ->name('logout');

// ArticleController applies its own #[Middleware('auth')] attribute.
Route::resource('articles', ArticleController::class);
```

Save all three files and inspect the registered routes:

```bash
php artisan route:list
```

Expected result: named routes for login, logout, and `articles.index`, `articles.create`, `articles.store`, `articles.show`, `articles.edit`, `articles.update`, and `articles.destroy`. The controller intentionally accepts integer route IDs, so the model query happens inside the action.

## Step 7: Create the Standalone Blade Views {#step-7-create-the-standalone-blade-views}

Create the two view directories:

```bash
mkdir -p resources/views/auth resources/views/articles
```

Every view uses standalone HTML and the Tailwind CDN. The QadrLabs footer is inside each Blade file, not appended to the Markdown article itself.

### Login View

Create `resources/views/auth/login.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Demo Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-4">Article Demo Login</h1>
        <p class="text-gray-600 mb-4">Sign in with the local demo account.</p>
        <form method="POST" action="{{ route('login.store') }}" class="space-y-4">
            @csrf
            <label class="block">Email
                <input type="email" name="email" value="{{ old('email', 'editor@example.test') }}"
                       class="mt-1 w-full border rounded p-2" required>
            </label>
            <label class="block">Password
                <input type="password" name="password" class="mt-1 w-full border rounded p-2" required>
            </label>
            @error('email') <p class="text-red-600 text-sm">{{ $message }}</p> @enderror
            <button class="bg-blue-600 text-white px-4 py-2 rounded">Log In</button>
        </form>
        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Database Replication at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The form posts to the login route, includes CSRF protection, and shows validation errors. The password remains blank on each render.

### Article List View

Create `resources/views/articles/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Articles</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">My Articles</h1>
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button class="text-sm text-red-600">Log Out</button>
            </form>
        </div>
        <a class="inline-block bg-blue-600 text-white px-4 py-2 rounded mb-5"
           href="{{ route('articles.create') }}">New Article</a>
        <div class="space-y-3">
            @forelse($articles as $article)
                <div class="border rounded p-4">
                    <a class="font-semibold text-blue-700"
                       href="{{ route('articles.show', $article->id) }}">{{ $article->title }}</a>
                </div>
            @empty
                <p class="text-gray-500">No articles yet.</p>
            @endforelse
        </div>
        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Database Replication at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

This list scopes articles to the logged-in user because the controller filters by their ID. The links open the article detail page used for the replication experiment.

### Create Article View

Create `resources/views/articles/create.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New Article</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-4">New Article</h1>
        <form method="POST" action="{{ route('articles.store') }}" class="space-y-4">
            @csrf
            <label class="block">Title
                <input name="title" value="{{ old('title') }}" required
                       class="mt-1 w-full border rounded p-2">
                @error('title') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
            </label>
            <label class="block">Body
                <textarea name="body" required rows="5"
                          class="mt-1 w-full border rounded p-2">{{ old('body') }}</textarea>
                @error('body') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
            </label>
            <button class="bg-blue-600 text-white px-4 py-2 rounded">Save Article</button>
            <a class="ml-3 text-blue-700" href="{{ route('articles.index') }}">Cancel</a>
        </form>
        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Database Replication at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The form submits a title and body. The authenticated user is attached on the server through the Eloquent relationship, so the browser never needs to send `user_id`.

### Edit Article View

Create `resources/views/articles/edit.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Edit Article</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-4">Edit Article</h1>
        <form method="POST" action="{{ route('articles.update', $record->id) }}" class="space-y-4">
            @csrf
            @method('PUT')
            <label class="block">Title
                <input name="title" value="{{ old('title', $record->title) }}" required
                       class="mt-1 w-full border rounded p-2">
                @error('title') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
            </label>
            <label class="block">Body
                <textarea name="body" required rows="5"
                          class="mt-1 w-full border rounded p-2">{{ old('body', $record->body) }}</textarea>
                @error('body') <span class="text-red-600 text-sm">{{ $message }}</span> @enderror
            </label>
            <button class="bg-blue-600 text-white px-4 py-2 rounded">Update Article</button>
            <a class="ml-3 text-blue-700" href="{{ route('articles.show', $record->id) }}">Cancel</a>
        </form>
        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Database Replication at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The `@method('PUT')` directive tells Laravel to treat this HTML POST as a PUT request. The form preserves the existing article values while allowing corrections when validation fails.

### Article Detail View

Create `resources/views/articles/show.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Article Detail</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <a class="text-blue-700" href="{{ route('articles.index') }}">Back to Articles</a>
        <h1 class="text-2xl font-bold mt-4">{{ $record->title }}</h1>
        <p class="text-gray-700 whitespace-pre-line mt-4">{{ $record->body }}</p>
        <div class="bg-blue-50 border border-blue-200 rounded p-3 mt-6 text-sm">
            Database server ID: <strong>{{ $serverId }}</strong>
            <span class="text-gray-600">(1 = primary, 2 = replica)</span>
        </div>
        <div class="flex items-center gap-4 mt-6">
            <a class="bg-blue-600 text-white px-4 py-2 rounded"
               href="{{ route('articles.edit', $record->id) }}">Edit</a>
            <form method="POST" action="{{ route('articles.destroy', $record->id) }}">
                @csrf
                @method('DELETE')
                <button class="text-red-600" onclick="return confirm('Delete this article?')">
                    Delete
                </button>
            </form>
        </div>
        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Database Replication at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The server indicator helps establish which connection supplied the displayed article. Both the model query and the `@@server_id` query run inside the controller action, after the web middleware stack has had an opportunity to choose a read connection.

Save all five views. Start Laravel:

```bash
php artisan serve
```

Expected result: the application serves `http://127.0.0.1:8000`. Sign in at `/login` using `editor@example.test` and `local-password-123`. The article list should contain `First draft`; opening it should show **database server ID 2** once replication has caught up. Try creating an article, editing it, and deleting it while replication is running normally before continuing.

## Step 8: Reproduce the Stale Read Before Enabling Middleware {#step-8-reproduce-the-stale-read-before-enabling-middleware}

Now deliberately pause replication after the initial article and account have arrived on the replica. This reproduces a large, predictable lag without relying on the timing of a real production workload.

In a second terminal, open the replica's MySQL shell:

```bash
docker compose exec mysql-replica mysql -uroot -p
```

Run:

```sql
STOP REPLICA SQL_THREAD;
SHOW REPLICA STATUS\G
```

The receiver may keep fetching binary log events, but the SQL applier stops applying changes to replica tables. Confirm `Replica_SQL_Running` is `No` before continuing. Do not stop the primary.

In the browser, open the existing `First draft` article and click **Edit**. Change its title to `Revision A`, keep the body, and submit the form. Laravel updates the article on the primary and redirects to the detail page. Because the replica still has the original record, the detail page should show **First draft** with **database server ID 2**. That is the stale read.

Verify the divergence directly. In the primary MySQL client, run:

```sql
USE repo_demo;
SELECT id, title FROM articles ORDER BY id;
```

Expected result: the original article's title is `Revision A` on the primary. Run the same query in the replica client. The title should still be `First draft`. This is evidence of replication lag, not evidence that the update failed.

Restore replication now so the next demonstration starts with matching data:

```sql
START REPLICA SQL_THREAD;
SHOW REPLICA STATUS\G
```

Run these commands in the **replica** client, then repeat `SELECT id, title FROM repo_demo.articles ORDER BY id;` there until `Revision A` appears. Confirm `Replica_SQL_Running` returns to `Yes`. The SQL applier has caught up and the two copies are ready for a controlled second experiment.

## Step 9: Register PreventStaleDatabaseReads {#step-9-register-preventstaledatabasereads}

Laravel 13.38.0 ships `Illuminate\Foundation\Http\Middleware\PreventStaleDatabaseReads`, but it is not enabled automatically. It works with the HTTP session to remember when the current user last wrote to the default database connection.

Open `bootstrap/app.php` and replace the complete file with:

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Foundation\Http\Middleware\PreventStaleDatabaseReads;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Use 15 seconds for an observable browser demonstration.
        $middleware->web(append: [
            PreventStaleDatabaseReads::for(15),
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );
    })->create();
```

`PreventStaleDatabaseReads::for(15)` configures a 15-second protection window, which is easier to observe by clicking through a browser. The normal default is **2 seconds**, so a production application can use `PreventStaleDatabaseReads::class` when its replication delay is consistently short. The argument is an interval in seconds, not a timeout for MySQL replication.

Save the file and clear the route cache if you have cached routes:

```bash
php artisan route:clear
php artisan route:list
```

Expected result: the same article and login routes remain available. No new route is registered because the change concerns middleware, not URL definitions. Reopen the article in the browser and confirm its title is `Revision A` while the replica is caught up.

## Step 10: Add Pest Feature Tests {#step-10-add-pest-feature-tests}

The project already includes Pest from Step 1. We will add nine feature tests for authentication, CRUD, validation, and ownership protection. They use SQLite through Laravel's test configuration; the cross-server replication behavior remains a separate integration scenario in Step 11.

Open `tests/Pest.php` and ensure the base test case is applied to Feature tests. If it is already configured, leave the existing registration in place rather than adding a duplicate:

```php
<?php

use Tests\TestCase;

uses(TestCase::class)->in('Feature');
```

Use `RefreshDatabase` directly in the new test file so the database is reset for each test. Create `tests/Feature/ArticleReplicationDemoTest.php` with:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function makeDemoArticle(User $user, string $title = 'First draft')
{
    return $user->articles()->create([
        'title' => $title,
        'body' => 'A body for the test article.',
    ]);
}

it('requires authentication to view articles', function () {
    $this->get(route('articles.index'))
        ->assertRedirect(route('login'));
});

it('allows the demo user to log in', function () {
    $user = User::factory()->create(['password' => 'local-password-123']);

    $this->post(route('login.store'), [
        'email' => $user->email,
        'password' => 'local-password-123',
    ])->assertRedirect(route('articles.index'));

    $this->assertAuthenticatedAs($user);
});

it('creates an article under its owner', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->post(route('articles.store'), [
        'title' => 'Fresh article',
        'body' => 'Written by the owner.',
    ])->assertRedirect();

    $this->assertDatabaseHas('articles', [
        'user_id' => $user->id,
        'title' => 'Fresh article',
    ]);
});

it('validates required article fields', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->post(route('articles.store'), [
        'title' => '',
        'body' => '',
    ])->assertSessionHasErrors(['title', 'body']);
});

it('only lists articles owned by the user', function () {
    $owner = User::factory()->create();
    $other = User::factory()->create();
    makeDemoArticle($owner, 'My private title');
    makeDemoArticle($other, 'Another private title');

    $this->actingAs($owner)->get(route('articles.index'))
        ->assertOk()
        ->assertSee('My private title')
        ->assertDontSee('Another private title');
});

it('shows an article to its owner', function () {
    $user = User::factory()->create();
    $article = makeDemoArticle($user);

    $this->actingAs($user)->get(route('articles.show', $article->id))
        ->assertOk()
        ->assertSee('First draft');
});

it('updates an article title', function () {
    $user = User::factory()->create();
    $article = makeDemoArticle($user);

    $this->actingAs($user)->put(route('articles.update', $article->id), [
        'title' => 'Revision A',
        'body' => 'Updated body.',
    ])->assertRedirect(route('articles.show', $article->id));

    $this->assertDatabaseHas('articles', [
        'id' => $article->id,
        'title' => 'Revision A',
    ]);
});

it('forbids reading and editing another users article', function () {
    $owner = User::factory()->create();
    $other = User::factory()->create();
    $article = makeDemoArticle($owner);

    $this->actingAs($other)
        ->get(route('articles.show', $article->id))
        ->assertForbidden();

    $this->actingAs($other)
        ->put(route('articles.update', $article->id), [
            'title' => 'Unauthorized change',
            'body' => 'Unauthorized body',
        ])->assertForbidden();
});

it('deletes an article owned by the user', function () {
    $user = User::factory()->create();
    $article = makeDemoArticle($user);

    $this->actingAs($user)->delete(route('articles.destroy', $article->id))
        ->assertRedirect(route('articles.index'));

    $this->assertDatabaseMissing('articles', ['id' => $article->id]);
});
```

These nine tests cover the essential article flow. They do not pretend that SQLite has MySQL's primary/replica routing. The test for `articles.show` will read a different database server ID under SQLite, so the assertion checks only the article content, not the hardcoded MySQL server ID.

To make that last point work, adjust the `ArticleController::show()` diagnostic query so it runs only with MySQL. Replace the line:

```php
$serverId = (int) DB::selectOne('SELECT @@server_id AS server_id')->server_id;
```

with:

```php
$serverId = DB::connection()->getDriverName() === 'mysql'
    ? (int) DB::selectOne('SELECT @@server_id AS server_id')->server_id
    : null;
```

Then replace the database indicator portion of `resources/views/articles/show.blade.php`:

```html
<div class="bg-blue-50 border border-blue-200 rounded p-3 mt-6 text-sm">
    Database server ID: <strong>{{ $serverId }}</strong>
    <span class="text-gray-600">(1 = primary, 2 = replica)</span>
</div>
```

with:

```html
@if($serverId !== null)
    <div class="bg-blue-50 border border-blue-200 rounded p-3 mt-6 text-sm">
        Database server ID: <strong>{{ $serverId }}</strong>
        <span class="text-gray-600">(1 = primary, 2 = replica)</span>
    </div>
@endif
```

This keeps the production-oriented MySQL diagnostic visible in the browser while allowing SQLite feature tests to exercise the same controller safely. Save both changes before running the tests.

Run the test file:

```bash
php artisan test tests/Feature/ArticleReplicationDemoTest.php
```

Expected result: all **9 tests** pass. Read the actual command output to verify the pass count, assertion details, and duration on your machine. If the test environment unexpectedly connects to MySQL, check that `phpunit.xml` defines `DB_CONNECTION=sqlite` and `DB_DATABASE=:memory:` and that its SQLite configuration has not been overridden by cached configuration.

## Step 11: Try It Out {#step-11-try-it-out}

The final experiment compares the same update workflow while the replica is deliberately behind. Work from the article called `Revision A`. Keep the existing browser session logged in, and leave Laravel's web server running.

### Scenario A: Pause Replication Again

Open the replica MySQL shell:

```bash
docker compose exec mysql-replica mysql -uroot -p
```

```sql
STOP REPLICA SQL_THREAD;
SHOW REPLICA STATUS\G
```

Expected result: `Replica_SQL_Running` is `No`. The replica still has `Revision A`, and the primary is ready to accept another edit.

### Scenario B: Update and Read Within the Protection Window

In the browser, open the article detail page, click **Edit**, change its title to `Revision B`, and submit promptly. The update goes to the primary. The redirect starts a new HTTP request; middleware reads the session timestamp and routes its SELECT queries to the write PDO.

Expected browser result: the title is **Revision B** and the database indicator is **1**. Refresh immediately, within 15 seconds of the update. The page should still show **Revision B** from primary.

Verify the data directly if desired. The primary contains `Revision B`; the stopped replica still contains `Revision A`. The browser displays the primary version because the middleware temporarily selects that connection for the same session.

### Scenario C: Let the Protection Window Expire

Keep the replica's SQL thread paused and wait more than 15 seconds from the last write. Refresh the article again.

Expected browser result: the page may again show **Revision A** with database indicator **2**, because the middleware's protection window has ended while the replica remains artificially delayed. This behavior is intentional and illustrates the limit of a time-based guard. It is not a guarantee of replica freshness after the timer expires.

### Scenario D: Resume Replication and Verify Recovery

In the replica MySQL client, run:

```sql
START REPLICA SQL_THREAD;
SHOW REPLICA STATUS\G
SELECT id, title FROM repo_demo.articles ORDER BY id;
```

Repeat the SELECT until the title becomes `Revision B`. Check that both replication threads are running and the error fields are clear. Refresh the browser again after the protection window. The replica should now return **Revision B** with indicator **2**.

The comparison is now complete: before middleware, the immediate redirected read was stale; with middleware, the same user reads the primary during the configured window. After the window, correctness once again depends on the replica catching up.

## How PreventStaleDatabaseReads Works Under the Hood {#how-preventstaledatabasereads-works-under-the-hood}

The middleware is intentionally small. Its core behavior is to check a timestamp in the session **before** the next route action runs, then record the timestamp **after** a request has modified records. You can inspect its exact implementation in the [Laravel v13.38.0 source](https://github.com/laravel/framework/blob/v13.38.0/src/Illuminate/Foundation/Http/Middleware/PreventStaleDatabaseReads.php).

When a request begins, the middleware reads the session key `_database_modified_at`. If that timestamp falls within the configured interval, it calls `useWriteConnectionWhenReading(true)` on the default database connection. Otherwise, reads can use the configured replica. After the downstream request finishes, it checks whether records were modified and, if so, writes the current timestamp to the session.

The middleware is different from Laravel's existing `sticky` setting. Sticky routing remembers a write **during the current HTTP request**. The new middleware remembers a write **across requests sharing the same session**, for a configurable number of seconds. Neither feature makes asynchronous replication synchronous.

There are practical limits. The middleware is session-based and monitors the default database connection. It is not a general solution for stateless API clients, users with separate sessions, background readers, or replication that remains delayed beyond the configured interval. Session availability and middleware ordering therefore matter. In this project, models are resolved inside the controller so that the appended middleware has already selected the intended read connection before those database queries execute.

## When to Use usingWritePdo() Instead {#when-to-use-usingwritepdo-instead}

Laravel 13.38.0 also adds `usingWritePdo()` to the database connection. Unlike the session middleware, this method directs reads to the write connection **only while a callback executes** and restores the prior setting afterward, including when the callback throws an exception.

For example, a service method can force a fresh read for both a user and its related articles:

```php
use App\Models\User;
use Illuminate\Support\Facades\DB;

$userWithArticles = DB::connection()->usingWritePdo(
    fn () => User::query()
        ->with('articles')
        ->findOrFail($userId)
);
```

The `with('articles')` relationship query runs inside the same callback, so it also uses the write PDO. This avoids a common pitfall where forcing one model query to primary does not automatically force later relation queries to use primary. For selected operations that require fresh reads irrespective of browser sessions, `usingWritePdo()` offers finer control. See [Laravel PR #62099](https://github.com/laravel/framework/pull/62099).

## Troubleshooting the Replication Demo {#troubleshooting-the-replication-demo}

Replication demos can fail for reasons that have nothing to do with Laravel's middleware. Check each layer in order rather than adjusting multiple settings at once.

- **Replica is not running:** Check `docker compose ps` and the container logs. Both MySQL servers must finish initialization before replication is configured.
- **Replica SQL error:** Inspect `SHOW REPLICA STATUS\G` and `Last_SQL_Error`. A conflicting table or account often means a replica was initialized with different data or the wrong log coordinates were used. For a disposable lab, starting again with clean Docker volumes can be simpler than repairing divergent databases.
- **Authentication to source fails:** Verify the `replicator` account and `GET_SOURCE_PUBLIC_KEY = 1` in the local setup. For real environments, configure replication over TLS.
- **Laravel cannot connect:** Confirm `pdo_mysql`, the `.env` values, the exposed ports, and `php artisan config:clear`.
- **Every article read goes to primary:** A write during the same request may trigger `sticky`, or the session timestamp may still be within the protection window. Check the timing and use a fresh GET request.
- **The article lookup still reads the replica:** Do not use implicit `Article $article` route model binding with this tutorial's appended middleware arrangement. Resolve the model in the action, after middleware runs.
- **The tests connect to MySQL:** Keep the SQLite testing overrides in `phpunit.xml`. The integration demo uses MySQL; feature tests use the in-memory testing database.

When finished with the lab, stop the containers:

```bash
docker compose down
```

This preserves the named data volumes for later use. If the entire disposable lab is no longer needed, `docker compose down -v` additionally removes both MySQL volumes and permanently deletes their local data.

## Conclusion {#conclusion}

Stale reads are a consequence of asynchronous replication, not necessarily a failed update. By reproducing the condition locally, we can distinguish a real data-loss bug from a temporarily delayed replica and choose the appropriate Laravel behavior.

- **Read/write splitting.** Laravel sends ordinary reads to replicas and writes to primary when `read` and `write` connections are configured.
- **Sticky connections.** The `sticky` option keeps reads on the primary within the same request after a write, but does not protect a later redirect or refresh.
- **Controlled replication lag.** Pausing the MySQL replica's SQL applier creates a predictable stale-read scenario without relying on chance.
- **PreventStaleDatabaseReads.** Laravel 13.38.0 tracks writes in the session and temporarily routes that session's reads to the write connection, for 2 seconds by default or a customized interval.
- **Middleware ordering.** Database model lookup must happen after the middleware selects the connection. Explicit controller queries keep this demo's behavior predictable.
- **Testing.** Pest verifies CRUD, validation, authentication, and ownership; the MySQL integration exercise verifies actual primary/replica behavior.
- **usingWritePdo().** For a specific operation requiring fresh data, its callback can force primary reads, including relationship queries, without relying on a browser session.
- **Consistency limits.** Neither method accelerates replication or guarantees all users see the latest data. Choose the protection interval based on observed replication behavior, and monitor replication health independently.

For further details, consult the [Laravel 13 database documentation](https://laravel.com/docs/13.x/database#read-and-write-connections) and the [Laravel 13.38.0 release notes](https://github.com/laravel/framework/releases/tag/v13.38.0).
