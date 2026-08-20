## 1. Before You Begin

Every lesson so far handed you one problem at a time. Lesson 3 gave you a controller doing too much, and nothing else was wrong. Lesson 4 gave you a dispatcher, and the contract was already the right size. Lesson 6 gave you a fat interface, and the dependencies were already inverted. That isolation was deliberate, because you cannot learn to recognize a principle while four other things are also broken.

Real code does not arrive that way. You open a feature and find a controller doing six jobs, one of which calls a service that branches on a type string, which instantiates carriers implementing an interface most of them cannot honor, one of which quietly rounds a number in the wrong direction. All five problems, one afternoon, and the first real decision is not how to fix any of them but which to fix first and what to leave alone.

That decision is what this lesson is about. You will build a shipping dispatch feature carrying all five defects at once, diagnose them by name, and fix them in a deliberate order with a reason for the order. Then you will turn the whole course into a checklist short enough to actually use during code review.

### What You'll Build

A shipment dispatch endpoint in SolidLab: quote a parcel with a carrier, persist it, generate a shipping label, notify the customer. It starts with an SRP violation in the controller, an OCP violation in the service, an ISP violation in the carrier contract, an LSP violation in one carrier's pricing, and a DIP violation in the notifier. You will end with 8 passing tests, a bug found that the original suite could not see, and one violation deliberately left in place.

### What You'll Learn

- ✅ How to diagnose five simultaneous violations and name each one precisely
- ✅ Why correctness bugs get fixed before structural ones
- ✅ Why contracts get reshaped before registries are built on top of them
- ✅ How the five refactors compound rather than merely accumulate
- ✅ How to decide what not to refactor, and how to say why
- ✅ A code review checklist that fits on one screen

### What You'll Need

- SolidLab with Lessons 3 through 7 complete
- `AppServiceProvider` holding both the payment gateway tagging and the newsletter binding
- All five principles fresh enough that the names mean something without looking them up

---

## 2. Build the Feature With All Five Problems

Write the whole thing badly, in one pass, the way it would actually have been written: one carrier at first, then a second one bolted on, then a notifier added late under deadline. Do not fix anything as you go.

### Step 1: Generate the Model and Migration

```bash
php artisan make:model Shipment -m
php artisan make:controller ShipmentController
mkdir app/Shipping
```

Open the generated migration and replace its contents.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('shipments', function (Blueprint $table) {
            $table->id();
            $table->string('carrier');
            $table->string('destination');
            $table->decimal('weight_kg', 8, 2);
            $table->decimal('cost', 12, 2);
            $table->string('tracking_code')->unique();
            $table->string('label_path')->nullable();
            $table->string('status')->default('dispatched');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shipments');
    }
};
```

Then replace `app/Models/Shipment.php`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'carrier',
    'destination',
    'weight_kg',
    'cost',
    'tracking_code',
    'label_path',
    'status',
])]
class Shipment extends Model
{
    protected $casts = [
        'weight_kg' => 'float',
        'cost' => 'float',
    ];
}
```

Run the migration.

```bash
php artisan migrate
```

```
   INFO  Running migrations.  

  2026_08_18_153551_create_shipments_table ...................... 14.40ms DONE
```

### Step 2: Write the Fat Carrier Contract

Create `app/Contracts/Carrier.php`.

```php
<?php

namespace App\Contracts;

interface Carrier
{
    public function name(): string;

    /**
     * Quote the shipping cost in IDR.
     *
     * Contract: the quote MUST be computed from the exact weight given.
     */
    public function quote(float $weightKg, string $destination): float;

    public function createLabel(string $trackingCode): string;

    public function track(string $trackingCode): array;

    public function cancel(string $trackingCode): bool;

    public function insure(float $declaredValue): float;
}
```

Six methods, written the way a contract gets written when someone lists everything a shipping API might offer. Note the docblock on `quote`, because it is a promise that one implementation is about to break.

### Step 3: Write Two Carriers

Create `app/Shipping/JneCarrier.php`.

```php
<?php

namespace App\Shipping;

use App\Contracts\Carrier;
use BadMethodCallException;

class JneCarrier implements Carrier
{
    public const RATE_PER_KG = 10000.0;
    public const REMOTE_SURCHARGE = 25000.0;

    public function name(): string
    {
        return 'jne';
    }

    public function quote(float $weightKg, string $destination): float
    {
        $cost = $weightKg * self::RATE_PER_KG;

        if ($destination === 'remote') {
            $cost += self::REMOTE_SURCHARGE;
        }

        return round($cost, 2);
    }

    public function createLabel(string $trackingCode): string
    {
        return "LABEL[jne:{$trackingCode}]";
    }

    public function track(string $trackingCode): array
    {
        return ['code' => $trackingCode, 'status' => 'in_transit'];
    }

    // Forced stubs.

    public function cancel(string $trackingCode): bool
    {
        throw new BadMethodCallException('JNE shipments cannot be cancelled via the API');
    }

    public function insure(float $declaredValue): float
    {
        throw new BadMethodCallException('JNE does not expose insurance pricing');
    }
}
```

Create `app/Shipping/PosCarrier.php`.

```php
<?php

namespace App\Shipping;

use App\Contracts\Carrier;
use BadMethodCallException;

class PosCarrier implements Carrier
{
    public const RATE_PER_KG = 8000.0;
    public const REMOTE_SURCHARGE = 20000.0;

    public function name(): string
    {
        return 'pos';
    }

    public function quote(float $weightKg, string $destination): float
    {
        // LSP violation: the contract says quote from the exact weight.
        // Pos bills whole kilograms, so this quietly rounds down and
        // under-quotes every fractional parcel.
        $cost = floor($weightKg) * self::RATE_PER_KG;

        if ($destination === 'remote') {
            $cost += self::REMOTE_SURCHARGE;
        }

        return round($cost, 2);
    }

    public function createLabel(string $trackingCode): string
    {
        return "LABEL[pos:{$trackingCode}]";
    }

    // Forced stubs.

    public function track(string $trackingCode): array
    {
        throw new BadMethodCallException('Pos does not provide tracking');
    }

    public function cancel(string $trackingCode): bool
    {
        throw new BadMethodCallException('Pos shipments cannot be cancelled');
    }

    public function insure(float $declaredValue): float
    {
        throw new BadMethodCallException('Pos does not expose insurance pricing');
    }
}
```

Five stubs across two classes, and a `floor()` that costs the business money on every fractional parcel. The `floor()` is the kind of line that gets written by someone who correctly knew Pos bills whole kilograms and picked the wrong rounding direction on a Friday.

### Step 4: Write the Dispatcher Service

Create `app/Services/ShipmentService.php`.

```php
<?php

namespace App\Services;

use App\Shipping\JneCarrier;
use App\Shipping\PosCarrier;
use InvalidArgumentException;

class ShipmentService
{
    public function quote(string $carrier, float $weightKg, string $destination): float
    {
        // OCP violation: a new carrier means a new branch in this method.
        if ($carrier === 'jne') {
            return (new JneCarrier())->quote($weightKg, $destination);
        } elseif ($carrier === 'pos') {
            return (new PosCarrier())->quote($weightKg, $destination);
        }

        throw new InvalidArgumentException("Unsupported carrier: {$carrier}");
    }

    public function label(string $carrier, string $trackingCode): string
    {
        if ($carrier === 'jne') {
            return (new JneCarrier())->createLabel($trackingCode);
        } elseif ($carrier === 'pos') {
            return (new PosCarrier())->createLabel($trackingCode);
        }

        throw new InvalidArgumentException("Unsupported carrier: {$carrier}");
    }
}
```

Worse than Lesson 4's dispatcher, because the chain is duplicated. Adding a carrier means editing two branches in two methods, and forgetting one produces a feature that quotes correctly and cannot print a label.

### Step 5: Write the Notifier and Its Log

Create `app/Shipping/FakeDispatchLog.php`.

```php
<?php

namespace App\Shipping;

class FakeDispatchLog
{
    /** @var array<int, array{tracking_code:string,carrier:string,channel:string}> */
    public static array $entries = [];

    public static function record(string $trackingCode, string $carrier, string $channel): void
    {
        self::$entries[] = [
            'tracking_code' => $trackingCode,
            'carrier'       => $carrier,
            'channel'       => $channel,
        ];
    }

    public static function reset(): void
    {
        self::$entries = [];
    }

    /** @return array<int, array{tracking_code:string,carrier:string,channel:string}> */
    public static function all(): array
    {
        return self::$entries;
    }
}
```

Create `app/Shipping/EmailDispatchNotifier.php`.

```php
<?php

namespace App\Shipping;

class EmailDispatchNotifier
{
    public function notify(string $trackingCode, string $carrier): void
    {
        FakeDispatchLog::record($trackingCode, $carrier, 'email');
    }
}
```

Standing in for a real mailer, as in Lesson 5. The design problem is not what it does but that it implements no contract, so nothing can take its place.

### Step 6: Write the Controller That Does Everything

Replace `app/Http/Controllers/ShipmentController.php`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Shipment;
use App\Services\ShipmentService;
use App\Shipping\EmailDispatchNotifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ShipmentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        // Responsibility 1: validate
        $validated = $request->validate([
            'carrier'     => 'required|string',
            'destination' => 'required|string',
            'weight_kg'   => 'required|numeric|min:0.1',
        ]);

        // Responsibility 2: quote
        $service = new ShipmentService();
        $cost = $service->quote(
            carrier:     $validated['carrier'],
            weightKg:    $validated['weight_kg'],
            destination: $validated['destination'],
        );

        // Responsibility 3: mint a tracking code
        $trackingCode = strtoupper($validated['carrier']) . '-' . str_pad(
            (string) random_int(1, 999999), 6, '0', STR_PAD_LEFT
        );

        // Responsibility 4: persist
        $shipment = Shipment::create([
            'carrier'       => $validated['carrier'],
            'destination'   => $validated['destination'],
            'weight_kg'     => $validated['weight_kg'],
            'cost'          => $cost,
            'tracking_code' => $trackingCode,
        ]);

        // Responsibility 5: render and store the label
        $label = $service->label($validated['carrier'], $trackingCode);
        $labelPath = "labels/{$trackingCode}.txt";
        Storage::disk('local')->put($labelPath, $label);
        $shipment->update(['label_path' => $labelPath]);

        // Responsibility 6: notify the customer
        $notifier = new EmailDispatchNotifier();
        $notifier->notify($trackingCode, $validated['carrier']);

        // Responsibility 7: audit log
        Log::info("Shipment {$trackingCode} dispatched via {$validated['carrier']}");

        return response()->json($shipment->fresh(), 201);
    }
}
```

Seven numbered responsibilities and two `new` keywords, one of which constructs a service and one of which constructs an integration.

### Step 7: Register the Route

Add the shipments route to `routes/web.php`, alongside the three already there.

```php
Route::post('/shipments', [ShipmentController::class, 'store'])->name('shipments.store');
```

---

## 3. Cover It With Tests

Before diagnosing anything, get a safety net. Write the tests a competent developer would write for this feature without suspecting anything is wrong, because that is exactly what the original author would have written.

Create `tests/Feature/ShipmentDispatchTest.php`.

```php
<?php

use App\Models\Shipment;
use App\Shipping\FakeDispatchLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

beforeEach(function () {
    FakeDispatchLog::reset();
});

it('rejects requests without required fields', function () {
    $this->postJson('/shipments', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['carrier', 'destination', 'weight_kg']);
});

it('quotes a jne shipment from the exact weight', function () {
    Storage::fake('local');

    $this->postJson('/shipments', [
            'carrier'     => 'jne',
            'destination' => 'jakarta',
            'weight_kg'   => 2.5,
        ])
         ->assertStatus(201)
         ->assertJsonPath('carrier', 'jne')
         ->assertJsonPath('cost', 25000);
});

it('adds the remote surcharge', function () {
    Storage::fake('local');

    $this->postJson('/shipments', [
            'carrier'     => 'jne',
            'destination' => 'remote',
            'weight_kg'   => 1.0,
        ])
         ->assertStatus(201)
         ->assertJsonPath('cost', 35000);
});

it('writes a label file and records its path', function () {
    Storage::fake('local');

    $this->postJson('/shipments', [
            'carrier'     => 'jne',
            'destination' => 'jakarta',
            'weight_kg'   => 1.0,
        ])
         ->assertStatus(201);

    $shipment = Shipment::first();

    expect($shipment->label_path)->toBe("labels/{$shipment->tracking_code}.txt");
    Storage::disk('local')->assertExists($shipment->label_path);
});

it('notifies the customer that the shipment was dispatched', function () {
    Storage::fake('local');

    $this->postJson('/shipments', [
            'carrier'     => 'pos',
            'destination' => 'jakarta',
            'weight_kg'   => 3.0,
        ])
         ->assertStatus(201);

    $entries = FakeDispatchLog::all();

    expect($entries)->toHaveCount(1)
        ->and($entries[0]['carrier'])->toBe('pos')
        ->and($entries[0]['channel'])->toBe('email');
});
```

```bash
php artisan test tests/Feature/ShipmentDispatchTest.php
```

```
   PASS  Tests\Feature\ShipmentDispatchTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it quotes a jne shipment from the exact weight                       0.05s  
  ✓ it adds the remote surcharge                                         0.03s  
  ✓ it writes a label file and records its path                          0.03s  
  ✓ it notifies the customer that the shipment was dispatched            0.03s  

  Tests:    5 passed (17 assertions)
  Duration: 0.37s
```

**5 passed, 17 assertions**, and a money losing bug sitting in production.

Look at why the suite misses it. Fractional weights are tested only against JNE. Pos is tested only at 3.0 kg, where `floor()` changes nothing, and that test asserts on the notification rather than the cost. Neither omission is careless; both are the natural result of writing tests per scenario rather than per contract. Lesson 5's grid would have caught it on day one, which is the point.

---

## 4. Diagnose Before You Touch Anything

Resist opening an editor. Name the problems first, because the order you fix them in depends on what they are.

**SRP, in `ShipmentController::store`.** Seven responsibilities with seven different owners: product owns validation, operations owns carrier selection, finance owns pricing, engineering owns the schema, the warehouse owns label format, marketing owns the notification, compliance owns the audit line.

**OCP, in `ShipmentService`.** Two `if/elseif` chains over a carrier string, duplicated across two methods. Adding SiCepat means editing both, and forgetting one ships a carrier that can quote but not label.

**ISP, in `Carrier`.** Six methods, five stubs across two implementations. `cancel()` and `insure()` have zero working implementations anywhere.

**LSP, in `PosCarrier::quote`.** The contract says quote from the exact weight; this rounds down. A 2.5 kg parcel is billed as 2 kg, a 4000 IDR loss per parcel that no test can see.

**DIP, in the controller.** `new EmailDispatchNotifier()` welds a specific channel into the request handler. Switching to SMS means editing the controller, and no test can substitute a different notifier.

Now note what is *not* on the list. The `Shipment` model is fine: seven fillable columns, two casts, no behavior. The migration is fine. The route is fine. The validation rules are small and belong where they are. Refactoring is a budget, and spending it on files that are already correct is how a two hour cleanup becomes a two day one.

---

## 5. Fix LSP First

Correctness before structure. The other four defects make the code harder to change; this one makes it wrong. Restructuring around a bug preserves the bug and makes it harder to find afterwards.

### Step 1: Expose the Bug With a Contract Test

Write the test before the fix, so you can watch it fail. Create `tests/Feature/CarrierContractTest.php`.

```php
<?php

use App\Contracts\Carrier;
use App\Shipping\JneCarrier;
use App\Shipping\PosCarrier;

dataset('carriers', [
    'jne' => [fn () => new JneCarrier(), JneCarrier::RATE_PER_KG],
    'pos' => [fn () => new PosCarrier(), PosCarrier::RATE_PER_KG],
]);

it('quotes from the exact weight, without rounding', function (Carrier $carrier, float $rate) {
    expect($carrier->quote(2.5, 'jakarta'))->toBe(round(2.5 * $rate, 2));
})->with('carriers');
```

This is Lesson 5's technique applied to an interface rather than a base class: type hint the contract, run every implementation through it, assert what the contract promised.

```bash
php artisan test tests/Feature/CarrierContractTest.php
```

```
   FAIL  Tests\Feature\CarrierContractTest
  ✓ it quotes from the exact weight, without rounding with dataset "jne"                                         0.09s  
  ⨯ it quotes from the exact weight, without rounding with dataset "pos"                                         0.02s  
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  
   FAILED  Tests\Feature\CarrierContractTest > it quotes from the exact weight, without rounding with dataset "pos"     
  Failed asserting that 16000.0 is identical to 20000.0.
```

16000 against 20000. Four thousand rupiah per fractional parcel, quantified, with the responsible implementation named.

### Step 2: Decide Whether the Implementation or the Contract Is Wrong

The obvious fix is to delete the `floor()`. It is also the wrong fix, and working out why is the valuable part.

Pos genuinely does bill in whole kilograms. That is not a bug in the code, it is a fact about the carrier, and a `PosCarrier` that quotes 2.5 kg at exactly 2.5 times the rate would return a number the real Pos will never charge. The implementation was right about the domain and wrong about the direction.

So the contract is what is wrong. It said "the quote MUST be computed from the exact weight", which is a rule JNE happens to satisfy and Pos cannot. A contract that only its first implementation can honor is a contract written by looking at one implementation, which is the mistake Lesson 7 warned about from the other direction.

Rewrite the promise so it is true of every carrier while still forbidding the actual harm.

```php
/**
 * Quote the shipping cost in IDR.
 *
 * Contract: a carrier MAY round the billable weight up to match its own
 * pricing rules, but the returned cost MUST NEVER be lower than the cost
 * of the exact weight given.
 */
public function quote(float $weightKg, string $destination): float;
```

Then fix the direction in `PosCarrier::quote`.

```php
public function quote(float $weightKg, string $destination): float
{
    // Pos bills whole kilograms. Rounding up keeps the quote at or above
    // the exact-weight cost, which is what the contract requires.
    $cost = ceil($weightKg) * self::RATE_PER_KG;

    if ($destination === 'remote') {
        $cost += self::REMOTE_SURCHARGE;
    }

    return round($cost, 2);
}
```

One character changed, `floor` to `ceil`, and the business stops losing money. The contract change is the larger edit and the more important one, because it is what stops the next carrier author from guessing.

Update the test to assert the honest promise:

```php
it('never quotes below the exact weight cost', function (QuotesShipping $carrier, float $rate) {
    expect($carrier->quote(2.5, 'jakarta'))->toBeGreaterThanOrEqual(round(2.5 * $rate, 2));
})->with('carriers');

it('scales the quote with weight', function (QuotesShipping $carrier) {
    expect($carrier->quote(10.0, 'jakarta'))->toBeGreaterThan($carrier->quote(1.0, 'jakarta'));
})->with('carriers');
```

`toBeGreaterThanOrEqual` looks weaker than `toBe` and is actually stronger, because it is a claim every implementation must satisfy rather than one that happened to hold for the first one written. The second test adds back some of the precision the relaxation gave up: whatever rounding a carrier applies, more weight must not cost less. The `QuotesShipping` type hint comes from section 6; if you are following along in order, use `Carrier` here and change it in a moment.

---

## 6. Fix ISP Second

Contracts before registries. Section 7 builds a lookup keyed on the carrier contract, and building it on a six method interface would mean rebuilding it after the split.

### Step 1: Split by Capability

Replace `app/Contracts/Carrier.php` with an identity-only contract.

```php
<?php

namespace App\Contracts;

interface Carrier
{
    /**
     * The lowercase identifier used to route requests to this carrier.
     */
    public function name(): string;
}
```

Then add the capabilities as separate files in `app/Contracts/`: `QuotesShipping` holding the `quote()` method with the docblock from section 5, `CreatesLabels` holding `createLabel()`, and `TracksShipments` holding `track()`.

```php
<?php

namespace App\Contracts;

interface CreatesLabels
{
    public function createLabel(string $trackingCode): string;
}
```

```php
<?php

namespace App\Contracts;

interface TracksShipments
{
    /** @return array{code:string,status:string} */
    public function track(string $trackingCode): array;
}
```

`Carrier` survives as a separate one method contract because identity is genuinely a different thing from capability. The registry in section 7 needs to key carriers by name without caring what they can do, so `name()` gets its own home.

Now the deletion. `cancel()` and `insure()` do not become interfaces. They had two stub implementations each and zero working ones, and nothing in the application ever called them. They were not capabilities, they were a wish list, and the honest split removes them entirely.

That is the part of ISP that gets missed. Splitting a fat interface is not only about grouping methods correctly; it is about noticing that some of them were never real. When a capability has no implementation and no caller, deleting it is the refactor.

### Step 2: Rewire the Carriers

`JneCarrier` declares three capabilities and loses two stubs:

```php
class JneCarrier implements Carrier, QuotesShipping, CreatesLabels, TracksShipments
```

`PosCarrier` declares two and loses three:

```php
class PosCarrier implements Carrier, QuotesShipping, CreatesLabels
```

Delete every `BadMethodCallException` method and the `use BadMethodCallException;` import from both files. The bodies of the surviving methods do not change.

Ten stub methods across the original design became zero. The class declaration lines now read as accurate summaries: JNE quotes, labels, and tracks; Pos quotes and labels. Anyone can see the difference without opening either file.

---

## 7. Fix OCP Third

Now the registry, built on contracts that are the right shape.

Replace `app/Services/ShipmentService.php`.

```php
<?php

namespace App\Services;

use App\Contracts\Carrier;
use App\Contracts\CreatesLabels;
use App\Contracts\QuotesShipping;
use InvalidArgumentException;

class ShipmentService
{
    /** @var array<string, Carrier> */
    private array $carriers = [];

    /**
     * @param  iterable<Carrier>  $carriers
     */
    public function __construct(iterable $carriers)
    {
        foreach ($carriers as $carrier) {
            $this->carriers[$carrier->name()] = $carrier;
        }
    }

    public function quote(string $carrier, float $weightKg, string $destination): float
    {
        $resolved = $this->resolve($carrier);

        if (! $resolved instanceof QuotesShipping) {
            throw new InvalidArgumentException("Carrier [{$carrier}] does not provide quotes.");
        }

        return $resolved->quote($weightKg, $destination);
    }

    public function label(string $carrier, string $trackingCode): string
    {
        $resolved = $this->resolve($carrier);

        if (! $resolved instanceof CreatesLabels) {
            throw new InvalidArgumentException("Carrier [{$carrier}] does not create labels.");
        }

        return $resolved->createLabel($trackingCode);
    }

    /** @return array<int, string> */
    public function supported(): array
    {
        return array_keys($this->carriers);
    }

    private function resolve(string $carrier): Carrier
    {
        if (! isset($this->carriers[$carrier])) {
            throw new InvalidArgumentException(sprintf(
                'Unsupported carrier [%s]. Supported: %s.',
                $carrier,
                implode(', ', $this->supported()),
            ));
        }

        return $this->carriers[$carrier];
    }
}
```

The constructor is Lesson 4's registry loop, keyed on each carrier's own `name()`. The duplicated `if/elseif` chains collapse into one private `resolve()` used by both methods, which is why the duplication that made adding a carrier error prone is now impossible: there is one lookup, not two.

The `instanceof` checks are Lesson 6's capability probe. `quote()` needs `QuotesShipping`, `label()` needs `CreatesLabels`, and a carrier that provides one but not the other fails with a message naming exactly what is missing. Before the split this could not have been expressed at all: every carrier claimed every capability, so the only way to discover Pos cannot track was to call it and catch.

Now register the carriers in the container. Add to `register()` in `AppServiceProvider`, alongside the payment and newsletter blocks already there:

```php
// Shipping: one tag for the carrier registry, one binding for the notifier.
$this->app->tag([
    JneCarrier::class,
    PosCarrier::class,
], 'shipping.carriers');

$this->app->singleton(ShipmentService::class, function ($app) {
    return new ShipmentService($app->tagged('shipping.carriers'));
});
```

The service provider now holds three separate composition decisions: a tagged registry for payment gateways, a config driven `match` for newsletter providers, and a tagged registry for carriers. Three different shapes of the same job, in one file, not interfering with each other. That accumulation is what a composition root is supposed to look like.

---

## 8. Fix SRP Fourth

Seven responsibilities, and the goal is not seven classes.

### Step 1: Extract the Repository

Create `app/Services/ShipmentRepository.php`.

```php
<?php

namespace App\Services;

use App\Models\Shipment;

class ShipmentRepository
{
    public function create(string $carrier, string $destination, float $weightKg, float $cost): Shipment
    {
        return Shipment::create([
            'carrier'       => $carrier,
            'destination'   => $destination,
            'weight_kg'     => $weightKg,
            'cost'          => $cost,
            'tracking_code' => $this->mintTrackingCode($carrier),
        ]);
    }

    public function attachLabelPath(Shipment $shipment, string $path): Shipment
    {
        $shipment->update(['label_path' => $path]);

        return $shipment->fresh();
    }

    private function mintTrackingCode(string $carrier): string
    {
        return strtoupper($carrier) . '-' . str_pad(
            (string) random_int(1, 999999), 6, '0', STR_PAD_LEFT
        );
    }
}
```

Responsibility 3, minting the tracking code, moved in here as a private method rather than becoming its own class. That was a judgment call worth stating. It is one line of string formatting, and Lesson 3 was explicit that a one line operation is not a responsibility worth a file. It belongs to the repository specifically because a tracking code is the shipment record's identity, and identity is created at the moment of persistence. A `TrackingCodeGenerator` class would be the over extraction failure mode: a file, an injection, and an indirection, in exchange for nothing.

`attachLabelPath` returns `$shipment->fresh()` for the reason Lesson 3's Error 2 covered: `update()` writes the row and leaves the in memory model stale.

### Step 2: Extract the Labeler

Create `app/Services/ShipmentLabeler.php`.

```php
<?php

namespace App\Services;

use App\Models\Shipment;
use Illuminate\Support\Facades\Storage;

class ShipmentLabeler
{
    public function __construct(private ShipmentService $service) {}

    /**
     * Render the carrier's label for this shipment, store it, and return the path.
     */
    public function generate(Shipment $shipment): string
    {
        $label = $this->service->label($shipment->carrier, $shipment->tracking_code);
        $path  = "labels/{$shipment->tracking_code}.txt";

        Storage::disk('local')->put($path, $label);

        return $path;
    }
}
```

This class owns the answer to "where do labels live and in what format", which is the warehouse's concern. When they ask for PDFs or a different naming scheme, this file changes and nothing else does.

Note that it takes a `ShipmentService` in its constructor, so it is a service depending on a service. The container resolves the whole chain automatically, because `ShipmentService` has a binding from section 7 and `ShipmentLabeler` type hints a class.

### Step 3: Reduce the Controller to a Coordinator

Replace `app/Http/Controllers/ShipmentController.php`.

```php
<?php

namespace App\Http\Controllers;

use App\Contracts\DispatchNotifier;
use App\Services\ShipmentLabeler;
use App\Services\ShipmentRepository;
use App\Services\ShipmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ShipmentController extends Controller
{
    public function __construct(
        private ShipmentService $service,
        private ShipmentRepository $repository,
        private ShipmentLabeler $labeler,
        private DispatchNotifier $notifier,
    ) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'carrier'     => 'required|string',
            'destination' => 'required|string',
            'weight_kg'   => 'required|numeric|min:0.1',
        ]);

        $cost = $this->service->quote(
            carrier:     $validated['carrier'],
            weightKg:    $validated['weight_kg'],
            destination: $validated['destination'],
        );

        $shipment = $this->repository->create(
            carrier:     $validated['carrier'],
            destination: $validated['destination'],
            weightKg:    $validated['weight_kg'],
            cost:        $cost,
        );

        $shipment = $this->repository->attachLabelPath(
            $shipment,
            $this->labeler->generate($shipment),
        );

        $this->notifier->notify($shipment->tracking_code, $shipment->carrier);

        // Audit log stays inline; one line is not worth its own service.
        Log::info("Shipment {$shipment->tracking_code} dispatched via {$shipment->carrier}");

        return response()->json($shipment, 201);
    }
}
```

`Storage` and `EmailDispatchNotifier` are gone from the imports. The controller no longer knows that files or notification channels exist.

The audit log stays inline, exactly as in Lesson 3, and for the same reason. One `Log::info` after a successful operation is not a responsibility. Leaving it is the counterweight that keeps this from becoming a demonstration of extraction for its own sake.

The `DispatchNotifier` type hint in the constructor is section 9's work, arriving one step early because the controller is being rewritten anyway.

---

## 9. Fix DIP Fifth

The last violation, and the smallest change.

### Step 1: Define the Contract and Implementations

Create `app/Contracts/DispatchNotifier.php`.

```php
<?php

namespace App\Contracts;

interface DispatchNotifier
{
    public function notify(string $trackingCode, string $carrier): void;
}
```

Add `implements DispatchNotifier` to `EmailDispatchNotifier`, then add a second real implementation so the abstraction is not a hypothesis. Create `app/Shipping/SmsDispatchNotifier.php`.

```php
<?php

namespace App\Shipping;

use App\Contracts\DispatchNotifier;

class SmsDispatchNotifier implements DispatchNotifier
{
    public function notify(string $trackingCode, string $carrier): void
    {
        FakeDispatchLog::record($trackingCode, $carrier, 'sms');
    }
}
```

And a fake, so tests can inspect what was requested. Create `app/Shipping/FakeDispatchNotifier.php`.

```php
<?php

namespace App\Shipping;

use App\Contracts\DispatchNotifier;

class FakeDispatchNotifier implements DispatchNotifier
{
    /** @var array<int, array{tracking_code:string,carrier:string}> */
    public array $sent = [];

    public function notify(string $trackingCode, string $carrier): void
    {
        $this->sent[] = ['tracking_code' => $trackingCode, 'carrier' => $carrier];
    }
}
```

### Step 2: Bind the Default

Add one line to `register()` in `AppServiceProvider`.

```php
$this->app->bind(DispatchNotifier::class, EmailDispatchNotifier::class);
```

This is the two argument form of `bind()`, which takes a contract and a concrete class name rather than a closure. It works here and did not work for the newsletter in Lesson 7 for one reason: `EmailDispatchNotifier` has no constructor arguments, so the container can build it by reflection. The providers in Lesson 7 needed two strings each, which reflection cannot supply, so they needed closures.

Knowing which form applies saves a lot of unnecessary closures. If the concrete class autowires, name it. If it needs scalars or a decision, write the closure.

---

## 10. Run and Test

All five fixed. Run the original test file, unchanged.

```bash
php artisan test tests/Feature/ShipmentDispatchTest.php
```

```
   PASS  Tests\Feature\ShipmentDispatchTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it quotes a jne shipment from the exact weight                       0.04s  
  ✓ it adds the remote surcharge                                         0.03s  
  ✓ it writes a label file and records its path                          0.03s  
  ✓ it notifies the customer that the shipment was dispatched            0.03s  

  Tests:    5 passed (17 assertions)
  Duration: 0.37s
```

**5 passed, 17 assertions**, byte for byte the section 3 baseline. Five structural changes across nine files, and the endpoint behaves identically. The one behavior that did change, the Pos quote, was a bug fix that the original suite never covered.

Now add the tests the new design makes possible. Append to `tests/Feature/ShipmentDispatchTest.php`, adding `App\Contracts\Carrier`, `App\Contracts\DispatchNotifier`, `App\Services\ShipmentService`, and `App\Shipping\FakeDispatchNotifier` to the imports.

```php
it('lets a test swap the notifier without touching HTTP or the controller', function () {
    Storage::fake('local');

    $fake = new FakeDispatchNotifier();
    $this->app->instance(DispatchNotifier::class, $fake);

    $this->postJson('/shipments', [
            'carrier'     => 'jne',
            'destination' => 'jakarta',
            'weight_kg'   => 1.0,
        ])
         ->assertStatus(201);

    expect($fake->sent)->toHaveCount(1)
        ->and($fake->sent[0]['carrier'])->toBe('jne');
});

it('reports which carriers are supported when one is unknown', function () {
    $service = app(ShipmentService::class);

    expect(fn () => $service->quote('dhl', 1.0, 'jakarta'))
        ->toThrow(
            InvalidArgumentException::class,
            'Unsupported carrier [dhl]. Supported: jne, pos.'
        );
});

it('refuses to label with a carrier that does not create labels', function () {
    $service = new ShipmentService([new class implements Carrier {
        public function name(): string
        {
            return 'quote-only';
        }
    }]);

    expect(fn () => $service->label('quote-only', 'X-1'))
        ->toThrow(InvalidArgumentException::class, 'does not create labels');
});
```

The third test is the one to look at. It constructs a carrier inline as an anonymous class implementing only `Carrier`, hands it to a `ShipmentService` built by hand, and proves the capability check fires. Before the ISP split this test could not have been written: there was no way to express a carrier that has a name and no capabilities, because the interface demanded all six methods.

```bash
php artisan test tests/Feature/ShipmentDispatchTest.php
```

```
   PASS  Tests\Feature\ShipmentDispatchTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it quotes a jne shipment from the exact weight                       0.04s  
  ✓ it adds the remote surcharge                                         0.03s  
  ✓ it writes a label file and records its path                          0.03s  
  ✓ it notifies the customer that the shipment was dispatched            0.03s  
  ✓ it lets a test swap the notifier without touching HTTP or the contr… 0.03s  
  ✓ it reports which carriers are supported when one is unknown          0.02s  
  ✓ it refuses to label with a carrier that does not create labels       0.02s  

  Tests:    8 passed (24 assertions)
  Duration: 0.43s
```

Finally, the whole of SolidLab.

```bash
php artisan test
```

```
  Tests:    47 passed (115 assertions)
  Duration: 1.32s
```

Forty seven tests across six feature areas in about a second and a third, with no network, no queue, and no external service. Every integration in the application sits behind a contract with a fake on the other side.

---

## 11. Why That Order

The order was not arbitrary, and the reasoning generalizes to any codebase you inherit.

**Correctness before structure.** LSP went first because it was the only defect that made the code wrong rather than merely awkward. Restructuring around a bug carries it into the new design and makes it harder to attribute afterwards, since a `floor()` buried in a registry looks far more intentional than a `floor()` sitting next to its `if/elseif`.

**Contracts before things built on contracts.** ISP went second because sections 7 and 8 build a registry and a service layer that both depend on the shape of `Carrier`. Splitting after would have meant rewriting `ShipmentService::quote` twice. In general, reshape an interface before you write code against it.

**Structure before wiring.** OCP and SRP came next because they decide what classes exist, and DIP is about how classes find each other. Inverting a dependency on a class you are about to delete is wasted work.

**Wiring last, and cheapest.** DIP took one interface, one binding line, and one constructor parameter, because sections 7 and 8 had already given every collaborator a home. Done first, the same change would have meant inverting a dependency inside a controller that was about to be rewritten anyway.

There is a general shape here: **correctness, contracts, structure, wiring.** It is not a law, and a specific codebase can justify a different order. What matters is having a reason, because "I started with whatever I noticed first" is how a refactor ends up half finished in the middle of a sprint.

Notice also how the fixes compounded rather than merely accumulated. The ISP split is what made the OCP registry able to check capabilities. The OCP registry is what gave `ShipmentLabeler` a single collaborator to depend on. The SRP extraction is what left the controller small enough that adding the DIP constructor parameter was one line. Each fix made the next one smaller, which is why doing all five is less than five times the work of doing one.

---

## 12. The SOLID Code Review Checklist

Five questions, one per principle, phrased so you can answer them while reading a diff.

**SRP: who can ask for this file to change?** List the roles. Product, finance, design, compliance, operations. More than two distinct owners in one class is a split waiting to happen. Fewer than two and you probably should not split it, whatever the line count.

**OCP: what happens when the next one arrives?** Find the thing that recurs (a payment provider, a report format, a carrier) and ask whether adding the next one means writing a file or editing one. Editing means a contract is waiting to be extracted. Watch for `if/elseif` and `match` over type strings; they are the reliable tell.

**LSP: would a caller holding the contract be surprised?** For every implementation, check the return shape, the exception types, and the promises in the docblock. If one implementation quietly does less than the others, that is the bug. The executable form of this question is a dataset test running every implementation through the contract's promises.

**ISP: does any implementation lie?** Look for `BadMethodCallException`, empty method bodies, and methods returning null to satisfy a signature. One stub is a smell; several across several implementations means the interface is wrong, not the classes. And check for methods nobody implements at all, which should be deleted rather than segregated.

**DIP: could a test replace this collaborator?** Look for `new` followed by a class that talks to a database, a queue, a filesystem, or a network. If a test cannot substitute it, neither can production. The other form of the question: if you deleted the low level file, would the high level one still be valid?

Two questions worth asking on top of the five, because they prevent most bad applications of them:

**What did you choose not to change, and why?** A refactor with no explicit "left alone" list has probably been over applied. In this lesson: the model, the migration, the validation rules, the audit log, and tracking code generation. Each was a decision.

**Is anything under change pressure here?** If a class has not been touched in two years and nobody expects it to be, every principle above is theoretical for that file. SOLID buys the ability to absorb change, and where there is no change, there is nothing to buy.

---

## 13. Fix the Errors in Your Code

**Error 1: Refactoring the structure before fixing the correctness bug.**

The instinct is to clean up first and fix bugs in the tidied code. It reliably costs more.

```php
// Wrong: build the registry first, and the floor() rides along into it
class ShipmentService
{
    public function quote(string $carrier, float $weightKg, string $destination): float
    {
        return $this->resolve($carrier)->quote($weightKg, $destination);
    }
}

// Correct: fix the contract and the implementation first, then restructure
public function quote(float $weightKg, string $destination): float
{
    $cost = ceil($weightKg) * self::RATE_PER_KG;
    // ...
}
```

After the registry exists, the `floor()` is one hop further from the endpoint and looks deliberate, sitting inside a well organized carrier class. Fix what is wrong while the wrongness is still obvious.

**Error 2: Turning every extracted responsibility into a class.**

```php
// Wrong: a file, a constructor injection, and an indirection for one line
class TrackingCodeGenerator
{
    public function generate(string $carrier): string
    {
        return strtoupper($carrier) . '-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT);
    }
}

// Correct: a private method on the class that owns the record's identity
private function mintTrackingCode(string $carrier): string
{
    return strtoupper($carrier) . '-' . str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT);
}
```

Apply the actor test rather than counting verbs. Nobody owns tracking code format independently of who owns the shipment record, so it is not a separate responsibility. Seven numbered comments in the original controller became four collaborators plus two deliberate non extractions, not seven classes.

**Error 3: Asserting on an error message that enumerates a registry.**

```php
// Wrong: this test fails every time a carrier is added, for no real reason
expect(fn () => $service->quote('dhl', 1.0, 'jakarta'))
    ->toThrow(InvalidArgumentException::class, 'Unsupported carrier [dhl]. Supported: jne, pos.');

// Correct: assert the part that is actually the subject of the test
expect(fn () => $service->quote('dhl', 1.0, 'jakarta'))
    ->toThrow(InvalidArgumentException::class, 'Unsupported carrier [dhl]');
```

The full message assertion in section 10 is written the wrong way on purpose, and Exercise 1 makes you feel it. The test's subject is that an unknown carrier is rejected by name; the list of supported carriers is incidental, changes whenever the registry does, and turns a purely additive production change into a test failure. Lesson 4's Exercise 2 relied on the opposite habit, and this is what happens when you forget it.

---

## 14. Exercises

**Exercise 1:** Add a `SicepatCarrier` that quotes at 9000 IDR per kilogram from the exact weight, with a 22000 remote surcharge, and supports labels and tracking. Register it, and write a test in a new file dispatching a 2 kg remote parcel for 40000. Before running the full file, predict whether any existing test breaks. Then run it and explain what you find.

**Exercise 2:** The `Carrier` interface has `name()` and nothing else, and `ShipmentService` checks capabilities with `instanceof`. Argue for or against making `QuotesShipping` extend `Carrier`. Say what it would buy, what it would cost, and which of the two `instanceof` checks in `ShipmentService` it would eliminate.

**Exercise 3:** Run the section 12 checklist over one of your own projects, or over `InvoiceController` from Lesson 3. Write down the five answers and, more importantly, the list of things you would deliberately leave alone.

---

## 15. Solutions

**Solution for Exercise 1:**

```php
<?php

namespace App\Shipping;

use App\Contracts\Carrier;
use App\Contracts\CreatesLabels;
use App\Contracts\QuotesShipping;
use App\Contracts\TracksShipments;

class SicepatCarrier implements Carrier, QuotesShipping, CreatesLabels, TracksShipments
{
    public const RATE_PER_KG = 9000.0;
    public const REMOTE_SURCHARGE = 22000.0;

    public function name(): string
    {
        return 'sicepat';
    }

    public function quote(float $weightKg, string $destination): float
    {
        $cost = $weightKg * self::RATE_PER_KG;

        if ($destination === 'remote') {
            $cost += self::REMOTE_SURCHARGE;
        }

        return round($cost, 2);
    }

    public function createLabel(string $trackingCode): string
    {
        return "LABEL[sicepat:{$trackingCode}]";
    }

    public function track(string $trackingCode): array
    {
        return ['code' => $trackingCode, 'status' => 'in_transit'];
    }
}
```

Add `SicepatCarrier::class` to the `shipping.carriers` tag list and its `use` statement. The new test passes: 2 kg at 9000 is 18000, plus the 22000 remote surcharge, giving 40000.

The prediction most people make is that nothing breaks, because the production change was purely additive: one new file, one line in a tag list, no existing class opened. That prediction is right about the production code and wrong about the suite.

```
   FAILED  Tests\Feature\ShipmentDispatchTest > it reports which carriers are supported when one is unknown             
  Expected: Unsupported carrier [dhl]. Supported: jne, pos, sicepat.

  To contain: Unsupported carrier [dhl]. Supported: jne, pos.
```

The test asserting the full error message breaks, because that message enumerates the registry. Nothing regressed. A test simply asserted more than it needed to, and the fix is to assert on `'Unsupported carrier [dhl]'` and drop the rest, as Error 3 describes.

Keep the distinction, because it is what the exercise is for. OCP promises that adding an implementation does not require editing tested *code*, and that promise held completely. It says nothing about tests that were written to be more specific than their subject. An over specified test converts a safe additive change into a failing build, which is a good way for a team to conclude that the extensible design "did not work".

**Solution for Exercise 2:**

Making `QuotesShipping extends Carrier` would mean every quoting carrier necessarily has a name, so `resolve()` could return `QuotesShipping` directly and the `instanceof QuotesShipping` check in `quote()` would disappear. The `instanceof CreatesLabels` check in `label()` would remain, since labelling would still be an independent capability.

The cost is that it welds identity to one particular capability. A carrier that only tracks parcels, integrated purely so the app can query someone else's shipments, would be unable to implement `TracksShipments` and have a name without also promising to quote. That is a fat interface reappearing through inheritance, and it is precisely the coupling section 6 separated on purpose.

Ship the current design, with `Carrier` standing alone. The `instanceof` checks are cheap, they live in one small service, and they produce error messages naming exactly which capability is missing. Trading that clarity for one deleted line of a guard clause is a bad exchange, and the anonymous class test in section 10 is the concrete evidence: a carrier with a name and no capabilities is a legitimate thing to construct, and interface inheritance would make it unrepresentable.

Note the general point, since it recurs. Interface inheritance feels tidier than implementing three interfaces, and the tidiness is bought by removing combinations someone will eventually need. Composition at the point of use, with intersection types where a caller needs two capabilities at once, keeps the combinations available.

**Solution for Exercise 3:**

Running the checklist over Lesson 3's `InvoiceController` and the services around it:

**SRP.** The controller has one actor now, the API consumer, and coordinates four collaborators owned by finance, engineering, design, and marketing. Passes. The `InvoiceCalculator` is finance only, `InvoicePdfGenerator` is design only. Passes.

**OCP.** Fails, and this was already visible in Lesson 3's Exercise 1: adding a discount code means opening `InvoiceCalculator`. Whether it matters depends on how often discount codes change. If marketing ships a new code every quarter, extract a discount strategy contract. If `WELCOME10` has been the only code for two years, leave it, and note it as a known trade rather than a defect.

**LSP.** Not applicable. Nothing in the invoice feature has two implementations of anything, so there is no substitution to break. This is the answer for most of any codebase, and recognizing it saves the effort of looking for violations that cannot exist.

**ISP.** Not applicable, for the same reason: no interfaces. Worth noting that the absence of interfaces is not itself a finding.

**DIP.** Partially fails. `InvoicePdfGenerator` uses the `Storage` facade directly and `InvoiceMailer` uses `Mail`. Both are testable because Laravel provides `Storage::fake()` and `Mail::fake()`, so the practical cost is near zero. This is the honest reading: a facade dependency that the framework already provides a swap for is not the same problem as `new MailchimpProvider()`.

**Deliberately left alone:** the `Invoice` model, the migration, the inline validation rules, the `Log::info` call, and the `Storage` and `Mail` facade usage.

That last list is the real output of the exercise. Two findings, one of which is conditional on business context, and five explicit non actions. A checklist run that produces a page of findings on a well written feature is usually being applied as a style guide rather than as a design tool.

---

## Next Up - Lesson 9

You took one feature with all five defects and worked through them in a defensible order: correctness, contracts, structure, wiring. The original tests passed unchanged at the end, which proved the structure moved and the behavior did not, while the one behavior that did change was a money losing bug the original suite could not see. You also practised the half of the discipline that gets less attention, deciding that the model, the migration, the validation rules, the audit log, and the tracking code format were all fine as they were.

SolidLab is now six feature areas, forty seven tests, and a service provider holding three different composition strategies. More usefully, you have a checklist that fits on one screen and a sense of when each question actually applies.

Lesson 9 closes the course. It collects what SolidLab demonstrates, names the handful of ideas worth carrying into your own projects, and points at where to go next when you want the patterns that these principles have been quietly pointing toward the whole time.
