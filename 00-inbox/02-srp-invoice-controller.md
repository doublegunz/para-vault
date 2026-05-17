# Single Responsibility Principle in Laravel 13: Refactor a Bloated Invoice Controller

You open `InvoiceController.php` and the `store` method runs to ninety lines. It validates input, computes a subtotal, applies a tax rate, applies a discount code, persists the invoice, generates a PDF, sends an email, and writes an audit log. The marketing team asks for a small change to the email copy. You make the change, run the tests, and one of the calculation tests fails for reasons that have nothing to do with email. The fix takes an hour because everything in that method touches everything else.

This is the everyday cost of ignoring the Single Responsibility Principle. The class works, it ships, and the bill arrives later in the form of every change being slower and riskier than it should be. The longer you wait to split the responsibilities, the more the code accumulates implicit coupling, and the harder the eventual refactor becomes.

This article is the second in our SOLID series, following [SOLID Principles in Laravel 13: A Practical Introduction for Real-World Projects](https://qadrlabs.com). We will build a deliberately bloated invoice controller, write Pest tests against it, capture a clean baseline test run, then refactor the controller into four focused services without changing the public behavior. Every test that passed against the bloated version must still pass against the slim version, with the same count.

## Overview {#overview}

The work splits into two phases. First we build the worst possible version of an invoice creation endpoint, the kind that gets shipped under deadline pressure: one fat controller method that does everything. We write Pest tests against the public HTTP behavior, run them green, and freeze that baseline. Second we extract responsibilities one at a time into `InvoiceCalculator`, `InvoiceRepository`, `InvoicePdfGenerator`, and `InvoiceMailer`, leaving the controller as a thin coordinator. The same Pest tests run again at the end and must show the same pass count.

### What You'll Build
- A Laravel 13 invoice creation endpoint that calculates subtotals, taxes, and discount codes
- A bloated `InvoiceController::store` method as the "before" baseline
- Four focused service classes that each handle one responsibility
- Pest feature tests that validate the public behavior end to end and still pass after refactoring

### What You'll Learn
- How to identify multiple responsibilities living inside a single controller method
- How to extract calculation, persistence, file generation, and email into separate classes
- How to use Laravel 13's `#[Fillable]` attribute on Eloquent models
- How to verify a refactor with Pest by maintaining a stable test suite

### What You'll Need
- PHP 8.3 or later
- Composer 2.x
- Familiarity with Laravel routing, controllers, and Eloquent
- A terminal and a code editor

## Step 1: Set Up the Laravel Project {#step-1-set-up-the-laravel-project}

We start with a fresh Laravel 13 application, configured to use SQLite (so no database server is needed) and to scaffold Pest as the testing framework. The `--pest` flag tells the installer to wire Pest up out of the box, including a `tests/Pest.php` bootstrapper and example test files.

```bash
laravel new srp-invoice-demo --no-interaction --database=sqlite --pest --no-boost
cd srp-invoice-demo
```

After the installer finishes, verify that Pest is installed by running the default test suite. The fresh install ships with example tests in `tests/Feature/ExampleTest.php` and `tests/Unit/ExampleTest.php`, both of which should pass immediately.

```bash
php artisan test
```

The output should look like this, confirming the toolchain is ready before we add anything of our own.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

  Tests:    2 passed (2 assertions)
  Duration: 0.18s
```

## Step 2: Create the Invoice Model and Migration {#step-2-create-the-invoice-model-and-migration}

The invoice domain is intentionally small. One table, one model, JSON column for line items so we do not have to manage a second table just to demonstrate SRP. Generate the model and migration together with Artisan.

```bash
php artisan make:model Invoice -m
```

Open the generated migration in `database/migrations/xxxx_xx_xx_xxxxxx_create_invoices_table.php` and replace its contents with the following. The columns mirror the data we will collect from the API and the fields we will compute server side.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->string('customer_name');
            $table->string('customer_email');
            $table->json('items');                              // line items as a JSON array
            $table->decimal('subtotal', 12, 2);                 // sum of line totals
            $table->decimal('tax_amount', 12, 2);               // computed from subtotal
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('total', 12, 2);                    // subtotal + tax - discount
            $table->string('status')->default('pending');
            $table->string('pdf_path')->nullable();             // populated after PDF is written
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
```

Now open `app/Models/Invoice.php` and replace its body with the following. Notice the use of the new Laravel 13 `#[Fillable]` attribute, which replaces the old `protected $fillable` array with a class-level declaration. Casts remain as a property because there is no equivalent attribute that improves readability for them.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'customer_name',
    'customer_email',
    'items',
    'subtotal',
    'tax_amount',
    'discount_amount',
    'total',
    'status',
    'pdf_path',
])]
class Invoice extends Model
{
    protected $casts = [
        'items' => 'array',
        'subtotal' => 'float',
        'tax_amount' => 'float',
        'discount_amount' => 'float',
        'total' => 'float',
    ];
}
```

Run the migration so the test environment has the table available. The fresh Laravel 13 install already configured SQLite, including the in-memory database for tests, so a single command is enough.

```bash
php artisan migrate
```

You should see something like this in your terminal.

```

   INFO  Preparing database.

  Creating migration table .................................................. 5.32ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table .................................... 11.89ms DONE
  0001_01_01_000001_create_cache_table ..................................... 5.61ms DONE
  0001_01_01_000002_create_jobs_table ...................................... 8.45ms DONE
  2026_05_02_000000_create_invoices_table .................................. 4.12ms DONE
```

## Step 3: Build the Bloated Invoice Controller {#step-3-build-the-bloated-invoice-controller}

Time to write the kind of controller that this article exists to refactor. Generate the controller and the supporting Mailable.

```bash
php artisan make:controller InvoiceController
php artisan make:mail InvoiceMailable
```

Open `app/Mail/InvoiceMailable.php` and replace its body with the following. The Mailable uses Laravel 13's `Envelope` and `Content` API, with an inline HTML string so we do not need a separate Blade view for the demo.

```php
<?php

namespace App\Mail;

use App\Models\Invoice;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class InvoiceMailable extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public Invoice $invoice) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "Invoice #{$this->invoice->id} from QadrLabs",
        );
    }

    public function content(): Content
    {
        $html = "<p>Hi {$this->invoice->customer_name},</p>"
              . "<p>Your invoice <strong>#{$this->invoice->id}</strong> has been created.</p>"
              . "<p>Total amount due: <strong>\${$this->invoice->total}</strong></p>";

        return new Content(htmlString: $html);
    }
}
```

The Mailable is the only piece of the email side that gets reused after refactoring; for now it is also the only piece that is even close to being SRP compliant. Now write the bloated controller. Open `app/Http/Controllers/InvoiceController.php` and replace its contents with the version below.

```php
<?php

namespace App\Http\Controllers;

use App\Mail\InvoiceMailable;
use App\Models\Invoice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;

class InvoiceController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        // Responsibility 1: validate input
        $validated = $request->validate([
            'customer_name'        => 'required|string|max:255',
            'customer_email'       => 'required|email',
            'items'                => 'required|array|min:1',
            'items.*.description'  => 'required|string',
            'items.*.quantity'     => 'required|integer|min:1',
            'items.*.unit_price'   => 'required|numeric|min:0',
            'discount_code'        => 'nullable|string',
        ]);

        // Responsibility 2: calculate subtotal, tax, discount, and total
        $subtotal = 0.0;
        foreach ($validated['items'] as $item) {
            $subtotal += $item['quantity'] * $item['unit_price'];
        }
        $taxAmount = round($subtotal * 0.11, 2);                      // Indonesia PPN 11%

        $discountAmount = 0.0;
        if (!empty($validated['discount_code']) && $validated['discount_code'] === 'WELCOME10') {
            $discountAmount = round($subtotal * 0.10, 2);             // 10% off subtotal
        }
        $total = round($subtotal + $taxAmount - $discountAmount, 2);

        // Responsibility 3: persist the invoice
        $invoice = Invoice::create([
            'customer_name'   => $validated['customer_name'],
            'customer_email'  => $validated['customer_email'],
            'items'           => $validated['items'],
            'subtotal'        => $subtotal,
            'tax_amount'      => $taxAmount,
            'discount_amount' => $discountAmount,
            'total'           => $total,
            'status'          => 'pending',
        ]);

        // Responsibility 4: render and store a PDF representation
        $pdfContent  = "INVOICE #{$invoice->id}\n";
        $pdfContent .= "Customer: {$invoice->customer_name} <{$invoice->customer_email}>\n\n";
        $pdfContent .= "Items:\n";
        foreach ($invoice->items as $item) {
            $line = $item['quantity'] * $item['unit_price'];
            $pdfContent .= "- {$item['description']} | qty {$item['quantity']} x {$item['unit_price']} = {$line}\n";
        }
        $pdfContent .= "\nSubtotal: {$invoice->subtotal}\n";
        $pdfContent .= "Tax (11%): {$invoice->tax_amount}\n";
        $pdfContent .= "Discount: {$invoice->discount_amount}\n";
        $pdfContent .= "Total: {$invoice->total}\n";

        $pdfPath = "invoices/{$invoice->id}.pdf";
        Storage::disk('local')->put($pdfPath, $pdfContent);
        $invoice->update(['pdf_path' => $pdfPath]);

        // Responsibility 5: dispatch the customer email
        Mail::to($invoice->customer_email)->send(new InvoiceMailable($invoice));

        // Responsibility 6: write audit log
        Log::info("Invoice #{$invoice->id} created for {$invoice->customer_email} (total {$invoice->total})");

        return response()->json($invoice->fresh(), 201);
    }
}
```

Six responsibilities, one method. Each comment block in the code corresponds to a different actor in the business: validation rules come from product, calculation rules come from finance, persistence comes from engineering, the PDF format comes from design, the email comes from marketing, and the audit log comes from compliance. Any of those teams can demand a change to this controller, and any change risks the others.

Finally, register the route. Open `routes/web.php` and add the following lines at the bottom. We use a web route rather than an API route to keep the demo simple; the same SRP refactor applies regardless of route file.

```php
use App\Http\Controllers\InvoiceController;

Route::post('/invoices', [InvoiceController::class, 'store'])->name('invoices.store');
```

## Step 4: Write the Pest Tests {#step-4-write-the-pest-tests}

The tests will become our refactor safety net. They drive the public HTTP behavior and avoid asserting on internal implementation, so the same tests will pass before and after we extract services.

Generate a feature test file using Pest's Artisan command.

```bash
php artisan make:test InvoiceCreationTest --pest
```

Open `tests/Feature/InvoiceCreationTest.php` and replace its body with the following test suite. There are six feature tests covering input validation, subtotal arithmetic, tax application, discount handling, PDF generation, and email dispatch.

```php
<?php

use App\Mail\InvoiceMailable;
use App\Models\Invoice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

// Common payload used across happy-path tests.
function validInvoicePayload(array $overrides = []): array
{
    return array_merge([
        'customer_name'  => 'Asriyanik',
        'customer_email' => 'asriyanik@example.com',
        'items'          => [
            ['description' => 'Consulting hour',  'quantity' => 2, 'unit_price' => 100.00],
            ['description' => 'Setup fee',        'quantity' => 1, 'unit_price' => 50.00],
        ],
    ], $overrides);
}

it('rejects requests without required fields', function () {
    $this->postJson('/invoices', [])
         ->assertStatus(422)
         ->assertJsonValidationErrors(['customer_name', 'customer_email', 'items']);
});

it('calculates subtotal as the sum of line totals', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201)
         ->assertJsonPath('subtotal', 250.00);              // 2*100 + 1*50

    expect(Invoice::first()->subtotal)->toBe(250.00);
});

it('applies an 11 percent tax to the subtotal', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201)
         ->assertJsonPath('tax_amount', 27.50)              // 250 * 0.11
         ->assertJsonPath('total', 277.50);                 // 250 + 27.50 - 0
});

it('applies a 10 percent discount when WELCOME10 code is provided', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload(['discount_code' => 'WELCOME10']))
         ->assertStatus(201)
         ->assertJsonPath('discount_amount', 25.00)         // 250 * 0.10
         ->assertJsonPath('total', 252.50);                 // 250 + 27.50 - 25
});

it('writes a PDF file and stores its path on the invoice', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201);

    $invoice = Invoice::first();

    expect($invoice->pdf_path)->toBe("invoices/{$invoice->id}.pdf");
    Storage::disk('local')->assertExists($invoice->pdf_path);
});

it('sends the invoice email to the customer', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201);

    Mail::assertSent(InvoiceMailable::class, function ($mail) {
        return $mail->hasTo('asriyanik@example.com');
    });
});
```

Each test fakes only the side effects it needs to verify. `Mail::fake()` intercepts outgoing email so no SMTP connection is attempted, and `Storage::fake('local')` swaps the disk for an in-memory one so the PDF write is asserted without touching the real filesystem. The tests do not know anything about how the controller is structured internally; they only know the request and the visible outcomes.

## Step 5: Run the Baseline Tests {#step-5-run-the-baseline-tests}

Run the full test suite to capture the baseline. This is the green state we will preserve through the refactor.

```bash
php artisan test
```

Your output should look like this. Six new feature tests pass, plus the two example tests that ship with Laravel.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.06s

   PASS  Tests\Feature\InvoiceCreationTest
  ✓ it rejects requests without required fields                                                                                                                                                        0.21s
  ✓ it calculates subtotal as the sum of line totals                                                                                                                                                   0.04s
  ✓ it applies an 11 percent tax to the subtotal                                                                                                                                                       0.03s
  ✓ it applies a 10 percent discount when welcome10 code is provided                                                                                                                                   0.03s
  ✓ it writes a pdf file and stores its path on the invoice                                                                                                                                            0.03s
  ✓ it sends the invoice email to the customer                                                                                                                                                         0.04s

  Tests:    8 passed (16 assertions)
  Duration: 0.49s
```

Eight passing tests is our baseline. After the refactor we need exactly the same eight tests passing.

## Step 6: Extract the InvoiceCalculator {#step-6-extract-the-invoicecalculator}

The first responsibility we peel off is calculation. Create a new directory for service classes and the calculator file.

```bash
mkdir -p app/Services
```

Create `app/Services/InvoiceCalculator.php` with the following content. The class exposes one method per arithmetic concern, plus a `compose` method that returns a fully assembled set of figures the controller can hand to persistence.

```php
<?php

namespace App\Services;

class InvoiceCalculator
{
    public const TAX_RATE = 0.11;
    public const DISCOUNT_CODE = 'WELCOME10';
    public const DISCOUNT_RATE = 0.10;

    /**
     * Sum the line totals across an array of items.
     *
     * @param  array<int, array{description:string,quantity:int,unit_price:float}>  $items
     */
    public function subtotal(array $items): float
    {
        $sum = 0.0;
        foreach ($items as $item) {
            $sum += $item['quantity'] * $item['unit_price'];
        }
        return round($sum, 2);
    }

    public function tax(float $subtotal): float
    {
        return round($subtotal * self::TAX_RATE, 2);
    }

    public function discount(float $subtotal, ?string $code): float
    {
        if ($code === self::DISCOUNT_CODE) {
            return round($subtotal * self::DISCOUNT_RATE, 2);
        }
        return 0.0;
    }

    public function total(float $subtotal, float $tax, float $discount): float
    {
        return round($subtotal + $tax - $discount, 2);
    }

    /**
     * Compose all four figures into one array so the caller does not have to
     * orchestrate the order of operations.
     */
    public function compose(array $items, ?string $discountCode): array
    {
        $subtotal = $this->subtotal($items);
        $tax      = $this->tax($subtotal);
        $discount = $this->discount($subtotal, $discountCode);
        $total    = $this->total($subtotal, $tax, $discount);

        return compact('subtotal', 'tax', 'discount', 'total');
    }
}
```

The calculator does not know about HTTP, models, files, or email. It only knows arithmetic. That is exactly what SRP asks for: this class can change only when the finance team changes a tax rate or a discount rule, and no other reason.

## Step 7: Extract the InvoiceRepository {#step-7-extract-the-invoicerepository}

Persistence is the next responsibility. Create `app/Services/InvoiceRepository.php` with the following content.

```php
<?php

namespace App\Services;

use App\Models\Invoice;

class InvoiceRepository
{
    public function create(array $attributes): Invoice
    {
        return Invoice::create($attributes);
    }

    public function attachPdfPath(Invoice $invoice, string $path): Invoice
    {
        $invoice->update(['pdf_path' => $path]);
        return $invoice->fresh();
    }
}
```

The repository is intentionally thin. It hides Eloquent behind a method name, which is enough to stop the controller from caring whether the underlying store is Eloquent, a different ORM, or a queue, should that ever change. We do not need a full repository pattern with interfaces here; a thin wrapper is sufficient because the article is about SRP, not DIP. We will revisit the repository pattern in Article 6.

## Step 8: Extract the InvoicePdfGenerator {#step-8-extract-the-invoicepdfgenerator}

PDF rendering and storage move into their own class. Create `app/Services/InvoicePdfGenerator.php` with the following content.

```php
<?php

namespace App\Services;

use App\Models\Invoice;
use Illuminate\Support\Facades\Storage;

class InvoicePdfGenerator
{
    /**
     * Render a textual representation of the invoice and store it on the
     * local disk. Returns the relative path of the written file.
     */
    public function generate(Invoice $invoice): string
    {
        $content = $this->render($invoice);
        $path    = "invoices/{$invoice->id}.pdf";

        Storage::disk('local')->put($path, $content);

        return $path;
    }

    private function render(Invoice $invoice): string
    {
        $body  = "INVOICE #{$invoice->id}\n";
        $body .= "Customer: {$invoice->customer_name} <{$invoice->customer_email}>\n\n";
        $body .= "Items:\n";
        foreach ($invoice->items as $item) {
            $line = $item['quantity'] * $item['unit_price'];
            $body .= "- {$item['description']} | qty {$item['quantity']} x {$item['unit_price']} = {$line}\n";
        }
        $body .= "\nSubtotal: {$invoice->subtotal}\n";
        $body .= "Tax (11%): {$invoice->tax_amount}\n";
        $body .= "Discount: {$invoice->discount_amount}\n";
        $body .= "Total: {$invoice->total}\n";

        return $body;
    }
}
```

The PDF generator is the only class that knows the file format. If marketing later asks for a real PDF using a library like dompdf, the change happens entirely inside `render`; no other class is affected.

## Step 9: Extract the InvoiceMailer {#step-9-extract-the-invoicemailer}

Email dispatch is the last responsibility to extract. Create `app/Services/InvoiceMailer.php` with the following content.

```php
<?php

namespace App\Services;

use App\Mail\InvoiceMailable;
use App\Models\Invoice;
use Illuminate\Support\Facades\Mail;

class InvoiceMailer
{
    public function send(Invoice $invoice): void
    {
        Mail::to($invoice->customer_email)->send(new InvoiceMailable($invoice));
    }
}
```

This class is small on purpose. It exists so that the controller no longer imports the `Mail` facade or the Mailable class directly. If the email rules ever grow (CC the finance team, attach the PDF, send via a different channel), all of that complexity lands here without touching the controller.

## Step 10: Slim Down the Controller {#step-10-slim-down-the-controller}

Now we replace the bloated controller with a coordinator. The new method only orchestrates: calculate, persist, generate PDF, attach path, send email. Each line corresponds to a single delegated responsibility.

Open `app/Http/Controllers/InvoiceController.php` and replace its contents entirely with the slim version below.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Services\InvoiceCalculator;
use App\Services\InvoiceMailer;
use App\Services\InvoicePdfGenerator;
use App\Services\InvoiceRepository;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class InvoiceController extends Controller
{
    public function __construct(
        private InvoiceCalculator $calculator,
        private InvoiceRepository $repository,
        private InvoicePdfGenerator $pdfGenerator,
        private InvoiceMailer $mailer,
    ) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'customer_name'        => 'required|string|max:255',
            'customer_email'       => 'required|email',
            'items'                => 'required|array|min:1',
            'items.*.description'  => 'required|string',
            'items.*.quantity'     => 'required|integer|min:1',
            'items.*.unit_price'   => 'required|numeric|min:0',
            'discount_code'        => 'nullable|string',
        ]);

        // Calculator owns all arithmetic.
        $figures = $this->calculator->compose(
            items:        $validated['items'],
            discountCode: $validated['discount_code'] ?? null,
        );

        // Repository owns persistence.
        $invoice = $this->repository->create([
            'customer_name'   => $validated['customer_name'],
            'customer_email'  => $validated['customer_email'],
            'items'           => $validated['items'],
            'subtotal'        => $figures['subtotal'],
            'tax_amount'      => $figures['tax'],
            'discount_amount' => $figures['discount'],
            'total'           => $figures['total'],
            'status'          => 'pending',
        ]);

        // PDF generator owns file rendering and storage.
        $path    = $this->pdfGenerator->generate($invoice);
        $invoice = $this->repository->attachPdfPath($invoice, $path);

        // Mailer owns email dispatch.
        $this->mailer->send($invoice);

        // Audit log stays inline; one line is not worth its own service yet.
        Log::info("Invoice #{$invoice->id} created for {$invoice->customer_email} (total {$invoice->total})");

        return response()->json($invoice, 201);
    }
}
```

The constructor uses Laravel 13 promoted properties to declare four dependencies. The service container resolves them automatically because each service has a zero-argument constructor and Laravel's reflection-based resolution can handle that without any binding configuration.

The validation block remains in the controller. Some teams prefer to extract it into a Form Request class, which would make the controller even thinner. That is a defensible move under SRP, but it is also an additional file. For this article we keep validation inline so the diff between bloated and slim is purely about the four extracted services.

The audit log line also stays in the controller. One line that runs after a successful operation is not a separate responsibility worth a class. This is a deliberate counterweight to the over-extraction failure mode: SRP is about reasons to change, not about line count.

## Step 11: Run All Tests Again {#step-11-run-all-tests-again}

Run the test suite one more time. The same eight tests must pass, with no changes to any test file.

```bash
php artisan test
```

Your output should match the baseline almost exactly, with timing differences being the only delta.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.06s

   PASS  Tests\Feature\InvoiceCreationTest
  ✓ it rejects requests without required fields                                                                                                                                                        0.20s
  ✓ it calculates subtotal as the sum of line totals                                                                                                                                                   0.04s
  ✓ it applies an 11 percent tax to the subtotal                                                                                                                                                       0.03s
  ✓ it applies a 10 percent discount when welcome10 code is provided                                                                                                                                   0.03s
  ✓ it writes a pdf file and stores its path on the invoice                                                                                                                                            0.03s
  ✓ it sends the invoice email to the customer                                                                                                                                                         0.04s

  Tests:    8 passed (16 assertions)
  Duration: 0.47s
```

Same eight tests, same assertions, same green state. The refactor is behavior preserving. That is the property a real refactor must always have, and it is the property the SRP-driven extraction made easy: each new class is testable in isolation because each new class has only one reason to exist.

## Understanding Single Responsibility Principle {#understanding-single-responsibility-principle}

Now that the code is split, we can revisit what the principle is actually saying. Robert C. Martin's modern phrasing is: "a class should have one, and only one, reason to change". The "reason" is not "thing it does"; it is "actor in the business who can demand it changes". That distinction matters because it explains why some splits feel right and others feel forced.

In the bloated controller, six different actors could ask for changes. Finance owned the tax rate and discount rules. Design owned the PDF format. Marketing owned the email copy. Compliance owned the audit log. Product owned the validation rules. Engineering owned everything else. Six actors meant six possible directions of change pulling on the same file. Now those six actors have different files to pull on. Finance opens `InvoiceCalculator`. Design opens `InvoicePdfGenerator`. Marketing opens `InvoiceMailable`. None of those changes makes the others more risky.

This framing also tells you when not to split. If a class only ever has one actor demanding changes, splitting it produces ceremony without benefit. The audit log line is a good example: there is no realistic future where compliance demands a complex audit pipeline that is not better solved by a different approach (a Laravel observer, a queued job, a logging middleware). One line of `Log::info` is fine where it is.

A useful self-check after any refactor is to read each class out loud as "this class is responsible for...". If the sentence has more than one main clause connected by "and", you have not finished the split. After our refactor, the sentences read cleanly: the calculator is responsible for invoice arithmetic; the repository is responsible for invoice persistence; the PDF generator is responsible for invoice file rendering; the mailer is responsible for invoice email dispatch; the controller is responsible for orchestrating these in response to an HTTP request. No "and" at the top level. That is the shape we wanted.

## Common SRP Pitfalls {#common-srp-pitfalls}

The most common failure mode is over-extraction. If you split every helper into its own class, you end up with a codebase where adding a single feature requires touching ten files, and the abstractions hide rather than reveal what the system does. The fix is to ask the actor question: who would demand a change here? If the answer is "the same person who would demand the change next door", the two pieces probably belong in the same class.

A second failure mode is anemic services. The new class has methods like `getX` and `setX` and never does anything interesting. That usually means the responsibility has not actually been extracted; the data has been moved but the behavior still lives in the caller. Watch for this in repositories that wrap Eloquent without adding any meaning, and in calculators that take fifteen parameters because the original caller did not really delegate.

A third failure mode is splitting along the wrong seam. If you extract by data type rather than by actor, you can end up with classes that always need to be modified together. For example, if you split a `User` class into `UserData` and `UserBehavior`, almost every change to user logic touches both, and you have just doubled the surface area for no benefit. Splits along actor boundaries do not have this problem because different actors really do change at different times.

The fourth failure mode is over-applying SRP to small, stable code. A simple Eloquent model with five fields and three relationships does not need splitting. A controller with two-line methods does not need extracted services. SRP is a tool for managing change pressure; if the pressure is not there, the tool is not needed.

## Conclusion {#conclusion}

The Single Responsibility Principle is the easiest of the SOLID principles to summarize and the trickiest to apply with judgment. The summary fits in one sentence: a class should have one reason to change. The judgment lies in deciding what counts as a reason and which boundaries are worth drawing.

Here are the key takeaways from this refactor to carry forward into the rest of the series:

- **Reasons to change come from actors, not from verbs.** A method that does five things is fine if all five concern the same business actor. A method that does two things is a problem if those two things belong to two different actors.
- **Refactor behind a green test suite.** The same Pest tests passed before and after the extraction. Without that safety net, every refactor becomes a guess about whether you broke something.
- **Extract along actor boundaries.** Calculator for finance. PDF generator for design. Mailer for marketing. The names should make obvious which team can change which class.
- **Keep the controller as a coordinator.** A thin controller that calls services in sequence is exactly what SRP wants. Validation can live there as long as it is small; the moment it grows, move it to a Form Request.
- **Do not extract for the sake of extracting.** A one-line log call is not a class. An anemic getter/setter is not a service. Every new file is a cost paid up front; only pay it when there is a reason to change in the future.
- **The Laravel 13 `#[Fillable]` attribute is the new default.** Class-level attributes keep configuration visible at the top of the file and reduce model boilerplate. Use them on new models from day one.
- **SRP enables the rest of SOLID.** Once responsibilities are split, the next four principles (OCP, LSP, ISP, DIP) become easier to apply because each class has a clear scope to design within.

In Article 3 we will tackle the Open/Closed Principle by building a payment gateway service that starts with an `if/elseif` block and ends as an extensible system where adding a new gateway requires zero modification to existing code. The case study is different but the working pattern is the same: capture a baseline with Pest, refactor with intention, verify the tests stay green.
