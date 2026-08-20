## 1. Before You Begin

Four principles down, and each has been about the shape of a thing. How many reasons a class has to change. Whether it can be extended without being edited. Whether its implementations keep their promises. Whether it asks for more than its clients need.

The fifth is about direction. Right now, if you draw an arrow from every class in SolidLab to the classes it names, most arrows point sensibly downward: a controller points at a service, a service points at a model. The Dependency Inversion Principle says some of those arrows are pointing the wrong way, and that turning them around is what makes the other four principles enforceable rather than merely advisable.

The symptom is easy to recognize once you know it. Somewhere in a request handler there is a `new` keyword followed by the name of a third party integration, and the class containing that line cannot be tested, configured, or reasoned about without dragging the whole integration along with it. This lesson writes that line on purpose, feels the consequences in the test suite, and then inverts it.

### What You'll Build

A newsletter subscription endpoint in SolidLab that starts with `new MailchimpProvider(...)` in the middle of a controller. You will test it, notice that the tests are about HTTP rather than about subscribing, then extract a `NewsletterProvider` contract, add a Sendgrid implementation and a fake, bind the contract in a service provider driven by configuration, and rewrite the tests so they never mention HTTP at all.

### What You'll Learn

- ✅ How to spot a dependency arrow pointing from high level code at a low level detail
- ✅ How to design a contract around the consumer's needs rather than a provider's response shape
- ✅ How to bind an interface to a concrete class in a service provider using configuration
- ✅ How `$this->app->instance()` swaps an implementation for a single test
- ✅ The real differences between dependency inversion, dependency injection, and inversion of control
- ✅ How contextual binding gives one consumer a different implementation from everyone else
- ✅ When adding an abstraction is genuinely dead weight

### What You'll Need

- SolidLab with Lessons 3 through 6 complete
- `AppServiceProvider` still holding the payment gateway tagging from Lesson 4, since this lesson adds to it rather than replacing it
- Familiarity with Laravel's `Http` facade and `config()` helper

---

## 2. Set Up the Subscription Domain

The application keeps its own record of every subscription in addition to forwarding the email to a third party. That local record is what the endpoint returns and what the tests assert against.

### Step 1: Generate the Model and Migration

```bash
php artisan make:model Subscription -m
```

### Step 2: Define the Subscriptions Table

Open the generated migration and replace its contents.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->string('provider');
            $table->string('external_id')->nullable();
            $table->string('status')->default('active');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
```

The `provider` column is the interesting one. Recording which provider handled a subscription is a practical necessity once more than one can, because unsubscribing later means talking to whichever service holds the record. It also gives the tests an observable way to confirm which implementation was actually used, which becomes the whole point in section 8.

`external_id` is nullable because the identifier comes back from the provider and its format is entirely theirs. Storing it as a plain string rather than modeling it is a deliberate choice that section 10 returns to.

### Step 3: Configure the Model

Replace `app/Models/Subscription.php`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'email',
    'provider',
    'external_id',
    'status',
])]
class Subscription extends Model
{
    //
}
```

No casts this time, since every column is already a string. The empty class body is a good sign: this model holds data and nothing else.

### Step 4: Run the Migration

```bash
php artisan migrate
```

```
   INFO  Running migrations.  

  2026_08_18_153017_create_subscriptions_table .................. 14.04ms DONE
```

---

## 3. Build the Tightly Coupled Version

Now write the antipattern. A provider class that talks to a real API, and a controller that constructs it inline.

### Step 1: Write the MailchimpProvider

```bash
mkdir -p app/Services/Newsletter
```

Create `app/Services/Newsletter/MailchimpProvider.php`.

```php
<?php

namespace App\Services\Newsletter;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class MailchimpProvider
{
    public function __construct(
        private string $apiKey,
        private string $baseUrl = 'https://api.mailchimp.com/3.0',
    ) {}

    public function subscribe(string $email): string
    {
        $response = Http::withToken($this->apiKey)
            ->asJson()
            ->post("{$this->baseUrl}/lists/main/members", [
                'email_address' => $email,
                'status'        => 'subscribed',
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('Mailchimp subscribe failed: ' . $response->status());
        }

        // Mailchimp returns an "id" field on success.
        return (string) $response->json('id');
    }
}
```

This class is not the problem. It is a perfectly reasonable low level module: it knows one API, formats one request, checks one response, and reports one result. Every SOLID principle so far would approve of it.

Taking the base URL as a constructor argument with a sensible default is what makes it testable at all, since a test can point it somewhere harmless. Note the two scalar constructor parameters, which Lesson 3's Error 3 flagged as something the container cannot autowire. Hold that thought; it becomes the reason section 6 needs a binding closure.

### Step 2: Write the Controller That Constructs It

```bash
php artisan make:controller NewsletterController
```

Replace `app/Http/Controllers/NewsletterController.php`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use App\Services\Newsletter\MailchimpProvider;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NewsletterController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        // DIP violation: the controller knows about a specific provider
        // class and constructs it directly. There is no abstraction.
        $provider = new MailchimpProvider(
            apiKey:  config('services.mailchimp.api_key', 'fake-key'),
            baseUrl: config('services.mailchimp.base_url', 'https://api.mailchimp.com/3.0'),
        );

        $externalId = $provider->subscribe($validated['email']);

        $subscription = Subscription::create([
            'email'       => $validated['email'],
            'provider'    => 'mailchimp',
            'external_id' => $externalId,
        ]);

        return response()->json($subscription, 201);
    }
}
```

Count what this controller knows that it should not. It knows a class called `MailchimpProvider` exists. It knows that class takes an API key and a base URL in that order. It knows where in the config those values live. It knows the literal string `'mailchimp'` belongs in the database. Four facts about a low level detail, embedded in a method whose actual job is "subscribe someone to the newsletter".

The word `'mailchimp'` appearing as a hardcoded string next to a `new MailchimpProvider` is the tell. The controller is not recording which provider handled the call; it is asserting an answer it happens to already know, because it chose the provider itself.

### Step 3: Add the Configuration

Open `config/services.php` and add these entries to the returned array.

```php
    'mailchimp' => [
        'api_key'  => env('MAILCHIMP_API_KEY', 'fake-mailchimp-key'),
        'base_url' => env('MAILCHIMP_BASE_URL', 'https://api.mailchimp.com/3.0'),
    ],

    'sendgrid' => [
        'api_key'  => env('SENDGRID_API_KEY', 'fake-sendgrid-key'),
        'base_url' => env('SENDGRID_BASE_URL', 'https://api.sendgrid.com/v3'),
    ],

    'newsletter' => [
        'driver' => env('NEWSLETTER_DRIVER', 'mailchimp'),
    ],
```

The `sendgrid` and `newsletter` blocks are not used yet; adding them now saves a return trip. The `newsletter.driver` key is the one that eventually decides everything, and note that it currently decides nothing at all: the controller ignores it and constructs Mailchimp regardless. Configuration that describes an intention the code does not honor is its own small warning sign.

### Step 4: Register the Route

Open `routes/web.php` and add the newsletter route.

```php
<?php

use App\Http\Controllers\InvoiceController;
use App\Http\Controllers\NewsletterController;
use App\Http\Controllers\PaymentController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/invoices', [InvoiceController::class, 'store'])->name('invoices.store');
Route::post('/payments', [PaymentController::class, 'store'])->name('payments.store');
Route::post('/newsletter/subscribe', [NewsletterController::class, 'store'])
    ->name('newsletter.subscribe');
```

---

## 4. Write Tests and Notice What They Are Actually Testing

The controller can be tested, which is worth acknowledging up front. Tight coupling does not make code untestable; it makes the tests test the wrong thing.

### Step 1: Create the Test File

```bash
php artisan make:test NewsletterSubscriptionTest --pest
```

### Step 2: Write Two Tests Around the Coupling

Replace `tests/Feature/NewsletterSubscriptionTest.php`.

```php
<?php

use App\Models\Subscription;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

it('rejects requests without a valid email', function () {
    $this->postJson('/newsletter/subscribe', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['email']);
});

it('subscribes a new email and persists the record', function () {
    Http::fake([
        '*api.mailchimp.com*' => Http::response(['id' => 'mc-abc123'], 200),
    ]);

    $this->postJson('/newsletter/subscribe', ['email' => 'asriyanik@example.com'])
         ->assertStatus(201)
         ->assertJsonPath('email', 'asriyanik@example.com')
         ->assertJsonPath('provider', 'mailchimp')
         ->assertJsonPath('external_id', 'mc-abc123');

    expect(Subscription::count())->toBe(1);
});
```

`Http::fake()` intercepts outgoing requests and returns canned responses, matched by URL pattern. Without it this test would attempt a real network call to Mailchimp, which would fail slowly, non deterministically, and differently on every machine.

Now read the second test as a description of what it verifies. It states that a request to a URL matching `*api.mailchimp.com*` will receive a JSON body containing an `id` key, and that the value of that key ends up in a database column. Every one of those facts is about Mailchimp's HTTP API. Not one is about subscribing to a newsletter.

That mismatch is the diagnostic. The test had to reach down to the HTTP layer because the controller offered no seam any higher up. When your feature tests are full of URL patterns and third party response shapes, the usual cause is not a testing problem; it is a missing abstraction, and the tests are simply reporting it.

### Step 3: Run the Baseline

```bash
php artisan test tests/Feature/NewsletterSubscriptionTest.php
```

```
   PASS  Tests\Feature\NewsletterSubscriptionTest
  ✓ it rejects requests without a valid email                            0.28s  
  ✓ it subscribes a new email and persists the record                    0.06s  

  Tests:    2 passed (8 assertions)
  Duration: 0.41s
```

**2 passed, 8 assertions.** Green, and testing the wrong layer.

---

## 5. Invert the Dependency

The refactor has three parts: define the abstraction, make the implementations satisfy it, and point the controller at it instead of at a concrete class.

### Step 1: Define the NewsletterProvider Contract

Create `app/Contracts/NewsletterProvider.php`.

```php
<?php

namespace App\Contracts;

interface NewsletterProvider
{
    /**
     * Subscribe an email address to the configured newsletter list.
     * Returns the external identifier assigned by the provider.
     */
    public function subscribe(string $email): string;

    /**
     * The provider name as a lowercase string. Used when persisting
     * subscription records.
     */
    public function name(): string;
}
```

Two methods, and the design decision is in what they return rather than in what they are called.

`subscribe()` returns a `string`, not a `MailchimpResponse` object, not an array shaped like Mailchimp's JSON. That is the second half of DIP in practice: abstractions must not depend on details. The moment the contract returns a Mailchimp specific type, the contract itself is coupled to Mailchimp, and adding Sendgrid would force the contract to change. Design the return type around what the consumer needs, which here is an opaque identifier to store.

`name()` exists because the controller needs to record which provider handled the call and, after this refactor, will genuinely not know. This is the same move as `PaymentGateway::name()` in Lesson 4, and for the same reason: identity belongs to the implementation.

Notice what is absent. No `unsubscribe()`, no `addTag()`, no `listMembers()`, even though both real APIs support all three. Lesson 6 named that habit: a contract with methods nobody calls manufactures stub implementations. Add them when a consumer needs them, as separate capability interfaces if only some providers support them.

### Step 2: Make MailchimpProvider Implement the Contract

Replace `app/Services/Newsletter/MailchimpProvider.php`.

```php
<?php

namespace App\Services\Newsletter;

use App\Contracts\NewsletterProvider;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class MailchimpProvider implements NewsletterProvider
{
    public function __construct(
        private string $apiKey,
        private string $baseUrl = 'https://api.mailchimp.com/3.0',
    ) {}

    public function subscribe(string $email): string
    {
        $response = Http::withToken($this->apiKey)
            ->asJson()
            ->post("{$this->baseUrl}/lists/main/members", [
                'email_address' => $email,
                'status'        => 'subscribed',
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('Mailchimp subscribe failed: ' . $response->status());
        }

        return (string) $response->json('id');
    }

    public function name(): string
    {
        return 'mailchimp';
    }
}
```

Two changes: an `implements` clause and a `name()` method. The HTTP logic is untouched, because it was never the problem. The arrow from this class now points at the contract instead of being pointed at by the controller.

### Step 3: Add a Second Implementation

An abstraction with one implementation is a hypothesis. Create `app/Services/Newsletter/SendgridProvider.php`.

```php
<?php

namespace App\Services\Newsletter;

use App\Contracts\NewsletterProvider;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class SendgridProvider implements NewsletterProvider
{
    public function __construct(
        private string $apiKey,
        private string $baseUrl = 'https://api.sendgrid.com/v3',
    ) {}

    public function subscribe(string $email): string
    {
        $response = Http::withToken($this->apiKey)
            ->asJson()
            ->post("{$this->baseUrl}/marketing/contacts", [
                'contacts' => [['email' => $email]],
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('Sendgrid subscribe failed: ' . $response->status());
        }

        // Sendgrid returns a job_id on success.
        return (string) $response->json('job_id');
    }

    public function name(): string
    {
        return 'sendgrid';
    }
}
```

The two providers differ in every detail that matters: different endpoint path, different request body shape, different response key (`id` versus `job_id`). Every one of those differences is absorbed inside the class and none of it reaches the contract. That is the test of whether an abstraction is real.

This is also where the Lesson 5 discipline applies. Both implementations must return the same *kind* of value, throw the same kind of exception, and behave the same way from the caller's point of view. A `SendgridProvider` that returned a JSON blob instead of an ID would satisfy the type hint and break every consumer, which is exactly the violation Lesson 5 planted deliberately.

### Step 4: Add a Fake for Tests

Create `app/Services/Newsletter/FakeNewsletterProvider.php`.

```php
<?php

namespace App\Services\Newsletter;

use App\Contracts\NewsletterProvider;

class FakeNewsletterProvider implements NewsletterProvider
{
    /** @var array<int, string> */
    public array $subscribed = [];

    public function subscribe(string $email): string
    {
        $this->subscribed[] = $email;

        // Deterministic external ID for assertions.
        return 'fake-' . md5($email);
    }

    public function name(): string
    {
        return 'fake';
    }

    public function reset(): void
    {
        $this->subscribed = [];
    }
}
```

The fake is application code, not test scaffolding, and it lives in `app/` alongside the real providers for that reason. It is also evidence about the contract: a contract you can implement completely in fifteen lines with no external dependency is a contract sized correctly. If a fake requires substantial machinery to write, the contract is doing too much.

`md5($email)` gives a deterministic identifier, so a test can compute the expected value rather than accepting whatever comes back. `$subscribed` is public so tests can inspect what the controller asked for, which is a capability the real providers cannot offer.

### Step 5: Point the Controller at the Contract

Replace `app/Http/Controllers/NewsletterController.php`.

```php
<?php

namespace App\Http\Controllers;

use App\Contracts\NewsletterProvider;
use App\Models\Subscription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NewsletterController extends Controller
{
    public function __construct(private NewsletterProvider $provider) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        $externalId = $this->provider->subscribe($validated['email']);

        $subscription = Subscription::create([
            'email'       => $validated['email'],
            'provider'    => $this->provider->name(),
            'external_id' => $externalId,
        ]);

        return response()->json($subscription, 201);
    }
}
```

Compare the imports against section 3. `MailchimpProvider` is gone, replaced by the contract. Every one of the four facts the controller used to know about Mailchimp has left the file: the class name, the constructor signature, the config keys, and the hardcoded `'mailchimp'` string, which became `$this->provider->name()`.

That last substitution is the one to notice. The controller no longer asserts which provider ran; it asks. It cannot answer the question itself, because it genuinely does not know, and not knowing is precisely the property that was wanted.

The `store` method also lost four lines and gained nothing. Inverting a dependency usually makes the consumer smaller, because constructing a collaborator is work the consumer was never supposed to be doing.

---

## 6. Bind the Contract in the Container

The controller asks for a `NewsletterProvider`. Something has to decide which one it gets, and that decision belongs in exactly one place.

### Step 1: Add the Binding to AppServiceProvider

Open `app/Providers/AppServiceProvider.php` and add a newsletter binding alongside the payment gateway registrations from Lesson 4. The whole file should now read as follows.

```php
<?php

namespace App\Providers;

use App\Contracts\NewsletterProvider;
use App\Services\Newsletter\MailchimpProvider;
use App\Services\Newsletter\SendgridProvider;
use App\Services\Payment\Gateways\MidtransGateway;
use App\Services\Payment\Gateways\PaypalGateway;
use App\Services\Payment\Gateways\StripeGateway;
use App\Services\PaymentService;
use Illuminate\Support\ServiceProvider;
use InvalidArgumentException;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Register every gateway implementation under a shared tag.
        $this->app->tag([
            PaypalGateway::class,
            StripeGateway::class,
            MidtransGateway::class,
        ], 'payment.gateways');

        // Resolve the service with all tagged gateways injected as an iterable.
        $this->app->singleton(PaymentService::class, function ($app) {
            return new PaymentService($app->tagged('payment.gateways'));
        });

        // Bind the newsletter contract to whichever driver is configured.
        $this->app->bind(NewsletterProvider::class, function ($app) {
            $driver = config('services.newsletter.driver');

            return match ($driver) {
                'mailchimp' => new MailchimpProvider(
                    apiKey:  config('services.mailchimp.api_key'),
                    baseUrl: config('services.mailchimp.base_url'),
                ),
                'sendgrid' => new SendgridProvider(
                    apiKey:  config('services.sendgrid.api_key'),
                    baseUrl: config('services.sendgrid.base_url'),
                ),
                default => throw new InvalidArgumentException(
                    "Unknown newsletter driver: {$driver}"
                ),
            };
        });
    }

    public function boot(): void
    {
        //
    }
}
```

`bind()` registers a recipe: when anything asks for `NewsletterProvider`, run this closure. `bind` rather than `singleton` means a fresh instance per resolution, which matters here because the driver is read from config each time and could differ between a web request and a queued job in the same process.

The closure is required because the container cannot autowire either provider, both of which take two `string` parameters. Reflection can resolve a type hinted class and cannot invent a string, which is Lesson 3's Error 3 arriving as promised. The closure supplies exactly the knowledge reflection lacks.

The `match` on the driver keeps the entire decision in one expression, and the `default` arm throws rather than falling back silently, so a typo in `NEWSLETTER_DRIVER` fails loudly at boot instead of quietly subscribing nobody.

Look at where knowledge now lives. The controller knows the contract. The providers know their APIs. This file, and only this file, knows how those two sets of facts connect. Switching production from Mailchimp to Sendgrid is a change to one environment variable, with no application code touched.

Notice too that the file now contains two entirely different binding styles, tagging for the gateway registry and a config driven `match` for the newsletter, sitting side by side without interfering. A service provider is a composition root, and being the one place where concrete choices are made is its whole purpose.

### Step 2: Rewrite the Tests Without HTTP

Replace `tests/Feature/NewsletterSubscriptionTest.php`.

```php
<?php

use App\Contracts\NewsletterProvider;
use App\Models\Subscription;
use App\Services\Newsletter\FakeNewsletterProvider;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    // Replace the bound implementation with the fake for this test only.
    // The container's instance() call is the test-time equivalent of
    // editing the binding in a service provider.
    $this->fake = new FakeNewsletterProvider();
    $this->app->instance(NewsletterProvider::class, $this->fake);
});

it('rejects requests without a valid email', function () {
    $this->postJson('/newsletter/subscribe', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['email']);
});

it('subscribes a new email and persists the record', function () {
    $this->postJson('/newsletter/subscribe', ['email' => 'asriyanik@example.com'])
         ->assertStatus(201)
         ->assertJsonPath('email', 'asriyanik@example.com')
         ->assertJsonPath('provider', 'fake')
         ->assertJsonPath('external_id', 'fake-' . md5('asriyanik@example.com'));

    expect(Subscription::count())->toBe(1)
        ->and($this->fake->subscribed)->toBe(['asriyanik@example.com']);
});

it('reports the provider name correctly on the persisted record', function () {
    $this->postJson('/newsletter/subscribe', ['email' => 'second@example.com'])
         ->assertStatus(201);

    expect(Subscription::first()->provider)->toBe('fake');
});
```

`$this->app->instance()` hands the container an object that already exists and says to return this exact instance for that contract from now on. Holding it in `$this->fake` lets the test both drive the endpoint and inspect what the fake recorded, which is why the second test can assert on `$this->fake->subscribed`.

Read what these tests now say. A valid email produces a subscription record. The provider that handled it is recorded. The email the controller passed to the provider is the email that was submitted. Three statements about the application's own behavior, and not one word about HTTP, URLs, tokens, or third party response shapes.

The `Http` import is gone. So is `Http::fake()`. There is nothing left to fake, because the thing that used to make HTTP calls is no longer part of this test at all.

---

## 7. Run and Test

```bash
php artisan test tests/Feature/NewsletterSubscriptionTest.php
```

```
   PASS  Tests\Feature\NewsletterSubscriptionTest
  ✓ it rejects requests without a valid email                            0.19s  
  ✓ it subscribes a new email and persists the record                    0.03s  
  ✓ it reports the provider name correctly on the persisted record       0.02s  

  Tests:    3 passed (11 assertions)
  Duration: 0.32s
```

Three tests instead of two, and the extra one exists because the refactor made a new question worth asking. The assertion count went from 8 to 11 while the tests got simpler, which is the shape of a good abstraction: less machinery, more actually verified.

This is not a behavior preserving refactor in the Lesson 3 sense, and the test file changed substantially. The endpoint's contract with its callers is identical, but the tests were deliberately moved to a different layer, which was the entire objective.

Now confirm that nothing across the whole course broke, since this lesson edited `AppServiceProvider` and `routes/web.php`, both of which earlier lessons depend on.

```bash
php artisan test
```

```
   PASS  Tests\Feature\SetupTest
  ✓ it boots the application in the testing environment                  0.03s  
  ✓ it uses the sqlite connection                                        0.02s  
  ✓ it has an app contracts directory ready                              0.03s  

  Tests:    35 passed (85 assertions)
  Duration: 1.04s
```

Thirty five tests across five feature areas, all green, in about a second. Worth noting how fast that is: SolidLab talks to two payment providers, a mail system, a filesystem, and two newsletter APIs, and its entire suite runs in roughly the time one real HTTP call would take. Every one of those integrations sits behind an abstraction with a fake or a Laravel provided test double on the other side.

---

## 8. Understanding Dependency Inversion

Robert C. Martin's formulation has two halves. High level modules should not depend on low level modules; both should depend on abstractions. And abstractions should not depend on details; details should depend on abstractions.

The first half is what section 5 did. `NewsletterController` is the high level module: its job is the application's own concept of subscribing someone. `MailchimpProvider` is the low level module: its job is formatting an HTTP request for one vendor. Before, the arrow pointed from high to low, so any change to the vendor integration reached up into the controller and the controller could not be exercised without dragging the integration along. After, both point at `NewsletterProvider`. The arrow from the low level module was reversed, which is what the word "inversion" refers to.

The second half is what section 5's contract design did, and it is the half people skip. If `subscribe()` had been declared to return a `MailchimpResponse`, the abstraction would itself depend on a Mailchimp detail. `SendgridProvider` would have to construct a Mailchimp shaped object to satisfy a contract meant to be vendor neutral, and the inversion would be cosmetic. Contracts must be designed from the consumer's needs, not generalized upward from whichever implementation was written first.

The diagnostic is a thought experiment: if you deleted the file containing the low level module, would the high level module still be valid? Before the refactor, deleting `MailchimpProvider.php` breaks `NewsletterController` immediately, because it imports and constructs it. After, deleting it breaks one arm of a `match` in a service provider, and the controller is untouched. That structural difference is the whole principle.

There is a second, quieter benefit visible in the test suite. Before, the only seam available was the HTTP boundary, so tests had to reach down and pretend to be Mailchimp. After, the seam is the contract, which sits exactly where the application's concepts meet the outside world. Good abstractions put seams where you want to cut.

---

## 9. DIP, Dependency Injection, and Inversion of Control

Three terms, constantly used as synonyms, all genuinely different. Untangling them is one of the more useful things a Laravel developer can do, because the framework uses all three at once.

**The Dependency Inversion Principle is a design principle.** It says: depend on abstractions, not on concrete classes. It is satisfied or violated by the shape of your code, regardless of mechanism. You can satisfy DIP with no framework at all, by hand constructing everything in one entry point and passing interfaces down.

**Dependency injection is a technique.** It says: a class should receive its collaborators from outside rather than construct them, usually through the constructor. It is the most common way to satisfy DIP, and it is not the same thing. You can have DI without DIP, by injecting a concrete class, which still leaves the consumer coupled to a specific type. You can have DIP without DI, by depending on an interface and resolving it through a service locator, which is rarely a good idea but is possible.

**Inversion of control is an architectural pattern.** It says: rather than your code calling into a framework, the framework calls into your code. A plain script is in charge of its own flow. Laravel is not: you register routes, jobs, listeners, and commands, and the framework decides when to invoke them.

Now map them onto the code you just wrote. The `NewsletterProvider` interface is the abstraction, which is DIP. The `private NewsletterProvider $provider` constructor parameter is dependency injection. The `bind()` call in the service provider is where the inversion is actually configured. And all of it runs inside Laravel's inversion of control architecture, since nothing in your code ever calls `NewsletterController::store` directly; the router does, when a request arrives.

The practical value of keeping them distinct is that it tells you where to look when something is wrong. If the wrong provider is being used, the binding is wrong (DIP configuration). If nothing is being provided at all, the constructor or the type hint is wrong (DI). If your handler never runs, the route or listener registration is wrong (IoC). Three different files, three different failures, one blurry phrase that hides which is which.

---

## 10. Contextual Binding

Sometimes one consumer needs a different implementation from everyone else. An admin bulk import that should always use the high volume provider, a queued job that should use a different list, a legacy endpoint pinned to an old integration during a migration.

The naive solutions are all bad. A global flag means every consumer has to read it and agree on what it means. A second interface duplicates a contract that has not actually changed. A parameter on `subscribe()` pushes a deployment concern into a domain method. Laravel's container solves it directly.

```php
$this->app->when(AdminBulkSubscribeController::class)
    ->needs(NewsletterProvider::class)
    ->give(function ($app) {
        return new SendgridProvider(
            apiKey:  config('services.sendgrid.api_key'),
            baseUrl: config('services.sendgrid.base_url'),
        );
    });
```

The three clauses read as one sentence. `when()` names the consumer, `needs()` names the abstraction it will ask for, and `give()` supplies what it gets instead of the default. Every other consumer of `NewsletterProvider` continues to receive whatever the driver config selects.

What makes this powerful is that the variation is expressed entirely in the composition root. `AdminBulkSubscribeController` is written exactly like `NewsletterController`, type hinting the contract and knowing nothing. It does not know it is special, and if the policy changes, the controller does not change. Exercise 2 builds this and proves it works.

---

## 11. Common DIP Pitfalls

**Depending on the abstraction in name only.** A controller that type hints `NewsletterProvider` and then does `if ($this->provider instanceof MailchimpProvider)` to reach a vendor specific method has not inverted anything; it has added a file. Downcasts and `instanceof` checks on an injected contract inside a high level module mean the contract is too thin for what the consumer actually needs. Widen the contract or admit the coupling.

**Leaky abstractions.** If the contract exposes a type owned by the low level module, a `MailchimpResponse`, a vendor specific enum, a provider exception class, the coupling survives through the type system. Contracts should traffic in primitives, in types the high level module already owns, or in value objects defined next to the contract itself.

**Binding everything.** DIP is for dependencies that vary: across environments, across tests, across consumers. A value object, a date formatter, a one off helper with a single implementation that has never been swapped should just be `new`ed. Over binding turns the service provider into a graveyard of one line entries and makes every dependency harder to trace for no benefit.

**Reading DIP as "always use interfaces".** This is the same trap Lesson 1's Error 2 described. An interface with one implementation, no test double, and no environment variation costs a file, an indirection, and reading effort, and returns nothing. The three things that justify an abstraction are a fake for testing, variation across environments, and genuine extension pressure. `NewsletterProvider` earns its place on all three. Many interfaces earn it on none.

**Fighting the container.** Teams sometimes treat the container as opaque and build their own factories and registries. Laravel's container is mature, well documented, and integrated with route model binding, queued job resolution, and event listener resolution. Nine times out of ten the container is the answer, and the tenth case is usually still a binding closure in a service provider.

---

## 12. Fix the Errors in Your Code

**Error 1: Type hinting the contract while still constructing the concrete class.**

The constructor looks inverted, and nothing actually changed.

```php
// Wrong: the type hint is decoration, the class still picks its own provider
class NewsletterController extends Controller
{
    private NewsletterProvider $provider;

    public function __construct()
    {
        $this->provider = new MailchimpProvider(
            apiKey: config('services.mailchimp.api_key'),
        );
    }
}

// Correct: the class names what it needs and lets the container supply it
class NewsletterController extends Controller
{
    public function __construct(private NewsletterProvider $provider) {}
}
```

The test is whether a caller can supply a different implementation without editing the class. In the wrong version, no, which means `$this->app->instance()` has nothing to override and the tests are back to faking HTTP. This is Lesson 1's Error 3, and it is worth repeating because the wrong version genuinely looks correct at a glance.

**Error 2: Binding the concrete class instead of the contract.**

```php
// Wrong: nothing asks for MailchimpProvider, so this binding is never used
$this->app->bind(MailchimpProvider::class, function ($app) {
    return new MailchimpProvider(apiKey: config('services.mailchimp.api_key'));
});

// Correct: bind the abstraction the consumer actually type hints
$this->app->bind(NewsletterProvider::class, function ($app) {
    return new MailchimpProvider(apiKey: config('services.mailchimp.api_key'));
});
```

The failure is confusing: the binding exists, the class exists, and resolving the controller throws `BindingResolutionException` saying `NewsletterProvider` is not instantiable. The container is right. Nobody ever asks for `MailchimpProvider` by name, so its recipe is dead code, and the contract that is requested has no recipe at all. Bind the key that consumers type hint.

**Error 3: Reaching for `Http::fake()` after the abstraction exists.**

```php
// Wrong: still testing the vendor's API through an abstraction that removed the need
it('subscribes a new email', function () {
    Http::fake(['*api.mailchimp.com*' => Http::response(['id' => 'mc-abc123'], 200)]);

    $this->postJson('/newsletter/subscribe', ['email' => 'asriyanik@example.com'])
         ->assertStatus(201);
});

// Correct: swap the implementation, and HTTP never enters the picture
beforeEach(function () {
    $this->fake = new FakeNewsletterProvider();
    $this->app->instance(NewsletterProvider::class, $this->fake);
});
```

The wrong version passes, which is what makes it stick around. It is also coupled to Mailchimp's URL and response shape forever, so flipping `NEWSLETTER_DRIVER` to `sendgrid` in production leaves a test suite that verifies an integration nobody uses. Once a seam exists at the contract, test at the contract. `Http::fake()` belongs in tests written *for* `MailchimpProvider` itself, where the vendor's API genuinely is the subject.

---

## 13. Exercises

**Exercise 1:** Prove the binding actually responds to configuration. Write tests that set `services.newsletter.driver` to `mailchimp`, then `sendgrid`, then `bogus`, and assert what the container resolves in each case. Note which application files you had to change.

**Exercise 2:** Build the contextual binding from section 10 for real. Create an `AdminBulkSubscribeController` that reports which provider it received, register a contextual binding giving it Sendgrid, and write a test proving it gets Sendgrid while the global driver is Mailchimp.

**Exercise 3:** Suppose `subscribe()` returned a `MailchimpResponse` object rather than a string. Explain concretely what would break when `SendgridProvider` is added, name which half of DIP is violated, and describe the fix if you had to keep richer return data.

---

## 14. Solutions

**Solution for Exercise 1:**

```php
it('resolves mailchimp by default', function () {
    config()->set('services.newsletter.driver', 'mailchimp');

    expect(app(NewsletterProvider::class))->toBeInstanceOf(MailchimpProvider::class);
});

it('resolves sendgrid when the driver config changes', function () {
    config()->set('services.newsletter.driver', 'sendgrid');

    $provider = app(NewsletterProvider::class);

    expect($provider)->toBeInstanceOf(SendgridProvider::class)
        ->and($provider->name())->toBe('sendgrid');
});

it('throws on an unknown driver', function () {
    config()->set('services.newsletter.driver', 'bogus');

    expect(fn () => app(NewsletterProvider::class))
        ->toThrow(InvalidArgumentException::class);
});
```

All three pass, and the answer to the second half of the question is that no application file changed at all. Switching the provider is a config value, which is what the refactor was for.

The `bogus` test is the one worth keeping. It documents that a typo in `NEWSLETTER_DRIVER` produces an immediate, named exception rather than a silent fallback to some default. Silent fallbacks in a composition root are a good way to run production on the wrong integration for a week without noticing.

Note that these tests resolve the contract directly instead of going through the endpoint, because the subject is the binding rather than the controller. That is a legitimate seam to test at, and it exists only because the binding is now a separate, addressable thing.

**Solution for Exercise 2:**

```php
<?php

namespace App\Http\Controllers;

use App\Contracts\NewsletterProvider;
use Illuminate\Http\JsonResponse;

class AdminBulkSubscribeController extends Controller
{
    public function __construct(private NewsletterProvider $provider) {}

    public function show(): JsonResponse
    {
        return response()->json(['provider' => $this->provider->name()]);
    }
}
```

Add the contextual binding to `register()` in `AppServiceProvider`, after the default binding:

```php
// The admin path always uses Sendgrid, whatever the global driver is.
$this->app->when(AdminBulkSubscribeController::class)
    ->needs(NewsletterProvider::class)
    ->give(function ($app) {
        return new SendgridProvider(
            apiKey:  config('services.sendgrid.api_key'),
            baseUrl: config('services.sendgrid.base_url'),
        );
    });
```

```php
it('gives the admin controller sendgrid even when the default is mailchimp', function () {
    config()->set('services.newsletter.driver', 'mailchimp');

    $controller = app(AdminBulkSubscribeController::class);

    expect($controller->show()->getData()->provider)->toBe('sendgrid');
});
```

It passes. The global driver says Mailchimp, `NewsletterController` would receive Mailchimp, and this one consumer receives Sendgrid.

The detail to appreciate is that `AdminBulkSubscribeController` is written identically to `NewsletterController`. It type hints the contract, it has no flag, no parameter, and no knowledge that a special rule applies to it. All of the variation lives in the composition root, which means changing the policy later touches one file that contains no business logic. That is the property that makes DIP scale past two implementations.

**Solution for Exercise 3:**

If `subscribe()` returned a `MailchimpResponse`, then `SendgridProvider` would have to construct a Mailchimp object to satisfy the contract. Sendgrid's response has a `job_id` and no `id`, and its fields do not correspond, so the class would end up populating a foreign shape with fabricated or empty values just to type check. `FakeNewsletterProvider` would have the same problem for no reason at all, since it has no vendor and no response.

The half violated is the second: abstractions should not depend on details. The interface would be sitting one level above the implementations while quietly carrying one implementation's data model, so the inversion would be cosmetic. Adding a third provider would either force the contract to change or force the new provider to lie, which is the Liskov violation from Lesson 5 arriving through the type system instead of through behavior.

If richer return data were genuinely needed, the fix is to define a value object owned by the contract rather than by any provider, for example a `SubscriptionResult` living in `app/Contracts` with the fields the *consumer* needs: an external ID, a status, maybe a timestamp. Each provider maps its own response onto it. The direction of the mapping is the entire point: providers translate into the application's vocabulary, never the other way around.

The way to reach that design in the first place is to write the contract before looking at any vendor's documentation. Ask what the controller needs to know, and stop there. Everything the vendor returns beyond that is the provider's private business.

---

## Next Up - Lesson 8

You inverted a dependency. The controller that once constructed `MailchimpProvider` inline now names only a contract, two real providers and a fake satisfy it, and a single service provider decides which one gets used based on one config value. The test suite dropped HTTP entirely and started asserting the application's own concepts, and the full run covering five feature areas and four external integrations finishes in about a second.

That is all five principles. SRP gave classes one reason to change. OCP let the system grow without editing what already worked. LSP kept the implementations honest about their promises. ISP kept the contracts small enough to implement without lying. DIP pointed the dependencies at abstractions so the rest could actually be enforced.

Each arrived in isolation, one lesson and one feature area at a time. Real code is never that tidy: you meet a class that is doing too much, and hardcoding its collaborator, and hiding a fat interface, all at once, and you have to decide what to fix first and what to leave alone.

Lesson 8 does exactly that. You will take one feature with all five problems at the same time and work through them in a single pass, deciding the order and stopping deliberately short of a full rewrite. Then you will turn the whole course into a code review checklist you can apply to your own projects the next morning.
