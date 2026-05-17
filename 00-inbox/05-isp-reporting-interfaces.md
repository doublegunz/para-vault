# Interface Segregation Principle in Laravel 13: Stop Forcing Classes to Implement Methods They Don't Need

You inherit a reporting module that defines a single `ReportInterface`. The interface declares six methods: `generatePdf`, `generateExcel`, `generateCsv`, `scheduleDaily`, `archiveToS3`, and `signWithCertificate`. Almost every report only uses one or two of these. The simple sales report just needs PDF output. The compliance report needs PDF plus signing. The data export needs CSV only. But every single report class is forced to declare all six methods because the interface demands them. The result, you discover when reading the code, is that most reports satisfy the contract by throwing `BadMethodCallException` from the methods they do not actually support.

The codebase compiles. The type system is satisfied. Nothing fails until production, when a scheduled job calls `archiveToS3()` on a report that lied about supporting it, the exception fires, the queue retries, and finally the on-call engineer gets paged at three in the morning. The interface promised more than the implementations could deliver, and there was no way to tell from the type system alone.

This article is the fifth in our SOLID series, following [Liskov Substitution Principle in Laravel 13: Why Inheritance Can Silently Break Your Code](https://qadrlabs.com). The Interface Segregation Principle is exactly the discipline that prevents the situation above. We will build a fat reporting interface with the same six methods, watch concrete report classes drown in stub implementations, capture a baseline Pest run, and then split the interface into focused capability contracts. Reports declare only what they truly do. Callers ask for only what they need. The `BadMethodCallException` antipattern disappears entirely.

## Overview {#overview}

The work has three phases. First we build the fat `ReportInterface` and three concrete reports that each support a different subset of its methods. The reports are forced to declare the methods they do not need, and they implement those methods by throwing `BadMethodCallException`. We write Pest tests against the public reporting behavior and capture a green baseline. Second we refactor the fat interface into six small capability interfaces (`PdfReportable`, `ExcelReportable`, `CsvReportable`, `Schedulable`, `Archivable`, `Signable`) and rewire each report to implement only the capabilities it actually has. Third we update the consuming code to depend on the smallest capability interface it needs, so the type system can guarantee at compile time that no report will be asked to do something it does not support.

### What You'll Build
- A Laravel 13 reporting module with three reports of different shapes
- A "before" `ReportInterface` with six methods that no report actually needs in full
- Six capability interfaces (`PdfReportable`, `ExcelReportable`, `CsvReportable`, `Schedulable`, `Archivable`, `Signable`)
- A reporting service that asks for the smallest interface it needs and uses PHP's `instanceof` check to discover optional capabilities

### What You'll Learn
- How to recognize a fat interface and the `BadMethodCallException` antipattern it produces
- How to split a single large contract into small capability interfaces
- Why Laravel's own `Contracts` directory is the canonical example of ISP done right
- How to use PHP's `instanceof` check at the boundary to consume capability interfaces safely

### What You'll Need
- PHP 8.3 or later
- Composer 2.x
- Familiarity with PHP interfaces and the difference between an interface and an abstract class
- A terminal and a code editor

## Step 1: Set Up the Laravel Project {#step-1-set-up-the-laravel-project}

Create a fresh Laravel 13 project with Pest. The same toolchain we used in earlier articles applies.

```bash
laravel new isp-reporting-demo --no-interaction --database=sqlite --pest --no-boost
cd isp-reporting-demo
```

Confirm Pest works before adding any code.

```bash
php artisan test
```

The two example tests should pass.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

  Tests:    2 passed (2 assertions)
  Duration: 0.17s
```

## Step 2: Build the Fat ReportInterface {#step-2-build-the-fat-reportinterface}

Create the contracts directory and the fat interface that will demonstrate the antipattern.

```bash
mkdir -p app/Contracts app/Reports
```

Create `app/Contracts/ReportInterface.php` with the following content. The interface declares six methods, which sounds reasonable in the abstract: a "report" should be able to render in several formats, schedule itself, archive itself, and sign itself. The trouble starts the moment you ask whether any single concrete report actually needs all six.

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

The interface is the textbook fat interface. It treats unrelated capabilities (rendering, scheduling, archiving, signing) as if they were the same kind of thing, because they all happen to live on objects called "reports". They are not the same kind of thing, and we are about to feel the consequences.

## Step 3: Create Three Reports That Don't Need Most of It {#step-3-create-three-reports-that-dont-need-most-of-it}

Each of the three reports we are about to build supports a different subset of the fat interface, but all three are forced to declare every method.

Create `app/Reports/SimpleSalesReport.php` with the following content. This report is meant to do one thing: render a PDF of the day's sales. The interface forces it to pretend it can also do Excel, CSV, scheduling, archiving, and signing.

```php
<?php

namespace App\Reports;

use App\Contracts\ReportInterface;
use BadMethodCallException;

class SimpleSalesReport implements ReportInterface
{
    public function generatePdf(): string
    {
        return "PDF[SimpleSalesReport: total sales = 12500.00 USD]";
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

Create `app/Reports/ComplianceReport.php` with the following content. This report is the only one that genuinely needs signing. It also produces a PDF. Everything else is a forced stub.

```php
<?php

namespace App\Reports;

use App\Contracts\ReportInterface;
use BadMethodCallException;

class ComplianceReport implements ReportInterface
{
    public function generatePdf(): string
    {
        return "PDF[ComplianceReport: quarterly attestation, period 2026-Q1]";
    }

    public function signWithCertificate(): string
    {
        // In a real integration this would produce a PKCS7 signature.
        return base64_encode("SIGNED::" . $this->generatePdf());
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

Create `app/Reports/DataExportReport.php` with the following content. This one is essentially a CSV producer that runs daily and gets archived to S3. It does not produce PDFs, Excel, or signed payloads.

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

We also need the small `FakeScheduleLog` helper used by `DataExportReport::scheduleDaily`. Create `app/Reports/FakeScheduleLog.php` with the following content. It is just plumbing for the demo, not part of the contract under discussion.

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

Three reports, eighteen method declarations, and only six of those methods are actually meaningful. The other twelve are landmines that pass type checks and explode at runtime. That ratio (one third real implementation, two thirds stub) is what ISP is trying to fix.

## Step 4: Build a Reporting Service That Tries to Cope {#step-4-build-a-reporting-service-that-tries-to-cope}

The consumer side suffers too. A `ReportingService` that wants to use the fat interface has no way to know in advance which methods will throw and which will work. The only realistic strategy is to call the method and catch the exception, which turns runtime errors into control flow.

Create `app/Services/ReportingService.php` with the following content. It exposes one entry point per capability and uses try/catch to hide the antipattern from callers.

```bash
mkdir -p app/Services
```

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

This is the kind of code that grows in real codebases when interfaces lie about capabilities. The try/catch blocks are not handling errors; they are handling the design flaw. Every new capability added to the interface forces a corresponding `try/catch` in every consumer. The code grows quadratically, and silent `null` returns hide bugs.

## Step 5: Write the Pest Tests {#step-5-write-the-pest-tests}

The tests describe the public reporting behavior we want to preserve through the refactor. They focus on what each report can actually do, ignoring the stub methods entirely.

Generate the test file.

```bash
php artisan make:test ReportingTest --pest
```

Open `tests/Feature/ReportingTest.php` and replace its body with the following.

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
                ->and($signed)->toStartWith(base64_encode('SIGNED::'));
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

Each test exercises only the methods the report under test actually supports. None of the tests depend on the fat interface; they depend on the concrete capabilities each report offers. This is a hint about the right shape of the contracts.

## Step 6: Run the Baseline Tests {#step-6-run-the-baseline-tests}

Run the suite to capture a green baseline.

```bash
php artisan test
```

The output should look like this. Five new tests pass, plus the two examples that ship with Laravel.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

   PASS  Tests\Feature\ReportingTest
  ✓ it renders a PDF for the simple sales report                                                                                                                                                       0.05s
  ✓ it renders a PDF for the compliance report and signs it                                                                                                                                            0.03s
  ✓ it exports CSV for the data export report                                                                                                                                                          0.02s
  ✓ it archives the data export report to a storage URL                                                                                                                                                0.03s
  ✓ it schedules the data export report on a daily cadence                                                                                                                                             0.02s

  Tests:    7 passed (16 assertions)
  Duration: 0.42s
```

Seven tests passing. The baseline is locked. Now we refactor toward ISP.

## Step 7: Split the Fat Interface Into Capabilities {#step-7-split-the-fat-interface-into-capabilities}

Each capability becomes its own focused interface. The names describe what an object can do, not what it is. This is the conceptual shift ISP demands: stop modeling categories and start modeling capabilities.

Create six interface files inside `app/Contracts/`. Start with `app/Contracts/PdfReportable.php`.

```php
<?php

namespace App\Contracts;

interface PdfReportable
{
    public function generatePdf(): string;
}
```

Then `app/Contracts/ExcelReportable.php`.

```php
<?php

namespace App\Contracts;

interface ExcelReportable
{
    public function generateExcel(): string;
}
```

Then `app/Contracts/CsvReportable.php`.

```php
<?php

namespace App\Contracts;

interface CsvReportable
{
    public function generateCsv(): string;
}
```

Then `app/Contracts/Schedulable.php`.

```php
<?php

namespace App\Contracts;

interface Schedulable
{
    public function scheduleDaily(): void;
}
```

Then `app/Contracts/Archivable.php`.

```php
<?php

namespace App\Contracts;

interface Archivable
{
    public function archiveToS3(): string;
}
```

Finally `app/Contracts/Signable.php`.

```php
<?php

namespace App\Contracts;

interface Signable
{
    public function signWithCertificate(): string;
}
```

Six interfaces, one method each. The contracts are now precise. A class that implements `PdfReportable` is making a single, narrow promise that callers can rely on. The same class can implement two or three of these interfaces if it has multiple capabilities, but it never has to lie about capabilities it lacks.

We can now delete the fat interface entirely. Remove `app/Contracts/ReportInterface.php`.

```bash
rm app/Contracts/ReportInterface.php
```

## Step 8: Rewire Each Report to Implement Only What It Does {#step-8-rewire-each-report-to-implement-only-what-it-does}

The reports get to drop everything they were forced to fake. Each one declares only the capability interfaces that match its real responsibilities.

Open `app/Reports/SimpleSalesReport.php` and replace its body with the following. The class drops from seven methods to one and switches from one fat interface to one capability interface.

```php
<?php

namespace App\Reports;

use App\Contracts\PdfReportable;

class SimpleSalesReport implements PdfReportable
{
    public function generatePdf(): string
    {
        return "PDF[SimpleSalesReport: total sales = 12500.00 USD]";
    }
}
```

Open `app/Reports/ComplianceReport.php` and replace its body with the following. This report implements two capability interfaces (PDF and signing) and nothing else.

```php
<?php

namespace App\Reports;

use App\Contracts\PdfReportable;
use App\Contracts\Signable;

class ComplianceReport implements PdfReportable, Signable
{
    public function generatePdf(): string
    {
        return "PDF[ComplianceReport: quarterly attestation, period 2026-Q1]";
    }

    public function signWithCertificate(): string
    {
        return base64_encode("SIGNED::" . $this->generatePdf());
    }
}
```

Open `app/Reports/DataExportReport.php` and replace its body with the following. Three capabilities (CSV, schedule, archive), zero stubs.

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

The transformation is the most visible benefit of ISP. Twelve of the original eighteen method declarations were stubs that lied about behavior. Now there are zero stubs. Every method that exists is a method the class actually implements meaningfully.

## Step 9: Refactor the Service to Use the Smallest Interface It Needs {#step-9-refactor-the-service-to-use-the-smallest-interface-it-needs}

The consumer side gets cleaner too. Each method on `ReportingService` now asks for the specific capability it needs, and the type system guarantees the report supports it. The try/catch blocks disappear because the antipattern that made them necessary no longer exists.

Open `app/Services/ReportingService.php` and replace its body with the following.

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

Each parameter type is the smallest contract that satisfies the method body. `renderPdf` does not care whether the report can also be signed or scheduled; it only needs to call `generatePdf`, so it asks for `PdfReportable`. The type system now refuses to compile any code that tries to pass a `DataExportReport` (which is not `PdfReportable`) to `renderPdf`. The bug class that the fat interface allowed at runtime is now eliminated at compile time.

## Step 10: Use instanceof at the Boundary for Optional Capabilities {#step-10-use-instanceof-at-the-boundary-for-optional-capabilities}

Sometimes you have a generic processing pipeline that receives a report and wants to "do everything that is supported": render any available format, schedule if possible, archive if possible. With capability interfaces, this is expressed cleanly with `instanceof` checks at the boundary, and each branch is type-safe within itself.

Add a new method to `app/Services/ReportingService.php` that demonstrates the pattern.

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

The method takes `object` rather than any specific interface because it explicitly probes for capabilities. This is the right place for runtime type checks: a small, clearly delimited boundary where heterogeneous reports converge into a single processing pipeline. Inside each `if` branch, PHP's flow-sensitive type narrowing knows the report supports the corresponding interface, so calling its method is type-safe.

This pattern (small narrow interfaces plus `instanceof` at the consumer boundary) replaces the fat interface plus try/catch antipattern. The two designs solve the same problem, but one of them is honest at compile time and the other is honest only at runtime.

## Step 11: Update Tests for the New Service Shape {#step-11-update-tests-for-the-new-service-shape}

The existing tests still pass because the public behavior of each report is preserved. We add one more test to demonstrate the new `processAvailable` boundary method, which proves that capability detection works correctly.

Open `tests/Feature/ReportingTest.php` and append the following test at the bottom of the file.

```php
it('processes only the capabilities each report supports', function () {
    Storage::fake('local');

    $service = app(ReportingService::class);

    $simple    = $service->processAvailable(new SimpleSalesReport());
    $compliance = $service->processAvailable(new ComplianceReport());
    $export    = $service->processAvailable(new DataExportReport());

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

## Step 12: Run All Tests Again {#step-12-run-all-tests-again}

Run the full test suite. The original five reporting tests still pass, and the new capability-detection test passes too.

```bash
php artisan test
```

Your output should look like this.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

   PASS  Tests\Feature\ReportingTest
  ✓ it renders a PDF for the simple sales report                                                                                                                                                       0.04s
  ✓ it renders a PDF for the compliance report and signs it                                                                                                                                            0.03s
  ✓ it exports CSV for the data export report                                                                                                                                                          0.02s
  ✓ it archives the data export report to a storage URL                                                                                                                                                0.03s
  ✓ it schedules the data export report on a daily cadence                                                                                                                                             0.02s
  ✓ it processes only the capabilities each report supports                                                                                                                                            0.04s

  Tests:    8 passed (29 assertions)
  Duration: 0.46s
```

Eight tests, all green. Compared to the baseline, we added one new test (capability detection) and preserved the behavior of every existing test. The old reporting code with its eighteen forced method declarations and runtime exceptions is gone, replaced by classes that only declare what they truly do.

## Understanding Interface Segregation Principle {#understanding-interface-segregation-principle}

The Interface Segregation Principle says that no client should be forced to depend on methods it does not use. Stated as a positive: prefer many small focused interfaces over a few large general-purpose ones.

The clearest signal you have crossed the line into a fat interface is the `BadMethodCallException` antipattern. Concrete classes that throw "this method is not supported" at runtime are advertising themselves as something they are not. Type checkers cannot help, code review cannot reliably help, and the only place the lie surfaces is production. Every time you see a stub method that throws, treat it as a hint that the interface should be split.

A second signal is the empty implementation. A method body that just `return null` or `// no-op` is even more dangerous than the `BadMethodCallException` version, because it pretends to succeed. Callers continue as if the method worked, and the silent failure compounds. ISP says: do not put yourself in a position where you have to choose between throwing and silently doing nothing.

A third signal is consumer code that has many `instanceof` checks against unrelated facets of the same interface. If `ReportingService` had to do `if ($report->canDoExcel())` and `if ($report->canDoSigning())` everywhere, the interface is asking the consumer to encode capability detection that the type system should have handled. Capability interfaces move that detection into the type system.

The conceptual shift ISP asks for is from "what is this object" to "what can this object do". The fat `ReportInterface` modeled a category called "report". The capability interfaces (`PdfReportable`, `Schedulable`, `Signable`) model abilities. A class can have many abilities; trying to fit those abilities into a single category contract forces lies. Designing around abilities makes the contracts precise and lets each class declare exactly the ones it has.

## Why Laravel's Contracts Directory Is the Canonical ISP Example {#why-laravels-contracts-directory-is-the-canonical-isp-example}

The Laravel framework's `Illuminate\Contracts` namespace is one of the cleanest applications of ISP in any major PHP codebase, and reading it is genuinely educational. Look at the cache contracts as an example. There is `Cache\Repository` for the operations a single cache store supports (`get`, `put`, `forever`, `remember`). There is `Cache\Lock` for atomic locking primitives. There is `Cache\Store` for the lower-level key-value contract. There is `Cache\Factory` for resolving named cache stores out of configuration. Four interfaces, each with a focused purpose, instead of one bloated `Cache` interface trying to cover everything.

The same pattern applies to filesystem contracts (`Filesystem`, `Cloud`, `Factory`), notification contracts (`Channel`, `Factory`, `Dispatcher`), bus contracts (`Dispatcher`, `QueueingDispatcher`, `BatchRepository`), and many others. Each subsystem is decomposed into the smallest contracts that callers can depend on without overcommitting.

The practical lesson for your own code: when you start designing a new contract, ask whether it is a single capability or a bag of unrelated capabilities. If it is a bag, decompose it. The decomposition costs you a few extra files and pays you back in honesty: every implementation declares exactly the capabilities it has, every consumer asks for exactly the capabilities it needs, and the type system enforces the rest.

A second lesson is that ISP and OCP work hand in hand. The capability interfaces in this article are open for extension (you can add a new report by writing a new class with whatever capability mix it needs) and closed for modification (existing reports do not change when new capabilities are introduced; they simply do not implement the new interface). Splitting the fat interface did not just satisfy ISP; it also strengthened OCP, because adding a new capability to the system is purely additive now.

## Common ISP Pitfalls {#common-isp-pitfalls}

The most frequent failure mode is over-segregation. If you split every method onto its own interface, you end up with a codebase where every concrete class implements ten interfaces and every consumer accepts a complicated intersection type. That is ISP applied as a rule rather than a tool. The right grain is "capability", which is usually one to three closely related methods, not "single method".

A second pitfall is interface naming. Names like `IUserService` or `ReportableInterface` (with the suffix) tell you what kind of thing the interface is, not what it does. Capability-oriented names (`PdfReportable`, `Schedulable`, `Archivable`) tell you what an implementer promises. Capability names also read better at the consumer side; `function process(Schedulable $job)` reads more clearly than `function process(IJobInterface $job)`.

A third pitfall is interface inheritance. PHP allows interfaces to extend other interfaces, and it is tempting to recreate the fat interface as a "convenience" interface that extends all six capabilities. That convenience is almost always a bad trade. It reintroduces the original problem (classes that implement the convenience interface are forced to declare every method) for marginal typing convenience. If you really need a "full report" type, an intersection type at the type-hint level is cleaner: `function fullProcess(PdfReportable & Schedulable & Archivable $report)` makes the requirement explicit without forcing every concrete report to implement everything.

A fourth pitfall is depending on capability interfaces in places that should depend on the concrete class. ISP is about consumers depending on the smallest contract they need. If a method genuinely uses three concrete features of one specific report class, accept the concrete class. ISP is not "always use interfaces"; it is "do not force consumers to depend on more interface surface than they actually use".

## Conclusion {#conclusion}

The Interface Segregation Principle is the SOLID principle that prevents a category of bugs entirely. Where SRP, OCP, and LSP each ask you to be careful, ISP lets you ask the type system to be careful for you. A class that implements only the interfaces matching its real capabilities cannot be passed to consumers that need more capability, because the compiler will refuse the call.

Here are the key takeaways from this refactor to carry forward:

- **The `BadMethodCallException` antipattern is the smell.** Any time a concrete class throws "method not supported" from a method it was forced to declare, the interface is too fat. Split the interface and let the class drop the method entirely.
- **Capabilities, not categories.** Name interfaces after what an object can do (`Schedulable`, `Archivable`, `PdfReportable`), not after what kind of thing it is. Capability names compose; category names do not.
- **Each interface should have one tightly focused purpose.** One method is fine if that captures the capability. Three closely related methods is also fine. Six unrelated methods is a fat interface waiting to be split.
- **Consumers depend on the smallest interface they use.** The reporting service in this article asks for `PdfReportable` when it only needs to call `generatePdf`, not for a full `Report` type. The compiler enforces correctness automatically.
- **Use `instanceof` at the boundary for optional capabilities.** A processing pipeline that handles heterogeneous reports can probe for capability with `instanceof`, and PHP's flow-sensitive typing makes each branch safe. This replaces the fat interface plus try/catch antipattern.
- **Laravel's `Contracts` directory is the canonical example.** Read it. The cache, filesystem, queue, and notification contracts each show how the framework decomposes responsibilities into focused interfaces.
- **ISP and OCP reinforce each other.** Adding a new capability to the system becomes purely additive: a new interface, optionally a new report implementing it. No existing class needs to be opened.

In Article 6 we will close the series with the Dependency Inversion Principle by refactoring a tightly coupled newsletter subscription controller. We will untangle DIP from dependency injection and inversion of control, build a `NewsletterProvider` contract, swap implementations in a service provider, and write tests that run without ever touching a real third-party API. The Laravel service container will finally take its place as the explicit DIP infrastructure it was always meant to be.
