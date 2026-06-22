# Processing Huge CSV Files in PHP with Generators: Millions of Rows Without Running Out of Memory

Reading a CSV file in PHP looks harmless when the file has 50 rows. You call `file()`, loop over the result, and move on. The problem appears later, when the same script receives a customer export, payment report, or analytics dump with hundreds of thousands of rows. Suddenly the script needs to hold the whole file in memory before it can process the first useful row.

That is how a simple import job turns into a memory problem. The file keeps growing, the worker crashes, and increasing `memory_limit` only delays the next crash. A better fix is to stop loading the whole CSV at once. In this tutorial, you will process a large CSV file with native PHP generators, `fgetcsv()`, and a streaming pipeline that reads, transforms, and writes one row at a time.

## Overview {#overview}

We will build a small command-line PHP project without Laravel, Composer, a database, or any framework. The goal is to make the memory behavior visible. First, we will create a large synthetic CSV file. Then we will read it with a naive approach, compare it with a generator-based reader, and finish by writing a cleaned CSV file without keeping every row in an array.

### What You'll Build

- A native PHP command-line project for processing CSV files.
- A script that generates a large `sales.csv` test file.
- A naive CSV reader that shows why `file()` is risky for large files.
- A reusable generator-based CSV reader.
- A streaming sales processor that calculates totals and region counts.
- A streaming exporter that writes a cleaned CSV file row by row.

### What You'll Learn

- Why `file()` can exhaust memory when a CSV file grows.
- How PHP generators use `yield` to provide lazy rows to `foreach`.
- How to combine `fopen()`, `fgetcsv()`, and `finally` for safe file handling.
- How to measure peak memory with `memory_get_peak_usage(true)`.
- How to write transformed CSV output with `fputcsv()` without building a giant array.

### What You'll Need

- PHP 8.3 or newer.
- A terminal.
- Basic knowledge of PHP functions, arrays, and `foreach`.
- No Laravel setup. This tutorial does not use `php artisan`, models, migrations, controllers, or routes.

## Step 1: Create the Project Folder {#step-1-create-the-project-folder}

Start with an empty folder. We will keep generated CSV files inside `data/` and transformed output inside `output/`. These folders are created first because the scripts in later steps will write files into them.

Run these commands:

```bash
mkdir huge-csv-generators
cd huge-csv-generators
mkdir data output
php -v
```

On my machine, PHP is available as a CLI command:

```text
PHP 8.5.4 (cli) (built: May 25 2026 12:19:37) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.4, Copyright (c) Zend Technologies
    with Xdebug v3.5.0, Copyright (c) 2002-2025, by Derick Rethans
    with Zend OPcache v8.5.4, Copyright (c), by Zend Technologies
```

Your version string may be different. The important part is that you are using PHP 8.3 or newer.

## Step 2: Generate a Large CSV File {#step-2-generate-a-large-csv-file}

Before processing a huge CSV, we need a repeatable CSV file for testing. Create a new file named `generate_csv.php`. This file writes predictable sales rows to `data/sales.csv`, which lets us test the same processing scripts again and again.

Create `generate_csv.php`:

```php
<?php

declare(strict_types=1);

$rows = (int) ($argv[1] ?? 100000);
$path = __DIR__ . '/data/sales.csv';

if ($rows < 1) {
    fwrite(STDERR, "Row count must be at least 1.\n");
    exit(1);
}

$startedAt = microtime(true);
$handle = fopen($path, 'w');

if ($handle === false) {
    fwrite(STDERR, "Cannot open {$path} for writing.\n");
    exit(1);
}

fputcsv($handle, ['order_id', 'customer_email', 'region', 'total', 'ordered_at'], ',', '"', '');

$regions = ['north', 'south', 'east', 'west'];
$baseTimestamp = strtotime('2026-01-01 09:00:00');

for ($i = 1; $i <= $rows; $i++) {
    $region = $regions[$i % count($regions)];
    $total = number_format((($i % 5000) + 100) / 10, 2, '.', '');
    $orderedAt = date('Y-m-d H:i:s', $baseTimestamp + ($i * 60));

    fputcsv(
        $handle,
        [
            $i,
            "customer{$i}@example.com",
            $region,
            $total,
            $orderedAt,
        ],
        ',',
        '"',
        ''
    );
}

fclose($handle);

$elapsed = microtime(true) - $startedAt;
$fileSize = filesize($path);

printf("Generated rows: %s\n", number_format($rows));
printf("CSV path: %s\n", $path);
printf("File size: %s MB\n", number_format($fileSize / 1024 / 1024, 2));
printf("Elapsed time: %.2f seconds\n", $elapsed);
printf("Peak memory: %s MB\n", number_format(memory_get_peak_usage(true) / 1024 / 1024, 2));
```

This script uses `fputcsv()` instead of manual string concatenation. CSV has edge cases like quoted values, commas inside fields, and escaping rules, so it is better to let PHP format each row. The last argument, `''`, disables PHP's proprietary escape mechanism. This is intentional because PHP 8.4 deprecates relying on the default CSV escape value, and the PHP manual recommends passing it explicitly.

Now generate 100,000 rows:

```bash
php generate_csv.php 100000
```

You should see output similar to this:

```text
Generated rows: 100,000
CSV path: /home/gun-gun-priatna/obsidian-vault/sandbox/huge-csv-generators/data/sales.csv
File size: 6.30 MB
Elapsed time: 0.38 seconds
Peak memory: 2.00 MB
```

The exact path and elapsed time will be different on your machine. The important signal is the peak memory. Writing rows one at a time keeps memory low even while creating a large file.

## Step 3: Show the Memory Problem with a Naive Reader {#step-3-show-the-memory-problem-with-a-naive-reader}

Now we will intentionally create a reader that does the wrong thing for large CSV files. This file exists to give us a baseline. It uses `file()`, which reads the entire file into an array before our code can process the rows.

Create `read_naive.php`:

```php
<?php

declare(strict_types=1);

$path = __DIR__ . '/data/sales.csv';
$startedAt = microtime(true);

$lines = file($path);

if ($lines === false) {
    fwrite(STDERR, "Cannot read {$path}.\n");
    exit(1);
}

$rowCount = max(count($lines) - 1, 0);
$elapsed = microtime(true) - $startedAt;

printf("Rows counted: %s\n", number_format($rowCount));
printf("Elapsed time: %.2f seconds\n", $elapsed);
printf("Peak memory: %s MB\n", number_format(memory_get_peak_usage(true) / 1024 / 1024, 2));
```

Run the naive reader:

```bash
php read_naive.php
```

Output from the 100,000-row CSV:

```text
Rows counted: 100,000
Elapsed time: 0.01 seconds
Peak memory: 18.31 MB
```

For a 6.30 MB CSV file, 18.31 MB of peak memory may not look terrible yet. But this is the pattern that fails when the file becomes 600 MB or 2 GB. The memory usage grows because `$lines` holds the whole file.

You can make the problem visible by lowering the memory limit:

```bash
php -d memory_limit=16M read_naive.php
```

Output:

```text
PHP Fatal error:  Allowed memory size of 16777216 bytes exhausted (tried to allocate 2097160 bytes) in /home/gun-gun-priatna/obsidian-vault/sandbox/huge-csv-generators/read_naive.php on line 8
Stack trace:
#0 /home/gun-gun-priatna/obsidian-vault/sandbox/huge-csv-generators/read_naive.php(8): file()
#1 {main}
```

The script fails at `file($path)` because PHP has to allocate a large array of lines. We have not even parsed the CSV fields yet.

## Step 4: Build a Generator-Based CSV Reader {#step-4-build-a-generator-based-csv-reader}

Next, create the reusable reader that the rest of the tutorial will use. This file opens the CSV, reads the header, then yields one associative array per data row. The caller can loop over it with `foreach`, but PHP does not need to keep every row in memory.

Create `CsvReader.php`:

```php
<?php

declare(strict_types=1);

/**
 * @return Generator<int, array<string, string>>
 */
function readCsvRows(string $path): Generator
{
    $handle = fopen($path, 'r');

    if ($handle === false) {
        throw new RuntimeException("Cannot open {$path} for reading.");
    }

    try {
        $header = fgetcsv($handle, null, ',', '"', '');

        if ($header === false || $header === [null]) {
            throw new RuntimeException('The CSV file is empty or missing a header row.');
        }

        while (($row = fgetcsv($handle, null, ',', '"', '')) !== false) {
            if ($row === [null]) {
                continue;
            }

            if (count($row) !== count($header)) {
                throw new RuntimeException('A CSV row does not match the header column count.');
            }

            yield array_combine($header, $row);
        }
    } finally {
        fclose($handle);
    }
}
```

The `yield` line is the key. When a function contains `yield`, PHP returns a `Generator` object. The caller receives one row at a time as the loop advances. The function pauses after each `yield`, then resumes when the next row is requested.

The `finally` block is also important. It closes the file handle even if the caller breaks out of the loop early or an exception is thrown during processing.

## Step 5: Process Rows Without Keeping Them {#step-5-process-rows-without-keeping-them}

Now we can build the real processing script. This file requires `CsvReader.php`, loops over the generator, and calculates simple sales metrics. It never stores all rows. It only keeps counters and totals.

Create `process_sales.php`:

```php
<?php

declare(strict_types=1);

require __DIR__ . '/CsvReader.php';

$path = __DIR__ . '/data/sales.csv';
$startedAt = microtime(true);
$rowCount = 0;
$totalRevenue = 0.0;
$ordersByRegion = [];

foreach (readCsvRows($path) as $row) {
    $rowCount++;
    $totalRevenue += (float) $row['total'];

    $region = $row['region'];
    $ordersByRegion[$region] = ($ordersByRegion[$region] ?? 0) + 1;
}

ksort($ordersByRegion);

printf("Rows processed: %s\n", number_format($rowCount));
printf("Total revenue: %s\n", number_format($totalRevenue, 2));

foreach ($ordersByRegion as $region => $count) {
    printf("Orders in %s: %s\n", $region, number_format($count));
}

printf("Elapsed time: %.2f seconds\n", microtime(true) - $startedAt);
printf("Peak memory: %s MB\n", number_format(memory_get_peak_usage(true) / 1024 / 1024, 2));
```

Run it:

```bash
php process_sales.php
```

Output:

```text
Rows processed: 100,000
Total revenue: 25,995,000.00
Orders in east: 25,000
Orders in north: 25,000
Orders in south: 25,000
Orders in west: 25,000
Elapsed time: 0.65 seconds
Peak memory: 2.00 MB
```

The peak memory is much lower than the naive reader because each row is handled and then discarded. The script keeps only `$rowCount`, `$totalRevenue`, and `$ordersByRegion`.

Now run the same streaming processor with a 16 MB memory limit:

```bash
php -d memory_limit=16M process_sales.php
```

Output:

```text
Rows processed: 100,000
Total revenue: 25,995,000.00
Orders in east: 25,000
Orders in north: 25,000
Orders in south: 25,000
Orders in west: 25,000
Elapsed time: 0.48 seconds
Peak memory: 2.00 MB
```

This is the practical difference. The naive reader failed because it loaded the whole file. The generator-based reader succeeds because it streams the file.

## Step 6: Write a Streaming CSV Transformer {#step-6-write-a-streaming-csv-transformer}

Processing often means more than counting rows. Sometimes you need to create a cleaned file for another system. The safe pattern is the same: read one row, transform one row, write one row.

Create `export_clean_sales.php`:

```php
<?php

declare(strict_types=1);

require __DIR__ . '/CsvReader.php';

$sourcePath = __DIR__ . '/data/sales.csv';
$targetPath = __DIR__ . '/output/clean-sales.csv';
$startedAt = microtime(true);
$processed = 0;

$target = fopen($targetPath, 'w');

if ($target === false) {
    fwrite(STDERR, "Cannot open {$targetPath} for writing.\n");
    exit(1);
}

try {
    fputcsv($target, ['order_id', 'region', 'total_cents', 'ordered_date'], ',', '"', '');

    foreach (readCsvRows($sourcePath) as $row) {
        $processed++;

        fputcsv(
            $target,
            [
                $row['order_id'],
                strtoupper($row['region']),
                (string) ((int) round(((float) $row['total']) * 100)),
                substr($row['ordered_at'], 0, 10),
            ],
            ',',
            '"',
            ''
        );
    }
} finally {
    fclose($target);
}

printf("Rows exported: %s\n", number_format($processed));
printf("Output path: %s\n", $targetPath);
printf("Elapsed time: %.2f seconds\n", microtime(true) - $startedAt);
printf("Peak memory: %s MB\n", number_format(memory_get_peak_usage(true) / 1024 / 1024, 2));
```

This script creates `output/clean-sales.csv`. It converts `region` to uppercase, converts a decimal total into cents, and keeps only the date part from `ordered_at`.

Run it:

```bash
php export_clean_sales.php
```

Output:

```text
Rows exported: 100,000
Output path: /home/gun-gun-priatna/obsidian-vault/sandbox/huge-csv-generators/output/clean-sales.csv
Elapsed time: 0.96 seconds
Peak memory: 2.00 MB
```

Verify the output row count:

```bash
php -r "echo count(file('output/clean-sales.csv')) . PHP_EOL;"
```

Output:

```text
100001
```

The output contains 100,001 lines because it has one header row and 100,000 data rows. This quick check uses `file()` only for a small verification command. In a real large-file pipeline, keep using streaming reads.

## Step 7: Try It Out with More Rows {#step-7-try-it-out-with-more-rows}

The 100,000-row file is good for learning because it runs quickly. To see why generators matter in a more realistic scenario, generate one million rows.

Run:

```bash
php generate_csv.php 1000000
php process_sales.php
php export_clean_sales.php
```

You should see the row count increase while peak memory stays low. The file size and elapsed time will grow, but the generator-based scripts should not need memory proportional to the number of rows.

If your machine is small, you can also test the streaming script with a strict memory limit:

```bash
php -d memory_limit=16M process_sales.php
```

The goal is not to make the script the fastest possible importer. The goal is to make memory predictable. Once memory is stable, you can optimize database writes, add batching, or move the job into a queue.

## How PHP Generators Keep Memory Low {#how-php-generators-keep-memory-low}

PHP generators are not magic background workers. They are lazy iterators. According to the PHP manual, generators let you provide data to `foreach` without building an array in memory ahead of time. That is exactly what we need for huge CSV files.

Compare these two shapes:

```php
$rows = file($path);

foreach ($rows as $row) {
    // The full file is already in memory.
}
```

The first version reads everything before the loop starts. Now compare it with the generator reader:

```php
foreach (readCsvRows($path) as $row) {
    // One parsed row is available here.
}
```

The second version asks for one row, processes it, then asks for the next row. PHP still uses memory for the current row, the file handle, and your counters, but it does not need to keep the entire CSV file as an array.

There is one tradeoff: generators are forward-only. You cannot jump to row 500,000 or loop over the same generator twice without opening the file again. For import and export jobs, that is usually fine because the natural shape is already forward-only.

## CSV Edge Cases You Should Handle {#csv-edge-cases-you-should-handle}

CSV looks simple until real files arrive from different tools. A production importer should be explicit about parsing rules and validation.

Use `fgetcsv()` instead of `explode(',', $line)`. A valid CSV field can contain a comma when the field is quoted. Manual splitting will break that row, while `fgetcsv()` understands CSV field boundaries.

Pass the CSV escape argument explicitly:

```php
fgetcsv($handle, null, ',', '"', '');
```

The empty string disables PHP's proprietary escape mechanism. The PHP manual notes that relying on the default escape value is deprecated as of PHP 8.4, and the default will change no earlier than PHP 9.0.

Validate the header row before processing. In this tutorial, `CsvReader.php` throws an exception when the file is empty or the row column count does not match the header count. That gives you a clear failure instead of quietly importing broken data.

Decide how to handle rejected rows. For a real importer, you might write invalid rows to `output/rejected-sales.csv` with an error reason, then continue processing the rest of the file.

## When to Move Beyond a Simple Script {#when-to-move-beyond-a-simple-script}

This tutorial uses native PHP scripts so the generator pattern is easy to see. The same idea applies inside larger applications.

If the CSV import writes to a database, avoid one insert per row for millions of rows. Read rows lazily, collect a small batch such as 500 or 1,000 rows, insert the batch, then clear the batch array. That keeps memory bounded while reducing database overhead.

If the import runs from a web request, move it to a queue or a CLI command. A web request can time out even when memory usage is low. Long-running file processing belongs in a worker process where you can track progress, retry failures, and log rejected rows.

If you use Laravel later, `LazyCollection` gives you a framework-friendly way to work with lazy streams. It does not replace understanding generators. It builds on the same idea: avoid materializing every item unless you truly need every item in memory.

## References {#references}

The implementation in this tutorial is based on native PHP behavior documented in the PHP manual:

- [Generators overview](https://www.php.net/manual/en/language.generators.overview.php)
- [file()](https://www.php.net/manual/en/function.file.php)
- [fgetcsv()](https://www.php.net/manual/en/function.fgetcsv.php)
- [fputcsv()](https://www.php.net/manual/en/function.fputcsv.php)
- [memory_get_peak_usage()](https://www.php.net/manual/en/function.memory-get-peak-usage.php)

## Conclusion {#conclusion}

Large CSV processing becomes manageable when your script stops treating the file as one giant value. With generators, each row can move through the pipeline independently.

- **Generators stream data.** They let PHP produce one row at a time instead of building a giant array first.
- **CSV parsing needs CSV tools.** `fgetcsv()` handles quoted fields and commas inside values better than manual string splitting.
- **Memory must be measured.** `memory_get_peak_usage(true)` makes the difference between the naive and streaming versions visible.
- **Pipelines stay simple.** Read one row, transform one row, write one row, then move on.
- **Native PHP is enough.** You do not need a framework to process huge files safely, although the same pattern works well inside framework jobs and commands.
