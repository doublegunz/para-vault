# Case-Sensitive Token Lookups in Laravel 13 with whereBinary()

You store an API token in a MySQL or MariaDB column, a client sends it back on the next request, and you look it up with `ApiToken::where('token', $submitted)->first()`. It works in every test you write, because every test pastes the token back exactly as it was generated. What none of those tests cover is the request that sends `AB3XK9PQ` when the stored token is `aB3xK9pQ`, and the default collation on those two databases says those strings are equal.

That single fact turns a token check into something weaker than it looks. A token of eight mixed-case characters no longer has the entropy you counted on, because case stops being part of the comparison. Worse, in a table where two rows hold tokens that differ only in case, the query returns whichever row the database reaches first, so one user's token can resolve to another user's record. Nothing errors, nothing logs, and the wrong account is authenticated.

Laravel 13.27.0 shipped `whereBinary()` to close that gap without dropping into raw SQL. The [release roundup for 13.27.0](https://qadrlabs.com/post/whats-new-in-laravel-13270-refreshforupdate-mariadb-vector-search-and-more) covered the method briefly among five other changes; this article turns it into a small project you can actually run. You will build a two-row token table where the collision is real, watch a plain `where()` match the wrong owner in the browser, then fix the lookup and lock the behavior down with Pest.

## Overview {#overview}

This is a short case study rather than a full application. The whole demo is one table, one model, one route, and one Blade page that runs the same lookup twice, once with `where()` and once with `whereBinary()`, so the difference is visible side by side. The Pest suite that follows turns each observation into an assertion, including one test that deliberately documents the broken behavior so a future change to the query cannot pass silently.

### What You'll Build

- An `api_tokens` table holding two tokens that differ only in letter case, owned by two different people.
- A `/verify` page that looks up a submitted token twice and shows both results next to each other.
- A Pest suite of nine tests covering the collision, the fix, the compiled SQL, and the browser output.

### What You'll Learn

- Why `where()` on a MySQL or MariaDB string column is case-insensitive by default, and what that costs you on token columns.
- How `whereBinary()`, `orWhereBinary()`, `whereNotBinary()`, and `orWhereNotBinary()` compile into SQL.
- How to run a Pest suite against MariaDB instead of the default SQLite, which is mandatory for this feature.
- When changing the column collation is the better fix than changing the query.

### What You'll Need

- PHP 8.3 or newer, the minimum for Laravel 13.
- Laravel 13.27.0 or newer, since `whereBinary()` does not exist in earlier releases.
- MySQL or MariaDB. This feature is not portable, and the demo cannot run on SQLite.
- Basic familiarity with Eloquent, migrations, and Pest.

## Step 1: Create the Project and Point It at MariaDB {#step-1-create-the-project-and-point-it-at-mariadb}

Most Laravel tutorials scaffold with SQLite because it needs no setup. This one cannot. `whereBinary()` is implemented only in the MySQL grammar, and every other driver throws when you call it, so the demo needs a real MySQL or MariaDB database from the first command.

```bash
laravel new wherebinary-demo --no-interaction --database=mariadb --pest --no-boost
cd wherebinary-demo
```

The `--database=mariadb` flag writes the MariaDB connection into `.env` for you, and `--pest` installs Pest as the test runner. Pass `--database=mysql` instead if that is what you run locally; everything in this article behaves the same on both.

Create the database next. The collation matters here, so set it explicitly rather than relying on the server default.

```sql
CREATE DATABASE db_wherebinary_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

`utf8mb4_unicode_ci` is the case-insensitive collation that creates the whole problem this article is about. It is also the collation most Laravel projects end up with, since it is what the framework's default `charset` and `collation` config values ask for, which is exactly why the bug is so easy to ship.

Now point the application at that database by editing `.env`.

```
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_wherebinary_demo
DB_USERNAME=your_database_user
DB_PASSWORD=your_database_password
```

Confirm the connection works before writing any code. An empty migration run is the quickest check.

```bash
php artisan migrate
```

```
   INFO  Preparing database.

  Creating migration table .. 12.14ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table .. 49.70ms DONE
  0001_01_01_000001_create_cache_table .. 44.58ms DONE
  0001_01_01_000002_create_jobs_table .. 49.24ms DONE
```

## Step 2: Build the api_tokens Table and Model {#step-2-build-the-api-tokens-table-and-model}

The table is deliberately plain. An owner, a token, and nothing clever, because the point of the case study is that ordinary columns behave this way. Generate the migration and the model together.

```bash
php artisan make:migration create_api_tokens_table
php artisan make:model ApiToken
```

Open the generated migration in `database/migrations` and fill in the schema.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('api_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('owner');
            // A plain string column, so it inherits the connection's default
            // collation. On MySQL and MariaDB that is a case-insensitive one.
            $table->string('token', 64);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_tokens');
    }
};
```

Two things are missing on purpose. There is no `unique()` on the token column, because under a case-insensitive collation a unique index would reject the second of our two tokens as a duplicate, and there is no plain index either, for a reason covered in the reference section at the end. Both omissions are discussed later with the output that justifies them.

Next, open `app/Models/ApiToken.php` and declare the mass assignable columns.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['owner', 'token'])]
class ApiToken extends Model
{
    //
}
```

The `#[Fillable]` attribute is the Laravel 13 way of expressing what `protected $fillable` used to. It reads as part of the class signature rather than as a property buried in the body, and it behaves identically at runtime.

Run the migration to create the table.

```bash
php artisan migrate
```

## Step 3: Seed Two Tokens That Differ Only in Case {#step-3-seed-two-tokens-that-differ-only-in-case}

The collision needs two rows to be interesting. One token belongs to Alice, the other to Bob, and the only difference between them is which letters are capitalized. In a real system these would be two independently generated tokens that happened to collide under the collation; here they are written by hand so the demo is reproducible.

Open `database/seeders/DatabaseSeeder.php` and replace its contents.

```php
<?php

namespace Database\Seeders;

use App\Models\ApiToken;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Two tokens that differ only in letter case. Under the default
        // case-insensitive collation the database treats them as equal.
        ApiToken::create([
            'owner' => 'Alice',
            'token' => 'aB3xK9pQ',
        ]);

        ApiToken::create([
            'owner' => 'Bob',
            'token' => 'Ab3Xk9Pq',
        ]);
    }
}
```

Run the seeder and check what actually landed in the table.

```bash
php artisan migrate:fresh --seed
```

```
+----+-------+----------+
| id | owner | token    |
+----+-------+----------+
|  1 | Alice | aB3xK9pQ |
|  2 | Bob   | Ab3Xk9Pq |
+----+-------+----------+
```

Both rows are stored exactly as written, which confirms the storage layer keeps the bytes intact. The collation only affects comparison, not storage, and that distinction is the key to understanding everything that follows.

## Step 4: Reproduce the Collision in Tinker {#step-4-reproduce-the-collision-in-tinker}

Before fixing anything, it is worth seeing the problem with your own data. Tinker is the fastest way to run a query against the seeded table without building a UI first.

```bash
php artisan tinker
```

Inside the session, submit a token that belongs to nobody. `AB3XK9PQ` is the fully uppercased form, so byte for byte it matches neither stored row.

```php
use App\Models\ApiToken;

$submitted = "AB3XK9PQ";

echo "where()       -> ", ApiToken::where("token", $submitted)->count(), " row(s)", PHP_EOL;
echo "whereBinary() -> ", ApiToken::whereBinary("token", $submitted)->count(), " row(s)", PHP_EOL;
```

```
where()       -> 2 row(s)
whereBinary() -> 0 row(s)
```

A token that was never issued to anyone matches both rows in the table. If that lookup sat behind an authentication middleware, the request would be authenticated as whichever row came back first. `whereBinary()` compares the raw bytes and correctly reports that nothing matches.

The second scenario is more subtle and more dangerous, because it involves a token that is genuinely valid. Bob's token is `Ab3Xk9Pq`, and it is a real credential that a real client would send.

```php
$bobToken = "Ab3Xk9Pq";

echo "where()       -> ", ApiToken::where("token", $bobToken)->first()->owner, PHP_EOL;
echo "whereBinary() -> ", ApiToken::whereBinary("token", $bobToken)->first()->owner, PHP_EOL;
```

```
where()       -> Alice
whereBinary() -> Bob
```

This is the failure mode that never shows up as an error. Bob sends his own valid token, and the plain lookup hands back Alice's row because her token sorts as equal and her row has the lower id. The request succeeds, the response looks normal, and Bob is now operating as Alice. Exit Tinker with `exit` once you have seen both outputs.

## Step 5: Fix the Lookup with whereBinary() {#step-5-fix-the-lookup-with-wherebinary}

The fix is a one-word change at the call site, which is the point of the method existing at all. Before 13.27.0 the equivalent required raw SQL, which meant giving up identifier wrapping and writing a MySQL-specific string into the middle of a portable query.

This is the lookup as it is usually written, and the one that produced the wrong owner above.

```php
// Old: the database compares with the column's collation,
// so letter case is ignored.
$token = ApiToken::query()
    ->where('token', $submitted)
    ->first();
```

Replacing `where` with `whereBinary` is the whole change.

```php
// New: the comparison happens byte by byte, so a token that
// differs in case no longer matches.
$token = ApiToken::query()
    ->whereBinary('token', $submitted)
    ->first();
```

Nothing else about the query changes. The column name still goes through the grammar's identifier wrapping, the value is still sent as a bound parameter rather than interpolated into the SQL string, and the clause still composes with everything else the builder offers. You can see the compiled statement without executing it.

```php
echo ApiToken::whereBinary("token", "aB3xK9pQ")->toSql(), PHP_EOL;
```

```
select * from `api_tokens` where `token` = binary ?
```

The `binary` keyword sits between the operator and the placeholder, which tells MySQL and MariaDB to treat the compared value as a byte string rather than as text in the column's collation. The placeholder is still a placeholder, so parameter binding and its protection against injection are untouched.

## Step 6: Expose It in the Browser {#step-6-expose-it-in-the-browser}

Running both queries side by side in a page makes the difference concrete in a way that a Tinker session does not, and it gives you something to click through at the end. Create a controller that performs both lookups on the same submitted value.

```bash
php artisan make:controller TokenVerificationController
```

Open `app/Http/Controllers/TokenVerificationController.php` and write the two lookups.

```php
<?php

namespace App\Http\Controllers;

use App\Models\ApiToken;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TokenVerificationController extends Controller
{
    public function __invoke(Request $request): View
    {
        $submitted = (string) $request->query('token', '');

        // The old lookup: a plain where() comparison that the database resolves
        // with the column's collation, which is case-insensitive by default.
        $looseMatch = $submitted === ''
            ? null
            : ApiToken::query()->where('token', $submitted)->first();

        // The new lookup: whereBinary() compares the raw bytes, so a token that
        // differs only in letter case no longer matches.
        $binaryMatch = $submitted === ''
            ? null
            : ApiToken::query()->whereBinary('token', $submitted)->first();

        return view('verify', [
            'submitted' => $submitted,
            'looseMatch' => $looseMatch,
            'binaryMatch' => $binaryMatch,
        ]);
    }
}
```

Both lookups run against the same submitted string, which is what makes the page useful: any difference between the two panels comes purely from the comparison, not from the input. The empty check keeps the page usable on a first visit when no token has been submitted yet.

Register the route in `routes/web.php`.

```php
<?php

use App\Http\Controllers\TokenVerificationController;
use Illuminate\Support\Facades\Route;

Route::get('/verify', TokenVerificationController::class)->name('verify');
```

Now create `resources/views/verify.blade.php` with the two result panels.

```blade
<title>Token Verification</title>
<script src="https://cdn.tailwindcss.com"></script>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-2">API Token Verification</h1>
        <p class="text-gray-600 mb-6">
            The same token is looked up twice: once with a plain <code>where()</code>
            and once with <code>whereBinary()</code>.
        </p>

        <form method="GET" action="{{ route('verify') }}" class="flex gap-2 mb-8">
            <input type="text" name="token" value="{{ $submitted }}" placeholder="Paste a token"
                class="flex-1 border border-gray-300 rounded px-3 py-2 font-mono">
            <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 transition">
                Verify
            </button>
        </form>

        @if ($submitted !== '')
            <p class="mb-4 text-sm text-gray-600">
                Submitted token: <span class="font-mono font-semibold">{{ $submitted }}</span>
            </p>

            <div class="grid md:grid-cols-2 gap-4">
                <div class="border border-gray-200 rounded p-4">
                    <h2 class="font-semibold mb-2">where('token', ...)</h2>
                    @if ($looseMatch)
                        <p class="text-red-600 font-semibold">Matched</p>
                        <p class="text-sm mt-1">Owner: {{ $looseMatch->owner }}</p>
                        <p class="text-sm font-mono">Stored: {{ $looseMatch->token }}</p>
                    @else
                        <p class="text-gray-500 font-semibold">No match</p>
                    @endif
                </div>

                <div class="border border-gray-200 rounded p-4">
                    <h2 class="font-semibold mb-2">whereBinary('token', ...)</h2>
                    @if ($binaryMatch)
                        <p class="text-green-600 font-semibold">Matched</p>
                        <p class="text-sm mt-1">Owner: {{ $binaryMatch->owner }}</p>
                        <p class="text-sm font-mono">Stored: {{ $binaryMatch->token }}</p>
                    @else
                        <p class="text-gray-500 font-semibold">No match</p>
                    @endif
                </div>
            </div>
        @endif

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial whereBinary at qadrlabs.com</a>
        </div>
    </div>
</body>
```

Each panel prints the owner and the stored token of whatever row it found, which is the detail that makes the demonstration land. Seeing a submitted value of `Ab3Xk9Pq` next to a stored value of `aB3xK9pQ` in the same panel is more convincing than any assertion about collations.

Start the development server and leave it running for the next two steps.

```bash
php artisan serve
```

## Step 7: Cover It with Pest {#step-7-cover-it-with-pest}

A behavior this quiet needs tests, but there is a configuration problem to solve first. Laravel 13 ships `phpunit.xml` with SQLite pinned as the test database, and SQLite has no implementation of `whereBinary()`. Running the suite as generated would fail on every test that touches the new method, for a reason that has nothing to do with your code.

Open `phpunit.xml` and comment out the two database lines.

```xml
        <!-- whereBinary() is a MySQL and MariaDB feature, so the test suite
             must run on the same driver as the application. -->
        <!-- <env name="DB_CONNECTION" value="sqlite"/> -->
        <!-- <env name="DB_DATABASE" value=":memory:"/> -->
```

With those lines gone, the suite falls back to the connection in `.env`, which is the MariaDB database from Step 1. That is slower than an in-memory SQLite database, and it is the price of testing a driver-specific feature honestly. The alternative, testing on SQLite and deploying on MySQL, is exactly how a query that throws in production ends up shipping green.

Since tests now run against a real database, they need `RefreshDatabase` to reset state between them. Open `tests/Pest.php` and uncomment that line.

```php
pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');
```

Now create `tests/Feature/TokenVerificationTest.php` with the full suite.

```php
<?php

use App\Models\ApiToken;

beforeEach(function () {
    // Two tokens that are byte-different but collation-equal.
    ApiToken::create(['owner' => 'Alice', 'token' => 'aB3xK9pQ']);
    ApiToken::create(['owner' => 'Bob', 'token' => 'Ab3Xk9Pq']);
});

it('matches a token of the wrong case with a plain where clause', function () {
    $match = ApiToken::query()->where('token', 'AB3XK9PQ')->first();

    expect($match)->not->toBeNull();
});

it('rejects a token of the wrong case with whereBinary', function () {
    $match = ApiToken::query()->whereBinary('token', 'AB3XK9PQ')->first();

    expect($match)->toBeNull();
});

it('matches the exact token with whereBinary', function () {
    $match = ApiToken::query()->whereBinary('token', 'aB3xK9pQ')->first();

    expect($match)->not->toBeNull()
        ->and($match->owner)->toBe('Alice');
});

it('resolves each case variant to its own owner', function () {
    $alice = ApiToken::query()->whereBinary('token', 'aB3xK9pQ')->first();
    $bob = ApiToken::query()->whereBinary('token', 'Ab3Xk9Pq')->first();

    expect($alice->owner)->toBe('Alice')
        ->and($bob->owner)->toBe('Bob');
});

it('excludes only the exact match with whereNotBinary', function () {
    $owners = ApiToken::query()
        ->whereNotBinary('token', 'aB3xK9pQ')
        ->pluck('owner')
        ->all();

    expect($owners)->toBe(['Bob']);
});

it('combines binary clauses with orWhereBinary', function () {
    $owners = ApiToken::query()
        ->whereBinary('token', 'aB3xK9pQ')
        ->orWhereBinary('token', 'Ab3Xk9Pq')
        ->orderBy('id')
        ->pluck('owner')
        ->all();

    expect($owners)->toBe(['Alice', 'Bob']);
});

it('compiles to a binary comparison operator', function () {
    $sql = ApiToken::query()->whereBinary('token', 'aB3xK9pQ')->toSql();

    expect($sql)->toContain('`token` = binary ?');
});

it('reports a loose match and no binary match for a wrong-case token', function () {
    $this->get('/verify?token=AB3XK9PQ')
        ->assertOk()
        ->assertSee('where(\'token\', ...)', false)
        ->assertSee('Matched')
        ->assertSee('No match');
});

it('shows the plain lookup returning the wrong owner in the browser', function () {
    // Bob's token. The plain where() panel reports Alice because her token is
    // collation-equal, while the whereBinary() panel reports Bob.
    $this->get('/verify?token=Ab3Xk9Pq')
        ->assertOk()
        ->assertSee('Alice')
        ->assertSee('Bob')
        ->assertDontSee('No match');
});
```

The first test deserves a note, because it asserts that the broken behavior still happens. That is intentional. It pins the fact that a plain `where()` matches a wrong-case token on this driver, so if someone later changes the column collation, that test fails and forces a conversation instead of quietly changing the meaning of every other test in the file.

Run the suite.

```bash
php artisan test
```

```
   PASS  Tests\Feature\TokenVerificationTest
  ✓ it matches a token of the wrong case with a plain where clause                           0.42s  
  ✓ it rejects a token of the wrong case with whereBinary                                    0.02s  
  ✓ it matches the exact token with whereBinary                                              0.02s  
  ✓ it resolves each case variant to its own owner                                           0.02s  
  ✓ it excludes only the exact match with whereNotBinary                                     0.02s  
  ✓ it combines binary clauses with orWhereBinary                                            0.02s  
  ✓ it compiles to a binary comparison operator                                              0.02s  
  ✓ it reports a loose match and no binary match for a wrong-case token                      0.04s  
  ✓ it shows the plain lookup returning the wrong owner in the browser                       0.02s  

  Tests:    9 passed (17 assertions)
  Duration: 0.67s
```

Note that `RefreshDatabase` rebuilds the schema in your development database on the first run, so the two seeded rows from Step 3 are gone once the suite finishes. Run `php artisan migrate:fresh --seed` again before returning to the browser.

## Step 8: Try It Out {#step-8-try-it-out}

With the seeded data restored and `php artisan serve` running, three URLs cover the whole story. Each one submits a different token and shows what the two lookups make of it.

### Scenario 1: The Exact Token

Visit `http://127.0.0.1:8000/verify?token=aB3xK9pQ`, which is Alice's real token submitted exactly as stored.

```
Submitted token: aB3xK9pQ
where('token', ...)
Matched
Owner: Alice
Stored: aB3xK9pQ
whereBinary('token', ...)
Matched
Owner: Alice
Stored: aB3xK9pQ
```

Both panels agree, which is the case that every test written by hand tends to cover. This is why the bug survives so long in real projects.

### Scenario 2: A Valid Token Resolving to the Wrong Owner

Visit `http://127.0.0.1:8000/verify?token=Ab3Xk9Pq`, which is Bob's real token.

```
Submitted token: Ab3Xk9Pq
where('token', ...)
Matched
Owner: Alice
Stored: aB3xK9pQ
whereBinary('token', ...)
Matched
Owner: Bob
Stored: Ab3Xk9Pq
```

Look at the stored value in the left panel. Bob sent his own credential and the plain lookup returned a row belonging to Alice, holding a different string. Both panels report a match, so an application that only checked whether a row was found would see nothing wrong at all.

### Scenario 3: A Token Nobody Owns

Visit `http://127.0.0.1:8000/verify?token=AB3XK9PQ`, an uppercased variant that was never issued.

```
Submitted token: AB3XK9PQ
where('token', ...)
Matched
Owner: Alice
Stored: aB3xK9pQ
whereBinary('token', ...)
No match
```

An unissued token authenticates as Alice under the plain lookup and is correctly rejected by the binary one. This is the scenario that matters most from a security point of view, because it means an attacker who learns a token in any letter case learns every case variant of it at once.

## How whereBinary Compiles {#how-wherebinary-compiles}

The method is thinner than it looks, which is worth understanding before deciding how much to lean on it. `Illuminate\Database\Query\Builder::whereBinary()` does not build SQL at all. It appends a where clause of type `Binary` to the query and binds the value, exactly like any other where clause, and leaves the SQL to the grammar.

The MySQL grammar is where the feature actually lives. It takes that clause, sets the operator to `= binary` or `!= binary` depending on the `not` flag, and then hands the clause to the same `whereBasic()` compiler that ordinary comparisons use. That is why the output looks so unremarkable.

```
select * from `api_tokens` where `token` = binary ?
```

Two properties follow from that design. The column is wrapped by the grammar, so identifiers with reserved words or unusual characters are quoted the way they always are, and the value stays a bound parameter rather than being interpolated into the statement. Both are things you lose the moment you write `whereRaw('token = BINARY ?', [$token])` by hand, which was the only option before 13.27.0.

The `binary` keyword itself is a MySQL and MariaDB operator that reinterprets the value on its right as a byte string. Comparing a `utf8mb4_unicode_ci` column against a byte string forces the comparison itself to be byte-oriented, which is how case sensitivity appears without any change to the stored data or the column definition.

## The Four Binary Methods {#the-four-binary-methods}

`whereBinary()` ships with three siblings, covering the usual combinations of negation and boolean joining. All four are on the base query builder, so they work on `DB::table()` queries and Eloquent queries alike.

```php
use App\Models\ApiToken;

echo ApiToken::whereBinary("token", "aB3xK9pQ")->toSql(), PHP_EOL;
echo ApiToken::whereNotBinary("token", "aB3xK9pQ")->toSql(), PHP_EOL;
echo ApiToken::where("owner", "Alice")->orWhereBinary("token", "Ab3Xk9Pq")->toSql(), PHP_EOL;
echo ApiToken::where("owner", "Alice")->orWhereNotBinary("token", "Ab3Xk9Pq")->toSql(), PHP_EOL;
```

```
select * from `api_tokens` where `token` = binary ?
select * from `api_tokens` where `token` != binary ?
select * from `api_tokens` where `owner` = ? or `token` = binary ?
select * from `api_tokens` where `owner` = ? or `token` != binary ?
```

The last two are the reason these exist as first-class methods rather than as a documentation note about `whereRaw()`. Mixing a raw fragment into an `or` chain means writing the boolean joining by hand, and getting the precedence right when the clause is nested inside a closure is a well-known way to produce a query that quietly matches more rows than intended.

## Why It Throws on SQLite and PostgreSQL {#why-it-throws-on-sqlite-and-postgresql}

The base grammar implements `whereBinary()` by refusing to compile it, and only the MySQL grammar overrides that refusal. MariaDB inherits the working version through the MySQL grammar, so it is supported. PostgreSQL, SQLite, and SQL Server all reach the base implementation and throw.

Here is what that looks like from the same demo code run against an in-memory SQLite connection.

```
RuntimeException: This database engine does not support binary comparison operations.
```

Notice that this is a runtime exception, not a compile-time error or a deprecation notice. It fires only when the query is actually executed, which means a `whereBinary()` call sitting on a rarely exercised code path can pass code review, pass a test suite running on SQLite, and then throw the first time a real request reaches it in production.

That is the practical reason Step 7 spent time on `phpunit.xml`. The usual Laravel convention of testing on SQLite while deploying on MySQL is comfortable right up until you use a driver-specific feature, and this is one. If you adopt `whereBinary()` anywhere in an application, the test suite has to run on MySQL or MariaDB too.

For PostgreSQL the situation is different but not a problem. PostgreSQL compares strings case-sensitively by default, so the behavior `whereBinary()` provides on MySQL is what a plain `where()` already does there. Code that needs to run on both drivers is better served by fixing the column collation, which the next section covers.

## Indexes, Collations, and a MariaDB Gotcha {#indexes-collations-and-a-mariadb-gotcha}

The migration in Step 2 left the token column without any index, which is unusual for a column that every request looks up. That omission was not an oversight, and the reason is worth seeing rather than taking on trust.

An index built on a `utf8mb4_unicode_ci` column stores its entries in that collation's order, so it cannot answer a byte-exact question directly. On the MariaDB 11.8 server used while writing this article, adding a plain index to the token column changed the result of a query that combines two binary comparisons. Run this in Tinker against the seeded table to see it.

```php
use App\Models\ApiToken;
use Illuminate\Support\Facades\Schema;

$binaryOr = fn () => ApiToken::whereBinary("token", "aB3xK9pQ")
    ->orWhereBinary("token", "Ab3Xk9Pq")
    ->orderBy("id")
    ->pluck("owner")
    ->join(", ");

echo "without an index on token: ", $binaryOr(), PHP_EOL;

Schema::table("api_tokens", fn ($table) => $table->index("token"));

echo "with an index on token:    ", $binaryOr(), PHP_EOL;

Schema::table("api_tokens", fn ($table) => $table->dropIndex(["token"]));
```

```
without an index on token: Alice, Bob
with an index on token:    Alice
```

The same query returns one row instead of two purely because an index exists. Single-clause lookups such as `whereBinary('token', $submitted)->first()`, which is what the demo application actually runs, returned correct results with the index in place; the discrepancy appeared when two collation-equal values were combined with `or` and an ordering. The safe reading is that binary comparisons and case-insensitive indexes are a combination to avoid rather than to reason about, so this article keeps the column unindexed and small.

A unique index is worse than useless here for a related reason. Under a case-insensitive collation the database considers Alice's and Bob's tokens duplicates, so the second insert fails.

```
Illuminate\Database\UniqueConstraintViolationException
SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry 'Ab3Xk9Pq' for key 'api_tokens_token_unique'
```

Read that error message carefully. MariaDB reports `Ab3Xk9Pq` as a duplicate of a row that stores `aB3xK9pQ`, which is the same collation rule seen from the write side rather than the read side. A unique constraint on a case-insensitive column silently enforces case-insensitive uniqueness, which is not what "unique token" means to anyone reading the schema.

## whereBinary or a Binary Column Collation {#wherebinary-or-a-binary-column-collation}

All of this points at a question the query builder cannot answer for you: is the case-insensitivity a property of one lookup, or a property of the column? For a token column the honest answer is the column. A token is an opaque byte string, and nothing about it should ever be compared case-insensitively, including its index and its unique constraint.

MySQL and MariaDB express that with a binary collation on the column itself.

```php
Schema::table('api_tokens', function (Blueprint $table) {
    $table->string('token', 64)->collation('utf8mb4_bin')->change();
});
```

With the column declared that way, an ordinary `where()` is already byte-exact, and the behavior travels with the schema instead of depending on every call site remembering to use a special method.

```
utf8mb4_bin, where("token", "AB3XK9PQ") -> 0 row(s)
utf8mb4_bin, where("token", "Ab3Xk9Pq") -> Bob
```

The uppercased variant now matches nothing and Bob's token resolves to Bob, from a plain `where()` call. Indexes and unique constraints on the column become byte-exact too, which removes both problems from the previous section at once.

So where does `whereBinary()` fit? It is the right tool when you cannot change the schema: a legacy table shared with another application, a column you do not own, a migration you cannot run during business hours, or a single query that needs byte-exact semantics on a column that is legitimately case-insensitive everywhere else, such as matching a display name exactly as typed. It is also the fastest way to stop the bleeding while a collation migration is planned, which is not a small thing when the bug in question is an authentication bypass.

## Conclusion {#conclusion}

A collation is easy to treat as a formatting detail, and this case study is a reminder that it is really a comparison rule that reaches into authentication, uniqueness, and indexing all at once. Laravel 13.27.0 gives you a clean way to opt out of it per query, and knowing when to reach for that instead of fixing the column is most of the value.

- **Default MySQL and MariaDB collations ignore letter case.** On a `utf8mb4_unicode_ci` column, a plain `where()` treats `aB3xK9pQ` and `AB3XK9PQ` as the same value, which quietly removes case from the entropy of every token you store.
- **The failure is silent, not loud.** In the demo, Bob's valid token returns Alice's row and the response looks completely normal, so nothing in your logs or error tracker will ever point at the query.
- **`whereBinary()` is a one-word fix at the call site.** It compiles to `= binary ?` through the MySQL grammar, keeping identifier wrapping and parameter binding intact, which raw SQL does not.
- **Four methods ship together.** `whereBinary()`, `orWhereBinary()`, `whereNotBinary()`, and `orWhereNotBinary()` cover negation and `or` joining, so a byte-exact clause composes like any other clause.
- **The method throws on every driver except MySQL and MariaDB.** It is a runtime exception, so a test suite running on SQLite will pass while production fails; move the suite onto the real driver before using it.
- **Case-insensitive indexes and binary comparisons do not mix.** A plain index on the token column changed the result of a combined binary query on MariaDB 11.8, and a unique index rejects two tokens that differ only in case as duplicates.
- **Prefer a binary collation when you own the schema.** Declaring the column as `utf8mb4_bin` makes plain lookups, indexes, and unique constraints all byte-exact, and leaves `whereBinary()` for the cases where changing the column is not an option.
