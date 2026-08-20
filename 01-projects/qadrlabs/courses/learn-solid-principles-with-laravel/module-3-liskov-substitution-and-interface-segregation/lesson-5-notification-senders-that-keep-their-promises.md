## 1. Before You Begin

Lesson 4 built a design that rests entirely on trust. `PaymentService` looks up an implementation by name and calls `charge()` on it, and it trusts every gateway to return the same array shape and to fail in the same way. The contract says so. PHP enforces only the method signature.

That gap is where the Liskov Substitution Principle lives. An implementation can satisfy every type hint your editor checks and still lie about what it does. It can quietly drop data, throw an exception nobody is catching, or hand back a value of the right type but the wrong shape. All three pass code review, because each one looks like a small kindness rather than a bug.

This lesson plants three such lies in a notification sender hierarchy and then hunts them down. The important part is not the fixes, which are mechanical; it is the technique that finds them. You will write tests that treat every subclass as its parent type and assert the parent's promises, watch three of them fail with precise diagnoses, and only then repair the implementations.

### What You'll Build

A `NotificationSender` hierarchy in SolidLab with three concrete senders: email, SMS, and push. Each will be built with a deliberate contract violation. You will write a polymorphic Pest suite using datasets, watch it fail in exactly three places, then fix each violation and watch all nine cases pass.

### What You'll Learn

- ✅ Why "is a" in code does not always match "is a" in the real world
- ✅ The four LSP guardrails: return types, parameter types, exception types, and behavioral contracts
- ✅ How to write a contract that states its promises where subclasses can read them
- ✅ How to test polymorphically with Pest datasets instead of subclass by subclass
- ✅ How to read a Pest failure report and map each failure back to a specific broken promise
- ✅ When an LSP violation is worth fixing, and when the inheritance itself was the mistake

### What You'll Need

- SolidLab with Lessons 3 and 4 complete
- Comfort with PHP abstract classes, inheritance, and custom exception types
- The `PaymentGateway` design from Lesson 4 fresh in mind, since this lesson explains why it was trustworthy

---

## 2. The Classical Rectangle and Square Problem

Before building the senders, it is worth walking through the textbook example. It is the cleanest illustration of the gap between structural subtyping and behavioral subtyping, and the notification violations later are the same mistake wearing better clothes.

Mathematically, a square is a rectangle. Every property of a rectangle holds for a square: four corners, a width, a height, an area of width times height. So the inheritance looks obviously correct.

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
        $this->height = $w;
    }

    public function setHeight(float $h): void
    {
        $this->width = $h;
        $this->height = $h;
    }
}
```

`Square` must keep its sides equal, so setting either dimension sets both. The class is valid PHP, the type system is satisfied, and `Square` genuinely extends `Rectangle`. Now consider a function that knows nothing about squares.

```php
function resizeAndCheck(Rectangle $r): void
{
    $r->setWidth(5);
    $r->setHeight(4);
    assert($r->area() === 20.0);
}
```

Pass a `Rectangle` and the assertion holds. Pass a `Square` and it fails: `setHeight(4)` overwrote the width, so the area is 16 rather than 20. The function never mentioned squares and had no way to defend itself.

What broke is not a type. It is a promise. `Rectangle` implied that width and height are independent, and `Square` cannot keep that promise while remaining a square. Inheritance handed `Square` syntactic compatibility for free; behavioral compatibility was never on offer, and behavioral compatibility is what callers actually depend on.

Note that the fix is not to write a cleverer `Square`. No implementation of a square can keep width and height independent. The correct conclusion is that a square is not a subtype of a mutable rectangle, whatever geometry says, and the inheritance should not exist. That conclusion is available whenever you find yourself fighting a subclass to keep a promise: sometimes the answer is that the relationship was wrong.

You will not run this code in SolidLab. It is here to set the frame for what follows, where the violations are subtler than a width overwriting a height but the underlying mistake is identical.

---

## 3. Declare the Contract

If subclasses are going to be held to promises, the promises have to be written down somewhere they can be read. That is what this section builds.

### Step 1: Create the Directories and the Exception

```bash
mkdir -p app/Notifications app/Exceptions/Notifications
```

Create `app/Exceptions/Notifications/NotificationFailedException.php`.

```php
<?php

namespace App\Exceptions\Notifications;

use RuntimeException;

class NotificationFailedException extends RuntimeException
{
    //
}
```

An empty class body, and that is fine. Its value is entirely in its name and its type. A domain specific exception is how a contract advertises which failures callers should expect, so that a caller can write `catch (NotificationFailedException $e)` and degrade gracefully instead of catching `Exception` and swallowing genuine bugs alongside expected failures.

Extending `RuntimeException` rather than `Exception` places it in the branch of the hierarchy that means "an error that can only be detected at run time", which is the accurate category for a rejected phone number or a dead device token.

### Step 2: Write the Abstract Base Class

Create `app/Notifications/NotificationSender.php`.

```php
<?php

namespace App\Notifications;

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

Look at where the contract actually lives, because it is in two very different places with very different enforcement.

The method signatures are enforced by PHP. A subclass cannot change `send()` to take three parameters or to return an array; the engine rejects it at compile time. That covers exactly one of the four guardrails you will meet in section 8.

The docblock is enforced by nothing. "The full message MUST be delivered" and "MUST throw NotificationFailedException" are promises PHP has no opinion about. A subclass can violate both while remaining perfectly valid code. This is not a flaw in the design; it is the reality of LSP in almost every language, and it is why the tests in section 5 exist. The docblock states the contract, and the tests enforce it.

Writing the promises as explicit MUST clauses is a small habit worth adopting. It converts a vague sense of how the class should behave into a checklist that a reviewer, a subclass author, or a test can work through item by item.

---

## 4. Build Three Senders, Two of Which Lie

Now write the implementations. One honors the contract. The other two violate it in ways that would very plausibly survive a code review, because each violation looks like a considerate decision rather than a mistake.

### Step 1: Write the Test Log Helper

The senders need somewhere to record what they dispatched so tests can inspect it without a real mail server or SMS provider. Create `app/Notifications/FakeChannelLog.php`.

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

Static state is normally a smell, and here it is a deliberate shortcut to keep the lesson focused on substitutability rather than on dependency wiring. Because the state persists across tests, section 5 resets it in a `beforeEach`. In production this would be a real channel integration, and Lesson 7 shows how to inject a fake through the container instead of reaching for a static.

### Step 2: Write the Well Behaved EmailSender

Create `app/Notifications/EmailSender.php`.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class EmailSender extends NotificationSender
{
    public function send(string $recipient, string $message): string
    {
        if (! filter_var($recipient, FILTER_VALIDATE_EMAIL)) {
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

This one keeps all three promises. It delivers the message unmodified, it throws the declared exception type on a bad recipient, and it returns the lowercase channel name. Read it carefully now, because it is the reference against which the next two are wrong.

### Step 3: Write the SmsSender With Violation 1

SMS providers charge per segment of 160 characters, so a developer might decide to be helpful and trim long messages rather than fail the send. Create `app/Notifications/SmsSender.php`.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class SmsSender extends NotificationSender
{
    public const MAX_LENGTH = 160;

    public function send(string $recipient, string $message): string
    {
        if (! preg_match('/^\+?\d{8,15}$/', $recipient)) {
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

This is the most dangerous of the three violations, and it is the one most likely to reach production. The method returns successfully, the return value is correct, the exception type is correct, and no error is logged anywhere. A caller sending a two hundred character password reset message gets a cheerful `'sms'` back and a customer who received forty characters of instructions.

There is no signal at all. No exception, no log line, no failing type check. The only evidence is a user who cannot complete a flow and cannot explain why.

### Step 4: Write the PushSender With Violations 2 and 3

Create `app/Notifications/PushSender.php`.

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
            // a generic Exception, which slips past a typed catch block in the
            // calling code and crashes the request instead of degrading.
            throw new Exception("Push device token rejected: {$recipient}");
        }

        FakeChannelLog::record($this->channel(), $recipient, $message);

        // VIOLATION 3: shifted return shape. The contract says return the
        // channel name as a string. This subclass returns a richer JSON
        // payload. Code that expected a plain string will misbehave.
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

Violation 2 is an exception type mismatch. A caller that wrote `catch (NotificationFailedException $e)` around a `NotificationSender` call handles email failures and SMS failures gracefully, and then crashes on push failures with an uncaught exception. The caller did nothing wrong; it caught exactly what the contract told it to catch.

Violation 3 is the subtle one, because PHP is entirely satisfied. The declared return type is `string`, and `json_encode` returns a string, so nothing complains anywhere. The *type* is right and the *meaning* is wrong. A caller logging `"Sent via {$result}"` writes a JSON blob into the log; a caller comparing `$result === 'push'` gets false forever.

Notice how each of the three reads as a considerate decision. Truncating is polite. Preserving the original exception feels honest. Returning richer metadata seems generous. None of them are caught by PHP, because all three method signatures still match the parent exactly. They are LSP violations because they break promises, not because they break types.

---

## 5. Test Polymorphically

Here is the technique that makes the whole lesson work, and it is worth understanding before writing the file.

The instinct when testing three senders is to write three test files: one that checks `EmailSender` does email things, one for SMS, one for push. That approach cannot find a single one of these violations. A test written specifically for `SmsSender` would assert the truncation, because the author of the test is the author of the truncation and considers it correct behavior.

LSP violations only appear when you test the *parent's* contract against *every* child. The tests must not know which sender they are running against; they must know only that it is a `NotificationSender` and that the base class made three promises.

### Step 1: Create the Test File

```bash
php artisan make:test NotificationSenderTest --pest
```

### Step 2: Write the Dataset and the Three Contract Tests

Open `tests/Feature/NotificationSenderTest.php` and replace its body.

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
    'email sender' => [fn () => new EmailSender(), 'asriyanik@example.com'],
    'sms sender'   => [fn () => new SmsSender(),   '+6281234567890'],
    'push sender'  => [fn () => new PushSender(),  'device-token-abc123'],
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

`dataset('senders', [...])` names a reusable set of arguments. Each entry is an array of arguments passed to the test closure, and the string key becomes part of the test name in the output, which is how a failure tells you *which* sender broke.

The senders are wrapped in closures (`fn () => new EmailSender()`) rather than instantiated directly. Pest resolves the closure per test case, so each case gets a fresh object rather than one instance shared across every test in the file.

`->with('senders')` attaches the dataset, and Pest then generates one test per entry. Three tests times three senders gives nine results.

Read the closure signatures: `function (NotificationSender $sender, string $recipient)`. The type hint is the parent, which is the entire point. Inside the closure there is no way to ask which subclass is running, so the assertions can only express what the parent promised.

Each test maps to exactly one clause of the docblock in section 3. The first asserts the return value is the channel name. The second asserts the full message was delivered. The third asserts the declared exception type. Note that the third uses an inline dataset without recipients, because `'invalid-recipient'` is rejected by all three senders for their own reasons: it fails the email filter, it fails the phone regex, and it starts with `invalid-`.

### Step 3: Watch It Fail

Run the file. You expect failures, which is not the usual reason to run tests.

```bash
php artisan test tests/Feature/NotificationSenderTest.php
```

```
   FAIL  Tests\Feature\NotificationSenderTest
  ✓ it returns the channel name as a string on success with dataset "email sender"                                                   0.09s  
  ✓ it returns the channel name as a string on success with dataset "sms sender"                                                     0.02s  
  ⨯ it returns the channel name as a string on success with dataset "push sender"                                                    0.02s  
  ✓ it delivers the full message without truncation with dataset "email sender"                                                      0.02s  
  ⨯ it delivers the full message without truncation with dataset "sms sender"                                                        0.02s  
  ✓ it delivers the full message without truncation with dataset "push sender"                                                       0.02s  
  ✓ it throws NotificationFailedException on invalid recipient with dataset "email sender"                                           0.02s  
  ✓ it throws NotificationFailedException on invalid recipient with dataset "sms sender"                                             0.02s  
  ⨯ it throws NotificationFailedException on invalid recipient with dataset "push sender"                                            0.02s  
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  
   FAILED  Tests\Feature\NotificationSenderTest > it returns the channel name as a string on success with dataset "push sender"             
  Failed asserting that two strings are identical.
  -'push'
  +'{"channel":"push","recipient":"device-token-abc123","sent_at":"2026-08-18T15:20:50+00:00"}'
```

The grid is the thing to study. Nine cells, three of them failing, and the pattern is diagonal: each sender fails exactly the clause it violates and passes the other two. `EmailSender` passes all three because it lied about nothing.

Read the grid as a diagnosis. Push fails the return value clause and the exception clause, so `PushSender` has two problems. SMS fails only the delivery clause, so `SmsSender` has one. This is far more useful than a suite that simply goes red, and it comes entirely from having written the tests against the parent type.

Further down, Pest prints the detail for each failure along with the summary.

```
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  
   FAILED  Tests\Feature\NotificationSenderTest > it throws NotificationFailedException on invalid recipient with dataset "push sender"     
  Failed asserting that an instance of class Exception is an instance of class App\Exceptions\Notifications\NotificationFailedException.

  at tests/Feature/NotificationSenderTest.php:40
     36▕ })->with('senders');
     37▕ 
     38▕ it('throws NotificationFailedException on invalid recipient', function (NotificationSender $sender) {
     39▕     expect(fn () => $sender->send('invalid-recipient', 'hello'))
  ➜  40▕         ->toThrow(NotificationFailedException::class);
     41▕ })->with([
     42▕     'email sender' => [fn () => new EmailSender()],
     43▕     'sms sender'   => [fn () => new SmsSender()],
     44▕     'push sender'  => [fn () => new PushSender()],

  1   tests/Feature/NotificationSenderTest.php:40


  Tests:    3 failed, 6 passed (9 assertions)
  Duration: 0.28s
```

The SMS failure is the one worth staring at. Pest prints the expected 200 character string and the actual 160 character string one above the other, and they are identical for their entire shared length. That is what silent truncation looks like when something finally checks: not an error, just a value that is quietly shorter than it should be.

---

## 6. Fix the Violations

Three failures, three fixes. Each one restores a promise rather than adding a feature.

### Step 1: Fix Silent Truncation in SmsSender

When a message exceeds the channel limit there are two defensible behaviors: reject it loudly, or split it into segments. Silent truncation is not among them, because it destroys data without telling anyone.

This lesson picks rejection, as the simpler and safer default. Segmentation is a real feature with real complexity, and the LSP correct behavior is whatever does not silently lose data.

Open `app/Notifications/SmsSender.php` and replace the file.

```php
<?php

namespace App\Notifications;

use App\Exceptions\Notifications\NotificationFailedException;

class SmsSender extends NotificationSender
{
    public const MAX_LENGTH = 160;

    public function send(string $recipient, string $message): string
    {
        if (! preg_match('/^\+?\d{8,15}$/', $recipient)) {
            throw new NotificationFailedException("Invalid phone number: {$recipient}");
        }

        // FIX 1: do not silently truncate. Long messages either need to
        // be split (a separate concern) or rejected loudly.
        if (strlen($message) > self::MAX_LENGTH) {
            throw new NotificationFailedException(
                'SMS message exceeds ' . self::MAX_LENGTH . ' characters'
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

Be clear about what just happened: this is a behavior change, not a refactor. Calls that used to succeed with mangled data now throw. That is the correct outcome, because the caller gets to decide what to do about a long message instead of receiving silent corruption, but it is a different kind of change from Lessons 3 and 4 and it deserves a different expectation about tests.

### Step 2: Update the Delivery Test to Match the Honest Contract

Because the behavior genuinely changed, the test has to change too. The 200 character message is no longer something all three senders can deliver; SMS now correctly refuses it.

Open `tests/Feature/NotificationSenderTest.php` and replace the second test.

```php
it('delivers the full message without truncation', function (NotificationSender $sender, string $recipient) {
    // A length every sender supports, per the limits each one declares.
    $message = 'Verification code: 482917 (valid 5 minutes)';

    $sender->send($recipient, $message);

    $entry = FakeChannelLog::all()[0];
    expect($entry['message'])->toBe($message);
})->with('senders');
```

Lesson 3 insisted that editing tests during a refactor destroys your evidence, so it is worth being precise about why this edit is legitimate. Lesson 3 was a pure refactor: behavior was meant to be identical, so any test change would have been hiding a mistake. This lesson deliberately changes behavior, and a test that asserts the old behavior *should* fail. The rule is not "never edit tests"; it is "know which kind of change you are making, and let the tests fail when behavior was supposed to change".

This edit also exposes a genuine weakness in the design, which is worth naming rather than papering over. The contract in `NotificationSender` says nothing about a maximum message length, yet every sender has one. A caller holding a `NotificationSender` reference cannot know whether its message is too long without knowing the concrete class, which is exactly the kind of hidden knowledge LSP is meant to eliminate. Two honest resolutions exist: add a `maxLength()` method to the contract so callers can ask, or promise that any length is accepted and make each sender handle it internally by segmenting. This lesson leaves the contract loose and documents the responsibility, which is a reasonable compromise. What is not reasonable is truncating in silence.

### Step 3: Fix Both Violations in PushSender

Open `app/Notifications/PushSender.php` and replace the file.

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
        // dedicated diagnostics surface, not in the success return value.
        return $this->channel();
    }

    public function channel(): string
    {
        return 'push';
    }
}
```

Both fixes preserve what the class actually does. Invalid tokens still fail, valid dispatches are still recorded. Only the shape of the failure and the shape of the success changed, which is precisely what LSP is about: the observable contract, not the internal work.

The import at the top changed from `Exception` to `NotificationFailedException`, and that one line is the whole of fix 2. It is worth noticing how small the diff is relative to how serious the bug was.

If the dispatch metadata from violation 3 is genuinely useful to somebody, the answer is to expose it properly: fire an event, write a log line, or add a separate method that callers can opt into. Smuggling it through the return value of a method whose contract promises a channel name means every caller pays for one caller's convenience.

---

## 7. Run and Test

```bash
php artisan test tests/Feature/NotificationSenderTest.php
```

```
   PASS  Tests\Feature\NotificationSenderTest
  ✓ it returns the channel name as a string on success with dataset "email sender"                                                   0.09s  
  ✓ it returns the channel name as a string on success with dataset "sms sender"                                                     0.02s  
  ✓ it returns the channel name as a string on success with dataset "push sender"                                                    0.02s  
  ✓ it delivers the full message without truncation with dataset "email sender"                                                      0.02s  
  ✓ it delivers the full message without truncation with dataset "sms sender"                                                        0.01s  
  ✓ it delivers the full message without truncation with dataset "push sender"                                                       0.01s  
  ✓ it throws NotificationFailedException on invalid recipient with dataset "email sender"                                           0.02s  
  ✓ it throws NotificationFailedException on invalid recipient with dataset "sms sender"                                             0.02s  
  ✓ it throws NotificationFailedException on invalid recipient with dataset "push sender"                                            0.02s  

  Tests:    9 passed (9 assertions)
  Duration: 0.28s
```

Nine cases, no gaps in the grid. Every sender now keeps every promise its parent made, which means a function that accepts a `NotificationSender` can be handed any of the three without surprise.

The nine cell grid is worth keeping as a habit. It is a substitutability matrix: rows are contract clauses, columns are implementations, and a filled grid is a claim you can point at during code review. When a fourth sender is added, the dataset grows by one line and the grid grows by three cells, and any promise the new sender fails to keep shows up immediately with its name attached.

---

## 8. The Four Guardrails

With the violations fixed, LSP can be stated precisely. Barbara Liskov's formal phrasing is dense, but for PHP it reduces to four rules. A subclass is substitutable only if all four hold.

**Return types.** A child may narrow the return type but never widen it. Returning `Collection` where the parent returned `iterable` is fine; the caller expected less and got more specific. The reverse breaks callers. Note that PHP checks the declared type, not the meaning, which is exactly how violation 3 slipped through: `json_encode` returns a `string`, so the declaration held while the contract did not. Type systems check types; only tests check meaning.

**Parameter types.** A child may widen a parameter type but never narrow it. Accepting `iterable` where the parent accepted `array` is fine, because every caller that worked before still works. Narrowing breaks callers that relied on the parent's wider signature. PHP enforces this one strictly at compile time, which makes it the easiest of the four to get right.

**Exception types.** A child must throw only the exception types the parent declares, or subtypes of them. Violation 2 broke this. PHP has no checked exceptions, so nothing enforces it: the contract lives in a docblock and the enforcement lives in a test.

**Preconditions and postconditions.** A child may not demand more of its callers than the parent did, nor deliver less than the parent promised. `Square::setHeight` broke a precondition by requiring that callers not care about width. `SmsSender` broke a postcondition by delivering less than the full message. These are the hardest to spot because they are not in the type system at all, and they are the most damaging in production because the code looks correct at every level a tool can inspect.

The mental check that covers all four: if a function elsewhere in the codebase knew this object only as the parent type, would my override surprise it? If yes, you have a violation, whatever the type checker says. The tests in section 5 are that question in executable form, which is why they found all three.

---

## 9. When an LSP Violation Is Worth Fixing

LSP is the principle most easily over applied. Almost every inheritance relationship in a real codebase has some imperfection, and chasing all of them produces ceremony without benefit. Three signals tell you when it matters.

**Polymorphic use.** This is the dominant signal. If your code only ever instantiates `EmailSender` directly and passes around `EmailSender` references, a flaw in `SmsSender` is irrelevant, because nothing substitutes one for the other. The moment code accepts a `NotificationSender` parameter, holds a collection of them, or resolves one from the container, any misbehaving subclass can reach any of those paths. LSP discipline should scale with how much polymorphism you actually have.

**Cost of failure.** Notification senders are high stakes precisely because their failures are quiet. A user who does not receive a message rarely files a bug; they just lose trust. Subsystems whose failures are silent deserve more discipline than subsystems that crash loudly, because loud failures are self reporting and silent ones are not.

**Breadth of the hierarchy.** One parent and one child is barely polymorphism and rarely has a meaningful LSP problem. Three or more concrete children, especially in a hierarchy the team plans to grow, is where these bugs live. The design in this lesson sits right at that threshold.

There is a fourth question worth asking whenever the fixes start to feel like a fight: what would happen if I deleted this inheritance and used composition instead? Sometimes, as with `Square`, the honest answer is that the relationship was never real.

This is where Lesson 4's design earns retrospective credit. `PaymentGateway` is an interface with independent implementations, not a base class with subclasses. No implementation inherits behavior it might accidentally contradict, because there is no behavior to inherit; each gateway starts from nothing and implements two methods. Inheritance promises behavioral compatibility that you then have to actively maintain. An interface promises only signatures, which is less, but it is a promise that cannot rot. That is a large part of why modern Laravel codebases reach for interfaces plus implementations far more often than for deep class hierarchies.

---

## 10. Common LSP Pitfalls

**Throwing `BadMethodCallException` from a method the parent declares.** A subclass announcing that it cannot honor part of its parent's contract is a textbook violation. The fix is almost never to leave the exception in place. Either the method does not belong on the contract, in which case the contract should be split, or the class is not really a subtype and should not inherit. This antipattern is the direct subject of Lesson 6.

**Overriding a method to do nothing.** Worse than throwing, because throwing at least produces a signal. An empty override lies with no observable trace: callers expect the side effect the parent promised, get nothing, and see no error. It is the truncation problem taken to its conclusion.

**Widening accepted input without widening the contract.** A child that quietly accepts both arrays and collections where the parent documented arrays sounds generous. The trouble is that the extra tolerance is undocumented and untested, so it accumulates dependents anyway. Eventually the class is swapped for another implementation of the same parent and everything that relied on the undocumented behavior breaks. Wider acceptance is fine when contracted and dangerous when accidental.

**Reaching for `instanceof` to special case a subclass.** Writing `if ($sender instanceof PushSender)` is a confession that the parent contract is insufficient and the subclasses are not truly substitutable. Occasionally unavoidable, always a prompt to revisit the design: if the special cases are rare, the contract probably needs another method; if they are frequent, the hierarchy probably should not exist.

---

## 11. Fix the Errors in Your Code

**Error 1: Testing each subclass in its own file with its own expectations.**

This is the mistake that makes every other LSP bug invisible, and it looks like thorough testing.

```php
// Wrong: the test agrees with the violation, because the same person wrote both
it('truncates long messages to the sms limit', function () {
    $sender = new SmsSender();
    $sender->send('+6281234567890', str_repeat('A', 200));

    expect(strlen(FakeChannelLog::all()[0]['message']))->toBe(160);
});

// Correct: one test, run against every sender, asserting the parent's promise
it('delivers the full message without truncation', function (NotificationSender $sender, string $recipient) {
    $message = 'Verification code: 482917 (valid 5 minutes)';

    $sender->send($recipient, $message);

    expect(FakeChannelLog::all()[0]['message'])->toBe($message);
})->with('senders');
```

The wrong version is green, thorough looking, and actively harmful: it locks the violation in place and any future developer who fixes the truncation will see a test fail and assume they broke something. Tests written per subclass encode each subclass's opinion of itself. Only tests written against the parent can catch a subclass that disagrees with its parent.

**Error 2: Instantiating dataset values directly instead of wrapping them in closures.**

```php
// Wrong: one shared instance per dataset entry across the whole file
dataset('senders', [
    'email sender' => [new EmailSender(), 'asriyanik@example.com'],
]);

// Correct: a closure, so every test case builds a fresh sender
dataset('senders', [
    'email sender' => [fn () => new EmailSender(), 'asriyanik@example.com'],
]);
```

With stateless senders like these, both forms happen to pass, which is what makes the habit worth forming before it bites. As soon as a sender holds state, a retry counter or a connection, the shared instance leaks that state between tests and produces failures that depend on test ordering. Those are among the most expensive bugs to diagnose, and the closure costs five characters.

**Error 3: Catching `Exception` in the caller to work around a subclass that throws the wrong type.**

When `PushSender` threw a generic `Exception`, the tempting fix is at the call site rather than in the sender.

```php
// Wrong: the caller widens its catch to accommodate one badly behaved subclass
try {
    $sender->send($recipient, $message);
} catch (Exception $e) {
    Log::warning('Notification failed', ['error' => $e->getMessage()]);
}

// Correct: fix the sender, and let the caller catch only what the contract declares
try {
    $sender->send($recipient, $message);
} catch (NotificationFailedException $e) {
    Log::warning('Notification failed', ['error' => $e->getMessage()]);
}
```

The wrong version does stop the crash, which is why it is tempting. It also swallows every genuine bug in the send path: a `TypeError`, a null dereference, a database failure all become a warning log and a shrug. Typed exceptions exist so that expected failures can be handled and unexpected ones can surface. Widening the catch to accommodate one misbehaving implementation throws that distinction away for every implementation.

---

## 12. Exercises

**Exercise 1:** The contract implies, without stating, that a failed send has no side effects. Write a fourth polymorphic test asserting that when `send()` throws, nothing was recorded in `FakeChannelLog`. Run it against all three senders and report whether they all pass.

**Exercise 2:** Add a `SlackSender` whose `channel()` returns `'slack'` but whose `send()` returns `ucfirst($this->channel())`. Add it to the dataset and run the suite. Which test catches it, and what does the failure output show? Then fix it.

**Exercise 3:** Section 6 noted that the contract says nothing about maximum message length, even though every sender has one. Design a fix. Write the modified `NotificationSender` contract and describe what each of the three senders would return, then state what this costs compared to leaving the contract loose.

---

## 13. Solutions

**Solution for Exercise 1:**

```php
it('records nothing when the send fails', function (NotificationSender $sender) {
    try {
        $sender->send('invalid-recipient', 'hello');
    } catch (NotificationFailedException) {
        // expected
    }

    expect(FakeChannelLog::all())->toBeEmpty();
})->with([
    'email sender' => [fn () => new EmailSender()],
    'sms sender'   => [fn () => new SmsSender()],
    'push sender'  => [fn () => new PushSender()],
]);
```

All three pass. Every sender validates its recipient before touching the log, so a rejection leaves no trace.

The `catch` with no variable is PHP 8 syntax for catching a type you do not intend to inspect. Swallowing the exception is correct here because the exception is not what this test is about; the third test in section 5 already covers that. This one is about what did *not* happen.

The exercise is really about noticing that the contract has an unstated clause. Nothing in the docblock says a failed send leaves no side effects, yet every caller assumes it, and a sender that logged before validating would break that assumption while passing all four tests except this one. Unstated promises are the ones that get broken, which is a good argument for writing this test now, before somebody adds a sender that retries mid send.

**Solution for Exercise 2:**

```php
class SlackSender extends NotificationSender
{
    public function send(string $recipient, string $message): string
    {
        if (! str_starts_with($recipient, '#')) {
            throw new NotificationFailedException("Invalid Slack channel: {$recipient}");
        }

        FakeChannelLog::record($this->channel(), $recipient, $message);

        return ucfirst($this->channel());
    }

    public function channel(): string
    {
        return 'slack';
    }
}
```

The first test catches it, and the failure output is exactly two lines of diff:

```
  Failed asserting that two strings are identical.
  -'slack'
  +'Slack'
```

The fix is to return `$this->channel()`. What makes this exercise worth doing is that the violation is one character, is invisible in review, and would produce a bug nobody could reproduce: a lookup keyed on channel name misses for Slack and only for Slack. The suite caught it the instant the sender joined the dataset, with no new test written. That is the return on having tested against the parent type.

**Solution for Exercise 3:**

Add the limit to the contract so callers can ask instead of guess.

```php
abstract class NotificationSender
{
    /**
     * Send a notification message to the given recipient.
     *
     * Contract:
     *  - The full message MUST be delivered. No silent truncation.
     *  - A message longer than maxLength() MUST be rejected with
     *    NotificationFailedException, never truncated.
     *  - On failure, MUST throw NotificationFailedException (and only that type).
     *  - MUST return the channel name as a lowercase string on success.
     */
    abstract public function send(string $recipient, string $message): string;

    abstract public function channel(): string;

    /**
     * Maximum message length this channel accepts, or null for no limit.
     */
    abstract public function maxLength(): ?int;
}
```

`SmsSender` returns `160`. `EmailSender` and `PushSender` return `null`, meaning no practical limit. A caller holding a `NotificationSender` can now check `$sender->maxLength()` before sending, or catch the exception, and either way it is making an informed decision rather than a hopeful one.

The cost is real and worth stating. Adding an abstract method is a breaking change to the hierarchy: all three existing senders must be opened and updated, and so must any sender written outside this codebase. It is also the same trade Lesson 4 identified when adding a method to `PaymentGateway`, which is not a coincidence; contracts are closed against new implementations and never against changes to their own shape.

The alternative, leaving the contract loose, costs nothing today and leaves every caller relying on knowledge the type system cannot give them. Which to choose depends on whether callers actually need to know. If they only ever send short messages, the loose contract is fine. If a caller needs to decide between SMS and email based on message length, it must be told, and telling it through the contract is the only way that does not require an `instanceof`, which section 10 identified as the smell that the contract was insufficient in the first place.

---

## Next Up - Lesson 6

You planted three lies in a class hierarchy and built a nine cell grid that found all three, each with the offending subclass named. The technique matters more than the fixes: tests written against the parent type, run across every implementation, are the only thing that catches promises PHP cannot check. You also saw why Lesson 4's interface based design was the safer starting point, and why "a square is a rectangle" is true in geometry and false in code.

Section 10 flagged an antipattern without addressing it: a subclass that throws `BadMethodCallException` from a method it was forced to declare. That is an LSP violation, but blaming the subclass misses the point. Usually the class is behaving as well as it can, and the real fault is upstream in a contract that demanded too much.

In Lesson 6 you will build that fault deliberately. A `ReportInterface` with six methods, three report classes that genuinely need only a fraction of them, and twelve stub implementations that throw or, worse, silently do nothing. Then you will split the fat interface into small capability based contracts, watch the stubs disappear entirely rather than being fixed, and see why Laravel's own `Contracts` directory is full of tiny interfaces instead of a few large ones. That is the Interface Segregation Principle.
