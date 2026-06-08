---
title: "Crosstab Query in Laravel 13: Pivot Reports with the Query Builder"
slug: "crosstab-query-in-laravel-13-pivot-reports-with-the-query-builder"
category: "Laravel"
date: "2026-04-24"
status: "published"
---

If you have already worked through [crosstab queries in plain MySQL and MariaDB](https://qadrlabs.com/post/crosstab-query-in-mysql-and-mariadb-pivot-rows-into-columns-without-a-pivot-function), you know how powerful conditional aggregation can be for turning rows into columns. The problem that article leaves open is a practical one: real applications do not run raw SQL in a MySQL client. They run inside a web framework, with controllers, models, and routing handling the delivery of results to a browser. Taking the SQL technique and wiring it into a Laravel 13 application correctly is not obvious, and there are a few places where the direct translation breaks down in ways that require a different approach.

The most significant of these is the dynamic pivot. In the previous article, the dynamic query relied on MySQL's `PREPARE` and `EXECUTE` statements to run a dynamically assembled SQL string entirely inside the database. PDO, the database layer that Laravel uses under the hood, does not support that multi-statement flow through its standard interface. Trying to port the MySQL session-variable approach directly produces confusing errors. The solution is to move the SQL assembly logic from MySQL into PHP, where Laravel's Query Builder handles data retrieval and plain PHP string operations handle the column expression building. The result is cleaner, more maintainable, and easier to reason about than the MySQL-native version.

This article walks through a complete Laravel 13 implementation: database setup with migrations and seeders, two focused controllers (one for static pivots, one for dynamic), a combined report controller, and a Blade view that renders both tables side by side so you can see the difference between the two approaches in a single browser tab.

## Overview {#overview}

This tutorial builds a Laravel 13 application that replicates the crosstab queries from the previous article. The dataset is identical: product sales across multiple months, with deliberate gaps to show how each approach handles missing data. The focus is on how to correctly implement both the static and dynamic pivot patterns inside Laravel's architecture, and on understanding why the dynamic approach requires a different mechanism than what was used in plain SQL.

### What You'll Build

- A fresh Laravel 13 project connected to the `pivot_demo` database from the previous article.
- A `StaticPivotController` with a reusable `getData()` method that uses `DB::table()->selectRaw()` to run hardcoded `CASE WHEN` column expressions.
- A `DynamicPivotController` with a `getData()` method that discovers month values at runtime via the Query Builder and assembles the pivot SQL in PHP before executing it with `DB::select()`.
- A `SalesReportController` that calls both `getData()` methods and passes the combined results to a single Blade view.
- A standalone Blade view with Tailwind CSS that renders both pivot tables side by side, with dynamic column headers derived from the data itself.

### What You'll Learn

- How to use `DB::table()->selectRaw()` to embed raw SQL expressions, including `CASE WHEN` blocks, inside Laravel's Query Builder.
- Why MySQL's `PREPARE`/`EXECUTE` approach cannot be used directly in Laravel, and how to replicate its behavior by moving the assembly logic to PHP.
- How to call a static method on one controller from another controller, keeping responsibilities cleanly separated.
- How to iterate over dynamic column names in a Blade view using a variable property accessor on a `stdClass` object.
- How to design a seeder that inserts a batch of rows efficiently with `DB::table()->insert()`.

### What You'll Need

- PHP 8.4+.
- Laravel 13 (fresh installation, no starter kit).
- MySQL 8.0+ or MariaDB 10.4+, with the `pivot_demo` database already created. If you have not created it yet, the schema setup SQL is in the [previous article](https://qadrlabs.com/post/crosstab-query-in-mysql-and-mariadb-pivot-rows-into-columns-without-a-pivot-function).
- Familiarity with basic Laravel concepts: Artisan commands, controllers, migrations, seeders, routes, and Blade templates.
- A working database client (MySQL CLI, DBeaver, TablePlus, or phpMyAdmin) to verify intermediate steps.

## Step 1: Create the Laravel Project {#step-1-create-laravel-project}

The cleanest way to create a fresh Laravel 13 project without a starter kit is through Composer's `create-project` command. This skips the interactive installer entirely and produces a plain installation with no frontend scaffolding attached.

```bash
composer create-project laravel/laravel:^13.0 crosstab-demo
cd crosstab-demo
```

Once the installation completes, open `.env` in the project root and configure the database connection to point at the `pivot_demo` database. Update the following lines to match your local MySQL credentials:

```ini
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=pivot_demo
DB_USERNAME=root
DB_PASSWORD=your_password_here
```

To confirm the connection is working before going further, run:

```bash
php artisan db:show
```

You should see a summary describing the `pivot_demo` database, its driver, and its connection status. If you see a "Connection refused" error, double-check your `DB_HOST`, `DB_PORT`, and credentials.

## Step 2: Create the Migration and Model {#step-2-migration-model}

With the project connected to the database, the next step is to define the `sales` table schema through a Laravel migration. Even though the table might already exist in `pivot_demo` if you followed the previous article, a migration gives you a repeatable, version-controlled record of the schema that can be run on any environment.

Generate the migration file:

```bash
php artisan make:migration create_sales_table
```

Laravel creates a timestamped file inside `database/migrations/`. Open it and replace its content with the following:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Drop the table first if it already exists from the previous article.
        // This makes the migration idempotent: safe to run whether or not
        // you already have a 'sales' table in pivot_demo.
        Schema::dropIfExists('sales');

        Schema::create('sales', function (Blueprint $table) {
            $table->id();                        // BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
            $table->string('product', 50);
            $table->string('month', 10);         // Stored as 'Jan', 'Feb', etc. for readability
            $table->tinyInteger('month_order');  // Numeric order so rows can be sorted correctly
            $table->decimal('revenue', 10, 2);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales');
    }
};
```

A few things are worth noting here. The `Schema::dropIfExists('sales')` at the top of `up()` handles both readers who are starting fresh and those who already have a `sales` table from the previous article. Additionally, `$table->id()` produces a `BIGINT UNSIGNED AUTO_INCREMENT` column rather than the plain `INT` the original MySQL schema used. This has no effect on any of the pivot queries, which never touch the `id` column, but it is worth being aware of if you inspect the table structure afterward. Finally, there are no `created_at` or `updated_at` columns. The pivot logic does not need them, and leaving them out keeps the schema aligned with the original article's design.

Now generate the `Sale` model:

```bash
php artisan make:model Sale
```

Open `app/Models/Sale.php` and replace its content with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['product', 'month', 'month_order', 'revenue'])]
class Sale extends Model
{
    // Disable automatic timestamp management because the migration
    // does not include created_at and updated_at columns.
    public $timestamps = false;
}
```

The `#[Fillable]` attribute is the modern Laravel 11+ replacement for the `protected $fillable` array. It declares which columns are safe for mass assignment. The `$timestamps = false` property prevents Eloquent from trying to write to timestamp columns that do not exist in the schema.

Now run the migration:

```bash
php artisan migrate
```

Expected output:

```
   INFO  Running migrations.

  2025_XX_XX_XXXXXX_create_sales_table ................................................ 23ms DONE
```

## Step 3: Seed the Database {#step-3-seed-database}

With the schema in place, populate the table with the same dataset from the previous article. The data includes deliberate gaps: Keyboard has no February entry and Mouse has no April entry. These gaps are what make the pivot queries interesting, since they force each approach to handle missing intersections and reveal how each one behaves differently when data is absent.

Generate the seeder:

```bash
php artisan make:seeder SalesSeeder
```

Open `database/seeders/SalesSeeder.php` and fill it in:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SalesSeeder extends Seeder
{
    public function run(): void
    {
        // Truncate before inserting so re-running the seeder does not
        // produce duplicate rows.
        DB::table('sales')->truncate();

        // Insert all rows in a single query for efficiency.
        // The data is identical to the INSERT block in the previous article,
        // including the intentional gaps: no Feb for Keyboard, no Apr for Mouse.
        DB::table('sales')->insert([
            ['product' => 'Laptop',   'month' => 'Jan', 'month_order' => 1, 'revenue' => 15000.00],
            ['product' => 'Laptop',   'month' => 'Feb', 'month_order' => 2, 'revenue' => 18500.00],
            ['product' => 'Laptop',   'month' => 'Mar', 'month_order' => 3, 'revenue' => 17200.00],
            ['product' => 'Laptop',   'month' => 'Apr', 'month_order' => 4, 'revenue' => 21000.00],
            ['product' => 'Mouse',    'month' => 'Jan', 'month_order' => 1, 'revenue' =>  3200.00],
            ['product' => 'Mouse',    'month' => 'Feb', 'month_order' => 2, 'revenue' =>  2800.00],
            ['product' => 'Mouse',    'month' => 'Mar', 'month_order' => 3, 'revenue' =>  3500.00],
            ['product' => 'Keyboard', 'month' => 'Jan', 'month_order' => 1, 'revenue' =>  5100.00],
            ['product' => 'Keyboard', 'month' => 'Mar', 'month_order' => 3, 'revenue' =>  4800.00],
            ['product' => 'Keyboard', 'month' => 'Apr', 'month_order' => 4, 'revenue' =>  6200.00],
        ]);
    }
}
```

Register the seeder in `database/seeders/DatabaseSeeder.php`:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(SalesSeeder::class);
    }
}
```

Run the seeder:

```bash
php artisan db:seed
```

Expected output:

```
   INFO  Seeding database.

  Database\Seeders\SalesSeeder ......................................................... DONE
```

Verify the data in Tinker to confirm all ten rows loaded correctly:

```bash
php artisan tinker
```

```
Psy Shell v0.12.7 (PHP 8.4.5 — cli) by Justin Hileman
> DB::table('sales')->count()
= 10

> DB::table('sales')->orderBy('product')->orderBy('month_order')->get(['product', 'month', 'revenue'])
= Illuminate\Support\Collection {#534
    all: [
      {#535 +"product": "Keyboard", +"month": "Jan", +"revenue": "5100.00"},
      {#536 +"product": "Keyboard", +"month": "Mar", +"revenue": "4800.00"},
      {#537 +"product": "Keyboard", +"month": "Apr", +"revenue": "6200.00"},
      {#538 +"product": "Laptop",   +"month": "Jan", +"revenue": "15000.00"},
      {#539 +"product": "Laptop",   +"month": "Feb", +"revenue": "18500.00"},
      {#540 +"product": "Laptop",   +"month": "Mar", +"revenue": "17200.00"},
      {#541 +"product": "Laptop",   +"month": "Apr", +"revenue": "21000.00"},
      {#542 +"product": "Mouse",    +"month": "Jan", +"revenue": "3200.00"},
      {#543 +"product": "Mouse",    +"month": "Feb", +"revenue": "2800.00"},
      {#544 +"product": "Mouse",    +"month": "Mar", +"revenue": "3500.00"},
    ],
  }
```

Ten rows, with Keyboard missing February and Mouse missing April. This matches the expected dataset from the previous article exactly.

## Step 4: Build the Static Pivot Controller {#step-4-static-pivot-controller}

The static pivot controller handles the case where pivot columns are known in advance. Its `getData()` method is a direct translation of the static `CASE WHEN` query from the previous article into Laravel's Query Builder, using `selectRaw()` to embed the raw SQL expression where it belongs.

Generate the controller:

```bash
php artisan make:controller StaticPivotController
```

Open `app/Http/Controllers/StaticPivotController.php` and replace its content with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class StaticPivotController extends Controller
{
    /**
     * Execute the static pivot query and return its results.
     *
     * Declared as a public static method so that SalesReportController
     * can call StaticPivotController::getData() without instantiating
     * this class. The return value is always an array with two keys:
     *   'columns' => ordered list of column names for the table header.
     *   'rows'    => Collection of stdClass objects, one per product.
     */
    public static function getData(): array
    {
        // selectRaw() passes its argument directly to the database as a
        // raw SQL expression. Each SUM(CASE WHEN ...) block creates one
        // virtual pivot column. ELSE 0 ensures missing months show 0.00
        // rather than NULL in the result set.
        $rows = DB::table('sales')
            ->selectRaw("
                product,
                SUM(CASE WHEN month = 'Jan' THEN revenue ELSE 0 END) AS Jan,
                SUM(CASE WHEN month = 'Feb' THEN revenue ELSE 0 END) AS Feb,
                SUM(CASE WHEN month = 'Mar' THEN revenue ELSE 0 END) AS Mar,
                SUM(CASE WHEN month = 'Apr' THEN revenue ELSE 0 END) AS Apr,
                SUM(revenue) AS total
            ")
            ->groupBy('product')
            ->orderBy('product')
            ->get();

        return [
            // The column list must match the SQL aliases letter-for-letter,
            // including case. The Blade view uses these strings as dynamic
            // property names when accessing each stdClass row object.
            'columns' => ['product', 'Jan', 'Feb', 'Mar', 'Apr', 'total'],
            'rows'    => $rows,
        ];
    }

    public function index(): \Illuminate\View\View
    {
        $data = self::getData();

        return view('sales.pivot', [
            'title'   => 'Static Pivot',
            'columns' => $data['columns'],
            'rows'    => $data['rows'],
        ]);
    }
}
```

The `columns` array deserves attention. Its values must match the SQL aliases letter-for-letter, including case, because the Blade view uses those strings as dynamic property names to access each row object. If the SQL alias is `Jan` but the columns array has `jan`, the view will silently produce empty cells.

Before registering any routes, verify the query output directly in Tinker:

```bash
php artisan tinker
```

```
Psy Shell v0.12.7 (PHP 8.4.5 — cli) by Justin Hileman
> use App\Http\Controllers\StaticPivotController;
> StaticPivotController::getData()
= [
    "columns" => [
      "product",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "total",
    ],
    "rows" => Illuminate\Support\Collection {#545
      all: [
        {#546
          +"product": "Keyboard",
          +"Jan": "5100.00",
          +"Feb": "0.00",
          +"Mar": "4800.00",
          +"Apr": "6200.00",
          +"total": "16100.00",
        },
        {#547
          +"product": "Laptop",
          +"Jan": "15000.00",
          +"Feb": "18500.00",
          +"Mar": "17200.00",
          +"Apr": "21000.00",
          +"total": "71700.00",
        },
        {#548
          +"product": "Mouse",
          +"Jan": "3200.00",
          +"Feb": "2800.00",
          +"Mar": "3500.00",
          +"Apr": "0.00",
          +"total": "9500.00",
        },
      ],
    },
  ]
```

The output confirms three things: the query runs without error, missing months appear as `"0.00"` rather than `null`, and the `total` column correctly sums only the revenue values that actually exist. The static pivot is working.

## Step 5: Build the Dynamic Pivot Controller {#step-5-dynamic-pivot-controller}

The dynamic pivot controller solves the maintenance problem that the static version leaves open: what happens when a new month's data appears in the table. Instead of hardcoding month names, this controller discovers them at runtime from the database, builds the SQL string in PHP, and then executes it.

Generate the controller:

```bash
php artisan make:controller DynamicPivotController
```

Open `app/Http/Controllers/DynamicPivotController.php` and replace its content with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class DynamicPivotController extends Controller
{
    /**
     * Execute the dynamic pivot query and return its results.
     *
     * Unlike the static version, this method first discovers which months
     * exist in the table, then builds the SQL string in PHP, then executes
     * it. Adding new months to the data requires no changes to this code.
     */
    public static function getData(): array
    {
        // Phase 1: discover distinct months, ordered correctly.
        // This is the PHP equivalent of the subquery inside GROUP_CONCAT
        // from the previous article. The Query Builder fetches unique
        // month/month_order pairs as a Collection of stdClass objects.
        $months = DB::table('sales')
            ->select('month', 'month_order')
            ->distinct()
            ->orderBy('month_order')
            ->get();

        // Phase 2: map each month into a CASE WHEN SQL fragment.
        // This replaces the GROUP_CONCAT + CONCAT logic from MySQL.
        // The backtick-quoted alias (AS `Jan`) protects against month
        // names that could conflict with a MySQL reserved keyword.
        // implode() joins the fragments with a comma, producing the same
        // column expression list that GROUP_CONCAT produced in MySQL.
        $columnExpressions = $months
            ->map(fn($m) => "SUM(CASE WHEN month = '{$m->month}' THEN revenue ELSE 0 END) AS `{$m->month}`")
            ->implode(', ');

        // Phase 3: assemble and execute the full SELECT statement.
        // DB::select() runs a raw SQL string and returns an array of stdClass
        // objects, one per result row. collect() wraps it in a Collection so
        // both controllers return the same type for the view to consume.
        $sql = "SELECT product, {$columnExpressions}, SUM(revenue) AS total
                FROM sales
                GROUP BY product
                ORDER BY product";

        $rows = collect(DB::select($sql));

        // Phase 4: build the column list from the discovered months.
        // This is what the view uses for table headers and for property
        // access on each row object.
        $columns = array_merge(
            ['product'],
            $months->pluck('month')->toArray(),
            ['total']
        );

        return [
            'columns' => $columns,
            'rows'    => $rows,
        ];
    }

    public function index(): \Illuminate\View\View
    {
        $data = self::getData();

        return view('sales.pivot', [
            'title'   => 'Dynamic Pivot',
            'columns' => $data['columns'],
            'rows'    => $data['rows'],
        ]);
    }
}
```

There are two details worth highlighting. First, the `collect()` call on the result of `DB::select()`. The Query Builder's `get()` method returns a `Collection`, but `DB::select()` returns a plain PHP array. Wrapping with `collect()` makes both `getData()` methods return the same type, so the Blade view does not need any conditional logic to handle the difference. Second, the `array_merge()` in Phase 4 builds the column list by prepending `product` and appending `total` around the dynamically discovered month names, exactly mirroring the column order in the SQL.

Verify in Tinker:

```bash
php artisan tinker
```

```
Psy Shell v0.12.7 (PHP 8.4.5 — cli) by Justin Hileman
> use App\Http\Controllers\DynamicPivotController;
> DynamicPivotController::getData()
= [
    "columns" => [
      "product",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "total",
    ],
    "rows" => Illuminate\Support\Collection {#549
      all: [
        {#550
          +"product": "Keyboard",
          +"Jan": "5100.00",
          +"Feb": "0.00",
          +"Mar": "4800.00",
          +"Apr": "6200.00",
          +"total": "16100.00",
        },
        {#551
          +"product": "Laptop",
          +"Jan": "15000.00",
          +"Feb": "18500.00",
          +"Mar": "17200.00",
          +"Apr": "21000.00",
          +"total": "71700.00",
        },
        {#552
          +"product": "Mouse",
          +"Jan": "3200.00",
          +"Feb": "2800.00",
          +"Mar": "3500.00",
          +"Apr": "0.00",
          +"total": "9500.00",
        },
      ],
    },
  ]
```

The output is identical to the static pivot. Both methods return the same structure: a `columns` array and a `rows` Collection. This consistency is intentional. The combined report controller and the shared Blade view can work with either dataset without knowing which method produced it.

## Step 6: Build the Combined Report Controller {#step-6-report-controller}

The combined report controller is deliberately thin. Its only job is to call `getData()` on each of the two pivot controllers and pass the results to a single view that renders both tables side by side.

Generate it:

```bash
php artisan make:controller SalesReportController
```

Open `app/Http/Controllers/SalesReportController.php` and replace its content with:

```php
<?php

namespace App\Http\Controllers;

class SalesReportController extends Controller
{
    public function index(): \Illuminate\View\View
    {
        // Call getData() on each pivot controller as a static method.
        // No instantiation is needed, and no HTTP request is dispatched.
        // Each method returns the same array shape:
        //   ['columns' => [...], 'rows' => Collection]
        // The view receives both under the keys 'static' and 'dynamic'.
        return view('sales.report', [
            'static'  => StaticPivotController::getData(),
            'dynamic' => DynamicPivotController::getData(),
        ]);
    }
}
```

The controller has no constructor and no injected dependencies. Both `getData()` methods handle their own database interaction internally. Keeping this controller thin also makes it easy to extend later: if you add a third pivot variant in the future, you add one line here.

## Step 7: Create the Blade Views {#step-7-blade-views}

Two views are needed. The first is a general-purpose pivot view used by `StaticPivotController` and `DynamicPivotController` when accessed individually. The second is the combined report view used by `SalesReportController`. Both use standalone HTML with Tailwind CSS loaded via CDN.

Create the views directory first:

```bash
mkdir -p resources/views/sales
```

### The Individual Pivot View

Create `resources/views/sales/pivot.blade.php`. This view receives a `$title`, a `$columns` array, and a `$rows` Collection. The table headers and cell values are both driven by the same `$columns` array, which is what allows a single view to render either a static or dynamic pivot without any conditional logic.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-4xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">

        <h1 class="text-2xl font-bold text-gray-800 mb-6">{{ $title }}</h1>

        <div class="overflow-x-auto">
            <table class="min-w-full text-sm text-left border border-gray-200 rounded-md">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                    <tr>
                        {{-- Render one <th> per column name. ucfirst() capitalises the first
                             letter so 'product' displays as 'Product' and 'total' as 'Total'. --}}
                        @foreach ($columns as $col)
                            <th class="px-4 py-3 border-b border-gray-200">{{ ucfirst($col) }}</th>
                        @endforeach
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                    @foreach ($rows as $row)
                        <tr class="hover:bg-gray-50">
                            @foreach ($columns as $col)
                                {{-- $row->$col uses a variable property name to access the
                                     matching column on the stdClass object returned by PDO.
                                     $col is a string like 'Jan', so $row->$col reads $row->Jan.
                                     This pattern works for any column name discovered at runtime. --}}
                                <td class="px-4 py-3 {{ $col === 'product' ? 'font-medium' : 'text-right tabular-nums' }}">
                                    {{ $row->$col }}
                                </td>
                            @endforeach
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Crosstab Query at qadrlabs.com</a>
        </div>

    </div>
</body>
</html>
```

### The Combined Report View

Create `resources/views/sales/report.blade.php`. This view receives two variables, `$static` and `$dynamic`, each carrying the same `columns`/`rows` structure. The table markup is repeated for each pivot, with a descriptive subtitle that explains the behavioral difference between the two approaches.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sales Pivot Report</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-4xl mx-auto space-y-8">

        {{-- Static pivot section --}}
        <div class="bg-white p-6 md:p-8 rounded-lg shadow-md">
            <h2 class="text-xl font-bold text-gray-800 mb-1">Static Pivot</h2>
            <p class="text-sm text-gray-500 mb-5">
                Columns are hardcoded. New months are silently absorbed into the total but never appear as a column.
            </p>
            <div class="overflow-x-auto">
                <table class="min-w-full text-sm text-left border border-gray-200 rounded-md">
                    <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                        <tr>
                            @foreach ($static['columns'] as $col)
                                <th class="px-4 py-3 border-b border-gray-200">{{ ucfirst($col) }}</th>
                            @endforeach
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @foreach ($static['rows'] as $row)
                            <tr class="hover:bg-gray-50">
                                @foreach ($static['columns'] as $col)
                                    <td class="px-4 py-3 {{ $col === 'product' ? 'font-medium' : 'text-right tabular-nums' }}">
                                        {{ $row->$col }}
                                    </td>
                                @endforeach
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Dynamic pivot section --}}
        <div class="bg-white p-6 md:p-8 rounded-lg shadow-md">
            <h2 class="text-xl font-bold text-gray-800 mb-1">Dynamic Pivot</h2>
            <p class="text-sm text-gray-500 mb-5">
                Columns are discovered at runtime. New months appear automatically without any code changes.
            </p>
            <div class="overflow-x-auto">
                <table class="min-w-full text-sm text-left border border-gray-200 rounded-md">
                    <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                        <tr>
                            @foreach ($dynamic['columns'] as $col)
                                <th class="px-4 py-3 border-b border-gray-200">{{ ucfirst($col) }}</th>
                            @endforeach
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                        @foreach ($dynamic['rows'] as $row)
                            <tr class="hover:bg-gray-50">
                                @foreach ($dynamic['columns'] as $col)
                                    <td class="px-4 py-3 {{ $col === 'product' ? 'font-medium' : 'text-right tabular-nums' }}">
                                        {{ $row->$col }}
                                    </td>
                                @endforeach
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        <div class="mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Crosstab Query at qadrlabs.com</a>
        </div>

    </div>
</body>
</html>
```

The table-rendering markup in both views is structurally identical. Columns and cell values are derived entirely from the data passed in, which means the view does not need to know anything about months, products, or how many columns there are. It only knows that `$columns` is an ordered list of property names, and that every object in `$rows` exposes those names as accessible properties.

## Step 8: Register the Routes {#step-8-register-routes}

Open `routes/web.php` and add three routes: one for the static pivot individually, one for the dynamic pivot individually, and one for the combined report.

```php
<?php

use App\Http\Controllers\DynamicPivotController;
use App\Http\Controllers\SalesReportController;
use App\Http\Controllers\StaticPivotController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/sales/static',  [StaticPivotController::class,  'index']);
Route::get('/sales/dynamic', [DynamicPivotController::class, 'index']);
Route::get('/sales/report',  [SalesReportController::class,  'index']);
```

Verify the routes were registered correctly:

```bash
php artisan route:list
```

```
  GET|HEAD  /               .............................................................. 
  GET|HEAD  sales/dynamic   DynamicPivotController@index                                
  GET|HEAD  sales/report    SalesReportController@index                                 
  GET|HEAD  sales/static    StaticPivotController@index                                 
```

All three routes appear. You are ready to start the development server and verify the output in the browser.

## Step 9: Try It Out {#step-9-try-it-out}

Start the development server:

```bash
php artisan serve
```

The server starts on `http://127.0.0.1:8000` by default.

### Scenario A: Viewing the Initial Report

Open `http://127.0.0.1:8000/sales/report` in your browser. You will see two tables rendered on the same page: "Static Pivot" above and "Dynamic Pivot" below. At this point, both tables show the same output:

```
Product    Jan        Feb        Mar        Apr        Total
Keyboard   5100.00    0.00       4800.00    6200.00    16100.00
Laptop     15000.00   18500.00   17200.00   21000.00   71700.00
Mouse      3200.00    2800.00    3500.00    0.00       9500.00
```

This is expected. Both techniques produce identical results when the data matches the hardcoded column definitions. The behavioral difference only surfaces when new data appears.

You can also view each pivot individually. Opening `http://127.0.0.1:8000/sales/static` renders only the static pivot table via `StaticPivotController@index`, and `http://127.0.0.1:8000/sales/dynamic` renders only the dynamic one via `DynamicPivotController@index`, both using the shared `sales.pivot` view.

### Scenario B: Adding a New Month

Insert May data for all three products via Tinker. Keep `php artisan serve` running in a separate terminal window while you open a second terminal for Tinker.

```bash
php artisan tinker
```

```
Psy Shell v0.12.7 (PHP 8.4.5 — cli) by Justin Hileman
> DB::table('sales')->insert([
    ['product' => 'Laptop',   'month' => 'May', 'month_order' => 5, 'revenue' => 23500.00],
    ['product' => 'Mouse',    'month' => 'May', 'month_order' => 5, 'revenue' =>  4100.00],
    ['product' => 'Keyboard', 'month' => 'May', 'month_order' => 5, 'revenue' =>  7300.00],
  ]);
= true
```

Now reload `http://127.0.0.1:8000/sales/report`.

The Static Pivot table will look like this:

```
Product    Jan        Feb        Mar        Apr        Total
Keyboard   5100.00    0.00       4800.00    6200.00    23400.00
Laptop     15000.00   18500.00   17200.00   21000.00   95200.00
Mouse      3200.00    2800.00    3500.00    0.00       13600.00
```

May has disappeared entirely. The query has no `CASE WHEN month = 'May'` block, so it cannot produce a May column. Meanwhile, the `total` column has silently absorbed May's revenue: Keyboard's total jumped from 16100.00 to 23400.00, but there is no May column to account for the increase. The per-column numbers no longer add up to the total. This is a silent data inconsistency, the kind that is easy to miss in a report and difficult to trace without looking at the raw data.

The Dynamic Pivot table, on the other hand, will look like this:

```
Product    Jan        Feb        Mar        Apr        May       Total
Keyboard   5100.00    0.00       4800.00    6200.00    7300.00   23400.00
Laptop     15000.00   18500.00   17200.00   21000.00   23500.00  95200.00
Mouse      3200.00    2800.00    3500.00    0.00       4100.00   13600.00
```

May appeared as a new column without any code change. The totals are consistent: every month is visible, and each row's column values add up to its total. The dynamic controller discovered May by querying the database on this request, included it in the assembled SQL, and produced a correct result.

## Understanding the Shift: From MySQL PREPARE to PHP Assembly {#understanding-shift}

If you followed the previous article closely, you may have noticed that the dynamic pivot there relied on MySQL session variables, `GROUP_CONCAT`, `PREPARE`, and `EXECUTE` to build and run the SQL string entirely inside the database. This article moved that assembly step to PHP. The reason is not a preference for one language over the other. It is a technical constraint imposed by how Laravel communicates with MySQL.

### Why MySQL PREPARE Does Not Work in Laravel

Laravel uses PHP's PDO (PHP Data Objects) extension as its database abstraction layer. PDO is built around the concept of a single, parameterized prepared statement per execution cycle. When you call `DB::select()`, `DB::table()->get()`, or any other Laravel database method, it eventually calls `PDOStatement::prepare()` followed by `PDOStatement::execute()` on a single SQL string. One call, one statement, one result set.

MySQL's `PREPARE stmt FROM @sql` is a fundamentally different mechanism. It is a server-side command that instructs the MySQL engine to parse a SQL string and store it as a named statement handle for later execution with `EXECUTE`. This is a multi-step, stateful procedure that spans multiple SQL operations sharing a session. PDO has no corresponding abstraction for this. Each call to `PDO::prepare()` is independent and stateless relative to the previous one.

You might wonder whether `DB::statement()` could bridge the gap. `DB::statement()` does let you run arbitrary SQL, including `SET @sql = ...` to store a value in a MySQL session variable. However, it sends one statement per call and returns only a boolean success value, not rows. The subsequent `PREPARE` and `EXECUTE` steps would each need their own `DB::statement()` calls, and crucially, `EXECUTE` cannot return a result set through `DB::statement()` because that method is not designed to fetch rows. There is no standard PDO mechanism to retrieve data from a `PREPARE`/`EXECUTE` sequence across separate method calls.

PDO does include a multi-statement mode (controlled by the `PDO::MYSQL_ATTR_MULTI_STATEMENTS` flag) that allows sending multiple SQL statements in a single string. Laravel disables this mode by default as a security measure, since allowing arbitrary multi-statement input significantly increases SQL injection risk. Re-enabling it for this use case would introduce an audit surface that is difficult to justify.

### Why PHP Assembly Is the Right Trade-off

Moving the SQL assembly to PHP turns out to be the better approach for an application context anyway. In MySQL, `GROUP_CONCAT` was necessary because SQL lacks native array-mapping operations. PHP has them built in. The four lines that call `$months->map()` and `->implode()` in `DynamicPivotController::getData()` do exactly what `GROUP_CONCAT(CONCAT(...))` did in MySQL, but in a language that makes the operation readable, debuggable, and testable.

There are also practical advantages. The assembled SQL string can be logged, inspected with `\Log::debug($sql)`, or dumped during development before execution. Additional business logic, such as filtering months by a date range or capping the column count, can be applied in PHP without touching MySQL procedural syntax. And because `getData()` is a plain PHP method, it can be unit tested independently by mocking the Query Builder, something that is not possible with a multi-statement MySQL procedure.

The one trade-off is that the dynamic pivot now issues two database round-trips: one `SELECT DISTINCT` to fetch the months, and one `SELECT` to run the assembled pivot query. In practice, for reporting queries that aggregate hundreds of thousands or millions of rows, the overhead of a single additional fast `SELECT DISTINCT` on a small set of distinct values is negligible. The aggregation itself is the expensive part, and that runs only once.

## Conclusion {#conclusion}

Bringing crosstab queries into Laravel requires one meaningful shift from the MySQL-native technique: the dynamic SQL assembly moves from MySQL's `GROUP_CONCAT`/`PREPARE`/`EXECUTE` flow into PHP, where the Query Builder and Collection methods handle the same job more cleanly. The conditional aggregation pattern itself translates directly, with `selectRaw()` acting as the bridge. Here are the key ideas to carry forward:

- **`selectRaw()` is the bridge between the Query Builder and raw SQL expressions.** You do not have to choose between the Query Builder and raw SQL. `selectRaw()` lets you embed any SQL expression, including multi-line `CASE WHEN` blocks, inside a fully chainable Query Builder call, keeping the rest of the query (groupBy, orderBy) in the Query Builder where it is readable and composable.
- **Return a consistent shape from each `getData()` method.** Defining a standard return structure with `columns` and `rows` for both the static and dynamic controllers means the view and the combined report controller work with either dataset without knowing which method produced it. This makes the code easy to extend: adding a third pivot variant requires one new controller and one line in `SalesReportController`.
- **MySQL's `PREPARE`/`EXECUTE` cannot be replicated through PDO.** Laravel's database layer is stateless across individual calls. Session variables set by `DB::statement()` persist in the MySQL session, but `EXECUTE` cannot return rows through that interface, and multi-statement mode is disabled by default for good security reasons. Moving assembly to PHP avoids this limitation entirely.
- **Two database round-trips are acceptable for reporting.** The dynamic pivot issues one query for distinct months and one for the aggregation. For datasets that justify a pivot report, the overhead of an additional lightweight `SELECT DISTINCT` is negligible compared to the aggregation itself.
- **Variable property access (`$row->$col`) is how Blade handles dynamic columns.** When column names are not known at template-compile time, passing the column list alongside the rows and using `$row->$col` to access each property by variable name is the correct pattern. It works on any `stdClass` object returned by PDO, and it requires no special Blade directives or helper methods.
- **`collect()` ensures type consistency between the two controllers.** `DB::table()->get()` returns a Collection, but `DB::select()` returns a plain PHP array. Wrapping the array in `collect()` inside the dynamic controller means both methods deliver the same type to the view, eliminating the need for any conditional handling in the template.