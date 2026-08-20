## 1. Before You Begin

Lesson 5 ended by naming an antipattern and refusing to fix it: a class that throws `BadMethodCallException` from a method it was forced to declare. That is unmistakably a Liskov violation, since substituting the class where its contract is expected will crash. But blaming the class misses what actually went wrong. Usually the class is behaving as well as anything could. The fault is upstream, in a contract that demanded more than any single implementer could honestly provide.

The Interface Segregation Principle addresses that upstream cause. It says no client should be forced to depend on methods it does not use, which sounds like advice for the consumer and is really advice about the shape of the contract. Stated as a positive instruction: prefer many small focused interfaces over a few large general purpose ones.

This lesson makes the failure concrete. You will build a `ReportInterface` with six methods and three report classes that each genuinely need only a fraction of them, producing eighteen method declarations of which twelve are lies. Then you will split the interface apart and watch all twelve lies disappear, not get fixed, disappear, because there is nothing left to force them into existence.

### What You'll Build

A reporting module in SolidLab with three reports: a sales report that only renders PDFs, a compliance report that renders and signs, and a data export that produces CSV, schedules itself, and archives. They start behind a fat interface with a consumer full of try/catch blocks, and finish behind six single method capability contracts with a consumer that is type safe.

### What You'll Learn

- ✅ How a fat interface manufactures stub implementations that pass type checks and fail at runtime
- ✅ Why try/catch in a consumer is often a design smell rather than error handling
- ✅ How to split an interface by capability rather than by category
- ✅ How to type hint the smallest contract a method actually needs
- ✅ How to use `instanceof` at a boundary to probe optional capabilities safely
- ✅ How PHP 8 intersection types express "must do both of these things"
- ✅ Why Laravel's `Contracts` directory is full of tiny interfaces rather than a few large ones

### What You'll Need

- SolidLab with Lessons 3 through 5 complete
- PHP 8.3 or later, since section 10 uses intersection types
- The `app/Contracts` directory, which now holds `PaymentGateway` from Lesson 4

---

## 2. Build the Fat Interface

Start with the interface that causes the problem. Read it and notice that nothing about it looks obviously wrong; that is the point.

### Step 1: Create the Reports Directory

```bash
mkdir app/Reports
```

### Step 2: Write the Six Method ReportInterface

Create `app/Contracts/ReportInterface.php`.

```php
<?php

namespace App\Contracts;

interface ReportInterface
{
    public function generatePdf(): string;          // returns the PDF bytes (or path)
    public function generateExcel(): string;        // returns the Excel bytes (or path)
    public function generateCsv(): string;          // returns the CSV string

    public function scheduleDaily(): void;          // registers a daily schedule
    public function archiveToS3(): string;          // uploads to S3, returns the URL
    public function signWithCertificate(): string;  // returns a signed payload
}
```

Read this the way it would have been written originally, and it sounds entirely reasonable. A report should be renderable in the formats the business uses. It should be schedulable. It should be archivable. It should be signable when compliance requires it. Every method belongs to something a report might do.

The error is in the word "might". The interface has gathered six capabilities under one contract because they all happen to appear on objects the business calls reports. But rendering a PDF, running on a schedule, uploading to storage, and applying a cryptographic signature are four unrelated concerns that happen to co-occur. The interface models a *category* of object rather than a set of *capabilities*, and categories are exactly the wrong unit here: no member of the category has all the capabilities.

The name is the tell. `ReportInterface` describes what an object *is*. Section 7 will replace it with six names that describe what an object *can do*, and that shift is the whole principle.

---

## 3. Write Three Reports That Mostly Lie

Each report supports a different subset of the interface, and all three must declare every method.

### Step 1: Add the Schedule Log Helper

`DataExportReport` needs somewhere to record that it registered a schedule. Create `app/Reports/FakeScheduleLog.php`.

```php
<?php

namespace App\Reports;

class FakeScheduleLog
{
    /** @var array<int, array{report:string,frequency:string}> */
    public static array $entries = [];

    public static function record(string $report, string $frequency): void
    {
        self::$entries[] = compact('report', 'frequency');
    }

    public static function reset(): void
    {
        self::$entries = [];
    }

    /** @return array<int, array{report:string,frequency:string}> */
    public static function all(): array
    {
        return self::$entries;
    }
}
```

Same shape as `FakeChannelLog` from Lesson 5, and the same caveat applies: static state is a shortcut to keep this lesson about interfaces rather than about wiring.

### Step 2: Write SimpleSalesReport

Create `app/Reports/SimpleSalesReport.php`. This report has exactly one job.

```php
<?php

namespace App\Reports;

use App\Contracts\ReportInterface;
use BadMethodCallException;

class SimpleSalesReport implements ReportInterface
{
    public function generatePdf(): string
    {
        return 'PDF[SimpleSalesReport: total sales = 12500.00 USD]';
    }

    // Everything below is the antipattern. None of these methods make sense
    // for this report, but the interface demands implementations.

    public function generateExcel(): string
    {
        throw new BadMethodCallException('SimpleSalesReport does not support Excel output');
    }

    public function generateCsv(): string
    {
        throw new BadMethodCallException('SimpleSalesReport does not support CSV output');
    }

    public function scheduleDaily(): void
    {
        throw new BadMethodCallException('SimpleSalesReport is generated on demand only');
    }

    public function archiveToS3(): string
    {
        throw new BadMethodCallException('SimpleSalesReport is not archived');
    }

    public function signWithCertificate(): string
    {
        throw new BadMethodCallException('SimpleSalesReport does not require signing');
    }
}
```

One real method and five landmines. Count the ratio: six sevenths of this file exists purely to satisfy a contract, and every one of those five methods will pass every type check your tooling can run while being guaranteed to fail if called.

There is a worse version of this file, and it is worth picturing. Replace each `throw` with an empty body, and the class returns `''` instead of exploding. That version is more dangerous, because a thrown exception is at least a signal. An empty body produces a plausible looking result and no evidence that anything went wrong, which is the silent truncation problem from Lesson 5 wearing a different hat.

### Step 3: Write ComplianceReport

Create `app/Reports/ComplianceReport.php`. This one has two real capabilities.

```php
<?php

namespace App\Reports;

use App\Contracts\ReportInterface;
use BadMethodCallException;

class ComplianceReport implements ReportInterface
{
    public function generatePdf(): string
    {
        return 'PDF[ComplianceReport: quarterly attestation, period 2026-Q1]';
    }

    public function signWithCertificate(): string
    {
        // In a real integration this would produce a PKCS7 signature.
        return base64_encode('SIGNED::' . $this->generatePdf());
    }

    // Forced stubs.

    public function generateExcel(): string
    {
        throw new BadMethodCallException('ComplianceReport does not support Excel output');
    }

    public function generateCsv(): string
    {
        throw new BadMethodCallException('ComplianceReport does not support CSV output');
    }

    public function scheduleDaily(): void
    {
        throw new BadMethodCallException('ComplianceReport runs quarterly, not daily');
    }

    public function archiveToS3(): string
    {
        throw new BadMethodCallException('ComplianceReport archival is handled by an external system');
    }
}
```

Note the `scheduleDaily` message: this report genuinely runs on a schedule, just a quarterly one. The interface hardcoded a cadence into a method name, so a report with the capability still has to refuse the method. That is a second, quieter failure of the fat interface: it is not only too big, it is too specific.

### Step 4: Write DataExportReport

Create `app/Reports/DataExportReport.php`. Three real capabilities, and no overlap at all with `SimpleSalesReport`.

```php
<?php

namespace App\Reports;

use App\Contracts\ReportInterface;
use BadMethodCallException;
use Illuminate\Support\Facades\Storage;

class DataExportReport implements ReportInterface
{
    public function generateCsv(): string
    {
        return "id,product,quantity\n1,Widget,42\n2,Gadget,17\n";
    }

    public function scheduleDaily(): void
    {
        // In a real app this would call $schedule->call(...)->daily().
        // For demo purposes we just record the registration.
        FakeScheduleLog::record(static::class, 'daily');
    }

    public function archiveToS3(): string
    {
        $key = 'archives/data-export-' . date('Ymd') . '.csv';
        Storage::disk('local')->put($key, $this->generateCsv());

        return "s3://fake-bucket/{$key}";
    }

    // Forced stubs.

    public function generatePdf(): string
    {
        throw new BadMethodCallException('DataExportReport does not produce PDFs');
    }

    public function generateExcel(): string
    {
        throw new BadMethodCallException('DataExportReport does not produce Excel files');
    }

    public function signWithCertificate(): string
    {
        throw new BadMethodCallException('DataExportReport does not require signing');
    }
}
```

Now total it up. Three classes, eighteen method declarations, six of them meaningful. Twelve of the eighteen are stubs: two thirds of the code exists to satisfy a contract rather than to do work.

Look at what the three classes have in common, too: nothing. `SimpleSalesReport` and `DataExportReport` share zero real methods. They are grouped under one interface purely because a human called them both reports.

---

## 4. Watch the Consumer Suffer

The damage is not confined to the implementations. Any code that accepts a `ReportInterface` has no way to know which methods will work, because the type tells it all six exist and reality says otherwise.

### Step 1: Write the Defensive ReportingService

Create `app/Services/ReportingService.php`.

```php
<?php

namespace App\Services;

use App\Contracts\ReportInterface;
use BadMethodCallException;

class ReportingService
{
    public function renderPdf(ReportInterface $report): ?string
    {
        try {
            return $report->generatePdf();
        } catch (BadMethodCallException) {
            return null;                       // silently mask the antipattern
        }
    }

    public function exportCsv(ReportInterface $report): ?string
    {
        try {
            return $report->generateCsv();
        } catch (BadMethodCallException) {
            return null;
        }
    }

    public function archive(ReportInterface $report): ?string
    {
        try {
            return $report->archiveToS3();
        } catch (BadMethodCallException) {
            return null;
        }
    }
}
```

These try/catch blocks are not error handling. Nothing here has gone wrong at run time; the service is catching a *design decision*. It is using the exception mechanism to ask a question that the type system should have answered: can this object do this thing?

Three costs follow, and all three compound. The return types became nullable, so every caller now has to handle a `null` that means "not supported" and is indistinguishable from `null` meaning "failed". Every new capability added to the interface requires a matching try/catch in every consumer, so the defensive code grows with the product of capabilities and consumers. And the `return null` silently swallows a genuine `BadMethodCallException` from anywhere deeper in the call stack, which is a real bug turned invisible.

This is the code that actually grows in real codebases when interfaces lie, and it grows one reasonable looking commit at a time.

---

## 5. Write the Tests and Capture a Baseline

The tests describe the behavior that must survive the refactor. They deliberately exercise only what each report genuinely supports, which turns out to be a hint about the right shape for the contracts.

### Step 1: Create the Test File

```bash
php artisan make:test ReportingTest --pest
```

### Step 2: Write Five Behavior Tests

Open `tests/Feature/ReportingTest.php` and replace its body.

```php
<?php

use App\Reports\ComplianceReport;
use App\Reports\DataExportReport;
use App\Reports\FakeScheduleLog;
use App\Reports\SimpleSalesReport;
use App\Services\ReportingService;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    FakeScheduleLog::reset();
});

it('renders a PDF for the simple sales report', function () {
    $service = app(ReportingService::class);
    $output  = $service->renderPdf(new SimpleSalesReport());

    expect($output)->toContain('SimpleSalesReport')
                   ->and($output)->toContain('total sales');
});

it('renders a PDF for the compliance report and signs it', function () {
    $report = new ComplianceReport();

    $pdf    = $report->generatePdf();
    $signed = $report->signWithCertificate();

    expect($pdf)->toContain('ComplianceReport')
                ->and(base64_decode($signed))->toStartWith('SIGNED::');
});

it('exports CSV for the data export report', function () {
    $service = app(ReportingService::class);
    $csv     = $service->exportCsv(new DataExportReport());

    expect($csv)->toContain('id,product,quantity')
                ->and($csv)->toContain('Widget,42');
});

it('archives the data export report to a storage URL', function () {
    Storage::fake('local');

    $service = app(ReportingService::class);
    $url     = $service->archive(new DataExportReport());

    expect($url)->toStartWith('s3://fake-bucket/archives/data-export-');
});

it('schedules the data export report on a daily cadence', function () {
    $report = new DataExportReport();
    $report->scheduleDaily();

    $entries = FakeScheduleLog::all();
    expect($entries)->toHaveCount(1)
                    ->and($entries[0]['report'])->toBe(DataExportReport::class)
                    ->and($entries[0]['frequency'])->toBe('daily');
});
```

Every test pairs a report with a capability it really has. Not one of them calls a stub, which is worth pausing on: five tests cover the entire useful surface of this module, and they touch six of the eighteen declared methods. The twelve stubs are untested because there is nothing to test, yet they still ship, still appear in autocomplete, and still crash anyone who trusts the type.

`->and(...)` chains further assertions onto one `expect()` call, which keeps a related group of checks in one statement.

### Step 3: Run the Baseline

```bash
php artisan test tests/Feature/ReportingTest.php
```

```
   PASS  Tests\Feature\ReportingTest
  ✓ it renders a PDF for the simple sales report                         0.09s  
  ✓ it renders a PDF for the compliance report and signs it              0.02s  
  ✓ it exports CSV for the data export report                            0.02s  
  ✓ it archives the data export report to a storage URL                  0.02s  
  ✓ it schedules the data export report on a daily cadence               0.02s  

  Tests:    5 passed (10 assertions)
  Duration: 0.23s
```

**5 passed, 10 assertions.** Green, and the module is still full of landmines. That combination is the honest summary of what a test suite can and cannot tell you: these tests prove the working paths work, and say nothing at all about the twelve methods nobody dared call.

---

## 6. Split the Interface by Capability

Now the refactor. Each capability becomes its own interface, named for what an object can do rather than what it is.

### Step 1: Write the Six Capability Contracts

Create the following six files in `app/Contracts/`.

```php
<?php

namespace App\Contracts;

interface PdfReportable
{
    public function generatePdf(): string;
}
```

```php
<?php

namespace App\Contracts;

interface ExcelReportable
{
    public function generateExcel(): string;
}
```

```php
<?php

namespace App\Contracts;

interface CsvReportable
{
    public function generateCsv(): string;
}
```

```php
<?php

namespace App\Contracts;

interface Schedulable
{
    public function scheduleDaily(): void;
}
```

```php
<?php

namespace App\Contracts;

interface Archivable
{
    public function archiveToS3(): string;
}
```

```php
<?php

namespace App\Contracts;

interface Signable
{
    public function signWithCertificate(): string;
}
```

Six interfaces, one method each. Compare the names against the original: `ReportInterface` answered "what is this object", while `PdfReportable`, `Schedulable`, and `Signable` answer "what can this object do". The `-able` suffix is not a style choice, it is the principle showing through the naming.

A class that implements `PdfReportable` makes exactly one narrow promise, and a caller holding a `PdfReportable` can rely on it completely. A class with three capabilities implements three interfaces. No class ever declares a capability it lacks, because nothing forces it to.

### Step 2: Delete the Fat Interface

```bash
rm app/Contracts/ReportInterface.php
```

Deleting it entirely rather than keeping it around as a convenience aggregate is deliberate. An interface that extends all six would immediately recreate the original problem for anyone who implemented it, and the only class that could honestly implement it is one that does all six things, which does not exist here.

---

## 7. Rewire the Reports

Each report now declares only what it does. This is the section where the twelve stubs vanish.

### Step 1: Reduce SimpleSalesReport to One Method

Replace `app/Reports/SimpleSalesReport.php`.

```php
<?php

namespace App\Reports;

use App\Contracts\PdfReportable;

class SimpleSalesReport implements PdfReportable
{
    public function generatePdf(): string
    {
        return 'PDF[SimpleSalesReport: total sales = 12500.00 USD]';
    }
}
```

From six methods to one. The five stubs were not rewritten or improved; there is simply no longer anything demanding that they exist. The `BadMethodCallException` import is gone too, and a class that no longer needs to import an exception type is usually a class that stopped lying.

### Step 2: Reduce ComplianceReport to Two

Replace `app/Reports/ComplianceReport.php`.

```php
<?php

namespace App\Reports;

use App\Contracts\PdfReportable;
use App\Contracts\Signable;

class ComplianceReport implements PdfReportable, Signable
{
    public function generatePdf(): string
    {
        return 'PDF[ComplianceReport: quarterly attestation, period 2026-Q1]';
    }

    public function signWithCertificate(): string
    {
        return base64_encode('SIGNED::' . $this->generatePdf());
    }
}
```

Two capabilities, two interfaces, two methods. The class declaration now reads as a factual summary of the file: this report renders a PDF and it signs.

### Step 3: Reduce DataExportReport to Three

Replace `app/Reports/DataExportReport.php`.

```php
<?php

namespace App\Reports;

use App\Contracts\Archivable;
use App\Contracts\CsvReportable;
use App\Contracts\Schedulable;
use Illuminate\Support\Facades\Storage;

class DataExportReport implements CsvReportable, Schedulable, Archivable
{
    public function generateCsv(): string
    {
        return "id,product,quantity\n1,Widget,42\n2,Gadget,17\n";
    }

    public function scheduleDaily(): void
    {
        FakeScheduleLog::record(static::class, 'daily');
    }

    public function archiveToS3(): string
    {
        $key = 'archives/data-export-' . date('Ymd') . '.csv';
        Storage::disk('local')->put($key, $this->generateCsv());

        return "s3://fake-bucket/{$key}";
    }
}
```

Eighteen declarations became six. Twelve stubs became zero. Every method that survives is a method the class actually implements, which means the type of every one of these objects is now a true statement about it.

---

## 8. Shrink the Consumer's Requirements

The service can now ask for the smallest contract each method actually needs, and the try/catch blocks lose their reason to exist.

### Step 1: Type Hint the Narrowest Contract

Replace `app/Services/ReportingService.php`.

```php
<?php

namespace App\Services;

use App\Contracts\Archivable;
use App\Contracts\CsvReportable;
use App\Contracts\PdfReportable;

class ReportingService
{
    public function renderPdf(PdfReportable $report): string
    {
        return $report->generatePdf();
    }

    public function exportCsv(CsvReportable $report): string
    {
        return $report->generateCsv();
    }

    public function archive(Archivable $report): string
    {
        return $report->archiveToS3();
    }
}
```

Each parameter type is now the smallest contract that satisfies its method body. `renderPdf` does not care whether the report can also be signed, scheduled, or archived; it calls one method, so it asks for the one interface that guarantees that method.

The try/catch blocks are gone, and so are the nullable return types. `renderPdf` returns `string`, not `?string`, because there is no longer any way to reach its body with an object that cannot produce a PDF. The `null` that used to mean "not supported" has no cases left to represent.

Consider what happened to the bug class. Passing a `DataExportReport` to `renderPdf` used to compile, run, throw internally, get swallowed, and return `null` to a caller with no idea why. Now it is a `TypeError` at the call site, and static analysis flags it before the code ever runs. To be precise about PHP: this is a run time check that fires the moment the call is made, not a compile time one, so the guarantee is "it fails immediately and unmistakably at the boundary" rather than "it cannot be written". Combined with a static analyser like PHPStan or Larastan reading the same type hints, it does become a build time guarantee.

### Step 2: Probe Optional Capabilities at a Boundary

Narrow interfaces handle the case where the caller knows what it needs. Sometimes a pipeline receives a report and wants to do everything that report supports, whatever that turns out to be. Capability interfaces handle that too, with `instanceof` checks at a single well defined boundary.

Add `processAvailable` to `app/Services/ReportingService.php`, so the file reads as follows.

```php
<?php

namespace App\Services;

use App\Contracts\Archivable;
use App\Contracts\CsvReportable;
use App\Contracts\PdfReportable;
use App\Contracts\Schedulable;
use App\Contracts\Signable;

class ReportingService
{
    public function renderPdf(PdfReportable $report): string
    {
        return $report->generatePdf();
    }

    public function exportCsv(CsvReportable $report): string
    {
        return $report->generateCsv();
    }

    public function archive(Archivable $report): string
    {
        return $report->archiveToS3();
    }

    /**
     * Process whatever the given report can do. Each capability is
     * detected with instanceof, and the branch only runs when supported.
     *
     * @return array<string, string|bool>
     */
    public function processAvailable(object $report): array
    {
        $result = [];

        if ($report instanceof PdfReportable) {
            $result['pdf'] = $report->generatePdf();
        }
        if ($report instanceof CsvReportable) {
            $result['csv'] = $report->generateCsv();
        }
        if ($report instanceof Signable) {
            $result['signature'] = $report->signWithCertificate();
        }
        if ($report instanceof Archivable) {
            $result['archive_url'] = $report->archiveToS3();
        }
        if ($report instanceof Schedulable) {
            $report->scheduleDaily();
            $result['scheduled'] = true;
        }

        return $result;
    }
}
```

The parameter is typed `object` rather than any interface, because the method's whole job is to discover capabilities it cannot assume. Inside each `if`, PHP narrows the type, so the call within the branch is safe and static analysis agrees.

Compare this against the try/catch version in section 4, because they look superficially similar and are opposites. The try/catch asked "did calling this blow up?" after the fact, and could not distinguish an unsupported capability from a genuine failure. The `instanceof` asks "does this object declare this capability?" before calling, using information the type system actually has. One is honest at run time only; the other is honest at the point of writing.

Lesson 5 listed `instanceof` as a smell, and it is worth reconciling that. There, the check special cased one concrete subclass to work around an inadequate contract. Here it probes an interface at a deliberate boundary where heterogeneous objects converge. Testing for a *capability* is a different act from testing for a *class*, and it is the intended use of these small contracts.

---

## 9. Run and Test

The five original tests still pass, since no report's real behavior changed. Add one more to prove that capability detection works.

Append this to `tests/Feature/ReportingTest.php`.

```php
it('processes only the capabilities each report supports', function () {
    Storage::fake('local');

    $service = app(ReportingService::class);

    $simple     = $service->processAvailable(new SimpleSalesReport());
    $compliance = $service->processAvailable(new ComplianceReport());
    $export     = $service->processAvailable(new DataExportReport());

    // SimpleSalesReport only supports PDF.
    expect($simple)->toHaveKey('pdf')
                   ->and($simple)->not->toHaveKey('csv')
                   ->and($simple)->not->toHaveKey('signature');

    // ComplianceReport supports PDF and signing.
    expect($compliance)->toHaveKey('pdf')
                       ->and($compliance)->toHaveKey('signature')
                       ->and($compliance)->not->toHaveKey('csv');

    // DataExportReport supports CSV, archive, and scheduling.
    expect($export)->toHaveKey('csv')
                   ->and($export)->toHaveKey('archive_url')
                   ->and($export)->toHaveKey('scheduled')
                   ->and($export)->not->toHaveKey('pdf');
});
```

The `not->toHaveKey` assertions carry as much weight as the positive ones. They prove the pipeline did not attempt an unsupported capability, which under the old design would have meant an exception thrown and swallowed on every unsupported call.

```bash
php artisan test tests/Feature/ReportingTest.php
```

```
   PASS  Tests\Feature\ReportingTest
  ✓ it renders a PDF for the simple sales report                         0.09s  
  ✓ it renders a PDF for the compliance report and signs it              0.02s  
  ✓ it exports CSV for the data export report                            0.02s  
  ✓ it archives the data export report to a storage URL                  0.02s  
  ✓ it schedules the data export report on a daily cadence               0.02s  
  ✓ it processes only the capabilities each report supports              0.02s  

  Tests:    6 passed (20 assertions)
  Duration: 0.25s
```

The original five are untouched and green, and the sixth confirms capability detection. Behavior was preserved while twelve stub methods were deleted outright.

Note that the assertion count doubled, from 10 to 20, while only one test was added. That is the new test carrying ten assertions on its own, and it is a fair reflection of how much the previous design left unverifiable.

---

## 10. Understanding Interface Segregation

The principle's own wording, that no client should be forced to depend on methods it does not use, is easy to misread as being about consumers. The consumers in section 4 certainly suffered, but they were victims rather than causes. The real subject is the shape of the contract, and the practical rule is to split by capability rather than by category.

The difference is visible in the names. Categories answer "what is this": `ReportInterface`, `UserInterface`, `PaymentInterface`. Capabilities answer "what can this do": `PdfReportable`, `Schedulable`, `Signable`. Category interfaces attract methods, because anything a member of the category might conceivably do has a plausible claim to belong. Capability interfaces resist growth, because a method that does not serve the single capability obviously does not fit.

The diagnostic is the stub. Any implementation that throws, returns null, or does nothing to satisfy an interface is evidence that the interface asked for something that class cannot provide. One such stub might mean one badly designed class. Twelve out of eighteen means the interface is wrong, and no amount of fixing the classes will help.

Segregation does not mean one method per interface, even though it produced that here by coincidence. The rule is to group methods that clients actually use together. If every caller who reads also writes, `Readable` and `Writable` can reasonably be one `Storage` interface; splitting them further would add files without eliminating a single forced implementation. Exercise 3 in Lesson 1 made this same point from the other direction.

It is also worth being clear about how ISP relates to the two principles before it. A fat interface causes LSP violations, since the stubs are precisely the substitution failures Lesson 5 hunted. And ISP makes OCP practical, because when Lesson 4 defined `PaymentGateway` with only `name()` and `charge()`, that restraint is what let a new gateway be a small honest file rather than a large mostly fake one. The principles are not five separate rules; they are five views of the same concern.

---

## 11. Why Laravel's Contracts Directory Looks the Way It Does

Open the framework source and look at `Illuminate/Contracts/Cache`. There is no single `Cache` interface. There is `Repository`, `Store`, `Lock`, `Factory`, and `LockProvider`, each small and each describing one capability.

That decomposition is why `Cache::store('redis')` and a custom driver registered through `Cache::extend()` can coexist. A driver that supports atomic locks implements `LockProvider`; one that does not, does not, and no driver is ever forced to throw from a lock method it cannot honor. The same pattern repeats across `Filesystem`, `Queue`, and `Mail`.

`Illuminate\Contracts\Support` is even more direct. `Arrayable`, `Jsonable`, `Renderable`, and `Responsable` each declare a single method and are named for what an object can do. Any class in your application can implement `Arrayable` without inheriting anything else, and the framework then knows how to convert it. That is capability based design at framework scale, and it is exactly the shape section 6 built.

The practical takeaway when designing your own contracts: if you cannot name the interface after a single capability without reaching for a noun that describes a category, you are probably about to write a fat interface. `PdfReportable` names itself easily. `ReportInterface` needs the word "Interface" in it because there is no single idea to name.

---

## 12. Fix the Errors in Your Code

**Error 1: Keeping the fat interface as a convenience aggregate.**

The split is done, and it feels wasteful to write three `implements` clauses, so an interface extending all six seems like a tidy shortcut.

```php
// Wrong: this recreates the original problem for anyone who implements it
interface ReportInterface extends
    PdfReportable, ExcelReportable, CsvReportable,
    Schedulable, Archivable, Signable
{
}

class SimpleSalesReport implements ReportInterface  // back to six stubs
{
}

// Correct: each class names exactly the capabilities it has
class SimpleSalesReport implements PdfReportable
{
}
```

The aggregate is only honest for a class that genuinely has all six capabilities, and no such class exists here. Its presence guarantees that the next developer under time pressure implements it and reintroduces the stubs, because it is the shortest thing to type.

**Error 2: Type hinting a wider interface than the method body needs.**

```php
// Wrong: demands signing capability to render a PDF
public function renderPdf(PdfReportable&Signable $report): string
{
    return $report->generatePdf();
}

// Correct: ask for exactly what the body calls
public function renderPdf(PdfReportable $report): string
{
    return $report->generatePdf();
}
```

The wrong version compiles, passes its tests with `ComplianceReport`, and silently excludes `SimpleSalesReport` from a method that would work perfectly on it. The rule is mechanical and worth applying literally: read the method body, list the methods it calls on the parameter, and require the smallest type that provides them.

**Error 3: Adding a capability interface and forgetting to probe for it in the boundary method.**

`processAvailable` checks five capabilities. `ExcelReportable` is not one of them, so an Excel capable report passes through the pipeline and quietly produces no Excel output.

```php
// Wrong: ExcelReportable exists as a contract but nothing ever detects it
if ($report instanceof PdfReportable) {
    $result['pdf'] = $report->generatePdf();
}
if ($report instanceof CsvReportable) {
    $result['csv'] = $report->generateCsv();
}

// Correct: every capability the system defines is probed
if ($report instanceof PdfReportable) {
    $result['pdf'] = $report->generatePdf();
}
if ($report instanceof CsvReportable) {
    $result['csv'] = $report->generateCsv();
}
if ($report instanceof ExcelReportable) {
    $result['excel'] = $report->generateExcel();
}
```

This is the honest cost of the `instanceof` boundary, and it should be weighed rather than waved away. The fat interface guaranteed the consumer knew about every capability, at the price of forcing every implementation to lie. Capability interfaces remove the lies and move the completeness burden onto the boundary method. That trade is worth making, but it means a new capability requires updating each probing pipeline, and only a test will remind you. Exercise 1 walks through exactly this failure.

---

## 13. Exercises

**Exercise 1:** Add a `BudgetReport` that implements `ExcelReportable` and `Archivable`. Write a test asserting that `processAvailable` returns both an `excel` key and an `archive_url` key for it. Run it before changing `ReportingService` and report what happens, then make it pass.

**Exercise 2:** Prove that the type system now prevents the bug the fat interface allowed. Write a test asserting that passing a `DataExportReport` to `renderPdf` throws a `TypeError`. Then explain in one sentence what the old design did in the same situation.

**Exercise 3:** A new requirement says only a report that can render a PDF *and* sign it may be submitted to the regulator. Write a function whose signature enforces that at the type level, using PHP 8 intersection types, and write two tests: one that accepts `ComplianceReport` and one that rejects `SimpleSalesReport`.

---

## 14. Solutions

**Solution for Exercise 1:**

```php
<?php

namespace App\Reports;

use App\Contracts\Archivable;
use App\Contracts\ExcelReportable;
use Illuminate\Support\Facades\Storage;

class BudgetReport implements ExcelReportable, Archivable
{
    public function generateExcel(): string
    {
        return 'XLSX[BudgetReport: 2026 departmental budget]';
    }

    public function archiveToS3(): string
    {
        $key = 'archives/budget-' . date('Ymd') . '.xlsx';
        Storage::disk('local')->put($key, $this->generateExcel());

        return "s3://fake-bucket/{$key}";
    }
}
```

```php
it('detects the excel capability once processAvailable probes for it', function () {
    Storage::fake('local');

    $result = app(ReportingService::class)->processAvailable(new BudgetReport());

    expect($result)->toHaveKey('excel')
                   ->and($result)->toHaveKey('archive_url')
                   ->and($result)->not->toHaveKey('pdf');
});
```

Run it first and it fails, because `processAvailable` never asks about `ExcelReportable`. The `archive_url` key is present and correct, which makes the failure specific: this is not a broken report, it is an incomplete pipeline. Add the probe from Error 3 and it passes.

The interesting part is the failure mode. Nothing threw, nothing logged, and the report ran successfully through the pipeline producing one of its two outputs. Without a test asking for the `excel` key, this ships silently. That is the burden the `instanceof` boundary accepts in exchange for eliminating stubs, and the mitigation is to add a test alongside every new capability rather than to wish the burden away.

**Solution for Exercise 2:**

```php
it('refuses a report that cannot render a pdf, at the type level', function () {
    $service = app(ReportingService::class);

    expect(fn () => $service->renderPdf(new DataExportReport()))
        ->toThrow(TypeError::class);
});
```

The `TypeError` fires at the call boundary, before a single line of `renderPdf` executes.

Under the fat interface, the same call was accepted without complaint. It entered the method, called `generatePdf()`, hit the `BadMethodCallException` stub, had that exception swallowed by the try/catch, and returned `null` to a caller that could not tell "this report has no PDF" from "PDF generation failed". A programming error had been converted into a data value and passed downstream.

Note the precision worth keeping: this is enforcement at run time, at the moment of the call, not at compile time. PHP has no compile step that would reject the code outright. What makes it a build time guarantee in practice is running PHPStan or Larastan over the same type hints, which reports the mismatch without executing anything.

**Solution for Exercise 3:**

```php
function certify(PdfReportable&Signable $report): string
{
    return $report->signWithCertificate();
}

it('accepts a report satisfying an intersection type', function () {
    expect(base64_decode(certify(new ComplianceReport())))->toStartWith('SIGNED::');
});

it('rejects a report that satisfies only half the intersection', function () {
    expect(fn () => certify(new SimpleSalesReport()))
        ->toThrow(TypeError::class);
});
```

`PdfReportable&Signable` reads as "must implement both", and PHP enforces it at the call site. `ComplianceReport` implements both and passes. `SimpleSalesReport` implements only `PdfReportable`, so the call throws before the body runs, even though `SimpleSalesReport` is a perfectly valid report.

Intersection types are what make a fine grained split practical rather than merely tidy. Without them, the only way to express "renders and signs" would be to define a third interface extending both, and requirements combine faster than you can name their combinations: renders and signs, renders and archives, exports and schedules. Intersections let you compose requirements at the point of use, so the six base contracts cover every combination a caller might need without a single extra file.

This is the answer to the objection that six interfaces are more to manage than one. Six composable pieces express far more than one rigid contract, and they express it precisely, at the call sites where precision matters.

---

## Next Up - Lesson 7

You took eighteen method declarations, twelve of which were lies, and reduced them to six honest ones. The stubs did not get fixed; they stopped being possible, because nothing required them. On the consumer side, defensive try/catch blocks disappeared and nullable returns became plain strings, since the type system now answers the question the exceptions used to ask. You also saw why Laravel's `Contracts` directory is a catalogue of tiny capabilities rather than a few grand ones.

Four principles down. Each has been about the shape of a class or a contract: how many reasons it has to change, whether it can be extended without editing, whether its implementations keep their promises, whether it asks for more than its clients need.

The fifth is about the direction of dependencies, and it is the one that makes the other four enforceable. In Lesson 7 you will build a newsletter controller welded to Mailchimp with `new MailchimpProvider(...)` in the middle of a request handler, watch its tests strain against real HTTP, then invert it onto a `NewsletterProvider` contract resolved by the service container. Along the way you will untangle three terms that are constantly confused: dependency inversion, dependency injection, and inversion of control. That is the Dependency Inversion Principle, and it is where the Laravel container stops being convenient plumbing and starts being the thing that holds the design together.
