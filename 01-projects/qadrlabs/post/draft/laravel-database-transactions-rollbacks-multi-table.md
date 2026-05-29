# Laravel 13 Database Transactions and Rollbacks: Stop Multi-Table Inserts From Half-Failing

A checkout looks simple until you count the tables it touches. You create an `order` row, insert an `order_item` for each product in the cart, and decrement the `stock` on each `product`. On a good day all of those writes succeed and the customer gets their confirmation. Then one day a popular item sells out in the half second between the customer loading the page and clicking buy, your code throws an out-of-stock error on the third item, and the first two writes are already sitting in the database.

Now you have an order with only some of its items, or stock decremented for products that belong to an order that was never really completed. This is the worst kind of bug because the application cannot heal it on its own: the data is internally inconsistent, your inventory counts drift away from reality, finance sees phantom orders, and support tickets pile up. Eventually someone is writing careful `DELETE` statements against production at two in the morning trying to reverse a half-finished checkout by hand.

The fix is a database transaction. A transaction tells the database to treat a group of writes as a single all-or-nothing unit: either every write commits together, or the instant anything goes wrong they all roll back and the database looks exactly as it did before you started. In this tutorial we build a checkout that writes to three tables, watch it corrupt data when it fails without a transaction, then wrap it in `DB::transaction()` and watch the same failure leave the database perfectly clean.

## Overview {#overview}

The teaching strategy is to make the partial-write bug real before we fix it, because a rollback is much easier to trust once you have seen the mess it prevents. We build a `CheckoutService` that creates an order, loops over the cart inserting items and decrementing stock, and throws when a product does not have enough stock. We run it first with no transaction and confirm in the database that an order and some items survived a failed checkout. Then we wrap the exact same logic in `DB::transaction()`, rerun the failing cart, and confirm nothing was written at all. After exposing it through an HTTP endpoint and testing it, we cover how transactions work underneath and the one gotcha that trips up almost everyone: dispatching jobs and events from inside a transaction.

### What You'll Build

- A `CheckoutService` that inserts an order, its line items, and decrements product stock as one atomic operation
- A side-by-side demonstration of the same checkout failing destructively without a transaction, then safely with one
- A `CheckoutController` and POST `/checkout` endpoint with validation that calls the service
- A Pest test suite proving that a successful checkout commits everything and a failed one rolls back everything

### What You'll Learn

- How to wrap multi-table writes in `DB::transaction()` so they commit or roll back together
- Why a thrown exception inside the closure triggers an automatic rollback
- How the deadlock-retry attempts argument works
- When to use a manual `beginTransaction` / `commit` / `rollBack` block instead of the closure
- How to lock rows with `lockForUpdate()` to avoid overselling under concurrency
- The `afterCommit` gotcha for queued jobs and events dispatched inside a transaction

### What You'll Need

- PHP 8.3 or newer
- Laravel 13 with the default SQLite database
- Basic familiarity with Eloquent models, controllers, and Artisan Tinker

## Step 1: Create the Project {#step-1-create-the-project}

Create a fresh Laravel 13 application configured for SQLite and Pest, then move into it.

```bash
laravel new transactions-demo --no-interaction --database=sqlite --pest --no-boost
cd transactions-demo
```

Run the default migrations to set up the base tables.

```bash
php artisan migrate
```

```
   INFO  Running migrations.

  0001_01_01_000000_create_users_table ............................... 9ms DONE
  0001_01_01_000001_create_cache_table ............................... 2ms DONE
  0001_01_01_000002_create_jobs_table ................................ 5ms DONE
```

SQLite fully supports transactions, so nothing extra needs installing. With the project ready, we build the tables a checkout touches.

## Step 2: Build the Models and Seed Stock {#step-2-build-the-models-and-seed-stock}

A checkout spans three tables, so we need three models. Generate them with their migrations.

```bash
php artisan make:model Product -mf
php artisan make:model Order -m
php artisan make:model OrderItem -m
```

Open the products migration in `database/migrations` and define a product with a stock count.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('price', 10, 2);
            $table->unsignedInteger('stock');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
```

The `stock` column is the one that makes this scenario interesting, because decrementing it is one of the writes that can leave the database inconsistent. Open the orders migration and define the order header.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('status')->default('pending');
            $table->decimal('total', 10, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

An order tracks its status and a running total that we fill in as we add items. Open the order items migration and link each line back to its order and product.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained();
            $table->unsignedInteger('quantity');
            $table->decimal('unit_price', 10, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
    }
};
```

Each item records the quantity ordered and the price at the time of purchase, which is good practice since product prices change over time. Now define the models. Open `app/Models/Product.php`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'price', 'stock'])]
class Product extends Model
{
    use HasFactory;
}
```

Open `app/Models/Order.php` and add a relationship to its items so we can load them easily later.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['status', 'total'])]
class Order extends Model
{
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
```

Open `app/Models/OrderItem.php`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['order_id', 'product_id', 'quantity', 'unit_price'])]
class OrderItem extends Model
{
}
```

Finally, seed a few products with known, predictable stock levels so our experiments are repeatable. Open `database/seeders/DatabaseSeeder.php`.

```php
<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Product::create(['name' => 'Wireless Mouse', 'price' => 25.00, 'stock' => 10]);
        Product::create(['name' => 'Mechanical Keyboard', 'price' => 80.00, 'stock' => 0]);
        Product::create(['name' => 'USB-C Cable', 'price' => 12.00, 'stock' => 50]);
    }
}
```

The keyboard is deliberately out of stock; it is the trap that will make our checkout fail partway through. Migrate fresh and seed.

```bash
php artisan migrate:fresh --seed
```

```
   INFO  Preparing database.

  Dropping all tables ................................................. 6ms DONE

   INFO  Running migrations.

  ...

   INFO  Seeding database.
```

We now have three products with a known mouse stock of ten, a keyboard stock of zero, and a cable stock of fifty. Time to write a checkout that mishandles failure.

## Step 3: Write a Naive Checkout and Watch It Half-Fail {#step-3-write-a-naive-checkout-and-watch-it-half-fail}

We will put the checkout logic in a dedicated service class. Create the file at `app/Services/CheckoutService.php` and write the first, deliberately unsafe version with no transaction.

```php
<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use RuntimeException;

class CheckoutService
{
    /**
     * @param  array<int, array{product_id: int, quantity: int}>  $items
     */
    public function checkout(array $items): Order
    {
        // Write the order header first.
        $order = Order::create(['status' => 'pending', 'total' => 0]);

        $total = 0;

        foreach ($items as $line) {
            $product = Product::findOrFail($line['product_id']);

            // The trap: a later item may not have enough stock,
            // after earlier items have already been written.
            if ($product->stock < $line['quantity']) {
                throw new RuntimeException("Not enough stock for {$product->name}.");
            }

            $product->decrement('stock', $line['quantity']);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'quantity' => $line['quantity'],
                'unit_price' => $product->price,
            ]);

            $total += $product->price * $line['quantity'];
        }

        $order->update(['total' => $total]);

        return $order;
    }
}
```

The flow is the natural way you would write this without thinking about atomicity. It creates the order, then for each cart line it loads the product, refuses to continue if stock is insufficient, decrements the stock, and inserts the order item. The bug is structural: by the time the third line throws, the order row and the earlier items are already committed to the database independently. Let us prove it in Tinker by checking out a cart whose second item is the out-of-stock keyboard.

```bash
php artisan tinker
```

```php
> $service = app(App\Services\CheckoutService::class);

> try {
.     $service->checkout([
.         ['product_id' => 1, 'quantity' => 2],
.         ['product_id' => 2, 'quantity' => 1],
.     ]);
. } catch (\Throwable $e) {
.     echo $e->getMessage();
. }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 1

> App\Models\OrderItem::count();
= 1

> App\Models\Product::find(1)->stock;
= 8
```

The checkout failed, yet it left a trail of damage: one order row exists, one order item exists for the mouse, and the mouse stock has dropped from ten to eight. The customer was never charged and never got a complete order, but your database now disagrees with reality. This is exactly the inconsistency a transaction prevents.

## Step 4: Make It Atomic With DB::transaction() {#step-4-make-it-atomic-with-db-transaction}

The fix requires no change to the logic, only a wrapper around it. The current method body writes directly to the database.

```php
public function checkout(array $items): Order
{
    $order = Order::create(['status' => 'pending', 'total' => 0]);

    $total = 0;

    foreach ($items as $line) {
        $product = Product::findOrFail($line['product_id']);

        if ($product->stock < $line['quantity']) {
            throw new RuntimeException("Not enough stock for {$product->name}.");
        }

        $product->decrement('stock', $line['quantity']);

        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'quantity' => $line['quantity'],
            'unit_price' => $product->price,
        ]);

        $total += $product->price * $line['quantity'];
    }

    $order->update(['total' => $total]);

    return $order;
}
```

Wrap that entire body in a `DB::transaction()` closure. Update the method to this.

```php
public function checkout(array $items): Order
{
    // Everything inside the closure commits together, or rolls back
    // entirely the moment anything throws.
    return DB::transaction(function () use ($items) {
        $order = Order::create(['status' => 'pending', 'total' => 0]);

        $total = 0;

        foreach ($items as $line) {
            $product = Product::findOrFail($line['product_id']);

            if ($product->stock < $line['quantity']) {
                throw new RuntimeException("Not enough stock for {$product->name}.");
            }

            $product->decrement('stock', $line['quantity']);

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'quantity' => $line['quantity'],
                'unit_price' => $product->price,
            ]);

            $total += $product->price * $line['quantity'];
        }

        $order->update(['total' => $total]);

        return $order;
    });
}
```

Add the `DB` facade import at the top of the file.

```php
use Illuminate\Support\Facades\DB;
```

`DB::transaction()` issues a `BEGIN` before running your closure, a `COMMIT` if the closure returns normally, and a `ROLLBACK` if the closure throws any exception, after which it rethrows that exception for you to handle. Because every write now happens between `BEGIN` and either `COMMIT` or `ROLLBACK`, a failure undoes all of them. The closure also returns its value straight through, which is why we can still `return $order`. Reset the database and run the exact same failing cart from Step 3.

```bash
php artisan migrate:fresh --seed
php artisan tinker
```

```php
> $service = app(App\Services\CheckoutService::class);

> try {
.     $service->checkout([
.         ['product_id' => 1, 'quantity' => 2],
.         ['product_id' => 2, 'quantity' => 1],
.     ]);
. } catch (\Throwable $e) {
.     echo $e->getMessage();
. }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 0

> App\Models\OrderItem::count();
= 0

> App\Models\Product::find(1)->stock;
= 10
```

Same error, completely different aftermath. No order was created, no item was inserted, and the mouse stock is still ten. The transaction rolled the order row and the stock decrement back as though the checkout had never started. If you ever face deadlocks under heavy concurrency, you can pass a second argument to retry the whole transaction automatically, for example `DB::transaction($closure, 3)` to attempt it up to three times before giving up. With the core safe, we expose it over HTTP.

## Step 5: Expose It Through an HTTP Endpoint {#step-5-expose-it-through-an-http-endpoint}

Real checkouts arrive as requests, so we wrap the service in a controller with validation. Generate the controller.

```bash
php artisan make:controller CheckoutController
```

Open `app/Http/Controllers/CheckoutController.php` and write the `store` action.

```php
<?php

namespace App\Http\Controllers;

use App\Services\CheckoutService;
use Illuminate\Http\Request;
use RuntimeException;

class CheckoutController extends Controller
{
    public function store(Request $request, CheckoutService $service)
    {
        // Validate the cart shape before touching the database.
        $validated = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);

        try {
            $order = $service->checkout($validated['items']);
        } catch (RuntimeException $e) {
            // A business failure such as out-of-stock; the transaction
            // already rolled back, so we just report it.
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Order placed',
            'order' => $order->load('items'),
        ], 201);
    }
}
```

The validation rules guarantee the cart is a non-empty array and that every line references a real product with a quantity of at least one, which keeps malformed input from ever reaching the service. The `try/catch` turns the service's out-of-stock exception into a clean `422` response; by the time we catch it, the transaction has already rolled back, so there is nothing to clean up. A successful checkout returns the created order with its items and a `201` status. Register the route in `routes/web.php`.

```php
<?php

use App\Http\Controllers\CheckoutController;
use Illuminate\Support\Facades\Route;

Route::post('/checkout', [CheckoutController::class, 'store']);
```

The endpoint is now live at `POST /checkout`. We will exercise it directly in the test suite, where Laravel handles CSRF for us automatically. First, let us drive the service interactively to see both outcomes.

## Step 6: Try It Out {#step-6-try-it-out}

We will use Tinker to call the service through both a successful and a failing cart, inspecting the database after each. Reset to a clean, seeded state first.

```bash
php artisan migrate:fresh --seed
php artisan tinker
```

### Scenario 1: A Successful Checkout Commits Everything

Check out a cart that fits within stock and confirm every table was written and stock was reduced.

```php
> $service = app(App\Services\CheckoutService::class);

> $order = $service->checkout([
.     ['product_id' => 1, 'quantity' => 2],
.     ['product_id' => 3, 'quantity' => 3],
. ]);

> $order->total;
= "86.00"

> App\Models\Order::count();
= 1

> App\Models\OrderItem::count();
= 2

> [App\Models\Product::find(1)->stock, App\Models\Product::find(3)->stock];
= [
    8,
    47,
  ]
```

The order committed with a total of two mice at twenty five plus three cables at twelve, which is eighty six. Two order items were created, and the mouse and cable stock dropped to eight and forty seven. Everything that should have happened, happened together.

### Scenario 2: A Failing Checkout Rolls Everything Back

Now check out a cart that includes the out-of-stock keyboard and confirm the database is untouched.

```php
> try {
.     $service->checkout([
.         ['product_id' => 1, 'quantity' => 1],
.         ['product_id' => 2, 'quantity' => 1],
.     ]);
. } catch (\Throwable $e) {
.     echo $e->getMessage();
. }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 1

> App\Models\Product::find(1)->stock;
= 8
```

The order count is still one and the mouse stock is still eight, exactly the values from the successful checkout in Scenario 1. The failed checkout added nothing and changed nothing, even though it had already created an order row and was about to decrement the mouse before it hit the keyboard. That is atomicity in action. Now we lock the behavior down with tests.

## Step 7: Write the Tests {#step-7-write-the-tests}

We will test the endpoint for both outcomes plus validation, and the service directly for completeness. Create the test file.

```bash
php artisan make:test CheckoutTest --pest
```

Open `tests/Feature/CheckoutTest.php` and write the suite.

```php
<?php

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Services\CheckoutService;

it('places an order and decrements stock on success', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);
    $cable = Product::create(['name' => 'Cable', 'price' => 12, 'stock' => 50]);

    $response = $this->postJson('/checkout', [
        'items' => [
            ['product_id' => $mouse->id, 'quantity' => 2],
            ['product_id' => $cable->id, 'quantity' => 3],
        ],
    ]);

    $response->assertCreated();

    expect(Order::count())->toBe(1)
        ->and(OrderItem::count())->toBe(2)
        ->and($mouse->fresh()->stock)->toBe(8)
        ->and($cable->fresh()->stock)->toBe(47)
        ->and((float) Order::first()->total)->toBe(86.0);
});

it('rolls back everything when a product is out of stock', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);
    $keyboard = Product::create(['name' => 'Keyboard', 'price' => 80, 'stock' => 0]);

    $response = $this->postJson('/checkout', [
        'items' => [
            ['product_id' => $mouse->id, 'quantity' => 2],
            ['product_id' => $keyboard->id, 'quantity' => 1],
        ],
    ]);

    $response->assertStatus(422);

    expect(Order::count())->toBe(0)
        ->and(OrderItem::count())->toBe(0)
        ->and($mouse->fresh()->stock)->toBe(10);
});

it('requires a non-empty items array', function () {
    $this->postJson('/checkout', [])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['items']);
});

it('rejects unknown products and zero quantities', function () {
    $this->postJson('/checkout', [
        'items' => [['product_id' => 999, 'quantity' => 0]],
    ])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['items.0.product_id', 'items.0.quantity']);
});

it('computes the order total from product prices', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);

    $this->postJson('/checkout', [
        'items' => [['product_id' => $mouse->id, 'quantity' => 4]],
    ])->assertCreated();

    expect((float) Order::first()->total)->toBe(100.0);
});

it('can place an order directly through the service', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);

    $order = app(CheckoutService::class)->checkout([
        ['product_id' => $mouse->id, 'quantity' => 1],
    ]);

    expect($order->items)->toHaveCount(1)
        ->and($mouse->fresh()->stock)->toBe(9);
});
```

The first two tests are the heart of the suite: a valid cart commits an order, its items, and the stock decrements together, while an out-of-stock cart returns a `422` and leaves all three tables exactly as they were. The next two confirm validation rejects an empty cart and bad line data before any database work happens. The fifth checks the computed total, and the last calls the service directly to prove it works outside an HTTP request too. Run the suite.

```bash
php artisan test
```

```
   PASS  Tests\Feature\CheckoutTest
  ✓ it places an order and decrements stock on success            0.22s
  ✓ it rolls back everything when a product is out of stock       0.04s
  ✓ it requires a non-empty items array                           0.02s
  ✓ it rejects unknown products and zero quantities               0.02s
  ✓ it computes the order total from product prices               0.03s
  ✓ it can place an order directly through the service            0.03s

  Tests:    6 passed (14 assertions)
  Duration: 0.46s
```

Six green tests confirm the happy path commits, the failure path rolls back, and validation guards the door. With the behavior verified, here is what the transaction is doing underneath.

## How DB::transaction Works Under the Hood {#how-db-transaction-works-under-the-hood}

A transaction is a feature of the database itself, and Laravel's `DB::transaction()` is a thin, convenient wrapper around three raw SQL statements. When you call it, Laravel sends a `BEGIN` to the database to open a transaction. From that point on, every insert, update, and delete your closure performs is held in a pending state that is invisible to other connections. If your closure returns without throwing, Laravel sends a `COMMIT`, which makes all of those pending changes permanent and visible at once. If your closure throws anything at all, Laravel sends a `ROLLBACK`, which discards every pending change as if the `BEGIN` had never happened, and then rethrows the exception so your application can react.

This is why you never call `commit()` or `rollBack()` yourself inside the closure form, and why simply throwing is the correct way to abort. Our out-of-stock `throw` is not an error in the transaction's eyes so much as the signal to roll back. The closure form also handles deadlocks for you: databases sometimes abort a transaction when two of them contend for the same rows, and passing an attempts count as the second argument tells Laravel to roll back and retry the whole closure that many times before surfacing the failure. Because the closure can run more than once, it should not contain side effects that cannot be safely repeated, which leads directly to the gotcha covered below.

It is worth knowing that transactions can nest. If you call `DB::transaction()` inside another one, Laravel does not open a second real transaction; it creates a savepoint instead, because most databases do not support truly nested transactions. An inner rollback then unwinds to its savepoint rather than discarding the outer transaction, and only the outermost commit actually writes anything to disk.

## Closure Transactions vs Manual Transactions {#closure-transactions-vs-manual-transactions}

The closure form we used is the right default for almost everything, because it cannot forget to commit or roll back and it handles deadlock retries for free. There are times, though, when you want explicit control over the boundaries, for example to catch the exception, log rich context, perform some compensating action, and then decide whether to rethrow. For those cases Laravel exposes the three statements directly through `DB::beginTransaction()`, `DB::commit()`, and `DB::rollBack()`.

```php
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

public function checkoutManually(array $items): Order
{
    DB::beginTransaction();

    try {
        $order = $this->buildOrder($items);

        DB::commit();

        return $order;
    } catch (Throwable $e) {
        DB::rollBack();

        Log::error('Checkout rolled back', ['reason' => $e->getMessage()]);

        throw $e;
    }
}
```

This does exactly what the closure form does, but you can see every boundary. You open the transaction, do the work, commit on success, and in the `catch` you roll back, log, and rethrow. The danger of the manual form is that an early `return` or a forgotten `rollBack()` leaves a transaction open, so reach for it only when you genuinely need the extra control.

There is also a concurrency concern worth naming. Two customers checking out the last unit of a product at the same time can both read a stock of one and both pass the check before either decrements it, which oversells the item. The defense is a pessimistic lock: inside the transaction, load the product with `Product::lockForUpdate()->findOrFail($id)` so the database locks that row until your transaction finishes, forcing the second checkout to wait its turn. Row-level locks like this require a database that supports them, such as MySQL or PostgreSQL, and have no effect on a shared SQLite file, so this is a production hardening you add once you move off SQLite.

## The afterCommit Gotcha {#the-aftercommit-gotcha}

The most common transaction bug in Laravel applications is not data corruption; it is dispatching a job or firing an event from inside a transaction. Imagine that after creating the order you dispatch a `SendOrderConfirmation` job to the queue. If your queue worker is fast, it can pick up and start running that job before your transaction has committed, which means the job queries the database for an order that does not exist yet and fails with a "not found" error. The job ran against a snapshot that did not include your still-pending writes.

Laravel gives you three ways to defer side effects until after the commit succeeds. For an inline callback, wrap it in `DB::afterCommit(fn () => ...)`, which runs the closure only once the surrounding transaction commits, or immediately if there is no transaction. For queued jobs, set `public bool $afterCommit = true;` on the job class, or enable `'after_commit' => true` on the queue connection in `config/queue.php` so every job waits for the commit. For event listeners that should not react until the data is durable, implement the `Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit` interface on the listener.

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function () use ($items) {
    $order = $this->createOrder($items);

    // Deferred: the job is only dispatched if and when the
    // transaction actually commits.
    DB::afterCommit(fn () => SendOrderConfirmation::dispatch($order));

    return $order;
});
```

The rule of thumb is simple: anything that reads the rows you are writing, especially across a queue or another process, should wait for the commit. Keeping side effects out of the transaction body, or explicitly deferring them, saves you from a class of bugs that only appear under load and are miserable to reproduce.

## Conclusion {#conclusion}

A multi-table write without a transaction is a partial failure waiting to happen, and the resulting inconsistency is the kind of bug that erodes trust in your data and your application. Transactions turn a sequence of independent writes into a single all-or-nothing operation, which is exactly the guarantee a checkout, a transfer, or any multi-step write needs. Here are the ideas worth keeping.

- **Wrap related writes in `DB::transaction()`.** Every write inside the closure commits together, or rolls back together the moment anything throws, so the database is never left half-updated.
- **Throwing is how you roll back.** Inside the closure you never call commit or rollback yourself; an exception signals the rollback and is rethrown for you to handle.
- **The closure can retry, so keep it repeatable.** Passing an attempts count retries on deadlock, which means the closure may run more than once and should avoid unrepeatable side effects.
- **Use the manual form only for explicit control.** `beginTransaction`, `commit`, and `rollBack` are there when you need to catch and log around the boundary, but they are easier to get wrong.
- **Lock rows to prevent overselling.** Under concurrency, load contended rows with `lockForUpdate()` inside the transaction on a database that supports row-level locks.
- **Defer side effects until after commit.** Dispatch jobs and fire events with `DB::afterCommit()`, `$afterCommit = true`, or `ShouldHandleEventsAfterCommit`, so nothing reacts to data that has not been committed yet.
