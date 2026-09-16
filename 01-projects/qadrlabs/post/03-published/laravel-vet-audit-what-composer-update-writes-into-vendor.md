# Laravel Vet: Audit What composer update Writes Into vendor/ Before It Lands

You run `composer update`, watch a wall of green text scroll past, and go back to work. In that moment your project accepted thousands of lines of new code that nobody on your team has read. Not one line. You trusted a version number and a lock file hash, and that was the whole review.

That habit has already cost the PHP ecosystem. In 2026 the `laravel-lang` and `intercom/intercom-php` packages were both hijacked through stolen tokens, and developers who updated at the wrong moment pulled the malicious code down without a single warning. We covered the machine-side answer to that in [PHP Supply Chain Security: What Changed in Composer 2.10 and Why It Matters](https://qadrlabs.com/post/php-supply-chain-security-what-changed-in-composer-210-and-why-it-matters), where Composer learned to block known malware and known advisories. The catch is that those defences only catch what somebody has already reported. A brand new payload, published an hour ago, is on nobody's list yet.

Laravel Vet closes that gap from the other side. Announced by Nuno Maduro and built as a Composer plugin, it shows you the actual code that `composer update` is about to write into `vendor/`, it records the packages you have read in a `vet.json` file, and it fails your build when a package arrives that nobody has read. If reading diffs sounds like a chore, vet will hand each change to the coding agent already installed on your machine and report back with a verdict. In this tutorial you will install vet in a Laravel 13 project, record a trust baseline, intercept a real dependency update before it lands, let Claude read the diff for you, and wire the whole thing into CI.

## Overview {#overview}

This is a sequential, hands-on tutorial. The terminal blocks below were captured from a real run on a fresh Laravel 13 project with Laravel Vet v0.1.2, PHP 8.5.9 and Composer 2.10.0, and are reproduced exactly as they were printed. Two illustrative blocks come from the project's own documentation instead, and they are labelled where they appear. You will end with a project that refuses to install unreviewed dependency code, and a trust file you can commit alongside `composer.lock`.

### What You'll Build

- A Laravel 13 project with Laravel Vet installed as a Composer plugin.
- A `vet.json` trust file recording all 129 packages the project ships with.
- A gated `composer update` that stops before writing an unreviewed package into `vendor/`.
- An agent-assisted review that reads a real dependency diff and returns a PASS verdict.
- A CI job that fails the build when a dependency arrives that nobody has read.

### What You'll Learn

- How Laravel Vet hooks into Composer and where in the install cycle it intervenes.
- How to record a trust baseline with `--init` and what the resulting `vet.json` actually stores.
- How to read the delta between the version you trusted and the version Composer wants to write.
- How to hand a review to a local coding agent, and what PASS, FAIL, WARN and SKIP each mean.
- Why the `tree-v2:` hash matters more than the version number when a package is re-tagged.
- How vet's exit codes turn a reading habit into a build requirement.

### What You'll Need

- PHP 8.4 or newer. Laravel Vet declares `php: ^8.4`, so PHP 8.3 will not install it. This tutorial used PHP 8.5.9.
- The `dom`, `mbstring`, `openssl`, `phar` and `zip` extensions, all of which vet requires.
- Composer 2.x. This tutorial used Composer 2.10.0.
- A terminal, plus Git if you want to follow the commit step.
- Optional for the agent step: one of the coding agent CLIs vet knows about, which are `claude`, `codex`, `gemini` and `opencode`. This tutorial used `claude`.
- Basic familiarity with `composer.json`, `composer.lock` and what lives in `vendor/`.
- Laravel Vet is in beta at v0.1.2, released on 14 September 2026. The behaviour can change before the first stable release.

## Step 1: Set Up a Project to Audit {#step-1-set-up-a-project-to-audit}

Vet works with any PHP project that has a `composer.json`, so there are two ways into this tutorial. If you already have a project you want to audit, open its directory and skip straight to Step 2; everything that follows applies unchanged, only your package counts will differ. If you would rather follow along on something disposable, create a fresh Laravel 13 project.

```bash
laravel new vet-demo --no-interaction --database=sqlite --pest --no-boost
cd vet-demo
```

The installer prints a single line of JSON when it runs non-interactively:

```
{"success":true,"name":"vet-demo","directory":"/home/user/sandbox/vet-demo"}
```

Confirm what you are working with before going further, because vet cares about both numbers.

```bash
php artisan --version
composer --version
```

```
Laravel Framework 13.32.0
Composer version 2.10.0 2026-05-28 11:22:08
PHP version 8.5.9 (/home/linuxbrew/.linuxbrew/Cellar/php/8.5.9/bin/php)
```

Laravel 13.32.0 on PHP 8.5.9 clears the `^8.4` requirement comfortably. If your `php -v` reports 8.3, install a newer PHP before continuing, because Composer will refuse to resolve `laravel/vet` at all.

## Step 2: Install Laravel Vet {#step-2-install-laravel-vet}

Vet ships as a development dependency. It is a Composer plugin, which means Composer will ask for your permission before it is allowed to run code during install and update. Answer `y` to that question, because the plugin is the entire point: it is what lets vet see an operation before the bytes are written.

```bash
composer require laravel/vet --dev
```

```
./composer.json has been updated
Running composer update laravel/vet
Loading composer repositories with package information
Updating dependencies
Lock file operations: 1 install, 0 updates, 0 removals
  - Locking laravel/vet (v0.1.2)
Writing lock file
Installing dependencies from lock file (including require-dev)
Package operations: 1 install, 0 updates, 0 removals
  - Downloading laravel/vet (v0.1.2)
laravel/vet contains a Composer plugin which is currently not in your allow-plugins config. See https://getcomposer.org/allow-plugins
Do you trust "laravel/vet" to execute code and wish to enable it now? (writes "allow-plugins" to composer.json) [y,n,d,?]   - Installing laravel/vet (v0.1.2): Extracting archive
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

 INFO Discovering packages. 

 laravel/pail .. DONE
 laravel/pao .. DONE
 laravel/tinker .. DONE
 nesbot/carbon .. DONE
 nunomaduro/collision .. DONE
 nunomaduro/termwind .. DONE
 pestphp/pest-plugin-laravel .. DONE

89 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Vet has no trust file in this project yet. Run [./vendor/bin/vet --init] to record what you trust today.
> @php artisan vendor:publish --tag=laravel-assets --ansi --force

 INFO No publishable resources for tag [laravel-assets]. 

No security vulnerability advisories found.
Using version ^0.1.2 for laravel/vet
```

Three lines in that output matter. The `laravel/vet contains a Composer plugin which is currently not in your allow-plugins config` warning and the question under it are Composer asking for consent, and answering `y` writes the permission into `composer.json`. Then, right after the autoload dump, vet speaks for the first time: `Vet has no trust file in this project yet.` That notice is vet's plugin reporting that it has nothing to compare against yet, which is exactly right for a project that has never been audited.

Check what the consent wrote into your `composer.json`:

```bash
php -r '$j=json_decode(file_get_contents("composer.json"),true); echo json_encode($j["config"], JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES),"\n";'
```

```
{
    "optimize-autoloader": true,
    "preferred-install": "dist",
    "sort-packages": true,
    "allow-plugins": {
        "laravel/vet": true,
        "pestphp/pest-plugin": true,
        "php-http/discovery": true
    }
}
```

The `laravel/vet: true` entry is what makes the rest of this tutorial work. Without it Composer loads vet as an ordinary library, the binary still runs when you call it by hand, but nothing intercepts `composer update`. Commit that entry along with everything else.

## Step 3: Give Yourself a Real Update to Review {#step-3-give-yourself-a-real-update-to-review}

A brand new Laravel project already sits on the newest version of everything, so there is nothing pending for vet to show you. On a real project you would simply wait, because updates arrive on their own. To see the interesting behaviour today, pin one small package to an older release so that a genuine upgrade is waiting for you later. If you are following along on an existing project that already has updates pending, skip this step.

```bash
composer require carbonphp/carbon-doctrine-types:3.2.0 -W
```

```
Installing dependencies from lock file (including require-dev)
Package operations: 0 installs, 1 update, 0 removals
  - Downgrading carbonphp/carbon-doctrine-types (3.2.1 => 3.2.0): Extracting archive
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

 INFO Discovering packages. 

 laravel/pail .. DONE
 laravel/pao .. DONE
 laravel/tinker .. DONE
 nesbot/carbon .. DONE
 nunomaduro/collision .. DONE
 nunomaduro/termwind .. DONE
 pestphp/pest-plugin-laravel .. DONE

89 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Vet has no trust file in this project yet. Run [./vendor/bin/vet --init] to record what you trust today.
> @php artisan vendor:publish --tag=laravel-assets --ansi --force

 INFO No publishable resources for tag [laravel-assets]. 

No security vulnerability advisories found.
```

`carbonphp/carbon-doctrine-types` is a transitive dependency of `nesbot/carbon`, and the `-W` flag lets Composer adjust dependencies it did not previously manage directly. Note that the downgrade went through without vet stopping anything, and vet said why: there is no trust file yet, so it has no opinion to enforce. That changes in the next step.

## Step 4: Record Your Trust Baseline {#step-4-record-your-trust-baseline}

Vet cannot tell you what changed until it knows what you started from. Before anything else, run it once with no arguments and see what it says about a project with no trust file.

```bash
./vendor/bin/vet
echo "exit code: $?"
```

```

   WARN  No trust file yet. Run [./vendor/bin/vet --init] to record every package that vendor/ holds today in [vet.json].  

exit code: 1
```

The warning names the fix and the exit code is `1`, not `0`. That failing status is the whole design: a project with no trust file is a project where nothing has been reviewed, and vet treats that as a failure rather than a neutral state.

Now record the baseline. The `--init` option walks everything `vendor/` currently holds, trusts those exact bytes, and writes `vet.json` for the first time.

```bash
./vendor/bin/vet --init
```

The full listing runs to 129 lines, so the block below shows the first few entries and the closing summary, with the middle of the list elided:

```

  to trust (129)

  brianium/paratest v7.24.1 (dev) .............................. never trusted  
  brick/math 0.18.0 ............................................ never trusted  
  carbonphp/carbon-doctrine-types 3.2.0 ........................ never trusted  
  dflydev/dot-access-data v3.0.3 ............................... never trusted  
  doctrine/deprecations 1.1.6 (dev) ............................ never trusted  
  doctrine/inflector 2.1.0 ..................................... never trusted  
  doctrine/lexer 3.0.1 ......................................... never trusted  
  …
  webmozart/assert 2.4.1 (dev) ................................. never trusted  

   INFO  Trusted [129] packages, and wrote [vet.json].  

```
Two details are worth noticing. The `(dev)` marker separates development dependencies from runtime ones, and vet keeps that distinction in the trust file. And `carbonphp/carbon-doctrine-types 3.2.0` is in the list, which is the pinned version from Step 3, so the baseline has locked in the older bytes rather than the newest release.

Be clear about what `--init` claims. It trusts the bytes that are already on your disk and nothing else. It is not a security review, it is a starting line. If you would rather begin from scratch on a project that already has a `vet.json`, the `--fresh` option deletes the file first and then does the same thing.

Run vet again with no arguments to see the audit pass.

```bash
./vendor/bin/vet
```

```

   INFO  All [129] packages are trusted.  

```

Now open the file vet just wrote. It sits at the root of your project, next to `composer.json`.

```bash
head -c 400 vet.json
```

```
{
    "schema": 4,
    "require": {
        "brick/math": {
            "version": "0.18.0",
            "hash": "tree-v2:2874e68aa90095792f48cee52e27a38f16e74caea77707cce8390f8cdf497551"
        },
        "carbonphp/carbon-doctrine-types": {
            "version": "3.2.0",
            "hash": "tree-v2:ad33848c07e8c0d58a0f9011341684a226db43f96f7fc21c6cb99b9c66720f0f"
        },
```

Each entry records two things: the version you read, and a `tree-v2:` hash covering every file in the package. The hash is what makes the record meaningful, and we come back to why in the reference section below. Count what landed in each bucket:

```bash
php -r '$j=json_decode(file_get_contents("vet.json"),true); echo "schema: ",$j["schema"],"\n","require: ",count($j["require"]),"\n","require-dev: ",count($j["require-dev"]),"\n";'
```

```
schema: 4
require: 76
require-dev: 53
```

That is 76 runtime packages and 53 development packages, which adds up to the 129 vet reported. Commit `vet.json` now, because from this point on it is the record of what your team has agreed to run.

## Step 5: Audit an Update Before It Lands {#step-5-audit-an-update-before-it-lands}

This is the step that shows what vet is for. Loosen the pin you set in Step 3 so that Composer is free to move `carbonphp/carbon-doctrine-types` forward again.

```bash
sed -i 's#"carbonphp/carbon-doctrine-types": "3.2.0"#"carbonphp/carbon-doctrine-types": "^3.2"#' composer.json
```

If you prefer to edit by hand, change the constraint in the `require` block of `composer.json` from the exact version to a caret range:

```json
"carbonphp/carbon-doctrine-types": "^3.2",
```

Save the file and ask Composer to update just that package.

```bash
composer update carbonphp/carbon-doctrine-types
```


```
Loading composer repositories with package information
Updating dependencies
Lock file operations: 0 installs, 1 update, 0 removals
  - Upgrading carbonphp/carbon-doctrine-types (3.2.0 => 3.2.1)
Writing lock file
Installing dependencies from lock file (including require-dev)
  .

  to review (1)

  carbonphp/carbon-doctrine-types 3.2.0 → 3.2.1 .............. 4 files changed  
  │
  │   ~ composer.json
  │     @@ -32,5 +32,10 @@
  │                  "email": "kylekatarnls@gmail.com"
  │              }
  │          ],
  │     -    "minimum-stability": "dev"
  │     +    "minimum-stability": "dev",
  │     +    "extra": {
  │     +        "branch-alias": {
  │     +            "dev-main": "3.x-dev"
  │     +        }
  │     +    }
  │      }
  │
  │   ~ src/Carbon/Doctrine/CarbonDoctrineType.php
  │     @@ -4,13 +4,14 @@
  │      
  │      namespace Carbon\Doctrine;
  │      
  │     +use Carbon\CarbonInterface;
  │      use Doctrine\DBAL\Platforms\AbstractPlatform;
  │      
  │      interface CarbonDoctrineType
  │      {
  │     -    public function getSQLDeclaration(array $fieldDeclaration, AbstractPlatform $platform);
  │     +    public function getSQLDeclaration(array $fieldDeclaration, AbstractPlatform $platform): string;
  │      
  │     -    public function convertToPHPValue(mixed $value, AbstractPlatform $platform);
  │     +    public function convertToPHPValue(mixed $value, AbstractPlatform $platform): ?CarbonInterface;
  │      
  │     -    public function convertToDatabaseValue($value, AbstractPlatform $platform);
  │     +    public function convertToDatabaseValue(mixed $value, AbstractPlatform $platform): ?string;
  │      }
  │
  │   ~ src/Carbon/Doctrine/CarbonTypeConverter.php
  │     @@ -62,7 +62,7 @@
  │          /**
  │           * @SuppressWarnings(PHPMD.UnusedFormalParameter)
  │           */
  │     -    public function convertToDatabaseValue($value, AbstractPlatform $platform): ?string
  │     +    public function convertToDatabaseValue(mixed $value, AbstractPlatform $platform): ?string
  │          {
  │              if ($value === null) {
  │                  return $value;
  │     @@ -79,11 +79,11 @@
  │
  │   ~ README.md
  │
  │   … and 22 more lines, with [./vendor/bin/vet carbonphp/carbon-doctrine-types]
  │
  Packages: 1 to review, 128 trusted

   ERROR  [1] package is not trusted. Read every change with [./vendor/bin/vet -v]. Run [./vendor/bin/vet] in a terminal to pick the ones that you trust.  

   TIP  Run [./vendor/bin/vet] in a terminal to hand every change to your coding agent.  

```

Read that from the top. Composer resolved the upgrade and wrote the lock file, then reached the point where it would start copying files into `vendor/`. That is where vet's plugin took over. It downloaded the 3.2.1 archive, compared it against the 3.2.0 tree recorded in `vet.json`, and printed the actual diff: a `branch-alias` entry added to the package's own `composer.json`, return types tightened on three interface methods, `$value` changed to `mixed $value`, and an `is_object()` guard added before an `is_a()` call. Then it stopped the command with an error.

Confirm that "stopped" means what it says:

```bash
php -r '$j=json_decode(file_get_contents("vendor/composer/installed.json"),true); foreach($j["packages"] as $p){ if($p["name"]==="carbonphp/carbon-doctrine-types") echo "vendor: ",$p["version"],"\n";}'
php -r '$j=json_decode(file_get_contents("composer.lock"),true); foreach($j["packages"] as $p){ if($p["name"]==="carbonphp/carbon-doctrine-types") echo "lock:   ",$p["version"],"\n";}'
```

```
vendor: 3.2.0
lock:   3.2.1
```

The lock file moved to 3.2.1 but `vendor/` still holds 3.2.0. Nothing was written. This is the promise in the project's tagline made concrete: you saw the code before it landed, and it did not land. The `… and 22 more lines` note at the bottom of the report is vet capping a long diff, and it tells you the exact command that shows the rest.

## Step 6: Read a Single Package Delta {#step-6-read-a-single-package-delta}

Passing a package name to vet zooms in on one package and prints the full picture rather than the capped summary.

```bash
./vendor/bin/vet carbonphp/carbon-doctrine-types
```

The report opens with a header describing the package before it shows any diff:

```

  carbonphp/carbon-doctrine-types .............................. 3.2.0 → 3.2.1  
  state .......................... composer would write these bytes to vendor/  
  hash  tree-v2:0f158f3b909fc01e691ed5f5121186056232b049031e7d3a914676d49881ece5  
  source ................................................................ dist  
  contents .................................................. 10 files, 8.2 KB  
  path  /home/user/.cache/vet/archives/carbonphp/carbon-doctrine-types/3.2.1-f7b127842a71b1bc  

  delta ([3.2.0] → [3.2.1])
  identity ................................ ad33848c07e8 → 0f158f3b909f (dist)  
```

Every line there answers a question you would otherwise have to dig for. `state` says what Composer intends to do with these bytes. `source` says the package came from a `dist` archive rather than a git checkout. `contents` gives you the size of what you are agreeing to, which is 10 files and 8.2 KB. `path` points at the extracted archive in vet's cache, so you can open the files yourself in an editor. And `identity` shows the two tree hashes side by side, short form, which is the pair that has to change before vet will ask you anything.

Below that header comes the complete diff. The tail of it includes the parts the earlier report had capped:

```
               if ($value === null) {
                   return $value;
      @@ -79,11 +79,11 @@
               );
           }
       
      -    private function doConvertToPHPValue(mixed $value)
      +    private function doConvertToPHPValue(mixed $value): ?CarbonInterface
           {
               $class = $this->getCarbonClassName();
       
      -        if ($value === null || is_a($value, $class)) {
      +        if ($value === null || (is_object($value) && is_a($value, $class))) {
                   return $value;
               }
       

    ~ README.md
      @@ -4,7 +4,7 @@
       
       ## Documentation
       
      -[Check how to use in the official Carbon documentation](https://carbon.nesbot.com/symfony/)
      +[Check how to use in the official Carbon documentation](https://carbon.nesbot.com/guide/getting-started/symfony.html)
       
       This package is an externalization of [src/Carbon/Doctrine](https://github.com/briannesbitt/Carbon/tree/2.71.0/src/Carbon/Doctrine)
       from `nestbot/carbon` package.



   INFO  Record these bytes with [./vendor/bin/vet].  

```

Now you can see the whole change: a private method gained a return type, an `is_a()` call was guarded with `is_object()` first, and a documentation link was updated. Nothing here reads files, opens sockets, or runs shell commands. This is what a boring, safe patch release looks like, and being able to say that with confidence is the point.

By default vet compares against the version you trusted. The `--from` and `--to` options let you compare any two versions instead, which is useful when you are catching up on a package you have ignored for a while.

```bash
./vendor/bin/vet carbonphp/carbon-doctrine-types --from=3.1.0
```

```
  .

  carbonphp/carbon-doctrine-types ...................................... 3.2.1  
  hash  tree-v2:0f158f3b909fc01e691ed5f5121186056232b049031e7d3a914676d49881ece5  
  source ................................................................ dist  
  contents .................................................. 10 files, 8.2 KB  
  path ................................ vendor/carbonphp/carbon-doctrine-types  

  delta ([3.1.0] → [3.2.1])
  identity ................................ 9526f09603cc → 0f158f3b909f (dist)  
  compared against ....................................... your installed tree  

```

The header now reports `delta ([3.1.0] → [3.2.1])` and adds a `compared against` line saying the comparison ran against your installed tree. The single dot on the first line is vet's progress indicator: it prints one dot for every archive it downloads, so a run over many packages shows you that work is happening.

## Step 7: Hand the Review to Your Coding Agent {#step-7-hand-the-review-to-your-coding-agent}

Reading four files by hand was easy. Reading a Laravel upgrade that touches forty packages is not, and that is where most review habits quietly die. Vet's answer is to hand each change to a coding agent you already have installed, and it supports `claude`, `codex`, `gemini` and `opencode`. The agent reads and reports, and you still make the call.

This part needs a real terminal, because vet only asks questions when it detects one. Run it with no arguments:

```bash
./vendor/bin/vet
```

Vet prints the same report you saw in Step 5, then follows it with a question. Use the arrow keys to move to the second option and press enter:

```
 ┌ How do you want to review these packages? ──────────────────────────┐
 │ › ● Manually, and pick the packages that I trust                    │
 │   ○ Automatically, with my coding agent reading the changes first   │
 └─────────────────────────────────────────────────────────────────────┘

 ┌ How do you want to review these packages? ──────────────────────────┐
 │   ○ Manually, and pick the packages that I trust                    │
 │ › ● Automatically, with my coding agent reading the changes first   │
 └─────────────────────────────────────────────────────────────────────┘

 ┌ How do you want to review these packages? ────────────────────┐
 │ Automatically, with my coding agent reading the changes first │
 └───────────────────────────────────────────────────────────────┘
```

The prompt is rendered three times there because the capture recorded each repaint: the menu as it opens with the manual option selected, the menu after the arrow key moves the selection, and the collapsed confirmation once enter is pressed. In your own terminal you see one box that updates in place.

Vet then asks which model the agent should use. Press enter to keep the agent's own default, or type a name. For `claude` the offered list is `fable`, `opus`, `sonnet` and `haiku`, and each supported agent carries its own list.

```
 ┌ Which model do you want the agent to use? ───────────────────┐
 │ Press enter for the default model of [claude].             ⌄ │
 └──────────────────────────────────────────────────────────────┘
  Type a model name, pick one from the list, or press escape to go back.
```

Before a single byte of prompt leaves your machine, vet tells you how many packages it is about to send and how large the payload is, so you have a chance to stop it:

```
   INFO  [claude] reviews [1] package (5.8 KB). This takes a moment.  

  .
  carbonphp/carbon-doctrine-types 3.2.0 → 3.2.1 .............. 4 files changed  
  │  PASS   Only type declarations, a stricter is_object check and a branch-alias entry; nothing new reachable.
```

That is a real verdict from a real run. The agent read all four changed files and answered `PASS` with its reasoning on the same line: `Only type declarations, a stricter is_object check and a branch-alias entry; nothing new reachable.` Compare that against the diff you read yourself in Step 6 and you will find it accurate, which is the point of having read one by hand first.

## Step 8: Record What You Trust and Write the Bytes {#step-8-record-what-you-trust-and-write-the-bytes}

The agent advises. You decide. Vet follows the review with a checklist of every package still waiting on you, and it pre-picks the `PASS` rows so that a clean run is one keystroke away. Rows marked `FAIL` or `WARN` are left unpicked on purpose, because those are the ones that need your eyes.

```
 ┌ Which packages do you trust? ────────────────────────────────┐
 │ › ◼ PASS  carbonphp/carbon-doctrine-types  3.2.0 → 3.2.1     │
 └──────────────────────────────────────────────────────────────┘
  Press the space bar to pick a package, ctrl+a to pick every package, ente…
 ┌ Which packages do you trust? ────────────────────────────────┐
 │ 1 picked                                                     │
 └──────────────────────────────────────────────────────────────┘
```

Press the space bar to toggle a package, `ctrl+a` to pick everything, and enter to record what you picked. Vet writes the decision and tells you what to do next:

```

   INFO  Recorded [carbonphp/carbon-doctrine-types] [3.2.1] at [0f158f3b909f].  

   INFO  Run [composer install] to write those bytes to vendor/.  
```

Notice the short hash `0f158f3b909f` in that confirmation. It matches the `identity` line from Step 6, so what you trusted is the exact tree you read, not merely the version string `3.2.1`. Check the entry vet just rewrote:

```bash
php -r '$j=json_decode(file_get_contents("vet.json"),true); echo json_encode($j["require"]["carbonphp/carbon-doctrine-types"], JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES),"\n";'
```

```
{
    "version": "3.2.1",
    "hash": "tree-v2:0f158f3b909fc01e691ed5f5121186056232b049031e7d3a914676d49881ece5"
}
```

Now let Composer finish the job it started in Step 5. The lock file already points at 3.2.1, so a plain install is all that is left.

```bash
composer install
```

```

Package operations: 0 installs, 1 update, 0 removals
  - Upgrading carbonphp/carbon-doctrine-types (3.2.0 => 3.2.1): Extracting archive
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

 INFO Discovering packages. 

 laravel/pail .. DONE
 laravel/pao .. DONE
 laravel/tinker .. DONE
 nesbot/carbon .. DONE
 nunomaduro/collision .. DONE
 nunomaduro/termwind .. DONE
 pestphp/pest-plugin-laravel .. DONE

89 packages you are using are looking for funding.
Use the `composer fund` command to find out more!

   INFO  All [129] packages are trusted.  

```

The upgrade went through, and vet ran again after the install finished and confirmed `All [129] packages are trusted.` That second run is the plugin's other hook: it gates before operations execute, and it audits again afterwards. Commit the result so your team inherits the decision:

```bash
git add composer.json composer.lock vet.json
git commit -m "Trust carbonphp/carbon-doctrine-types 3.2.1"
```

`vet.json` belongs in version control next to `composer.lock`. It is the record of which bytes a human or an agent has actually read, and a teammate who pulls your branch inherits that record instead of starting from nothing.

## Step 9: Enforce Vet in CI {#step-9-enforce-vet-in-ci}

A reading habit that only exists on your laptop is not a policy. Vet turns it into one through its exit code, so the last step is to make your pipeline run it. First see what CI would see. Simulate a teammate bumping a dependency without recording trust by removing one entry from the trust file:

```bash
php -r '$j=json_decode(file_get_contents("vet.json"),true); unset($j["require"]["carbonphp/carbon-doctrine-types"]); file_put_contents("vet.json", json_encode($j, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES)."\n");'
./vendor/bin/vet
```

```

  to review (1)

  carbonphp/carbon-doctrine-types 3.2.1 never trusted  whole package, 10 files  

  Packages: 1 to review, 128 trusted

   ERROR  [1] package is not trusted. Run [./vendor/bin/vet] in a terminal to pick the ones that you trust.  

   TIP  Vet holds no earlier version to compare these packages to. Run [./vendor/bin/vet] in a terminal to hand the whole packages to your coding agent.  

```

That run exits with status `1`. Vet has no earlier version to diff against here, so it offers the whole package for review rather than a delta, and the `TIP` line says exactly that. Restore the entry and confirm the clean state exits with `0`:

```bash
git checkout vet.json
./vendor/bin/vet
```

```

   INFO  All [129] packages are trusted.  

```

Those two exit codes are all a pipeline needs. Add a job that installs dependencies and then runs vet:

```yaml
name: Dependencies

on: [push, pull_request]

jobs:
  vet:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          extensions: dom, mbstring, openssl, phar, zip

      # Vet also runs automatically after install, through its Composer plugin.
      - run: composer install --prefer-dist --no-progress

      # Run it explicitly as well, so the job fails on its own line
      # and the report is easy to find in the log.
      - run: ./vendor/bin/vet
```

Two details make this job work. The `extensions` list matches what vet declares it needs, and PHP 8.4 is the floor, so a runner pinned to 8.3 will fail at the install step rather than the audit step. Outside a terminal vet asks no questions and never calls a coding agent, so the job either prints a clean report and passes, or prints the packages nobody has read and fails. Someone then has to sit in front of a terminal, read the change, and record it, which is precisely the behaviour you wanted.


## How the Trust File Works {#how-the-trust-file-works}

Now that you have used `vet.json` end to end, it is worth understanding what it does and does not promise. The file lives at the root of your project, next to `composer.json`, and it holds one entry per package split across the same two buckets Composer uses.

```json
{
    "schema": 4,
    "require": {
        "carbonphp/carbon-doctrine-types": {
            "version": "3.2.1",
            "hash": "tree-v2:0f158f3b909fc01e691ed5f5121186056232b049031e7d3a914676d49881ece5"
        }
    },
    "require-dev": {
        "brianium/paratest": {
            "version": "v7.24.1",
            "hash": "tree-v2:075f8b7e73532ba3689126db0f91288a199bcba5f2743bc17a9bf37d53e030c1"
        }
    }
}
```

The `version` field is the human-readable half, and the `hash` field is the half that does the work. That `tree-v2:` value covers every file in the package, which means the entry is a statement about bytes rather than about a label. If a maintainer republishes the same version number with different code, whether through a re-tag or a compromised token, the hash no longer matches and the entry stops trusting that package. Vet then asks you to read the difference, even though the version string never moved. That specific attack, pushing new code onto an existing tag, is the one that hit `laravel-lang` and `intercom/intercom-php`.

The `schema` key is a version number for the file format itself, currently `4`. It lets vet recognise and migrate files written by older releases, which matters while the project is still in beta.

One honest limitation: an entry records that these exact bytes were accepted, not that they were safe. `--init` in particular trusts whatever is on your disk without anyone reading a line. Its value is that it draws a line in the sand, after which every new byte has to be looked at by someone.

## Where Vet Sits in the Composer Lifecycle {#where-vet-sits-in-the-composer-lifecycle}

Vet's usefulness comes from running at the right moment, and its Composer plugin subscribes to three events to get there. Understanding which event fires when explains every behaviour you saw above.

The first is `PRE_OPERATIONS_EXEC`, which Composer dispatches after it has resolved dependencies and written the lock file, but before it starts copying files into `vendor/`. This is the gate. Vet collects the pending operations, writes them to a temporary plan file, and runs its own binary against that plan. That is why Step 5 ended with the lock file at 3.2.1 while `vendor/` still held 3.2.0: the resolution had finished, the write had not started, and vet threw the command away in between.

The other two are `POST_INSTALL_CMD` and `POST_UPDATE_CMD`, which fire after an install or update completes. This is the audit, and it is the `All [129] packages are trusted.` line that appeared at the end of `composer install` in Step 8. The gate protects the write, the audit confirms the resulting state.

The `--plan` option you will see in the options table is the mechanism behind the gate rather than something you type yourself. The plugin passes it the temporary plan file so vet can audit operations that have not happened yet.

## The Four Verdicts {#the-four-verdicts}

The agent answers with one of four labels, and each one tells you something different about how much reading is left for you.

`PASS` means the agent read every changed file and found no attack. That is the verdict Step 7 produced, and in a terminal vet pre-picks those rows for you because they are the ones that need no further attention.

`FAIL` means the agent found something it wants you to look at, and it names the file and the reason. The project's own documentation illustrates it with a fabricated package that exfiltrates environment variables:

```
  acme/logger 1.2.0 → 2.0.0 ................................. 12 files changed
  │  FAIL   src/Ship.php reads .env and sends it to an unknown host
  │         src/Ship.php  it posts the contents of [.env] to [telemetry.example.com]
```

`WARN` means the rest of the reading is yours. It appears when the agent could not read every file, or when its answer did not arrive at all. A file can be unread for three reasons: it is too big for the prompt, it is not text, such as a `.phar` or a compiled binary, or it is not readable. Vet names the file, the reason and its size so you know exactly what is left:

```
  acme/tooling 4.1.0 → 4.2.0 ................................. 8 files changed
  │  WARN   the changes add two commands
  │         The agent did not read [1] file, because it is too big. Read it yourself:
  │         resources/schema.php  612.4 KB
```

`SKIP` means vet sent nothing to the agent in the first place, either because no file actually changed or because vet could not read the package's files.

Both of the blocks above come from the official Laravel Vet documentation rather than from this tutorial's run, because a clean upgrade of a small Carbon helper package does not produce a `FAIL`. Manufacturing one would mean shipping deliberately malicious code to Packagist, which is not a thing to do for a demonstration.

## How Vet Runs Your Coding Agent {#how-vet-runs-your-coding-agent}

Handing your dependency diffs to an AI agent deserves a closer look at what is actually being sent and under what constraints. Vet does not talk to any API of its own. It shells out to the agent CLI already installed on your machine, which means the review runs under your existing account, your existing configuration, and your existing billing.

For `claude`, vet builds the invocation with these flags:

```
--print --tools '' --no-session-persistence --output-format json --json-schema <schema>
```

Each one matters. `--print` runs a single non-interactive query rather than opening a session. `--tools ''` hands the agent an empty tool list, so it can read the diff text it was given and nothing else; it cannot open other files, run commands, or reach the network. `--no-session-persistence` means the review is not written into your session history. And `--output-format json` together with `--json-schema` forces the answer into a fixed shape, which is how vet turns a model's reply into a `PASS` or `FAIL` row instead of parsing prose. The other supported agents get equivalent treatment: `codex` runs through `exec` with `--sandbox read-only`, and both `gemini` and `opencode` are invoked in their plan or approval modes rather than an execution mode.

Three more guarantees are worth stating plainly. Vet prints the package count and the total prompt size before the first request leaves your machine, which you saw as `[claude] reviews [1] package (5.8 KB)`. The Composer plugin never triggers an agent review by itself, so an automated `composer install` in CI will not quietly start calling a model. And a verdict writes nothing to `vet.json`. Trust is only recorded after you answer the checklist, which keeps the decision with a person.

## Vet Command Options {#vet-command-options}

Vet has one command, and `./vendor/bin/vet --help` lists everything it accepts. A few of these are not covered in the project README, so here is the full set as the binary reports it:

```
Description:
  Audit what vendor/ holds, then record the packages that you trust

Usage:
  vet [options] [--] [<packages>...]

Arguments:
  packages              Audit these packages, as vendor/name

Options:
      --init            Record every package that vendor/ holds today, and start the trust file from them
      --fresh           Delete the trust file, then do the same as --init
      --from[=FROM]     Show the delta from this version rather than the trusted one
      --to[=TO]         The version to compare to (defaults to the installed one)
      --path[=PATH]     The project directory to audit (defaults to the current one)
      --plan[=PLAN]     Audit the operations that this composer plan file holds
      --no-cache        Re-download archives instead of reusing the cache
  -h, --help            Display help for the given command. When no command is given display help for the vet command
      --silent          Do not output any message
  -q, --quiet           Only errors are displayed. All other output is suppressed
  -V, --version         Display this application version
      --ansi|--no-ansi  Force (or disable --no-ansi) ANSI output
  -n, --no-interaction  Do not ask any interactive question
      --env[=ENV]       The environment the command should run under
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug
```

The ones you will reach for most often, and when:

| Option | What it does |
|--------|--------------|
| `<packages>` | Audits only the packages you name, and prints the full delta instead of the capped summary. |
| `--init` | Trusts every package `vendor/` holds today and writes `vet.json` for the first time. |
| `--fresh` | Deletes `vet.json`, then does the same as `--init`. |
| `--from=` | Shows the delta from this version rather than from the one you trusted. Needs a package name. |
| `--to=` | The version to compare to, defaulting to the installed one. Needs a package name. |
| `--path=` | Audits a different project directory, which is useful from a script or a monorepo root. |
| `--plan=` | Audits the operations held in a Composer plan file. This is how the plugin gates an update. |
| `--no-cache` | Re-downloads archives instead of reusing vet's cache. |
| `-v` | Prints every change in full rather than capping long diffs. |

The `-v` flag is the one the error message in Step 5 pointed at with `Read every change with [./vendor/bin/vet -v]`. On a large update it produces a lot of output, so pipe it to a pager or a file.

## Where Vet Fits Next to Composer 2.10 {#where-vet-fits-next-to-composer-2-10}

Vet does not replace anything Composer 2.10 added, and running both is the point. The two tools fail in different directions, which is what makes them worth stacking.

Composer 2.10 checks your dependencies against lists of things already known to be bad: the Aikido malware feed, published security advisories, abandoned packages. Those checks are fast, they need no attention from you, and they catch the attacks that somebody has already found and reported. Their blind spot is time. A payload published this morning is on nobody's list this afternoon, and the compromise window in the 2026 PHP incidents was measured in hours.

Vet checks your dependencies against a different thing entirely: whether a human or an agent has read this exact tree of bytes. It knows nothing about malware, and it will happily trust something malicious if you tell it to. What it will not do is let code into `vendor/` that nobody looked at, and it does not care whether the code is new, obscure, or unreported.

Enable the Composer 2.10 policies described in [PHP Supply Chain Security: What Changed in Composer 2.10 and Why It Matters](https://qadrlabs.com/post/php-supply-chain-security-what-changed-in-composer-210-and-why-it-matters), then put vet on top. The first stops what is known to be bad. The second stops what is simply unread.

## Beta Caveats {#beta-caveats}

Laravel Vet is in beta at v0.1.2, released on 14 September 2026, and the project states plainly that behaviour can change before the first stable release. Plan accordingly on anything you depend on.

The PHP floor is the practical constraint you will hit first. Vet declares `php: ^8.4`, so projects and CI runners still on 8.3 cannot install it at all, and that includes plenty of Laravel applications that are otherwise perfectly current. The output format is the second thing to watch: the report layout, the `schema` version in `vet.json`, and the flag set are all pre-1.0, so avoid parsing vet's stdout in a script and rely on its exit code instead, which is the interface least likely to shift.

None of that is a reason to wait. The trust file is plain JSON you can read and regenerate, the plugin adds no step to your workflow, and the worst case of adopting it early is a `--fresh` run against a newer release.

## Conclusion {#conclusion}

Dependency review has historically been a thing teams agreed was important and then never did, because the tooling made it a research project rather than a habit. Laravel Vet changes the economics: the diff comes to you at the moment it matters, the agent you already pay for can do the first pass, and the decision gets written down where your build can enforce it. Here is what to carry away.

- **Vet shows you code, not version numbers.** It prints the actual diff that `composer update` is about to write into `vendor/`, and it does so at Composer's `PRE_OPERATIONS_EXEC` event, before a single file is copied.
- **The trust file records bytes, not labels.** Each `vet.json` entry pairs a version with a `tree-v2:` hash over every file, so a republished tag with different code loses its trust even though the version string did not move.
- **`--init` is a starting line, not an audit.** It trusts whatever `vendor/` holds today so that everything arriving after that point has to be read by someone.
- **The exit code is the enforcement mechanism.** An unread package exits non-zero, which is what turns a good intention into a build requirement your CI job can hold you to.
- **The agent reads and you decide.** A `PASS`, `FAIL`, `WARN` or `SKIP` verdict never writes to `vet.json` on its own; trust is recorded only after you answer the checklist yourself.
- **Agent reviews are opt-in and constrained.** They run only when you ask for one in a terminal, never from the Composer plugin, and the agent is invoked with tools disabled, no session persistence and a fixed output schema.
- **It stacks with Composer 2.10 rather than replacing it.** Composer blocks what is known to be malicious, and vet blocks what is simply unread, which covers the window where a fresh payload is neither.
- **It works on any PHP project.** Laravel, Symfony, WordPress or plain PHP: a `composer.json` is the only requirement, alongside PHP 8.4 or newer.
