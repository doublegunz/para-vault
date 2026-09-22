# Laravel 14: What We Know So Far and How to Get Ready

Every team has a version of the same sentence in a planning document somewhere: "we will deal with that when the next major release lands." Dependency upgrades, a PHP version bump, that one package with an abandoned maintainer, all of it gets parked behind the next big number. It feels responsible, because you are batching disruptive work into a single window instead of scattering it across the year.

The problem is that the parking spot has an expiry date, and for a lot of applications it has already passed. Laravel 12 stopped receiving bug fixes on August 13, 2026, and its security fixes end on February 24, 2027. Laravel 11 went fully end of life back on March 12, 2026. If your plan was to jump straight from 12 to 14 and skip a version, you are now running unsupported code for months while waiting for a release that has no announced date. Meanwhile the PHP floor is moving underneath you, and the jump you deferred is getting taller, not shorter.

So it is worth separating two things that usually get blended together in "Laravel 14" discussions: what is actually confirmed, and what is speculation dressed up as a feature list. This article does that split. It covers the release window, the dependency chain that sets the PHP requirement, the changes visible in the framework's development branch today, and the concrete work you can do this week regardless of when Laravel 14 ships.

## Overview {#overview}

This is a preview and readiness article rather than a build-along tutorial. There is no project to scaffold and nothing to run at the end. Laravel 14 does not exist as a stable release yet, so none of the code here has been executed against a shipped Laravel 14, and every snippet taken from the development branch is marked as such. Anything on that branch can be renamed, reworked, or reverted before release. What you will not find here is invented terminal output pretending to be a real run.

What you will get instead is a clear separation between the parts that are verifiable today, such as the version constraints sitting in the framework's `composer.json`, and the parts that are still a moving target.

### What This Article Covers

- The expected Laravel 14 release window and what the Laravel team has and has not officially announced.
- The dependency chain that makes PHP 8.4 the new minimum, traced back to its actual source.
- A problem with that PHP 8.4 requirement that is worth planning around now.
- The features and breaking changes already visible on the framework's development branch.
- Why the annual major release is no longer where most new Laravel features arrive.
- The readiness work you can do on your current application before any of this is final.

### What You'll Learn

- How to read Laravel's support policy table and work out exactly how much runway your application has.
- Why Symfony's release cycle, not Laravel's, effectively sets Laravel's minimum PHP version.
- Why targeting Laravel 14's minimum PHP version is the wrong call, and what to target instead.
- What `Route::query()`, `$user->authorize()`, and the other development branch additions are meant to solve.
- Which of the breaking changes so far can alter your application's behavior without throwing an error.
- How to audit your own application's upgrade readiness with Composer and Artisan.

### What You'll Need

- An existing Laravel application, ideally on Laravel 12 or 13, to run the audit commands against.
- Composer available on your command line.
- Familiarity with semantic versioning and how Composer version constraints such as `^13.0` work.
- No Laravel 14 installation, because there is not one to install.

## Where Laravel 14 Stands Right Now {#where-laravel-14-stands-right-now}

The single most important fact about Laravel 14 is the one that gets skipped in most roundups: the Laravel team has not announced a release date or a feature list. Everything circulating about Laravel 14 is inferred from commits landing on the `master` branch of `laravel/framework`, which is where development for the next major version happens. That is a legitimate source, but it is a development branch, not a changelog.

What we can rely on is the cadence. Laravel's versioning scheme commits to a major release roughly every Q1, and that schedule has held consistently. Laravel 12 arrived February 24, 2025, and Laravel 13 arrived March 17, 2026. On that pattern, Laravel 14 is expected in Q1 2027, with bug fixes running to roughly Q3 2028 and security fixes to roughly Q1 2029, following the standard policy of 18 months of bug fixes and 2 years of security fixes.

Here is where each version sits, with the Laravel 14 row marked as projected rather than confirmed.

| Version | PHP | Released | Bug Fixes Until | Security Fixes Until |
| --- | --- | --- | --- | --- |
| 11 | 8.2 to 8.4 | March 12, 2024 | September 3, 2025 | March 12, 2026 |
| 12 | 8.2 to 8.5 | February 24, 2025 | August 13, 2026 | February 24, 2027 |
| 13 | 8.3 to 8.5 | March 17, 2026 | September 30, 2027 | March 17, 2028 |
| 14 (expected) | 8.4 and up | Q1 2027 | Q3 2028 | Q1 2029 |

Read that table against your own application and the practical conclusion is usually the same. If you are on Laravel 12, you are already past bug fixes and have a few months of security coverage left. Waiting for Laravel 14 means sitting on unsupported code until Q1 2027, then attempting a two-major-version jump. Upgrading to Laravel 13 now buys you until March 2028 and turns the eventual Laravel 14 move into a single-version step. If you are already on Laravel 13, you have comfortable runway and no urgency at all.

## Why Laravel 14 Will Require PHP 8.4 {#why-laravel-14-will-require-php-8-4}

The PHP 8.4 minimum is the most widely repeated Laravel 14 claim, and unlike the feature lists it is something you can verify yourself right now rather than take on trust. Laravel's minimum PHP version is not really chosen in isolation; it is inherited. Laravel builds on a set of Symfony components for its console, routing, HTTP foundation, mailer, and more, so when Symfony raises its floor, Laravel's floor follows at its next major release.

Symfony 8.0 was released on November 27, 2025, and it requires PHP 8.4 as a minimum. That is the actual origin of the Laravel 14 requirement.

You can see the handoff by comparing the two branches of `laravel/framework` directly. The `13.x` branch, which is the current stable line, still straddles both Symfony generations:

```json
"php": "^8.3",
"symfony/console": "^7.4.0 || ^8.0.0",
"symfony/error-handler": "^7.4.0 || ^8.0.0",
"symfony/http-foundation": "^7.4.0 || ^8.0.0",
"symfony/http-kernel": "^7.4.0 || ^8.0.0",
"symfony/routing": "^7.4.0 || ^8.0.0",
```

The `||` in each constraint is what keeps Laravel 13 installable on PHP 8.3. By accepting either Symfony 7.4 or Symfony 8, the framework lets Composer resolve to the Symfony 7.4 components on a PHP 8.3 host, and to Symfony 8 on a newer one. That compatibility bridge is exactly what a major release gets to remove.

The `master` branch has already removed it:

```json
"php": "^8.4",
"symfony/console": "^8.1.0",
"symfony/error-handler": "^8.1.0",
"symfony/http-foundation": "^8.1.0",
"symfony/http-kernel": "^8.1.0",
"symfony/routing": "^8.1.0",
```

With the Symfony 7.4 fallback gone and every component pinned to `^8.1.0`, PHP 8.3 is no longer resolvable. The `"php": "^8.4"` line is a consequence of that decision rather than an independent one. This is the clearest confirmed signal we have about Laravel 14, and it comes from the repository itself rather than from a conference slide.

Two smaller details in that same file are worth noticing. The branch also requires `symfony/polyfill-php85` and `symfony/polyfill-php86`, which means the codebase is already reaching for syntax and functions from PHP versions beyond its own minimum and backfilling them for older runtimes. And the `extra.branch-alias` entry still reads `13.0.x-dev`, a leftover that has not been retargeted yet. That combination is a good reminder of what this branch is: real, but unfinished, and not yet formally labelled as Laravel 14 by its own metadata.

## The Catch in the PHP 8.4 Requirement {#the-catch-in-the-php-8-4-requirement}

Here is the part that tends to get missed, and it changes what you should actually install.

PHP branches get two years of active support followed by two years of security-only support. PHP 8.4 was released on November 21, 2024, which means its active support ends on December 31, 2026. Laravel 14 is expected in Q1 2027.

Those two dates do not overlap. If both hold, Laravel 14's minimum supported PHP version will already be in security-fix-only mode on the day Laravel 14 ships. It will not be receiving general bug fixes at all.

This is not a criticism of the decision, and it is not unusual. A framework's minimum is a floor for compatibility, not a recommendation. But it does mean that reading "Laravel 14 requires PHP 8.4" as "install PHP 8.4" gives you the worst available outcome: you do the work of a PHP upgrade and land on a branch that is already halfway through its life.

The dates make the better target obvious:

| PHP Branch | Released | Active Support Until | Security Support Until |
| --- | --- | --- | --- |
| 8.3 | November 23, 2023 | December 31, 2025 | December 31, 2027 |
| 8.4 | November 21, 2024 | December 31, 2026 | December 31, 2028 |
| 8.5 | November 20, 2025 | December 31, 2027 | December 31, 2029 |

PHP 8.5 is the version to aim for. It is already supported by Laravel 13, so you can move to it today without waiting for anything, and it keeps active support through the end of 2027, well past Laravel 14's release. Doing the PHP upgrade now, on your current Laravel version, also decouples the two migrations. You debug PHP-related breakage against a framework you already know, instead of discovering it tangled up with framework breakage during the Laravel 14 upgrade itself.

## What Is Already Visible on the master Branch {#what-is-already-visible-on-the-master-branch}

With the confirmed material covered, here is the speculative half. Everything in this section comes from commits on the `master` branch of `laravel/framework`. None of it has shipped in a stable release, none of it is officially announced as a Laravel 14 feature, and any of it can change or disappear before release. Treat the snippets as a preview of direction, not as an API you can code against.

The most interesting addition is a new routing verb helper for the HTTP `QUERY` method.

```php
// Preview from the master branch. Not available in any stable release,
// and subject to change before Laravel 14 ships.
Route::query('/search', function () {
    return request()->input('filter');
});
```

This one is easier to appreciate with the history behind it. Laravel 13.19 already added support for the `QUERY` method on the client and testing sides, with `Http::query()` for outgoing requests and the `query()` and `queryJson()` test helpers, as covered in [HTTP QUERY Method Support in Laravel 13.19](https://qadrlabs.com/post/http-query-method-support-in-laravel-13-19). What was missing was the routing side. To register a `QUERY` endpoint today you have to fall back to the generic matcher, writing `Route::match(['QUERY'], '/search', ...)` because there is no dedicated verb helper the way there is for `get` and `post`. `Route::query()` closes that gap and makes `QUERY` a first-class citizen alongside the other verbs.

Next is an authorization shorthand that moves the entry point onto the user model.

```php
// Laravel 13 and earlier
Gate::forUser($user)->authorize('viewAny', Post::class);

// Preview from the master branch
$user->authorize('viewAny', Post::class);
```

The distinction to keep in mind is that `authorize()` is not a friendlier `can()`. They behave differently on failure: `can()` returns a boolean you have to check, while `authorize()` throws an authorization exception that Laravel converts into a 403 response. Having `authorize()` directly on the user instance makes the stricter, throwing behavior as convenient to reach for as the permissive one, which matters because silently ignoring a `can()` result is a classic way to ship an authorization hole.

The `report()` helper gains a context array as an optional second argument.

```php
// Preview from the master branch
try {
    $order->charge();
} catch (Throwable $e) {
    report($e, ['order_id' => $order->id]);
}
```

Anyone who has opened an exception tracker at 2am knows why this matters. A stack trace tells you where something broke but rarely which record it broke on, and the usual workaround is wrapping the call in `Context::add()` or pushing data into the logger beforehand. Passing the context inline keeps the identifying data attached to the one report that needs it.

Two smaller items round out the list. `Storage::fake()` gains support for on-demand disks, so tests that exercise dynamically built disks can be faked the same way named disks already are:

```php
// Preview from the master branch
Storage::fake('ondemand');
```

And the `whereKey()` family expands with `orWhereKey()` and `orWhereKeyNot()`, along with support for passing subqueries into the existing `whereKey()` methods rather than only arrays or scalar values.

## Breaking Changes That Have Landed So Far {#breaking-changes-that-have-landed-so-far}

A major release is the framework's opportunity to fix things that could not be fixed without breaking someone, and the changes accumulated on `master` so far fit that description well. Most of them are corrections to behavior that was arguably wrong already.

| Change | What it does |
| --- | --- |
| Queue pause methods | The queue name moves to the first argument position, and the connection becomes optional, defaulting to the default connection |
| `lazy()` and `chunk()` | No longer mutate the underlying query builder while paginating, so the same builder can be safely reused afterwards |
| `findOr()` with arrays | Now invokes the fallback callback when passed an array of IDs, matching how `findOrFail()` already behaves |
| `Cache::has()` and `Cache::forget()` | Array arguments now work correctly: `has()` returns true only when every key exists, and `forget()` removes all of them |
| `MassPrunable` | Now includes soft-deleted models when pruning, consistent with the `Prunable` trait |

It is worth sorting these by how they will fail for you, because they are not equally dangerous. The queue pause signature change is the loud kind: reorder the arguments wrong and you get an error you can see in development. The rest are quiet. If you have code relying on `findOr()` skipping the callback for arrays, or on `MassPrunable` leaving soft-deleted records alone, nothing will throw. The behavior simply becomes different, and different pruning behavior in particular is the sort of thing you notice weeks later when rows you expected to still be there are gone.

That is the argument for reading the upgrade guide properly when it appears rather than upgrading and waiting for your error tracker to tell you what broke. Silent behavior changes do not show up in an error tracker.

## Why the Major Release Is Not Where Features Arrive {#why-the-major-release-is-not-where-features-arrive}

Look at that list of Laravel 14 features again and you might find it underwhelming. A routing helper, an authorization shorthand, an extra argument on `report()`. That reaction is the real story, and it reflects a genuine change in how Laravel ships rather than a slow year.

Laravel's versioning scheme promises that minor and patch releases never contain breaking changes, and the team has leaned hard into that promise. Because minors cannot break anything, they can be released as often as every week and can carry substantial new functionality. There is no reason to hold a non-breaking feature back for a major release, so nothing gets held back.

The evidence for this is the Laracon US 2026 keynote on July 29, 2026. It introduced the new image manipulation API, the `artisan dev` command, the head tag API, refreshable cache locks, debounced jobs, a new container binding syntax, Blade formatting in Pint, `artisan doctor`, and CPX. That is a substantial release worth of functionality by any measure. Laravel's own announcement post introduced the list with the phrase "here is everything you can do right now," because all of it shipped in Laravel 13.x minor releases. Not one item was a Laravel 14 preview. You can see the full rundown in the [Laracon US 2026 recap](https://qadrlabs.com/post/everything-announced-at-laracon-us-2026-laravel-ai-and-cloud-updates).

This is why the mental model matters more than the feature list. Under the old model, a major version was the event and you upgraded to get the new capabilities. Under the current model, features arrive continuously in minors, and the major release is the one moment per year when the framework is permitted to raise its floor and clean up breaking changes. Laravel 14 is best understood as a maintenance window, not a feature drop.

Two practical consequences follow. First, "we will wait for Laravel 14 to get the new stuff" is backwards, because the new stuff is already in the minor releases you are skipping by staying pinned. Second, staying current within your major line is where the actual return is. Running `composer update` on a 13.x application every few weeks gets you the image API, debounced jobs, and the rest, with no upgrade guide and no breaking changes to audit.

## Getting Your Application Ready Today {#getting-your-application-ready-today}

None of the preparation work depends on knowing Laravel 14's final feature list, which is exactly why it can start now. Every command below runs against your existing application.

Start by establishing where you actually are, since the version in your `composer.json` constraint is not necessarily the version you have installed:

```bash
composer show laravel/framework
```

This prints the installed version rather than the constraint. Check it against the support table earlier in this article to see how much runway you have. A constraint of `^13.0` tells you what is allowed; this tells you what is real.

Next, find out what is standing between you and PHP 8.4 or later:

```bash
composer why-not php 8.4
```

This is the single most useful command for upgrade planning and the most underused. It reports every installed package whose constraints would block that PHP version, which converts a vague worry about "some dependency probably is not ready" into a specific, finite list. Run it again with `8.5` to check the version you should actually be targeting. An empty result means your dependency tree is already clear and the only thing to change is your runtime.

Then look at how current your direct dependencies are:

```bash
composer outdated --direct
```

The `--direct` flag limits output to packages you required yourself rather than the full transitive tree, which keeps the list actionable. Pay particular attention to packages that are several major versions behind or whose last release was a long time ago. An abandoned package is the most common thing that turns a routine framework upgrade into a rewrite, and it is far better to discover that now than during the upgrade.

For a snapshot of the environment itself:

```bash
php artisan about
```

This summarizes your PHP version, Laravel version, configured drivers, and cached state in one place. It is a quick way to confirm that the PHP version your web server uses matches the one on your command line, which is a surprisingly common mismatch.

If you are on a recent Laravel 13 release, there is also a health check that flags environment problems directly:

```bash
php artisan doctor
```

Introduced at Laracon US 2026, this runs a set of checks across your application, including whether your `APP_KEY` is set, whether your PHP version matches what Composer expects, and whether required extensions are installed. It fixes what it can automatically and reports what it cannot.

With those results in hand, the sequence that minimizes risk is to move to PHP 8.5 on your current Laravel version first, then get onto Laravel 13 if you are not already, then stay current within 13.x with regular minor updates. By the time Laravel 14 arrives, the PHP requirement will already be satisfied, your dependencies will be current, and the upgrade becomes a single-version step. If you are still on Laravel 12, [How to Upgrade Laravel 12 to Laravel 13](https://qadrlabs.com/post/how-to-upgrade-laravel-12-to-laravel-13-a-step-by-step-guide) walks through that move, and [Laravel 13 Is Here](https://qadrlabs.com/post/laravel-13-is-here-ai-native-features-semantic-search-and-more) covers what you gain from it.

## Conclusion {#conclusion}

Laravel 14 is still far enough out that most of what is written about it is inference rather than announcement, but the parts that are confirmed are enough to plan against. The useful response is not to wait for the release, it is to do the preparation that pays off whether Laravel 14 arrives in January or June.

- **Nothing is officially announced yet.** There is no confirmed release date and no published feature list for Laravel 14. Everything circulating comes from the `master` branch of `laravel/framework` and can change before release.
- **Q1 2027 is the expected window.** Laravel has held an annual Q1 cadence through versions 12 and 13, and the standard policy of 18 months of bug fixes plus 2 years of security fixes puts Laravel 14's support through roughly Q1 2029.
- **PHP 8.4 comes from Symfony, not from Laravel.** The `master` branch pins every Symfony component to `^8.1.0` and drops the Symfony 7.4 fallback that keeps Laravel 13 installable on PHP 8.3. Symfony 8 requires PHP 8.4, so Laravel's floor follows.
- **Target PHP 8.5, not the minimum.** PHP 8.4 leaves active support on December 31, 2026, before Laravel 14 is expected to ship. PHP 8.5 is supported by Laravel 13 today and stays in active support through the end of 2027.
- **The quiet breaking changes deserve the most attention.** The queue pause signature change will fail loudly, but the `findOr()`, `Cache` array handling, and `MassPrunable` changes alter behavior without throwing, which means your error tracker will not catch them.
- **Major releases are no longer where features arrive.** Everything announced at Laracon US 2026, from the image manipulation API to `artisan dev` and debounced jobs, shipped in Laravel 13.x minor releases. Staying current within your major line is where the return is.
- **The preparation work is available now.** `composer why-not php 8.4`, `composer outdated --direct`, and `php artisan doctor` turn an abstract upgrade into a specific list of blockers, and none of them require knowing anything more about Laravel 14 than this article already covers.
