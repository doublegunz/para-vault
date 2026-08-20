## 1. Before You Begin

You inherit a Laravel project that has been in production for two years. The `PostController` is six hundred lines long. Adding a new field to the post creation flow means editing the controller, the form request, three different views, two scheduled jobs, and a notification class. You make the change, run the tests, and three unrelated tests fail. You fix those, push to staging, and the QA team reports that the comment notifications stopped working. None of this is unusual. It is what happens when code is written without design discipline.

The cost of that messiness is not just frustration. It is slower feature delivery, more bugs in production, longer onboarding for new team members, and a creeping fear of changing anything. Many teams respond by writing more tests, hoping to catch regressions. That helps, but tests cannot fix a structural problem; they can only flag it. The actual fix is to write code that is structured to absorb change in the first place.

SOLID is a set of five design principles for object oriented code that, when applied with judgment, give you exactly that absorptive structure. They are not magic, they are not Laravel specific, and they are not new. They are habits. This lesson is the conceptual entry point to the course, and its job is to give you a clear, working mental model of all five principles before we touch any real project code. The goal is not to memorize five definitions; the goal is to recognize each principle in the wild so you can apply it when it matters.

### What You'll Build

No project files yet. What you build in this lesson is the vocabulary. By the end you will be able to look at a controller, a service, or an interface and say which principle it is straining against, which is the skill every later lesson depends on. Lesson 2 scaffolds SolidLab, the Laravel 13 application you will refactor for the rest of the course.

### What You'll Learn

- ✅ The full meaning of the SOLID acronym and the people behind each principle
- ✅ Why each principle exists and what kind of bug or maintenance pain it prevents
- ✅ How to spot common violations in Laravel controllers, models, and services
- ✅ How Laravel's own design (service container, contracts, notification channels) embodies SOLID
- ✅ How the five principles reinforce each other in real codebases
- ✅ When applying SOLID pays off and when it becomes over engineering

### What You'll Need

- Comfort with PHP 8.3 and basic object oriented programming (classes, interfaces, inheritance)
- Working knowledge of Laravel routing, controllers, models, and Eloquent
- No project setup and no terminal. Read this lesson in one sitting, then move on to Lesson 2 when you are ready to write code

---

## 2. What SOLID Stands For

SOLID is an acronym coined by Michael Feathers and popularized by Robert C. Martin (also known as Uncle Bob) in the early 2000s. The five principles it represents were not all invented at the same time or by the same person, but they share a single concern: how to structure object oriented code so that it stays soft, meaning easy to change.

The five letters expand as follows. The S stands for the Single Responsibility Principle, attributed to Robert C. Martin in its modern form. The O stands for the Open/Closed Principle, originally articulated by Bertrand Meyer in 1988. The L stands for the Liskov Substitution Principle, derived from a 1987 keynote by Barbara Liskov on data abstraction and hierarchy. The I stands for the Interface Segregation Principle, also from Robert C. Martin. The D stands for the Dependency Inversion Principle, again from Martin's writing in the late 1990s.

The principles were not designed for any particular language or framework. They predate Laravel by more than a decade. What makes them feel native to Laravel is that Laravel itself was designed by people who internalized these principles deeply. The service container, the contracts directory, the notification channel system, the queue drivers, the broadcast drivers; all of these are textbook SOLID applied at framework scale. When you use them, you are using SOLID, even if you have never opened a SOLID book.

---

## 3. The Mindset Shift SOLID Asks For

Before walking through the five principles individually, it is worth naming the mindset shift they all push toward. Most beginner code is written to handle the case in front of you right now: this user, this form, this database table. Code written this way works. It ships. The trouble shows up the second time the requirements change.

SOLID asks you to write code with a particular kind of paranoia in mind: the requirement you are coding for today will change, and you will not be the one to change it. This is not pessimism; it is statistics. Most code in production gets modified after it is written, often by someone other than the original author, often months or years later. Code that absorbs that future change without breaking everything around it has a property the SOLID principles try to encourage. Code that does not absorb change well has properties they try to prevent.

With that frame in mind, let us go through the five.

---

## 4. Single Responsibility Principle

The Single Responsibility Principle is stated simply: a class should have one and only one reason to change. The phrase is shorter than its meaning. Many developers read "single responsibility" and translate it as "do one thing". That translation is wrong, and chasing it leads to either too few classes (because "save and email a user" feels like one thing) or absurdly many classes (because you split every helper into its own file).

A more useful translation is the one Uncle Bob himself prefers in newer writing: a class should be responsible to one, and only one, actor. An actor is a person, role, or system that has the authority to request a change. If your `InvoiceController` calculates totals (the finance team's concern), generates a PDF (the design team's concern), sends an email (the marketing team's concern), and writes to an audit log (the compliance team's concern), then four different actors can request a change to that class. Sooner or later, two of them will request changes that conflict. That is the moment SRP is trying to prevent.

Here is the shape of the problem, compressed. Read the method and count the actors.

```php
public function store(Request $request)
{
    $data = $request->validate([...]);          // actor: the API consumer
    $subtotal = collect($data['items'])->sum(fn ($i) => $i['qty'] * $i['price']);
    $total = $subtotal * 1.11;                  // actor: the finance team (tax rate)
    $invoice = Invoice::create([...]);          // actor: the DBA (schema)
    $pdf = $this->buildPdf($invoice);           // actor: the design team (layout)
    Mail::to($invoice->email)->send(...);       // actor: the marketing team (copy)
    Log::channel('audit')->info(...);           // actor: the compliance team
}
```

Six lines of real work, and six different people in the organization can walk up to your desk and ask for a change to this one method. Each of those requests risks breaking the other five. Nothing here is technically wrong; the code runs, the tests pass, the feature ships. The problem is entirely structural, and it only bills you later.

In Laravel, SRP shows up as a balance between thin controllers, form requests for validation, services or actions for business logic, jobs for asynchronous work, and notifications for user communication. None of this is enforced by the framework. You can absolutely cram all of it into a single controller method, and Laravel will run it. The framework simply gives you the tools to split responsibilities cleanly when you decide to. SRP is the principle that helps you decide.

A simple way to feel for an SRP violation is to write the description of a class out loud. If the description requires the word "and" more than once, you are probably looking at a class with multiple reasons to change. "The InvoiceController validates input *and* calculates totals *and* persists the record *and* generates a PDF *and* sends an email." That is five responsibilities, and Lesson 3 will refactor exactly that controller.

---

## 5. Open/Closed Principle

The Open/Closed Principle, originally written by Bertrand Meyer, says that software entities should be open for extension but closed for modification. The phrase is paradoxical on first read: how can something be both open and closed? The answer is that "open" and "closed" refer to different things. The class is closed to having its source code modified, but it is open to having new behavior added through extension mechanisms like inheritance, composition, or interface implementation.

The pain that OCP prevents is regression. Every time you open a tested, working class to add a new feature, you risk breaking something that already worked. The risk is small for one change, but it compounds. After a year of opening the same `PaymentService` class to add Paypal, then Stripe, then Midtrans, then a coupon system, then a wallet, you have a class that nobody trusts to change without a full regression test pass.

The classic smell is a dispatch chain that grows every quarter.

```php
public function charge(string $gateway, int $amount): array
{
    if ($gateway === 'paypal') {
        return $this->chargePaypal($amount);
    } elseif ($gateway === 'stripe') {
        return $this->chargeStripe($amount);
    }

    throw new InvalidArgumentException("Unknown gateway: {$gateway}");
}
```

Every new gateway means opening this file, adding a branch, and re-running every payment test to prove you did not disturb the existing branches. The file grows monotonically and its blast radius grows with it.

OCP says: structure the class so that adding the next payment method does not require opening the existing class at all. You add a new file, register it, and the existing tested code stays untouched. In Laravel, this often takes the shape of an interface (such as `PaymentGateway`) with one implementation per gateway. The service that uses the interface never knows or cares which implementation is plugged in.

It is important to be honest about OCP: you cannot make code closed against every possible change. If a new payment gateway needs a fundamentally different concept, like multi step approvals, you may have to widen the interface. OCP is not about closing all change; it is about closing the kinds of change you can predict. Most of the time, "we will need another payment method" is predictable, so designing for it pays off. "We will need to fundamentally rethink payments" usually is not, and over engineering for that is what gives SOLID a bad name.

Lesson 4 will take a `PaymentService` with exactly this if/else block and refactor it into an OCP compliant design with three gateways, then add a fourth without touching the original code.

---

## 6. Liskov Substitution Principle

The Liskov Substitution Principle is the trickiest of the five to get right, in part because its formal statement is dense. Barbara Liskov's original phrasing was: if S is a subtype of T, then objects of type T may be replaced with objects of type S without altering any of the desirable properties of the program. Translated into code: if `B` extends `A`, then any code that works correctly with an `A` instance must continue to work correctly when handed a `B` instance, with no surprises.

This sounds obvious until you realize how often subclasses break it. The classic example is a `Bird` class with a `fly()` method, and an `Ostrich` subclass that throws an exception when `fly()` is called because ostriches do not fly.

```php
class Bird
{
    public function fly(): string
    {
        return 'flying';
    }
}

class Ostrich extends Bird
{
    public function fly(): string
    {
        throw new RuntimeException('Ostriches cannot fly');
    }
}

function migrate(Bird $bird): string
{
    return $bird->fly();   // works for Bird, explodes for Ostrich
}
```

Syntactically, `Ostrich` is a `Bird`. PHP will accept it, static analysis will accept it, the type hint is satisfied. Semantically the substitution broke, and it broke at runtime inside a function that never mentioned ostriches.

In Laravel codebases, LSP violations rarely look like ostriches. They look like a repository implementation that returns an Eloquent `Collection` while another implementation of the same interface returns a plain array. They look like a notification sender that silently truncates messages over a certain length while its sibling sender does not. They look like a child class that throws a different exception type than its parent declares. All of these will pass type checks. None of them will break loudly during code review. They will break months later when someone swaps the implementation in a service container binding and a code path nobody thought to test misbehaves.

The practical guardrails for LSP in PHP are: keep return types consistent (a child can narrow them, but never widen), keep parameter types consistent (a child can widen them, but never narrow), throw the same exception types that the parent declares, and honor the same preconditions and postconditions. Lesson 5 will demonstrate all four guardrails by building a notification system that violates them and then fixing each violation in turn.

---

## 7. Interface Segregation Principle

The Interface Segregation Principle says that no client should be forced to depend on methods it does not use. Stated as a positive: prefer many small, focused interfaces over a few large, general purpose ones.

The pain ISP prevents is the empty implementation. You have a `ReportInterface` that requires `generatePdf()`, `generateExcel()`, `scheduleDaily()`, and `archiveToS3()`. You add a new `SimpleSalesReport` class that only needs to produce a PDF. To satisfy the interface, you have two bad options.

```php
class SimpleSalesReport implements ReportInterface
{
    public function generatePdf(): string
    {
        return 'the one thing this class actually does';
    }

    public function generateExcel(): string
    {
        throw new BadMethodCallException('Not supported');  // option one: crash
    }

    public function scheduleDaily(): void
    {
        // option two: silently do nothing, which is worse
    }

    public function archiveToS3(): void
    {
        //
    }
}
```

Both options are bad. The first violates LSP, because substituting `SimpleSalesReport` where the interface is expected will crash. The second creates landmines that surface only when the methods are actually called, possibly in production, possibly months later, with no error to trace.

The fix is to split the fat interface into focused ones. `Reportable` for the rendering, `Schedulable` for scheduling, `Archivable` for archival. A class that only generates a PDF implements only `Reportable`. A class that needs all three implements all three. Nothing is forced to declare capabilities it does not have.

Laravel's own Contracts directory is a master class in ISP. Look at the framework source and you will find separate small contracts for `Cache\Repository`, `Cache\Lock`, `Cache\Store`, `Cache\Factory`, and so on, rather than a single bloated `Cache` interface that tries to cover everything. This is not an accident. Lesson 6 will walk through a fat reporting interface and split it apart, with Pest tests demonstrating that the split removes the need for stub implementations.

---

## 8. Dependency Inversion Principle

The Dependency Inversion Principle has two parts. First: high level modules should not depend on low level modules; both should depend on abstractions. Second: abstractions should not depend on details; details should depend on abstractions.

The everyday way to feel for DIP is to ask: when this class needs another class, does it grab a specific implementation, or does it ask for an abstraction and let someone else decide which implementation to plug in?

```php
// Depends on a low level detail. Untestable without the network.
class NewsletterController
{
    public function subscribe(Request $request)
    {
        $provider = new MailchimpProvider(config('services.mailchimp.key'));

        return $provider->subscribe($request->input('email'));
    }
}

// Depends on an abstraction. The container decides what gets injected.
class NewsletterController
{
    public function __construct(private NewsletterProvider $provider) {}

    public function subscribe(Request $request)
    {
        return $this->provider->subscribe($request->input('email'));
    }
}
```

The first controller is welded to the Mailchimp HTTP client. The second names only what it needs, a thing that can subscribe an email address, and the actual provider is bound elsewhere, usually in a service provider, and can be swapped without touching the controller.

The benefit is most visible at test time. If your controller `new`s up Mailchimp, your test cannot run without either an internet connection or a heavy stubbing setup. If your controller depends on an interface, your test binds a fake implementation in two lines and runs in milliseconds. The same flexibility that makes the code testable also makes it adaptable: switching from Mailchimp to Sendgrid becomes a one line change in a service provider, not a search and replace across the codebase.

DIP is the principle most directly served by Laravel's service container. The container exists to resolve dependencies for you, to bind interfaces to concrete classes, and to swap those bindings at runtime. When you type hint an interface in a controller constructor and Laravel injects a working implementation, you are using DIP. Lesson 7 will refactor a tightly coupled newsletter controller into a DIP compliant design and show how the container, service providers, and contextual binding fit together.

It is worth saying clearly: DIP, dependency injection, and inversion of control are three different things, and Lesson 7 will untangle them. For now, hold this loose mental model: DIP is the principle (depend on abstractions), dependency injection is the technique (pass dependencies in, do not new them up), and inversion of control is the mechanism (a container resolves and wires things for you).

---

## 9. How the Principles Work Together

The five principles are easier to absorb individually, but they are not five independent rules. They reinforce each other, and applying one tends to push you toward the others.

SRP enables OCP. A class that has one responsibility is much easier to leave alone when adding new behavior; you add the new behavior in a new class. A class with many responsibilities tempts you to keep cramming new behavior in, because there is already so much in there.

OCP demands LSP. The whole point of OCP is that you can swap one implementation for another behind a stable abstraction. That swap only works if the new implementation truly behaves like the old one. Without LSP, OCP becomes a lie: you appear to have pluggable strategies, but plugging in the wrong one breaks everything.

ISP supports LSP. Smaller, more focused interfaces are easier to implement faithfully. A class that only has to implement two methods is much less likely to fudge one of them than a class that has to implement ten.

DIP makes the previous four enforceable. Without dependency inversion, your high level modules import concrete low level modules directly, and SRP, OCP, LSP, and ISP all become guidelines you cannot really enforce. With dependency inversion, the abstractions become the contract that the other principles hang off of.

A practical consequence: when you refactor toward one principle and feel another principle starting to make sense too, that is the system working as designed. You are not doing extra work; you are doing one body of work that pays off in five different ways. Lesson 8 makes this explicit by applying all five to a single feature in one pass.

---

## 10. When to Apply SOLID and When Not To

A common failure mode of developers who have just discovered SOLID is to apply every principle to every class, regardless of context. This produces code that is technically pure and practically painful: ten files where two would do, three layers of abstraction over a function that has one implementation and will only ever have one, contracts written for code that is not under any change pressure.

The honest framing is that SOLID has a cost. Every interface you introduce is a file someone has to read. Every binding in a service provider is a line someone has to follow when tracing a bug. These costs are paid up front. The benefits arrive later, when the code needs to change. If the code never needs to change much, you paid the cost for nothing.

A reasonable rule of thumb: apply SOLID where change is likely, and skip it where change is unlikely. A `PaymentService` that has been rewritten three times in two years is screaming for OCP. A throwaway script that imports a CSV one time is fine as a single function. A model with a complex set of business rules that different teams own is a candidate for SRP. A simple Eloquent model that holds five fields and three relationships is fine as it is.

Watch for these signals that SOLID is paying off: features that used to take days now take hours, changes that used to break unrelated tests no longer do, new team members can extend the system without reading the whole codebase first. Watch for these signals that SOLID has been overapplied: simple changes require touching five files, the abstractions have only one implementation each and have never been swapped, the codebase has more interfaces than concrete classes.

---

## 11. Common Misconceptions

A few persistent misunderstandings deserve direct callouts before we move into the practical lessons.

SOLID is not the same as "use lots of interfaces". You can satisfy several SOLID principles without writing a single interface, particularly in small applications where the strategies and bindings would be over engineering. Interfaces are a tool that helps; they are not the goal.

SOLID does not require any specific architecture. Hexagonal architecture, clean architecture, and onion architecture are all heavily SOLID influenced, but you can write SOLID code in a plain Laravel MVC project, in a single file, or in a hexagonal architecture. The architectures are opinionated containers for the principles, not the principles themselves.

SOLID is not a dogma. The principles are guidelines, sometimes in tension with each other, sometimes outweighed by other concerns like performance, simplicity, or shipping a deadline. A senior engineer applies SOLID with judgment; a junior engineer applies it as gospel. Aim for the senior posture.

SOLID does not mean writing more code. Done well, applying SOLID often results in less total code, because removing duplication and structuring responsibilities clearly tends to shrink things. If your SOLID refactor doubles the line count, something has probably gone wrong.

---

## 12. Your Course Roadmap

The next lessons each take one principle and demonstrate it on a realistic Laravel 13 codebase. Everything is built inside a single application called SolidLab, which you scaffold in Lesson 2. Every principle lesson uses Pest for tests, ships a baseline test run before the refactor, and shows the same tests passing after the refactor. Each lesson uses a different feature area of SolidLab, so the code you write never collides with the code from a previous lesson.

Lesson 2 sets up SolidLab, removes the pieces that get in the way of readable test output, and teaches you to read a Pest run. It is short, and it is the only lesson with no refactoring in it.

Lesson 3 covers the Single Responsibility Principle by refactoring a bloated invoice controller. You will start with a single controller method that calculates totals, persists, generates a PDF, sends an email, and logs an audit entry, then split it into a calculator, a repository, a PDF generator, and a mailer.

Lesson 4 covers the Open/Closed Principle by building an extensible payment gateway system. You will start with a service that uses an if/else block to dispatch to Paypal or Stripe, then refactor it to a `PaymentGateway` contract, and add Midtrans as a third gateway without modifying the existing service or its tests.

Lesson 5 covers the Liskov Substitution Principle by exposing and fixing violations in a notification sender hierarchy. You will see how a child class that silently truncates messages or throws different exception types breaks code that depends on the parent contract, and you will fix each violation explicitly.

Lesson 6 covers the Interface Segregation Principle by splitting a fat reporting interface into focused contracts. You will see exactly the kind of `BadMethodCallException` driven design that ISP exists to prevent, and you will refactor it into a small set of capability based interfaces.

Lesson 7 covers the Dependency Inversion Principle by refactoring a tightly coupled newsletter subscription controller. You will untangle DIP from dependency injection and inversion of control, build a `NewsletterProvider` contract, swap implementations in a service provider, and write tests that run without ever touching a real third party API.

Lesson 8 applies all five principles to one feature in a single pass and gives you a code review checklist. Lesson 9 closes the course and points at where to go next.

---

## 13. Fix the Errors in Your Code

The five principles are misread in predictable ways. These three misreadings are the ones that do the most damage, because each of them feels like following the principle while actually working against it.

**Error 1: Reading SRP as "one method per class" and shattering the code into fragments.**

The word "responsibility" gets read as "action", so every verb becomes a class. The result is a codebase where following one request means opening nine files, and none of those files is easier to change than the original.

```php
// Wrong: one class per verb, split by mechanics rather than by actor
class InvoiceSubtotalAdder { public function add(array $items): float {} }
class InvoiceTaxMultiplier { public function multiply(float $n): float {} }
class InvoiceDiscountSubtractor { public function subtract(float $n): float {} }
class InvoiceRounder { public function round(float $n): float {} }

// Correct: one class per actor. The finance team owns all of this arithmetic.
class InvoiceCalculator
{
    public function subtotal(array $items): float {}
    public function tax(float $subtotal): float {}
    public function discount(float $subtotal, ?string $code): float {}
}
```

The correct version has four methods and one reason to change: the finance team changing how money is computed. The wrong version has four reasons to open your editor and still only one actor. Split by who asks for changes, not by how many verbs you can find.

**Error 2: Introducing an interface with exactly one implementation and calling it OCP.**

OCP is about closing predictable change. An abstraction over something that has never varied and shows no sign of varying is pure cost: an extra file, an extra binding, an extra hop when reading a stack trace.

```php
// Wrong: an interface invented for a class with one implementation and no second one in sight
interface UserFullNameFormatterInterface
{
    public function format(User $user): string;
}

class UserFullNameFormatter implements UserFullNameFormatterInterface
{
    public function format(User $user): string
    {
        return "{$user->first_name} {$user->last_name}";
    }
}

// Correct: it is one line of formatting logic that nobody has ever asked to vary
class User extends Model
{
    public function fullName(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }
}
```

Ask the question honestly: has this varied, or is it likely to? If the answer is no, the concrete class is the correct design, and you can extract the interface on the day a second implementation actually appears.

**Error 3: Type hinting an interface while still constructing the concrete class inside.**

This one is the most deceptive, because the constructor signature looks inverted. The dependency is still hard wired; you just moved the `new` a few lines down.

```php
// Wrong: the type hint is decoration, the class still decides which implementation runs
class NewsletterService
{
    private NewsletterProvider $provider;

    public function __construct()
    {
        $this->provider = new MailchimpProvider(config('services.mailchimp.key'));
    }
}

// Correct: the class names what it needs and lets the container supply it
class NewsletterService
{
    public function __construct(private NewsletterProvider $provider) {}
}
```

The test is simple. Can a caller hand this class a different implementation without editing the class? In the wrong version, no. In the correct version, yes, which is the entire point of DIP.

---

## 14. Exercises

**Exercise 1:** Name the principle each of these violates, and say why in one sentence. (a) A `UserController::store` method that validates, saves, uploads an avatar, sends a welcome email, and pushes to an analytics API. (b) An `ExportService::export` method with a `match` block over `'csv'`, `'xlsx'`, and `'pdf'` that gains a branch every quarter. (c) A `CachedUserRepository::find()` that returns `null` on a miss while the interface's other implementation throws `ModelNotFoundException`.

**Exercise 2:** Take a controller from a project you have actually worked on and write a one sentence description of it out loud, exactly as described in section 4. Count the number of times you needed the word "and". Then list the actors, meaning the real people or teams who could request each of those behaviors to change. Write down how many actors you found.

**Exercise 3:** Here is a fat interface. Split it into focused contracts and state which classes would implement which.

```php
interface StorageInterface
{
    public function put(string $path, string $contents): bool;
    public function get(string $path): string;
    public function delete(string $path): bool;
    public function temporaryUrl(string $path, int $minutes): string;
    public function setVisibility(string $path, string $visibility): bool;
}
```

Assume you have three implementations: `LocalStorage` (no temporary URLs, no visibility), `S3Storage` (all five), and `ReadOnlyArchiveStorage` (only reads).

---

## 15. Solutions

**Solution for Exercise 1:**

(a) Single Responsibility Principle. Five different actors (the API consumer, the DBA, the design team, the marketing team, the analytics team) can each demand a change to that one method, so it has five reasons to change.

(b) Open/Closed Principle. Adding a format requires opening and re-testing a class that already works, which is the definition of being open for modification rather than closed.

(c) Liskov Substitution Principle. Two implementations of the same interface disagree about what happens on a miss, so code written against one will break when the other is substituted, even though both satisfy the type hint.

Notice that (a) and (b) are about structure you can see by reading one file, while (c) is only visible when you compare two files. That is why LSP violations survive code review so often.

**Solution for Exercise 2:**

There is no single correct answer here, but there is a correct interpretation of your result. One or two "and"s is normal and usually fine. Four or more, combined with three or more distinct actors, means the class is a merge conflict waiting to happen: two teams will eventually request changes that pull the same method in opposite directions.

The actor count matters more than the "and" count. A method that validates *and* saves *and* returns a response has three verbs but arguably one actor, the API consumer, and splitting it buys you little. A method that computes tax *and* renders a PDF has two verbs and two actors, finance and design, and splitting it buys you a lot. Verbs are cheap; actors are the signal.

**Solution for Exercise 3:**

Split by capability, not by category, and let each class declare only what it can honestly do.

```php
interface Readable
{
    public function get(string $path): string;
}

interface Writable
{
    public function put(string $path, string $contents): bool;
    public function delete(string $path): bool;
}

interface SignsUrls
{
    public function temporaryUrl(string $path, int $minutes): string;
}

interface ControlsVisibility
{
    public function setVisibility(string $path, string $visibility): bool;
}

class LocalStorage implements Readable, Writable {}
class S3Storage implements Readable, Writable, SignsUrls, ControlsVisibility {}
class ReadOnlyArchiveStorage implements Readable {}
```

`ReadOnlyArchiveStorage` is the class that proves the split was worth it. Under the original interface it needed three methods that throw or silently lie. Under the split it implements one method, honestly, and the type system now prevents anyone from passing it to code that intends to write.

Note that `put` and `delete` stayed together in `Writable`. Segregation does not mean one method per interface; it means grouping methods that clients actually use together. No caller in practice wants the ability to write without the ability to delete, so splitting those further would add files without removing a single forced implementation.

---

## Next Up - Lesson 2

You now have the vocabulary. You can name all five principles, explain the pain each one prevents, recognize the classic violation shapes in Laravel code, and, just as importantly, argue against applying a principle when the change pressure is not there. That last skill is what separates a useful application of SOLID from a ceremonious one.

In Lesson 2 we leave the theory behind. You will scaffold SolidLab, the Laravel 13 application that carries the rest of this course, configure it with SQLite and Pest, remove the one default package that makes test output unreadable, and run your first green baseline. It is a short lesson, but every refactor from Lesson 3 onward depends on the setup you do there.
