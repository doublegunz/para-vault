# PHP 8.6 Released: What's New and Changed

A new PHP release is easy to ignore until a dependency starts requiring it or a deprecation notice floods the logs on a staging server. PHP 8.6.0 was released on November 19, 2026, and it brings more than a few small helpers: partial function application changes how callbacks are written, readonly properties finally accept default values, and the session extension now ships with stricter defaults that can change how an existing app behaves. Teams that read the changes now can adopt the new features on their own schedule instead of discovering them in a failed deployment. This article walks through what actually shipped in PHP 8.6, with examples tested on PHP 8.6.0.

## Overview {#overview}

This article was first written before the release, when several features were still proposals. It has been revised against the official release page[^1], the migration guide, and the RFC list, so everything below reflects what PHP 8.6.0 actually contains. Every code example was run on PHP 8.6.0, and the output shown in the comments comes from those runs.

### What You'll Build

- A set of small PHP scripts, one per feature, that you can run with the PHP 8.6 CLI.
- A quick checklist of backward incompatible changes and deprecations to review before upgrading.

### What You'll Learn

- The release date of PHP 8.6 and how long each supported PHP version receives updates.
- How to use partial function application, `clamp()`, the `SortDirection` enum, and readonly property defaults.
- What the new `Time\Duration` class and the `Io\Poll` polling API do.
- Which behavior changes and deprecations in PHP 8.6 can affect existing code.
- Which proposals did not make it into PHP 8.6.

### What You'll Need

- PHP 8.6 CLI. On Ubuntu 26.04 you can follow [How to Install PHP 8.6 on Ubuntu 26.04 from packages.sury.org](https://qadrlabs.com/post/install-php-86-from-sury-repository-on-ubuntu-2604).
- The `intl` extension for the `grapheme_strrev()` example.
- Basic knowledge of PHP functions, closures, classes, and enums.

To run any example, save it to a file such as `example.php` and run `php example.php` in the terminal.

## Release Date and Support Timeline {#release-date}

PHP 8.6.0 was announced on php.net on November 19, 2026, on the same day as security releases for the older branches (8.2.36, 8.3.37, 8.4.28, and 8.5.13). Each PHP branch receives two years of active support followed by security fixes only, and support periods now end on December 31 of the given year. Here is the current timeline from the official supported versions page[^2]:

| Version | Initial Release | Active Support Until | Security Fixes Until |
|---------|-----------------|----------------------|----------------------|
| 8.2     | Dec 8, 2022     | Dec 31, 2024         | Dec 31, 2026         |
| 8.3     | Nov 23, 2023    | Dec 31, 2025         | Dec 31, 2027         |
| 8.4     | Nov 21, 2024    | Dec 31, 2026         | Dec 31, 2028         |
| 8.5     | Nov 20, 2025    | Dec 31, 2027         | Dec 31, 2029         |
| **8.6** | **Nov 19, 2026**| **Dec 31, 2028**     | **Dec 31, 2030**     |

PHP 8.2 reaches end of life on December 31, 2026, so projects still running it should plan an upgrade now. Moving to 8.5 or 8.6 gives the longest runway.

## Headline Features {#headline-features}

The release page highlights a handful of features that change how everyday PHP code is written. Each one below comes with a runnable example and its real output on PHP 8.6.0.

### Partial Function Application {#partial-function-application}

Partial Function Application (PFA) is the biggest language change in PHP 8.6[^3]. When a function call contains the `?` placeholder, PHP does not call the function. It returns a `Closure` that waits for the missing argument. The `...` placeholder leaves all remaining arguments open.

```php
<?php

function add(int $a, int $b): int
{
    return $a + $b;
}

// Lock in the first argument, leave the second open with "?".
$addTen = add(10, ?);

echo $addTen(5), PHP_EOL;  // 15
echo $addTen(20), PHP_EOL; // 30

// "?" can sit at any position, including the first.
$versions = ['8.4.1', '8.5.12', '8.6.0', '8.3.20'];
$modern = array_filter($versions, version_compare(?, '8.5', '>='));
print_r($modern);

// "..." leaves all remaining arguments open.
function logMessage(string $level, string $context, string $message): string
{
    return "[$level][$context] $message";
}

$errorLog = logMessage('ERROR', ...);
echo $errorLog('auth', 'Invalid token received'), PHP_EOL;

var_dump($addTen instanceof Closure);
```

Output:

```
15
30
Array
(
    [1] => 8.5.12
    [2] => 8.6.0
)
[ERROR][auth] Invalid token received
bool(true)
```

`add(10, ?)` creates a closure that only needs `$b`. The `version_compare(?, '8.5', '>=')` call is the most practical pattern: the placeholder sits in the first position, so `array_filter()` passes each version string into it without a wrapper like `fn($v) => version_compare($v, '8.5', '>=')`. `logMessage('ERROR', ...)` fixes the level and leaves both `$context` and `$message` open. The final `var_dump()` confirms that the result is an ordinary `Closure`, so it works anywhere a callable is accepted.

### New `clamp()` Function {#clamp-function}

`clamp()` keeps a value between a lower and an upper bound[^4]. It replaces the nested `min(max($value, $min), $max)` pattern, which is easy to write with the arguments in the wrong order.

```php
<?php

var_dump(clamp(50, 0, 100));    // within range
var_dump(clamp(-10, 0, 100));   // below min
var_dump(clamp(150, 0, 100));   // above max
var_dump(clamp(1.75, 0.0, 1.0)); // floats

try {
    clamp(5, 10, 0); // min greater than max
} catch (ValueError $e) {
    echo get_class($e), ': ', $e->getMessage(), PHP_EOL;
}
```

Output:

```
int(50)
int(0)
int(100)
float(1)
ValueError: clamp(): Argument #2 ($min) must be smaller than or equal to argument #3 ($max)
```

A value inside the range is returned unchanged, a value below `$min` becomes `$min`, and a value above `$max` becomes `$max`. It works with both integers and floats. The last call shows a safety check the old `min()`/`max()` pattern never had: if the bounds are swapped, `clamp()` throws a `ValueError` instead of silently returning a wrong number.

### New `SortDirection` Enum {#sort-direction-enum}

PHP 8.6 adds a global `SortDirection` enum with two cases, `Ascending` and `Descending`[^5]. It is a pure enum (it has no backing value), so it is meant to be used as a type in function and method signatures. Frameworks and libraries can accept a `SortDirection` parameter instead of a loose `'asc'`/`'desc'` string.

```php
<?php

function sortNames(array $names, SortDirection $direction): array
{
    usort($names, function (string $a, string $b) use ($direction): int {
        $result = $a <=> $b;

        return $direction === SortDirection::Descending ? -$result : $result;
    });

    return $names;
}

$names = ['Charlie', 'Alice', 'Bob'];

echo implode(', ', sortNames($names, SortDirection::Ascending)), PHP_EOL;
echo implode(', ', sortNames($names, SortDirection::Descending)), PHP_EOL;

var_dump(SortDirection::cases());
```

Output:

```
Alice, Bob, Charlie
Charlie, Bob, Alice
array(2) {
  [0]=>
  enum(SortDirection::Ascending)
  [1]=>
  enum(SortDirection::Descending)
}
```

The `sortNames()` signature documents itself: callers must pass one of the two cases, and a typo like `'dsc'` is rejected with a `TypeError` before the function body runs. The existing sort functions and the `SORT_ASC`/`SORT_DESC` constants are unchanged; the enum is a shared type for userland code.

### Readonly Property Defaults {#readonly-property-defaults}

Before PHP 8.6, a readonly property could not have a default value, so a fixed setting had to be assigned in the constructor. PHP 8.6 allows a default value on readonly properties[^6].

```php
<?php

final class HttpClientConfig
{
    public function __construct(
        public readonly string $baseUrl,
    ) {
    }

    // New in PHP 8.6: a readonly property can declare a default value.
    public readonly int $timeout = 30;
}

$config = new HttpClientConfig('https://api.example.com');

echo $config->baseUrl, PHP_EOL;
echo $config->timeout, PHP_EOL;

try {
    $config->timeout = 60;
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), PHP_EOL;
}
```

Output:

```
https://api.example.com
30
Error: Cannot modify readonly property HttpClientConfig::$timeout
```

`$timeout` starts at `30` without any constructor code, and it is still readonly: the attempt to change it throws an `Error`. On PHP 8.5, the line `public readonly int $timeout = 30;` is a compile error, so this is also a quick way to tell which version a codebase requires.

### `Time\Duration` Class {#duration-class}

`Time\Duration` is a new immutable value object for lengths of time with nanosecond precision[^7]. It removes the guesswork of passing bare integers around and wondering whether they mean seconds or milliseconds.

```php
<?php

use Time\Duration;

$timeout = Duration::fromSeconds(30);
$retryDelay = Duration::fromMilliseconds(1500);

// Durations are immutable value objects; arithmetic returns a new instance.
$total = $timeout->add($retryDelay->multiplyBy(3));

echo $total->seconds, ' s ', $total->nanoseconds, ' ns', PHP_EOL;

// compare() returns -1, 0, or 1.
var_dump(Duration::compare($timeout, $retryDelay));

$fromIso = Duration::fromIso8601DurationString('PT1M30S');
echo $fromIso->seconds, PHP_EOL;
```

Output:

```
34 s 500000000 ns
int(1)
90
```

Named constructors (`fromSeconds()`, `fromMilliseconds()`, `fromMinutes()`, `fromHours()`, and more) make the unit explicit at the call site. Methods like `add()` and `multiplyBy()` return a new instance, so the original values never change. The result is stored as whole seconds plus nanoseconds: 30 seconds plus three times 1.5 seconds is 34.5 seconds. `fromIso8601DurationString()` parses ISO 8601 strings such as `PT1M30S`, which is 90 seconds.

### Polling API (`Io\Poll`) {#polling-api}

PHP 8.6 adds a modern I/O polling API under the `Io\Poll` namespace[^8]. It uses the best mechanism the operating system offers (epoll on Linux, kqueue on BSD and macOS, event ports, or WSAPoll on Windows) and is designed as a scalable replacement for `stream_select()` in servers, workers, and event loops.

```php
<?php

use Io\Poll\Context;
use Io\Poll\Event;
use Time\Duration;

// A pair of connected sockets stands in for a real client connection.
[$left, $right] = stream_socket_pair(STREAM_PF_UNIX, STREAM_SOCK_STREAM, STREAM_IPPROTO_IP);

$poll = new Context();
echo 'Backend: ', $poll->getBackend()->name, PHP_EOL;

$poll->add(new StreamPollHandle($right), [Event::Read], 'right-socket');

// Nothing has been written yet, so the wait times out with no events.
var_dump(count($poll->wait(Duration::fromMilliseconds(100))));

fwrite($left, "ping\n");

foreach ($poll->wait(Duration::fromSeconds(1)) as $watcher) {
    if ($watcher->hasTriggered(Event::Read)) {
        echo $watcher->getData(), ' received: ', fgets($watcher->getHandle()->getStream());
    }
}
```

Output (on Linux):

```
Backend: Epoll
int(0)
right-socket received: ping
```

`stream_socket_pair()` creates two connected sockets, so the example runs without a network server. `Context` picks a backend automatically, which is `Epoll` on Linux. `add()` registers the `$right` socket for `Event::Read` and attaches a label as user data. The first `wait()` returns an empty array after 100 milliseconds because nothing has been written. After writing `ping` to `$left`, the second `wait()` returns a watcher for `$right`, and `hasTriggered()` confirms it is readable. Note that `wait()` takes a `Time\Duration` as its timeout, so the two new APIs are designed to work together.

### JSON Error Messages With Location {#json-error-location}

When `json_decode()` fails, the error message now includes the line and column where parsing stopped[^9]. This applies to both `json_last_error_msg()` and the message of a `JsonException`.

```php
<?php

$invalidJson = '{"name": "Alice", "scores": [10, 20, 30}';

json_decode($invalidJson);
echo json_last_error_msg(), PHP_EOL;

try {
    json_decode($invalidJson, flags: JSON_THROW_ON_ERROR);
} catch (JsonException $e) {
    echo $e->getMessage(), PHP_EOL;
}
```

Output:

```
State mismatch (invalid or malformed JSON) near location 1:40
State mismatch (invalid or malformed JSON) near location 1:40
```

The JSON string closes the array with `}` instead of `]`. On PHP 8.5 the message is only `State mismatch (invalid or malformed JSON)`. On PHP 8.6 it adds `near location 1:40`, meaning line 1, column 40, which is exactly where the wrong bracket sits. In a large API payload this saves a lot of manual searching.

### New `grapheme_strrev()` Function {#grapheme-strrev}

`strrev()` reverses bytes, so it breaks any multibyte character. The `intl` extension now provides `grapheme_strrev()`, which reverses a string by grapheme clusters, the units a person sees as single characters[^10].

```php
<?php

$text = "Hello 👋🏽🌍";

echo strrev($text), PHP_EOL;
echo grapheme_strrev($text), PHP_EOL;
```

Output:

```
���𽏟����� olleH
🌍👋🏽 olleH
```

`strrev()` scrambles the emoji bytes into invalid characters. `grapheme_strrev()` keeps every emoji intact, including the waving hand with its skin tone modifier, which is two Unicode code points that must stay together.

## Other Notable Additions {#other-additions}

Beyond the headline features, the migration guide[^11] lists many smaller improvements. These are the ones most likely to matter in application code:

- **`#[\Override]` on class constants.** The attribute now also checks that a constant really overrides one from a parent class or interface.
- **`__debugInfo()` on enums.** Enums can control what `var_dump()` shows.
- **DocComments on parameters.** `ReflectionParameter::getDocComment()` reads a doc comment written directly above a parameter.
- **`ReflectionProperty::isReadable()` and `isWritable()`.** Reflection can tell whether a property can be read or written from a given scope.
- **Stream error API.** New `StreamException` and `StreamErrorCode` types give structured errors for stream operations.
- **TLS session resumption.** Stream sockets support TLS session resumption, PSK, and 0-RTT.
- **Intl additions.** `IntlNumberRangeFormatter` formats number ranges, and `Locale::getDisplayKeyword()` and `Locale::getDisplayKeywordValue()` were added.
- **Function arguments in errors.** Error messages can now display the arguments of the function call that failed.

## Backward Incompatible Changes {#backward-incompatible-changes}

Most code runs on PHP 8.6 without changes, but a few behavior changes can surprise an existing application. The full list is in the official backward incompatible changes page[^12]. Two of them are easy to see on the command line:

```php
<?php

// trim() now strips the form feed character (\f) by default.
var_dump(trim("\fhello\f"));

// Secure session defaults.
var_dump(ini_get('session.use_strict_mode'));
var_dump(ini_get('session.cookie_httponly'));
var_dump(ini_get('session.cookie_samesite'));
```

Output on PHP 8.6 (run with `php -n` to ignore any `php.ini` overrides):

```
string(5) "hello"
string(1) "1"
string(1) "1"
string(3) "Lax"
```

On PHP 8.5 the same script prints `string(7)` for the trimmed string (the form feeds stay) and `0`, `0`, and an empty string for the session settings. The session change comes from the Secure Session Configuration Defaults RFC[^13]: sessions now reject uninitialized IDs, session cookies are hidden from JavaScript, and they are sent with `SameSite=Lax`. Apps that relied on reading the session cookie from JavaScript, or on cross-site requests carrying the session, need to set these values explicitly.

Other changes worth checking before upgrading:

- **New `ValueError`s.** Invalid flags passed to `array_filter()`, `array_change_key_case()`, `pathinfo()`, and `scandir()`, NUL bytes in several functions, and out-of-range values in `number_format()`, `sleep()`, `usleep()`, and `shmop_open()` now throw.
- **Imprecise base conversion.** `base_convert()`, `bindec()`, `hexdec()`, and `octdec()` emit a notice when the result loses precision.
- **`unpack()` modifiers.** `<` and `>` after a format code are now read as endianness modifiers, so a format like `"s<value"` produces the key `value`.
- **`ZipArchive` serialization.** `ZipArchive` objects can no longer be serialized.
- **`session_encode()`.** It returns an empty string for an empty session.
- **By-reference `foreach`.** Iterating by reference after array compaction can visit elements that were previously skipped.
- **`preg_grep()`.** It returns `false` on PCRE execution errors.

## Deprecations {#deprecations}

PHP 8.6 includes the accepted proposals from the PHP 8.6 deprecations RFC[^14] and several others. Deprecated code still runs, but it emits an `E_DEPRECATED` notice and is scheduled for removal in PHP 9.0. Here is how the notice looks:

```php
<?php

var_dump(is_integer(42));
var_dump(doubleval('3.14'));
```

Save it as `deprecated.php` and run it with deprecation notices switched on. The script is passed through standard input, so the notice shows `Standard input code` instead of a file path:

```bash
php -n -d error_reporting=E_ALL -d display_errors=1 < deprecated.php
```

Output on PHP 8.6:

```
Deprecated: Function is_integer() is deprecated since 8.6, use is_int() instead in Standard input code on line 3
bool(true)

Deprecated: Function doubleval() is deprecated since 8.6, use floatval() instead in Standard input code on line 4
float(3.14)
```

The notice names the replacement, so most fixes are a simple rename. The main deprecations, grouped by area, are listed in the official deprecated features page[^15]:

- **Function aliases.** `is_double()`, `is_long()`, `is_integer()`, and `doubleval()`. Use `is_float()`, `is_int()`, and `floatval()`.
- **Constructors and destructors.** Returning a value from, or using `yield` in, `__construct()` and `__destruct()`.
- **Language details.** `return` inside a `finally` block, `namespace` as a class constant name, `let` and `is` as identifiers, `_` as a constant name, a function named `readonly`, and a nullable return type on `__debugInfo()`.
- **String and locale functions.** `strcoll()`, the `SORT_LOCALE_STRING` flag, and `metaphone()`.
- **Multibyte regex.** The whole `mb_ereg*` family, `mb_split()`, `mb_regex_*`, and the `MB_ONIGURUMA_VERSION` constant, because the bundled Oniguruma library is no longer maintained. Use the `preg_*` functions with the `u` modifier instead.
- **Objects in array functions.** Passing objects to `array_walk()`, `array_walk_recursive()`, and `http_build_query()`.
- **Other functions.** The third argument of `define()`, `mysqli_get_charset()`, `mysqli_stmt_init()`, `spl_classes()`, `spl_object_hash()`, and the CSV methods of `SplFileObject`.
- **Session save handlers.** Custom handlers without `create_sid()` and `validateId()` now raise a warning.

## What Did Not Make It Into PHP 8.6 {#not-in-php-86}

The earlier version of this article listed several proposals that were still being discussed. None of them shipped in PHP 8.6.0, and according to the RFC index on November 20, 2026, they are still open:

- **`BackedEnum::values()`.** The RFC[^16] is still under discussion, so `array_map(fn ($case) => $case->value, Status::cases())` remains the way to collect enum values.
- **Namespace-scoped visibility.** The RFC[^17] for members visible only inside a namespace is still under discussion.
- **Context managers.** The original proposal was replaced by Context Managers v2[^18], which now targets PHP 8.7.
- **Native concurrency.** The Concurrency Support in the PHP Engine RFC[^19] is under discussion and also aims at the next 8.x release.
- **Fuzzy cast deprecation.** Deprecating casts like `(int) "123abc"` is proposed in a separate RFC[^20] that has not been voted on, so these casts still work silently in PHP 8.6.

The PDO `disconnect()`/`isConnected()` and stringable enum proposals mentioned in the earlier version are not part of PHP 8.6 either.

## Conclusion {#conclusion}

PHP 8.6 is a release that rewards a close read. A few features change how everyday code looks, and a few defaults change how existing apps behave.

- **Released on November 19, 2026.** PHP 8.6 gets active support until December 31, 2028 and security fixes until December 31, 2030, while PHP 8.2 reaches end of life on December 31, 2026.
- **Partial Function Application.** The `?` and `...` placeholders turn a function call into a closure, which removes most single-use wrapper closures.
- **`clamp()` and `SortDirection`.** `clamp()` replaces the error-prone `min(max())` pattern and validates its bounds, and `SortDirection` gives libraries a shared type for sort order.
- **Readonly property defaults.** Readonly properties can now declare a default value directly in the class body.
- **`Time\Duration` and `Io\Poll`.** Durations become explicit, immutable values, and the polling API brings epoll and kqueue to plain PHP code.
- **Better JSON errors.** Decoding errors now report the line and column where parsing failed.
- **Check the session defaults.** Strict mode, HttpOnly cookies, and `SameSite=Lax` are now on by default, so review apps that depended on the old values.
- **Clear deprecation notices.** Aliases like `is_integer()` and `doubleval()`, the mbregex functions, and constructor return values are deprecated ahead of PHP 9.0.

## References {#references}

[^1]: PHP 8.6 Release Announcement @ [https://www.php.net/releases/8.6/en.php](https://www.php.net/releases/8.6/en.php)
[^2]: Supported Versions @ [https://www.php.net/supported-versions.php](https://www.php.net/supported-versions.php)
[^3]: PHP RFC: Partial Function Application (v2) @ [https://wiki.php.net/rfc/partial_function_application_v2](https://wiki.php.net/rfc/partial_function_application_v2)
[^4]: PHP RFC: clamp @ [https://wiki.php.net/rfc/clamp_v2](https://wiki.php.net/rfc/clamp_v2)
[^5]: PHP RFC: enum SortDirection @ [https://wiki.php.net/rfc/sort_direction_enum](https://wiki.php.net/rfc/sort_direction_enum)
[^6]: PHP RFC: Readonly Property Defaults @ [https://wiki.php.net/rfc/readonly_property_defaults](https://wiki.php.net/rfc/readonly_property_defaults)
[^7]: PHP RFC: Duration class @ [https://wiki.php.net/rfc/duration_class](https://wiki.php.net/rfc/duration_class)
[^8]: PHP RFC: Polling API @ [https://wiki.php.net/rfc/poll_api](https://wiki.php.net/rfc/poll_api)
[^9]: PHP 8 ChangeLog, Version 8.6.0 @ [https://www.php.net/ChangeLog-8.php](https://www.php.net/ChangeLog-8.php)
[^10]: PHP RFC: grapheme_strrev: strrev for grapheme cluster @ [https://wiki.php.net/rfc/grapheme_strrev](https://wiki.php.net/rfc/grapheme_strrev)
[^11]: Migrating from PHP 8.5.x to PHP 8.6.x: New Features @ [https://www.php.net/manual/en/migration86.new-features.php](https://www.php.net/manual/en/migration86.new-features.php)
[^12]: Migrating from PHP 8.5.x to PHP 8.6.x: Backward Incompatible Changes @ [https://www.php.net/manual/en/migration86.incompatible.php](https://www.php.net/manual/en/migration86.incompatible.php)
[^13]: PHP RFC: Secure Session Configuration Defaults @ [https://wiki.php.net/rfc/session_security_defaults](https://wiki.php.net/rfc/session_security_defaults)
[^14]: PHP RFC: Deprecations for PHP 8.6 @ [https://wiki.php.net/rfc/deprecations_php_8_6](https://wiki.php.net/rfc/deprecations_php_8_6)
[^15]: Migrating from PHP 8.5.x to PHP 8.6.x: Deprecated Features @ [https://www.php.net/manual/en/migration86.deprecated.php](https://www.php.net/manual/en/migration86.deprecated.php)
[^16]: PHP RFC: Add values() Method to BackedEnum @ [https://wiki.php.net/rfc/add_values_method_to_backed_enum](https://wiki.php.net/rfc/add_values_method_to_backed_enum)
[^17]: Namespace-Scoped Visibility for Methods and Properties @ [https://wiki.php.net/rfc/namespace_visibility](https://wiki.php.net/rfc/namespace_visibility)
[^18]: PHP RFC: Context Managers v2 @ [https://wiki.php.net/rfc/context-managers-v2](https://wiki.php.net/rfc/context-managers-v2)
[^19]: PHP RFC: Concurrency Support in the PHP Engine @ [https://wiki.php.net/rfc/async_scheduler_abi](https://wiki.php.net/rfc/async_scheduler_abi)
[^20]: PHP RFC: Deprecate Fuzzy Type Casts and Allow Stringable in Strict Mode @ [https://wiki.php.net/rfc/deprecate-fuzzy-casts](https://wiki.php.net/rfc/deprecate-fuzzy-casts)
