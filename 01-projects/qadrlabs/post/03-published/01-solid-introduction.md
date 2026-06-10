You inherit a Laravel project that has been in production for two years. The PostController is six hundred lines long. Adding a new field to the post creation flow means editing the controller, the form request, three different views, two scheduled jobs, and a notification class. You make the change, run the tests, and three unrelated tests fail. You fix those, push to staging, and the QA team reports that the comment notifications stopped working. None of this is unusual. It is what happens when code is written without design discipline.

The cost of that messiness is not just frustration. It is slower feature delivery, more bugs in production, longer onboarding for new team members, and a creeping fear of changing anything. Many teams respond by writing more tests, hoping to catch regressions. That helps, but tests cannot fix a structural problem; they can only flag it. The actual fix is to write code that is structured to absorb change in the first place.

SOLID is a set of five design principles for object oriented code that, when applied with judgment, give you exactly that absorptive structure. They are not magic, they are not Laravel specific, and they are not new. They are habits. This article is the first in a six part series, and its job is to give you a clear, working mental model of all five principles before we touch any code in the next articles. The goal is not to memorize five definitions; the goal is to recognize each principle in the wild so you can apply it when it matters.

## Overview {#overview}

This is the conceptual entry point to the series. It establishes shared vocabulary so that when later articles say "this controller violates SRP" or "we are extracting a contract to satisfy DIP", the words land. There is no project setup, no migrations, no Pest tests in this article; those start in Article 2. The next five articles will refactor real Laravel code, and you will need a feel for what each principle is actually pointing at before you can refactor toward it.

### What You'll Take Away
- A working definition of each of the five SOLID principles in your own words
- The ability to spot common violations in Laravel controllers, models, and services
- A sense of how the principles reinforce each other in real codebases
- A judgment about when to apply SOLID and when applying it would be over engineering

### What You'll Learn
- The full meaning of the SOLID acronym and the people behind each principle
- Why each principle exists and what kind of bug or maintenance pain it prevents
- How Laravel's own design (service container, contracts, notification channels) embodies SOLID
- The most common misinterpretations of each principle

### What You'll Need
- Comfort with PHP 8.3 and basic object oriented programming (classes, interfaces, inheritance)
- Working knowledge of Laravel routing, controllers, models, and Eloquent
- No project setup. Read this article in one sitting, then move on to Article 2 when you want to refactor real code

## What SOLID Stands For {#what-solid-stands-for}

SOLID is an acronym coined by Michael Feathers and popularized by Robert C. Martin (also known as Uncle Bob) in the early 2000s. The five principles it represents were not all invented at the same time or by the same person, but they share a single concern: how to structure object oriented code so that it stays soft, meaning easy to change.

The five letters expand as follows. The S stands for the Single Responsibility Principle, attributed to Robert C. Martin in its modern form. The O stands for the Open/Closed Principle, originally articulated by Bertrand Meyer in 1988. The L stands for the Liskov Substitution Principle, derived from a 1987 keynote by Barbara Liskov on data abstraction and hierarchy. The I stands for the Interface Segregation Principle, also from Robert C. Martin. The D stands for the Dependency Inversion Principle, again from Martin's writing in the late 1990s.

The principles were not designed for any particular language or framework. They predate Laravel by more than a decade. What makes them feel native to Laravel is that Laravel itself was designed by people who internalized these principles deeply. The service container, the contracts directory, the notification channel system, the queue drivers, the broadcast drivers; all of these are textbook SOLID applied at framework scale. When you use them, you are using SOLID, even if you have never opened a SOLID book.

## The Mindset Shift SOLID Asks For {#the-mindset-shift-solid-asks-for}

Before walking through the five principles individually, it is worth naming the mindset shift they all push toward. Most beginner code is written to handle the case in front of you right now: this user, this form, this database table. Code written this way works. It ships. The trouble shows up the second time the requirements change.

SOLID asks you to write code with a particular kind of paranoia in mind: the requirement you are coding for today will change, and you will not be the one to change it. This is not pessimism; it is statistics. Most code in production gets modified after it is written, often by someone other than the original author, often months or years later. Code that absorbs that future change without breaking everything around it has a property the SOLID principles try to encourage. Code that does not absorb change well has properties they try to prevent.

With that frame in mind, let us go through the five.

## Single Responsibility Principle {#single-responsibility-principle}

The Single Responsibility Principle is stated simply: a class should have one and only one reason to change. The phrase is shorter than its meaning. Many developers read "single responsibility" and translate it as "do one thing". That translation is wrong, and chasing it leads to either too few classes (because "save and email a user" feels like one thing) or absurdly many classes (because you split every helper into its own file).

A more useful translation is the one Uncle Bob himself prefers in newer writing: a class should be responsible to one, and only one, actor. An actor is a person, role, or system that has the authority to request a change. If your `InvoiceController` calculates totals (the finance team's concern), generates a PDF (the design team's concern), sends an email (the marketing team's concern), and writes to an audit log (the compliance team's concern), then four different actors can request a change to that class. Sooner or later, two of them will request changes that conflict. That is the moment SRP is trying to prevent.

In Laravel, SRP shows up as a balance between thin controllers, form requests for validation, services or actions for business logic, jobs for asynchronous work, and notifications for user communication. None of this is enforced by the framework. You can absolutely cram all of it into a single controller method, and Laravel will run it. The framework simply gives you the tools to split responsibilities cleanly when you decide to. SRP is the principle that helps you decide.

A simple way to feel for an SRP violation is to write the description of a class out loud. If the description requires the word "and" more than once, you are probably looking at a class with multiple reasons to change. "The InvoiceController validates input *and* calculates totals *and* persists the record *and* generates a PDF *and* sends an email." That is five responsibilities, and Article 2 will refactor exactly that controller.

## Open/Closed Principle {#open-closed-principle}

The Open/Closed Principle, originally written by Bertrand Meyer, says that software entities should be open for extension but closed for modification. The phrase is paradoxical on first read: how can something be both open and closed? The answer is that "open" and "closed" refer to different things. The class is closed to having its source code modified, but it is open to having new behavior added through extension mechanisms like inheritance, composition, or interface implementation.

The pain that OCP prevents is regression. Every time you open a tested, working class to add a new feature, you risk breaking something that already worked. The risk is small for one change, but it compounds. After a year of opening the same `PaymentService` class to add Paypal, then Stripe, then Midtrans, then a coupon system, then a wallet, you have a class that nobody trusts to change without a full regression test pass.

OCP says: structure the class so that adding the next payment method does not require opening the existing class at all. You add a new file, register it, and the existing tested code stays untouched. In Laravel, this often takes the shape of an interface (such as `PaymentGateway`) with one implementation per gateway. The service that uses the interface never knows or cares which implementation is plugged in.

It is important to be honest about OCP: you cannot make code closed against every possible change. If a new payment gateway needs a fundamentally different concept, like multi step approvals, you may have to widen the interface. OCP is not about closing all change; it is about closing the kinds of change you can predict. Most of the time, "we will need another payment method" is predictable, so designing for it pays off. "We will need to fundamentally rethink payments" usually is not, and over engineering for that is what gives SOLID a bad name.

Article 3 will take a `PaymentService` with a growing if/else block and refactor it into an OCP compliant design with three gateways, then add a fourth without touching the original code.

## Liskov Substitution Principle {#liskov-substitution-principle}

The Liskov Substitution Principle is the trickiest of the five to get right, in part because its formal statement is dense. Barbara Liskov's original phrasing was: if S is a subtype of T, then objects of type T may be replaced with objects of type S without altering any of the desirable properties of the program. Translated into code: if `B` extends `A`, then any code that works correctly with an `A` instance must continue to work correctly when handed a `B` instance, with no surprises.

This sounds obvious until you realize how often subclasses break it. The classic example is a `Bird` class with a `fly()` method, and an `Ostrich` subclass that throws an exception when `fly()` is called because ostriches do not fly. Syntactically, `Ostrich` is a `Bird`. Semantically, if you wrote a function that accepts a `Bird` and calls `fly()` on it, that function will crash when an `Ostrich` is passed in. The substitution broke.

In Laravel codebases, LSP violations rarely look like ostriches. They look like a repository implementation that returns an Eloquent `Collection` while another implementation of the same interface returns a plain array. They look like a notification sender that silently truncates messages over a certain length while its sibling sender does not. They look like a child class that throws a different exception type than its parent declares. All of these will pass type checks. None of them will break loudly during code review. They will break months later when someone swaps the implementation in a service container binding and a code path nobody thought to test misbehaves.

The practical guardrails for LSP in PHP are: keep return types consistent (a child can narrow them, but never widen), keep parameter types consistent (a child can widen them, but never narrow), throw the same exception types that the parent declares, and honor the same preconditions and postconditions. Article 4 will demonstrate all four guardrails by building a notification system that violates them and then fixing each violation in turn.

## Interface Segregation Principle {#interface-segregation-principle}

The Interface Segregation Principle says that no client should be forced to depend on methods it does not use. Stated as a positive: prefer many small, focused interfaces over a few large, general purpose ones.

The pain ISP prevents is the empty implementation. You have a `ReportInterface` that requires `generatePdf()`, `generateExcel()`, `scheduleDaily()`, and `archiveToS3()`. You add a new `SimpleSalesReport` class that only needs to produce a PDF. To satisfy the interface, you implement the other three methods with `throw new BadMethodCallException()` or, worse, with empty bodies that silently lie about what they do. Both options are bad. The first violates LSP (substituting `SimpleSalesReport` where the interface is expected will crash); the second creates landmines that surface only when the methods are actually called.

The fix is to split the fat interface into focused ones. `Reportable` for the rendering, `Schedulable` for scheduling, `Archivable` for archival. A class that only generates a PDF implements only `Reportable`. A class that needs all three implements all three. Nothing is forced to declare capabilities it does not have.

Laravel's own Contracts directory is a master class in ISP. Look at the framework source and you will find separate small contracts for `Cache\Repository`, `Cache\Lock`, `Cache\Store`, `Cache\Factory`, and so on, rather than a single bloated `Cache` interface that tries to cover everything. This is not an accident. Article 5 will walk through a fat reporting interface and split it apart, with Pest tests demonstrating that the split removes the need for stub implementations.

## Dependency Inversion Principle {#dependency-inversion-principle}

The Dependency Inversion Principle has two parts. First: high level modules should not depend on low level modules; both should depend on abstractions. Second: abstractions should not depend on details; details should depend on abstractions.

The everyday way to feel for DIP is to ask: when this class needs another class, does it grab a specific implementation, or does it ask for an abstraction and let someone else decide which implementation to plug in? A `NewsletterController` that does `new MailchimpProvider($apiKey)` inside its `subscribe()` method is depending directly on a low level detail (the Mailchimp HTTP client). A `NewsletterController` that accepts a `NewsletterProvider` interface in its constructor is depending on an abstraction; the actual provider is bound elsewhere, usually in a service provider, and can be swapped without touching the controller.

The benefit is most visible at test time. If your controller `new`s up Mailchimp, your test cannot run without either an internet connection or a heavy stubbing setup. If your controller depends on an interface, your test binds a fake implementation in two lines and runs in milliseconds. The same flexibility that makes the code testable also makes it adaptable: switching from Mailchimp to Sendgrid becomes a one line change in a service provider, not a search and replace across the codebase.

DIP is the principle most directly served by Laravel's service container. The container exists to resolve dependencies for you, to bind interfaces to concrete classes, and to swap those bindings at runtime. When you type hint an interface in a controller constructor and Laravel injects a working implementation, you are using DIP. Article 6 will refactor a tightly coupled newsletter controller into a DIP compliant design and show how the container, service providers, and contextual binding fit together.

It is worth saying clearly: DIP, dependency injection, and inversion of control are three different things, and Article 6 will untangle them. For now, hold this loose mental model: DIP is the principle (depend on abstractions), dependency injection is the technique (pass dependencies in, do not new them up), and inversion of control is the mechanism (a container resolves and wires things for you).

## How the Principles Work Together {#how-the-principles-work-together}

The five principles are easier to absorb individually, but they are not five independent rules. They reinforce each other, and applying one tends to push you toward the others.

SRP enables OCP. A class that has one responsibility is much easier to leave alone when adding new behavior; you add the new behavior in a new class. A class with many responsibilities tempts you to keep cramming new behavior in, because there is already so much in there.

OCP demands LSP. The whole point of OCP is that you can swap one implementation for another behind a stable abstraction. That swap only works if the new implementation truly behaves like the old one. Without LSP, OCP becomes a lie: you appear to have pluggable strategies, but plugging in the wrong one breaks everything.

ISP supports LSP. Smaller, more focused interfaces are easier to implement faithfully. A class that only has to implement two methods is much less likely to fudge one of them than a class that has to implement ten.

DIP makes the previous four enforceable. Without dependency inversion, your high level modules import concrete low level modules directly, and SRP, OCP, LSP, and ISP all become guidelines you cannot really enforce. With dependency inversion, the abstractions become the contract that the other principles hang off of.

A practical consequence: when you refactor toward one principle and feel another principle starting to make sense too, that is the system working as designed. You are not doing extra work; you are doing one body of work that pays off in five different ways.

## When to Apply SOLID and When Not To {#when-to-apply-solid-and-when-not-to}

A common failure mode of developers who have just discovered SOLID is to apply every principle to every class, regardless of context. This produces code that is technically pure and practically painful: ten files where two would do, three layers of abstraction over a function that has one implementation and will only ever have one, contracts written for code that is not under any change pressure.

The honest framing is that SOLID has a cost. Every interface you introduce is a file someone has to read. Every binding in a service provider is a line someone has to follow when tracing a bug. These costs are paid up front. The benefits arrive later, when the code needs to change. If the code never needs to change much, you paid the cost for nothing.

A reasonable rule of thumb: apply SOLID where change is likely, and skip it where change is unlikely. A `PaymentService` that has been rewritten three times in two years is screaming for OCP. A throwaway script that imports a CSV one time is fine as a single function. A model with a complex set of business rules that different teams own is a candidate for SRP. A simple Eloquent model that holds five fields and three relationships is fine as it is.

Watch for these signals that SOLID is paying off: features that used to take days now take hours, changes that used to break unrelated tests no longer do, new team members can extend the system without reading the whole codebase first. Watch for these signals that SOLID has been overapplied: simple changes require touching five files, the abstractions have only one implementation each and have never been swapped, the codebase has more interfaces than concrete classes.

## Common Misconceptions {#common-misconceptions}

A few persistent misunderstandings deserve direct callouts before we move into the practical articles.

SOLID is not the same as "use lots of interfaces". You can satisfy several SOLID principles without writing a single interface, particularly in small applications where the strategies and bindings would be over engineering. Interfaces are a tool that helps; they are not the goal.

SOLID does not require any specific architecture. Hexagonal architecture, clean architecture, and onion architecture are all heavily SOLID influenced, but you can write SOLID code in a plain Laravel MVC project, in a single file, or in a hexagonal architecture. The architectures are opinionated containers for the principles, not the principles themselves.

SOLID is not a dogma. The principles are guidelines, sometimes in tension with each other, sometimes outweighed by other concerns like performance, simplicity, or shipping a deadline. A senior engineer applies SOLID with judgment; a junior engineer applies it as gospel. Aim for the senior posture.

SOLID does not mean writing more code. Done well, applying SOLID often results in less total code, because removing duplication and structuring responsibilities clearly tends to shrink things. If your SOLID refactor doubles the line count, something has probably gone wrong.

## The Series Roadmap {#the-series-roadmap}

The next five articles will each take one principle and demonstrate it on a realistic Laravel 13 codebase. Every article uses Pest for tests, ships a baseline `php artisan test` output before the refactor, and shows the same test count passing after the refactor. Each article uses a different sub domain so you can read them in any order, but they were designed to be read in sequence.

Article 2 covers the Single Responsibility Principle by refactoring a bloated invoice controller. You will start with a single controller method that calculates totals, persists, generates a PDF, sends an email, and logs an audit entry, then split it into a calculator, a repository, a PDF generator, and a mailer.

Article 3 covers the Open/Closed Principle by building an extensible payment gateway system. You will start with a service that uses an if/else block to dispatch to Paypal or Stripe, then refactor it to a `PaymentGateway` contract, and add Midtrans as a third gateway without modifying the existing service or its tests.

Article 4 covers the Liskov Substitution Principle by exposing and fixing violations in a notification sender hierarchy. You will see how a child class that silently truncates messages or throws different exception types breaks code that depends on the parent contract, and you will fix each violation explicitly.

Article 5 covers the Interface Segregation Principle by splitting a fat reporting interface into focused contracts. You will see exactly the kind of `BadMethodCallException` driven design that ISP exists to prevent, and you will refactor it into a small set of capability based interfaces.

Article 6 covers the Dependency Inversion Principle by refactoring a tightly coupled newsletter subscription controller. You will untangle DIP from dependency injection and inversion of control, build a `NewsletterProvider` contract, swap implementations in a service provider, and write tests that run without ever touching a real third party API.

## Conclusion {#conclusion}

SOLID is a small set of habits that make object oriented code more able to absorb change. None of the five principles are magic, none of them are Laravel specific, and none of them should be applied as an absolute rule. The reason to learn them is that they give you a shared vocabulary for the design pressures you already feel when working in a real codebase, and a shared toolkit for relieving that pressure.

Here are the key takeaways from this introduction to carry into the rest of the series:

- **Single Responsibility Principle.** A class should have one reason to change, meaning one actor in the business who can demand changes to it. Aim for descriptions you can give without saying "and" more than once.
- **Open/Closed Principle.** A class should be open for extension and closed for modification, so that new variations of behavior can be added without editing tested code. Look for if/else dispatch chains; they are usually OCP smells.
- **Liskov Substitution Principle.** Subtypes must behave as their parent types in any code that uses the parent. Watch for return type widening, parameter narrowing, and unexpected exception types in subclasses.
- **Interface Segregation Principle.** Many small, focused interfaces are better than a few large ones, because they avoid forcing classes to implement methods they do not need. Empty implementations and `BadMethodCallException` are signs of a fat interface.
- **Dependency Inversion Principle.** High level modules should depend on abstractions, not on low level concretes. Constructor inject your dependencies, type hint interfaces, and let the Laravel service container resolve them.
- **The principles reinforce each other.** SRP enables OCP, OCP demands LSP, ISP supports LSP, and DIP makes the rest enforceable. Applying one well usually makes the others fall into place.
- **SOLID has a cost; apply it where change is likely.** Over applied, SOLID produces ceremonious code with too many files. Under applied, it produces fragile code that fights every change. The judgment is the engineering, not the rule.

In Article 2 we will leave the theory behind, install Laravel 13 with Pest, and refactor a deliberately bloated invoice controller into a Single Responsibility Principle compliant design. The before and after Pest tests will give you a concrete feel for what the principle buys in practice.