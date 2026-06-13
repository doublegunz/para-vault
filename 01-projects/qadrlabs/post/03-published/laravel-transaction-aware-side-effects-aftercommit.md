# Laravel afterCommit: Don't Send the Confirmation Email Before the Transaction Commits

In the previous tutorial, [Laravel 13 Database Transactions and Rollbacks: Stop Multi-Table Inserts From Half-Failing](https://qadrlabs.com/post/laravel-13-database-transactions-and-rollbacks-stop-multi-table-inserts-from-half-failing), we wrapped a checkout in `DB::transaction()` so that a failed order rolls back every table it touched. No orphaned order rows, no phantom stock decrements, nothing left half-written. The database guarantee was airtight. Then you add one innocent line: right after creating the order, you queue a "we received your order" email so the customer hears from you immediately.

Now run the same out-of-stock checkout that fails partway through. The transaction rolls back perfectly, the order disappears, the stock is restored, and the customer still gets an email confirming an order that does not exist in your database. Support gets a ticket asking where the order went. Worse, this only happens some of the time, because it depends on how fast your queue worker picks the job up relative to your commit. It passes every test you wrote, works fine on your laptop, and then misbehaves under load in production. The job ran against data that had not been committed yet.

The fix is to make the side effect transaction-aware: tell Laravel to hold the dispatch until the surrounding transaction actually commits, and to throw it away if the transaction rolls back. Laravel ships exactly this through `afterCommit`. In this tutorial we reproduce the leaked email deterministically, fix it with `->afterCommit()`, and then tour every mechanism Laravel gives you for jobs, events, notifications, and inline callbacks.

## Overview {#overview}

The teaching strategy mirrors the transactions tutorial: make the bug real before fixing it. We take the checkout from the previous article, queue a confirmation email from inside the `DB::transaction()` closure, and watch the email escape from a checkout that rolled back. We make the race deterministic by running the queue on the `sync` driver and mail on the `array` driver, so the job runs inline and we can inspect exactly what was sent. Then we add `->afterCommit()` to the queued mailable, rerun the identical failing cart, and confirm nothing was sent. After locking the behavior down with Pest, we cover how the deferral works and the full toolbox for jobs, events, and notifications.

### What You'll Build

- A checkout that queues an order confirmation email from inside a database transaction
- A deterministic reproduction of the email being sent even though the order rolled back
- The same checkout fixed with `->afterCommit()` so the email waits for the commit
- A Pest suite proving a successful checkout sends exactly one email and a failed one sends none

### What You'll Learn

- Why a job or email dispatched inside a transaction can fire before the data is committed
- How `->afterCommit()` defers a queued mailable until the transaction commits
- How `DB::afterCommit()` defers an inline callback
- How to enable `after_commit` globally on a queue connection in `config/queue.php`
- How `ShouldQueueAfterCommit`, `ShouldDispatchAfterCommit`, and `ShouldHandleEventsAfterCommit` apply the same rule to mailables, events, and queued listeners
- How to test after-commit behavior with the `sync` queue and the `array` mailer

### What You'll Need

- PHP 8.3 or newer
- Laravel 13 with the default SQLite database
- The checkout from the previous tutorial, [Laravel 13 Database Transactions and Rollbacks](https://qadrlabs.com/post/laravel-13-database-transactions-and-rollbacks-stop-multi-table-inserts-from-half-failing)
- Basic familiarity with queues, mailables, and Artisan Tinker

## Step 1: Start From the Checkout {#step-1-start-from-the-checkout}

This tutorial builds directly on the checkout service from the previous article. You can take either path depending on whether you followed along last time.

If you already have the `transactions-demo` project from the previous tutorial, you can keep working in it. The only change you need is to give the `checkout` method an `$email` parameter so we have a recipient for the confirmation. If you are starting fresh, create the project now.

```bash
laravel new side-effects-demo --no-interaction --database=sqlite --pest --no-boost
cd side-effects-demo
```

```
 • Creating Laravel application
   ✔ Application initialized

 • Running database migrations
   ✔ Database migrated

 • Setting up Pest
   ✔ Pest initialized

 Application ready in [side-effects-demo]. You can start your local development using:

 ➜ cd side-effects-demo
 ➜ npm install --ignore-scripts && npm run build
 ➜ composer run dev
```

Whether you continued the old project or scaffolded a new one, set the queue and mail drivers in your `.env` so the bug is reproducible. The `sync` queue runs jobs inline instead of in a separate worker, which makes the timing deterministic, and the `array` mailer keeps every "sent" message in memory so we can count it.

```
QUEUE_CONNECTION=sync
MAIL_MAILER=array
```

If you are scaffolding fresh, recreate the three models, their migrations, and the seeder from the previous tutorial. The products migration carries a stock count.

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

The orders migration holds a status and a running total, exactly as before. Notice there is no email column; we send the confirmation to an address passed into the checkout, so the schema from the previous tutorial does not change at all.

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

The order items migration links each line back to its order and product.

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

Define the three models with the `#[Fillable]` attribute. Open `app/Models/Product.php`.

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

Open `app/Models/Order.php` and give it the items relationship.

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

Seed the same predictable stock levels as before, with the keyboard deliberately out of stock. Open `database/seeders/DatabaseSeeder.php`.

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

Finally, create `app/Services/CheckoutService.php` with the transaction-wrapped checkout from the previous tutorial, now accepting an `$email` for the recipient. There is no email logic yet; we add that in the next step.

```php
<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class CheckoutService
{
    /**
     * @param  array<int, array{product_id: int, quantity: int}>  $items
     */
    public function checkout(string $email, array $items): Order
    {
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
}
```

Migrate fresh and seed so the database matches the scenario.

```bash
php artisan migrate:fresh --seed
```

```

  Dropping all tables ............................................ 3.82ms DONE

   INFO  Preparing database.  

  Creating migration table ...................................... 10.93ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 22.86ms DONE
  0001_01_01_000001_create_cache_table .......................... 17.60ms DONE
  0001_01_01_000002_create_jobs_table ........................... 26.28ms DONE
  2026_06_13_023605_create_order_items_table ..................... 7.79ms DONE
  2026_06_13_023605_create_orders_table .......................... 4.54ms DONE
  2026_06_13_023605_create_products_table ........................ 4.29ms DONE


   INFO  Seeding database.  

```

We now have the same three products as before, with the keyboard at zero stock waiting to trip the checkout. Time to add the email that will leak.

## Step 2: Queue the Confirmation Email the Naive Way {#step-2-queue-the-confirmation-email-the-naive-way}

A confirmation email is a queued mailable, so generate one. We will dispatch it from inside the transaction, right after the order is created, which is the natural and most common place to put it.

```bash
php artisan make:mail OrderConfirmation
```

```
   INFO  Mailable [app/Mail/OrderConfirmation.php] created successfully.  
```

Open `app/Mail/OrderConfirmation.php` and turn it into a queued mailable that carries the order. We implement `ShouldQueue` so the email goes through the queue instead of sending during the request, and we use an inline `htmlString` so there is no Blade view to create for this demo.

```php
<?php

namespace App\Mail;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OrderConfirmation extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(public Order $order)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "We received your order #{$this->order->id}",
        );
    }

    public function content(): Content
    {
        return new Content(
            htmlString: "<h1>Thanks for your order!</h1>
                <p>We received order #{$this->order->id} and are processing it now.</p>",
        );
    }
}
```

Because the mailable implements `ShouldQueue`, sending it with `queue()` pushes a job onto the queue rather than sending it immediately. Now wire it into the checkout. Open `app/Services/CheckoutService.php` and queue the email right after the order is created, then import the `Mail` facade and the mailable.

```php
<?php

namespace App\Services;

use App\Mail\OrderConfirmation;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use RuntimeException;

class CheckoutService
{
    /**
     * @param  array<int, array{product_id: int, quantity: int}>  $items
     */
    public function checkout(string $email, array $items): Order
    {
        return DB::transaction(function () use ($email, $items) {
            $order = Order::create(['status' => 'pending', 'total' => 0]);

            // The naive placement: the acknowledgment email is queued right
            // after the order is created, while the transaction is still open
            // and might still roll back later in this same closure.
            Mail::to($email)->queue(new OrderConfirmation($order));

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
}
```

The email is dispatched on the third line, but the stock check that throws is further down in the loop. That ordering is the whole problem: the moment a later line runs out of stock and throws, the transaction rolls back the order, but the email dispatch has already happened. To exercise this through a real request, expose it with a controller. Generate one.

```bash
php artisan make:controller CheckoutController
```

Open `app/Http/Controllers/CheckoutController.php` and write the `store` action with validation, including the recipient email.

```php
<?php

namespace App\Http\Controllers;

use App\Services\CheckoutService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use RuntimeException;

class CheckoutController extends Controller
{
    public function store(Request $request, CheckoutService $service)
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();

        try {
            $order = $service->checkout($validated['email'], $validated['items']);
        } catch (RuntimeException $e) {
            // A business failure such as out-of-stock; the transaction
            // already rolled back, so the confirmation email was never sent.
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Order placed',
            'order' => $order->load('items'),
        ], 201);
    }
}
```

The validation guarantees a valid recipient email and a non-empty cart of real products before any database work happens. Register the route in `routes/web.php`.

```php
<?php

use App\Http\Controllers\CheckoutController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/checkout', [CheckoutController::class, 'store']);
```

The endpoint is live at `POST /checkout`. Before testing it, let us drive the service straight through Tinker and watch the email leak.

## Step 3: Watch the Email Escape a Rolled-Back Order {#step-3-watch-the-email-escape-a-rolled-back-order}

We will check out a cart whose second item is the out-of-stock keyboard, exactly the failing cart from the previous tutorial. Reset to a clean state and open Tinker.

```bash
php artisan migrate:fresh --seed
php artisan tinker
```

Run the failing checkout, then inspect both the database and the emails the `array` mailer actually recorded.

```php
> $service = app(App\Services\CheckoutService::class);

> try {
     $service->checkout('buyer@example.com', [
         ['product_id' => 1, 'quantity' => 2],
         ['product_id' => 2, 'quantity' => 1],
     ]);
 } catch (\Throwable $e) {
     echo $e->getMessage();
 }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 0

> $messages = Illuminate\Support\Facades\Mail::mailer()->getSymfonyTransport()->messages();

> count($messages);
= 1

> $messages->first()->getOriginalMessage()->getSubject();
= "We received your order #1"
```

Read that carefully. The transaction did its job: `Order::count()` is zero, so the order rolled back cleanly. Yet the `array` transport holds one real message, addressed to the customer, with the subject "We received your order #1" for an order that does not exist in the database. The `getSymfonyTransport()->messages()` call returns every message the mailer genuinely handed off to a transport, which is our ground truth for "did an email actually go out."

On the `sync` queue this happens every single time, which is what makes it a good teaching tool. In production with a real queue worker, the email leaks only when the worker happens to pick up the job before your transaction commits, so it shows up intermittently under load and is miserable to reproduce. The cause is identical in both cases: the dispatch happened inside the transaction, before the commit.

## Step 4: Defer the Email Until After Commit {#step-4-defer-the-email-until-after-commit}

The fix does not move the dispatch out of the transaction; it tells Laravel to hold the dispatch until the transaction commits. The mailable picks up an `afterCommit()` method from the `Queueable` trait, and calling it marks this message so the queue waits for the commit. The current dispatch line queues the mailable immediately.

```php
Mail::to($email)->queue(new OrderConfirmation($order));
```

Change it to call `afterCommit()` on the mailable before queueing it.

```php
Mail::to($email)->queue((new OrderConfirmation($order))->afterCommit());
```

The surrounding code does not change, so the comment in `app/Services/CheckoutService.php` is the only other edit.

```php
// afterCommit() defers the dispatch until the surrounding
// transaction actually commits. If it rolls back, the email
// is never sent.
Mail::to($email)->queue((new OrderConfirmation($order))->afterCommit());
```

When you mark a queued mailable with `afterCommit()`, Laravel does not push the job onto the queue right away. Instead it registers the dispatch as a callback on the current database transaction. If the transaction commits, the callback runs and the job is dispatched for real. If the transaction rolls back, the callback is discarded and the job is never dispatched at all. Reset the database and rerun the exact same failing cart.

```bash
php artisan migrate:fresh --seed
php artisan tinker
```

```php
> $service = app(App\Services\CheckoutService::class);

> try {
     $service->checkout('buyer@example.com', [
         ['product_id' => 1, 'quantity' => 2],
         ['product_id' => 2, 'quantity' => 1],
     ]);
 } catch (\Throwable $e) {
     echo $e->getMessage();
 }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 0

> count(Illuminate\Support\Facades\Mail::mailer()->getSymfonyTransport()->messages());
= 0
```

Same error, same clean rollback, but now zero emails. The dispatch was registered against the transaction and thrown away when the keyboard line rolled it back. The customer hears nothing about an order that never existed. Now we confirm the happy path still sends the email when the transaction commits.

## Step 5: Try It Out {#step-5-try-it-out}

We will run both a successful and a failing checkout through Tinker, inspecting the order count and the email count after each. Reset to a clean, seeded state first.

```bash
php artisan migrate:fresh --seed
php artisan tinker
```

### Scenario 1: A Successful Checkout Sends One Email

Check out a cart that fits within stock and confirm the order committed and exactly one email was sent.

```php
> $service = app(App\Services\CheckoutService::class);

> $order = $service->checkout('buyer@example.com', [
     ['product_id' => 1, 'quantity' => 2],
     ['product_id' => 3, 'quantity' => 3],
 ]);

> $order->total;
= "86.00"

> App\Models\Order::count();
= 1

> count(Illuminate\Support\Facades\Mail::mailer()->getSymfonyTransport()->messages());
= 1
```

The order committed with a total of eighty six, and because the commit succeeded, the deferred email was dispatched and sent. Deferring with `afterCommit()` does not suppress the email; it only waits for the data to be durable first.

### Scenario 2: A Failing Checkout Sends Nothing

Now check out a cart that includes the out-of-stock keyboard and confirm both the database and the mailer are untouched.

```php
> try {
     $service->checkout('buyer@example.com', [
         ['product_id' => 1, 'quantity' => 1],
         ['product_id' => 2, 'quantity' => 1],
     ]);
 } catch (\Throwable $e) {
     echo $e->getMessage();
 }
Not enough stock for Mechanical Keyboard.

> App\Models\Order::count();
= 0

> App\Models\Product::find(1)->stock;
= 10

> count(Illuminate\Support\Facades\Mail::mailer()->getSymfonyTransport()->messages());
= 0
```

The order count is zero, the mouse stock is back to ten, and no email was sent. The side effect now shares the fate of the transaction: it happens only if the transaction commits. With both paths verified, we lock the behavior down with tests.

## Step 6: Write the Tests {#step-6-write-the-tests}

Laravel's test environment already uses the `sync` queue and the `array` mailer by default, which is exactly the deterministic setup we want, so the tests need no extra configuration. Create the test file.

```bash
php artisan make:test CheckoutEmailTest --pest
```

Open `tests/Feature/CheckoutEmailTest.php` and write the suite. We deliberately avoid `Mail::fake()` here, because the fake records messages the moment you queue them and ignores the after-commit deferral, which would hide the very behavior we are testing. Instead we count the messages the `array` transport actually sent.

```php
<?php

use App\Models\Order;
use App\Models\Product;
use App\Services\CheckoutService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;

uses(RefreshDatabase::class);

/**
 * Count the emails that actually reached the array transport. With the
 * array mailer, every message that is genuinely sent is recorded here,
 * so a deferred email that was discarded on rollback will not appear.
 */
function sentEmails(): int
{
    return count(Mail::mailer()->getSymfonyTransport()->messages());
}

it('places an order and sends one confirmation on success', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);
    $cable = Product::create(['name' => 'Cable', 'price' => 12, 'stock' => 50]);

    $response = $this->postJson('/checkout', [
        'email' => 'buyer@example.com',
        'items' => [
            ['product_id' => $mouse->id, 'quantity' => 2],
            ['product_id' => $cable->id, 'quantity' => 3],
        ],
    ]);

    $response->assertCreated();

    expect(Order::count())->toBe(1)
        ->and($mouse->fresh()->stock)->toBe(8)
        ->and(sentEmails())->toBe(1);
});

it('sends no email when the checkout rolls back', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);
    $keyboard = Product::create(['name' => 'Keyboard', 'price' => 80, 'stock' => 0]);

    $response = $this->postJson('/checkout', [
        'email' => 'buyer@example.com',
        'items' => [
            ['product_id' => $mouse->id, 'quantity' => 2],
            ['product_id' => $keyboard->id, 'quantity' => 1],
        ],
    ]);

    $response->assertStatus(422);

    expect(Order::count())->toBe(0)
        ->and($mouse->fresh()->stock)->toBe(10)
        ->and(sentEmails())->toBe(0);
});

it('sends no email when the service rolls back directly', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);
    $keyboard = Product::create(['name' => 'Keyboard', 'price' => 80, 'stock' => 0]);

    $checkout = fn () => app(CheckoutService::class)->checkout('buyer@example.com', [
        ['product_id' => $mouse->id, 'quantity' => 2],
        ['product_id' => $keyboard->id, 'quantity' => 1],
    ]);

    expect($checkout)->toThrow(RuntimeException::class);

    expect(Order::count())->toBe(0)
        ->and(sentEmails())->toBe(0);
});

it('requires an email and a non-empty items array', function () {
    $response = $this->postJson('/checkout', ['items' => []]);

    expect($response->status())->toBe(422);

    expect($response->json('errors'))->toHaveKeys(['email', 'items']);
});

it('rejects unknown products and zero quantities', function () {
    $response = $this->postJson('/checkout', [
        'email' => 'buyer@example.com',
        'items' => [['product_id' => 999, 'quantity' => 0]],
    ]);

    expect($response->status())->toBe(422);

    expect($response->json('errors'))->toHaveKeys([
        'items.0.product_id',
        'items.0.quantity',
    ]);
});

it('computes the order total from product prices', function () {
    $mouse = Product::create(['name' => 'Mouse', 'price' => 25, 'stock' => 10]);

    $this->postJson('/checkout', [
        'email' => 'buyer@example.com',
        'items' => [['product_id' => $mouse->id, 'quantity' => 4]],
    ])->assertCreated();

    expect((float) Order::first()->total)->toBe(100.0);
});
```

The first three tests are the heart of the suite. A valid cart commits the order and sends exactly one email, an out-of-stock cart returns a `422` and sends nothing through the endpoint, and the third calls the service directly to prove the rollback suppresses the email even outside an HTTP request. The remaining tests confirm validation rejects a missing email or empty cart and bad line data, and that the total is computed correctly. Run the suite.

```bash
php artisan test tests/Feature/CheckoutEmailTest.php
```

```
   PASS  Tests\Feature\CheckoutEmailTest
  ✓ it places an order and sends one confirmation on success             0.25s  
  ✓ it sends no email when the checkout rolls back                       0.04s  
  ✓ it sends no email when the service rolls back directly               0.03s  
  ✓ it requires an email and a non-empty items array                     0.02s  
  ✓ it rejects unknown products and zero quantities                      0.03s  
  ✓ it computes the order total from product prices                      0.04s  

  Tests:    6 passed (19 assertions)
  Duration: 0.46s
```

Six green tests confirm the happy path sends one email, both rollback paths send none, and validation guards the door. With the behavior verified, here is what the deferral is doing underneath.

## How afterCommit Works Under the Hood {#how-aftercommit-works-under-the-hood}

Laravel tracks open transactions through a transaction manager bound in the container as `db.transactions`. Every time you enter `DB::transaction()` or call `DB::beginTransaction()`, that manager increments a counter for the connection and keeps a list of callbacks to run once the outermost transaction commits. This is the same machinery that powers the `DB::afterCommit()` helper from the previous tutorial.

When you dispatch a job or queue a mailable that is marked for after-commit, Laravel asks the queue whether the dispatch should wait. If it should, and a transaction is currently open, Laravel does not push the job. Instead it registers a callback on the transaction manager that will perform the dispatch later. On a successful commit the manager walks its callback list and dispatches everything that was deferred. On a rollback the manager simply throws those callbacks away, so the deferred dispatches never happen. If there is no open transaction when you dispatch, the after-commit flag is a no-op and the job dispatches immediately, which is why marking something for after-commit is always safe.

It is worth understanding why the `sync` driver made our bug deterministic. With `sync`, dispatching a job runs it inline in the same process, so without after-commit the email sends the instant you call `queue()`, well before the rollback. A real queue worker is a separate process polling the queue, so it can pick up the job at any moment, sometimes before the commit and sometimes after. After-commit removes the timing entirely: the job is not even visible to a worker until the commit has happened, so there is no window in which a worker can run it against uncommitted data.

## Deferring Jobs, Events, and Notifications {#deferring-jobs-events-and-notifications}

We fixed a mailable with `->afterCommit()`, but the same rule applies to every kind of side effect Laravel can queue. Reach for whichever mechanism fits the side effect you are deferring.

For a queued job, the per-dispatch method is identical to the mailable. You can chain `afterCommit()` onto the pending dispatch, and you can chain `beforeCommit()` to force an immediate dispatch when after-commit is enabled globally.

```php
use App\Jobs\ProcessShipment;

ProcessShipment::dispatch($order)->afterCommit();
```

If a job should always wait for the commit no matter where it is dispatched, declare it once on the job class itself with a property, so you never have to remember the chained call.

```php
class ProcessShipment implements ShouldQueue
{
    public bool $afterCommit = true;
}
```

To apply the rule across an entire queue connection, set `after_commit` to `true` on that connection in `config/queue.php`. This makes every job, mailable, notification, queued listener, and broadcast event on that connection wait for open transactions to commit, and you can still opt a single dispatch out with `->beforeCommit()`.

```php
'database' => [
    'driver' => 'database',
    'connection' => env('DB_QUEUE_CONNECTION'),
    'table' => env('DB_QUEUE_TABLE', 'jobs'),
    'queue' => env('DB_QUEUE', 'default'),
    'retry_after' => (int) env('DB_QUEUE_RETRY_AFTER', 90),
    'after_commit' => true,
],
```

Events and their listeners have their own declarative interfaces. To make an event dispatch only after the current transaction commits, implement `ShouldDispatchAfterCommit` on the event class.

```php
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;

class OrderPlaced implements ShouldDispatchAfterCommit
{
    public function __construct(public Order $order)
    {
    }
}
```

To defer only a queued listener while letting the event dispatch normally, implement `ShouldHandleEventsAfterCommit` on the listener instead.

```php
use Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendShipmentNotification implements ShouldQueue, ShouldHandleEventsAfterCommit
{
    public function handle(OrderPlaced $event): void
    {
        // Runs only after the transaction that fired the event commits.
    }
}
```

Mailables have a matching declarative option too. Instead of calling `->afterCommit()` on every dispatch, you can implement `ShouldQueueAfterCommit` on the mailable so it always waits, which is handy when the mailable is queued from several places.

For an inline side effect that is not a queued job at all, the helper from the previous tutorial still applies. Wrap any closure in `DB::afterCommit()` to run it only once the transaction commits, or immediately if there is no transaction.

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function () use ($order) {
    // ... write the order ...

    DB::afterCommit(function () use ($order) {
        Http::post('https://example.test/webhooks/order', ['id' => $order->id]);
    });
});
```

One caution to close on: deferral is the right default for anything that reads or reacts to the rows you are writing, but not everything belongs after the commit. A side effect that must run regardless of the outcome, such as audit logging of the attempt itself, should stay outside the after-commit path, because you do want it even when the transaction rolls back. The question to ask of each side effect is simple: should this still happen if the transaction fails? If the answer is no, defer it.

## Conclusion {#conclusion}

A transaction protects your tables, but it does nothing for the jobs, emails, events, and webhooks you fire from inside it. Those side effects escape into the world the moment you dispatch them, and if the transaction later rolls back, you are left with confirmations for orders that never existed and jobs querying rows that were never committed. After-commit deferral ties each side effect to the fate of the transaction, so it happens only when the data is real. Here are the ideas worth keeping.

- **Dispatching inside a transaction is a race, not a guarantee.** A job or email queued before the commit can run against data that has not been committed, and on a rollback it should never have run at all.
- **`->afterCommit()` defers a single dispatch.** Chain it onto a queued mailable or job to hold the dispatch until the transaction commits, and the dispatch is discarded if it rolls back.
- **`$afterCommit = true` and the `after_commit` config defer by default.** Set the property on a job class, or the config option on a queue connection, so you never have to remember the chained call.
- **Events and listeners have their own interfaces.** Implement `ShouldDispatchAfterCommit` on an event, `ShouldHandleEventsAfterCommit` on a queued listener, or `ShouldQueueAfterCommit` on a mailable for the same guarantee.
- **`DB::afterCommit()` handles inline side effects.** Wrap a webhook call or any non-queued closure so it runs only after the data is durable.
- **Ask whether the side effect should survive a rollback.** Defer anything that should not happen when the transaction fails, and leave anything that must always run, such as audit logs, outside the after-commit path.
