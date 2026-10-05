---
title: 'AI Can Write Code. But Can You Read It?'
date: '2026-10-05'
category: 'Software Engineering'
tags: ['AI', 'Programming', 'Code Reading', 'Software Engineering', 'Developer Skills']
draft: false
summary: 'AI can now implement substantial parts of real software systems. That shifts the developer’s job from producing every line toward understanding, reviewing, verifying, and owning what gets built.'
---

# AI Can Write Code. But Can You Read It?

A few years ago, the most obvious question about AI and programming was simple:

> Can AI actually write useful code?

In 2026, that question already feels incomplete.

Modern coding agents can explore repositories, edit multiple files, run tests, use terminals, fix their own mistakes, and continue working across tasks that would once have required a developer to manually coordinate every step.

The capability jump matters because it changes the premise of the conversation.

The important question is no longer only whether AI can produce code that works.

Increasingly, the question is:

> If AI can build a meaningful part of the software for you, do you understand enough of that software to confidently own the result?

That is a different problem.

And it may become one of the defining programming skills of the AI era.

## The Premise Changed {#the-premise-changed}

In 2025, discussions about AI-assisted programming often focused on trust.

Developers complained about hallucinated APIs, plausible-but-wrong implementations, and code that took longer to debug than expected. Those concerns were real, but using them as the main argument against relying on AI is becoming less convincing as models improve.

By 2026, the frontier has moved considerably.

OpenAI describes GPT-6 Astra as a model designed for demanding software-engineering and computer-use tasks. Anthropic's Claude Opus 5.5 announcement highlights large improvements on complex coding work and reports an early tester completing a 680,000-line code migration in less than a day. Kimi's current coding models emphasize long-horizon programming and context windows large enough to reason across substantial codebases.

Vendor claims should always be read carefully. Benchmarks are not production systems, and a successful demo is not the same thing as maintainable software.

But the direction is difficult to ignore.

Independent research is seeing the same shift.

The 2026 [DeepSWE benchmark](https://arxiv.org/abs/2607.07946) was designed around original, long-horizon engineering tasks across 91 active repositories. Its authors describe the transition directly: large language models have moved from completing individual functions toward agents that locate relevant code, modify multiple files, run tests, and iterate inside real repositories.

That means the most interesting risk is no longer simply:

> What if AI writes bad code?

A more interesting risk is:

> What if AI writes good code faster than you build a mental model of the system?

## Code Generation Is Becoming Cheap {#code-generation-is-becoming-cheap}

Software development has always had expensive parts.

Writing boilerplate was expensive.

Looking up unfamiliar APIs was expensive.

Translating a requirement into five controllers, three migrations, several tests, and configuration changes was expensive.

A capable coding agent can now compress a surprising amount of that work.

Suppose you ask:

```text
Add organization-level permissions to the application.

Existing users can belong to multiple organizations.
Each organization needs its own roles.
Update the API, database schema, authorization,
tests, and existing data migration.
```

A modern agent may be able to inspect the project, identify the relevant models and policies, create migrations, update relationships, modify authorization logic, adjust API resources, add tests, and run the test suite.

That is much more than autocomplete.

And when implementation becomes cheaper, the bottleneck moves.

The developer's job shifts from:

> How do I write all of this?

toward:

> Is this the right design?

> What assumptions did the agent make?

> Does this fit the existing architecture?

> What changed outside the obvious files?

> Which invariants must still hold?

> How do I know this is safe to ship?

Those are not code-generation questions.

They are software-understanding questions.

## Working Code Is Not the Same as Owned Code {#working-code-is-not-the-same-as-owned-code}

Consider a small Laravel example:

```php
public function store(StorePostRequest $request)
{
    $post = Post::create($request->validated());

    return new PostResource($post);
}
```

An AI agent can produce this instantly.

It may also be completely correct.

But those four visible lines are not the system.

To understand what happens when this endpoint runs, you may still need to know:

- which route reaches the controller;
- which middleware runs before it;
- where authorization is enforced;
- which fields survive validation;
- which fields are mass assignable;
- whether model observers or events run;
- whether database constraints can reject the operation;
- whether the operation should be transactional;
- how the response is transformed;
- what happens when validation fails;
- what happens when two requests arrive at the same time.

The syntax is the smallest part of the problem.

An experienced developer reads those lines while simultaneously thinking about the execution path around them.

That is what code reading increasingly needs to mean in an AI-assisted workflow.

Not:

> Can I explain each line?

But:

> Can I reconstruct enough of the surrounding system to reason about its behavior?

## "Read the Code" Now Means "Understand the System" {#read-the-code-now-means-understand-the-system}

When AI changes ten files instead of ten lines, reading every generated character is not always the highest-value review strategy.

You need multiple levels of understanding.

### 1. Intent

What requirement is the implementation supposed to satisfy?

If the requirement itself is ambiguous, perfect code can still implement the wrong thing.

Before reviewing implementation details, make sure the intended behavior is explicit.

### 2. Change Surface

What actually changed?

Look beyond the obvious diff.

Did the agent modify configuration?

Add a dependency?

Change a database constraint?

Alter an API response?

Introduce a background job?

Modify shared infrastructure used by unrelated features?

A small request can produce a large behavioral surface.

### 3. Control Flow

How does execution move through the system?

Trace requests, commands, jobs, events, middleware, services, exceptions, and callbacks.

The goal is not memorization.

The goal is to know where important decisions happen.

### 4. Data Flow

Where does data enter, change shape, persist, and leave?

Follow input through validation, transformation, persistence, caching, queues, external APIs, and responses.

Many subtle bugs are not syntax problems. They are data-flow problems.

### 5. Boundaries and Contracts

What does this feature depend on?

What assumptions exist between modules?

What happens at the boundary between your application and a database, queue, filesystem, payment provider, authentication service, or third-party API?

AI can implement both sides of a local abstraction and still preserve a wrong assumption.

### 6. Failure Modes

What happens when the happy path disappears?

A useful review asks about:

- invalid input;
- missing authorization;
- retries;
- partial failures;
- duplicate requests;
- timeouts;
- race conditions;
- stale data;
- unavailable dependencies;
- unexpected state.

This is where understanding becomes more valuable than simply recognizing clean-looking code.

## The Bottleneck Is Moving Up the Stack {#the-bottleneck-is-moving-up-the-stack}

A 2026 developer survey gives a useful picture of this shift.

In its [Q3 2026 Dev Barometer](https://www.bairesdev.com/research/), BairesDev surveyed 705 developers across more than 60 countries. Forty-two percent said AI now assists with at least half of their code, up from 12% a year earlier.

Developers also reported saving an average of 13 hours per week on coding.

But those hours did not simply become free time.

According to the same survey, 67% said they were spending more time reviewing AI-generated code than a year earlier, 52% were spending more time debugging problems introduced by AI, and 58% reported greater accountability for code they did not fully write.

That combination is more interesting than a simple productivity statistic.

The typing decreases.

The responsibility does not.

In fact, responsibility may increase because a developer can now approve far more implementation than they could manually produce in the same amount of time.

This creates a new kind of leverage.

One developer with capable agents may be able to create changes across a much larger surface area.

But leverage amplifies both good judgment and bad judgment.

## AI Getting Better Does Not Remove the Need for Review {#ai-getting-better-does-not-remove-the-need-for-review}

There is a tempting assumption:

> Once AI becomes good enough, we will not need to inspect its work as carefully.

That is not necessarily how engineering works.

We already trust compilers without reviewing the machine code they emit.

We trust database engines without manually inspecting their storage algorithms.

We trust frameworks to perform large amounts of behavior we did not write.

So yes, some AI-generated implementation may eventually become another abstraction layer.

But abstractions do not remove responsibility.

They change where responsibility sits.

You do not need to understand every line inside PostgreSQL to use it professionally.

You do need to understand transactions, indexes, constraints, isolation, failure modes, and the consequences of the queries your application sends.

The same pattern is likely to emerge with coding agents.

You may not need to personally author every implementation detail.

You will still need enough understanding to specify constraints, recognize architectural mistakes, verify behavior, and decide whether the result belongs in production.

## Better Agents Make Better Questions More Important {#better-agents-make-better-questions-more-important}

When an AI assistant was limited to short snippets, vague prompts produced limited damage.

If the output was wrong, you usually rejected a function.

As agents become capable of making repository-wide changes, vague intent becomes more expensive.

Imagine giving an agent this task:

```text
Make file uploads private.
```

There are many reasonable interpretations.

Should existing files be migrated?

Should public URLs stop working immediately?

Should access use signed URLs?

How long should those URLs remain valid?

Are administrators exempt from access rules?

Do background workers need access?

What happens to cached URLs?

Should the API response change?

What should happen to old mobile clients?

A strong coding agent may implement a technically coherent solution.

It may still be the wrong product decision.

This is why AI capability does not reduce the need for engineering judgment.

It increases the amount of implementation that can be produced from a single judgment.

## The Real Test: Can You Change What the Agent Built? {#the-real-test-can-you-change-what-the-agent-built}

A useful test of understanding is still simple:

Change the requirement.

Suppose an agent builds a document upload feature.

The first version works.

Then the requirements change:

- only PDF files are allowed;
- the maximum size is 5 MB;
- replacing a document must delete the previous file;
- files move from local storage to S3;
- access becomes private;
- existing public files must remain available during a migration period.

If you understand the system, you can reason about the change.

Validation rules are one part.

Storage configuration is another.

The replacement lifecycle matters.

Authorization may need to move closer to file access.

Existing database records may contain public paths that no longer represent the new storage model.

Old files may need a migration strategy.

Tests should describe both the new behavior and the compatibility period.

Observability may matter if the migration runs asynchronously.

If your only strategy is to ask the agent to regenerate the entire feature, you may still get a working result.

But each regeneration resets your dependency on the agent's internal reasoning.

Ownership starts when you can predict where the system needs to change before the agent changes it.

That is a much stronger definition of understanding.

## Productivity Research Is Changing Too {#productivity-research-is-changing-too}

The evidence around AI productivity is moving quickly, which is another reason to be careful with conclusions from older studies.

In 2025, METR published a randomized study in which experienced open-source developers were slower on a particular set of tasks when using then-current AI tools.

That result was widely discussed.

But METR itself updated the picture in February 2026.

In [a follow-up on its experiment design](https://metr.org/blog/2026-02-24-uplift-update/), the organization said it believes developers are likely more accelerated by AI tools in early 2026 than they were in early 2025. It also explained that the newer experiment had become difficult to interpret because some developers did not want to participate if they had to work without AI, while multi-agent workflows made time measurement harder.

That update is important.

It shows how quickly the tooling and developer workflow are changing.

The useful takeaway is not that AI always makes developers faster.

It is that evidence about AI-assisted engineering has a short shelf life, and broad claims should be anchored to the tools and workflows being studied.

For developers, the practical direction is clearer than the exact percentage:

AI is taking on more implementation work.

Human work is moving toward specification, review, validation, integration, and ownership.

## Benchmarks Show Capability, Not Responsibility {#benchmarks-show-capability-not-responsibility}

Modern software-engineering benchmarks are becoming more realistic.

DeepSWE, for example, uses original tasks that require agents to work inside existing repositories, discover relevant code, make multi-file changes, and satisfy functional verifiers.

That is useful progress because it measures much more than whether a model can complete an isolated function.

But even a strong benchmark cannot answer the final production question:

> Should this change ship in your system?

A benchmark can verify specified behavior.

It usually cannot know your product intent, undocumented business rules, organizational risk tolerance, legacy client behavior, operational constraints, or why an architectural boundary exists.

Those live outside the prompt unless someone deliberately puts them into context.

That "someone" is still part of the engineering process.

## Use AI for Comprehension, Not Only Production {#use-ai-for-comprehension-not-only-production}

The answer is not to avoid coding agents.

Use them more intelligently.

Instead of asking only:

```text
Implement this feature.
```

also ask:

```text
Before changing anything, explain the current execution flow.

List the files and abstractions that own this behavior.

Identify the assumptions you think the existing design makes.

Do not implement yet.
```

After implementation:

```text
Summarize the behavioral changes, not just the files changed.

Which existing invariants could this affect?

Which failure modes are not covered by the current tests?

What would you inspect manually before shipping this?
```

For an unfamiliar codebase:

```text
Trace this request from the route to the database.

Show where authorization, validation, persistence,
events, and response transformation occur.
```

And one of the most useful prompts is still:

```text
Give me five questions I should be able to answer
if I truly understand this implementation.

Do not answer them yet.
```

The goal is not to make the AI prove that its own work is correct.

The goal is to use AI to accelerate your investigation of the system.

## The Learning Loop Still Matters {#the-learning-loop-still-matters}

A practical AI-assisted programming loop can still be summarized in six steps:

### Generate

Let the agent produce implementation when that is the most efficient path.

This may now mean much more than generating a function. It may mean delegating an entire feature.

### Read

Read at the right level.

Inspect the diff, but also inspect architecture, dependencies, tests, data flow, and changed contracts.

### Explain

Explain the resulting behavior in your own words.

If you cannot describe why a major component changed, investigate before moving on.

### Predict

Before running everything, predict important behavior.

Which query should execute?

Which authorization path should reject the request?

Which test should fail if you remove a constraint?

What happens when a dependency times out?

Prediction exposes gaps in your mental model.

### Modify

Change a requirement.

Do not ask the agent to rebuild from zero immediately.

Reason about which parts should change first, then use the agent to accelerate the work.

### Verify

Use tests, logs, static analysis, database inspection, observability, manual review, and realistic edge cases.

The loop remains:

> **Generate → Read → Explain → Predict → Modify → Verify**

What changed in 2026 is the scale of the first step.

The agent may generate far more.

That makes the remaining steps more important, not less.

## Programming Is Moving Up a Level {#programming-is-moving-up-a-level}

Software development has repeatedly moved through layers of abstraction.

Assembly gave way to higher-level languages.

Libraries removed repeated low-level work.

Frameworks encoded application patterns.

Cloud platforms abstracted infrastructure.

Managed services reduced operational burden.

Each layer made certain implementation details cheaper.

None eliminated engineering.

Instead, the valuable questions moved upward.

AI coding agents appear to be doing something similar to implementation itself.

If producing code becomes abundant, manually typing every line becomes less distinctive.

The scarce skills move toward:

- defining the right problem;
- designing boundaries;
- communicating constraints;
- evaluating trade-offs;
- understanding existing systems;
- reviewing changes;
- validating behavior;
- diagnosing failures;
- deciding what is safe to ship;
- taking responsibility for the result.

This does not mean syntax, algorithms, databases, networking, or frameworks stop mattering.

It means those fundamentals become the vocabulary you use to supervise increasingly powerful tools.

## You May Write Less Code and Need to Understand More Software {#you-may-write-less-code-and-need-to-understand-more-software}

That may be the most important shift.

A developer using modern agents can potentially touch more of a system in one day than they could manually implement in a week.

That sounds like pure productivity.

It is also an expansion of responsibility.

More code can change.

More assumptions can enter the system.

More architecture can be modified.

More behavior can reach production.

So the relevant skill is not proving that you personally typed every line.

It is being able to say:

> I understand what changed.

> I understand why we chose this design.

> I know the important assumptions.

> I know how we verified the behavior.

> I know where to look when it fails.

That is ownership.

And ownership matters regardless of whether the implementation came from your keyboard, a framework, a compiler, a code generator, or an AI agent.

AI can write increasingly large parts of the code.

The question is whether you can still read enough of the system to own what it builds.

---

## References {#references}

1. Huang, W., Lee, C., Tng, L., & Ge, S. [*DeepSWE: Measuring Frontier Coding Agents on Original, Long-Horizon Engineering Tasks*](https://arxiv.org/abs/2607.07946), 2026.
2. BairesDev. [*Dev Barometer Q3 2026 — One Year In: What AI Actually Did to Software Work*](https://www.bairesdev.com/research/), 2026.
3. BairesDev. [*Developers Now Spend the Hours AI Freed Up Answering for the Code*](https://www.bairesdev.com/blog/dev-barometer-q3-2026-devs-answering-for-code/), 2026.
4. METR. [*We are Changing our Developer Productivity Experiment Design*](https://metr.org/blog/2026-02-24-uplift-update/), February 2026.
5. OpenAI. [*GPT-6 Astra: A New Generation of Intelligence*](https://openai.com/index/gpt-6-astra/), 2026.
6. Anthropic. [*Introducing Claude Opus 5.5*](https://www.anthropic.com/claude-opus-5-5), September 2026.
7. Kimi. [*Kimi Code — What's New*](https://www.kimi.com/code/docs/en/kimi-code/whats-new.html), 2026.
