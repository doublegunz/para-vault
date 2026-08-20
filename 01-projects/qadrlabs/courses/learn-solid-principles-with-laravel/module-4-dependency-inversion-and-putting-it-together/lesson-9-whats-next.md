## 1. Before You Begin

You started this course with a definition problem: five principles, five one line summaries, and no reliable way to tell whether the code in front of you was violating any of them. Eight lessons later you have refactored six feature areas, planted and caught three deliberate contract violations, deleted twelve stub methods that a bad interface manufactured, and found a money losing bug that a green test suite could not see.

This lesson does not add code. It collects what SolidLab actually demonstrates, separates the parts worth carrying into your own projects from the parts that were teaching scaffolding, and points at where to go next.

### What You'll Take Away

- ✅ A one page summary of all five principles as questions rather than definitions
- ✅ An honest account of which parts of SolidLab are production shaped and which are not
- ✅ The habits that outlast the acronym
- ✅ Concrete next steps, including the courses that pick up where this one stops

### What You'll Need

- SolidLab with Lessons 2 through 8 complete and its suite green
- Half an hour and a project of your own to look at with fresh eyes

---

## 2. What You Built

SolidLab is one Laravel 13 application containing six feature areas, each of which started broken in an instructive way.

The **invoicing** area began as a ninety line controller method with six actors able to demand changes to it, and became a coordinator delegating to a calculator, a repository, a PDF generator, and a mailer. The **payments** area began as an `if/elseif` chain and became a registry of gateways resolved through container tagging, where the third gateway cost one file and one line. The **notifications** area was built with three deliberate lies in it, and a nine cell polymorphic test grid found all three with the offending class named. The **reporting** area had eighteen method declarations of which twelve were stubs, and finished with six honest ones behind capability contracts. The **newsletter** area was welded to Mailchimp inside a request handler, and finished behind a contract with three implementations and a container binding driven by one config value. The **shipping** area carried all five defects at once and was worked through in a deliberate order.

The numbers at the end: thirteen contracts in `app/Contracts`, fifty six PHP files under `app/`, and a suite of forty seven tests with a hundred and fifteen assertions that runs in about a second and a third.

That last figure is worth dwelling on. SolidLab talks to two payment providers, three notification channels, two newsletter APIs, two shipping carriers, a mail system, and a filesystem. Its entire test suite finishes faster than a single real HTTP request to any of them. Nothing about that speed came from a testing trick; it came from every integration sitting behind a contract with a fake or a framework provided double on the other side. When people say SOLID pays off in testability, this is the specific thing they mean.

---

## 3. The Five Principles as Questions

Definitions are hard to apply while reading code. Questions are not. This is the section 12 checklist from Lesson 8, condensed to the form worth memorizing.

**Single Responsibility.** Who can ask for this file to change? Count the roles, not the verbs. Two or more distinct owners in one class is a split waiting to happen.

**Open/Closed.** When the next one arrives, do you write a file or edit one? An `if/elseif` or `match` over a type string is the reliable tell.

**Liskov Substitution.** Would a caller holding only the contract be surprised by this implementation? Check return shapes, exception types, and the promises in the docblock.

**Interface Segregation.** Does any implementation lie? Look for `BadMethodCallException`, empty bodies, and methods no implementation supports at all.

**Dependency Inversion.** Could a test replace this collaborator? If not, neither can production.

And the two questions that stop the five from being over applied: what did you deliberately choose not to change, and is anything here actually under change pressure?

---

## 4. The Habits That Outlast the Acronym

Five years from now you may not remember which letter stands for which principle. These habits are the part that keeps working.

**Write the bad version first, then change it.** Every lesson in this course built the painful thing on purpose. That was not a teaching gimmick; it is how refactoring works. A design decision you have not felt the need for is a guess.

**Freeze a baseline before you touch anything.** Both numbers, tests and assertions. Lesson 3's refactor was provable only because 6 passed, 19 assertions existed before it started. A green run after a change tells you the code passes tests now; it cannot tell you the behavior is unchanged.

**Test the contract, not the implementation.** The single most transferable technique in this course is Lesson 5's dataset grid: type hint the parent or the interface, run every implementation through it, assert what the contract promised. It found all three planted violations, it caught the Slack sender in an exercise the moment it joined the dataset, and it is what the shipping feature's original suite was missing.

**Know which kind of change you are making.** A refactor must not change behavior, so a failing test means you broke something. A bug fix or a contract change is supposed to change behavior, so a failing test is the system working. Lessons 3 and 5 differ on whether editing a test is legitimate, and the difference is entirely which kind of change was underway.

**Say what you left alone.** The audit log stayed inline in Lessons 3 and 8. Validation stayed in the controller. Tracking code generation stayed a private method. Each was a decision with a reason, and a refactor with no explicit list of non actions has usually been over applied.

**Design contracts from the consumer's side.** `NewsletterProvider::subscribe()` returns a string because that is what the controller needs, not because either vendor returns one. Contracts generalized upward from whichever implementation was written first carry that implementation's assumptions forever.

---

## 5. What SolidLab Is Not

Being clear about the scaffolding matters, because copying it into production would be a mistake.

The **fakes that are static classes**, `FakeChannelLog`, `FakeScheduleLog`, and `FakeDispatchLog`, are shortcuts. Static mutable state shared across tests is a real smell, mitigated here only by `beforeEach` resets. `FakeNewsletterProvider` and `FakeDispatchNotifier` show the better pattern: an instance, injected through the container, inspected directly by the test.

The **PDF and label generators write text files**, not PDFs. Substituting a real library changes one private method in each, which was the design's point, but nothing here is a rendering tutorial.

The **payment gateways return `random_int` transaction IDs** and never touch a network. Real integrations need timeouts, retries, idempotency keys, and webhook handling, none of which this course covers and all of which live inside the implementations rather than in the contracts.

The **repositories are thin on purpose.** `InvoiceRepository` and `ShipmentRepository` wrap Eloquent with two methods each. That was enough to move persistence out of a controller. It is not the full repository pattern, and Lesson 3 said so at the time.

The **audit logging is a `Log::info` line.** A real compliance trail needs its own storage, retention, and probably a model observer or queued job, which Lesson 3's Exercise 2 worked through without implementing.

None of these are oversights. Each one is a place where the lesson chose to keep the example small enough to read in one sitting, and knowing where those lines were drawn is part of using the code responsibly.

---

## 6. Where to Go Next

**Apply the checklist to code you own.** Pick the file in your current project that you dread opening. Run the five questions over it, write down the answers, and write down what you would leave alone. That last list is usually longer than people expect, which is the point.

**Read Laravel's own contracts.** Open `Illuminate/Contracts` in your vendor directory and read `Cache`, `Filesystem`, and `Support`. Lesson 6 described that directory as a catalogue of tiny capabilities; seeing it directly is more convincing than any explanation. `Illuminate\Contracts\Support\Arrayable` is one method, and half the framework depends on it.

**Add static analysis.** PHPStan or Larastan reads the type hints you wrote in Lessons 6 and 7 and reports mismatches before the code runs. Lesson 6's solution noted that the `TypeError` from passing a `DataExportReport` to `renderPdf` fires at call time; a static analyser turns that into a build time guarantee. The two together are what make narrow interfaces genuinely safe.

**Learn the patterns these principles point at.** Every refactor in this course arrived at a shape that has a name. The payment gateway registry is the Strategy pattern. `ShipmentLabeler` wrapping `ShipmentService` is Facade in miniature. The capability probing in `processAvailable` is close to Visitor's motivation. The qadrlabs course "Design Patterns in PHP" covers all twenty three Gang of Four patterns in modern PHP 8, and its own Lesson 2 revisits SOLID in framework free PHP, which is a useful second angle on the same material: everything you learned here holds without a container to lean on.

**Go deeper on testing.** This course used Pest for one job, proving refactors were behavior preserving. Datasets, fakes, and container swapping barely scratch it. "Learn Laravel: Beyond the Basics" has two lessons on Pest that cover feature and unit testing properly, along with queues, events, and authorization, all of which are places where these principles show up again.

**Read the source of the arguments.** Robert C. Martin's *Clean Architecture* is where the actor based reading of SRP comes from, and it is more useful than the original *Clean Code* on this specific topic. Barbara Liskov's 1987 keynote on data abstraction and hierarchy is short and worth reading once, if only to see how much of Lesson 5 was already there.

---

## 7. Exercises

**Exercise 1:** Take the file you dread most in a project you own and run the Lesson 8 checklist over it. Write the five answers plus your deliberate non actions. Then pick exactly one finding to act on, and say why that one first.

**Exercise 2:** Find a class in your own code with two or more implementations, or an abstract class with two or more children. Write a Pest dataset test that type hints the parent or interface and asserts one promise every implementation should keep. Report whether it went green on the first run.

**Exercise 3:** Search your codebase for `new ` followed by a class that talks to a network, a filesystem, a queue, or an external API. For each hit, answer one question: could a test replace it? List the ones where the answer is no, and rank them by how often that code changes.

---

## 8. Solutions

**Solution for Exercise 1:**

There is no single right answer, but there is a right shape for it. Two or three findings, several explicit non actions, and one of the findings marked conditional on business context.

On which finding to act on first, Lesson 8 section 11 gave the ordering rule: correctness, contracts, structure, wiring. If any of your findings is an LSP issue where one implementation quietly does less than its siblings, that goes first, because it is a bug rather than an inconvenience. If not, the usual highest value first move is whichever finding is blocking a change you already know is coming. A finding with no pending change behind it is a note, not a task.

The most common mistake is producing a page of findings on a file that is merely unfamiliar rather than badly designed. If the checklist flags everything, it is being used as a style guide.

**Solution for Exercise 2:**

The test itself is mechanical once you have the shape:

```php
dataset('implementations', [
    'first'  => [fn () => new FirstImplementation()],
    'second' => [fn () => new SecondImplementation()],
]);

it('keeps the promise the contract makes', function (TheContract $subject) {
    // assert one clause of the contract, phrased so it is true of every implementation
})->with('implementations');
```

The interesting part is the result. If it goes green on the first run, you have learned something real: those implementations genuinely agree, and you now have a regression guard that will catch the third one when somebody adds it.

If it goes red, look carefully before fixing the implementation, because Lesson 8 section 5 showed the other possibility. Sometimes the implementation is right about the domain and the contract is the thing that was written by looking at one case. `PosCarrier` was not wrong that Pos bills whole kilograms; it was wrong about the direction, and the contract was wrong to forbid rounding at all.

Writing the test at all is most of the value. The promise you have to articulate in order to assert it is usually a promise nobody had ever written down.

**Solution for Exercise 3:**

The ranking is what matters, and the ordering criterion is change frequency rather than severity.

A `new` that constructs a payment provider, a notification service, or anything with a vendor's name in it is worth inverting, because those change: vendors get replaced, contracts get renegotiated, and the code needs a fake to be testable at all. A `new` that constructs a date formatter or a value object is fine where it is, however many of them there are.

Watch for the false positive Lesson 8's Exercise 3 raised. A facade the framework already provides a swap for, `Storage`, `Mail`, `Http`, `Queue`, is not the same problem as `new MailchimpProvider()`. The dependency is on a framework seam that already has a test double, so the practical cost of leaving it is close to zero. Inverting those first is a common way to spend a refactoring budget on nothing.

If the honest answer is that nothing on your list changes often, that is a legitimate finding too, and the correct action is to write it down and move on.

---

## 9. Closing

SOLID gets taught as five rules and remembered as an exam question. It is more useful as five questions you ask while reading a diff, and the questions are worth more than the definitions because they can be answered about specific code in front of you.

What the eight lessons before this one were really teaching is a loop. Write the version that hurts. Cover it with tests that assert behavior rather than structure, and freeze both numbers. Change the structure. Run the same tests. If the numbers match, the behavior held and the design improved, and you can do that on a Friday afternoon without fear. That loop is independent of Laravel, independent of PHP, and independent of whether you can name which letter you just applied.

The other half is judgment, and it is the half that separates a useful application of these ideas from a ceremonious one. A discount rule that has not changed in two years does not need a strategy contract. An interface with one implementation and no fake is a file you pay for and never use. A one line log call is not a responsibility. Every lesson here left something deliberately unrefactored, and those decisions were as much a part of the work as the extractions.

You have SolidLab as a reference, a checklist that fits on one screen, and the habit of asking who can demand a change to this file. That is enough to start applying it to code that matters, which is the only place any of it counts.
