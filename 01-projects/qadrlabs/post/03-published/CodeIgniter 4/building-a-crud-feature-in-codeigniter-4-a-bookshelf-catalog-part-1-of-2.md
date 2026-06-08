---
title: "Building a CRUD Feature in CodeIgniter 4: A BookShelf Catalog (Part 1 of 2)"
slug: "building-a-crud-feature-in-codeigniter-4-a-bookshelf-catalog-part-1-of-2"
category: "CodeIgniter 4"
date: "2026-05-06"
status: "published"
---

Most CodeIgniter tutorials show you how to build a feature, then stop. The application works in the browser, the screenshots look good, and the article ends with a polite "happy coding" sign-off. A few weeks later, when the requirements change or a bug appears in production, the developer who built that feature has no way to know whether their fix broke something else. There are no tests, and there is no clear path to writing them, because the code was not designed with testability in mind to begin with.

This is the gap this two-part series exists to close. In Part 1 we will build a small but realistic CRUD application called BookShelf, a personal book catalog with all five CRUD verbs working through HTML forms. We will deliberately make design choices that pay off when we write tests in Part 2: thin controllers, validation in a predictable place, redirects after every write, and views that render real data without any AJAX or single-page-application complications. Part 2 will install Pest, bridge it to CodeIgniter 4's testing infrastructure, and write a complete test suite that covers every endpoint we build today. By the end of both articles you will have a working CRUD feature, a test suite that proves it works, and a mental model you can apply to any future CodeIgniter 4 project.

If you have used Laravel before, much of CodeIgniter 4 will feel familiar but slightly different. The directory layout, the migration system, the model class, and the routing all serve the same purposes as their Laravel counterparts but with different names and conventions. Where useful, this article will name those Laravel parallels explicitly to help you transfer your existing knowledge. If CodeIgniter 4 is your first PHP framework, do not worry: every concept is introduced from scratch, and the patterns you learn here are general enough to apply to any modern web framework.

## Overview {#overview}

The work in Part 1 is purely about building the feature. There are no tests yet, but there is a strong emphasis on the design decisions that will make tests easy in Part 2. We start with a fresh CodeIgniter 4 install, configure MySQL as the development database, create one table called `books`, and build a controller that handles all the CRUD operations through standard HTML forms. The views use Tailwind CSS via the CDN, which means no Vite, no npm, and no asset compilation. You can read the entire tutorial in one sitting, type the code as you go, and end up with a working application in your browser.

### What You'll Build
- A CodeIgniter 4 application called BookShelf with five working CRUD endpoints
- A `books` MySQL table with title, author, year, genre, read-status, and notes fields
- A `BookModel` that wraps Eloquent-style queries around the table
- A `BookController` with seven methods: `index`, `new`, `create`, `edit`, `update`, `delete`, plus a small redirect helper
- Four Tailwind-styled views that work on both desktop and mobile

### What You'll Learn
- How to set up a CodeIgniter 4 project with MySQL and run your first migration
- Where each piece of the framework lives in the project structure (controllers, models, views, routes, migrations)
- How to write a controller that handles both display routes and form-submission routes
- How to validate user input in the controller layer using CI4's built-in validation rules
- How to render flash messages cleanly after a successful create, update, or delete
- The POST-redirect-GET pattern and why it matters for both users and tests

### What You'll Need
- PHP 8.3 or later with the `intl`, `mysqlnd`, and `mbstring` extensions enabled
- Composer 2.x installed and on your `PATH`
- A running MySQL or MariaDB server, with a username and password you can use to create databases
- A terminal and a code editor (VS Code, PHPStorm, or anything else you are comfortable with)
- A modern web browser to view the result

## Step 1: Create the CodeIgniter 4 Project {#step-1-create-the-codeigniter-4-project}

CodeIgniter 4 is distributed as a Composer package called `codeigniter4/appstarter`. The "starter" part of the name matters: this is the project skeleton meant for new applications, not the framework source code itself. Composer downloads it once into a directory you choose, and that directory becomes your project root.

Open your terminal and run the following command. It tells Composer to create a new project from the latest stable starter, with `bookshelf` as the destination folder.

```bash
composer create-project codeigniter4/appstarter bookshelf
cd bookshelf
```

The download takes about thirty seconds on a normal connection. After Composer finishes, you will see a directory layout that looks like this. The folder names are worth recognizing because we will visit each one as we build the feature.

```
bookshelf/
├── app/                    # your application code (controllers, models, views, config)
├── public/                 # the web root, contains index.php and assets
├── system/                 # the framework source code (do not edit)
├── tests/                  # where Part 2 will live
├── writable/               # logs, sessions, uploads, cache
├── env                     # template environment file (rename to .env)
├── spark                   # the CLI tool, similar to Laravel's `artisan`
└── composer.json
```

If you have used Laravel, this layout will feel familiar with different names. The `spark` file is what `artisan` is to Laravel. The `app/` folder holds your application's code. The `public/` folder is the web root where Apache or Nginx (or PHP's built-in server) should point. The `system/` folder is framework code you should never modify directly.

Before we can run anything, we need to copy the environment template into a real `.env` file that CodeIgniter will actually read. The starter ships with a file literally named `env` (no dot in front) precisely so it is visible in directory listings and easy to find. We rename it to `.env` so PHP recognizes it.

```bash
cp env .env
```

Open `.env` in your editor and find the line that says `# CI_ENVIRONMENT = production`. Remove the leading `#` and change `production` to `development`. This single change unlocks several developer-friendly features, such as detailed error pages, debug toolbars, and a relaxed CSRF policy that makes form testing easier. The line should now read:

```
CI_ENVIRONMENT = development
```

Verify that the install works by starting CodeIgniter's built-in development server. The `spark serve` command is the equivalent of `php artisan serve` in Laravel; it spins up PHP's built-in server pointed at the right document root.

```bash
php spark serve
```

You should see output similar to this in your terminal.

```
CodeIgniter v4.7.2 Command Line Tool - Server Time: 2026-05-04 14:22:18 UTC

CodeIgniter development server started on http://localhost:8080
Press Control-C to stop.
```

Open `http://localhost:8080` in your browser and you should see the CodeIgniter welcome page, which is a friendly screen telling you the framework is alive. Stop the server with Ctrl+C for now; we will start it again later when we have something real to view.

## Step 2: Configure the MySQL Database {#step-2-configure-the-mysql-database}

CodeIgniter 4 reads database credentials from the `.env` file, which is the same place we just edited. The configuration system has good defaults baked into `app/Config/Database.php`, but those defaults are designed to be overridden by environment-specific values, which is exactly what `.env` is for. This separation means the same code can run on your laptop, on a teammate's laptop, on a staging server, and in production, with each environment supplying its own credentials.

Before we touch the configuration, create a fresh MySQL database for this project. Connect to MySQL using whatever client you prefer (the command-line `mysql` tool, MySQL Workbench, phpMyAdmin, TablePlus, or any other) and run the following SQL. Replace `bookshelf_user` and `secret_password` with credentials that make sense for your local environment.

```sql
CREATE DATABASE bookshelf CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'bookshelf_user'@'localhost' IDENTIFIED BY 'secret_password';
GRANT ALL PRIVILEGES ON bookshelf.* TO 'bookshelf_user'@'localhost';
FLUSH PRIVILEGES;
```

The `utf8mb4` character set is worth a moment of explanation. The older `utf8` set in MySQL only supports characters that fit in three bytes, which excludes most emoji and some less common symbols. The `utf8mb4` set supports the full four-byte UTF-8 range, which is what you almost always want for user-generated content. Setting this at database creation time avoids painful migration work later if a user types an emoji into a book title.

Now open `.env` in your editor again and find the database section, which lives near the bottom of the file. Most lines are commented out by default. Uncomment and update the relevant ones so your database section looks like this.

```
database.default.hostname = localhost
database.default.database = bookshelf
database.default.username = bookshelf_user
database.default.password = secret_password
database.default.DBDriver = MySQLi
database.default.DBPrefix =
database.default.port = 3306
```

The `DBDriver` value is `MySQLi`, not `MySQL`. The capital `i` matters; it refers to the improved MySQL extension that PHP has used since version 5. The `DBPrefix` is empty because we do not want CodeIgniter to prepend any prefix to our table names. The `port` is the standard MySQL port. If your MySQL is running on a non-standard port (perhaps because you are using Docker or a managed cloud database), adjust accordingly.

Verify the connection works by running CodeIgniter's database utility command. If the credentials are wrong, this command will tell you immediately rather than letting the error surface later when you run a migration.

```bash
php spark db:table --show
```

A successful connection produces a message about there being no tables yet (which is correct, we have not run any migrations). A failed connection produces an error mentioning host, username, or password problems. Resolve any errors before continuing.

## Step 3: Create the Books Migration {#step-3-create-the-books-migration}

A migration in CodeIgniter 4 is a versioned PHP file that describes a change to the database schema. Each migration has an `up()` method that applies the change and a `down()` method that undoes it. The framework keeps track of which migrations have run and which have not, so running `php spark migrate` brings any database up to the current schema regardless of where it started.

This concept will feel completely familiar if you have used Laravel migrations. The differences are mostly cosmetic: CodeIgniter uses a `Forge` object (the equivalent of Laravel's `Schema` builder) and a slightly different syntax for column definitions, but the structural idea is identical.

Generate a migration file using the `make:migration` spark command. The class name we pass becomes both the file name and the class name inside the file.

```bash
php spark make:migration CreateBooksTable
```

You should see output like this, confirming the file was created.

```
File created: APPPATH\Database\Migrations\2026-05-04-142500_CreateBooksTable.php
```

Open the generated file. The exact filename will include a different timestamp on your machine, but the location is `app/Database/Migrations/` and the file will end with `_CreateBooksTable.php`. Replace its contents with the following migration. Each column has a comment explaining what it represents, because this is the moment to be deliberate about your data model rather than discovering its quirks during debugging.

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateBooksTable extends Migration
{
    public function up()
    {
        // The Forge fluent API is similar in spirit to Laravel's Schema builder.
        // Each addField() call describes one column, and the addKey calls
        // describe the primary key and any indexes.
        $this->forge->addField([
            'id'         => [
                'type'           => 'INT',
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'title'      => [
                'type'       => 'VARCHAR',
                'constraint' => 200,
            ],
            'author'     => [
                'type'       => 'VARCHAR',
                'constraint' => 150,
            ],
            'year'       => [
                'type' => 'SMALLINT',
            ],
            'genre'      => [
                'type'       => 'VARCHAR',
                'constraint' => 50,
            ],
            'is_read'    => [
                'type'    => 'TINYINT',          // MySQL convention for booleans
                'default' => 0,
            ],
            'notes'      => [
                'type' => 'TEXT',
                'null' => true,                  // notes are optional
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

        $this->forge->addKey('id', true);        // true marks this as the primary key
        $this->forge->createTable('books');
    }

    public function down()
    {
        $this->forge->dropTable('books');
    }
}
```

A few choices in this migration deserve a closer look so you understand what they buy us.

The `title` and `author` columns are `VARCHAR` with a generous but bounded length. We could use `TEXT` for either, but doing so would make them harder to index later and would allow truly enormous inputs that should be rejected at the validation layer anyway. Bounded `VARCHAR` is the right default for fields with a natural maximum length.

The `year` column is `SMALLINT` because we will never need to store a year outside the range that `SMALLINT` covers (roughly negative thirty thousand to positive thirty thousand). Choosing the smallest type that fits saves storage space and makes the table slightly faster to scan. This is the kind of micro-decision that does not matter for ten rows but starts to matter for ten million.

The `is_read` column is `TINYINT` with a default of zero. MySQL does not have a native `BOOLEAN` type, only an alias called `BOOL` that is itself just `TINYINT(1)`. Using `TINYINT` directly makes this lineage explicit: the column stores zero or one, and we will treat zero as "not read yet" and one as "read".

The `notes` column allows `null`, which is how we encode optionality at the database level. A user does not have to write notes about every book, so we let the database represent the absence of notes as `null` rather than as an empty string. The validation layer will accept either, but the database layer is honest about what is present and what is absent.

The `created_at` and `updated_at` columns are also nullable. CodeIgniter's `Model` class manages these timestamps automatically when configured to do so, but we keep them nullable for safety in case rows are ever inserted through raw SQL without timestamps populated.

Run the migration to apply this schema to your database.

```bash
php spark migrate
```

You should see output similar to this.

```
Running all new migrations...
Running: (App) 2026-05-04-142500_App\Database\Migrations\CreateBooksTable
Done migrations.
```

If you connect to MySQL now and run `DESCRIBE books;`, you will see all nine columns in place, with the types we declared. The schema is ready to receive data.

## Step 4: Build the Book Model {#step-4-build-the-book-model}

A model in CodeIgniter 4 is a class that represents a database table and provides methods to query and manipulate it. The framework's `Model` base class is similar to Laravel's Eloquent in spirit but takes a slightly more procedural approach: instead of treating each row as a model instance, you call methods on a single `Model` object that returns rows as arrays or generic objects. The trade-off is that CodeIgniter models feel more like repositories than like active records, which is a style some developers find cleaner.

Generate a model file using the `make:model` spark command. The `--suffix` option (which would add `Model` to the class name) is the default in CodeIgniter, so we do not need to specify it.

```bash
php spark make:model BookModel
```

The output confirms the file location.

```
File created: APPPATH\Models\BookModel.php
```

Open `app/Models/BookModel.php`. The starter scaffolds a class with several properties already in place. Replace the file's contents with the following version, which is configured for our `books` table.

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class BookModel extends Model
{
    // The table this model represents. Without this property, CI4 would
    // try to guess the table name from the class name (e.g. "books" from
    // "BookModel"), which is correct here, but being explicit is better
    // because it removes one source of mystery for future readers.
    protected $table = 'books';

    // The primary key column. Defaults to 'id', which we use, but again
    // being explicit makes the model self-documenting.
    protected $primaryKey = 'id';

    // The data type returned when we query rows. 'array' is the most
    // convenient for views and tests because PHP arrays are easy to
    // pass around and assert against. The other option is 'object',
    // which gives you stdClass instances.
    protected $returnType = 'array';

    // Tells the model to automatically populate created_at and updated_at
    // on insert and update operations. We will not have to do this
    // manually anywhere in the controller.
    protected $useTimestamps = true;

    // The list of columns that can be mass-assigned through methods like
    // insert() and update(). This is CI4's equivalent of Laravel's
    // $fillable: a defense against accidentally writing to columns the
    // user should not be able to control (like 'id' or 'created_at').
    protected $allowedFields = [
        'title',
        'author',
        'year',
        'genre',
        'is_read',
        'notes',
    ];

    // We deliberately leave $validationRules empty here. CodeIgniter's
    // Model class supports validation at the model layer, but the user
    // has chosen to put validation in the controller for this tutorial.
    // Both approaches are valid; controller-level validation gives more
    // explicit control over which rules apply to which endpoint.
}
```

The decision to leave model-level validation empty is worth reflecting on. CodeIgniter 4's `Model` class can hold validation rules in a `$validationRules` property. When set, those rules run automatically during `insert()` and `update()` calls, and the model returns `false` (or throws an exception, depending on configuration) if the data fails. This is convenient and is the more common style in production CodeIgniter codebases.

The reason we are putting validation in the controller instead is pedagogical clarity. When validation lives in the model, the rules feel implicit: the model "just knows" how to validate itself. When validation lives in the controller, you can see exactly which fields are checked, in which order, and with which error messages, every time you read a controller method. For learning purposes the controller-level approach is more transparent. For production code with the same rules used in many places, model-level validation reduces duplication.

If you want a deeper understanding of how the model works, the `BookModel` class inherits a long list of methods from `CodeIgniter\Model` that you will use in the controller: `find($id)`, `findAll()`, `where('column', $value)->findAll()`, `insert($data)`, `update($id, $data)`, and `delete($id)`. We will see most of these in the next two steps.

## Step 5: Define the Routes {#step-5-define-the-routes}

Routing in CodeIgniter 4 maps URLs to controller methods. The framework supports automatic routing (where the URL `/books/edit/3` automatically calls `BookController::edit(3)`), but explicit routing is the recommended practice for production code. Explicit routes are easier to read, easier to refactor, and easier to test, because they document the entire URL surface of your application in one place.

Open `app/Config/Routes.php`. The file already contains a default route at the bottom that maps the root URL to a `Home::index` method, which is what served you the welcome page in Step 1. Replace the route definitions in the file with the following block. We add seven routes total: a redirect from the root to `/books`, plus six routes covering the full CRUD lifecycle.

```php
<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// Send the root URL to the books index. A small site like this one does
// not need a separate home page; the books list IS the home page.
$routes->get('/', static function () {
    return redirect()->to('/books');
});

// Read routes: list all books, show the new-book form, show the edit form.
$routes->get('books',                'BookController::index');
$routes->get('books/new',            'BookController::new');
$routes->get('books/(:num)/edit',    'BookController::edit/$1');

// Write routes: create, update, delete. All three are POST because HTML
// forms cannot send PUT or DELETE without JavaScript.
$routes->post('books',               'BookController::create');
$routes->post('books/(:num)',        'BookController::update/$1');
$routes->post('books/(:num)/delete', 'BookController::delete/$1');
```

Several details in this configuration are worth understanding clearly.

The placeholder `(:num)` matches one or more digits in the URL, which is exactly the pattern an integer ID takes. The captured digits are passed to the controller method as `$1`. CodeIgniter also has `(:any)` for any string and `(:segment)` for a single URL segment, but `(:num)` is the right choice for IDs because it rejects URLs like `/books/abc/edit` at the routing layer rather than letting them reach the controller and fail there.

All write operations use POST. Pure HTML forms cannot send PUT or DELETE requests; those verbs require JavaScript or a form-method spoofing middleware. Sticking to POST keeps the application simple and works in any browser, including users with JavaScript disabled. The trade-off is that the URLs are slightly less RESTful, but for a server-rendered application this is a fine choice.

The delete route uses a separate URL (`/books/3/delete`) rather than reusing the update URL with a different verb. This is partly because we are using POST for everything, and partly because separating the URLs makes the action of each route immediately obvious from its path alone. Tests in Part 2 will be very easy to read because every URL describes itself.

Verify the routes were registered correctly by running CodeIgniter's route listing command.

```bash
php spark routes
```

You should see output that includes the seven routes we just added.

```
+-----------+----------------------+-----------------------------------+----------------+---------------+
| Method    | Route                | Handler                           | Before Filters | After Filters |
+-----------+----------------------+-----------------------------------+----------------+---------------+
| GET       | /                    | (Closure)                         |                |               |
| GET       | books                | \App\Controllers\BookController:: |                |               |
|           |                      | index                             |                |               |
| GET       | books/new            | \App\Controllers\BookController:: |                |               |
|           |                      | new                               |                |               |
| GET       | books/([0-9]+)/edit  | \App\Controllers\BookController:: |                |               |
|           |                      | edit/$1                           |                |               |
| POST      | books                | \App\Controllers\BookController:: |                |               |
|           |                      | create                            |                |               |
| POST      | books/([0-9]+)       | \App\Controllers\BookController:: |                |               |
|           |                      | update/$1                         |                |               |
| POST      | books/([0-9]+)/delete| \App\Controllers\BookController:: |                |               |
|           |                      | delete/$1                         |                |               |
+-----------+----------------------+-----------------------------------+----------------+---------------+
```

The framework has noticed our `(:num)` placeholder and translated it into a regular expression `([0-9]+)` for matching, which is exactly what we want.

## Step 6: Build the BookController, Read Operations First {#step-6-build-the-bookcontroller-read-operations-first}

We will build the controller in two passes. The first pass implements the three read operations: showing the list, showing the new-book form, and showing the edit form. These methods are simpler because they only return views without modifying data. The second pass, in the next step, will add the three write operations: create, update, and delete.

Generate the controller file.

```bash
php spark make:controller BookController
```

The output confirms the location.

```
File created: APPPATH\Controllers\BookController.php
```

Open `app/Controllers/BookController.php` and replace its contents with the read-only version below. We will add to it in Step 7.

```php
<?php

namespace App\Controllers;

use App\Models\BookModel;

class BookController extends BaseController
{
    // Hold the model in a property so every method can use it without
    // re-instantiating. The constructor is the natural place to wire
    // this up, and CodeIgniter calls the constructor for us automatically.
    protected BookModel $books;

    public function __construct()
    {
        $this->books = new BookModel();
    }

    /**
     * GET /books
     *
     * Show the list of books, newest first. The order matters for the
     * test in Part 2 that asserts "newest first", and it matters for
     * users because the most recently added book is usually what they
     * are looking for.
     */
    public function index()
    {
        $books = $this->books
            ->orderBy('created_at', 'DESC')
            ->findAll();

        return view('books/index', [
            'books' => $books,
        ]);
    }

    /**
     * GET /books/new
     *
     * Show an empty form for creating a new book. This method is
     * deliberately small: it just renders the view. All the validation
     * and data-handling work happens in create() when the form is
     * submitted.
     */
    public function new()
    {
        return view('books/new');
    }

    /**
     * GET /books/{id}/edit
     *
     * Show the edit form for an existing book. If no book matches the
     * given id, throw a 404. The PageNotFoundException is what
     * CodeIgniter uses for "this resource does not exist", and it
     * triggers the framework's default 404 page.
     */
    public function edit(int $id)
    {
        $book = $this->books->find($id);

        if ($book === null) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound();
        }

        return view('books/edit', [
            'book' => $book,
        ]);
    }
}
```

Several choices here will matter when we write tests. The controller stores the model in a constructor-assigned property, which means the tests do not have to inject anything; they just hit the route and let CodeIgniter wire everything up. The `index` method returns a view directly, which means the response is HTML that we can search through with `assertSee()` in tests. The `edit` method throws a structured 404 exception when the book is missing, which the test will assert with `assertStatus(404)`.

The `findAll()` call on the model returns an array of books as associative arrays (because we set `$returnType = 'array'` in the model). If you preferred objects, you would set the return type to `'object'` and write `$book->title` in views instead of `$book['title']`. Both work; arrays are slightly more convenient for views, objects are slightly more convenient for code that walks complex graphs.

One thing you might notice is that we are not passing flash messages or session data to the views explicitly. The reason is that CodeIgniter's session is global; views can access flash messages through the `session()` helper without needing the controller to pass them through. This keeps the view-data array focused on the actual content of the page.

## Step 7: Build the BookController Write Operations {#step-7-build-the-bookcontroller-write-operations}

The second pass adds three methods that change data: `create`, `update`, and `delete`. These methods are where validation lives, and they all follow the POST-redirect-GET pattern. The pattern is simple: on a successful POST, the controller redirects (returning a 302 status) to a different URL; the browser follows the redirect, which fetches a fresh GET response. This pattern prevents users from accidentally double-submitting forms by pressing the back button, and it gives tests a clean target to assert against.

Open `app/Controllers/BookController.php` again and replace the entire file with the expanded version below. The three new methods (`create`, `update`, `delete`) come after `edit`. The validation rules are defined in a private helper so we do not duplicate them between `create` and `update`.

```php
<?php

namespace App\Controllers;

use App\Models\BookModel;
use CodeIgniter\Exceptions\PageNotFoundException;

class BookController extends BaseController
{
    protected BookModel $books;

    public function __construct()
    {
        $this->books = new BookModel();
    }

    public function index()
    {
        $books = $this->books
            ->orderBy('created_at', 'DESC')
            ->findAll();

        return view('books/index', [
            'books' => $books,
        ]);
    }

    public function new()
    {
        return view('books/new');
    }

    public function edit(int $id)
    {
        $book = $this->books->find($id);

        if ($book === null) {
            throw PageNotFoundException::forPageNotFound();
        }

        return view('books/edit', [
            'book' => $book,
        ]);
    }

    /**
     * POST /books
     *
     * Validate the input, save the book, set a flash message, and
     * redirect back to the index. If validation fails, redirect back
     * to the form with the errors and the user's previous input so
     * they do not have to retype everything.
     */
    public function create()
    {
        if (! $this->validate($this->validationRules())) {
            // The withInput() call preserves what the user typed in
            // the form, so the new() view can pre-fill the inputs
            // using the old() helper.
            return redirect()->back()
                ->withInput()
                ->with('errors', $this->validator->getErrors());
        }

        $this->books->insert($this->normalizedInput());

        return redirect()->to('/books')
            ->with('success', 'Book added to your shelf.');
    }

    /**
     * POST /books/{id}
     *
     * Same shape as create, but updates an existing row. We re-fetch
     * the book first to confirm it exists; without that check, the
     * model's update() would silently do nothing for a non-existent id
     * and the test would not be able to tell the difference.
     */
    public function update(int $id)
    {
        $book = $this->books->find($id);

        if ($book === null) {
            throw PageNotFoundException::forPageNotFound();
        }

        if (! $this->validate($this->validationRules())) {
            return redirect()->back()
                ->withInput()
                ->with('errors', $this->validator->getErrors());
        }

        $this->books->update($id, $this->normalizedInput());

        return redirect()->to('/books')
            ->with('success', 'Book updated.');
    }

    /**
     * POST /books/{id}/delete
     *
     * Confirm the book exists, delete it, and redirect to the index
     * with a flash message. There is no separate confirmation page;
     * the delete button itself sits inside a small confirmation form
     * (see the index view in Step 9) that asks the user to confirm
     * with a JavaScript prompt.
     */
    public function delete(int $id)
    {
        $book = $this->books->find($id);

        if ($book === null) {
            throw PageNotFoundException::forPageNotFound();
        }

        $this->books->delete($id);

        return redirect()->to('/books')
            ->with('success', 'Book removed from your shelf.');
    }

    /**
     * The validation rules used by both create() and update(). Defined
     * once so the two endpoints cannot drift apart over time.
     *
     * Each key is a field name; each value is a pipe-separated list of
     * CodeIgniter validation rules. The full list of built-in rules is
     * documented at https://codeigniter.com/user_guide/libraries/validation.html
     */
    private function validationRules(): array
    {
        return [
            'title'  => 'required|min_length[2]|max_length[200]',
            'author' => 'required|min_length[2]|max_length[150]',
            'year'   => 'required|integer|greater_than[999]|less_than[10000]',
            'genre'  => 'required|in_list[fiction,non-fiction,science,biography,history,technology,other]',
            'notes'  => 'permit_empty|max_length[2000]',
        ];
    }

    /**
     * Convert the raw form input into a clean array for the model.
     * The is_read field comes from a checkbox, which means it is
     * present in the request only when checked. We coerce it to a
     * boolean (1 or 0) so the database always gets a value.
     */
    private function normalizedInput(): array
    {
        return [
            'title'   => $this->request->getPost('title'),
            'author'  => $this->request->getPost('author'),
            'year'    => (int) $this->request->getPost('year'),
            'genre'   => $this->request->getPost('genre'),
            'is_read' => $this->request->getPost('is_read') ? 1 : 0,
            'notes'   => $this->request->getPost('notes'),
        ];
    }
}
```

This is the longest file in the entire tutorial, and it deserves a careful read because every choice will reappear when we write tests in Part 2.

The validation rules live in `validationRules()`, a private helper. Both `create` and `update` call this method, so the two endpoints share a single source of truth. If you ever decide that book titles can be three hundred characters instead of two hundred, you change one line and both endpoints update. This is a small but real benefit of the controller-level validation pattern when the same rules apply across multiple endpoints.

The rule strings might look unfamiliar if you come from Laravel, where the equivalent looks like `'title' => 'required|min:2|max:200'`. CodeIgniter uses `min_length` and `max_length` instead of `min` and `max`, and uses square-bracket arguments like `min_length[2]` instead of colon-separated arguments. The rule names are different but the concept is identical. The `in_list` rule restricts a field to a fixed set of values, which is how we enforce the genre options.

The `permit_empty` rule on `notes` is worth noting. Without it, an empty notes field would fail the `max_length` check (because CodeIgniter's default behavior is to apply rules even when a field is empty). Adding `permit_empty` says "skip the rest of the rules if the field is empty", which is the right behavior for an optional field.

The `normalizedInput()` helper exists to clean up the messy reality of HTML forms. The `is_read` field is a checkbox, which means it appears in the POST body only when it is checked; if the user leaves it unchecked, the field is not present at all. We use a ternary to coerce its presence-or-absence into a 1 or 0. The `year` field arrives as a string (HTML form fields are always strings), so we cast it to an integer before passing it to the model.

The redirect-with-input pattern in the validation-failure branch deserves attention. `redirect()->back()->withInput()` tells CodeIgniter to send the user back to the form they just submitted, with their previous input stored in flash data. The `new` and `edit` views (which we will build in Step 9) read this flash data through the `old()` helper to repopulate the form fields. Without this, a user who fails validation has to retype their whole entry, which is a bad experience.

The `redirect()->...->with()` calls attach flash data to the redirect. Flash data lives for exactly one request, which means the redirected-to page can read it and then it disappears. This is how we display "Book added to your shelf." once on the index page and never again.

## Step 8: Create the Layout View with Tailwind CDN {#step-8-create-the-layout-view-with-tailwind-cdn}

We will use Tailwind CSS through its CDN distribution. This means a single `<script>` tag in the layout brings in the entire Tailwind framework, with no build step, no npm install, and no Vite configuration. The trade-off is performance: the CDN ships every Tailwind class, even ones we do not use, which makes the page heavier than a properly compiled production build. For a tutorial application this trade-off is fine, and the simpler setup means the focus stays on CodeIgniter rather than on asset compilation.

CodeIgniter 4's view layer supports template inheritance through a pair of helpers called `extend()` and `section()`. A "layout" view is a regular view file that defines named sections; child views extend the layout and fill in the sections. This pattern is similar to Laravel's `@extends` and `@section` Blade directives, just with PHP function-call syntax instead of Blade's pseudo-tags.

Create the layout file at `app/Views/layout.php` with the following contents.

```php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= esc($title ?? 'BookShelf') ?></title>

    <!-- Tailwind CSS via CDN. No build step required. -->
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen">
    <header class="bg-white border-b border-slate-200">
        <div class="max-w-3xl mx-auto px-4 py-4 flex items-center justify-between">
            <a href="/books" class="text-xl font-semibold">BookShelf</a>
            <a href="/books/new"
               class="bg-slate-900 text-white text-sm px-3 py-2 rounded-lg">
                Add Book
            </a>
        </div>
    </header>

    <main class="max-w-3xl mx-auto px-4 py-8">

        <?php if (session()->getFlashdata('success')): ?>
            <div class="mb-6 bg-emerald-100 text-emerald-800 px-4 py-3 rounded-lg">
                <?= esc(session()->getFlashdata('success')) ?>
            </div>
        <?php endif; ?>

        <?= $this->renderSection('content') ?>

    </main>

    <footer class="text-center text-sm text-slate-400 py-8 border-t mt-12">
        Built for the testing tutorial at
        <a href="https://qadrlabs.com" class="underline">qadrlabs.com</a>
    </footer>
</body>
</html>
```

Two patterns in this layout will reappear in every child view, so understanding them now will save you headaches.

The first is `<?= esc(...) ?>`. The `esc()` function is CodeIgniter's HTML-escaping helper, equivalent to Laravel's `e()` or Blade's `{{ }}` syntax. Any data that comes from a user (or from the database, where it ultimately came from a user) should be wrapped in `esc()` to prevent cross-site scripting. The `<?= ?>` short tag is just shorthand for `<?php echo ... ?>`. Together, `<?= esc($value) ?>` is the safe way to output dynamic data.

The second is `$this->renderSection('content')`. This is the placeholder where child views will insert their content. The layout defines the surrounding structure (header, footer, flash message area) once, and each child view fills in just the part that is unique to its page. This is exactly the same idea as `@yield('content')` in Laravel Blade.

The flash message area reads `session()->getFlashdata('success')` and renders an emerald-green banner if any success message is present. We do not need a separate "error" flash because validation errors are passed through `withInput()` and rendered inside each form view (Step 9 will show this). For non-validation errors, we could add an analogous block for `getFlashdata('error')`, but our application does not produce any such errors yet.

## Step 9: Build the Index and Form Views {#step-9-build-the-index-and-form-views}

We need three child views: `index.php` for the list, `new.php` for the create form, and `edit.php` for the edit form. The two form views share most of their content, but we keep them as separate files because each one has slightly different behavior (the edit form preloads existing data, the new form starts blank).

### The Index View

Create `app/Views/books/index.php` with the following contents. This view shows a card for each book, with edit and delete buttons attached.

```php
<?= $this->extend('layout') ?>

<?= $this->section('content') ?>

<h1 class="text-2xl font-semibold mb-6">My Books</h1>

<?php if (empty($books)): ?>

    <div class="bg-white border border-slate-200 rounded-lg p-8 text-center">
        <p class="text-slate-500 mb-4">Your shelf is empty.</p>
        <a href="/books/new" class="text-slate-900 underline">Add your first book</a>
    </div>

<?php else: ?>

    <div class="space-y-4">
        <?php foreach ($books as $book): ?>
            <article class="bg-white border border-slate-200 rounded-lg p-5">
                <div class="flex items-start justify-between">
                    <div>
                        <h2 class="text-lg font-semibold">
                            <?= esc($book['title']) ?>
                            <?php if ($book['is_read']): ?>
                                <span class="text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded ml-2">
                                    Read
                                </span>
                            <?php endif; ?>
                        </h2>
                        <p class="text-sm text-slate-500">
                            by <?= esc($book['author']) ?>
                            &middot; <?= esc($book['year']) ?>
                            &middot; <?= esc(ucfirst($book['genre'])) ?>
                        </p>
                        <?php if (! empty($book['notes'])): ?>
                            <p class="mt-2 text-slate-700">
                                <?= esc($book['notes']) ?>
                            </p>
                        <?php endif; ?>
                    </div>

                    <div class="flex items-center gap-2 shrink-0">
                        <a href="/books/<?= $book['id'] ?>/edit"
                           class="text-sm text-slate-700 underline">
                            Edit
                        </a>
                        <form method="POST"
                              action="/books/<?= $book['id'] ?>/delete"
                              onsubmit="return confirm('Delete this book?');">
                            <?= csrf_field() ?>
                            <button type="submit"
                                    class="text-sm text-red-700 underline">
                                Delete
                            </button>
                        </form>
                    </div>
                </div>
            </article>
        <?php endforeach; ?>
    </div>

<?php endif; ?>

<?= $this->endSection() ?>
```

The two control patterns in this view are worth understanding because they will appear again. The conditional `<?php if (empty($books)): ?>` block handles the empty state, which is what tests will assert against in Part 2 with `assertSee('Your shelf is empty')`. The `foreach ($books as $book)` loop iterates over the rows returned by the model. Each iteration accesses fields with array syntax (`$book['title']`) because we set the model's return type to `array`.

The delete button is a small POST form rather than a link. Links use GET, and using GET for destructive actions is one of the oldest mistakes in web development, because anything that prefetches links (search engine crawlers, browser link previews, accessibility tools) can accidentally trigger destruction. Wrapping the delete in a POST form, with a JavaScript `confirm()` dialog as a safety net, is the safe pattern.

The `csrf_field()` helper outputs a hidden input containing CodeIgniter's CSRF token. The framework includes a CSRF filter by default, which checks for this token on every POST request and rejects requests without it. Without `csrf_field()` your forms would all return 403 errors. We will revisit this in Step 10 when something goes wrong, just so you remember the symptom.

### The Form Views

The new and edit forms share a structure but differ in their data source. We will write them as two separate files for clarity. Create `app/Views/books/new.php` with the following.

```php
<?= $this->extend('layout') ?>

<?= $this->section('content') ?>

<h1 class="text-2xl font-semibold mb-6">Add a Book</h1>

<?php if (session()->getFlashdata('errors')): ?>
    <div class="mb-6 bg-red-100 text-red-800 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside">
            <?php foreach (session()->getFlashdata('errors') as $error): ?>
                <li><?= esc($error) ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<form method="POST" action="/books" class="space-y-4 bg-white border border-slate-200 rounded-lg p-6">
    <?= csrf_field() ?>

    <div>
        <label for="title" class="block text-sm font-medium mb-1">Title</label>
        <input type="text" name="title" id="title"
               value="<?= esc(old('title')) ?>"
               class="w-full border border-slate-300 rounded-lg px-3 py-2">
    </div>

    <div>
        <label for="author" class="block text-sm font-medium mb-1">Author</label>
        <input type="text" name="author" id="author"
               value="<?= esc(old('author')) ?>"
               class="w-full border border-slate-300 rounded-lg px-3 py-2">
    </div>

    <div class="grid grid-cols-2 gap-4">
        <div>
            <label for="year" class="block text-sm font-medium mb-1">Year</label>
            <input type="number" name="year" id="year"
                   value="<?= esc(old('year')) ?>"
                   min="1000" max="9999"
                   class="w-full border border-slate-300 rounded-lg px-3 py-2">
        </div>

        <div>
            <label for="genre" class="block text-sm font-medium mb-1">Genre</label>
            <select name="genre" id="genre"
                    class="w-full border border-slate-300 rounded-lg px-3 py-2">
                <option value="">Select a genre...</option>
                <?php
                $genres = ['fiction', 'non-fiction', 'science', 'biography', 'history', 'technology', 'other'];
                foreach ($genres as $genre):
                ?>
                    <option value="<?= $genre ?>" <?= old('genre') === $genre ? 'selected' : '' ?>>
                        <?= ucfirst($genre) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </div>
    </div>

    <div>
        <label class="inline-flex items-center gap-2">
            <input type="checkbox" name="is_read" value="1"
                   <?= old('is_read') ? 'checked' : '' ?>
                   class="rounded">
            <span class="text-sm">I have read this book</span>
        </label>
    </div>

    <div>
        <label for="notes" class="block text-sm font-medium mb-1">Notes (optional)</label>
        <textarea name="notes" id="notes" rows="4"
                  class="w-full border border-slate-300 rounded-lg px-3 py-2"><?= esc(old('notes')) ?></textarea>
    </div>

    <div class="flex items-center gap-3">
        <button type="submit"
                class="bg-slate-900 text-white px-4 py-2 rounded-lg">
            Save Book
        </button>
        <a href="/books" class="text-slate-600 underline">Cancel</a>
    </div>
</form>

<?= $this->endSection() ?>
```

The `old()` helper is what makes the form sticky after a validation failure. When the controller calls `redirect()->back()->withInput()`, CodeIgniter saves the previous form values into flash data. The `old('title')` call retrieves whatever the user typed for `title` on their last attempt, or returns an empty string if there is no prior submission. This means a user who fails validation does not have to retype their whole entry; they fix only the fields the error block highlighted.

For the edit form, create `app/Views/books/edit.php` with similar contents but adjusted to preload existing data and post to a different URL. The structural changes are the form action URL, the page heading, and the use of the existing `$book` data as the fallback for `old()`.

```php
<?= $this->extend('layout') ?>

<?= $this->section('content') ?>

<h1 class="text-2xl font-semibold mb-6">Edit Book</h1>

<?php if (session()->getFlashdata('errors')): ?>
    <div class="mb-6 bg-red-100 text-red-800 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside">
            <?php foreach (session()->getFlashdata('errors') as $error): ?>
                <li><?= esc($error) ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<form method="POST" action="/books/<?= $book['id'] ?>" class="space-y-4 bg-white border border-slate-200 rounded-lg p-6">
    <?= csrf_field() ?>

    <div>
        <label for="title" class="block text-sm font-medium mb-1">Title</label>
        <input type="text" name="title" id="title"
               value="<?= esc(old('title', $book['title'])) ?>"
               class="w-full border border-slate-300 rounded-lg px-3 py-2">
    </div>

    <div>
        <label for="author" class="block text-sm font-medium mb-1">Author</label>
        <input type="text" name="author" id="author"
               value="<?= esc(old('author', $book['author'])) ?>"
               class="w-full border border-slate-300 rounded-lg px-3 py-2">
    </div>

    <div class="grid grid-cols-2 gap-4">
        <div>
            <label for="year" class="block text-sm font-medium mb-1">Year</label>
            <input type="number" name="year" id="year"
                   value="<?= esc(old('year', $book['year'])) ?>"
                   min="1000" max="9999"
                   class="w-full border border-slate-300 rounded-lg px-3 py-2">
        </div>

        <div>
            <label for="genre" class="block text-sm font-medium mb-1">Genre</label>
            <select name="genre" id="genre"
                    class="w-full border border-slate-300 rounded-lg px-3 py-2">
                <?php
                $genres = ['fiction', 'non-fiction', 'science', 'biography', 'history', 'technology', 'other'];
                $current = old('genre', $book['genre']);
                foreach ($genres as $genre):
                ?>
                    <option value="<?= $genre ?>" <?= $current === $genre ? 'selected' : '' ?>>
                        <?= ucfirst($genre) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </div>
    </div>

    <div>
        <label class="inline-flex items-center gap-2">
            <input type="checkbox" name="is_read" value="1"
                   <?= old('is_read', $book['is_read']) ? 'checked' : '' ?>
                   class="rounded">
            <span class="text-sm">I have read this book</span>
        </label>
    </div>

    <div>
        <label for="notes" class="block text-sm font-medium mb-1">Notes (optional)</label>
        <textarea name="notes" id="notes" rows="4"
                  class="w-full border border-slate-300 rounded-lg px-3 py-2"><?= esc(old('notes', $book['notes'])) ?></textarea>
    </div>

    <div class="flex items-center gap-3">
        <button type="submit"
                class="bg-slate-900 text-white px-4 py-2 rounded-lg">
            Update Book
        </button>
        <a href="/books" class="text-slate-600 underline">Cancel</a>
    </div>
</form>

<?= $this->endSection() ?>
```

The crucial difference between the new and edit forms is the second argument to `old()`. The call `old('title', $book['title'])` says "give me whatever the user typed on a failed submission, but if there is no failed submission, give me the existing book's title". This single change makes the same form serve both as a fresh-create form (when called from `new()`) and as an edit form (when called from `edit()`), with no flicker or empty state in between.

## Step 10: Try It in the Browser {#step-10-try-it-in-the-browser}

We have written every piece of the application. Now is the moment to see it work. Start the development server.

```bash
php spark serve
```

Open `http://localhost:8080` in your browser. The root URL redirects to `/books`, and the books index renders an empty-state message because no books exist yet.

Click the "Add Book" button in the top-right corner. The new-book form appears with empty fields. Fill in a real book; for example: title "Clean Code", author "Robert C. Martin", year 2008, genre "technology", check the "I have read this book" box, and add a short note. Click "Save Book".

The browser POSTs to `/books`, the controller validates the input, the model inserts the row, and the controller redirects to `/books`. The index page now shows your book with an emerald-green flash message at the top reading "Book added to your shelf." Refresh the page; the flash message disappears (because flash data is single-request) but the book remains.

Try the failure path. Click "Add Book" again, leave every field blank, and click "Save Book". The controller fails validation, redirects back to the form with input preserved (which is empty in this case), and the form view renders a red error banner listing every validation message. Fix the title, leave the year blank, click "Save Book"; this time only the year error appears, and the title is preserved. This is the validation flow the test suite will assert in Part 2.

Try editing. Click "Edit" on the book you just added. The edit form renders with all fields preloaded. Change the year and click "Update Book". The redirect lands on the index, the flash message reads "Book updated.", and the year shows the new value.

Finally, try deleting. Click "Delete" on a book. The browser shows a JavaScript `confirm()` dialog. Click OK. The book disappears from the list and a flash message reads "Book removed from your shelf." Click Cancel on a different book; nothing happens, which is the correct behavior because the form was never submitted.

If you encountered a 403 Forbidden error at any point, the most likely cause is a missing `csrf_field()` call in a form, or the CSRF cookie not being sent. Double-check that every `<form>` element in your views contains `<?= csrf_field() ?>` immediately after the opening tag. CodeIgniter's CSRF filter is strict by default, which is the right behavior for production but can surprise you while developing.

## Reflection: Design Decisions That Pay Off in Part 2 {#reflection-design-decisions-that-pay-off-in-part-2}

Before we close Part 1, it is worth pausing to recognize the design choices we made that will turn into testing wins in Part 2. Each of these choices was made deliberately, and naming them now will help you appreciate Part 2 when we get there.

The controller is thin and predictable. Every method does at most three things: load data, validate input, return a response. There are no side jobs hidden inside controller actions, no email sending, no external API calls, no caching layers. This means tests can assert the controller's behavior by inspecting the response and the database, without having to mock anything.

Validation lives in one place per endpoint, and the rules are extracted into a private method. When the test for the "missing title" case runs, it exercises exactly the same `validationRules()` array that production traffic exercises. There is no test-only validation, no subtly different rule set, and no possibility of test-production drift.

Every write endpoint follows the POST-redirect-GET pattern. Successful writes return a 302 with a known location header. Failed writes return a 302 back to the form with flash errors. Tests can match these patterns with one line of assertion code each, and the assertions read exactly like the user behavior they describe.

Flash messages have predictable keys: `success` for positive notifications, `errors` for validation failures. A test that wants to assert "the user saw a success message" reads the session's `success` key directly. There is no fishing through HTML or guessing about copy.

The model returns associative arrays. Test assertions like `expect($book['title'])->toBe('Clean Code')` are short and idiomatic. If we had returned objects, the same assertion would be `expect($book->title)->toBe('Clean Code')`, which is also fine, but arrays interoperate better with the rest of CodeIgniter's testing helpers.

The application uses no external services. Every test in Part 2 will be self-contained: no email queue to mock, no API to stub, no file system to fake. The entire test suite will run against an in-memory SQLite database in well under one second.

## Conclusion {#conclusion}

You have built a working CRUD application in CodeIgniter 4. Books can be added, listed, edited, and deleted; validation rejects bad input; redirects keep the navigation clean; and flash messages give users visible confirmation of every action. More importantly, every design choice was made with testability in mind, even though we have not yet written a single test.

Here are the key takeaways from Part 1 to carry into Part 2.

- **The CRUD pattern is the foundation of most web applications.** Mastering it in CodeIgniter 4 lets you build the majority of small business applications without reaching for any advanced framework features.
- **Migrations describe the database, not the code.** They live in `app/Database/Migrations/`, run with `php spark migrate`, and form a sequential record of every schema change. Treat them as version control for your data, the same way Git is version control for your code.
- **Models in CodeIgniter 4 are repository-style, not active-record-style.** A single `BookModel` instance handles all queries against the `books` table; rows come back as arrays or objects depending on configuration. This is different from Eloquent but takes about ten minutes to internalize.
- **Validation in the controller gives explicit, traceable rules.** Each endpoint shows exactly which fields are checked. The trade-off is duplication if many endpoints share the same rules; we addressed this by extracting `validationRules()` into a private helper.
- **POST-redirect-GET is mandatory for forms.** Successful writes redirect (302), failed writes redirect with input and errors. The pattern prevents double submission, simplifies user experience, and gives tests a clean assertion target.
- **Tailwind via CDN is fine for tutorials.** Production applications will likely want a build pipeline for performance, but the CDN keeps tutorials focused on the framework rather than on asset compilation.
- **Testability is a design property decided up front.** Every choice in Part 1, from the thin controller to the flash key naming, was selected so Part 2 would be short and clear. Code written without testing in mind tends to fight back when you try to test it later.

In Part 2 we will install Pest 4, configure it to bridge into CodeIgniter's testing infrastructure, switch the test database to in-memory SQLite for speed, and write a complete test suite covering every endpoint we built today. The suite will run in under one second, will be deterministic on every machine, and will give you the confidence to refactor or extend BookShelf without fear of breaking something in production.