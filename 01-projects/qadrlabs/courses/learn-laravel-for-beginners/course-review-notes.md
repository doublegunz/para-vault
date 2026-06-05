# Course Review Notes

Review date: 2026-06-04

Scope:

- Module 1, Lesson 1: `module-1-getting-to-know-catatku-1/lesson-1-what-we-will-build-4.md`
- Module 1, Lesson 2: `module-1-getting-to-know-catatku-1/lesson-2-setting-up-your-laravel-project.md`
- Module 2, Lesson 3: `module-2-laravel-foundations/lesson-3-your-first-route-and-view-1.md`

## Test Log

Environment used for practical validation:

- OS: Ubuntu Linux
- PHP: 8.5.4
- Composer: 2.10.0
- Test project path: `sandbox/catatku`

Commands tested:

```bash
composer create-project --prefer-dist laravel/laravel catatku
cd catatku
php artisan --version
php artisan test
php artisan serve --host=127.0.0.1 --port=8013
curl -I http://127.0.0.1:8013
```

Observed results:

- `composer create-project --prefer-dist laravel/laravel catatku` created `laravel/laravel` v13.8.0.
- Installed framework version was `Laravel Framework 13.13.0`.
- The generated `.env` used `DB_CONNECTION=sqlite`.
- `database/database.sqlite` was created automatically.
- Initial migrations were run automatically during project creation.
- Default tests passed: `2` tests, `2` assertions.
- The development server returned `HTTP/1.1 200 OK`.

Important Composer output from project creation:

```text
Creating a "laravel/laravel" project at "./catatku"
Installing laravel/laravel (v13.8.0)
Created project in /home/gun-gun-priatna/obsidian-vault/sandbox/catatku
```

```text
> @php -r "file_exists('database/database.sqlite') || touch('database/database.sqlite');"
> @php artisan migrate --graceful --ansi

 INFO Preparing database.

 Creating migration table .. 8.00ms DONE

 INFO Running migrations.

 0001_01_01_000000_create_users_table .. 25.90ms DONE
 0001_01_01_000001_create_cache_table .. 16.96ms DONE
 0001_01_01_000002_create_jobs_table .. 26.55ms DONE
```

Test output:

```text
{"tool":"phpunit","result":"passed","tests":2,"passed":2,"assertions":2,"duration_ms":114}
```

HTTP check:

```text
HTTP/1.1 200 OK
X-Powered-By: PHP/8.5.4
Content-Type: text/html; charset=utf-8
```

Official Laravel 13 documentation checked:

- `https://laravel.com/docs/13.x/installation`
- The docs state that fresh Laravel applications use SQLite by default, create `database/database.sqlite`, and run the default migrations during application creation.

## Lesson 1 Notes

### Course Structure

Lesson 1 is a course orientation page. It is not a coding lesson, so it does not need command validation.

No H1 is needed in the lesson draft because qadrlabs.com uses the lesson title as the H1 on the published course page.

### Database Direction

Keep MySQL as the course database requirement. Even though current Laravel 13 scaffolding defaults to SQLite, the course intentionally uses MySQL so learners get hands-on experience with a database server that is common in real projects.

Because of this decision, Lesson 2 or Lesson 3 should explicitly show the switch from Laravel's generated SQLite default to MySQL. The tested project confirmed that Laravel now creates SQLite automatically, so the course should tell learners that this default is expected and that they will change it for Catatku.

### Formatting

Lesson 1 uses ASCII hyphens in the feature bullets, not em dashes or en dashes. That is acceptable.

The final H2 is:

```markdown
## Before You Continue
```

For consistency with the project article rules, consider adding an explicit anchor:

```markdown
## Before You Continue {#before-you-continue}
```

## Lesson 2 Notes

### Overview Section

The `## Overview {#overview}` section goes directly into `### What You'll Build`. The qadrlabs rule says H2 sections should include narrative text before the first H3.

Add a short paragraph after the Overview heading, for example:

```markdown
In this lesson, we will focus on the tools and the first Laravel project. The goal is not to memorize every configuration option yet, but to make sure you can create, open, run, and inspect a fresh Laravel application.
```

### Project Creation Command

The tested command works:

```bash
composer create-project --prefer-dist laravel/laravel catatku
```

Keep `composer create-project` for this beginner course. It is widely used in beginner Laravel tutorials and does not require learners to install the Laravel installer first.

Note for later testing lessons: Composer scaffolding currently creates PHPUnit tests by default, not Pest tests. If the course later introduces testing, keep the examples aligned with PHPUnit unless Pest is installed in a later lesson.

### Database Setup Timing

The final paragraph says:

```text
In the next lesson, we will set up our database and create the first migration for the Catatku application.
```

This needs a small clarification because Laravel 13 default scaffolding already has:

- `.env` set to `DB_CONNECTION=sqlite`
- `database/database.sqlite`
- default migrations already executed

Recommended rewrite:

```text
In the next lesson, we will replace Laravel's default SQLite setup with MySQL, then create the first application-specific migration for Catatku.
```

### Folder Structure Tree

The folder structure tree should mention files that Laravel 13 now creates immediately:

```text
database/
├── database.sqlite       ← Local SQLite database file
└── migrations/           ← Database table definitions
```

This helps beginners connect the real generated project to the explanation.

### PHP 8.3 Download Details

There is a version mismatch in the PHP upgrade section:

- Direct link uses `php-8.3.12-nts-Win32-vs16-x64.zip`
- Later text refers to `php-8.3.13-nts-Win32-vs16-x64.zip`
- The screenshot alt text says `download php 8.3`, but the image path contains `download php 8.2`

Recommended fix:

- Do not use a direct ZIP link for a specific patch version because old Windows PHP ZIP URLs can disappear or become stale.
- Link to the official PHP Windows download instructions for PHP 8.3 instead: `https://www.php.net/downloads.php?os=windows&version=8.3`.
- Tell learners to choose the latest **PHP 8.3 x64 Non Thread Safe (NTS)** ZIP build from that page.
- Avoid PHP 8.5 in this Windows/Laragon lesson unless the screenshots and filenames are updated. Laravel 13 requires PHP 8.3 or higher, but PHP 8.3 is the clearer target for beginners because the course screenshots and section titles are already based on PHP 8.3.

### Expected Output for `php artisan serve`

The expected output in the lesson is close enough, but current Laravel output includes leading formatting from Symfony Console and may vary slightly. Keep the simplified expected output, but introduce it as "similar to this" instead of exact output.

Suggested wording:

```markdown
You should see output similar to this:
```

### Laravel Folder Explanation

The statement about `#[Fillable([...])]` is aligned with the course's Laravel 13 convention, but it appears before the learner has created any model. It is acceptable as a preview, but the lesson may read more smoothly if it simply says that model fields will be introduced when the `Entry` model is created.

### Windows-Only Scope

Lesson 2 is clearly Windows-focused, which is fine. Since the course may be read by Linux or macOS users too, consider adding one sentence near the start:

```markdown
This lesson uses Windows and Laragon. If you are on macOS or Linux, install PHP, Composer, Node.js, and a database using your operating system's usual package manager, then continue from Step 6.
```

This keeps the Windows path intact while giving non-Windows learners a clear re-entry point.

## Lesson 3 Notes

### Practical Test

Lesson 3 was practiced in `sandbox/catatku` without starting the development server, per review instruction.

Files changed in the sandbox project:

- `routes/web.php`
- `resources/views/home.blade.php`
- `resources/views/entries/index.blade.php`

Commands run for validation:

```bash
php artisan route:list --except-vendor
php artisan view:cache
php artisan view:clear
```

Observed route list:

```text
GET|HEAD / .. routes/web.php:5
GET|HEAD entries .. routes/web.php:9

Showing [2] routes
```

Blade validation:

```text
INFO Blade templates cached successfully.
INFO Compiled views cleared successfully.
```

The lesson's route and Blade code is valid. The views compile successfully, and the expected routes exist.

### Formatting

The lesson contains `---` section separators. The qadrlabs writing rules say not to use horizontal separators between sections. Remove those separators and rely on H2 structure instead.

The `## Overview {#overview}` section goes directly into `### What You'll Build`. Add a short narrative paragraph after the Overview H2 before the first H3.

The entries view uses an em dash in:

```html
<title>My Entries — Catatku</title>
```

Replace it with an ASCII hyphen:

```html
<title>My Entries - Catatku</title>
```

The entries view also uses an emoji in the navbar:

```html
Catatku 📓
```

For consistency with the course/article style and easier cross-platform rendering, use plain text:

```html
Catatku
```

### Tailwind CDN Consistency

The home view uses:

```html
<script src="https://cdn.tailwindcss.com"></script>
```

The entries view uses:

```html
<script src="https://unpkg.com/@tailwindcss/browser@4"></script>
```

Use one Tailwind CDN style consistently in beginner lessons. Since the qadrlabs article guide uses Tailwind CDN examples and Lesson 3 already starts with `https://cdn.tailwindcss.com`, the simplest fix is to use the same CDN script in both views.

### Empty `href` Attributes

The home page intentionally uses empty `href` attributes for login/register links because authentication is not built yet. This works for the lesson, but it can be confusing when learners click the buttons.

Consider using `href="#"` for placeholders, or add one sentence that clicking the buttons will not navigate anywhere yet because authentication routes will be added later.

### Step 5 Run Instruction

Step 5 asks learners to make sure the development server is still running. That is fine for a hands-on lesson. For article/course consistency, consider saying "If the server is not running, start it again with `php artisan serve`" so learners who paused after Lesson 2 do not get stuck.
