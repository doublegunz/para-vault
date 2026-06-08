---
title: "Preventing Race Conditions in Laravel with lockForUpdate"
slug: "preventing-race-conditions-in-laravel-with-lockforupdate"
category: "Laravel"
date: "2026-05-12"
status: "published"
---

You have built a withdrawal feature for your wallet app. The code checks the balance, deducts the requested amount, and saves. It works perfectly in every test you run. Then you go live and within days, some users somehow have a negative balance. The `if` statement checking the balance is right there in the code; how did that happen?

This is a race condition. When two HTTP requests hit your withdrawal endpoint at nearly the same moment, both read the same balance from the database before either one has written its update. Both pass the balance check, both deduct, and both call `save()`. The second `save()` overwrites the first, effectively discarding one deduction. The user has withdrawn twice but only one deduction was applied, and because each request computed its result from the same starting value, the balance appears normal while the funds are gone. This type of bug never shows up in local testing because your local environment almost never processes two requests against the same row simultaneously.

Laravel ships with a precise tool for this exact problem. `lockForUpdate()` instructs the database to place an exclusive row-level lock on the record as it is read, forcing every other transaction that needs the same row to wait until the current one finishes. Combine it with `DB::transaction()` and you get an atomic read-check-write sequence where the race condition becomes impossible by design.

In this tutorial, you will build a standalone digital wallet app, create the vulnerable withdrawal endpoint, write a Pest test that proves the bug exists, and then fix it properly using `lockForUpdate` inside a database transaction.

## Overview {#overview}

This is a standalone tutorial focused on one pattern: preventing race conditions on shared database rows using pessimistic locking. The concepts apply directly to any "read, check, then write" flow in your application, including inventory deduction, ticket booking, coupon redemption, and any ledger-style financial operation.

### What You'll Build

- A wallet dashboard that shows the current balance and a full transaction history.
- Two withdrawal endpoints side by side: one vulnerable to race conditions and one protected with `lockForUpdate`.
- A Pest test suite that first proves the bug exists with a concrete demonstration, then verifies that the safe endpoint behaves correctly under all scenarios.

### What You'll Learn

- Why a balance check with a plain `if` statement is not enough under concurrent load.
- How `lockForUpdate()` creates a row-level exclusive lock at the moment the row is read.
- Why `lockForUpdate()` must be called inside a `DB::transaction()` to have any effect.
- The exact SQL statement that `lockForUpdate()` generates and how the database interprets it.
- The difference between `lockForUpdate()` and `sharedLock()`.
- When to consider alternative approaches such as atomic `decrement()` or `Cache::lock()`.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally on your system.
- The Laravel installer: `composer global require laravel/installer`.
- Basic familiarity with Laravel routing, controllers, Eloquent models, and migrations.
- No prior experience with database locking is required.

## Step 1: Create the Project and Set Up the Database {#step-1-create-project}

Start by scaffolding a fresh Laravel 13 project. The `--no-boost` flag skips the Vite and npm setup because your views will load Tailwind directly from the CDN. SQLite keeps the database configuration minimal with no separate server to run.

```bash
laravel new wallet-demo --no-interaction --database=sqlite --pest --no-boost
cd wallet-demo
```

Pest is already included when you use this command, so no additional installation is needed.

### Create the Migrations

Two tables are needed for this tutorial. The `wallets` table stores each user's current balance, and the `wallet_transactions` table keeps an immutable log of every debit and credit operation. Run the make commands to generate the migration files:

```bash
php artisan make:migration create_wallets_table
php artisan make:migration create_wallet_transactions_table
```

Open `database/migrations/xxxx_xx_xx_create_wallets_table.php` and replace the `up` method:

```php
public function up(): void
{
    Schema::create('wallets', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        // Store balance as an integer (smallest currency unit, e.g. Rupiah).
        // This avoids floating-point precision errors that occur with float columns.
        // Rp 75,000 is stored as the integer 75000.
        $table->unsignedBigInteger('balance')->default(0);
        $table->timestamps();
    });
}
```

Storing money as an integer is a standard practice in financial applications. A `float` or `double` column can introduce subtle rounding errors when you add or subtract amounts repeatedly, which compounds into real discrepancies over time.

Open `database/migrations/xxxx_xx_xx_create_wallet_transactions_table.php` and replace the `up` method:

```php
public function up(): void
{
    Schema::create('wallet_transactions', function (Blueprint $table) {
        $table->id();
        $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
        // 'debit' means money left the wallet; 'credit' means money was added.
        $table->enum('type', ['debit', 'credit']);
        $table->unsignedBigInteger('amount');
        $table->string('note')->nullable();
        $table->timestamps();
    });
}
```

### Create the Models

Generate both models:

```bash
php artisan make:model Wallet
php artisan make:model WalletTransaction
```

Open `app/Models/Wallet.php` and replace its contents:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'balance'])]
class Wallet extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function transactions(): HasMany
    {
        // Latest transactions appear first when displayed in the dashboard.
        return $this->hasMany(WalletTransaction::class)->latest();
    }
}
```

Open `app/Models/WalletTransaction.php` and replace its contents:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['wallet_id', 'type', 'amount', 'note'])]
class WalletTransaction extends Model
{
    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }
}
```

The `#[Fillable]` PHP attribute is the Laravel 13 convention for declaring mass-assignable fields. It replaces the `protected $fillable` array property and places the declaration visibly at the class signature rather than inside the body, making it immediately apparent which fields can be mass-assigned without opening the class.

### Seed the Database

Open `database/seeders/DatabaseSeeder.php` and replace its contents:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::factory()->create([
            'name'  => 'Demo User',
            'email' => 'demo@example.com',
        ]);

        // Open a wallet with a starting balance of Rp 100,000.
        Wallet::create([
            'user_id' => $user->id,
            'balance' => 100000,
        ]);
    }
}
```

Run the migrations and seed in one command:

```bash
php artisan migrate --seed
```

You should see output similar to:

```
   INFO  Running migrations.

  xxxx_xx_xx_create_wallets_table ................. 8ms DONE
  xxxx_xx_xx_create_wallet_transactions_table ..... 6ms DONE

   INFO  Seeding database.
```

## Step 2: Build the Vulnerable Withdrawal Endpoint {#step-2-vulnerable-endpoint}

Before introducing the fix, build the broken version first. Seeing the flaw explicitly, with comments pointing to exactly where the race condition lives, makes the solution much more intuitive and easier to remember.

### Create the Controller

```bash
php artisan make:controller WalletController
```

Open `app/Http/Controllers/WalletController.php` and replace its contents:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class WalletController extends Controller
{
    public function index(): View
    {
        // Eager-load transactions so the view does not fire an extra query per row.
        $wallet = Wallet::with('transactions')->first();

        return view('wallet.index', compact('wallet'));
    }

    public function withdraw(Request $request): RedirectResponse
    {
        $request->validate(['amount' => 'required|integer|min:1']);
        $amount = $request->integer('amount');

        // Read the current balance from the database.
        $wallet = Wallet::first();

        // ⚠️  RACE CONDITION WINDOW OPENS HERE.
        // This check reads a snapshot of the balance at this exact moment.
        // A concurrent request running alongside this one may have read the
        // exact same snapshot before either request has committed a write.
        if ($wallet->balance < $amount) {
            return back()->with('error', 'Insufficient balance.');
        }

        // ⚠️  Another request may also have passed the check above
        // using the same stale snapshot. Both will now proceed to
        // compute and save their results independently.

        $wallet->balance -= $amount;
        $wallet->save();

        // ⚠️  RACE CONDITION WINDOW CLOSES HERE — but the damage is done.
        // The request that calls save() last overwrites the other's result.
        // One deduction is silently discarded with no error or indication.

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type'      => 'debit',
            'amount'    => $amount,
            'note'      => 'Withdrawal (unsafe)',
        ]);

        return back()->with('success', "Withdrawal of Rp {$amount} recorded.");
    }
}
```

The inline comments mark the exact window where a concurrent request can interleave. Between the moment the balance is read and the moment it is saved, another request can read the same value, pass the same check, compute the same result, and overwrite. This "read, check, write" pattern is the root cause of virtually every financial race condition in web applications.

### Create the View

Create the directory and file:

```bash
mkdir -p resources/views/wallet
touch resources/views/wallet/index.blade.php
```

Open `resources/views/wallet/index.blade.php` and add the following:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wallet Demo</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
<div class="max-w-2xl mx-auto">

    {{-- Balance Card --}}
    <div class="bg-white rounded-lg shadow-md p-6 md:p-8 mb-6">
        <h1 class="text-2xl font-bold mb-1">Wallet Dashboard</h1>
        <p class="text-sm text-gray-400 mb-5">Race Condition Demo</p>

        {{-- Balance display changes color when negative --}}
        <div class="rounded-lg p-4 mb-5 {{ $wallet->balance < 0 ? 'bg-red-50 border border-red-200' : 'bg-gray-50' }}">
            <p class="text-xs text-gray-400 uppercase tracking-wide mb-1">Current Balance</p>
            <p class="text-3xl font-bold {{ $wallet->balance < 0 ? 'text-red-600' : 'text-green-600' }}">
                Rp {{ number_format($wallet->balance, 0, ',', '.') }}
            </p>
            @if($wallet->balance < 0)
                <p class="text-xs text-red-500 mt-2">
                    ⚠️ Negative balance detected. A race condition has occurred.
                </p>
            @endif
        </div>

        @if(session('success'))
            <div class="bg-green-100 text-green-800 px-4 py-2 rounded mb-4 text-sm">
                {{ session('success') }}
            </div>
        @endif
        @if(session('error'))
            <div class="bg-red-100 text-red-800 px-4 py-2 rounded mb-4 text-sm">
                {{ session('error') }}
            </div>
        @endif

        {{-- Unsafe Withdrawal --}}
        <div class="border border-red-200 rounded-lg p-4 mb-4 bg-red-50">
            <h2 class="font-semibold text-red-700 mb-1">⚠️ Withdraw (Unsafe — No Lock)</h2>
            <p class="text-xs text-gray-500 mb-3">
                Vulnerable to race conditions. Two simultaneous requests can both pass
                the balance check and cause data loss.
            </p>
            <form action="/withdraw" method="POST" class="flex gap-2">
                @csrf
                <input type="number" name="amount" value="80000" min="1"
                    class="flex-1 border border-gray-300 rounded px-3 py-2 text-sm
                           focus:outline-none focus:ring-2 focus:ring-red-300">
                <button type="submit"
                    class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded
                           text-sm font-medium transition">
                    Withdraw
                </button>
            </form>
        </div>

        {{-- Safe Withdrawal (route added in Step 4) --}}
        <div class="border border-green-200 rounded-lg p-4 bg-green-50">
            <h2 class="font-semibold text-green-700 mb-1">✅ Withdraw (Safe — lockForUpdate)</h2>
            <p class="text-xs text-gray-500 mb-3">
                Protected by a database transaction and an exclusive row lock.
                Concurrent requests are serialized at the database level.
            </p>
            <form action="/withdraw-safe" method="POST" class="flex gap-2">
                @csrf
                <input type="number" name="amount" value="80000" min="1"
                    class="flex-1 border border-gray-300 rounded px-3 py-2 text-sm
                           focus:outline-none focus:ring-2 focus:ring-green-300">
                <button type="submit"
                    class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded
                           text-sm font-medium transition">
                    Withdraw
                </button>
            </form>
        </div>
    </div>

    {{-- Transaction History --}}
    <div class="bg-white rounded-lg shadow-md p-6 md:p-8">
        <h2 class="text-lg font-bold mb-4">Transaction History</h2>

        @if($wallet->transactions->isEmpty())
            <p class="text-sm text-gray-400">No transactions recorded yet.</p>
        @else
            <div class="overflow-x-auto">
                <table class="w-full text-sm">
                    <thead>
                        <tr class="border-b text-left text-gray-400 text-xs uppercase tracking-wide">
                            <th class="pb-2 pr-4 font-medium">Date</th>
                            <th class="pb-2 pr-4 font-medium">Type</th>
                            <th class="pb-2 pr-4 font-medium">Amount</th>
                            <th class="pb-2 font-medium">Note</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($wallet->transactions as $tx)
                            <tr class="border-b border-gray-50">
                                <td class="py-2 pr-4 text-gray-400 text-xs">
                                    {{ $tx->created_at->format('d M Y H:i:s') }}
                                </td>
                                <td class="py-2 pr-4">
                                    <span class="px-2 py-0.5 rounded-full text-xs font-medium
                                        {{ $tx->type === 'debit'
                                            ? 'bg-red-100 text-red-700'
                                            : 'bg-green-100 text-green-700' }}">
                                        {{ ucfirst($tx->type) }}
                                    </span>
                                </td>
                                <td class="py-2 pr-4 font-medium">
                                    Rp {{ number_format($tx->amount, 0, ',', '.') }}
                                </td>
                                <td class="py-2 text-gray-500">{{ $tx->note }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </div>

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com"
           class="text-blue-600 hover:text-blue-800 hover:underline transition"
           target="_blank">Tutorial Race Conditions at qadrlabs.com</a>
    </div>

</div>
</body>
</html>
```

The balance display turns red and shows a warning message when the value drops below zero, which makes the race condition immediately visible when it occurs. Both withdrawal forms are present in the view from the beginning; the safe form simply points to `/withdraw-safe`, which you will register in Step 4.

### Register the Routes

Open `routes/web.php` and replace its contents:

```php
<?php

use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

Route::get('/', [WalletController::class, 'index']);
Route::post('/withdraw', [WalletController::class, 'withdraw']);
// /withdraw-safe will be registered in Step 4 once the safe method is built.
```

### Try the App

Start the development server:

```bash
php artisan serve
```

Open `http://127.0.0.1:8000`. You should see the wallet dashboard with a balance of Rp 100,000 and an empty transaction history. A single withdrawal from the unsafe form processes correctly at this point. The problem only manifests when two requests arrive at the server simultaneously, which is nearly impossible to reproduce manually in a browser but straightforward to demonstrate with a test.

## Step 3: Prove the Problem with a Pest Test {#step-3-prove-the-problem}

The race condition is invisible when requests run one at a time, which is precisely why it survives code review and local testing. The most reliable way to expose it is to write a test that replicates exactly what the database sees during concurrent requests: two separate reads of the same row before either write has committed.

This is the mechanism of the problem. Two PHP processes each load the `Wallet` model at nearly the same moment, both holding a snapshot of the balance before either one has saved an update. From each process's perspective, the balance is still the original value, so both pass the balance check. Both proceed to compute a new balance, and both call `save()`. The second `save()` overwrites the first, silently discarding one deduction. Both transactions appear to have succeeded, but only one deduction was actually applied. The user withdrew twice but their balance only reflects one withdrawal.

Create the test file:

```bash
php artisan make:test WalletTest
```

Open `tests/Feature/WalletTest.php` and replace its contents:

```php
<?php

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// Create a fresh user and wallet with balance 100,000 before every test.
beforeEach(function () {
    $user = User::factory()->create();
    Wallet::create(['user_id' => $user->id, 'balance' => 100000]);
});

it('displays the wallet balance on the index page', function () {
    $response = $this->get('/');

    $response->assertStatus(200);
    // The view formats Rp 100,000 using a dot as the thousands separator.
    $response->assertSee('100.000');
});

it('demonstrates the race condition: two stale reads cause one deduction to be lost', function () {
    $wallet = Wallet::first();
    $amount  = 80000;

    // Simulate two HTTP requests reading the wallet at the same moment:
    // both load a snapshot of the row before either one has written an update.
    $requestA = Wallet::find($wallet->id); // Reads: balance = 100,000
    $requestB = Wallet::find($wallet->id); // Also reads: balance = 100,000 (stale snapshot)

    // Request A passes its check (100,000 >= 80,000) and saves.
    if ($requestA->balance >= $amount) {
        $requestA->balance -= $amount; // Computes: 100,000 - 80,000 = 20,000
        $requestA->save();             // DB is now 20,000.
    }

    // Request B also passes its check using the stale snapshot it holds.
    // It does not see that Request A has already reduced the balance.
    if ($requestB->balance >= $amount) {
        $requestB->balance -= $amount; // Computes from stale value: 100,000 - 80,000 = 20,000
        $requestB->save();             // Overwrites DB with 20,000, erasing A's deduction!
    }

    $wallet->refresh();

    // The correct outcomes should be one of:
    //   (A) Balance = -60,000 with both transactions recorded (both applied correctly).
    //   (B) Balance = 20,000 with the second withdrawal rejected (proper serialization).
    //
    // Instead: balance is 20,000, which LOOKS correct, but two 80,000 withdrawals
    // both "succeeded". The user received 160,000 from a 100,000 wallet.
    // One 80,000 deduction was silently lost.
    expect($wallet->balance)->toBe(20000);
});
```

Run these two tests now to confirm the behavior:

```bash
./vendor/bin/pest tests/Feature/WalletTest.php
```

Expected output:

```
$ ./vendor/bin/pest tests/Feature/WalletTest.php

   PASS  Tests\Feature\WalletTest
  ✓ it displays the wallet balance on the index page                     0.19s  
  ✓ it demonstrates the race condition: two stale reads cause one deduc… 0.02s  

  Tests:    2 passed (3 assertions)
  Duration: 0.27s


```

Both tests pass. The second test confirms the race condition by proving that the balance ends up at 20,000 when two simultaneous 80,000 withdrawals are processed from the same stale snapshot. A wallet that started at 100,000 effectively dispensed 160,000 with no error and no indication that anything went wrong.

## Step 4: Fix It with lockForUpdate Inside a Transaction {#step-4-fix-with-lockforupdate}

The fix requires two things working together. `DB::transaction()` wraps the entire operation so that either the full sequence (acquire lock, check balance, deduct, record transaction) commits atomically or nothing does. `lockForUpdate()` tells the database to place an exclusive lock on the row at the moment it is read, which forces any other transaction that needs the same row to wait at the database level until the current one finishes.

The practical result is this: when two requests arrive simultaneously, the database grants the lock to one and makes the other wait. The waiting request does not proceed with a stale snapshot; it is blocked at the `SELECT` statement until the first transaction commits. Only then does the second request continue, reading the fresh committed balance (20,000, not the stale 100,000), and the balance check correctly rejects the second withdrawal.

### Add the Safe Withdrawal Method

Open `app/Http/Controllers/WalletController.php` and add the `safeWithdraw` method after the existing `withdraw` method:

```php
public function safeWithdraw(Request $request): RedirectResponse
{
    $request->validate(['amount' => 'required|integer|min:1']);
    $amount = $request->integer('amount');

    $result = DB::transaction(function () use ($amount) {
        // lockForUpdate() acquires an exclusive row lock immediately at read time.
        // Any other transaction that calls lockForUpdate() on the same row will be
        // blocked at this line until this transaction commits or rolls back.
        $wallet = Wallet::lockForUpdate()->first();

        // This check now runs after the lock is held. The balance we read here is
        // the current committed value, not a stale snapshot from before the lock.
        // No concurrent request can modify this row while we are inside this transaction.
        if ($wallet->balance < $amount) {
            // Return a result array rather than redirecting; we cannot issue a
            // redirect from inside a transaction closure. Alternatively, you can
            // throw a custom exception, which also triggers an automatic rollback.
            return ['success' => false, 'message' => 'Insufficient balance.'];
        }

        $wallet->balance -= $amount;
        $wallet->save();

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type'      => 'debit',
            'amount'    => $amount,
            'note'      => 'Withdrawal (safe)',
        ]);

        return ['success' => true, 'message' => "Withdrawal of Rp {$amount} successful."];
    });
    // The transaction commits here. The row lock is released automatically.
    // Any requests that were waiting on the lock now proceed and read the fresh balance.

    return $result['success']
        ? back()->with('success', $result['message'])
        : back()->with('error', $result['message']);
}
```

The key difference from the unsafe version is that the balance check and the `save()` are now part of the same transaction, and the row is locked before the check runs. There is no longer a window between the read and the write where another request can slip in with a stale value.

### Register the Safe Route

Open `routes/web.php` and add the new route:

```php
<?php

use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

Route::get('/', [WalletController::class, 'index']);
Route::post('/withdraw', [WalletController::class, 'withdraw']);
Route::post('/withdraw-safe', [WalletController::class, 'safeWithdraw']); // Added
```

The safe form in the view already targets `/withdraw-safe`, so no changes to the template are needed. Both withdrawal endpoints are now active.

## Step 5: Verify the Fix with Pest Tests {#step-5-verify-with-tests}

With the safe endpoint in place, expand the test file to cover the full expected behavior: successful withdrawal, balance becoming insufficient, transaction logging, and the guarantee that no negative balance can result from two sequential requests against the same wallet.

Open `tests/Feature/WalletTest.php` and replace its contents with the complete suite:

```php
<?php

use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $user = User::factory()->create();
    Wallet::create(['user_id' => $user->id, 'balance' => 100000]);
});

// --- Index page ---

it('displays the wallet balance on the index page', function () {
    $response = $this->get('/');

    $response->assertStatus(200);
    $response->assertSee('100.000');
});

// --- Race condition demonstration ---

it('demonstrates the race condition: two stale reads cause one deduction to be lost', function () {
    $wallet = Wallet::first();
    $amount  = 80000;

    $requestA = Wallet::find($wallet->id); // Reads: 100,000
    $requestB = Wallet::find($wallet->id); // Also reads: 100,000 (stale)

    if ($requestA->balance >= $amount) {
        $requestA->balance -= $amount;
        $requestA->save(); // DB = 20,000
    }

    if ($requestB->balance >= $amount) {
        $requestB->balance -= $amount;
        $requestB->save(); // Overwrites with 20,000 — A's deduction is silently lost
    }

    $wallet->refresh();

    // Balance looks correct at 20,000, but two 80,000 withdrawals both "succeeded".
    expect($wallet->balance)->toBe(20000);
});

// --- Safe withdrawal: happy path ---

it('processes a successful safe withdrawal and reduces the balance correctly', function () {
    $wallet = Wallet::first();

    $response = $this->post('/withdraw-safe', ['amount' => 30000]);

    $response->assertRedirect('/');
    $response->assertSessionHas('success');

    $wallet->refresh();
    expect($wallet->balance)->toBe(70000);
});

// --- Safe withdrawal: insufficient balance ---

it('rejects a safe withdrawal when the requested amount exceeds the balance', function () {
    $wallet = Wallet::first();

    $response = $this->post('/withdraw-safe', ['amount' => 150000]);

    $response->assertRedirect('/');
    $response->assertSessionHas('error');

    $wallet->refresh();
    // Balance must remain exactly unchanged when the withdrawal is rejected.
    expect($wallet->balance)->toBe(100000);
});

// --- Transaction logging ---

it('records a debit transaction entry after a successful safe withdrawal', function () {
    $wallet = Wallet::first();

    $this->post('/withdraw-safe', ['amount' => 25000]);

    expect(WalletTransaction::count())->toBe(1);

    $tx = WalletTransaction::first();
    expect($tx->wallet_id)->toBe($wallet->id)
        ->and($tx->type)->toBe('debit')
        ->and($tx->amount)->toBe(25000)
        ->and($tx->note)->toBe('Withdrawal (safe)');
});

it('does not record a transaction when a safe withdrawal is rejected', function () {
    $this->post('/withdraw-safe', ['amount' => 999999]);

    // No transaction record should exist for a failed withdrawal.
    expect(WalletTransaction::count())->toBe(0);
});

// --- Serial safety guarantee ---

it('correctly rejects the second withdrawal when balance is insufficient after the first', function () {
    $wallet = Wallet::first();

    // First withdrawal: 80,000 from 100,000 — should succeed.
    $responseA = $this->post('/withdraw-safe', ['amount' => 80000]);
    $responseA->assertSessionHas('success');

    // Second withdrawal: 80,000 from the remaining 20,000 — must be rejected.
    $responseB = $this->post('/withdraw-safe', ['amount' => 80000]);
    $responseB->assertSessionHas('error');

    $wallet->refresh();

    // Final balance must be 20,000 with exactly one transaction recorded.
    expect($wallet->balance)->toBe(20000)
        ->and(WalletTransaction::count())->toBe(1);
});
```

Run the full suite:

```bash
./vendor/bin/pest tests/Feature/WalletTest.php
```

Expected output:

```
$ ./vendor/bin/pest tests/Feature/WalletTest.php

   PASS  Tests\Feature\WalletTest
  ✓ it displays the wallet balance on the index page                     0.18s  
  ✓ it demonstrates the race condition: two stale reads cause one deduc… 0.02s  
  ✓ it processes a successful safe withdrawal and reduces the balance c… 0.03s  
  ✓ it rejects a safe withdrawal when the requested amount exceeds the…  0.03s  
  ✓ it records a debit transaction entry after a successful safe withdr… 0.03s  
  ✓ it does not record a transaction when a safe withdrawal is rejected  0.02s  
  ✓ it correctly rejects the second withdrawal when balance is insuffic… 0.03s  

  Tests:    7 passed (21 assertions)
  Duration: 0.39s

```

All seven tests pass. The safe endpoint correctly rejects the second withdrawal, records exactly one transaction, and leaves the balance at 20,000.

## How `lockForUpdate` Works Under the Hood {#how-lockforupdate-works}

Now that the implementation is complete and tested, it is worth understanding what happens at the database level. This section explains the mechanics so you can apply the pattern confidently and know when a different tool is more appropriate.

### What Happens at the SQL Level

When you call `Wallet::lockForUpdate()->first()` inside a transaction, Laravel generates a SQL statement with a locking hint:

```sql
SELECT * FROM `wallets` LIMIT 1 FOR UPDATE
```

The `FOR UPDATE` clause is a standard SQL instruction that tells the database engine to acquire an exclusive write lock on every row returned by the query. In MySQL (InnoDB) and PostgreSQL, this is a row-level lock, meaning only the specific rows matching your query are locked; the rest of the table is completely unaffected and available for other queries.

Once a row is locked with `FOR UPDATE`, any other transaction that attempts to read that row with `FOR UPDATE` or modify it with `UPDATE` or `DELETE` is suspended at the database level. It does not fail immediately; it waits. The lock is released automatically when the holding transaction either commits or rolls back. You never manage lock acquisition or release manually; the database handles it entirely.

This is why `lockForUpdate()` must be called inside a `DB::transaction()`. Without an active transaction, there is no transaction boundary for the lock to live within, and the database releases the lock the moment the `SELECT` returns. The lock window would last for zero time, making it completely useless for preventing race conditions.

### `lockForUpdate()` vs `sharedLock()`

Laravel provides two pessimistic locking methods. `lockForUpdate()` generates `SELECT ... FOR UPDATE`, which acquires an exclusive lock: only one transaction can hold it, and it blocks both other `FOR UPDATE` reads and any writes. `sharedLock()` generates `SELECT ... LOCK IN SHARE MODE`, which allows multiple transactions to read the same row concurrently but prevents any of them from modifying it until all shared locks are released.

Use `lockForUpdate()` when you intend to read and then modify the row. Use `sharedLock()` when you need a consistent read and want to guarantee the row will not change during your read, but you do not intend to write to it yourself.

### The Common Mistake: Calling It Outside a Transaction

Calling `lockForUpdate()` without a transaction is a mistake that is easy to make and produces no error, which makes it particularly dangerous:

```php
// Wrong: the lock is acquired and released within the same SELECT statement.
// There is no transaction holding it open, so it provides zero protection.
$wallet = Wallet::lockForUpdate()->first();
$wallet->balance -= 50000;
$wallet->save(); // Still vulnerable — no lock was held during this save.

// Correct: the lock is held from the lockForUpdate() call until transaction commit.
DB::transaction(function () {
    $wallet = Wallet::lockForUpdate()->first(); // Lock acquired here.
    $wallet->balance -= 50000;
    $wallet->save();
}); // Lock released here when the transaction commits.
```

In the incorrect example, the lock is acquired and immediately released because there is no open transaction. The `balance -= 50000` and `save()` operations happen entirely outside any lock protection, and two concurrent requests can still interleave exactly as before.

### Keep Transactions Short

A common antipattern is including slow or external operations inside the transaction while the lock is held:

```php
// Dangerous: the row lock is held during an external HTTP call.
// Every other request needing this wallet must wait for the API response.
DB::transaction(function () use ($wallet, $amount) {
    $wallet = Wallet::lockForUpdate()->first();
    $wallet->balance -= $amount;
    $wallet->save();

    Http::post('https://audit-service.example.com/log', [...]);
});

// Correct: external calls happen before or after the transaction.
$auditPayload = ['amount' => $amount, 'wallet_id' => $wallet->id];

DB::transaction(function () use ($wallet, $amount) {
    $wallet = Wallet::lockForUpdate()->first();
    $wallet->balance -= $amount;
    $wallet->save();
}); // Lock released here.

Http::post('https://audit-service.example.com/log', $auditPayload);
```

The locked transaction should contain only the operations that require the lock. Any external API calls, file operations, or other slow tasks should live outside the transaction boundary. Long-held locks increase contention, raise the probability of lock timeouts, and in cases where multiple rows are locked in different orders across transactions, can lead to deadlocks.

### When to Consider Other Approaches

`lockForUpdate()` is not the only tool for concurrency, and it is not always the right choice.

**Atomic `decrement()` or `increment()`** — If your only goal is to decrease or increase a counter and you do not need to check a condition before doing so, `DB::table('wallets')->where('id', $id)->decrement('balance', $amount)` executes as a single atomic SQL operation (`UPDATE wallets SET balance = balance - ? WHERE id = ?`). No transaction is needed because the entire operation is a single statement. However, if you need to check the current value before deciding whether to apply the change, a raw decrement alone is insufficient because the check is still a separate read.

**`Cache::lock()` for non-database logic** — If the critical section involves external APIs, queue operations, or shared state not stored in a database row, a Redis-based lock via `Cache::lock('key', 10)->block(5, fn () => ...)` is the appropriate tool. Database row locks only work on database rows; they cannot protect business logic that touches external systems.

**Optimistic locking** — If contention on a given row is rare and you prefer non-blocking behavior, optimistic locking is an alternative. The pattern reads the row along with a version number, computes the update, and saves only if the version has not changed since the read. If it has changed (another request modified the row first), the operation retries. This avoids blocking entirely but requires retry logic and works best when collisions are genuinely infrequent.

## Conclusion {#conclusion}

Race conditions on shared database rows are a class of bug that hides perfectly in development and only surfaces under real concurrent load. Laravel's `lockForUpdate()` addresses this with a minimal, well-understood pattern that the database engine enforces at the storage level rather than in application code.

- **The root cause is a stale read.** When two requests read the same row before either one writes, both operate on outdated data. A conditional check against a stale value is not reliable under concurrency, no matter how logically correct it appears.

- **`lockForUpdate()` acquires an exclusive row lock at read time.** The SQL it generates, `SELECT ... FOR UPDATE`, tells the database to block any other transaction from reading the same rows with `FOR UPDATE` or modifying them until the current transaction finishes.

- **`lockForUpdate()` has no effect outside a `DB::transaction()`.** Without an open transaction, the lock is released immediately after the `SELECT` and provides no window of protection.

- **The fix pattern is one transaction enclosing the full read-check-write sequence.** Calling `lockForUpdate()` in the same query that reads the value you intend to conditionally modify guarantees the check and the write are serialized correctly across all concurrent requests.

- **Keep the locked transaction as short as possible.** Long-running transactions hold locks longer, increasing contention and the probability of timeouts. Move any external calls or slow operations to outside the transaction boundary.

- **`lockForUpdate()` is not always the right tool.** Use atomic `decrement()` or `increment()` when no condition check is needed. Use `Cache::lock()` for critical sections involving non-database resources. Use optimistic locking when contention is rare and retrying is preferable to blocking.