# Strategy Pattern in Laravel: Swappable Shipping Cost Calculators Without if/else Chains

Your checkout supports two couriers, SwiftPost and BudgetShip, so you write a `ShippingService` with an `if/elseif` that branches on the courier name. A month later the business adds CityRider for same-day delivery inside Jakarta, and you add another branch. Then MetroExpress. Then a flat-rate option for a promo. Six months in, one method carries five branches, each with its own weight rules, zone tables, and edge cases, all sharing the same file. A change to the CityRider distance formula forces you to scroll past SwiftPost and BudgetShip to reach it, and a careless refactor of the shared rounding logic quietly breaks BudgetShip.

The problem is not the new courier. The problem is that adding a courier means reopening a method that was already tested and shipped, and every reopen is a chance to break a courier that had nothing to do with your change. Over time the team stops trusting the file. Each shipping change turns into a full regression of every courier, because nobody can promise that touching one branch left the others alone.

This article continues the thread from our SOLID series, in particular the [Open/Closed Principle in Laravel 13: Build an Extensible Payment Gateway System](https://qadrlabs.com/post/openclosed-principle-in-laravel-build-an-extensible-payment-gateway-system). The Open/Closed Principle told us why we want code that is closed to modification; the Strategy pattern is one concrete way to get there. We will build the bloated `ShippingService` that almost every Indonesian e-commerce codebase grows, lock its behavior down with Pest tests, then refactor each courier into its own swappable strategy selected at runtime by the courier the buyer picks. By the end, adding a fifth courier means writing one new class and adding one line to a list, with zero edits to any calculator that already passed its tests.

## Overview {#overview}

The work happens in two phases. First we build the version with the `if/elseif` dispatcher and one private method per courier, expose it through a JSON endpoint, and capture a green Pest baseline. Second we extract a `ShippingCalculator` contract, move each courier behind it as a concrete strategy, pass the request data through a small readonly `Shipment` object, and let Laravel's service container assemble and select the right strategy at runtime. The same tests pass at the same count after the refactor. Finally we add a brand new courier to prove the payoff.

### What You'll Build
- A Laravel 13 JSON endpoint that returns a shipping cost for a chosen courier
- A `ShippingService` that starts as an `if/elseif` chain and ends as a strategy registry
- A `ShippingCalculator` contract with four concrete strategies: SwiftPost, BudgetShip, CityRider, and MetroExpress, each with a genuinely different pricing formula
- A readonly `Shipment` data object that carries the request into each strategy
- Pest tests that lock the behavior down across the refactor and across the new courier

### What You'll Learn
- How to recognize an `if/elseif` chain that is really a Strategy pattern waiting to happen
- How to design a small Strategy contract and move each algorithm behind it
- How to pass context into a strategy cleanly with a readonly data object instead of a long parameter list
- How to register a family of strategies with Laravel's service container using tags and select one at runtime
- How to add a new strategy without opening any file that already had passing tests

### What You'll Need
- PHP 8.3 or later
- Composer 2.x
- Familiarity with Laravel routing, controllers, and service providers
- A terminal and a code editor
- Optional but recommended: the [Open/Closed Principle](https://qadrlabs.com/post/openclosed-principle-in-laravel-build-an-extensible-payment-gateway-system) article, since Strategy is the pattern that puts that principle into practice

## Step 1: Set Up the Laravel Project {#step-1-set-up-the-laravel-project}

We start with a fresh Laravel 13 application configured with SQLite and Pest, the same toolchain used across the SOLID series.

```bash
laravel new shipping-strategy-demo --no-interaction --database=sqlite --pest --no-boost
cd shipping-strategy-demo
```

Before adding any of our own code, run the test suite so we know the starting point is clean.

```bash
php artisan test
```

The two example tests that ship with Laravel should pass.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

  Tests:    2 passed (2 assertions)
  Duration: 0.17s
```

A green baseline here means anything that breaks later is something we did, which is exactly the safety net a refactor needs.

## Step 2: Create the ShippingQuote Model and Migration {#step-2-create-the-shippingquote-model-and-migration}

The domain stays small. We persist one record per quote so we can inspect what was charged: which courier, the actual weight, the destination zone, and the final cost in rupiah. Generate the model and its migration together.

```bash
php artisan make:model ShippingQuote -m
```

That command creates two files. Open the migration it generated at `database/migrations/xxxx_xx_xx_xxxxxx_create_shipping_quotes_table.php` and replace the `up` method's schema definition so the table has the columns we need.

```php
public function up(): void
{
    Schema::create('shipping_quotes', function (Blueprint $table) {
        $table->id();
        $table->string('courier');                 // swiftpost, budgetship, cityrider, ...
        $table->unsignedInteger('weight');         // actual weight in grams
        $table->string('zone');                    // jabodetabek, java, outside_java
        $table->unsignedInteger('cost');           // final shipping cost in rupiah
        $table->timestamps();
    });
}
```

We store weight in grams and cost in whole rupiah as unsigned integers, because both are naturally non-negative whole numbers and integers avoid the rounding surprises that come with floats for money.

Now open the model at `app/Models/ShippingQuote.php`. Laravel generated it as an empty class, so we add the Laravel 13 `#[Fillable]` attribute to allow mass assignment of our columns, plus a couple of casts so the integers come back as integers.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'courier',
    'weight',
    'zone',
    'cost',
])]
class ShippingQuote extends Model
{
    protected $casts = [
        'weight' => 'integer',
        'cost'   => 'integer',
    ];
}
```

The `#[Fillable]` attribute keeps the mass-assignable fields visible at the top of the class, which is the Laravel 13 replacement for the older `protected $fillable` property.

Run the migration so SQLite gets the table.

```bash
php artisan migrate
```

Because `laravel new` already ran the default migrations during setup, the only pending migration is ours.

```

   INFO  Running migrations.  

  2026_06_24_054616_create_shipping_quotes_table ................ 10.53ms DONE
```

## Step 3: Build the Bloated ShippingService {#step-3-build-the-bloated-shippingservice}

Now we deliberately write the code this article exists to refactor: a single service with an `if/elseif` dispatcher and one private method per courier. The `app/Services` directory does not exist in a fresh Laravel app, so create it first.

```bash
mkdir -p app/Services
```

Create `app/Services/ShippingService.php` with the following content. Each private method holds a real pricing formula, so the branches genuinely differ from one another rather than being three copies of the same shape.

```php
<?php

namespace App\Services;

use InvalidArgumentException;

class ShippingService
{
    /**
     * Calculate the shipping cost in rupiah for a given courier.
     *
     * Open/Closed Principle violation: every new courier adds another branch
     * here, and every branch shares this single method with all the others.
     */
    public function quote(
        string $courier,
        int $weight,
        int $length,
        int $width,
        int $height,
        string $zone,
        int $distanceKm,
    ): int {
        if ($courier === 'swiftpost') {
            return $this->quoteSwiftPost($weight, $length, $width, $height, $zone);
        } elseif ($courier === 'budgetship') {
            return $this->quoteBudgetShip($weight, $zone);
        } elseif ($courier === 'cityrider') {
            return $this->quoteCityRider($zone, $distanceKm);
        } else {
            throw new InvalidArgumentException("Unsupported courier: {$courier}");
        }
    }

    /**
     * SwiftPost Regular. Charges on the chargeable weight, which is the larger of the
     * actual weight and the volumetric weight (length x width x height / 5000).
     * Weight is rounded up to the next whole kilogram before applying the rate.
     */
    private function quoteSwiftPost(int $weight, int $length, int $width, int $height, string $zone): int
    {
        $rates = [
            'jabodetabek'  => 9000,
            'java'         => 14000,
            'outside_java' => 28000,
        ];

        $volumetricGrams = (int) (($length * $width * $height) / 5);  // (L*W*H/5000) kg, expressed in grams
        $chargeableGrams = max($weight, $volumetricGrams);
        $chargeableKg    = (int) ceil($chargeableGrams / 1000);

        return $chargeableKg * $rates[$zone];
    }

    /**
     * BudgetShip Regular. Cheaper than SwiftPost and simpler: it bills on the actual
     * weight only and ignores volumetric weight entirely.
     */
    private function quoteBudgetShip(int $weight, string $zone): int
    {
        $rates = [
            'jabodetabek'  => 8000,
            'java'         => 12000,
            'outside_java' => 25000,
        ];

        $chargeableKg = (int) ceil($weight / 1000);

        return $chargeableKg * $rates[$zone];
    }

    /**
     * CityRider Instant. A same-city motorbike courier, so it only serves the
     * jabodetabek zone and prices by distance, not by weight: a flat base fare
     * covers the first 5 km, then a per-kilometer rate applies beyond that.
     */
    private function quoteCityRider(string $zone, int $distanceKm): int
    {
        if ($zone !== 'jabodetabek') {
            throw new InvalidArgumentException('CityRider only serves same-city (jabodetabek) deliveries.');
        }

        $baseFare       = 10000;   // covers the first 5 km
        $perKmBeyondCap = 2500;
        $freeKm         = 5;

        $extraKm = max(0, $distanceKm - $freeKm);

        return $baseFare + ($extraKm * $perKmBeyondCap);
    }
}
```

Two smells are worth naming before we touch anything. The first is the dispatcher itself: every new courier means another `elseif`, another private method, and another reason to read the whole file. The second is the parameter list. The public `quote` method takes seven positional arguments because it has to satisfy every courier at once, even though SwiftPost never looks at distance and CityRider never looks at dimensions. That long signature is a hint that the data wants to travel together as one object, which we will fix during the refactor.

## Step 4: Expose It Over HTTP {#step-4-expose-it-over-http}

A service is easier to test and to demonstrate when it has an HTTP entry point. Generate the controller first, before we write any code into it.

```bash
php artisan make:controller ShippingQuoteController
```

That creates `app/Http/Controllers/ShippingQuoteController.php` as an empty class. Open it and replace its body with a `store` action that validates the request, calls the service, persists the quote, and returns it as JSON.

```php
<?php

namespace App\Http\Controllers;

use App\Models\ShippingQuote;
use App\Services\ShippingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShippingQuoteController extends Controller
{
    public function __construct(private ShippingService $service) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'courier'     => 'required|string',
            'weight'      => 'required|integer|min:1',
            'length'      => 'required|integer|min:1',
            'width'       => 'required|integer|min:1',
            'height'      => 'required|integer|min:1',
            'zone'        => 'required|string|in:jabodetabek,java,outside_java',
            'distance_km' => 'nullable|integer|min:0',
        ]);

        $cost = $this->service->quote(
            courier:    $validated['courier'],
            weight:     $validated['weight'],
            length:     $validated['length'],
            width:      $validated['width'],
            height:     $validated['height'],
            zone:       $validated['zone'],
            distanceKm: $validated['distance_km'] ?? 0,
        );

        $quote = ShippingQuote::create([
            'courier' => $validated['courier'],
            'weight'  => $validated['weight'],
            'zone'    => $validated['zone'],
            'cost'    => $cost,
        ]);

        return response()->json($quote, 201);
    }
}
```

We type-hint `ShippingService` in the constructor and let the container inject it. The `distance_km` field is nullable because only instant couriers use it, and we default it to `0` when the buyer picks a courier that ignores distance.

Because this is a JSON endpoint, it belongs in the API routes file rather than `routes/web.php`. A fresh Laravel 13 app does not ship an API routes file, so create one at `routes/api.php` with a single route.

```php
<?php

use App\Http\Controllers\ShippingQuoteController;
use Illuminate\Support\Facades\Route;

Route::post('/shipping/quote', [ShippingQuoteController::class, 'store'])->name('shipping.quote');
```

Creating the file is not enough on its own; Laravel only loads it if we register it. Open `bootstrap/app.php`. The `withRouting` call currently lists `web`, `commands`, and `health` but no `api` file, so the new routes are invisible.

The current `withRouting` block looks like this.

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

Add the `api` line so Laravel loads our new file and prefixes its routes with `/api`.

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    api: __DIR__.'/../routes/api.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

There is a second reason to keep this endpoint under `/api`. A fresh Laravel 13 app configures its exception handler to render errors as JSON only for routes matching `api/*`, which you can see lower in the same `bootstrap/app.php` file inside the `withExceptions` closure. By serving the endpoint from the API routes file, validation failures come back as a clean `422` JSON payload instead of an HTML redirect, which is what an API client expects.

Our endpoint now lives at `POST /api/shipping/quote`.

## Step 5: Write the Pest Tests {#step-5-write-the-pest-tests}

The tests assert the public HTTP behavior plus two unit-level checks against the service directly. They will pass against the bloated version and keep passing after the refactor, which is what makes them a safety net rather than decoration. Generate the test file.

```bash
php artisan make:test ShippingQuoteTest --pest
```

Open `tests/Feature/ShippingQuoteTest.php` and replace its body with the following. Each cost assertion is annotated with the arithmetic it expects, so the formulas are verifiable by hand.

```php
<?php

use App\Models\ShippingQuote;
use App\Services\ShippingService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('rejects requests without required fields', function () {
    $this->postJson('/api/shipping/quote', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['courier', 'weight', 'length', 'width', 'height', 'zone']);
});

it('quotes swiftpost using actual weight when it beats volumetric', function () {
    // 1500 g in a compact 10x10x10 box (volumetric ~200 g), java zone @ 14000/kg.
    // chargeable = ceil(1500/1000) = 2 kg, so 2 * 14000 = 28000.
    $this->postJson('/api/shipping/quote', [
            'courier' => 'swiftpost',
            'weight'  => 1500,
            'length'  => 10,
            'width'   => 10,
            'height'  => 10,
            'zone'    => 'java',
        ])
         ->assertStatus(201)
         ->assertJsonPath('courier', 'swiftpost')
         ->assertJsonPath('cost', 28000);

    expect(ShippingQuote::first()->cost)->toBe(28000);
});

it('quotes swiftpost using volumetric weight when the box is bulky', function () {
    // 1000 g but a bulky 40x40x40 box: volumetric = 40*40*40/5000 = 12.8 kg.
    // chargeable = ceil(12800/1000) = 13 kg, jabodetabek @ 9000/kg = 117000.
    $this->postJson('/api/shipping/quote', [
            'courier' => 'swiftpost',
            'weight'  => 1000,
            'length'  => 40,
            'width'   => 40,
            'height'  => 40,
            'zone'    => 'jabodetabek',
        ])
         ->assertStatus(201)
         ->assertJsonPath('cost', 117000);
});

it('quotes budgetship on actual weight only, ignoring volumetric', function () {
    // Same bulky 40x40x40 box, but BudgetShip bills the 2300 g actual weight only.
    // chargeable = ceil(2300/1000) = 3 kg, outside_java @ 25000/kg = 75000.
    $this->postJson('/api/shipping/quote', [
            'courier' => 'budgetship',
            'weight'  => 2300,
            'length'  => 40,
            'width'   => 40,
            'height'  => 40,
            'zone'    => 'outside_java',
        ])
         ->assertStatus(201)
         ->assertJsonPath('courier', 'budgetship')
         ->assertJsonPath('cost', 75000);
});

it('quotes cityrider by distance within the city', function () {
    // jabodetabek, 8 km: base 10000 covers 5 km, then 3 km * 2500 = 7500, so 17500.
    $this->postJson('/api/shipping/quote', [
            'courier'     => 'cityrider',
            'weight'      => 500,
            'length'      => 10,
            'width'       => 10,
            'height'      => 10,
            'zone'        => 'jabodetabek',
            'distance_km' => 8,
        ])
         ->assertStatus(201)
         ->assertJsonPath('courier', 'cityrider')
         ->assertJsonPath('cost', 17500);
});

it('rejects cityrider outside the city zone', function () {
    $service = app(ShippingService::class);

    expect(fn () => $service->quote('cityrider', 500, 10, 10, 10, 'java', 8))
        ->toThrow(InvalidArgumentException::class);
});

it('throws when an unsupported courier is requested', function () {
    $service = app(ShippingService::class);

    expect(fn () => $service->quote('unknown', 1000, 10, 10, 10, 'java', 0))
        ->toThrow(InvalidArgumentException::class);
});
```

The third test is the interesting one. BudgetShip receives the exact same bulky `40x40x40` box as the SwiftPost volumetric test, but charges far less because it ignores volumetric weight and bills the actual `2300 g` only. That contrast is the whole reason these calculators are separate algorithms rather than one shared formula. The last two tests reach into the service directly rather than going through HTTP, because an unsupported courier and a cross-zone CityRider both throw exceptions, and asserting on a thrown exception is cleaner than asserting on a `500` response.

## Step 6: Run the Baseline Tests {#step-6-run-the-baseline-tests}

Run the suite so we have a green baseline to refactor against.

```bash
php artisan test
```

Nine tests pass: the seven we wrote plus the two Laravel examples.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                       0.11s  

   PASS  Tests\Feature\ShippingQuoteTest
  ✓ it rejects requests without required fields                         0.09s  
  ✓ it quotes swiftpost using actual weight when it beats volumetric    0.03s  
  ✓ it quotes swiftpost using volumetric weight when the box is bulky   0.02s  
  ✓ it quotes budgetship on actual weight only, ignoring volumetric     0.02s  
  ✓ it quotes cityrider by distance within the city                     0.02s  
  ✓ it rejects cityrider outside the city zone                          0.02s  
  ✓ it throws when an unsupported courier is requested                  0.02s  

  Tests:    9 passed (24 assertions)
  Duration: 0.41s
```

Nine green tests. This is the contract the refactor must preserve. If any of these nine change behavior, we broke something.

## Step 7: Introduce the Shipment Context Object {#step-7-introduce-the-shipment-context-object}

Before we extract the couriers, we fix the long parameter list. Every calculator needs the same bundle of facts about a shipment, so we model that bundle as a single readonly object. The directory does not exist yet, so create it.

```bash
mkdir -p app/DataObjects
```

Create `app/DataObjects/Shipment.php` with the following content. It carries the request data and adds two helper methods so the weight math lives in one place instead of being copied into every calculator.

```php
<?php

namespace App\DataObjects;

class Shipment
{
    public function __construct(
        public readonly int $weight,        // actual weight in grams
        public readonly int $length,        // cm
        public readonly int $width,         // cm
        public readonly int $height,        // cm
        public readonly string $zone,       // jabodetabek, java, outside_java
        public readonly int $distanceKm,    // used by instant couriers only
    ) {}

    /**
     * Volumetric weight in grams using the given divisor. Most Indonesian
     * couriers use 5000: (length x width x height) / 5000 gives kilograms,
     * which we express in grams by dividing by 5 instead.
     */
    public function volumetricGrams(int $divisor = 5000): int
    {
        return (int) (($this->length * $this->width * $this->height) / ($divisor / 1000));
    }

    /**
     * Chargeable weight in whole kilograms, rounded up. Couriers that bill on
     * volumetric weight pass their divisor; couriers that bill on actual weight
     * only can call chargeableKg() with no divisor and get the actual weight.
     */
    public function chargeableKg(?int $volumetricDivisor = null): int
    {
        $grams = $this->weight;

        if ($volumetricDivisor !== null) {
            $grams = max($grams, $this->volumetricGrams($volumetricDivisor));
        }

        return (int) ceil($grams / 1000);
    }
}
```

The `readonly` promoted properties make a `Shipment` immutable once constructed, so no calculator can accidentally mutate the shipment another calculator is about to read. The `chargeableKg` helper expresses the one rule every weight-based courier shares, rounding up to the next kilogram, while still letting each courier decide whether volumetric weight counts by passing or omitting a divisor. In the language of the Strategy pattern, this object is the context that gets handed to whichever strategy runs.

## Step 8: Define the ShippingCalculator Contract {#step-8-define-the-shippingcalculator-contract}

The contract is the abstraction that lets the service stay closed against new couriers. It is intentionally tiny, because the only things the service needs from a courier are its name and how to price a shipment. Create the directory and the interface.

```bash
mkdir -p app/Contracts
```

Create `app/Contracts/ShippingCalculator.php` with the following content.

```php
<?php

namespace App\Contracts;

use App\DataObjects\Shipment;

interface ShippingCalculator
{
    /**
     * The lowercase courier identifier used to route a request to this
     * calculator. Examples: 'swiftpost', 'budgetship', 'cityrider'.
     */
    public function courier(): string;

    /**
     * Calculate the shipping cost in whole rupiah for the given shipment.
     */
    public function calculate(Shipment $shipment): int;
}
```

The interface declares only `courier` and `calculate`. We resist the urge to add `estimatedDays`, `trackingUrl`, or `supportsCod` now, because none of those are needed yet, and a contract that promises methods nobody calls is a contract that every implementation has to fake. We can extend it honestly when a real requirement arrives.

## Step 9: Extract the SwiftPostCalculator {#step-9-extract-the-swiftpostcalculator}

Now we move each courier out of the service and into its own class implementing the contract. Create the directory that will hold the strategies, then the first calculator.

```bash
mkdir -p app/Services/Shipping/Calculators
```

Create `app/Services/Shipping/Calculators/SwiftPostCalculator.php` with the following content. The pricing logic is the same as the old private `quoteSwiftPost` method, but now it reads its inputs from the `Shipment` object and reuses the `chargeableKg` helper.

```php
<?php

namespace App\Services\Shipping\Calculators;

use App\Contracts\ShippingCalculator;
use App\DataObjects\Shipment;

class SwiftPostCalculator implements ShippingCalculator
{
    public function courier(): string
    {
        return 'swiftpost';
    }

    /**
     * SwiftPost Regular bills on chargeable weight, the larger of actual and
     * volumetric weight (divisor 5000), rounded up to the next kilogram.
     */
    public function calculate(Shipment $shipment): int
    {
        $rates = [
            'jabodetabek'  => 9000,
            'java'         => 14000,
            'outside_java' => 28000,
        ];

        $chargeableKg = $shipment->chargeableKg(volumetricDivisor: 5000);

        return $chargeableKg * $rates[$shipment->zone];
    }
}
```

The `courier` method returns the same `'swiftpost'` string that the old dispatcher matched against. That string is how the service will find this calculator at runtime, so it becomes the calculator's stable identity rather than a value buried inside an `if`.

## Step 10: Extract the BudgetShipCalculator {#step-10-extract-the-budgetshipcalculator}

Mirror the same extraction for BudgetShip. Create `app/Services/Shipping/Calculators/BudgetShipCalculator.php` with the following content.

```php
<?php

namespace App\Services\Shipping\Calculators;

use App\Contracts\ShippingCalculator;
use App\DataObjects\Shipment;

class BudgetShipCalculator implements ShippingCalculator
{
    public function courier(): string
    {
        return 'budgetship';
    }

    /**
     * BudgetShip Regular is cheaper and simpler: it bills on the actual weight
     * only and ignores volumetric weight, so chargeableKg() gets no divisor.
     */
    public function calculate(Shipment $shipment): int
    {
        $rates = [
            'jabodetabek'  => 8000,
            'java'         => 12000,
            'outside_java' => 25000,
        ];

        $chargeableKg = $shipment->chargeableKg();

        return $chargeableKg * $rates[$shipment->zone];
    }
}
```

Notice how the difference between SwiftPost and BudgetShip is now a single, readable line. SwiftPost calls `chargeableKg(volumetricDivisor: 5000)` and BudgetShip calls `chargeableKg()` with no divisor. The two pricing policies sit in two separate files, so changing the BudgetShip rate card cannot touch a single character of SwiftPost.

## Step 11: Extract the CityRiderCalculator {#step-11-extract-the-cityridercalculator}

CityRider is the strategy that proves the contract is flexible enough for couriers that work nothing like the others. It ignores weight entirely, prices by distance, and refuses any zone except same-city Jakarta. Create `app/Services/Shipping/Calculators/CityRiderCalculator.php` with the following content.

```php
<?php

namespace App\Services\Shipping\Calculators;

use App\Contracts\ShippingCalculator;
use App\DataObjects\Shipment;
use InvalidArgumentException;

class CityRiderCalculator implements ShippingCalculator
{
    public function courier(): string
    {
        return 'cityrider';
    }

    /**
     * CityRider Instant is a same-city motorbike courier: it only serves the
     * jabodetabek zone and prices by distance, not weight. A flat base fare
     * covers the first 5 km, then a per-kilometer rate applies beyond that.
     */
    public function calculate(Shipment $shipment): int
    {
        if ($shipment->zone !== 'jabodetabek') {
            throw new InvalidArgumentException('CityRider only serves same-city (jabodetabek) deliveries.');
        }

        $baseFare       = 10000;   // covers the first 5 km
        $perKmBeyondCap = 2500;
        $freeKm         = 5;

        $extraKm = max(0, $shipment->distanceKm - $freeKm);

        return $baseFare + ($extraKm * $perKmBeyondCap);
    }
}
```

Each of the three calculators is now an independent file that knows one courier and nothing else. That independence is the property the original `if/elseif` method could never offer, where every formula shared one method body and one set of local variables.

## Step 12: Rewire ShippingService and the Container {#step-12-rewire-shippingservice-and-the-container}

With the algorithms extracted, the service no longer needs to know about any specific courier. It becomes a registry: it receives every calculator, indexes them by their `courier` name, and delegates to whichever one matches the request. This is the Strategy pattern's context object, the piece that holds a reference to strategies and picks one at runtime.

The service currently holds the `if/elseif` dispatcher from Step 3.

```php
public function quote(
    string $courier,
    int $weight,
    int $length,
    int $width,
    int $height,
    string $zone,
    int $distanceKm,
): int {
    if ($courier === 'swiftpost') {
        return $this->quoteSwiftPost($weight, $length, $width, $height, $zone);
    } elseif ($courier === 'budgetship') {
        return $this->quoteBudgetShip($weight, $zone);
    } elseif ($courier === 'cityrider') {
        return $this->quoteCityRider($zone, $distanceKm);
    } else {
        throw new InvalidArgumentException("Unsupported courier: {$courier}");
    }
}

// ... plus the three private quoteSwiftPost/quoteBudgetShip/quoteCityRider methods
```

Replace the entire contents of `app/Services/ShippingService.php` with the registry version below. The private courier methods are gone, because that logic now lives in the calculator classes.

```php
<?php

namespace App\Services;

use App\Contracts\ShippingCalculator;
use App\DataObjects\Shipment;
use InvalidArgumentException;

class ShippingService
{
    /**
     * @var array<string, ShippingCalculator>
     */
    private array $calculators = [];

    /**
     * @param  iterable<ShippingCalculator>  $calculators
     */
    public function __construct(iterable $calculators)
    {
        foreach ($calculators as $calculator) {
            $this->calculators[$calculator->courier()] = $calculator;
        }
    }

    public function quote(string $courier, Shipment $shipment): int
    {
        if (! isset($this->calculators[$courier])) {
            throw new InvalidArgumentException("Unsupported courier: {$courier}");
        }

        return $this->calculators[$courier]->calculate($shipment);
    }

    /**
     * The list of registered courier identifiers, handy for tests and
     * for building a courier dropdown at checkout.
     *
     * @return array<int, string>
     */
    public function supported(): array
    {
        return array_keys($this->calculators);
    }
}
```

The public `quote` method shrank from seven parameters to two: the chosen courier and the `Shipment`. The dispatcher became a single array lookup, and the service is now closed against courier-specific changes. Adding, replacing, or removing a courier all happen outside this file.

That leaves one question: how does the service receive its collection of calculators? Laravel's service container has a feature called tagging that fits this exactly. We tag every calculator under a shared label, then resolve the service with all tagged calculators injected as an iterable. Open `app/Providers/AppServiceProvider.php`. Its `register` method is empty in a fresh app.

```php
public function register(): void
{
    //
}
```

Replace that empty method, and add the imports it needs at the top of the class, so the provider tags the calculators and wires up the service.

```php
<?php
namespace App\Providers;

use App\Services\Shipping\Calculators\CityRiderCalculator;
use App\Services\Shipping\Calculators\SwiftPostCalculator;
use App\Services\Shipping\Calculators\BudgetShipCalculator;
use App\Services\ShippingService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Register every calculator implementation under a shared tag.
        $this->app->tag([
            SwiftPostCalculator::class,
            BudgetShipCalculator::class,
            CityRiderCalculator::class,
        ], 'shipping.calculators');

        // Resolve the service with all tagged calculators injected as an iterable.
        $this->app->singleton(ShippingService::class, function ($app) {
            return new ShippingService($app->tagged('shipping.calculators'));
        });
    }
}
```

Tagging is Laravel's idiomatic answer to "I have a family of strategies and I want all of them injected somewhere". The service never imports a single calculator class; it only knows the contract. The provider is the one place where the list of available couriers is configured, which makes the provider the place we extend and the service the thing that stays closed.

One caller still uses the old method signature: the controller. It currently passes seven scalars into `quote`.

```php
$cost = $this->service->quote(
    courier:    $validated['courier'],
    weight:     $validated['weight'],
    length:     $validated['length'],
    width:      $validated['width'],
    height:     $validated['height'],
    zone:       $validated['zone'],
    distanceKm: $validated['distance_km'] ?? 0,
);
```

Open `app/Http/Controllers/ShippingQuoteController.php` and replace that call so it builds a `Shipment` and passes it alongside the courier name.

```php
$shipment = new Shipment(
    weight:     $validated['weight'],
    length:     $validated['length'],
    width:      $validated['width'],
    height:     $validated['height'],
    zone:       $validated['zone'],
    distanceKm: $validated['distance_km'] ?? 0,
);

$cost = $this->service->quote($validated['courier'], $shipment);
```

For that to compile, the controller needs to import the new data object. Add this `use` statement alongside the existing imports at the top of the file.

```php
use App\DataObjects\Shipment;
```

Two of our tests also call the service directly, and they still use the old seven-argument signature, so they need the same update. The five HTTP tests are untouched, because the endpoint contract did not change; only the internal service method did. First add the import near the top of `tests/Feature/ShippingQuoteTest.php`.

```php
use App\DataObjects\Shipment;
```

The two service-level tests currently look like this.

```php
it('rejects cityrider outside the city zone', function () {
    $service = app(ShippingService::class);

    expect(fn () => $service->quote('cityrider', 500, 10, 10, 10, 'java', 8))
        ->toThrow(InvalidArgumentException::class);
});

it('throws when an unsupported courier is requested', function () {
    $service = app(ShippingService::class);

    expect(fn () => $service->quote('unknown', 1000, 10, 10, 10, 'java', 0))
        ->toThrow(InvalidArgumentException::class);
});
```

Replace them with versions that build a `Shipment` and pass it to the two-argument `quote`.

```php
it('rejects cityrider outside the city zone', function () {
    $service = app(ShippingService::class);
    $shipment = new Shipment(weight: 500, length: 10, width: 10, height: 10, zone: 'java', distanceKm: 8);

    expect(fn () => $service->quote('cityrider', $shipment))
        ->toThrow(InvalidArgumentException::class);
});

it('throws when an unsupported courier is requested', function () {
    $service = app(ShippingService::class);
    $shipment = new Shipment(weight: 1000, length: 10, width: 10, height: 10, zone: 'java', distanceKm: 0);

    expect(fn () => $service->quote('unknown', $shipment))
        ->toThrow(InvalidArgumentException::class);
});
```

Run the suite to confirm the refactor preserved behavior.

```bash
php artisan test
```

The same nine tests pass, with the same assertion count.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                       0.12s  

   PASS  Tests\Feature\ShippingQuoteTest
  ✓ it rejects requests without required fields                         0.10s  
  ✓ it quotes swiftpost using actual weight when it beats volumetric    0.03s  
  ✓ it quotes swiftpost using volumetric weight when the box is bulky   0.02s  
  ✓ it quotes budgetship on actual weight only, ignoring volumetric     0.02s  
  ✓ it quotes cityrider by distance within the city                     0.02s  
  ✓ it rejects cityrider outside the city zone                          0.02s  
  ✓ it throws when an unsupported courier is requested                  0.02s  

  Tests:    9 passed (24 assertions)
  Duration: 0.42s
```

Nine passing, twenty-four assertions, exactly as before. The buyer-facing behavior is identical; only the internal structure changed. The next step shows what that structure buys us.

## Step 13: Add a New Courier Without Touching Existing Code {#step-13-add-a-new-courier-without-touching-existing-code}

The business signs a contract with MetroExpress. The point of this step is everything we do not have to touch: not `ShippingService`, not the contract, not the three existing calculators, not the controller, and not the seven tests that already pass. We write one new class and add one line to a list.

Create `app/Services/Shipping/Calculators/MetroExpressCalculator.php` with the following content. MetroExpress prices like SwiftPost but uses the `6000` volumetric divisor and its own rate card, which is exactly the kind of variation the contract was built to absorb.

```php
<?php

namespace App\Services\Shipping\Calculators;

use App\Contracts\ShippingCalculator;
use App\DataObjects\Shipment;

class MetroExpressCalculator implements ShippingCalculator
{
    public function courier(): string
    {
        return 'metroexpress';
    }

    /**
     * MetroExpress Regular bills on chargeable weight like SwiftPost, but uses the
     * 6000 volumetric divisor and its own rate card.
     */
    public function calculate(Shipment $shipment): int
    {
        $rates = [
            'jabodetabek'  => 10000,
            'java'         => 13000,
            'outside_java' => 24000,
        ];

        $chargeableKg = $shipment->chargeableKg(volumetricDivisor: 6000);

        return $chargeableKg * $rates[$shipment->zone];
    }
}
```

Now register it. This is the single line of modification we allow, because the service provider is the documented place where the courier list is configured. Open `app/Providers/AppServiceProvider.php`. The tag call currently lists three calculators.

```php
$this->app->tag([
    SwiftPostCalculator::class,
    BudgetShipCalculator::class,
    CityRiderCalculator::class,
], 'shipping.calculators');
```

Add the new calculator to the list.

```php
$this->app->tag([
    SwiftPostCalculator::class,
    BudgetShipCalculator::class,
    CityRiderCalculator::class,
    MetroExpressCalculator::class,              // newly added line
], 'shipping.calculators');
```

Add the matching import alongside the other calculator imports at the top of the file.

```php
use App\Services\Shipping\Calculators\MetroExpressCalculator;
```

To prove the new courier works and that registration took effect, append two tests to the bottom of `tests/Feature/ShippingQuoteTest.php`.

```php
it('quotes the newly added metroexpress courier', function () {
    // 3000 g in a small 10x10x10 box, jabodetabek @ 10000/kg.
    // chargeable = ceil(3000/1000) = 3 kg, so 3 * 10000 = 30000.
    $this->postJson('/api/shipping/quote', [
            'courier' => 'metroexpress',
            'weight'  => 3000,
            'length'  => 10,
            'width'   => 10,
            'height'  => 10,
            'zone'    => 'jabodetabek',
        ])
         ->assertStatus(201)
         ->assertJsonPath('courier', 'metroexpress')
         ->assertJsonPath('cost', 30000);
});

it('reports metroexpress as a supported courier after registration', function () {
    $service = app(ShippingService::class);

    expect($service->supported())->toContain('metroexpress');
});
```

## Step 14: Run All Tests Again {#step-14-run-all-tests-again}

Run the full suite one last time.

```bash
php artisan test
```

The seven original tests still pass, and the two new MetroExpress tests pass too, for eleven in total.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                       0.11s  

   PASS  Tests\Feature\ShippingQuoteTest
  ✓ it rejects requests without required fields                         0.09s  
  ✓ it quotes swiftpost using actual weight when it beats volumetric    0.03s  
  ✓ it quotes swiftpost using volumetric weight when the box is bulky   0.02s  
  ✓ it quotes budgetship on actual weight only, ignoring volumetric     0.02s  
  ✓ it quotes cityrider by distance within the city                     0.02s  
  ✓ it rejects cityrider outside the city zone                          0.02s  
  ✓ it throws when an unsupported courier is requested                  0.02s  
  ✓ it quotes the newly added metroexpress courier                      0.02s  
  ✓ it reports metroexpress as a supported courier after registration   0.02s  

  Tests:    11 passed (28 assertions)
  Duration: 0.44s
```

That is the payoff. A new courier arrived as one new file plus one line in a list. No existing calculator was edited, no existing test changed, and the nine tests that protected the old behavior never lit up red. That is what the Strategy pattern is for.

## Understanding the Strategy Pattern {#understanding-the-strategy-pattern}

The Strategy pattern defines a family of interchangeable algorithms, puts each one behind a common interface, and lets the calling code select which algorithm to run at runtime. The first time you read that definition it sounds abstract. After the refactor above, each part of it has a name in our code.

The interface is the strategy role, and ours is `ShippingCalculator`. Each concrete algorithm is a concrete strategy, and ours are `SwiftPostCalculator`, `BudgetShipCalculator`, `CityRiderCalculator`, and `MetroExpressCalculator`. The object that holds the strategies and decides which one to run is the context, and ours is `ShippingService`. The data the algorithms operate on travels in the `Shipment` object, which keeps every strategy's `calculate` signature identical even though SwiftPost reads dimensions and CityRider reads distance.

The defining trait, the one that separates Strategy from ordinary inheritance, is that the selection happens at runtime from data. Our context picks a calculator using the `courier` string that arrived in the HTTP request, which is a value the buyer chose at checkout. Nothing is decided at compile time. If tomorrow you load the courier from a database column or a feature flag, the context does not change at all, because it already treats the choice as runtime data.

## Strategy Pattern vs the Open/Closed Principle {#strategy-vs-ocp}

Readers who followed the [Open/Closed Principle article](https://qadrlabs.com/post/openclosed-principle-in-laravel-build-an-extensible-payment-gateway-system) will notice that this refactor looks familiar, and that is the point worth making explicit. The two ideas operate at different levels.

The Open/Closed Principle is a goal: software entities should be open for extension but closed for modification. It tells you what good extensible code feels like, but it does not tell you how to build it. The Strategy pattern is one concrete technique for reaching that goal. By moving each algorithm behind a shared interface and selecting among them at runtime, Strategy makes the context class closed to modification, since new algorithms arrive as new classes, while keeping the system open to extension. When we added MetroExpress without editing `ShippingService`, that was OCP satisfied, and the Strategy pattern is the mechanism that satisfied it.

The two are not the same thing, though. OCP can also be achieved with other patterns, such as Decorator for layering behavior or a Chain of Responsibility for sequential handlers. And Strategy is useful even when OCP is not your main concern, for example when you simply want to swap a sorting algorithm or a pricing experiment at runtime. Think of OCP as the why and Strategy as one well-worn how.

## When to Reach for Strategy (and When Not To) {#when-to-use-strategy}

Strategy earns its keep when you have a family of algorithms that vary independently, are chosen at runtime, and are expected to grow in number. Shipping couriers, payment gateways, tax calculators, export formats, and import parsers all fit, because the list keeps changing and each member is a self-contained variation on a shared theme. The signal in the code is an `if/elseif` or `match` over a type string where each branch is a chunk of behavior rather than a tiny tweak.

It is overkill when the branches are stable and few. Two cases that have not changed in years, like distinguishing a weekday rate from a weekend rate, do not need four new files and a service provider; a plain `if` is honest and readable. Reaching for Strategy there adds indirection without buying you anything, and indirection has a real cost when a newcomer has to open five files to follow one calculation. A good rule is to introduce the pattern on the second or third branch you add, once the direction of change is obvious, rather than speculatively on the first.

It is worth knowing that Laravel itself leans on this pattern constantly, which is why the container made our refactor so smooth. The framework's Manager classes, such as the ones behind cache stores, queue drivers, filesystem disks, and notification channels, are Strategy implementations that resolve a concrete driver at runtime from your configuration. When you switch `CACHE_STORE` from `file` to `redis` in your `.env`, you are selecting a strategy. Matching that style in your own code makes it instantly familiar to any other Laravel developer.

## Conclusion {#conclusion}

The Strategy pattern turns a branching method that everyone is afraid to touch into a set of small classes that each do one job, selected at runtime by data. It is the practical tool that makes the Open/Closed Principle real in day-to-day Laravel work, and the service container gives you the wiring for free.

Here are the key takeaways to carry forward:

- **The smell is a branch over a type string.** An `if/elseif` or `match` on a courier, gateway, or format name, where each branch is real logic, is the most reliable sign that a Strategy pattern is waiting to be extracted.
- **One interface, many independent classes.** Each concrete strategy lives in its own file and knows one algorithm, so changing one courier's rate card cannot break another courier.
- **A context object keeps signatures stable.** Passing a readonly `Shipment` instead of seven scalars lets every strategy share one `calculate` signature even when they read different fields, and immutability stops strategies from interfering with each other.
- **Let the container assemble and select strategies.** Laravel's `tag` and `tagged` give you a registry of strategies injected as an iterable, so the context never imports a concrete strategy and stays closed.
- **The configuration point is allowed to grow.** A service provider that tags one more calculator per new courier is the documented extension surface, not a violation. Adding a line there is additive; editing an existing algorithm is not.
- **Strategy is the how, OCP is the why.** The pattern is one concrete way to keep code open for extension and closed for modification, and recognizing the relationship helps you choose it deliberately rather than by habit.
- **Introduce it on the second or third branch, not the first.** Wait until the direction of change is obvious, so you pay the cost of indirection only where it buys real flexibility.
