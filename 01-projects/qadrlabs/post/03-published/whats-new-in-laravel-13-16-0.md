# What's New in Laravel 13.16.0: artisan dev, whenEnum, and Flexible JSON Schema Validation

Every Laravel point release ships as a flat list of pull request titles, and reading through fifty or so of them rarely tells you which ones actually change how you write code tomorrow morning. The list does not even guarantee accuracy: a PR title in the changelog does not always match what landed in the framework, since method names sometimes get renamed during code review and the changelog entry never catches up. Skip the step of reading the actual source and you either keep hand rolling logic the framework now handles for you, or you ship against a bug that was already fixed two releases ago.

Laravel 13.16.0 is a good example of both problems. Tucked between dozens of return type improvements are five additions and four fixes worth knowing about, so we went through the merged source code for each one ourselves before writing this. What follows reflects what actually shipped, including one case where the changelog's PR title does not match the method name you will find in your editor.

## Overview {#overview}

This article works through Laravel 13.16.0 one feature at a time. For each addition we show the real, current source signature, a short example you can drop into your own project, and where useful a quick way to verify the behavior yourself with Tinker or Pest. The four bug fixes get the same treatment, just lighter on code since most of them change internal behavior rather than a public API you call directly.

### What You'll Build

- A `DevCommands` registration inside a service provider that customizes what `php artisan dev` runs alongside the default server, queue worker, and Vite process.
- A form request that uses `whenEnum` to react only when a request field contains a valid backed enum value.
- A controller response that attaches several cookies at once with `withCookies`.
- A JSON Schema definition that uses `anyOf` to describe a payload that can take more than one shape, the kind of thing you would hand to a tool calling integration.
- A small Pest test that proves the new array maintenance mode driver keeps state isolated between parallel test processes.

### What You'll Learn

- How to register, name, and color code custom processes for `php artisan dev`, and how Laravel detects whether your project uses npm, yarn, pnpm, or bun.
- The real signature and behavior of the new enum helper on `InteractsWithData`, and why the changelog's name for it is wrong.
- How `withCookies` differs from chaining `withCookie` repeatedly, including the one constraint on what you can pass into it.
- How to express "this value can be one of several shapes" in Laravel's JSON Schema builder using `anyOf`.
- Why the array maintenance mode driver exists and how it avoids the state leaks the file and cache drivers can cause across parallel test workers.
- What four notable fixes in this release protect you from: a scheduler shell quoting bug, a stale batch status check, an unguarded `$ref` expansion path in JSON Schema, and a couple of HTTP client serialization edge cases.

### What You'll Need

- PHP 8.3 or newer.
- A Laravel project on `laravel/framework: ^13.16`, or run `composer update laravel/framework` on an existing 13.x app to pick up this release.
- Pest installed if you want to run the test snippets as written. If you have not set it up yet: `composer remove phpunit/phpunit`, then `composer require pestphp/pest --dev --with-all-dependencies`, then `./vendor/bin/pest --init`.
- General familiarity with Form Requests, Artisan commands, and basic controller responses. No prior knowledge of any of the specific features below is assumed.

## Streamlining Local Development with artisan dev {#artisan-dev-command}

Most Laravel apps run several processes at once during development: the HTTP server, a queue worker, log tailing through Pail, and the Vite dev server. Up to now you wired these together with the `dev` script inside `composer.json`, using the `concurrently` npm package directly. That works, but it means editing a JSON string whenever you want to add something like a Reverb websocket server or a Stripe webhook listener.

Laravel 13.16.0 moves that responsibility into the framework as a real Artisan command, `php artisan dev`. Out of the box it behaves the same as the old composer script: `serve`, `queue:listen`, `pail`, and your Node dev script run side by side, and stopping the command kills all of them together through `concurrently`'s `--kill-others` flag. The difference is that you now register and customize the list from PHP, inside a normal service provider, instead of editing a script string with no autocompletion or static analysis.

```php
use Illuminate\Foundation\DevCommands;

public function boot(): void
{
    DevCommands::artisan('reverb:start', 'reverb')->orange();

    DevCommands::register(
        'stripe listen --forward-to '.config('app.url').'/stripe/webhook'
    )->green();
}
```

`DevCommands::artisan()` prefixes whatever you pass it with `php artisan` automatically, which is why the Reverb line above only needs `reverb:start`. `DevCommands::register()` does not add that prefix, which is what makes it the right choice for an arbitrary shell command like the Stripe CLI listener. Both methods return a `DevCommand` instance, so the color call chains directly off the registration. If you skip the name argument, Laravel derives one from the first word of the command, but once you have more than a couple of custom processes registered, giving an explicit name is worth the extra few characters since two unnamed commands that both start with the same word would collide.

Calling `DevCommands::register()` or `::artisan()` outside of a console context, during a normal web request for instance, is a safe no-op. The registration only takes effect while Artisan is running, so it is fine to leave these calls inside a shared `AppServiceProvider::boot()` method without worrying about overhead on regular requests.

If you only want a subset of commands running on a given machine, `only()` and `except()` filter the list from the same place:

```php
DevCommands::except('reverb', 'stripe');
```

Vendor packages are explicitly blocked from registering dev commands automatically: calling `DevCommands::register()` from inside a file that lives under `vendor/` throws an exception. Nothing stops a package from exposing its own helper method that your application calls explicitly from your own service provider, which then calls `DevCommands::register()` internally on your behalf, but the registration call itself always has to originate from your code, not the package's.

One more detail worth knowing if your team is split across different Node tooling: Laravel ships a `NodePackageManager` helper that looks for `bun.lock`, `pnpm-lock.yaml`, and `yarn.lock` in that order, falling back to npm if none are present. That means `DevCommands::node('dev')`, which is what registers the default Vite process, resolves to `pnpm run dev` on a project that uses pnpm without any configuration on your part.

Running `php artisan dev` prints one line per registered command before handing off to `concurrently`, with each line formatted as a colored name in brackets followed by the underlying command. With only the defaults registered, the four lines look roughly like this before the live, interleaved output from each process takes over:

```
[server]   php artisan serve --host=localhost
[queue]    php artisan queue:listen --tries=1 --timeout=0
[logs]     php artisan pail --timeout=0
[vite]     npm run dev
```

## Reacting to Valid Enum Input with whenEnum {#whenenum-method}

Backed enums are a natural fit for status fields, but pulling one out of request input safely usually means writing the same three lines in every form request: read the raw value, call `tryFrom()` on it, check whether the result is null before doing anything with it. `InteractsWithData`, the trait shared by `Illuminate\Http\Request` and `FormRequest`, now exposes a method that collapses those three steps into one chain.

The pull request that introduced this method was titled "Add `whenFilledEnum` method to `InteractsWithData`" in the changelog, but the method that actually shipped in 13.16.0 is named `whenEnum`. You can confirm this yourself by opening `InteractsWithData.php` in your vendor directory and searching for either name; only `whenEnum` exists. We are flagging this directly because copying `whenFilledEnum` out of the GitHub release notes into your own code will throw a fatal "call to undefined method" error.

```php
enum OrderStatus: string
{
    case Pending = 'pending';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';
}
```

```php
use Illuminate\Validation\Rules\Enum;

public function rules(): array
{
    $this->whenEnum('status', OrderStatus::class, function (OrderStatus $status) {
        Log::info("Order status changing to {$status->value}.");
    }, function () {
        Log::warning('Order status field was missing or held an invalid value.');
    });

    return [
        'status' => ['required', new Enum(OrderStatus::class)],
    ];
}
```

`whenEnum()` only calls the first callback when the key is present in the request and `tryFrom()` resolves it to a real case of the enum you passed in. A missing key, an empty string, and a string that does not match any case (`"archived"` in the example above) all fall through to the second, optional default callback instead. The method is meant for branching side logic like the logging above, not for enforcing that the field is present and valid in the first place, which is why we keep the `Enum` validation rule in `rules()` regardless of whether we use `whenEnum()` elsewhere in the request.

You can verify the behavior directly with a small Pest test against a request instance, without needing a full controller or route:

```php
test('whenEnum only triggers its callback for a valid enum case', function () {
    $request = Illuminate\Http\Request::create('/', 'GET', ['status' => 'shipped']);

    $captured = null;

    $request->whenEnum('status', OrderStatus::class, function ($status) use (&$captured) {
        $captured = $status;
    });

    expect($captured)->toBe(OrderStatus::Shipped);
});
```

## Attaching Multiple Cookies in One Call with withCookies {#withcookies-response-method}

Setting more than one cookie on a response used to mean chaining `withCookie()` repeatedly, which is fine for two cookies and starts to read awkwardly past three. `ResponseTrait`, shared by `Illuminate\Http\Response` and the redirect response classes, now has a `withCookies(array $cookies)` method that loops through an array and registers every cookie on the response in a single call.

```php
return response('Preferences saved.')->withCookies([
    cookie('theme', 'dark', 60 * 24 * 30),
    cookie('locale', 'id', 60 * 24 * 30),
    cookie('session_token', $token, 120),
]);
```

There is one constraint worth knowing before you reach for this method: unlike `withCookie()`, which accepts a plain string and quietly builds the cookie for you through the global `cookie()` helper, `withCookies()` expects an array of already built cookie instances. Each entry has to come from the `cookie()` helper or from constructing a `Symfony\Component\HttpFoundation\Cookie` directly, you cannot pass `['theme' => 'dark']` and expect Laravel to figure out the rest. In exchange, building each cookie explicitly means you can freely mix different expiry times, domains, or `SameSite` settings within the same array, which is harder to express cleanly through a single chained call.

```php
test('withCookies attaches every cookie to the response', function () {
    $response = response('ok')->withCookies([
        cookie('theme', 'dark'),
        cookie('locale', 'id'),
    ]);

    $names = collect($response->headers->getCookies())->map->getName();

    expect($names)->toContain('theme', 'locale');
});
```

## Describing Flexible Payloads with anyOf in JSON Schema {#anyof-json-schema-support}

Laravel's JSON Schema builder, `Illuminate\JsonSchema\JsonSchema`, is mostly used to describe structured output for AI tool calling, where you tell a model the exact shape of arguments it is allowed to send back. Until 13.16.0 the builder had no clean way to say "this value can take more than one shape," which is a common requirement once a tool accepts more than one kind of input. The new `anyOf()` method closes that gap by wrapping a list of schemas and validating successfully if a value matches at least one of them.

```php
use Illuminate\JsonSchema\JsonSchema;

$paymentMethodSchema = JsonSchema::anyOf([
    JsonSchema::object([
        'type' => JsonSchema::string()->enum(['credit_card'])->required(),
        'card_number' => JsonSchema::string()->required(),
        'expiry' => JsonSchema::string()->required(),
    ]),
    JsonSchema::object([
        'type' => JsonSchema::string()->enum(['bank_transfer'])->required(),
        'account_number' => JsonSchema::string()->required(),
        'bank_name' => JsonSchema::string()->required(),
    ]),
])->title('PaymentMethod');

echo json_encode($paymentMethodSchema->toArray(), JSON_PRETTY_PRINT);
```

Running the snippet above produces the following schema, captured directly from a real run of this code:

```json
{
    "title": "PaymentMethod",
    "anyOf": [
        {
            "properties": {
                "type": {
                    "enum": [
                        "credit_card"
                    ],
                    "type": "string"
                },
                "card_number": {
                    "type": "string"
                },
                "expiry": {
                    "type": "string"
                }
            },
            "type": "object",
            "required": [
                "type",
                "card_number",
                "expiry"
            ]
        },
        {
            "properties": {
                "type": {
                    "enum": [
                        "bank_transfer"
                    ],
                    "type": "string"
                },
                "account_number": {
                    "type": "string"
                },
                "bank_name": {
                    "type": "string"
                }
            },
            "type": "object",
            "required": [
                "type",
                "account_number",
                "bank_name"
            ]
        }
    ]
}
```

Each branch passed into `anyOf()` is just another JSON Schema type, which is why we could reuse `object()` and `string()` the same way we would for a single shape. Nesting an `enum()` call on each branch's `type` field is what lets a consumer of this schema, whether that is a model deciding which fields to fill in or your own validation logic, tell the two branches apart at runtime. `anyOf()` also accepts a closure instead of a plain array if building the branches needs a bit of conditional logic, and calling `->nullable()` on the result appends a `{"type": "null"}` branch automatically rather than requiring you to add it by hand.

## Isolating Parallel Tests with the Array Maintenance Mode Driver {#array-maintenance-mode-driver}

Laravel's maintenance mode normally writes a flag file to `storage/framework/down` with the file driver, or a key to your configured cache store with the cache driver, and both work fine in production. They get awkward inside automated test suites that run in parallel, because every worker process shares the same filesystem and often the same cache backend. One test enabling maintenance mode can leak into a completely unrelated test running in a different worker at the same moment, producing failures that have nothing to do with the code under test.

The new array driver sidesteps the problem by keeping the down or up flag, along with whatever payload you passed to `php artisan down`, entirely in memory, scoped to the single PHP process that activated it.

```php
use Illuminate\Foundation\ArrayMaintenanceMode;

$mode = new ArrayMaintenanceMode();

$mode->activate(['message' => 'Upgrading the database schema.', 'retry' => 60]);

var_dump($mode->active());
var_dump($mode->data());
```

That snippet, run directly, produces this output:

```
bool(true)
array(2) {
  ["message"]=>
  string(30) "Upgrading the database schema."
  ["retry"]=>
  int(60)
}
```

To opt into this driver for your test suite, point `app.maintenance.driver` at `array`, typically through an environment variable so production keeps using `file`:

```php
'maintenance' => [
    'driver' => env('APP_MAINTENANCE_DRIVER', 'file'),
],
```

```
APP_MAINTENANCE_DRIVER=array
```

With that in place, a Pest test that puts the application down for maintenance no longer has any chance of affecting a sibling test running in another parallel worker, since each worker process gets its own in-memory flag:

```php
test('the app reports maintenance mode correctly with the array driver', function () {
    config(['app.maintenance.driver' => 'array']);

    $this->artisan('down', ['--retry' => 60])->assertSuccessful();

    expect(app()->isDownForMaintenance())->toBeTrue();

    $this->artisan('up')->assertSuccessful();

    expect(app()->isDownForMaintenance())->toBeFalse();
});
```

## Fixes Worth Knowing About {#fixes-worth-knowing-about}

Beyond the new methods above, four fixes in 13.16.0 close gaps that are easy to run into without immediately realizing the framework was misbehaving. None of them require you to change how you call the framework. Knowing what changed just helps you recognize symptoms you might have hit on an older 13.x release.

### Scheduled commands running as another user

Laravel's scheduler can run a command as a different system user through `->user('deploy')`, typically combined with cron running as root. Before this release, the framework built the underlying `sudo -u ... sh -c ...` wrapper by concatenating your command into the string without consistently escaping it first, so a scheduled command containing characters like quotes, `$`, or `&` inside one of its own arguments could be split incorrectly by the shell. `CommandBuilder` now passes the entire inner command through `ProcessUtils::escapeArgument()` before handing it to `sh -c`, the same escaping Symfony's Process component already relies on to quote arguments safely across platforms. Nothing changes in how you write your own schedule definitions, the fix lives entirely inside the framework's command building step.

### Batches that still reported batching() as true after they finished

`Bus\Batchable::batching()` is the method a queued job calls to check whether it is still part of an active batch. Before 13.16.0, the check only looked at whether the batch had been cancelled:

```php
return $this->batch() && ! $this->batch()->cancelled();
```

A job that called `$this->batching()` inside its own `handle()` method after the rest of the batch had already finished, a slow job, or one retried after its siblings completed, would get back `true` and could keep behaving as though the batch were still in progress. The fixed version adds the missing check:

```php
return $this->batch() && ! $this->batch()->finished() && ! $this->batch()->cancelled();
```

`batching()` now reliably reflects whether the batch is still running, not just whether it was cancelled.

### Circular and oversized $ref chains in JSON Schema

If you deserialize a JSON Schema document that came from somewhere other than your own code, a self-referencing `$ref` used to risk unbounded recursion while Laravel tried to resolve it. The deserializer now tracks every `$ref` it has already visited while resolving a branch and throws immediately if it sees one repeat:

```php
$circular = [
    '$defs' => ['node' => ['$ref' => '#/$defs/node']],
    '$ref' => '#/$defs/node',
];

JsonSchema::fromArray($circular);
```

Running that against a real Laravel 13.16.0 install produces:

```
Caught: Circular JSON Schema $ref [#/$defs/node] detected.
```

A second, related guard caps the deserializer at 20,000 expanded schema fragments in total, which protects against a `$ref` tree that is not technically circular but is deep or wide enough to exhaust memory on its own. Neither guard affects schemas you write yourself by hand, they only matter once you are deserializing a schema document you did not author.

### Non-finite numbers and invalid bodies in the HTTP client

Casting a non-finite float like `INF`, `-INF`, or `NAN` to a string for a fake response header or body used to risk a PHP 8.5 deprecation warning, since PHP's own string cast behavior for these values changed between PHP versions. `PendingRequest` and `Factory` now route every scalar through a `normalizeScalarString()` helper that converts those three values to their literal string form (`"INF"`, `"-INF"`, `"NAN"`) before they ever reach a header or a JSON payload, so the warning never has a chance to surface.

The same release also tightens what `Http::fake()` and `withBody()` will accept. Passing something other than a string, a resource, a PSR-7 stream, or `null` into `withBody()` now throws an `InvalidArgumentException` immediately:

```php
Http::fake([
    '*' => Http::response(['rate' => INF]),
]);
```

Before 13.16.0, a fake response body or header containing a value like the one above could end up serialized inconsistently. Now it resolves to a clean, predictable string, and any genuinely unsupported value type fails loudly and immediately rather than traveling deeper into Guzzle and failing with a less obvious error further down the stack.

## Conclusion {#conclusion}

None of the changes in Laravel 13.16.0 require you to touch existing code, but several of them are worth adopting on purpose rather than discovering by accident six months from now.

- **`artisan dev` replaces the composer dev script.** Registering processes from a service provider with `DevCommands::artisan()` and `::register()` gives you autocompletion, color coding, and per-machine filtering that a JSON script string never could.
- **The method is `whenEnum`, not `whenFilledEnum`.** Trust the source over the changelog title when a PR description and the shipped code disagree, and update any notes or AI-generated snippets that may have picked up the wrong name.
- **`withCookies` batches cookie writes, but expects built cookies.** Pass an array of `cookie()` calls or `Cookie` instances, not raw name and value pairs.
- **`anyOf` describes shape, not just type.** It is the right tool once a JSON Schema field, especially one feeding an AI tool call, needs to accept more than one valid structure.
- **The array maintenance driver exists specifically for parallel testing.** Point `app.maintenance.driver` at `array` in your testing environment to stop maintenance mode state from leaking between parallel workers.
- **Four fixes close real edge cases.** Scheduled commands that switch users are now quoted safely, finished batches no longer report themselves as still batching, JSON Schema deserialization can no longer recurse forever on a circular `$ref`, and the HTTP client now handles non-finite numbers and invalid bodies predictably instead of failing in surprising ways.
