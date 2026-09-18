# What's New in PHP 8.6

Following a new PHP release can feel like reading several different roadmaps at once. A promising RFC appears, its details change during voting, and an accepted proposal may arrive with only part of its original scope. That makes it easy to plan around syntax that will behave differently or overlook a change that affects existing applications.

PHP 8.6 brings shorter ways to create callbacks, defaults for readonly properties, a dedicated duration type, and improvements across the standard library. This article explains the notable changes through focused code snippets, then looks at compatibility and deprecations.

**Release status:** This preview reflects the official RFC pages reviewed on September 18, 2026. PHP 8.6 is scheduled for general availability on **November 19, 2026**. The date remains a target until the release is announced. [PHP 8.6 release schedule](https://wiki.php.net/todo/php86)

## PHP 8.6 at a Glance {#overview}

The changes fall into three useful groups: features that simplify everyday code, APIs for library and infrastructure developers, and compatibility changes that deserve attention during an upgrade. The snippets below illustrate those changes without requiring a sample project.

The official RFC index separates accepted proposals from implementations. This overview draws its feature selection from **Implemented > PHP 8.6**, while checking individual RFCs for amendments and implementation notes. The general Accepted list also includes work targeting other releases. [PHP RFC index](https://wiki.php.net/rfc#php_8_6)

The remaining scheduled milestones are:

| Milestone | Target date |
| --- | --- |
| Hard feature freeze | September 22, 2026 |
| Release Candidate 1 | September 24, 2026 |
| Release Candidate 2 | October 8, 2026 |
| Release Candidate 3 | October 22, 2026 |
| Release Candidate 4 | November 5, 2026 |
| General availability | November 19, 2026 |

Release managers may adjust this timetable to accommodate development progress. [Official timetable](https://wiki.php.net/todo/php86#timetable)

## Partial Function Application {#partial-function-application}

Partial function application creates a closure by supplying some arguments now and leaving others for a later call. The `?` placeholder identifies an argument that the resulting closure will receive.

```php
function formatLabel(string $prefix, string $name): string
{
    return $prefix . ': ' . $name;
}

// Existing approach.
$oldLabel = static fn (string $name): string => formatLabel('Article', $name);

// PHP 8.6.
$articleLabel = formatLabel('Article', ?);

$title = $articleLabel('PHP 8.6'); // Article: PHP 8.6
```

Creating `$articleLabel` binds the prefix without executing `formatLabel()`. The later call supplies the name. This removes a wrapper whose only job was to forward an argument. Supplied argument expressions are evaluated when the partial is created, which matters if they call functions with side effects. [Partial Function Application RFC](https://wiki.php.net/rfc/partial_function_application_v2)

There is an important amendment to the original proposal: **every `?` creates a required parameter**, even when the original parameter has a default. The `...` placeholder preserves the optionality of remaining parameters.

```php
function greet(string $name, string $punctuation = '!'): string
{
    return 'Hello, ' . $name . $punctuation;
}

$explicit = greet('Maya', ?);
$flexible = greet('Maya', ...);

$explicit('?'); // Hello, Maya?
$flexible();    // Hello, Maya!
```

`$explicit` requires punctuation; `$flexible` can use the original default. This distinction follows the accepted [optional-parameter amendment](https://wiki.php.net/rfc/partial_function_application_optional_placeholder).

## Readonly Property Defaults {#readonly-property-defaults}

PHP 8.6 allows defaults directly on instance readonly properties, including properties inside readonly classes. This is useful when an implementation needs to expose fixed metadata through a property contract.

```php
interface ExportFormat
{
    public string $extension { get; }
}

final readonly class CsvFormat implements ExportFormat
{
    public string $extension = 'csv';
}

$format = new CsvFormat();
$extension = $format->extension; // csv
```

The class satisfies the interface's readable property without a constructor assignment. The default initializes the property before the constructor body runs, so assigning a different value in the constructor would be a modification and fail.

This differs from constructor property promotion: a promoted parameter's default supplies an argument to the constructor. A declared property default initializes the property itself. Existing type, inheritance, and constant-expression rules still apply. [Readonly Property Defaults RFC](https://wiki.php.net/rfc/readonly_property_defaults)

## The New Duration Class {#duration-class}

An integer timeout leaves its unit implicit. A value of `500` might represent seconds, milliseconds, or microseconds depending on the API. PHP 8.6 introduces `Time\Duration` to represent elapsed time with nanosecond precision.

```php
use Time\Duration;

$connectionTimeout = Duration::fromMilliseconds(750);
$retryDelay = Duration::fromSeconds(2);
$combined = $connectionTimeout->add($retryDelay);

$seconds = $combined->seconds;         // 2
$nanoseconds = $combined->nanoseconds; // 750000000
```

The factory names make units explicit. `Duration` is immutable, so `add()` creates a new value without changing either input.

`DateInterval` remains appropriate for calendar relationships such as months and days. Their elapsed length can depend on the calendar and daylight saving transitions. `Time\Duration` represents a fixed amount of elapsed time, making it suitable for timeouts and retry delays. Existing third-party APIs still need to support this type before accepting it as an argument. [Duration RFC](https://wiki.php.net/rfc/duration_class)

## Language and Object Model Improvements {#language-improvements}

Several smaller changes make intentions easier to express in classes and improve the information available while debugging them.

### Override Checks for Class Constants

The `#[\Override]` attribute now applies to class constants. PHP checks that a corresponding constant exists in a parent class or implemented interface.

```php
class BaseExporter
{
    protected const FORMAT = 'text';
}

final class CsvExporter extends BaseExporter
{
    #[\Override]
    protected const FORMAT = 'csv';
}
```

The attribute records that `FORMAT` deliberately overrides an inherited constant. If the parent constant is renamed or removed, the mismatch becomes an error. A private parent constant does not satisfy this check. [Override for Class Constants RFC](https://wiki.php.net/rfc/override_constants)

### Debuggable Enums

Enums can implement `__debugInfo()` to customize the information exposed by `var_dump()`.

```php
enum PublicationStatus: string
{
    case Draft = 'draft';
    case Published = 'published';

    public function __debugInfo(): array
    {
        return [
            'status' => $this->value,
            'visible' => $this === self::Published,
        ];
    }
}
```

Debugging a status can now reveal a useful derived detail such as visibility. This method customizes debugging information; it does not add mutable state to enum cases. [Debuggable Enums RFC](https://wiki.php.net/rfc/debugable-enums)

### Property Writes on Objects Referenced by Constants

A constant can refer to a mutable object. PHP 8.6 permits direct property writes through that constant reference.

```php
const COUNTER = new stdClass();

COUNTER->processed = 0;
COUNTER->processed++;

$processed = COUNTER->processed; // 1
```

The object changes while the constant continues to refer to the same object. Property assignments, increments, and related operations become consistent with that distinction. This does not permit rebinding constants or generally changing array elements inside constant arrays. [Constant Object Property Writes RFC](https://wiki.php.net/rfc/const_object_property_write)

### Stateless Closure Caching

PHP can reuse stateless static closures that capture no variables and declare no static variables. This reduces repeated closure allocation.

The original RFC also proposed automatically inferring `static` for eligible closures. Its errata states that **only stateless closure caching was merged**. Automatic static inference should therefore not be presented as a PHP 8.6 feature. [Closure Optimizations RFC and errata](https://wiki.php.net/rfc/closure-optimizations#errata)

## New Functions and Standard Library Updates {#standard-library-updates}

These additions cover common operations such as constraining values, expressing sort direction, and inspecting properties. Their benefits range from clearer application code to more accurate framework tooling.

### The clamp() Function

`clamp()` returns a value when it lies within inclusive bounds, or the nearest boundary when it falls outside them.

```php
$progress = clamp(125, min: 0, max: 100); // 100
$volume = clamp(-5, min: 0, max: 10);    // 0
$rating = clamp(4, min: 1, max: 5);      // 4
```

The function names the operation directly, replacing expressions such as `max(0, min(100, $value))`. It accepts comparable values through `mixed` parameters and follows PHP's comparison rules, so consistent operand types remain important. Reversed bounds, or `NAN` used as a bound, cause a `ValueError`. [clamp() RFC](https://wiki.php.net/rfc/clamp_v2)

### SortDirection

The new global `SortDirection` enum provides `Ascending` and `Descending` cases. It is an unbacked enum, allowing each API to choose its own representation.

```php
function directionLabel(SortDirection $direction): string
{
    return match ($direction) {
        SortDirection::Ascending => 'Oldest first',
        SortDirection::Descending => 'Newest first',
    };
}

$label = directionLabel(SortDirection::Descending);
```

The parameter accepts only the two defined cases. The RFC introduces a shared type; it does not automatically update every sorting function or framework query builder to accept it. [SortDirection RFC](https://wiki.php.net/rfc/sort_direction_enum)

### Unicode and Locale Improvements

The `intl` extension gains `grapheme_strrev()`, which reverses text by grapheme cluster. This preserves combinations of code points that form a single visible character.

```php
$text = "Ae\u{0301}B";
$reversed = grapheme_strrev($text); // B, e with its accent, then A
```

The combining accent stays attached to `e`. Reversing bytes or individual code points would not express that same operation. [grapheme_strrev() RFC](https://wiki.php.net/rfc/grapheme_strrev)

`Locale::getDisplayKeyword()` and `Locale::getDisplayKeywordValue()` expose localized labels for locale keywords and their values.

```php
$keywordLabel = Locale::getDisplayKeyword('calendar', 'en');
$valueLabel = Locale::getDisplayKeywordValue(
    'en_US@calendar=gregorian',
    'calendar',
    'en',
);
```

These methods help build readable locale settings using ICU's display data instead of an application-maintained label map. Procedural equivalents are also available. [Locale Display Keyword RFC](https://wiki.php.net/rfc/getdisplaykeyword_and_getdisplaykeywordvalue)

### Reflection and Parameter DocComments

`ReflectionProperty::isReadable()` and `isWritable()` answer whether a property can be accessed from a specified scope. They account for details that `isPublic()` alone cannot describe.

```php
final class Article
{
    public private(set) string $title = 'PHP 8.6';
}

$article = new Article();
$property = new ReflectionProperty(Article::class, 'title');

$readable = $property->isReadable(null, $article); // true
$writable = $property->isWritable(null, $article); // false
```

A `null` scope represents access from outside a class. Supplying an object also allows instance-specific checks, such as whether a readonly property has been initialized. This is useful for serializers and mapping libraries. [Reflection Readability and Writability RFC](https://wiki.php.net/rfc/isreadable-iswriteable)

Function parameters can also carry DocComments retrievable through `ReflectionParameter::getDocComment()`.

```php
function excerpt(
    /** The original article content. */
    string $content,
    /** Maximum number of bytes to retain. */
    int $length = 120,
): string {
    return substr($content, 0, $length);
}

$parameter = (new ReflectionFunction('excerpt'))->getParameters()[1];
$documentation = $parameter->getDocComment();
```

The documentation sits beside its parameter, while reflection makes it available to tools. This does not add runtime validation for the comment's meaning. [Parameter DocComments RFC](https://wiki.php.net/rfc/parameter-doccomments)

## Streams and Extension Improvements {#streams-and-extensions}

PHP 8.6 also expands the APIs used by network clients, event-driven libraries, binary parsers, and database tools. These changes are especially relevant to developers maintaining infrastructure packages.

### Polling API

The new `Io\Poll` API monitors I/O readiness through platform-specific mechanisms such as epoll and kqueue. It provides a common interface for registering handles and waiting for events.

This gives event-driven libraries a native polling foundation. It supplies readiness notifications rather than a complete event loop with task scheduling, timers, and signal management. [Polling API RFC](https://wiki.php.net/rfc/poll_api)

### Stream Error Handling

Explicit stream contexts can select warning-based reporting, exceptions, or silent handling. Structured error storage allows applications to inspect failures programmatically.

```php
$context = stream_context_create([
    'stream' => [
        'error_mode' => StreamErrorMode::Exception,
    ],
]);
```

Passing this context to a supported stream operation opts into exceptions for terminating errors. Non-terminating errors do not automatically become exceptions. The default remains traditional error reporting, and these error-handling options cannot be applied globally through `stream_context_set_default()`. [Stream Error Handling RFC](https://wiki.php.net/rfc/stream_errors)

### TLS Session Resumption

OpenSSL stream support gains more control over TLS session reuse, including session import and export and callbacks for session management. Reusing an eligible session can reduce the work involved in a later TLS handshake.

This concerns encrypted connection state, which is separate from an application's PHP login session. The benefit depends on the connection pattern and server support. [TLS Session Resumption RFC](https://wiki.php.net/rfc/tls_session_resumption_api)

### Binary Packing

`pack()` and `unpack()` support explicit endianness modifiers for integer formats, including signed integers. Floating-point formats gain corresponding modifiers.

```php
$integerBytes = pack('l<', -120);
$integer = unpack('l<value', $integerBytes)['value']; // -120

$doubleBytes = pack('d>', 2.5);
$double = unpack('d>value', $doubleBytes)['value']; // 2.5
```

Here, `<` selects little-endian encoding and `>` selects big-endian encoding. The formats make the intended byte order visible without manual signed-integer conversion. Existing dedicated floating-point formats remain available. [Integer Endianness RFC](https://wiki.php.net/rfc/pack-unpack-endianness-signed-integers-support), [Floating-Point Endianness RFC](https://wiki.php.net/rfc/pack-unpack-float-endianness-modifier)

### MySQLi and SNMP

MySQLi gains `mysqli::quote_string()` and its procedural equivalent, `mysqli_quote_string()`. They escape a string and include the surrounding single quotes, which is useful for tools that need to generate complete SQL text. Parameterized queries remain the usual choice for application values. [MySQLi Quoting RFC](https://wiki.php.net/rfc/mysqli_quote_string)

SNMP improvements include additional SNMPv3 encryption options when supported by the underlying library, MIB reset functionality through `snmp_init_mib()`, and more control over parsing and output. These changes primarily affect network monitoring and management applications. [SNMP Improvements RFC](https://wiki.php.net/rfc/snmp_improvements_2026)

## Deprecations and Compatibility Changes {#deprecations}

New features are only part of the release. Existing code can also encounter new diagnostics or changed defaults, even when it does not adopt any new syntax.

### Accepted Deprecations

The umbrella RFC votes on each proposal separately. Selected accepted changes include:

| Affected code | Direction of change |
| --- | --- |
| `is_integer()`, `is_long()` | Use `is_int()` |
| `is_double()`, `doubleval()` | Use `is_float()`, `floatval()` |
| Objects passed to `http_build_query()` or `array_walk()` | Supply arrays |
| `return` inside `finally` | Move return logic outside `finally` |
| Certain identifiers, including `let` and `is` | Rename affected declarations |
| Reflection property writes targeting unrelated objects | Use a compatible object |
| Custom session handlers missing `create_sid()` or `validateId()` | Implement the missing methods |
| `SplFileObject` CSV methods | Review affected CSV code |

For a simple public data object, an explicit array replaces implicit object traversal:

```php
// Before.
$query = http_build_query((object) ['page' => 2]);

// After.
$query = http_build_query(['page' => 2]);
```

Both express the same query data. **The proposal to deprecate `list()` did not pass.** The RFC also contains further accepted SPL, MySQLi, reflection, and locale-related changes; consult individual results for the full scope. [PHP 8.6 Deprecations RFC](https://wiki.php.net/rfc/deprecations_php_8_6)

### Returning Values from Constructors and Destructors

A separate RFC deprecates returning a value from `__construct()` or `__destruct()`. A bare `return;` remains valid for ending the method early.

```php
final class CacheOptions
{
    public function __construct(public bool $enabled)
    {
        if (!$this->enabled) {
            return; // Still valid: no value is returned.
        }
    }
}
```

Using `return false;` or `return $this;` would trigger the new deprecation. Making either lifecycle method a generator is also deprecated. [Constructor and Destructor Return Values RFC](https://wiki.php.net/rfc/deprecate-return-value-from-construct)

### Session Defaults

PHP's native session extension changes three defaults:

| Setting | Previous default | PHP 8.6 default |
| --- | --- | --- |
| `session.use_strict_mode` | `0` | `1` |
| `session.cookie_httponly` | `0` | `1` |
| `session.cookie_samesite` | Empty string | `Lax` |

These settings strengthen session ID handling and cookie behavior. Applications that read the session cookie from JavaScript or depend on cross-site cookie delivery should review the effect. Explicit application or deployment configuration can override defaults, so the effective configuration matters. [Session Configuration Defaults RFC](https://wiki.php.net/rfc/session_security_defaults)

### The mbregex Transition

The Oniguruma-based mbregex functions are deprecated in PHP 8.6, with removal planned for PHP 9.0. This includes functions such as `mb_ereg()`, `mb_ereg_replace()`, and `mb_split()`.

The change concerns the regular-expression portion of mbstring, not the entire extension. Applications using these functions need to review their pattern syntax and encoding assumptions when choosing replacements. [Oniguruma and mbregex RFC](https://wiki.php.net/rfc/eol-oniguruma)

### Trimming and Filter Chains

`trim()`, `ltrim()`, and `rtrim()` now include form feed (`\f`) in their default character masks.

```php
$title = trim("\fPHP 8.6\f"); // PHP 8.6
```

Code that intentionally preserves boundary form-feed characters will need an explicit character mask. This is a behavior change, even though no new function call is involved. [Form Feed in Trim Functions RFC](https://wiki.php.net/rfc/trim_form_feed)

The default threshold for filters in a `php://filter` URL is 16. Exceeding it produces a deprecation in PHP 8.6. The context option `filter.max_filter_count` controls the threshold; programmatic filter attachment through `stream_filter_append()` and `stream_filter_prepend()` is outside this URL limit. [Filter Chain Limit RFC](https://wiki.php.net/rfc/limit-maximum-number-of-filter-chains)

### Function Arguments in Error Messages

The `error_include_args` setting controls inclusion of function arguments in error messages. The feature respects `#[SensitiveParameter]` and the existing string-length limit used for exception arguments.

More context can make failures easier to diagnose, but applications that parse error text or collect logs should account for the changed format and the data those arguments contain. [Function Arguments in Errors RFC](https://wiki.php.net/rfc/display_error_function_args)

## What These Changes Mean for Existing Applications {#application-impact}

The practical priority is compatibility before syntax adoption. For an existing application, the most useful questions are whether its dependencies support PHP 8.6, whether its extensions are available, and whether its code relies on behavior highlighted above.

New global names also deserve attention. An application-defined global `clamp()` function or `SortDirection` type can conflict with the built-in additions. Namespaced application code avoids those particular global-name collisions. [clamp() compatibility notes](https://wiki.php.net/rfc/clamp_v2#backward_incompatible_changes), [SortDirection compatibility notes](https://wiki.php.net/rfc/sort_direction_enum#backward_incompatible_changes)

Infrastructure requirements have their own scope. The accepted minimum-version RFC specifies Autoconf 2.71 for builds from Git and MySQL 5.7.3 or MariaDB 10.2.4 for the persistent-connection reset behavior. The database threshold concerns persistent connections, rather than declaring every older database connection unusable. This RFC remains in the index's pending-implementation category at the review date. [Minimum Supported Versions RFC](https://wiki.php.net/rfc/min_supported_versions_php_8_6), [RFC implementation status](https://wiki.php.net/rfc#pending_implementation_landing)

As the stable release approaches, its announcement and migration guide will provide the final reference for upgrade decisions. Accepted scope, implementation details, and the eventual release notes can differ.

## Conclusion {#conclusion}

PHP 8.6 offers useful improvements at several levels, from everyday callbacks to the infrastructure beneath network libraries. The main points to remember are:

- **Less callback boilerplate.** Partial function application binds arguments directly, with required `?` placeholders and optionality preserved through `...`.
- **Clearer data contracts.** Readonly defaults, `Time\Duration`, and `SortDirection` make fixed values, time units, and direction easier to express.
- **Better library APIs.** Reflection, stream errors, polling, Unicode helpers, and binary formats give library authors more precise tools.
- **Compatibility deserves attention.** Deprecations and changed defaults can affect an application before it adopts any new feature.
- **Release status matters.** November 19, 2026 is the scheduled stable release date; this article describes the preview reviewed on September 18, 2026.
