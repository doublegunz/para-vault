Your e-commerce app supports two payment gateways: PayPal and Stripe. Two months later the business adds Midtrans for the Indonesian market. You open `PaymentService::charge` and add an `elseif`. Six months later it adds a wallet provider, and you add another `elseif`. Twelve months later the file has eight branches, each touching the others, and your changes to PayPal somehow affect Stripe because of a refactor you did to the shared exception handling. The QA team starts asking for a full payment regression run on every change.

The pain is not the new gateway. The pain is that adding a new gateway forces you to open and modify code that was already tested and shipped. Every modification is a chance to break what already works. Over a long-lived codebase those chances accumulate, and the team eventually develops a learned helplessness: "we cannot touch payments without a war room".

This article is the third in our SOLID series, following [Single Responsibility Principle in Laravel 13: Refactor a Bloated Invoice Controller](https://qadrlabs.com/post/single-responsibility-principle-in-laravel-13-refactor-a-bloated-invoice-controller). The Open/Closed Principle exists exactly to prevent that learned helplessness. We will build a `PaymentService` that uses an `if/elseif` chain to dispatch to PayPal or Stripe, lock the behavior down with Pest tests, and refactor it into a contract-driven design where adding a third gateway requires zero modification to the service or its tests. Then we will add Midtrans as proof.

## Overview {#overview}

The plan has two phases. First we build the bloated `PaymentService` that almost every Laravel codebase has at least once, with its `if/elseif` dispatch and private methods per gateway. We capture a baseline Pest run with two gateways supported. Second we extract a `PaymentGateway` contract, move PayPal and Stripe behind it, and rewire the service so it discovers gateways through Laravel's service container tag mechanism. The same Pest tests pass with the same count after the refactor. Finally we add Midtrans without touching the service, the contract, or the existing tests, and write new tests just for the new gateway.

### What You'll Build
- A Laravel 13 payment endpoint that supports multiple gateways
- A `PaymentService` that starts as an `if/elseif` chain and ends as an extensible registry
- A `PaymentGateway` contract with three concrete implementations: PayPal, Stripe, and Midtrans
- Pest tests that lock down behavior across the refactor and across the new gateway addition

### What You'll Learn
- How to recognize an Open/Closed Principle violation in a Laravel service
- How to design an interface that closes the high-level module against modification
- How to register a set of strategies with Laravel's service container using tags
- How to add a new strategy without opening any file that already had passing tests

### What You'll Need
- PHP 8.3 or later
- Composer 2.x
- Familiarity with Laravel routing, controllers, and service providers
- A terminal and a code editor

## Step 1: Set Up the Laravel Project {#step-1-set-up-the-laravel-project}

We start with a fresh Laravel 13 application configured with SQLite and Pest. The same toolchain we used in the previous article works here.

```bash
laravel new ocp-payment-demo --no-interaction --database=sqlite --pest --no-boost
cd ocp-payment-demo
```

Verify Pest runs cleanly before adding any of our own code.

```bash
php artisan test
```

The two example tests should pass.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.06s

  Tests:    2 passed (2 assertions)
  Duration: 0.18s
```

## Step 2: Create the Payment Model and Migration {#step-2-create-the-payment-model-and-migration}

The domain stays small. One table holds payment records: which gateway processed the charge, the amount, the currency, and the transaction ID returned by the gateway. Generate the model and migration in one command.

```bash
php artisan make:model Payment -m
```

Open `database/migrations/xxxx_xx_xx_xxxxxx_create_payments_table.php` and replace its contents with the following.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('gateway');                         // paypal, stripe, midtrans, etc.
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3);                     // USD, IDR, EUR, ...
            $table->string('transaction_id')->unique();        // returned by the gateway
            $table->string('status')->default('succeeded');    // simplified: success only
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
```

Then update `app/Models/Payment.php` with the Laravel 13 attribute syntax. The `#[Fillable]` attribute keeps the configuration visible at the top of the file.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'gateway',
    'amount',
    'currency',
    'transaction_id',
    'status',
])]
class Payment extends Model
{
    protected $casts = [
        'amount' => 'float',
    ];
}
```

Run the migration so the SQLite database has the table.

```bash
php artisan migrate
```

The terminal output should look like this.

```

   INFO  Preparing database.

  Creating migration table .................................................. 5.21ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table .................................... 12.04ms DONE
  0001_01_01_000001_create_cache_table ..................................... 5.78ms DONE
  0001_01_01_000002_create_jobs_table ...................................... 8.33ms DONE
  2026_05_02_000000_create_payments_table .................................. 4.05ms DONE
```

## Step 3: Build the Bloated PaymentService {#step-3-build-the-bloated-paymentservice}

Now we deliberately write the code this article exists to refactor. Create a service class with an `if/elseif` dispatcher and one private method per gateway.

```bash
mkdir -p app/Services
```

Create `app/Services/PaymentService.php` with the following content. The two private gateway methods simulate calls to real payment providers, returning fake transaction data so we can write deterministic tests.

```php
<?php

namespace App\Services;

use InvalidArgumentException;

class PaymentService
{
    /**
     * Charge a customer through a given gateway. Returns the gateway's
     * response as an associative array.
     */
    public function charge(string $gateway, float $amount, string $currency): array
    {
        // Open/Closed Principle violation: every new gateway means a new branch here.
        if ($gateway === 'paypal') {
            return $this->chargePaypal($amount, $currency);
        } elseif ($gateway === 'stripe') {
            return $this->chargeStripe($amount, $currency);
        } else {
            throw new InvalidArgumentException("Unsupported gateway: {$gateway}");
        }
    }

    /**
     * Pretend to call the PayPal API. In a real app this would hit
     * https://api.paypal.com and return the parsed response.
     */
    private function chargePaypal(float $amount, float|string $currency): array
    {
        return [
            'transaction_id' => 'PP-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => 'paypal',
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }

    /**
     * Pretend to call the Stripe API.
     */
    private function chargeStripe(float $amount, string $currency): array
    {
        return [
            'transaction_id' => 'ST-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => 'stripe',
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

The smell is the dispatcher. Every new gateway will mean adding a new `elseif`, a new private method, and reading the entire file again to understand what changed. The class is closed to nothing; every change reopens it.

Now wire up the controller that exposes the service over HTTP. Create the controller with Artisan.

```bash
php artisan make:controller PaymentController
```

Open `app/Http/Controllers/PaymentController.php` and replace its body with the following.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private PaymentService $service) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'gateway'  => 'required|string',
            'amount'   => 'required|numeric|min:0.01',
            'currency' => 'required|string|size:3',
        ]);

        $result = $this->service->charge(
            gateway:  $validated['gateway'],
            amount:   $validated['amount'],
            currency: $validated['currency'],
        );

        $payment = Payment::create($result);

        return response()->json($payment, 201);
    }
}
```

Finally register the route. Open `routes/web.php` and add the following.

```php
use App\Http\Controllers\PaymentController;

Route::post('/payments', [PaymentController::class, 'store'])->name('payments.store');
```

## Step 4: Write the Pest Tests {#step-4-write-the-pest-tests}

The tests assert the public HTTP behavior plus a couple of unit-level checks against the service. They will pass against the bloated version and continue to pass after the refactor. Generate the test file.

```bash
php artisan make:test PaymentChargeTest --pest
```

Open `tests/Feature/PaymentChargeTest.php` and replace its body with the following.

```php
<?php

use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('rejects requests without required fields', function () {
    $this->postJson('/payments', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['gateway', 'amount', 'currency']);
});

it('charges a customer through the paypal gateway', function () {
    $this->postJson('/payments', [
            'gateway'  => 'paypal',
            'amount'   => 100.00,
            'currency' => 'USD',
        ])
         ->assertStatus(201)
         ->assertJsonPath('gateway', 'paypal')
         ->assertJsonPath('amount', 100)
         ->assertJsonPath('currency', 'USD')
         ->assertJsonPath('status', 'succeeded');

    $payment = Payment::first();
    expect($payment->transaction_id)->toStartWith('PP-');
});

it('charges a customer through the stripe gateway', function () {
    $this->postJson('/payments', [
            'gateway'  => 'stripe',
            'amount'   => 49.99,
            'currency' => 'EUR',
        ])
         ->assertStatus(201)
         ->assertJsonPath('gateway', 'stripe')
         ->assertJsonPath('currency', 'EUR');

    $payment = Payment::first();
    expect($payment->transaction_id)->toStartWith('ST-');
});

it('throws when an unsupported gateway is requested', function () {
    $service = app(PaymentService::class);

    expect(fn () => $service->charge('unknown', 10.00, 'USD'))
        ->toThrow(InvalidArgumentException::class);
});

```

The last test deliberately exercises the service directly rather than through HTTP, so we can assert that the service rejects unsupported gateways without going through Laravel's request validation. After the refactor the service still rejects unsupported gateways, just through a different mechanism.

## Step 5: Run the Baseline Tests {#step-5-run-the-baseline-tests}

Run the tests so we have a green baseline to refactor against.

```bash
php artisan test
```

The output should look like this. Six tests pass: four new feature tests plus the two examples that ship with Laravel.

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                    0.01s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                          0.08s  
  ✓ it charges a customer through the paypal gateway                     0.03s  
  ✓ it charges a customer through the stripe gateway                     0.02s  
  ✓ it throws when an unsupported gateway is requested                   0.02s  

  Tests:    6 passed (18 assertions)
  Duration: 0.33s

```

Six tests passing, all green. This is the safety net for the refactor.

## Step 6: Define the PaymentGateway Contract {#step-6-define-the-paymentgateway-contract}

The contract is the abstraction that lets the service stay closed against new gateways. It is small on purpose, because the only thing the service needs to know about a gateway is its name and how to charge with it.

Create the contracts directory and the interface file.

```bash
mkdir -p app/Contracts
```

Create `app/Contracts/PaymentGateway.php` with the following content.

```php
<?php

namespace App\Contracts;

interface PaymentGateway
{
    /**
     * The lowercase string identifier used to route requests to this gateway.
     * Examples: 'paypal', 'stripe', 'midtrans'.
     */
    public function name(): string;

    /**
     * Charge the given amount in the given currency. Returns the response
     * data from the underlying provider, normalized into a payment record
     * shape: gateway, amount, currency, transaction_id, status.
     *
     * @return array{gateway:string,amount:float,currency:string,transaction_id:string,status:string}
     */
    public function charge(float $amount, string $currency): array;
}
```

The interface declares only what the service truly needs. It does not add `refund`, `void`, or `capture` methods, even though real payment integrations support them. Adding them now would be speculative generality; if the business eventually needs refunds, we will design a separate contract for them in Article 5 (Interface Segregation).

## Step 7: Extract the PaypalGateway {#step-7-extract-the-paypalgateway}

Move the PayPal logic out of the service and into its own class that implements the contract.

```bash
mkdir -p app/Services/Payment/Gateways
```

Create `app/Services/Payment/Gateways/PaypalGateway.php` with the following content. The implementation is the same as the private method that used to live inside `PaymentService`, but now it is a first-class object with a stable identity.

```php
<?php

namespace App\Services\Payment\Gateways;

use App\Contracts\PaymentGateway;

class PaypalGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'paypal';
    }

    public function charge(float $amount, string $currency): array
    {
        // In a real integration this would call the PayPal HTTP API.
        return [
            'transaction_id' => 'PP-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => $this->name(),
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

## Step 8: Extract the StripeGateway {#step-8-extract-the-stripegateway}

Mirror the same extraction for Stripe. Create `app/Services/Payment/Gateways/StripeGateway.php` with the following content.

```php
<?php

namespace App\Services\Payment\Gateways;

use App\Contracts\PaymentGateway;

class StripeGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'stripe';
    }

    public function charge(float $amount, string $currency): array
    {
        return [
            'transaction_id' => 'ST-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => $this->name(),
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

The two gateway classes are nearly identical in shape but completely independent. A change to PayPal's logic does not affect Stripe, because they no longer share a file.

## Step 9: Refactor PaymentService to Use the Contract {#step-9-refactor-paymentservice-to-use-the-contract}

The service no longer needs to know about specific gateways. It accepts a collection of `PaymentGateway` implementations, indexes them by name, and delegates to whichever one matches the request.

Replace the contents of `app/Services/PaymentService.php` with the following.

```php
<?php

namespace App\Services;

use App\Contracts\PaymentGateway;
use InvalidArgumentException;

class PaymentService
{
    /**
     * @var array<string, PaymentGateway>
     */
    private array $gateways = [];

    /**
     * @param  iterable<PaymentGateway>  $gateways
     */
    public function __construct(iterable $gateways)
    {
        foreach ($gateways as $gateway) {
            $this->gateways[$gateway->name()] = $gateway;
        }
    }

    public function charge(string $gateway, float $amount, string $currency): array
    {
        if (!isset($this->gateways[$gateway])) {
            throw new InvalidArgumentException("Unsupported gateway: {$gateway}");
        }

        return $this->gateways[$gateway]->charge($amount, $currency);
    }

    /**
     * Public for tests and diagnostics: returns the names of registered gateways.
     *
     * @return array<int, string>
     */
    public function supported(): array
    {
        return array_keys($this->gateways);
    }
}
```

The service is now closed against gateway-specific changes. Adding PayPal v2, replacing Stripe with a fork, or removing a gateway entirely all happen outside this file.

The remaining piece is wiring: how does the service receive its iterable of gateways? Laravel's service container has a built-in mechanism called tagging that fits this pattern exactly. Open `app/Providers/AppServiceProvider.php` and update the `register` method to tag the gateways and bind the service.

```php
<?php

namespace App\Providers;

use App\Contracts\PaymentGateway;
use App\Services\Payment\Gateways\PaypalGateway;
use App\Services\Payment\Gateways\StripeGateway;
use App\Services\PaymentService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Register every gateway implementation under a shared tag.
        $this->app->tag([
            PaypalGateway::class,
            StripeGateway::class,
        ], 'payment.gateways');

        // Resolve the service with all tagged gateways injected as an iterable.
        $this->app->singleton(PaymentService::class, function ($app) {
            return new PaymentService($app->tagged('payment.gateways'));
        });
    }

    public function boot(): void
    {
        //
    }
}
```

Tagging is Laravel's idiomatic answer to "I have a registry of strategies and I want to inject all of them somewhere". The service does not import individual gateway classes; it only imports the contract. The service provider is the single place where the list of available gateways is configured. That makes the service provider the right place to extend, and the service itself stays closed.

Run the tests now to verify the refactor preserved behavior.

```bash
php artisan test
```

The output should show the same six tests passing, with the new wiring in place.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.06s

   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                                                                                                                                                        0.20s
  ✓ it charges a customer through the paypal gateway                                                                                                                                                   0.04s
  ✓ it charges a customer through the stripe gateway                                                                                                                                                   0.03s
  ✓ it throws when an unsupported gateway is requested                                                                                                                                                 0.02s

  Tests:    6 passed (12 assertions)
  Duration: 0.42s
```

Same six passing tests, same assertion count. The refactor preserved behavior. The next step proves the value of that refactor.

## Step 10: Add MidtransGateway Without Modifying Existing Code {#step-10-add-midtransgateway-without-modifying-existing-code}

Now we add a third gateway. The point of this step is what we do not have to touch: not the `PaymentService`, not the `PaymentGateway` contract, not the `PaypalGateway`, not the `StripeGateway`, not the `PaymentController`, and not the existing tests. We only add new files and one line to the service provider's tag list.

Create `app/Services/Payment/Gateways/MidtransGateway.php` with the following content.

```php
<?php

namespace App\Services\Payment\Gateways;

use App\Contracts\PaymentGateway;

class MidtransGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'midtrans';
    }

    public function charge(float $amount, string $currency): array
    {
        return [
            'transaction_id' => 'MT-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => $this->name(),
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

Now register it in the service provider's tag list. This is the single line of modification we do allow, because the service provider is the documented configuration point for gateway extension. Open `app/Providers/AppServiceProvider.php` and update the tag call.

The old `register` method had two gateways tagged.

```php
$this->app->tag([
    PaypalGateway::class,
    StripeGateway::class,
], 'payment.gateways');
```

Replace it with three.

```php
$this->app->tag([
    PaypalGateway::class,
    StripeGateway::class,
    MidtransGateway::class,                 // newly added line
], 'payment.gateways');
```

Add the `use` statement at the top of the file as well.

```php
use App\Services\Payment\Gateways\MidtransGateway;
```

To prove the new gateway works, add Pest tests for it. Open `tests/Feature/PaymentChargeTest.php` and append the following two tests at the bottom of the file.

```php
it('charges a customer through the midtrans gateway', function () {
    $this->postJson('/payments', [
            'gateway'  => 'midtrans',
            'amount'   => 250000.00,
            'currency' => 'IDR',
        ])
         ->assertStatus(201)
         ->assertJsonPath('gateway', 'midtrans')
         ->assertJsonPath('currency', 'IDR');

    $payment = Payment::first();
    expect($payment->transaction_id)->toStartWith('MT-');
});

it('reports midtrans as a supported gateway after registration', function () {
    $service = app(\App\Services\PaymentService::class);

    expect($service->supported())->toContain('midtrans');
});
```

## Step 11: Run All Tests Again {#step-11-run-all-tests-again}

Run the full suite. The four original payment tests still pass, and the two new midtrans tests pass too, for a total of eight tests.

```bash
php artisan test
```

Your output should look like this.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.06s

   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                                                                                                                                                        0.20s
  ✓ it charges a customer through the paypal gateway                                                                                                                                                   0.04s
  ✓ it charges a customer through the stripe gateway                                                                                                                                                   0.03s
  ✓ it throws when an unsupported gateway is requested                                                                                                                                                 0.02s
  ✓ it charges a customer through the midtrans gateway                                                                                                                                                 0.04s
  ✓ it reports midtrans as a supported gateway after registration                                                                                                                                      0.02s

  Tests:    8 passed (16 assertions)
  Duration: 0.51s
```

That is the proof of OCP value. We added a new payment method by writing one new file and adding one line to the service provider. We did not modify any class that already had passing tests, and none of the original tests changed.

## Understanding Open/Closed Principle {#understanding-open-closed-principle}

The Open/Closed Principle says software entities should be open for extension but closed for modification. The first time you read it the wording sounds contradictory; once you have done the refactor above, the meaning lands.

"Closed for modification" means existing tested code stays untouched when new behavior is added. Notice the qualifier: existing tested code. The service provider is not closed; it is the configuration point where the registry of gateways is updated. That is fine because the service provider does not contain logic that gets tested for correctness in the same way `PaymentService` does. Configuration and orchestration have a different change profile from algorithms and business rules.

"Open for extension" means new behavior gets added by writing new code, not by editing old code. In this article, the new behavior is a third gateway, and it lived entirely in two places: a new gateway class and a new line in the configuration list. Both are additive, and both are exactly the kinds of change we expected from the start. The system absorbed the change without any ripple.

The pre-refactor design failed both halves of the principle. Adding a new gateway required modifying `PaymentService` (not closed), and you could not add a new gateway purely by writing new code (not open). The post-refactor design satisfies both halves, but only for the kind of extension the contract anticipates: another gateway with the same `charge` signature. If a new requirement breaks the shape of `charge` itself, OCP cannot help you absorb that without revisiting the contract. That is fine; it is the honest limit of the principle. OCP is about closing the predictable changes, not all changes.

A useful diagnostic for whether code satisfies OCP is to ask: when this requirement changes in the way you expect it to, do you add a file or do you edit one? If you edit one, look harder. There is usually a contract waiting to be extracted.

## How Laravel Helps Apply OCP {#how-laravel-helps-apply-ocp}

Laravel was built by people who internalized OCP, and several of its features are direct expressions of the principle. Recognizing them helps you apply OCP in your own code without inventing infrastructure that already exists.

Notification channels are the clearest example. The `Notification` class has a `via` method that returns a list of channel names. Each channel is a class with a `send` method, registered with the framework. Adding a new channel (Slack, Discord, in-app database, custom webhook) means writing a new channel class; no existing notification logic is modified. That is OCP applied to user communication.

Broadcast drivers, queue drivers, cache stores, session drivers, and filesystem disks all follow the same pattern. They are configured in arrays inside `config/*.php`, resolved through factory classes that produce concrete drivers, and extensible by registering custom drivers in a service provider. When you write `Cache::extend('my-driver', ...)`, you are using the OCP design Laravel ships with. The cache code itself stays closed; you are extending it with new code.

Tagged services, used in the refactor above, are the most general-purpose tool Laravel offers for OCP. Any time you have a "registry of strategies" pattern (payment gateways, report generators, search indexers, file importers), tags give you a clean way to plug new strategies in by adding to a tag list, without modifying the consumer of those strategies.

The lesson: before inventing your own factory or strategy infrastructure, look at how Laravel already solves the same problem in its core. There is almost always a pattern you can match, and matching it makes your extensible code immediately readable to any other Laravel developer.

## Conclusion {#conclusion}

The Open/Closed Principle is the SOLID principle most directly tied to long-term codebase health. SRP makes individual classes easier to read; OCP makes the codebase as a whole safer to grow. A team that respects OCP can ship the tenth payment gateway as confidently as the second, because the existing tests and the existing classes never lit up during the change.

Here are the key takeaways from this refactor to carry forward:

- **The smell is the dispatcher.** An `if/elseif` chain or a `match` over type strings is the most reliable indicator of an OCP violation. Every new branch is a guaranteed modification to the existing code.
- **Closed means existing tested code does not change.** Adding a third gateway in this article required zero modifications to `PaymentService`, the contract, the existing gateways, or their tests. That is the standard to aim for.
- **Open means new behavior arrives as new code.** The MidtransGateway came as a new file plus one line in a tag list. No old logic was edited.
- **The configuration point is allowed to grow.** A service provider that tags more classes as new gateways are added is not a violation; it is the documented extension surface. Distinguish between "configuration grows additively" and "logic is modified".
- **Use Laravel's tagging mechanism for strategy registries.** Tags are built exactly for this case and integrate with the container's resolution. Reaching for a custom factory pattern is usually unnecessary when tags will do.
- **OCP closes predictable changes, not all changes.** If a requirement breaks the shape of the contract itself, the contract has to evolve. That is the honest limit. Aim for closure against the changes you can already see coming.
- **OCP depends on LSP.** The whole design assumes any `PaymentGateway` implementation behaves correctly when substituted for any other. The next article exposes what happens when that assumption breaks.

In Article 4 we will take on the Liskov Substitution Principle by exposing how subclasses can pass type checks while silently breaking the contract their parent class promised. The case study is a notification sender hierarchy where one of the senders truncates messages, another throws the wrong exception type, and a third returns the wrong shape. Pest will catch each violation, and we will fix them one at a time.