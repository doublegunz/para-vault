---
title: "Reducing AI Token Usage in PHP Tests with PAO"
slug: "reducing-ai-token-usage-in-php-tests-with-pao"
category: "Laravel"
date: "2026-04-09"
status: "published"
---

Every time an AI agent runs your test suite, it reads the entire output before deciding what to do next.
With a large Pest test suite, that output alone can consume more than 10,000 tokens per run.
Run your tests 50 times in a single coding session and you have just spent half a million tokens on dots, checkmarks, and stack traces that the agent could have processed in a fraction of the space.

[PAO](https://github.com/nunomaduro/pao) solves this by replacing the verbose, human-readable test output with compact structured JSON whenever it detects that your tests are running inside an AI agent.
No configuration required. You install it, and it works.

## Overview {#overview}

This article introduces PAO, a zero-config PHP package by Nuno Maduro that optimizes test output for AI agents.
Rather than walking through a complex build, the focus here is on understanding what PAO does, how to install it, and how to read the output it produces so you can get the most out of it in your own projects.

### What You'll Set Up

- PAO installed in a PHP project that uses PHPUnit, Pest, or Paratest
- A working understanding of the JSON output format PAO produces
- Familiarity with how PAO handles test failures and plugin output like coverage reports

### What You'll Learn

- Why test output is a significant source of token consumption in AI-assisted workflows
- How PAO detects AI agents and switches output formats automatically
- How to read and interpret the structured JSON output PAO produces
- How PAO handles failures, plugin output, and extra output from tools like `--coverage`

### What You'll Need

- PHP 8.3 or newer
- PHPUnit 12-13, Pest 4-5, or Paratest installed in your project
- Composer for package installation
- An AI agent such as Claude Code, Cursor, Devin, or Gemini CLI (PAO also works outside agents, but produces normal output in that case)

## Why Test Output Becomes a Token Problem {#why-test-output-is-a-token-problem}

When an AI agent runs your test suite, it treats the output as input that it must read and process before continuing.
This is fine for a small suite with a handful of tests, but scales poorly.
A Pest test run with 1,000 tests produces more than 10,000 tokens of progress indicators, assertion counts, timing information, and formatting before a single failure message even appears.

The agent does not need any of that detail to understand whether the tests passed or failed.
It needs a result, a count, and in the case of failures, a location and message.
Everything else is noise that consumes space in the context window, pushing out code, conversation history, and reasoning that actually matters.

PAO intercepts the output pipeline and collapses that noise into a small, fixed-size JSON response.
The result is constant at around 20 tokens regardless of how many tests you run.

## Installation {#installation}

Installing PAO is a single Composer command, run the following command in the root of your PHP project.

```bash
composer require laravel/pao --dev
```

That is all. PAO hooks into PHPUnit, Pest, and Paratest automatically through Composer's autoloader.
There is no configuration file to publish, no service provider to register, and no environment variable to set.
The package detects your test runner and patches into the output layer transparently.

## Running Your Tests With PAO {#running-your-tests}

Once installed, you use your test runner exactly as you did before.
PAO does not change any commands or flags.

```bash
vendor/bin/phpunit
# or
vendor/bin/pest
# or
vendor/bin/paratest
```

When PAO detects that the process is running inside a supported AI agent, it suppresses the standard output and replaces it with JSON.
When you run the same command in a normal terminal outside an agent, PAO stays out of the way and lets your test runner produce its usual output.
This means you keep full human-readable output during local development and get structured output when the agent takes over.

## Reading the JSON Output {#reading-the-json-output}

The JSON output PAO produces is intentionally minimal.
It contains only the fields an AI agent needs to understand what happened and decide what to do next.

### Understand the passing test output

When all tests pass, PAO produces a response like this.

```json
{
  "result": "passed",
  "tests": 1002,
  "passed": 1002,
  "duration_ms": 321
}
```

Each field has a clear purpose. `result` tells the agent the overall outcome. `tests` and `passed` give the counts it needs to verify nothing was skipped. `duration_ms` provides timing information in case the agent needs to reason about performance. The entire response is around 20 tokens, regardless of whether you have 10 tests or 10,000.

### Understand the failing test output

When tests fail, PAO expands the output just enough to tell the agent where to look and what went wrong.

```json
{
  "result": "failed",
  "tests": 1002,
  "passed": 1001,
  "failed": 1,
  "duration_ms": 318,
  "failures": [
    {
      "test": "Tests\\Feature\\UserTest::it_creates_a_user",
      "file": "tests/Feature/UserTest.php",
      "line": 24,
      "message": "Failed asserting that false is true."
    }
  ]
}
```

The `failures` array includes the full test name, the file path, the line number, and the failure message.
This gives the agent exactly what it needs to navigate to the failing test and start working on a fix, without any surrounding noise.

## Working With Plugin Output {#working-with-plugin-output}

Some Pest plugins and PHPUnit extensions produce additional output alongside the test results.
Coverage reports, profiling summaries, and similar tools all write to the output stream that PAO intercepts.

### Run tests with a plugin that produces extra output

```bash
vendor/bin/pest --coverage
```

PAO captures the extra output, strips ANSI color codes and formatting decorations, and appends it to the JSON response as an `output` array.

```json
{
  "result": "passed",
  "tests": 1002,
  "passed": 1002,
  "duration_ms": 1520,
  "output": [
    "Http/Controllers/Controller 100.0%",
    "Models/User 0.0%",
    "Total: 33.3 %"
  ]
}
```

The agent receives the coverage data in a clean, readable format without needing to parse colored terminal output or strip progress bars from the middle of a percentage table.
This pattern works the same way for `--profile` and other plugins that write to stdout.

## How PAO Detects AI Agents {#how-pao-detects-ai-agents}

PAO does not require you to set a flag or an environment variable to activate JSON mode.
It inspects the environment automatically and switches behavior based on whether it detects a known agent context.

Supported agents include Claude Code, Cursor, Devin, Gemini CLI, and others.
Each agent typically sets one or more environment variables that PAO looks for at startup.
If a matching signal is found, PAO activates structured output mode. If not, it does nothing and your test runner behaves exactly as it normally would.

This design means the same `composer.json` and the same CI configuration work for both human developers and AI agents without any branching logic or conditional scripts.

### Real-World Case Study: Testing PAO with Antigravity

During our initial testing with the **Antigravity** AI assistant, we found that PAO did not work out of the box. Instead of seeing the optimized JSON output, the agent was still presented with the standard, verbose Pest output. 

This happened because PAO detects AI environments by looking for specific environment variables (like `CLAUDECODE` or `CURSOR_AGENT`). At the time of our testing, the native `ANTIGRAVITY_AGENT` variable was not yet mapped in the package's detector logic.

Here is the exact progression of how we verified the problem, applied a solution, and measured the actual token savings.

#### 1. The Baseline Output (PAO Not Triggered)

First, we forced a test failure to see what the agent has to parse when PAO isn’t working. The output looked like this:

```text
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   FAIL  Tests\Feature\ExampleTest
  ⨯ the application returns a successful response                        0.10s  
  ────────────────────────────────────────────────────────────────────────────  
   FAILED  Tests\Feature\ExampleTest > the application returns a successful…    
  Expected response status code [300] but received 200.
Failed asserting that 200 is identical to 300.

  at tests/Feature/ExampleTest.php:6
      2▕ 
      3▕ test('the application returns a successful response', function () {
      4▕     $response = $this->get('/');
      5▕ 
  ➜   6▕     $response->assertStatus(300);
      7▕ });
      8▕ 

  Tests:    1 failed, 1 passed (2 assertions)
  Duration: 0.15s
```

*This output generated roughly 20 lines of text and consumed around 950 characters, heavily formatted with invisible ANSI rendering codes, spacing, and ASCII characters.*

#### 2. The Solution

To force PAO to activate inside our unsupported agent environment, we utilized the generic `AI_AGENT` environment variable that the package recognizes. We executed:

```bash
AI_AGENT=1 vendor/bin/pest
```

*(Tip: If you run into a similar issue with a new or custom AI tool, simply add `AI_AGENT=1` to your project's `.env` file to make this behavior permanent during local development.)*

#### 3. Optimized Output (PAO Triggered Successfully)

By prefixing our test run with `AI_AGENT=1`, PAO instantly took over and collapsed the exact same failure into a single JSON object:

```json
{"result":"failed","tests":2,"passed":1,"duration_ms":121,"failed":1,"failures":[{"test":"Tests\\Feature\\ExampleTest::the application returns a successful response","file":"vendor/laravel/framework/src/Illuminate/Testing/TestResponseAssert.php","line":45,"message":"the application returns a successful responseExpected response status code [300] but received 200.\nFailed asserting that 200 is identical to 300.\nat vendor/laravel/framework/src/Illuminate/Testing/TestResponseAssert.php:45\nat vendor/laravel/framework/src/Illuminate/Testing/TestResponse.php:176\nat tests/Feature/ExampleTest.php:6"}]}
```

#### 4. The Token Savings Comparison

Our test provided concrete, real-world proof of token efficiency for a single test failure:
- **Standard Output:** ~20 lines, ~950 characters
- **PAO Output:** 1 line, ~550 characters

**The Conclusion:** PAO achieved a **~42% reduction in character size** and a **~95% reduction in visual line footprint**. In a full test suite with hundreds of passing tests, the standard output balloons exponentially while PAO's output remains virtually the same size, securing massive token discounts for your agent's context window.

### Built-In Support: Testing with Gemini CLI

To contrast the unsupported Antigravity experience, we also ran the exact same test suite using **Gemini CLI**, an agent environment that PAO *does* natively recognize. 

In Gemini CLI, PAO looks for the `GEMINI_CLI` environment variable. Because the agent sets this automatically, we did not need to manually pass `AI_AGENT=1` or configure our `.env` file. We simply ran the standard testing command:

```bash
php artisan test
```

Without any extra flags or parameters, PAO instantly intercepted the output and returned the expected structured JSON format for the failing test:

```json
{
  "result": "failed",
  "tests": 2,
  "passed": 1,
  "duration_ms": 396,
  "failed": 1,
  "failures": [
    {
      "test": "Tests\\Feature\\ExampleTest::the application returns a successful response"
    }
  ]
}
```

This perfectly illustrates the "Zero Configuration" promise of PAO. When used inside supported AI agents like Claude Code, Cursor, or Gemini CLI, PAO optimizes the token usage entirely out of the box, requiring zero behavior changes from the developer.

## Token and Cost Savings in Practice {#token-and-cost-savings}

The benchmark numbers from the PAO repository make the token reduction concrete.
With 1,000 tests, Pest without PAO produces more than 10,000 tokens of output per run. With PAO, that drops to around 20 tokens regardless of the runner.

| Runner | Without PAO | With PAO | Reduction |
|--------|-------------|----------|-----------|
| PHPUnit | 336 tokens | 20 tokens | 94% |
| Paratest | 351 tokens | 20 tokens | 94% |
| Pest | 10,123 tokens | 20 tokens | 99.8% |
| Pest --parallel | 11,125 tokens | 20 tokens | 99.8% |

In a real coding session where an agent runs the test suite 50 times, PAO reduces token consumption by roughly 500,000 tokens with a 1,000-test Pest suite.
That translates to meaningful cost savings on models that charge by the token, but the more important benefit is context window space.

Every test run without PAO pushes code, conversation history, and reasoning out of the agent's active context.
After dozens of runs, the agent may be working with a truncated view of the codebase because the context window is full of test output it already processed and discarded.
PAO keeps the total test output across an entire session to around 1,000 tokens instead of 500,000, leaving the context window free for what actually matters.

## Conclusion {#conclusion}

PAO is a small package with a narrow, well-defined job: make PHP test output useful for AI agents instead of wasteful.
It does that job without requiring any changes to how you write tests, how you run them, or how you configure your project.
The zero-config design is deliberate. If you have to remember to activate it or adjust flags per environment, it stops being a default and starts being a chore.

If you are already using an AI agent to help with PHP development, PAO is one of the lowest-effort improvements you can make to how that agent spends its context.
Install it once and every future test run costs a fraction of what it did before.

- PAO replaces verbose PHP test output with compact JSON when it detects an AI agent, keeping output constant at around 20 tokens regardless of test suite size.
- It works with PHPUnit, Pest, and Paratest across any PHP project including Laravel, Symfony, Laminas, and vanilla PHP, with no configuration required.
- When tests fail, PAO includes file paths, line numbers, and failure messages so the agent has exactly what it needs to locate and fix the problem.
- Extra output from plugins like `--coverage` or `--profile` is captured, cleaned of ANSI formatting, and included as an `output` array in the JSON response.
- The primary benefit is context window preservation: without PAO, 50 test runs in a session can consume 500,000 tokens of context space that the agent needs for code and reasoning.
- PAO is currently in active development and available via `composer require nunomaduro/pao:0.x-dev --dev`.