## 1. Before You Begin

You open `InvoiceController.php` and the `store` method runs to ninety lines. It validates input, computes a subtotal, applies a tax rate, applies a discount code, persists the invoice, generates a PDF, sends an email, and writes an audit log. The marketing team asks for a small change to the email copy. You make the change, run the tests, and one of the calculation tests fails for reasons that have nothing to do with email. The fix takes an hour because everything in that method touches everything else.

This is the everyday cost of ignoring the Single Responsibility Principle. The class works, it ships, and the bill arrives later in the form of every change being slower and riskier than it should be. The longer you wait to split the responsibilities, the more the code accumulates implicit coupling, and the harder the eventual refactor becomes.

You will build that controller on purpose. Writing the painful version first is the point, because a refactor you have not felt the need for is an academic exercise. Once it exists and is covered by tests, you will pull four responsibilities out of it, one at a time, and prove with an unchanged test suite that nothing about its behavior moved.

### What You'll Build

An invoice creation endpoint in SolidLab that accepts line items, applies an 11 percent tax and an optional discount code, persists the invoice, writes a text based PDF to disk, and emails the customer. You will build it first as a single bloated controller method, then refactor it into `InvoiceCalculator`, `InvoiceRepository`, `InvoicePdfGenerator`, and `InvoiceMailer`, leaving the controller as a thin coordinator. Six Pest feature tests guard the whole operation and do not change a character between the two versions.

### What You'll Learn

- ✅ How to identify multiple responsibilities living inside a single controller method
- ✅ How to name responsibilities by actor rather than by verb
- ✅ How to extract calculation, persistence, file generation, and email into separate classes
- ✅ How to use Laravel 13's `#[Fillable]` attribute on an Eloquent model
- ✅ How constructor promotion plus the service container removes all wiring boilerplate
- ✅ How to verify a refactor with Pest by keeping the test file frozen
- ✅ When extracting a responsibility is not worth the file it costs

### What You'll Need

- SolidLab set up as described in Lesson 2, with `laravel/pao` removed and `app/Contracts` created
- Laravel 13 confirmed with `php artisan --version`
- The vocabulary from Lesson 1, particularly the idea that a reason to change is an actor rather than a verb

---

## 2. Set Up the Invoice Domain

The invoice domain is intentionally small. One table, one model, and a JSON column for line items so there is no second table to manage. Everything interesting in this lesson happens in the controller, not in the schema.

### Step 1: Generate the Model and Migration

Artisan can create both files in one command. The `-m` flag adds the migration alongside the model.

```bash
php artisan make:model Invoice -m
```

Artisan reports the migration path, which includes today's date in the filename. Yours will differ from the one shown throughout this lesson, which is expected; migration filenames are timestamped so they run in creation order.

### Step 2: Define the Invoices Table

Open the generated migration in `database/migrations/` and replace its contents with the following. The columns mirror the data collected from the request and the figures computed on the server.

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
            $table->json('items');
            $table->decimal('subtotal', 12, 2);
            $table->decimal('tax_amount', 12, 2);
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('total', 12, 2);
            $table->string('status')->default('pending');
            $table->string('pdf_path')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
```

The `json` column holds the line items as an array, which keeps the demo to one table. The four `decimal` columns use 12 digits with 2 decimal places, which is the right type for money; storing currency in a `float` column invites rounding drift that shows up as invoices that are one cent off. `discount_amount` defaults to zero so invoices without a code do not need special handling. `pdf_path` is nullable because it is populated after the invoice row already exists, since the file name depends on the invoice ID.

### Step 3: Configure the Invoice Model

Open `app/Models/Invoice.php` and replace its body with the following.

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

The `#[Fillable]` attribute is the Laravel 13 replacement for the old `protected $fillable` array. It declares mass assignable columns at the class level, above the class body, where a reader sees it before any code. Functionally it is identical to the property, so `Invoice::create([...])` behaves exactly as before; the change is about where the configuration lives.

The `$casts` array stays a property. There is no attribute equivalent that improves readability here, and casts are the more code adjacent of the two concerns. The `items` cast is the important one: it serializes the array to JSON on write and decodes it back to an array on read, so the rest of the code never touches `json_encode`. The four float casts make sure arithmetic on the retrieved model works on numbers rather than on the decimal strings SQLite returns.

### Step 4: Run the Migration

Create the table.

```bash
php artisan migrate
```

```
   INFO  Running migrations.  

  2026_08_18_150846_create_invoices_table ....................... 10.41ms DONE
```

Only the new migration runs, because the three that ship with Laravel already ran when you scaffolded the project in Lesson 2.

---

## 3. Build the Bloated Controller

Now write the version this lesson exists to fix. Resist the urge to make it nice. The goal is a faithful reproduction of the kind of controller that gets written under deadline pressure, because the refactor only teaches you something if the starting point is genuinely uncomfortable.

### Step 1: Generate the Controller and Mailable

```bash
php artisan make:controller InvoiceController
php artisan make:mail InvoiceMailable
```

The first command creates an empty controller class. The second creates a Mailable, which is Laravel's object representation of an email: it knows its own subject and body, and the mail system knows how to render and send it.

### Step 2: Write the Mailable

Open `app/Mail/InvoiceMailable.php` and replace its body with the following.

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
            subject: "Invoice #{$this->invoice->id} from SolidLab",
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

The constructor uses property promotion, so `public Invoice $invoice` both declares and assigns the property in one line. Because the property is public, it is available inside `envelope()` and `content()` without any further wiring.

`envelope()` returns the metadata of the email, here just the subject. `content()` returns the body; using `htmlString:` passes inline HTML directly instead of pointing at a Blade view, which keeps this lesson to one file for the email. The `Queueable` and `SerializesModels` traits come from the generator and let the Mailable be pushed onto a queue later without changes.

Notice that this class is already close to SRP compliant. It is responsible for one thing, describing an invoice email, and one actor, marketing, owns it. It is the only piece of the email path that survives the refactor untouched.

### Step 3: Write the Six Responsibility Controller

Open `app/Http/Controllers/InvoiceController.php` and replace its contents with the version below. Each numbered comment marks a different responsibility, and the numbering exists so you can count them.

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
        $taxAmount = round($subtotal * 0.11, 2);

        $discountAmount = 0.0;
        if (!empty($validated['discount_code']) && $validated['discount_code'] === 'WELCOME10') {
            $discountAmount = round($subtotal * 0.10, 2);
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

Read the six comment blocks as a list of the people who can demand a change to this file. Validation rules come from product. The 11 percent rate and the `WELCOME10` rule come from finance. The persisted column set comes from engineering and the DBA. The PDF layout comes from design. The email dispatch comes from marketing. The audit line comes from compliance.

Six actors, one method. Each of them can walk up and ask for a change, and each change risks the other five, because everything shares the same local variables and the same execution path. Note also what the file imports: `Storage`, `Mail`, `Log`, and the Mailable. A controller that imports the filesystem, the mail system, and the logger is announcing its own problem in its `use` block.

The `$invoice->fresh()` at the end re-reads the row from the database so the response includes the `pdf_path` written a few lines earlier, since the in-memory model still holds the pre-update state.

### Step 4: Register the Route

Open `routes/web.php` and replace its contents with the following.

```php
<?php

use App\Http\Controllers\InvoiceController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/invoices', [InvoiceController::class, 'store'])->name('invoices.store');
```

A web route is enough here. When a request arrives with an `Accept: application/json` header, which is what Pest's `postJson` helper sends, Laravel returns validation failures as a JSON 422 response rather than a redirect, so the endpoint behaves like an API endpoint for our tests without needing a separate API route file. The named route is not used by the tests but costs nothing and makes the route listing readable.

---

## 4. Write the Tests and Capture a Baseline

These tests are the safety net for everything that follows, so it is worth being deliberate about what they assert. They drive the endpoint over HTTP and check visible outcomes: the status code, the JSON body, the database row, the written file, the sent email. They say nothing about which class did the work.

That restraint is the whole point. You are about to move the tax calculation into a new class. A test that asserted `InvoiceController` computed the tax would have to be rewritten as part of the refactor, and a test that changes alongside the code it guards proves nothing about the change.

### Step 1: Create the Test File

```bash
php artisan make:test InvoiceCreationTest --pest
```

The `--pest` flag generates a Pest style file with `it()` closures rather than a PHPUnit class with methods.

### Step 2: Write Six Feature Tests

Open `tests/Feature/InvoiceCreationTest.php` and replace its body with the following.

```php
<?php

use App\Mail\InvoiceMailable;
use App\Models\Invoice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

function validInvoicePayload(array $overrides = []): array
{
    return array_merge([
        'customer_name'  => 'Asriyanik',
        'customer_email' => 'asriyanik@example.com',
        'items'          => [
            ['description' => 'Consulting hour', 'quantity' => 2, 'unit_price' => 100.00],
            ['description' => 'Setup fee',       'quantity' => 1, 'unit_price' => 50.00],
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
         ->assertJsonPath('subtotal', 250);

    expect(Invoice::first()->subtotal)->toEqual(250.00);
});

it('applies an 11 percent tax to the subtotal', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201)
         ->assertJsonPath('tax_amount', 27.50)
         ->assertJsonPath('total', 277.50);
});

it('applies a 10 percent discount when WELCOME10 code is provided', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload(['discount_code' => 'WELCOME10']))
         ->assertStatus(201)
         ->assertJsonPath('discount_amount', 25)
         ->assertJsonPath('total', 252.50);
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

`validInvoicePayload()` is a plain function that builds the request body, with an `$overrides` argument so a single test can change one field without restating the whole payload. Two consulting hours at 100 plus one setup fee at 50 gives a subtotal of 250, which makes the expected tax (27.50) and discount (25) easy to verify by hand.

`Mail::fake()` swaps the mail system for a recorder, so no SMTP connection is attempted and `Mail::assertSent` can inspect what would have been sent. `Storage::fake('local')` does the same for the disk, replacing it with a temporary one so the PDF assertion never touches your real filesystem. Each test fakes only what it needs.

The first test posts an empty body and expects a 422 with named validation errors. The next three assert on arithmetic through `assertJsonPath`, which reads a single key out of the response body. The fifth checks both halves of the PDF work: the path recorded on the model and the file actually existing on the disk. The sixth confirms the email went to the right address, using a closure so the assertion is about the recipient rather than merely that some mail was sent.

### Step 3: Run the Baseline

Run only this file, as Lesson 2 established.

```bash
php artisan test tests/Feature/InvoiceCreationTest.php
```

```
   PASS  Tests\Feature\InvoiceCreationTest
  ✓ it rejects requests without required fields                          0.18s  
  ✓ it calculates subtotal as the sum of line totals                     0.06s  
  ✓ it applies an 11 percent tax to the subtotal                         0.03s  
  ✓ it applies a 10 percent discount when WELCOME10 code is provided     0.03s  
  ✓ it writes a PDF file and stores its path on the invoice              0.03s  
  ✓ it sends the invoice email to the customer                           0.03s  

  Tests:    6 passed (19 assertions)
  Duration: 0.41s
```

Write down both numbers: **6 passed, 19 assertions**. That pair is the contract for the rest of the lesson. The bloated controller works correctly; it is badly organized, which is a different problem, and one that tests cannot detect.

---

## 5. Extract the Four Services

Now peel the responsibilities off one at a time. Work in the order below, and resist the temptation to run the tests only at the end; each extraction is small enough that if something breaks, you want to know which one did it.

Notice that no test file is touched from here to the end of the lesson. If you find yourself editing a test, stop and look at what you changed, because you have altered behavior rather than structure.

### Step 1: Create the Services Directory

```bash
mkdir app/Services
```

Like `app/Contracts` from Lesson 2, this maps to the `App\Services` namespace automatically through the PSR-4 root already registered in `composer.json`.

### Step 2: Extract the InvoiceCalculator

Create `app/Services/InvoiceCalculator.php` with the following content.

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

The three constants pull the magic numbers out of the middle of the logic and give them names, so a finance change is an edit to a named constant at the top of the file rather than a hunt for `0.11` inside a method body.

Each of the four arithmetic methods does one calculation and is independently callable, which makes them trivial to unit test. `compose()` exists so the caller does not have to know the order of operations; tax is computed on the subtotal, discount is computed on the subtotal rather than on the taxed amount, and total combines all three. That sequencing is a finance rule, so it belongs in the finance class rather than in the controller.

The class imports nothing. No models, no facades, no framework at all. That is the strongest available signal that a responsibility really has been isolated: this class can change only when the finance team changes a rule.

### Step 3: Extract the InvoiceRepository

Create `app/Services/InvoiceRepository.php` with the following content.

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

This repository is deliberately thin, and it is worth being honest about that. It hides Eloquent behind two method names and adds no logic of its own.

The value it adds is that the controller stops naming `Invoice::create` directly, which means the controller no longer knows how invoices are stored. `attachPdfPath` also captures a small piece of knowledge that was previously loose in the controller: after updating the path you must re-read the model to see it, which is why it returns `$invoice->fresh()` rather than the stale instance.

This is not the full repository pattern with an interface behind it. That would be dependency inversion, which is Lesson 7's subject. Here the goal is only to give persistence its own home.

### Step 4: Extract the InvoicePdfGenerator

Create `app/Services/InvoicePdfGenerator.php` with the following content.

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

The split into two methods matters. `generate()` is public and handles the side effect: decide the path, write the file, report where it went. `render()` is private and pure: given an invoice, return a string, touching nothing outside itself.

That separation is what makes the class easy to change later. When design asks for a real PDF using a library like dompdf, the change is confined to `render()`. When infrastructure asks for the file to go to S3 instead of local disk, the change is confined to `generate()`. Neither request reaches any other class.

### Step 5: Extract the InvoiceMailer

Create `app/Services/InvoiceMailer.php` with the following content.

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

One method, one line. It is fair to ask whether this class earns its place, and the answer is that it earns it on the imports rather than on the logic: it is the reason the controller no longer imports the `Mail` facade or the Mailable.

It also gives email rules somewhere to grow. The moment marketing asks to CC the finance team, attach the PDF, or skip the email for internal customers, that logic has an obvious home, and it lands there instead of accreting back into the controller. Wrapping one line is cheap; the alternative is that the next three email rules go into `store()`.

---

## 6. Slim Down the Controller

With the four responsibilities relocated, the controller has nothing left to do except decide the order of operations and translate the result into an HTTP response. That is what a controller is for.

### Step 1: Rewrite the Controller as a Coordinator

Open `app/Http/Controllers/InvoiceController.php` and replace its contents entirely.

```php
<?php

namespace App\Http\Controllers;

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

The constructor declares four dependencies using promoted properties, so each parameter is declared, typed, and assigned in one line. There is no binding to register anywhere: each service has a constructor with no arguments, so Laravel's container resolves them by reflection when it builds the controller. This is dependency injection working for free, and Lesson 7 explains the mechanism properly.

The named arguments in the `compose()` call (`items:` and `discountCode:`) make the call site self documenting, which matters when a method takes two arguments of loosely related types. `$validated['discount_code'] ?? null` handles the optional field, since a request without a code has no such key.

Compare the imports with the bloated version. `Storage`, `Mail`, and `InvoiceMailable` are gone. The controller no longer knows that files or emails exist; it knows only that it has collaborators that handle them.

### Step 2: Notice What Deliberately Stayed

Two things did not move, and both were judgment calls rather than oversights.

The validation block is still inline. Extracting it into a Form Request class is a defensible SRP move and many teams do exactly that. It is also an additional file, and for this lesson keeping it here makes the diff between the two controller versions purely about the four services. If those rules grow past about ten lines or start needing conditional logic, move them; at this size, the file they would cost is not repaid.

The audit log is still one call to `Log::info`. This one is more interesting, because it is the counterweight to the whole lesson. SRP is about reasons to change, not about line count, and a single log call after a successful operation is not a responsibility worth a class. If compliance later wants a real audit trail with its own storage and retention rules, that is not an `InvoiceAuditLogger` service anyway; it is a model observer or a queued job. Extracting it now would be ceremony, and recognizing that is as much a part of applying SRP as the four extractions above it.

---

## 7. Run and Test

Run the same command as before, with no changes to the test file.

```bash
php artisan test tests/Feature/InvoiceCreationTest.php
```

```
   PASS  Tests\Feature\InvoiceCreationTest
  ✓ it rejects requests without required fields                          0.19s  
  ✓ it calculates subtotal as the sum of line totals                     0.05s  
  ✓ it applies an 11 percent tax to the subtotal                         0.03s  
  ✓ it applies a 10 percent discount when WELCOME10 code is provided     0.03s  
  ✓ it writes a PDF file and stores its path on the invoice              0.03s  
  ✓ it sends the invoice email to the customer                           0.03s  

  Tests:    6 passed (19 assertions)
  Duration: 0.42s
```

Six passed, nineteen assertions, exactly matching the baseline from section 4. Only the timings moved, and those vary between runs on the same machine.

This is the evidence that matters. You moved four responsibilities into four new classes, rewrote a ninety line method into a twenty line coordinator, changed which files import the mail and storage systems, and the observable behavior of the endpoint is byte for byte identical. That is what a refactor is, and it is why the baseline was captured before any of it started.

If your numbers do not match, the mismatch itself tells you where to look. A different test count means a test file was edited or a file was renamed. A different assertion count with the same test count means an assertion was deleted. A failure in the calculation tests points at `InvoiceCalculator`, a failure in the PDF test points at `InvoicePdfGenerator`, and the failure output names which one.

---

## 8. Understanding the Single Responsibility Principle

With the code split, it is worth revisiting what the principle actually says. Robert C. Martin's modern phrasing is that a class should have one, and only one, reason to change. The word doing the work is "reason", and it does not mean "thing it does"; it means "actor in the business who can demand it changes".

That distinction explains why some splits feel right and others feel forced. In the bloated controller, six actors could ask for changes: product owned validation, finance owned the rates, engineering owned the columns, design owned the PDF layout, marketing owned the email, compliance owned the audit line. Six actors pulling on one file means that sooner or later two of them ask for changes that conflict, and whoever gets there second inherits the merge.

After the refactor those actors have different files to pull on. Finance opens `InvoiceCalculator`. Design opens `InvoicePdfGenerator`. Marketing opens `InvoiceMailable`. None of those edits makes the others riskier, and none of them requires reading the other three.

The self check is to read each class out loud as a sentence beginning "this class is responsible for". If the sentence needs more than one main clause joined by "and", the split is not finished. After this refactor the sentences read cleanly: the calculator is responsible for invoice arithmetic; the repository is responsible for invoice persistence; the PDF generator is responsible for invoice file rendering; the mailer is responsible for invoice email dispatch; the controller is responsible for orchestrating those in response to an HTTP request.

There is a second, quieter benefit worth naming. Before the refactor, testing the tax calculation required an HTTP request, a database, a faked filesystem, and a faked mail system, because the arithmetic was welded to all of them. After it, `InvoiceCalculator` can be instantiated with `new` and tested in microseconds with no framework at all. Exercise 3 has you do exactly that.

---

## 9. Common SRP Pitfalls

Four failure modes account for most bad SRP refactors, and the first is the most common by a wide margin.

**Over extraction.** Splitting every helper into its own class produces a codebase where adding one feature means touching ten files and the abstractions hide the behavior rather than reveal it. The corrective question is the actor question: who would demand a change here? If the answer is "the same person who would demand the change next door", the two pieces belong together. This is the failure mode the audit log decision in section 6 was guarding against.

**Anemic services.** The new class has `getX` and `setX` methods and never does anything interesting. That usually means the data moved but the behavior stayed in the caller, which is worse than not splitting at all, because now the logic and the data it operates on live in different files. Watch for it in repositories that wrap an ORM without adding meaning, and in calculators that take twelve parameters because the caller never really delegated.

**Splitting along the wrong seam.** If you split by data type rather than by actor, you get classes that always change together. Splitting `User` into `UserData` and `UserBehavior` means nearly every user change touches both files, which doubles the surface area for no benefit. Actor boundaries do not have this problem, because different actors genuinely do change at different times.

**Applying SRP where there is no change pressure.** A model with five fields and three relationships does not need splitting. A controller with two line methods does not need services. SRP is a tool for managing change; where nothing is changing, the tool costs files and returns nothing.

---

## 10. Fix the Errors in Your Code

These three mistakes come up constantly during this specific refactor, and each one produces a symptom that points somewhere other than the cause.

**Error 1: Editing the tests to make them pass after the refactor.**

The refactor breaks a test, and the natural instinct is to update the test to match the new structure. Doing that quietly destroys the only evidence you had.

```php
// Wrong: the test now asserts on internals and will break at the next refactor
it('calculates subtotal as the sum of line totals', function () {
    $calculator = new InvoiceCalculator();
    expect($calculator->subtotal([...]))->toBe(250.0);
});

// Correct: the original test, unchanged, still driving the endpoint
it('calculates subtotal as the sum of line totals', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload())
         ->assertStatus(201)
         ->assertJsonPath('subtotal', 250);

    expect(Invoice::first()->subtotal)->toEqual(250.00);
});
```

The rewritten version is not a bad test, and section 8 recommends writing one like it. It is a bad *replacement*, because it no longer proves the endpoint still works. Add unit tests alongside the feature tests; never swap one for the other during a refactor.

**Error 2: Forgetting that `update()` leaves the in-memory model stale.**

The PDF test fails with a null `pdf_path` even though the file was written and the database row is correct.

```php
// Wrong: $invoice still holds the values it had before the update
public function attachPdfPath(Invoice $invoice, string $path): Invoice
{
    $invoice->update(['pdf_path' => $path]);

    return $invoice;
}

// Correct: re-read the row so the returned model reflects what was saved
public function attachPdfPath(Invoice $invoice, string $path): Invoice
{
    $invoice->update(['pdf_path' => $path]);

    return $invoice->fresh();
}
```

This is easy to miss because the database is right and only the object in memory is wrong, so the bug surfaces one step later, in the JSON response. Any time an assertion on a response disagrees with what you can see in the database, suspect a stale model.

**Error 3: Giving an extracted service a constructor argument the container cannot resolve.**

The refactor is finished, and every test fails at once with a `BindingResolutionException` before a single line of your logic runs.

```php
// Wrong: the container has no idea what string to pass here
class InvoicePdfGenerator
{
    public function __construct(private string $diskName) {}
}

// Correct: no constructor arguments, so reflection resolves it automatically
class InvoicePdfGenerator
{
    // reads config or uses a default internally
}
```

Laravel resolves a class by reflection only when it can work out every constructor parameter, which it can do for type hinted classes and cannot do for scalars like `string $diskName`. If a service genuinely needs a scalar, it has to be bound explicitly in a service provider, which is exactly the machinery Lesson 7 covers. Until then, keep extracted services free of constructor arguments and let them read configuration internally.

---

## 11. Exercises

**Exercise 1:** Finance introduces a second discount code, `LOYAL5`, worth 5 percent. Add it without touching `InvoiceController`. Note which files you had to open, then add a test asserting that a payload with `LOYAL5` produces a `discount_amount` of 12.50 and a `total` of 265.00 on the standard payload.

**Exercise 2:** Compliance now wants the audit entry to include the discount code used, and to be written only for invoices over 1,000,000. Decide whether this changes your answer about leaving `Log::info` in the controller. Write two or three sentences justifying either extracting an `InvoiceAuditLogger` or keeping it inline, using the actor test from section 8.

**Exercise 3:** Write a unit test for `InvoiceCalculator` in `tests/Unit/InvoiceCalculatorTest.php` that instantiates the class directly with `new`, without booting the framework, faking anything, or touching the database. Cover the subtotal calculation and the behavior for an unknown discount code. Compare its duration against the feature test file.

---

## 12. Solutions

**Solution for Exercise 1:**

Only `InvoiceCalculator` changes. Replace the two single purpose constants with a map from code to rate, and look the code up instead of comparing it.

```php
public const TAX_RATE = 0.11;

public const DISCOUNT_RATES = [
    'WELCOME10' => 0.10,
    'LOYAL5'    => 0.05,
];

public function discount(float $subtotal, ?string $code): float
{
    $rate = self::DISCOUNT_RATES[$code] ?? 0.0;

    return round($subtotal * $rate, 2);
}
```

The null coalescing operator covers both an unknown code and a null one, so the previous `if` and its explicit `return 0.0` both disappear. Then add this to the feature test file:

```php
it('applies a 5 percent discount when LOYAL5 code is provided', function () {
    Mail::fake();
    Storage::fake('local');

    $this->postJson('/invoices', validInvoicePayload(['discount_code' => 'LOYAL5']))
         ->assertStatus(201)
         ->assertJsonPath('discount_amount', 12.5)
         ->assertJsonPath('total', 265);
});
```

The subtotal is 250, so the discount is 12.50 and the total is 250 plus 27.50 tax minus 12.50, which is 265.

The point of the exercise is the file count. One file changed, and it was the finance file, which is exactly what the section 8 sentence predicted. In the bloated version this same change meant opening the controller, editing a condition buried in a ninety line method, and re-running every test including the ones about email and PDFs.

It is worth noticing what this refactor did *not* achieve, though. You still had to open and edit a tested, working class to add a discount code. Keeping that file closed while still adding new behavior is a different principle, and it is what Lesson 4 is about.

**Solution for Exercise 2:**

Either answer can be defended, but the actor test points fairly clearly one way.

The case for extracting: the requirement now has two rules of its own, a content rule and a threshold rule, and compliance owns both. A conditional inside the controller means a compliance change edits the same method that finance and product also edit, which is the exact collision SRP exists to prevent. Two rules is usually the point where a responsibility becomes real.

The case for keeping it inline: it is still four or five lines, and if it is destined to become a real audit trail with retention and storage rules, a service class is the wrong destination anyway. A model observer on `Invoice::created` or a queued job would take the logic out of the request path entirely and would not need the controller to know about it at all.

The strongest answer combines them: extract it, but not into an `InvoiceAuditLogger` that the controller calls. Move it to an observer, so the controller loses the line entirely rather than trading one dependency for another. The lesson to take is that "should this be extracted" and "should this be a service class" are two separate questions, and answering the first yes does not answer the second.

**Solution for Exercise 3:**

Create `tests/Unit/InvoiceCalculatorTest.php`.

```php
<?php

use App\Services\InvoiceCalculator;

it('sums line totals into a subtotal', function () {
    $calculator = new InvoiceCalculator();

    $subtotal = $calculator->subtotal([
        ['description' => 'Consulting hour', 'quantity' => 2, 'unit_price' => 100.00],
        ['description' => 'Setup fee',       'quantity' => 1, 'unit_price' => 50.00],
    ]);

    expect($subtotal)->toBe(250.0);
});

it('returns no discount for an unknown code', function () {
    $calculator = new InvoiceCalculator();

    expect($calculator->discount(250.0, 'NOPE'))->toBe(0.0);
});
```

Run it on its own.

```bash
php artisan test tests/Unit/InvoiceCalculatorTest.php
```

Two things in the output are worth looking at. The duration is a small fraction of the feature file's, because nothing boots: no HTTP kernel, no database, no fakes. And Pest prints no per test timing at all, which it does only for tests that finish essentially instantly.

There is no `uses(RefreshDatabase::class)` line and no `Mail::fake()`, because there is nothing to reset or intercept. Note also that the generated `tests/Pest.php` binds the Laravel `TestCase` only to the `Feature` directory, so unit tests run without a framework instance by default. `new InvoiceCalculator()` works because the class has no dependencies, which is the practical payoff of the "imports nothing" observation in section 5.

This is the test you could not have written before the refactor. The arithmetic existed only as statements in the middle of a controller method, reachable only through an HTTP request. Extracting it by actor made it addressable, and addressable code is testable code.

---

## Next Up - Lesson 4

You took a controller with six responsibilities and gave four of them their own homes, guided by the question of who can demand a change rather than by counting verbs. The tests never moved, which is the proof that the behavior did not either. You also practised the other half of SRP judgment by leaving two things alone: validation, because it is small, and the audit log, because one line is not a responsibility.

Exercise 1 left a thread hanging. Adding `LOYAL5` still meant opening `InvoiceCalculator`, a tested and working class, and editing it. That worked, but it is not free: every edit to working code is a chance to break it, and the file grows with every new rule.

In Lesson 4 you close that gap. You will build a `PaymentService` whose `charge()` method dispatches to Paypal or Stripe through an if/else chain, watch how it demands to be opened for every new gateway, and refactor it behind a `PaymentGateway` contract. Then you will add Midtrans as a third gateway by writing one new file and registering it, without editing the service or its tests at all. That is the Open/Closed Principle, and it is the natural next move once responsibilities have homes.
