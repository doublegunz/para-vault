## 1. Before You Begin

Lesson 3 ended with a thread deliberately left hanging. Adding the `LOYAL5` discount code meant opening `InvoiceCalculator`, a class that was already written, already tested, and already working, and editing it. That was a far better outcome than editing a ninety line controller, but it was still an edit to working code, and every edit to working code is a chance to break it.

Now scale that up. Picture a `PaymentService` that has been in production for two years. It started with Paypal. Then Stripe was added, then Midtrans, then a wallet, then a coupon system. Each addition was a new branch in the same `if/elseif` chain and a new private method in the same file. The file is now four hundred lines, nobody remembers which branches are still reachable, and adding the next gateway means re-running the entire payment test suite to prove you did not disturb the five gateways that already worked. The code is not wrong. It is just permanently open.

The Open/Closed Principle is the fix, and it is the principle most directly tied to long term codebase health. SRP makes an individual class easier to read; OCP makes the codebase as a whole safer to grow. A team that respects it ships the tenth payment gateway as confidently as the second.

### What You'll Build

A payment charging endpoint in SolidLab that starts as a `PaymentService` with an `if/elseif` dispatcher for Paypal and Stripe. You will cover it with Pest tests, refactor it behind a `PaymentGateway` contract with one class per provider, wire it up using Laravel's container tagging, and then add Midtrans as a third gateway without editing a single existing class.

### What You'll Learn

- ✅ How to recognize a dispatcher as the most reliable smell of an OCP violation
- ✅ How to design a contract that declares only what its consumer actually needs
- ✅ How to turn a service into a registry that indexes implementations by name
- ✅ How to use Laravel's `tag()` and `tagged()` container methods for strategy registries
- ✅ Why a service provider growing a line is not a violation but a service growing a branch is
- ✅ Where the honest limit of OCP lies, and why it cannot close every kind of change

### What You'll Need

- SolidLab with Lesson 3 complete, including `app/Services` and `app/Contracts`
- The invoice feature passing its tests, since you will confirm at the end that this lesson did not disturb it
- Familiarity with PHP interfaces and constructor injection

---

## 2. Set Up the Payment Domain

The domain stays small on purpose. One table records what was charged, through which gateway, in which currency, and what transaction ID came back. All of the interesting design pressure lives in the service, not in the schema.

### Step 1: Generate the Model and Migration

```bash
php artisan make:model Payment -m
```

### Step 2: Define the Payments Table

Open the generated migration in `database/migrations/` and replace its contents.

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
            $table->string('gateway');
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3);
            $table->string('transaction_id')->unique();
            $table->string('status')->default('succeeded');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
```

`gateway` stores the provider name as a string, which is what makes the eventual registry lookup possible. `currency` is fixed at three characters for ISO codes like USD, EUR, and IDR. `transaction_id` is unique because a payment provider never issues the same ID twice, and letting the database enforce that catches a whole class of double charge bug. `status` defaults to `succeeded` because this lesson simulates only the happy path; a real integration would need pending and failed states.

### Step 3: Configure the Payment Model

Open `app/Models/Payment.php` and replace its body.

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

Same shape as the `Invoice` model from Lesson 3: the `#[Fillable]` attribute declares the mass assignable columns above the class, and the float cast makes sure `amount` comes back from SQLite as a number rather than a decimal string.

The five fillable keys are exactly the five keys a gateway will return. That is not a coincidence, and it is worth remembering when you read the contract in section 5.

### Step 4: Run the Migration

```bash
php artisan migrate
```

```
   INFO  Running migrations.  

  2026_08_18_151452_create_payments_table ....................... 13.04ms DONE
```

---

## 3. Build the Dispatcher You Will Delete

Write the version with the problem in it. As in Lesson 3, the discomfort is the teaching tool: a refactor only means something once you have felt why the starting point does not scale.

### Step 1: Write the PaymentService With an if/elseif Chain

Create `app/Services/PaymentService.php` with the following content. The two private methods stand in for real HTTP calls to the providers, returning deterministic fake responses so the tests do not need a network.

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
     * Pretend to call the PayPal API. In a real app this would call
     * the PayPal HTTP endpoint and return the parsed response.
     */
    private function chargePaypal(float $amount, string $currency): array
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

The `charge` method is the smell, and the comment names it. Everything else in the file is fine: the two private methods each do one job and would be perfectly acceptable as extracted classes.

The problem is structural. To add Midtrans you must open this file, add an `elseif`, add a private method, and then re-read the whole thing to be sure your branch did not disturb the two that already worked. Three gateways make that annoying. Ten make it dangerous. The class is closed to nothing: every single change reopens it.

Note also that this class is perfectly SRP compliant by Lesson 3's standard. One actor, the payments team, owns all of it. SRP has nothing to say about this design, which is a useful reminder that the five principles catch different problems and that satisfying one tells you nothing about the others.

### Step 2: Write the Controller

```bash
php artisan make:controller PaymentController
```

Open `app/Http/Controllers/PaymentController.php` and replace its body.

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

The controller is already thin, following Lesson 3's pattern: validate, delegate, persist, respond. This file will not change once in this entire lesson, which is itself part of the point. Passing the gateway result straight into `Payment::create` works because the array keys the service returns match the model's fillable list exactly.

### Step 3: Register the Route

Open `routes/web.php` and add the payments route alongside the invoices one from Lesson 3.

```php
<?php

use App\Http\Controllers\InvoiceController;
use App\Http\Controllers\PaymentController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/invoices', [InvoiceController::class, 'store'])->name('invoices.store');
Route::post('/payments', [PaymentController::class, 'store'])->name('payments.store');
```

---

## 4. Write the Tests and Capture a Baseline

As in Lesson 3, the tests assert public behavior so they can survive a structural change. Three of them drive the HTTP endpoint. The fourth reaches the service directly, for a reason worth understanding before you write it.

### Step 1: Create the Test File

```bash
php artisan make:test PaymentChargeTest --pest
```

### Step 2: Write Four Tests

Open `tests/Feature/PaymentChargeTest.php` and replace its body.

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

    expect(Payment::first()->transaction_id)->toStartWith('PP-');
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

    expect(Payment::first()->transaction_id)->toStartWith('ST-');
});

it('throws when an unsupported gateway is requested', function () {
    $service = app(PaymentService::class);

    expect(fn () => $service->charge('unknown', 10.00, 'USD'))
        ->toThrow(InvalidArgumentException::class);
});
```

The transaction ID prefix assertions are doing quiet but important work. `PP-` and `ST-` are the only observable difference between the two gateways, so asserting on the prefix is how the test proves that the right provider handled the charge. After the refactor the prefixes are produced by two separate classes instead of two private methods, and the same assertion still holds, which is exactly the property a refactor safety net needs.

The last test bypasses HTTP deliberately. Sending an unsupported gateway name through the endpoint would be caught by request validation before reaching the service, so testing it over HTTP would test the validator, not the dispatcher. Calling `app(PaymentService::class)` resolves the service from the container and exercises its own rejection path. Note that the test asserts only the exception type, not the message, which leaves the message free to improve later; Exercise 2 takes advantage of that.

`expect(fn () => ...)->toThrow(...)` wraps the call in a closure so Pest can invoke it and catch what comes out.

### Step 3: Run the Baseline

```bash
php artisan test tests/Feature/PaymentChargeTest.php
```

```
   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it charges a customer through the paypal gateway                     0.03s  
  ✓ it charges a customer through the stripe gateway                     0.02s  
  ✓ it throws when an unsupported gateway is requested                   0.02s  

  Tests:    4 passed (16 assertions)
  Duration: 0.32s
```

**4 passed, 16 assertions.** That is the contract for the refactor.

---

## 5. Define the Contract

The contract is the abstraction that lets the service stay closed. Getting its size right is the whole design decision, so it is worth pausing on before writing the file.

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

Two methods. `charge()` is the obvious one. `name()` is the interesting one: it moves the gateway's string identity from the dispatcher into the gateway itself. In the old design, `PaymentService` held the knowledge that the string `'paypal'` meant the PayPal branch. Now each implementation declares its own name, which is why the service will be able to build its routing table without knowing a single concrete class.

What is not in the contract matters as much as what is. Real payment integrations support refunds, voids, captures, and webhooks. None of those appear here, because nothing in this application needs them yet. Adding them now would be speculative generality: every implementation would be forced to provide methods no caller uses, which is a violation of the Interface Segregation Principle waiting to be discovered in Lesson 6. Design the contract for the consumer you have.

The docblock on `charge()` is not decoration either. The array shape it declares is a promise every implementation must keep, and `PaymentController` depends on that promise when it passes the result straight into `Payment::create`. PHP cannot enforce an array shape at runtime, so the docblock plus static analysis is the enforcement you get. Lesson 5 is entirely about what happens when an implementation quietly breaks a promise like this one.

---

## 6. Extract One Class per Gateway

Each branch of the old dispatcher becomes a class. The logic inside them is unchanged; what changes is that each one now has an identity, a file, and a life independent of its siblings.

### Step 1: Create the Gateways Directory

```bash
mkdir -p app/Services/Payment/Gateways
```

The nesting keeps the gateway implementations together and away from the general purpose services from Lesson 3. Any depth of directory maps to a matching namespace under the existing PSR-4 root.

### Step 2: Extract the PaypalGateway

Create `app/Services/Payment/Gateways/PaypalGateway.php`.

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

The body of `charge()` is the old `chargePaypal()` with one change: `'gateway' => 'paypal'` became `'gateway' => $this->name()`. That removes a duplicated literal, so the gateway's identity is now stated exactly once in the class. Rename the gateway later and there is one line to edit.

### Step 3: Extract the StripeGateway

Create `app/Services/Payment/Gateways/StripeGateway.php`.

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

The two classes have nearly the same shape and are now completely independent. When PayPal changes its API next quarter, the diff touches one file, and Stripe's tests cannot possibly be affected because Stripe's code is not in that file. In the old design both lived in the same class, so every PayPal change put Stripe's tests in the blast radius, even if only psychologically.

---

## 7. Turn the Service Into a Registry

The service no longer needs to know that PayPal or Stripe exist. It needs to know that gateways exist, that each one can state its name, and that one of them should handle the request.

### Step 1: Rewrite PaymentService

Replace the contents of `app/Services/PaymentService.php`.

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
        if (! isset($this->gateways[$gateway])) {
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

The constructor does the work that used to be spread across the dispatcher. It walks the gateways it is handed and builds a lookup table keyed by each gateway's own `name()`. Because the keys come from the implementations rather than from a hardcoded list, this loop needs no changes when a gateway is added, removed, or renamed.

`charge()` is now four lines: check the table, throw if the key is missing, delegate. The `if` that remains is not a dispatcher. A dispatcher grows a branch per implementation; this one is a single guard clause whose shape is fixed no matter how many gateways exist. That distinction is the practical test for whether you have actually applied OCP or merely moved code around.

`supported()` exists for diagnostics and tests. It also turns out to be useful for error messages, which Exercise 2 explores.

The `iterable` type hint on the constructor rather than `array` is deliberate, and section 7 step 2 explains why.

### Step 2: Wire It Up With Container Tagging

The service now expects an iterable of gateways, and something has to supply it. Laravel's container has a built in mechanism for exactly this shape of problem.

Open `app/Providers/AppServiceProvider.php` and replace its contents.

```php
<?php

namespace App\Providers;

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

`tag()` associates a list of class names with a label. It does not instantiate anything; it records an association. `tagged()` returns every class registered under that label, resolved through the container. What it returns is a lazy generator rather than an array, which is why `PaymentService` type hints `iterable`: gateways are only instantiated as the constructor loop reaches them, so a gateway that is registered but never used in a given request costs nothing.

`singleton()` registers the service so it is built once per request and reused. Without it, every injection point would rebuild the registry from scratch.

Read the imports on this file and on `PaymentService` side by side. The provider knows about concrete gateway classes and nothing about the contract. The service knows about the contract and nothing about concrete gateways. That separation is what "closed for modification" buys: the list of gateways lives in exactly one place, and it is a configuration file rather than a logic file.

### Step 3: Confirm the Refactor Preserved Behavior

Run the same command as the baseline, with the test file untouched.

```bash
php artisan test tests/Feature/PaymentChargeTest.php
```

```
   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it charges a customer through the paypal gateway                     0.04s  
  ✓ it charges a customer through the stripe gateway                     0.02s  
  ✓ it throws when an unsupported gateway is requested                   0.02s  

  Tests:    4 passed (16 assertions)
  Duration: 0.33s
```

Four passed, sixteen assertions, matching the baseline exactly. The dispatcher is gone and the endpoint behaves identically. Now comes the part that shows what the refactor was for.

---

## 8. Add a Third Gateway Without Editing Anything

This is the payoff section, and the interesting content is the list of files you will not open: not `PaymentService`, not `PaymentGateway`, not `PaypalGateway`, not `StripeGateway`, not `PaymentController`, and not one line of the four existing tests.

### Step 1: Write the MidtransGateway

Create `app/Services/Payment/Gateways/MidtransGateway.php`.

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

A new file that implements the contract. Nothing about it required reading the service, because the contract told it everything it needed to know.

### Step 2: Register It in the Tag List

This is the one modification the design permits. Open `app/Providers/AppServiceProvider.php`, add the import, and add the class to the tag list.

```php
use App\Services\Payment\Gateways\MidtransGateway;
use App\Services\Payment\Gateways\PaypalGateway;
use App\Services\Payment\Gateways\StripeGateway;
```

```php
$this->app->tag([
    PaypalGateway::class,
    StripeGateway::class,
    MidtransGateway::class,
], 'payment.gateways');
```

It is worth being precise about why this does not violate the principle. "Closed for modification" is about existing tested logic, and a tag list is not logic; it is a declaration of what exists. Its change profile is additive, its failure mode is loud (a missing gateway fails immediately and obviously), and no algorithm inside it can be subtly broken by adding a line. The service provider is the documented extension surface, and every extensible system needs one. What matters is that configuration grew while logic stayed still.

### Step 3: Prove It Works

Append two tests to the bottom of `tests/Feature/PaymentChargeTest.php`. Note that you are adding tests, not editing existing ones; the original four stay exactly as written.

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

    expect(Payment::first()->transaction_id)->toStartWith('MT-');
});

it('reports midtrans as a supported gateway after registration', function () {
    $service = app(PaymentService::class);

    expect($service->supported())->toContain('midtrans');
});
```

The first test is the end to end proof: a currency and amount plausible for the Indonesian market go in, and a Midtrans transaction ID comes back. The second checks the registration itself rather than the charge, which is a genuinely different failure. A gateway class can be written correctly and simply never reach the tag list, in which case charging through it returns a 500 and the reason is not obvious. Asserting on `supported()` turns that mistake into a clear failure.

---

## 9. Run and Test

```bash
php artisan test tests/Feature/PaymentChargeTest.php
```

```
   PASS  Tests\Feature\PaymentChargeTest
  ✓ it rejects requests without required fields                          0.17s  
  ✓ it charges a customer through the paypal gateway                     0.04s  
  ✓ it charges a customer through the stripe gateway                     0.02s  
  ✓ it throws when an unsupported gateway is requested                   0.02s  
  ✓ it charges a customer through the midtrans gateway                   0.02s  
  ✓ it reports midtrans as a supported gateway after registration        0.02s  

  Tests:    6 passed (21 assertions)
  Duration: 0.36s
```

Six passed, twenty one assertions. The four original tests are still there and still green, and they were never edited.

Now account for the change honestly. Adding a payment provider to this system cost one new file and one line in a configuration list. The classes with the business logic in them were not opened. The tests that guard them were not opened. Compare that to the same change against the version in section 3, which would have meant editing the dispatcher, adding a private method, and re-reading a file that three other gateways also depend on.

Finally, confirm the invoice feature from Lesson 3 is undisturbed, since this lesson rewrote `AppServiceProvider` and `routes/web.php`.

```bash
php artisan test tests/Feature/InvoiceCreationTest.php
```

This is the other use of the full suite that Lesson 2 described: scoped runs prove a refactor preserved behavior, and a wider run proves it did not leak into a neighbouring feature area.

---

## 10. Understanding the Open/Closed Principle

Having done the refactor, the paradox in the wording resolves.

"Closed for modification" means existing tested code stays untouched when new behavior arrives. The qualifier is doing real work: *existing tested* code. The service provider is not closed, and that is by design. It holds no algorithm whose correctness is being asserted anywhere; it is a manifest. Configuration and orchestration have a different change profile from business rules, and OCP is aimed at the second.

"Open for extension" means new behavior arrives as new code. Here it arrived as `MidtransGateway.php` plus a line in a list, both additive, both exactly the kind of change the design anticipated.

The design in section 3 failed both halves at once. Adding a gateway required modifying `PaymentService`, so it was not closed. You could not add a gateway purely by writing new code, so it was not open. Those are two views of the same defect: without an abstraction, extension and modification are the same operation.

The honest limit is worth stating plainly. The post refactor design is closed only against the extension the contract anticipates, which is another provider with the same `charge` signature. If Midtrans needs a two step flow where you create a transaction, redirect the customer to a hosted page, and confirm on a webhook, that does not fit `charge(float, string): array`, and no amount of OCP discipline in the current design will absorb it. The contract would have to evolve. That is not a failure of the principle; it is the principle's actual scope. OCP closes predictable changes, not all changes, and pretending otherwise is how codebases end up with abstractions that nobody can explain.

The diagnostic that transfers to your own code: when this requirement changes in the way you expect it to, do you add a file or edit one? If the answer is edit, there is usually a contract waiting to be extracted. If the answer is add, you are done.

---

## 11. How Laravel Already Does This

Laravel was built by people who internalized OCP, and recognizing the pattern in the framework saves you from inventing infrastructure that already ships.

Notification channels are the clearest case. A `Notification` has a `via()` method returning channel names, and each channel is a class registered with the framework. Adding Slack, Discord, or a custom webhook means writing a channel class; no existing notification is modified. That is exactly the design you just built, applied to user communication.

Cache stores, queue connections, session drivers, broadcast drivers, and filesystem disks all follow the same shape: a config array names what is available, a factory resolves the name into a concrete driver, and a service provider can register new drivers. When you call `Cache::extend('my-driver', ...)`, you are extending closed framework code with new code of your own, without a line of the cache internals changing.

Container tagging, which you used in section 7, is the most general purpose of these tools. Any time you find yourself with a registry of interchangeable strategies (report generators, search indexers, file importers, export formats, payment gateways), tags give you a clean way to plug new ones in without the consumer knowing they exist.

The practical advice: before writing your own factory or strategy infrastructure, look at how the framework solves the same problem internally. Matching an existing pattern makes your extensible code immediately legible to every other Laravel developer who reads it.

---

## 12. Fix the Errors in Your Code

These three mistakes account for most of the trouble during this specific refactor.

**Error 1: Type hinting `array` on the constructor instead of `iterable`.**

The refactor looks finished, and every payment test fails with a `TypeError` before any of your logic runs.

```php
// Wrong: tagged() returns a generator, which is not an array
public function __construct(array $gateways)
{
    foreach ($gateways as $gateway) {
        $this->gateways[$gateway->name()] = $gateway;
    }
}

// Correct: iterable accepts both arrays and generators
public function __construct(iterable $gateways)
{
    foreach ($gateways as $gateway) {
        $this->gateways[$gateway->name()] = $gateway;
    }
}
```

`$app->tagged()` returns a lazy generator so tagged services are only instantiated as they are iterated. The `foreach` works identically either way, so the only thing standing between you and a working refactor is the type hint. If you genuinely need an array, `iterator_to_array($app->tagged('payment.gateways'))` at the call site converts it, but you lose the laziness for no benefit.

**Error 2: Writing a gateway class and forgetting to tag it.**

The class exists, implements the contract, and looks completely correct. Charging through it throws `Unsupported gateway`, which points suspiciously at the service, where nothing is wrong.

```php
// Wrong: the class exists but nothing ever told the container about it
// app/Services/Payment/Gateways/MidtransGateway.php created,
// AppServiceProvider untouched

// Correct: registration is a separate step from implementation
$this->app->tag([
    PaypalGateway::class,
    StripeGateway::class,
    MidtransGateway::class,
], 'payment.gateways');
```

This is the trade the design makes. Extension became additive, and the cost is that adding behavior now takes two steps rather than one, with the second easy to forget. That is precisely what the `supported()` assertion in section 8 is for: it converts a confusing runtime error into a named test failure.

**Error 3: Reintroducing the dispatcher inside a gateway.**

Two providers share most of their logic, so the temptation is to write one class that handles both and branches internally.

```php
// Wrong: the if/elseif came back, just relocated
class InternationalGateway implements PaymentGateway
{
    public function __construct(private string $provider) {}

    public function charge(float $amount, string $currency): array
    {
        if ($this->provider === 'paypal') {
            return $this->paypalPayload($amount, $currency);
        }

        return $this->stripePayload($amount, $currency);
    }
}

// Correct: one class per provider, sharing code through a base class or trait
abstract class HttpGateway implements PaymentGateway
{
    abstract protected function prefix(): string;

    public function charge(float $amount, string $currency): array
    {
        return [
            'transaction_id' => $this->prefix() . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => $this->name(),
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

Duplication between implementations is a real cost and worth removing, but branching on a type string is not the way to remove it. Share the code through inheritance or composition and keep one class per provider, so adding the next one is still purely additive. Be careful with the base class approach though: a subclass that changes what its parent promises is a Liskov violation, which is Lesson 5's entire subject.

---

## 13. Exercises

**Exercise 1:** Add a fourth gateway, `XenditGateway`, whose transaction IDs start with `XD-`. Before you start, write down the list of files you expect to touch. Afterwards, check your prediction. Add a test in a new file that charges 75000 IDR through it and asserts the prefix.

**Exercise 2:** The error message `Unsupported gateway: bogus` tells a developer nothing about what *is* supported. Improve it to list the registered gateways, using the `supported()` method. Then explain in one sentence why this edit to `PaymentService` is not an OCP violation, even though you opened a tested class to make it.

**Exercise 3:** Finance wants each gateway to declare which currencies it accepts, and the service to reject a charge in an unsupported currency before calling the provider. Sketch two designs: one that adds a method to the `PaymentGateway` contract, and one that does not. State which you would ship and why, referring to the honest limit described in section 10.

---

## 14. Solutions

**Solution for Exercise 1:**

Two files: one new gateway class, and one line plus one import in the provider. That is the same cost as Midtrans, and it stays the same cost for the tenth gateway, which is the property the refactor bought.

```php
<?php

namespace App\Services\Payment\Gateways;

use App\Contracts\PaymentGateway;

class XenditGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'xendit';
    }

    public function charge(float $amount, string $currency): array
    {
        return [
            'transaction_id' => 'XD-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'status'         => 'succeeded',
            'gateway'        => $this->name(),
            'amount'         => $amount,
            'currency'       => $currency,
        ];
    }
}
```

Add `XenditGateway::class` to the tag list and the matching `use` statement, then test it in a new file.

```php
it('charges a customer through the xendit gateway', function () {
    $this->postJson('/payments', [
            'gateway'  => 'xendit',
            'amount'   => 75000.00,
            'currency' => 'IDR',
        ])
         ->assertStatus(201)
         ->assertJsonPath('gateway', 'xendit');

    expect(Payment::first()->transaction_id)->toStartWith('XD-');
});
```

**Solution for Exercise 2:**

Build the message from `supported()` so it always reflects what is actually registered.

```php
public function charge(string $gateway, float $amount, string $currency): array
{
    if (! isset($this->gateways[$gateway])) {
        throw new InvalidArgumentException(sprintf(
            'Unsupported gateway [%s]. Supported: %s.',
            $gateway,
            implode(', ', $this->supported()),
        ));
    }

    return $this->gateways[$gateway]->charge($amount, $currency);
}
```

With four gateways registered, a bad request now produces `Unsupported gateway [bogus]. Supported: paypal, stripe, midtrans, xendit.`, which tells the developer both what went wrong and what the options are. Because the list is generated rather than hardcoded, it can never drift out of date.

The reason this is not an OCP violation is that the change was not driven by adding an implementation. OCP asks that a class stay closed against a *particular axis of change*, here the addition of gateways, and this edit is on a different axis: improving the service's own error reporting. A class is never closed against every change, and treating a tested file as permanently unopenable would be cargo cult rather than design.

Note that the existing test still passes without modification, because it asserted only the exception type and never the message. That was a deliberate choice back in section 4, and this is where it pays off.

**Solution for Exercise 3:**

The contract based design adds one method.

```php
interface PaymentGateway
{
    public function name(): string;

    /** @return array<int, string> */
    public function supportedCurrencies(): array;

    public function charge(float $amount, string $currency): array;
}
```

The service then checks before delegating, and every implementation must declare its currencies.

The alternative keeps the contract as it is and puts the rule in configuration, for example a `config/payments.php` map from gateway name to allowed currencies, which the service consults. No implementation changes at all.

Ship the contract version. The reason is where the knowledge belongs: which currencies a provider accepts is a fact about that provider, and facts about a provider belong in the provider's class, where they cannot drift out of sync with the integration. A config map is a second source of truth that nothing forces you to update when you add a gateway, which is exactly the failure this design was built to prevent.

The trade off is real and worth naming, because it is section 10's honest limit in miniature. Adding a method to the contract is a breaking change: every existing implementation must be updated, so the moment you make it, all four gateway classes need opening. The contract is not closed against its own evolution, and nothing can make it so. What you get in exchange is that the *next* gateway is additive again, and the compiler tells you immediately if it forgot to declare its currencies. Paying a one time cost across all implementations to keep future additions free is usually the right trade; paying it speculatively, before anyone has asked for the feature, is the over engineering section 5 warned about.

---

## Next Up - Lesson 5

You replaced a dispatcher with a registry. Adding a payment provider to SolidLab is now one new file and one line of configuration, and the classes holding the business logic stayed closed throughout. You also saw where the principle stops: a contract is closed against new implementations, never against changes to its own shape.

That design rests on an assumption nobody has checked yet. `PaymentService` calls `charge()` on whatever implementation the name lookup returns, and it trusts every one of them to behave the same way: to return the same array shape, to throw the same kinds of exception, to honor the same promises. The contract says so, but PHP enforces only the method signature. An implementation can satisfy every type hint and still lie about what it does.

In Lesson 5 you will build a notification sender hierarchy with three such lies planted in it: a sender that silently truncates long messages, one that throws an exception type its parent never declared, and one that returns a different shape than its siblings. All three pass type checks. All three survive code review. You will write tests that catch them, watch those tests fail, and fix each violation in turn. That is the Liskov Substitution Principle, and it is the principle that makes the design you just built trustworthy rather than merely tidy.
