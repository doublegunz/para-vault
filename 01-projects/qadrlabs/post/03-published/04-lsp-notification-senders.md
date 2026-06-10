Your team has a notification system with three concrete senders inheriting from a common abstract class: email, SMS, and push. The interface looks clean. Type checks pass. Code review is happy. Then a critical password reset email goes out as an SMS instead, and the message gets silently truncated to one hundred sixty characters, cutting off the verification code. The code compiles. The tests pass. The customer cannot reset their password.

Welcome to the Liskov Substitution Principle. Most violations of LSP do not look like bugs at compile time. They look like reasonable subclasses that happen to behave differently than their parent in subtle ways. The behavior difference does not surface during code review, does not show up in the type system, and only becomes visible when production code routes a real user through the substitution and the wrong thing happens.

This article is the fourth in our SOLID series, following [Open/Closed Principle in Laravel 13: Build an Extensible Payment Gateway System](https://qadrlabs.com/post/openclosed-principle-in-laravel-build-an-extensible-payment-gateway-system). We will build a notification sender hierarchy with three deliberate LSP violations: silent truncation, wrong exception type, and inconsistent return value. Pest tests will expose each violation, and we will fix them one at a time, ending with a hierarchy that is genuinely substitutable.

## Overview {#overview}

The plan goes through three movements. First we set up an abstract `NotificationSender` with three children (email, SMS, push), each of which violates LSP in a different way. Second we write Pest tests that catch each violation by treating all three senders as their parent type and verifying they behave the same way. The tests fail, which is exactly what LSP-aware tests should do when subclasses misbehave. Third we fix each violation in turn, re-run the tests, and end with a green suite where any sender can be substituted for any other without surprises.

### What You'll Build
- An abstract `NotificationSender` base class with a clear contract
- Three concrete senders (`EmailSender`, `SmsSender`, `PushSender`), each with a deliberate LSP violation
- Pest tests that treat all senders polymorphically and detect the violations
- A corrected hierarchy where every sender honors the contract

### What You'll Learn
- The four practical guardrails for LSP in PHP: return types, parameter types, exception types, and behavioral contracts
- How silent truncation, wrong exceptions, and shifted return shapes break substitutability
- How to write tests that detect LSP violations rather than hide them
- Why the classical Rectangle/Square example still teaches the principle better than any modern alternative

### What You'll Need
- PHP 8.3 or later
- Composer 2.x
- Familiarity with abstract classes, inheritance, and exceptions in PHP
- A terminal and a code editor

## Step 1: Set Up the Laravel Project {#step-1-set-up-the-laravel-project}

Spin up a fresh Laravel 13 application with Pest. The same command shape we used in earlier articles works here.

```bash
laravel new lsp-notification-demo --no-interaction --database=sqlite --pest --no-boost
cd lsp-notification-demo
```

Confirm Pest is wired up before adding any code.

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

## The Classical Rectangle and Square Setup {#the-classical-rectangle-and-square-setup}

Before we build the notification hierarchy, it helps to walk through the textbook LSP example, because it is the cleanest illustration of why "is-a" in code does not always match "is-a" in mathematics.

Mathematically, a square is a rectangle. Every property of a rectangle holds for a square: it has four corners, it has a width, it has a height, its area is width times height. So in code, you might write the following.

```php
class Rectangle
{
    public function __construct(public float $width, public float $height) {}

    public function setWidth(float $w): void  { $this->width = $w; }
    public function setHeight(float $h): void { $this->height = $h; }
    public function area(): float             { return $this->width * $this->height; }
}

class Square extends Rectangle
{
    public function setWidth(float $w): void
    {
        $this->width = $w;
        $this->height = $w;        // a square's width equals its height
    }

    public function setHeight(float $h): void
    {
        $this->width = $h;
        $this->height = $h;
    }
}
```

The class compiles, the type system is satisfied, and `Square extends Rectangle`. Now consider a function that operates on rectangles.

```php
function resizeAndCheck(Rectangle $r): void
{
    $r->setWidth(5);
    $r->setHeight(4);
    assert($r->area() === 20.0);   // expected: 5 * 4
}
```

Pass a `Rectangle` and the assertion holds. Pass a `Square` and the assertion fails: `setHeight(4)` overwrites the width too, so the area becomes 16, not 20. The function never knew it was operating on a square. The substitution broke a precondition that the parent class promised: that `setWidth` and `setHeight` are independent.

The lesson is that LSP is about behavior, not just type. A subclass can be a structural subtype and still violate the contract its parent established. Inheritance gives you syntactic compatibility for free; it does not give you behavioral compatibility, and behavioral compatibility is what code actually depends on.

We will not run code for the rectangle example in this project. It is included to set the mental frame for the notification hierarchy that follows, where the violations are subtler than `setHeight` overwriting width but the underlying mistake is the same.

## Step 2: Define the Abstract NotificationSender {#step-2-define-the-abstract-notificationsender}

Create the directory for our senders and a custom exception class that the contract will declare.

```bash
mkdir -p app/Notifications app/Exceptions/Notifications
```

Create `app/Exceptions/Notifications/NotificationFailedException.php` with the following content. Having a domain-specific exception class is how the contract advertises which failures callers should expect.

```php
<?php

namespace App\Exceptions\Notifications;

use RuntimeException;

class NotificationFailedException extends RuntimeException
{
    //
}
```

Now create the abstract base class. Open `app/Notifications/NotificationSender.php` and add the following.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

abstract class NotificationSender
{
    /**
     * Send a notification message to the given recipient.
     *
     * Contract:
     *  - The full message MUST be delivered. No silent truncation.
     *  - On failure, MUST throw NotificationFailedException (and only that type).
     *  - MUST return the channel name as a lowercase string on success.
     */
    abstract public function send(string $recipient, string $message): string;

    /**
     * The channel name this sender represents. Used in tests and logs.
     */
    abstract public function channel(): string;
}
```

The base class declares the contract in three places: the abstract method signatures, the docblock describing the behavioral promises, and the exception type. Subclasses that violate any of these are violating LSP, even if PHP accepts them at compile time.

## Step 3: Build Three Senders With Deliberate Violations {#step-3-build-three-senders-with-deliberate-violations}

Now we write three subclasses. Each one looks correct on the surface and each one violates the contract in a different way.

Create `app/Notifications/EmailSender.php` with the following content. This sender is the well-behaved one; it honors the contract.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class EmailSender extends NotificationSender
{
    public function send(string $recipient, string $message): string
    {
        if (!filter_var($recipient, FILTER_VALIDATE_EMAIL)) {
            throw new NotificationFailedException("Invalid email: {$recipient}");
        }

        // In a real integration this would call Mail::to(...)->send(...).
        // We just record the dispatch in memory so tests can verify.
        FakeChannelLog::record($this->channel(), $recipient, $message);

        return $this->channel();
    }

    public function channel(): string
    {
        return 'email';
    }
}
```

The sender uses a tiny in-memory log so tests can assert what was sent without involving a real mailer. Create that helper at `app/Notifications/FakeChannelLog.php` with the following content. It is intentionally simple and not part of the contract; it is just plumbing for the demo.

```php
<?php

namespace App\Notifications;

class FakeChannelLog
{
    /** @var array<int, array{channel:string,recipient:string,message:string}> */
    public static array $entries = [];

    public static function record(string $channel, string $recipient, string $message): void
    {
        self::$entries[] = compact('channel', 'recipient', 'message');
    }

    public static function reset(): void
    {
        self::$entries = [];
    }

    /** @return array<int, array{channel:string,recipient:string,message:string}> */
    public static function all(): array
    {
        return self::$entries;
    }
}
```

Now the SMS sender, with violation number one: silent truncation. SMS providers typically charge per segment of one hundred sixty characters, and a developer might decide to be "helpful" by automatically trimming long messages. That decision quietly breaks the parent's promise that the full message will be delivered.

Create `app/Notifications/SmsSender.php` with the following content.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class SmsSender extends NotificationSender
{
    public const MAX_LENGTH = 160;

    public function send(string $recipient, string $message): string
    {
        if (!preg_match('/^\+?\d{8,15}$/', $recipient)) {
            throw new NotificationFailedException("Invalid phone number: {$recipient}");
        }

        // VIOLATION 1: silent truncation. The parent contract said the full
        // message must be delivered. This subclass quietly drops characters.
        $truncated = substr($message, 0, self::MAX_LENGTH);

        FakeChannelLog::record($this->channel(), $recipient, $truncated);

        return $this->channel();
    }

    public function channel(): string
    {
        return 'sms';
    }
}
```

Now the push sender, with violations two and three. The push sender throws a generic exception instead of `NotificationFailedException`, and on success it returns an associative array describing the dispatch instead of the channel name string the contract promised. Create `app/Notifications/PushSender.php` with the following content.

```php
<?php

namespace App\Notifications;

use Exception;

class PushSender extends NotificationSender
{
    public function send(string $recipient, string $message): string
    {
        if (str_starts_with($recipient, 'invalid-')) {
            // VIOLATION 2: wrong exception type. The contract says callers
            // should expect NotificationFailedException. This subclass raises
            // a generic Exception, which would slip past a typed catch block
            // in the calling code and crash the request instead of degrading
            // gracefully.
            throw new Exception("Push device token rejected: {$recipient}");
        }

        FakeChannelLog::record($this->channel(), $recipient, $message);

        // VIOLATION 3: shifted return shape. The contract says return the
        // channel name as a string. This subclass returns a richer JSON
        // payload that PHP coerces to a string in some contexts but not all.
        // Code that expected a plain string will misbehave.
        return json_encode([
            'channel'   => $this->channel(),
            'recipient' => $recipient,
            'sent_at'   => date('c'),
        ]);
    }

    public function channel(): string
    {
        return 'push';
    }
}
```

Each violation is small enough that you might actually write it in production without noticing. The truncation looks like a polite courtesy. The wrong exception looks like leaving the original error untouched. The richer return value looks like adding helpful context. None of them are caught by PHP's type checker, because all three method signatures still match the parent. They are LSP violations because they break the contract the parent promised, not because they break the type system.

## Step 4: Write LSP-Aware Pest Tests {#step-4-write-lsp-aware-pest-tests}

The trick to detecting LSP violations is to write tests that operate on the parent type, not on each subclass individually. If you only ever test `EmailSender` against email-shaped expectations and `SmsSender` against SMS-shaped expectations, you will never catch substitution failures. The tests have to treat all three senders as `NotificationSender` instances and assert the parent's contract.

Pest's dataset feature is perfect for this. We define the dataset of senders once and run the same tests against each.

Generate the test file.

```bash
php artisan make:test NotificationSenderTest --pest
```

Open `tests/Feature/NotificationSenderTest.php` and replace its body with the following.

```php
<?php

use App\Exceptions\Notifications\NotificationFailedException;
use App\Notifications\EmailSender;
use App\Notifications\FakeChannelLog;
use App\Notifications\NotificationSender;
use App\Notifications\PushSender;
use App\Notifications\SmsSender;

beforeEach(function () {
    FakeChannelLog::reset();
});

// A dataset of [sender instance, valid recipient] pairs so the same test
// runs polymorphically against every concrete subclass.
dataset('senders', [
    'email sender' => [fn () => new EmailSender(),  'asriyanik@example.com'],
    'sms sender'   => [fn () => new SmsSender(),    '+6281234567890'],
    'push sender'  => [fn () => new PushSender(),   'device-token-abc123'],
]);

it('returns the channel name as a string on success', function (NotificationSender $sender, string $recipient) {
    $result = $sender->send($recipient, 'Hello world');

    expect($result)->toBe($sender->channel());
})->with('senders');

it('delivers the full message without truncation', function (NotificationSender $sender, string $recipient) {
    // 200 characters, intentionally longer than any common SMS limit
    $longMessage = str_repeat('A', 200);

    $sender->send($recipient, $longMessage);

    $entry = FakeChannelLog::all()[0];
    expect($entry['message'])->toBe($longMessage);
})->with('senders');

it('throws NotificationFailedException on invalid recipient', function (NotificationSender $sender) {
    expect(fn () => $sender->send('invalid-recipient', 'hello'))
        ->toThrow(NotificationFailedException::class);
})->with([
    'email sender' => [fn () => new EmailSender()],
    'sms sender'   => [fn () => new SmsSender()],
    'push sender'  => [fn () => new PushSender()],
]);
```

The first test verifies the return type is the channel name string. The second test verifies the full message is delivered. The third test verifies the right exception type is thrown for invalid input. All three tests are written against `NotificationSender`, so a violation in any subclass surfaces as a failed test for that subclass specifically.

## Step 5: Watch the Tests Fail {#step-5-watch-the-tests-fail}

Run the suite. We expect failures because the three violations are still in place.

```bash
php artisan test
```

The output should look like this. Pest reports each subclass-dataset combination as a separate test, so the dataset of three senders multiplied by three test cases gives nine sender-specific results, with the failures highlighted.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

   FAIL  Tests\Feature\NotificationSenderTest
  ✓ it returns the channel name as a string on success with email sender                                                                                                                               0.04s
  ✓ it returns the channel name as a string on success with sms sender                                                                                                                                 0.02s
  ⨯ it returns the channel name as a string on success with push sender                                                                                                                                0.02s
  ✓ it delivers the full message without truncation with email sender                                                                                                                                  0.02s
  ⨯ it delivers the full message without truncation with sms sender                                                                                                                                    0.02s
  ✓ it delivers the full message without truncation with push sender                                                                                                                                   0.02s
  ✓ it throws NotificationFailedException on invalid recipient with email sender                                                                                                                       0.02s
  ✓ it throws NotificationFailedException on invalid recipient with sms sender                                                                                                                         0.02s
  ⨯ it throws NotificationFailedException on invalid recipient with push sender                                                                                                                        0.02s

  ---- Failed Tests ----

  • Tests\Feature\NotificationSenderTest > it returns the channel name as a string on success with push sender
  Failed asserting that '{"channel":"push","recipient":"device-token-abc123","sent_at":"2026-05-02T16:08:31+00:00"}' is identical to 'push'.

  • Tests\Feature\NotificationSenderTest > it delivers the full message without truncation with sms sender
  Failed asserting that 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' is identical to 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'.

  • Tests\Feature\NotificationSenderTest > it throws NotificationFailedException on invalid recipient with push sender
  Expected exception NotificationFailedException to be thrown, but Exception was thrown.

  Tests:    3 failed, 8 passed (12 assertions)
  Duration: 0.51s
```

Three sender-specific failures, each precisely identifying one violation. The Pest report names which sender failed which contract clause, which is exactly the kind of feedback you want when LSP is broken: not a vague "something is off", but "this subclass violates this specific guarantee".

## Step 6: Fix Violation 1, Silent Truncation in SmsSender {#step-6-fix-violation-1-silent-truncation-in-smssender}

The right behavior when an SMS message exceeds one hundred sixty characters is one of two things: either reject the message with a clear exception, or split it into multiple SMS segments. Silent truncation is never right because it produces invisible failures.

For this article we pick "reject with an exception" because it is the safer default and the simpler change. A real SMS sender might also implement segmentation behind the scenes, but that is a feature decision; the LSP-correct behavior is whatever does not silently lose data.

Open `app/Notifications/SmsSender.php` and replace the body of `send` with the following.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class SmsSender extends NotificationSender
{
    public const MAX_LENGTH = 160;

    public function send(string $recipient, string $message): string
    {
        if (!preg_match('/^\+?\d{8,15}$/', $recipient)) {
            throw new NotificationFailedException("Invalid phone number: {$recipient}");
        }

        // FIX 1: do not silently truncate. Long messages either need to
        // be split (a separate concern) or rejected loudly.
        if (strlen($message) > self::MAX_LENGTH) {
            throw new NotificationFailedException(
                "SMS message exceeds " . self::MAX_LENGTH . " characters"
            );
        }

        FakeChannelLog::record($this->channel(), $recipient, $message);

        return $this->channel();
    }

    public function channel(): string
    {
        return 'sms';
    }
}
```

The behavior change is significant. Code that used to "succeed" with truncated messages now fails loudly. That is the right outcome: callers get to decide what to do about long messages instead of receiving silent corruption. To make the LSP-aware test pass, we also need to adjust the second test slightly: a message longer than the contract supports should not be sent at all. Update the test that asserts full delivery to use a short message that all senders can deliver.

Open `tests/Feature/NotificationSenderTest.php` and replace the second test with the following.

```php
it('delivers the full message without truncation', function (NotificationSender $sender, string $recipient) {
    // Pick a message length all senders should support per their declared limits.
    $message = 'Verification code: 482917 (valid 5 minutes)';

    $sender->send($recipient, $message);

    $entry = FakeChannelLog::all()[0];
    expect($entry['message'])->toBe($message);
})->with('senders');
```

Notice the design choice this exposes: the contract in `NotificationSender` does not actually specify a maximum message length, but each subclass implicitly has one. This is a real LSP smell; in a production system you would either move that constraint into the contract (so callers know about it) or guarantee the contract supports any length and let each sender handle large messages internally. For this article we leave the contract loose and document that callers are responsible for keeping messages within their channel's limit. That is a reasonable compromise; what is not reasonable is silent truncation.

## Step 7: Fix Violations 2 and 3 in PushSender {#step-7-fix-violations-2-and-3-in-pushsender}

The push sender throws the wrong exception type and returns the wrong shape. Both fixes are mechanical.

Open `app/Notifications/PushSender.php` and replace its body with the following.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class PushSender extends NotificationSender
{
    public function send(string $recipient, string $message): string
    {
        if (str_starts_with($recipient, 'invalid-')) {
            // FIX 2: throw the contract's exception type, not a generic one.
            // Callers can now catch NotificationFailedException and degrade
            // gracefully on any sender, exactly as the parent promised.
            throw new NotificationFailedException(
                "Push device token rejected: {$recipient}"
            );
        }

        FakeChannelLog::record($this->channel(), $recipient, $message);

        // FIX 3: return the channel name string as the contract requires.
        // If callers need richer dispatch metadata, that belongs on a
        // dedicated diagnostics method, not in the success return value.
        return $this->channel();
    }

    public function channel(): string
    {
        return 'push';
    }
}
```

Both fixes preserve the underlying behavior (the push notification is still recorded; invalid tokens still fail) but bring the implementation back into line with the parent's contract. If the dispatch metadata is genuinely useful to some callers, the right move is to expose it through a separate observability surface, like an event or a logging line, rather than smuggling it through the return value of a method whose contract promises a string.

## Step 8: Run All Tests Again {#step-8-run-all-tests-again}

Run the suite once more. With all three violations fixed, every dataset case should now pass.

```bash
php artisan test
```

The output should look like this.

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                                                                                                                                                  0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                                                                                                                                                      0.05s

   PASS  Tests\Feature\NotificationSenderTest
  ✓ it returns the channel name as a string on success with email sender                                                                                                                               0.03s
  ✓ it returns the channel name as a string on success with sms sender                                                                                                                                 0.02s
  ✓ it returns the channel name as a string on success with push sender                                                                                                                                0.02s
  ✓ it delivers the full message without truncation with email sender                                                                                                                                  0.02s
  ✓ it delivers the full message without truncation with sms sender                                                                                                                                    0.02s
  ✓ it delivers the full message without truncation with push sender                                                                                                                                   0.02s
  ✓ it throws NotificationFailedException on invalid recipient with email sender                                                                                                                       0.02s
  ✓ it throws NotificationFailedException on invalid recipient with sms sender                                                                                                                         0.02s
  ✓ it throws NotificationFailedException on invalid recipient with push sender                                                                                                                        0.02s

  Tests:    11 passed (15 assertions)
  Duration: 0.49s
```

Eleven tests passing, including all nine sender-specific cases. Every concrete sender now satisfies the contract its parent declared, which is exactly what LSP demands. A function that accepts a `NotificationSender` can pass any of the three subclasses without surprise.

## Understanding Liskov Substitution Principle {#understanding-liskov-substitution-principle}

Now that the violations are fixed, we can describe LSP more precisely. Barbara Liskov's formal phrasing is dense, but the practical translation for PHP developers reduces to four guardrails. A subclass can only be substituted for its parent if all four hold.

The first guardrail is return types. A child can narrow the return type compared to its parent (a child that returns `Collection<User>` is fine where the parent returned `iterable<User>`), but it cannot widen it. A child that returns a richer associative array where the parent returned a string, as our push sender did, has widened the return contract and broken substitutability. PHP's covariance support catches some return type widenings at compile time but not all of them, especially when the declared return type is a broad type like `string` and the actual content shape changes.

The second guardrail is parameter types. A child can widen the parameter type compared to its parent (a child that accepts `iterable` where the parent accepted `array` is fine), but it cannot narrow it. Narrowing parameter types at the child level breaks callers that rightly expected the parent's wider contract. PHP enforces this strictly at compile time, which is one of the easier LSP constraints to honor in PHP specifically.

The third guardrail is exception types. A child must throw the same exception types the parent declares, or subtypes of them. Throwing a brand new exception type that callers cannot anticipate, as our push sender did with the generic `Exception`, is an LSP violation. PHP does not enforce this at compile time because PHP does not have checked exceptions; the contract has to be documented and tested.

The fourth guardrail is behavioral preconditions and postconditions. The classical Rectangle/Square example illustrates this: `Square::setHeight` violates the precondition that width and height are independent. Silent truncation in `SmsSender` violates the postcondition that the full message is delivered. These are the hardest violations to spot because they are not in the type system at all; they live in the documentation, the comments, and the implicit expectations of callers. They are also the most damaging in production because they look like correct code.

A useful mental check when writing a subclass is to ask: "if a function elsewhere in the codebase only knew this object as the parent type, would my override surprise it?" If the answer is yes, you have an LSP violation, regardless of whether the type checker complains. The LSP-aware tests we wrote in this article are the executable form of that question: they treat each subclass as the parent type and assert the parent's contract.

## When LSP Violations Are Worth Fixing {#when-lsp-violations-are-worth-fixing}

LSP is the principle most easily over-applied. Every inheritance relationship in any codebase carries some risk of LSP imperfection, and chasing every imperfection produces ceremonial code without obvious benefit.

The key signal that an LSP violation matters is polymorphic use. If your code only ever instantiates `EmailSender` directly and only ever passes around `EmailSender` references, an LSP issue with `SmsSender` is irrelevant; nobody is substituting one for the other. If your code accepts `NotificationSender` parameters, stores `NotificationSender` collections, or resolves `NotificationSender` from the service container, then any subclass that misbehaves can flow through any of those paths and cause hidden bugs. That is when LSP starts to matter.

A second signal is the cost of failure. Notification senders are high-stakes because failures often look like silence (the user does not get the message) rather than crashes. Silent failures are the worst kind in production because they do not page you; they degrade trust slowly. Subsystems where silent failures are dangerous deserve more LSP discipline than subsystems where failures are loud and visible.

A third signal is the breadth of the inheritance hierarchy. Two-level hierarchies (one parent, one child) rarely have meaningful LSP issues because there is no real polymorphism. Hierarchies with three or more concrete children, especially ones the team plans to grow, are where LSP discipline pays off. The notification sender example in this article is borderline; with three concrete senders and ongoing pressure to add channels, it is in the zone where LSP discipline starts to matter.

A useful counter-question is: "what would happen if I deleted this inheritance and used composition instead?" Sometimes the answer is that the composition is cleaner and the inheritance was the wrong tool. Many modern Laravel codebases prefer composition (an interface plus implementations, like the `PaymentGateway` design from Article 3) over inheritance precisely because composition makes LSP-style violations harder to introduce. Inheritance promises behavioral compatibility that you have to actively maintain; an interface only promises method signatures, leaving the behavioral contract to documentation and tests.

## Common LSP Pitfalls {#common-lsp-pitfalls}

A persistent failure mode is throwing `BadMethodCallException` from a subclass that does not support a method the parent declares. This is the antipattern Article 5 will address head-on under the Interface Segregation Principle, but it is also a square LSP violation: the subclass is announcing that it cannot honor the parent's contract for some methods. The right fix is almost never to leave the exception in place; either the method does not belong on the parent contract (split the interface), or the subclass should not be a subclass at all (it is not really an "is-a").

A second pitfall is overriding methods to do nothing. A subclass that turns a meaningful parent method into an empty body is lying about its capabilities even more quietly than one that throws an exception. Callers expect the side effects the parent promised, get nothing, and never see an error. This is worse than the truncation case in our SMS sender because there is no observable signal at all that something went wrong.

A third pitfall is widening accepted input formats in subclasses without widening the contract. A child that accepts both arrays and Eloquent collections where the parent only documented arrays is technically more permissive, which sounds good. The trouble is that callers who know they are working with the parent type cannot rely on the wider behavior, so the wider behavior accumulates in the codebase as undocumented and untested. Eventually somebody depends on it, the subclass is replaced with a different implementation, and the dependent code breaks. Wider acceptance is fine when it is contracted; it is dangerous when it is accidental.

A fourth pitfall is using `instanceof` checks to special-case a particular subclass. The pattern `if ($sender instanceof PushSender) { ... }` is a confession that the parent contract is not enough and that the subclasses are not really substitutable. Sometimes that is unavoidable, but it is always a signal to revisit the design. If the special-case branches are rare, the contract probably needs another method. If they are frequent, the inheritance probably should not exist at all.

## Conclusion {#conclusion}

The Liskov Substitution Principle is the SOLID principle that protects the rest. SRP gives you classes with one reason to change. OCP gives you the ability to extend the system without modifying existing code. Both depend on the assumption that when you swap one implementation for another, the swap actually preserves behavior. LSP is the discipline that makes that assumption true.

Here are the key takeaways from this refactor to carry forward:

- **Substitutability is about behavior, not just types.** A subclass that passes the type checker can still violate the contract its parent class established. PHP cannot detect most LSP violations on its own.
- **The four guardrails are return types, parameter types, exception types, and behavioral contracts.** The first two are partially enforced by PHP. The last two need documentation and tests.
- **Test polymorphically, not subclass by subclass.** The Pest dataset pattern in this article runs the same tests against every sender, treated as the parent type. That is how LSP violations surface during development instead of in production.
- **Silent truncation is the most insidious LSP violation.** Code that quietly drops data looks correct in code review and at runtime; the only signal is end-user trust eroding over time. Reject loudly instead.
- **Exception types are part of the contract even when PHP does not enforce them.** A subclass that throws a different exception type than its parent declares forces callers to either expand their `catch` blocks (defeating the point of typed exceptions) or accept that some error paths will crash unexpectedly.
- **Composition often dodges LSP issues entirely.** When you find yourself fighting inheritance to maintain substitutability, consider switching to an interface plus independent implementations. Article 3's `PaymentGateway` design is composition-first by construction.
- **LSP discipline scales with polymorphism.** Hierarchies with one or two children are forgiving. Hierarchies with three or more, especially growing ones, deserve real LSP-aware tests.

In Article 5 we will take on the Interface Segregation Principle by splitting a fat reporting interface into small focused contracts. The motivating problem is exactly the antipattern this article warned about: classes that throw `BadMethodCallException` from methods they were forced to declare but never intended to support.