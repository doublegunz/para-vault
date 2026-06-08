# Building a Safe Soft Delete Feature with Database Transactions in Laravel 13

Imagine a user clicks "Archive Project" in your dashboard. Your code soft deletes the project row, then starts looping through its tasks to soft delete each one. Halfway through the loop, the database connection drops or a validation guard throws. Now you have a project marked as deleted while half of its tasks are still active, pointing back to a parent that no longer appears in any normal query. That is exactly the kind of silent data corruption that surfaces weeks later as a confusing bug report, and it is painful to clean up because there is no clear "before" state to roll back to. The fix is to treat the whole archive operation as a single unit of work: either every record is soft deleted together, or nothing changes at all. In this tutorial you will combine Laravel's `SoftDeletes` trait with database transactions to build an archive and restore feature that is safe by construction.

## Overview {#overview}

Soft deleting is easy to add to a single model, but real applications rarely delete one record in isolation. A project owns tasks, an order owns line items, an invoice owns entries. When you remove a parent, you usually want its children to follow, and you want that to happen atomically so a partial failure never leaves your data in a broken middle state. This tutorial walks through a complete `Project` and `Task` example where archiving a project cascades to all of its tasks inside a database transaction, and restoring brings them all back the same way.

### What You'll Build

- A `Project` model that owns many `Task` records, both using soft deletes.
- A dedicated `ProjectArchiver` service that soft deletes a project and cascades to its tasks inside a single transaction.
- Restore logic that brings a project and its previously archived tasks back atomically.
- A small set of routes and a controller to trigger archive and restore.
- A Pest test suite that proves the cascade works and that a mid-operation failure rolls everything back.

### What You'll Learn

- How to enable soft deletes on a model with the `SoftDeletes` trait and the `softDeletes()` migration column.
- How to cascade a soft delete to related records manually and on purpose.
- How to wrap multi-step writes in `DB::transaction` so they succeed or fail as one unit.
- How automatic rollback protects you when an exception is thrown mid-operation.
- How to query archived data with `withTrashed` and `onlyTrashed`.
- How to test cascading deletes, restores, and rollback behavior with Pest.

### What You'll Need

- PHP 8.3 or higher, which is the minimum version for Laravel 13.
- Composer and the Laravel installer available on your machine.
- SQLite, which ships ready to use with a fresh Laravel 13 project.
- Basic familiarity with Eloquent models and relationships.

## Step 1: Create the Project and Install Dependencies {#step-1-create-the-project}

Start by scaffolding a fresh Laravel 13 application with Pest already wired in. Pest is the testing framework you will use at the end to verify the cascade and rollback behavior, so installing it up front saves a round trip later.

Run the following commands in your terminal. The first creates a new project configured for SQLite and Pest, and the second moves you into the project directory.

```bash
laravel new soft-delete-demo --no-interaction --database=sqlite --pest --no-boost
cd soft-delete-demo
```

The `--database=sqlite` flag tells Laravel to create a local `database/database.sqlite` file and point your `.env` at it, which means you do not need to run a separate database server to follow along. The `--pest` flag installs Pest and replaces the default PHPUnit test stubs with Pest equivalents.

Confirm the application boots by starting the development server.

```bash
php artisan serve
```

You should see the server come up and report the address it is listening on.

```
   INFO  Server running on [http://127.0.0.1:8000].

  Press Ctrl+C to stop the server
```

Open that address in your browser to confirm the default Laravel welcome page renders, then stop the server with Ctrl+C so your terminal is free for the next steps.

## Step 2: Create Migrations with Soft Delete Columns {#step-2-create-migrations}

A soft delete works by writing a timestamp into a `deleted_at` column instead of physically removing the row. Eloquent then automatically hides any row that has a non-null `deleted_at` from normal queries. For that to work, both the `projects` table and the `tasks` table need that column, so you will add it to each migration.

Generate the two migrations. The first creates the `projects` table and the second creates the `tasks` table.

```bash
php artisan make:migration create_projects_table
php artisan make:migration create_tasks_table
```

Open the newly created `projects` migration in `database/migrations` and replace the `up` method body so the schema includes a name, a status, and the soft delete column.

```php
public function up(): void
{
    Schema::create('projects', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('status')->default('active');
        $table->timestamps();
        $table->softDeletes(); // adds a nullable deleted_at TIMESTAMP column
    });
}
```

The `softDeletes()` call is the important line. It adds a nullable `deleted_at` timestamp column that Eloquent's soft delete feature reads and writes. Because it is nullable, a freshly created project has `deleted_at` set to null, which means "not deleted."

Now open the `tasks` migration and define a table that belongs to a project. It also gets its own `deleted_at` column so tasks can be soft deleted independently of their parent.

```php
public function up(): void
{
    Schema::create('tasks', function (Blueprint $table) {
        $table->id();
        $table->foreignId('project_id')->constrained()->cascadeOnDelete();
        $table->string('title');
        $table->boolean('is_done')->default(false);
        $table->timestamps();
        $table->softDeletes(); // tasks can be soft deleted too
    });
}
```

The `foreignId('project_id')->constrained()` line creates a foreign key that references the `projects` table. The `cascadeOnDelete()` modifier only applies to a real, physical delete at the database level, so it does not interfere with soft deletes; it is there as a safety net for the rare case where you permanently force delete a project. Your soft delete cascade will be handled in application code, which gives you full control over the transaction boundary.

Run the migrations to create both tables.

```bash
php artisan migrate
```

Because `laravel new` already ran the framework migrations when it created the project, only your two new migrations are pending, so those are the ones you see run.

```
   INFO  Running migrations.

  2026_06_07_120000_create_projects_table ........................ 7.93ms DONE
  2026_06_07_120001_create_tasks_table .......................... 30.85ms DONE
```

Both `projects` and `tasks` tables now exist with their `deleted_at` columns in place, ready for the models.

## Step 3: Build the Models with the SoftDeletes Trait {#step-3-build-the-models}

With the tables ready, the next step is to teach Eloquent that these models support soft deletes and to define the relationship between them. Laravel 13 lets you declare model configuration like the fillable fields using PHP attributes instead of class properties, which keeps the metadata compact and visible at the top of the class.

Create the two models with Artisan.

```bash
php artisan make:model Project
php artisan make:model Task
```

Open `app/Models/Project.php` and add the `SoftDeletes` trait, the fillable attribute, and a `tasks` relationship.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['name', 'status'])]
class Project extends Model
{
    use SoftDeletes;

    /**
     * A project owns many tasks.
     */
    public function tasks(): HasMany
    {
        return $this->hasMany(Task::class);
    }
}
```

Two things are happening here. The `use SoftDeletes;` line activates the trait, which overrides the model's delete behavior so calling `delete()` writes the current timestamp into `deleted_at` rather than removing the row. The `#[Fillable(['name', 'status'])]` attribute is the Laravel 13 way of declaring mass-assignable fields; it replaces the older `protected $fillable` property and does the same job, allowing `Project::create(['name' => ..., 'status' => ...])` to assign those fields safely.

Now open `app/Models/Task.php` and configure it the same way, with its own fillable fields and a relationship back to the project.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['project_id', 'title', 'is_done'])]
class Task extends Model
{
    use SoftDeletes;

    /**
     * A task belongs to a project.
     */
    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }
}
```

Both models now support soft deletes and know about each other. At this point you could already soft delete a single project or a single task, but deleting a project would leave its tasks untouched and active. The next step builds the service that ties the cascade together safely.

## Step 4: Create an Archive Service with a Transaction {#step-4-create-archive-service}

This is the heart of the tutorial. Archiving a project means two writes: soft deleting the project and soft deleting all of its tasks. Those two writes have to happen together. If the project is archived but the tasks are not, you have orphaned active tasks pointing at a hidden parent. To guarantee atomicity, you will wrap both writes in `DB::transaction`, which commits everything if the closure finishes and rolls everything back if any exception is thrown inside it.

Create a dedicated service class. A service keeps this business logic out of the controller, which makes it easy to reuse and easy to test in isolation. Create the file `app/Services/ProjectArchiver.php` with the following contents.

```php
<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Support\Facades\DB;

class ProjectArchiver
{
    /**
     * Archive a project and all of its tasks atomically.
     *
     * Every write runs inside a single transaction, so if any
     * step fails the database is left exactly as it was before.
     */
    public function archive(Project $project): void
    {
        DB::transaction(function () use ($project) {
            // Soft delete each task that still belongs to this project.
            $project->tasks()->each(function ($task) {
                $task->delete();
            });

            // Soft delete the project itself last.
            $project->delete();
        });
    }
}
```

The `DB::transaction` closure defines the boundary of the unit of work. Inside it, `$project->tasks()->each(...)` iterates over the project's active tasks in chunks and calls `delete()` on each, which sets their `deleted_at`. After every task is soft deleted, `$project->delete()` soft deletes the project itself. Because the trait is active on both models, none of these rows are physically removed; they are simply marked as deleted. If anything inside the closure throws, for example a database error on the third task, Laravel rolls the transaction back and the earlier soft deletes are undone, so the project and all of its tasks remain active. You never end up in a half-archived state.

You can also pass a second argument to `DB::transaction` to retry the transaction when a deadlock is detected, which is useful under heavy concurrent writes. The following variation retries up to three times before giving up.

```php
DB::transaction(function () use ($project) {
    $project->tasks()->each(fn ($task) => $task->delete());
    $project->delete();
}, attempts: 3);
```

The `attempts: 3` argument tells Laravel that if the database reports a deadlock, it should roll back and replay the entire closure up to three times before throwing. This is safe precisely because the closure is atomic; replaying it never produces a partial result. For the rest of this tutorial the single-attempt version is enough, but it is worth knowing the option exists for high-concurrency scenarios.

## Step 5: Add the Restore Logic in a Transaction {#step-5-add-restore-logic}

Archiving is only half the feature. Users will want to undo an archive, and restoring has the same atomicity requirement: the project and its tasks should come back together or not at all. There is one subtlety to handle. When you restore a project, you only want to restore the tasks that were archived as part of that same operation, not tasks that were already soft deleted earlier for unrelated reasons. A clean way to express "bring back the tasks that are currently trashed for this project" is to query the relationship with `onlyTrashed`.

Add a `restore` method to the same `ProjectArchiver` service. Update the file so it now contains both methods.

```php
<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Support\Facades\DB;

class ProjectArchiver
{
    /**
     * Archive a project and all of its tasks atomically.
     */
    public function archive(Project $project): void
    {
        DB::transaction(function () use ($project) {
            $project->tasks()->each(function ($task) {
                $task->delete();
            });

            $project->delete();
        });
    }

    /**
     * Restore a soft deleted project and its trashed tasks atomically.
     */
    public function restore(Project $project): void
    {
        DB::transaction(function () use ($project) {
            // Restore the project first so the relationship query can run.
            $project->restore();

            // Restore only the tasks that are currently trashed.
            $project->tasks()->onlyTrashed()->each(function ($task) {
                $task->restore();
            });
        });
    }
}
```

The `restore` method mirrors `archive`. It opens a transaction, calls `$project->restore()` to set the project's `deleted_at` back to null, then queries `$project->tasks()->onlyTrashed()` to find the tasks that are still soft deleted and restores each one. The `onlyTrashed()` scope is what keeps the restore precise: it limits the query to rows that have a non-null `deleted_at`, so already-active tasks are left alone. As with archiving, the whole thing is inside `DB::transaction`, so a failure partway through the task restores rolls the project back to its archived state and you can safely try again.

## Step 6: Wire Up Routes and a Controller {#step-6-wire-up-routes}

Now expose the archive and restore actions through HTTP so they can be triggered from a browser or an API client. The controller stays thin: it receives the request, hands the work to the `ProjectArchiver` service, and returns a response. Keeping the controller thin is what lets the service own the transaction logic and remain independently testable.

Generate a controller for project archiving.

```bash
php artisan make:controller ProjectArchiveController
```

Open `app/Http/Controllers/ProjectArchiveController.php` and define two actions, one for archiving and one for restoring. The service is injected through method parameters, so Laravel's container resolves it for you.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Project;
use App\Services\ProjectArchiver;
use Illuminate\Http\JsonResponse;

class ProjectArchiveController extends Controller
{
    /**
     * Archive a project and cascade to its tasks.
     */
    public function archive(Project $project, ProjectArchiver $archiver): JsonResponse
    {
        $archiver->archive($project);

        return response()->json([
            'message' => 'Project archived.',
            'project_id' => $project->id,
        ]);
    }

    /**
     * Restore an archived project and its tasks.
     */
    public function restore(int $projectId, ProjectArchiver $archiver): JsonResponse
    {
        // The project is trashed, so withTrashed is required to find it.
        $project = Project::withTrashed()->findOrFail($projectId);

        $archiver->restore($project);

        return response()->json([
            'message' => 'Project restored.',
            'project_id' => $project->id,
        ]);
    }
}
```

Notice the difference between the two methods. The `archive` action uses route model binding, where Laravel automatically resolves the `Project` from the URL; this works because the project is still active when you archive it. The `restore` action cannot rely on default route model binding because a soft deleted project is hidden from normal queries, so it accepts the raw id and uses `Project::withTrashed()->findOrFail($projectId)` to locate the archived record. The `withTrashed()` scope removes the soft delete filter from the query so the trashed project becomes visible again.

Register the routes in `routes/web.php`.

```php
use App\Http\Controllers\ProjectArchiveController;

Route::delete('/projects/{project}/archive', [ProjectArchiveController::class, 'archive']);
Route::patch('/projects/{projectId}/restore', [ProjectArchiveController::class, 'restore']);
```

The archive route uses the `DELETE` verb because it represents removing the project, while the restore route uses `PATCH` because it modifies the existing trashed record back into an active one. With the routes registered, the feature is fully wired from HTTP down to the database. The next step verifies it actually behaves correctly.

## Step 7: Try It Out {#step-7-try-it-out}

Before writing automated tests, it helps to watch the feature work interactively. Artisan Tinker gives you a REPL with your full application booted, which is perfect for creating data, archiving it, and inspecting the results. Start Tinker.

```bash
php artisan tinker
```

First, create a project with a few tasks so you have something to archive. Paste the following into the Tinker prompt.

```php
$project = App\Models\Project::create(['name' => 'Website Redesign']);
$project->tasks()->createMany([
    ['title' => 'Design homepage'],
    ['title' => 'Build navbar'],
    ['title' => 'Write copy'],
]);
```

Tinker echoes back the created collection of tasks, confirming three tasks now belong to the project.

```
= Illuminate\Database\Eloquent\Collection {#7624
    all: [
      App\Models\Task {#7625
        title: "Design homepage",
        project_id: 1,
        updated_at: "2026-06-07 12:30:11",
        created_at: "2026-06-07 12:30:11",
        id: 1,
      },
      App\Models\Task {#7623
        title: "Build navbar",
        project_id: 1,
        updated_at: "2026-06-07 12:30:11",
        created_at: "2026-06-07 12:30:11",
        id: 2,
      },
      App\Models\Task {#7622
        title: "Write copy",
        project_id: 1,
        updated_at: "2026-06-07 12:30:11",
        created_at: "2026-06-07 12:30:11",
        id: 3,
      },
    ],
  }
```

Now archive the project through the service and check how many active tasks remain. Because soft deleted tasks disappear from normal queries, the active count should drop to zero.

```php
app(App\Services\ProjectArchiver::class)->archive($project);
App\Models\Task::where('project_id', 1)->count();
```

The count comes back as zero, which confirms the cascade reached every task.

```
= 0
```

Confirm the tasks were soft deleted rather than physically removed by counting only the trashed ones. If the rows still exist with a `deleted_at` timestamp, `onlyTrashed` will find all three.

```php
App\Models\Task::onlyTrashed()->where('project_id', 1)->count();
```

The trashed count is three, proving the data is safely archived and recoverable rather than gone.

```
= 3
```

Now restore the project and verify the tasks come back. Reload the project with `withTrashed` first, since it is currently archived.

```php
$archived = App\Models\Project::withTrashed()->find(1);
app(App\Services\ProjectArchiver::class)->restore($archived);
App\Models\Task::where('project_id', 1)->count();
```

The active task count is back to three, which shows the restore cascaded correctly and atomically.

```
= 3
```

Exit Tinker with `exit`. You have now seen the happy path end to end. The automated tests in the next step will also prove the unhappy path, where a failure rolls everything back.

## Step 8: Write Tests with Pest {#step-8-write-tests}

Manual checks in Tinker are reassuring, but the real value of the transaction shows up when something goes wrong, and you do not want to trigger random failures by hand. Pest lets you assert both the cascade behavior and the rollback behavior reliably. You will write tests that confirm archiving cascades to tasks, restoring cascades back, and a forced exception inside the transaction leaves the database untouched.

Create a feature test file.

```bash
php artisan make:test ProjectArchiveTest --pest
```

Open `tests/Feature/ProjectArchiveTest.php` and replace its contents with the following tests.

```php
<?php

use App\Models\Project;
use App\Models\Task;
use App\Services\ProjectArchiver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('archives a project and cascades to its tasks', function () {
    $project = Project::create(['name' => 'Launch Plan']);
    $project->tasks()->createMany([
        ['title' => 'Task one'],
        ['title' => 'Task two'],
    ]);

    app(ProjectArchiver::class)->archive($project);

    // The project and both tasks should be soft deleted.
    expect(Project::count())->toBe(0)
        ->and(Project::onlyTrashed()->count())->toBe(1)
        ->and(Task::count())->toBe(0)
        ->and(Task::onlyTrashed()->count())->toBe(2);
});

it('restores a project and cascades to its trashed tasks', function () {
    $project = Project::create(['name' => 'Launch Plan']);
    $project->tasks()->createMany([
        ['title' => 'Task one'],
        ['title' => 'Task two'],
    ]);

    $archiver = app(ProjectArchiver::class);
    $archiver->archive($project);
    $archiver->restore($project->fresh());

    // Everything should be active again.
    expect(Project::count())->toBe(1)
        ->and(Task::count())->toBe(2)
        ->and(Task::onlyTrashed()->count())->toBe(0);
});

it('rolls back the archive when a task deletion fails', function () {
    $project = Project::create(['name' => 'Launch Plan']);
    $project->tasks()->createMany([
        ['title' => 'Task one'],
        ['title' => 'Task two'],
    ]);

    // Force a failure midway by throwing inside a transaction listener.
    DB::listen(function ($query) {
        if (str_contains($query->sql, 'update "tasks"')) {
            throw new RuntimeException('Simulated database failure.');
        }
    });

    expect(fn () => app(ProjectArchiver::class)->archive($project))
        ->toThrow(RuntimeException::class);

    // Because the transaction rolled back, nothing was archived.
    expect(Project::count())->toBe(1)
        ->and(Project::onlyTrashed()->count())->toBe(0)
        ->and(Task::count())->toBe(2)
        ->and(Task::onlyTrashed()->count())->toBe(0);
});

it('hides trashed projects from normal queries but finds them with withTrashed', function () {
    $project = Project::create(['name' => 'Launch Plan']);

    app(ProjectArchiver::class)->archive($project);

    expect(Project::find($project->id))->toBeNull()
        ->and(Project::withTrashed()->find($project->id))->not->toBeNull();
});

it('permanently removes a project and its tasks with force delete', function () {
    $project = Project::create(['name' => 'Launch Plan']);
    $project->tasks()->create(['title' => 'Task one']);

    // forceDelete cascades at the database level via the foreign key.
    $project->forceDelete();

    expect(Project::withTrashed()->count())->toBe(0)
        ->and(Task::withTrashed()->count())->toBe(0);
});
```

Each test targets a specific guarantee. The first proves the archive cascade reaches every task. The second proves restore brings them all back. The third is the most important one for this tutorial: it registers a query listener that throws the moment Laravel issues the soft delete update on the `tasks` table, simulating a mid-operation database failure, and then asserts that nothing was archived because the transaction rolled the project's earlier soft delete back. The fourth confirms the default query scope hides trashed projects while `withTrashed` reveals them. The fifth shows that `forceDelete` removes rows permanently and that the database foreign key cascade cleans up the tasks.

Run the suite.

```bash
php artisan test
```

All tests should pass, confirming both the cascade and the rollback behave as designed.

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                       0.11s

   PASS  Tests\Feature\ProjectArchiveTest
  ✓ it archives a project and cascades to its tasks                     0.10s
  ✓ it restores a project and cascades to its trashed tasks             0.03s
  ✓ it rolls back the archive when a task deletion fails                0.02s
  ✓ it hides trashed projects from normal queries but finds them with w… 0.02s
  ✓ it permanently removes a project and its tasks with force delete    0.02s

  Tests:    7 passed (18 assertions)
  Duration: 0.37s
```

The passing rollback test is the proof that matters. It demonstrates that even when a write fails partway through, your data is never left in a half-archived state.

## How Database Transactions Protect Soft Deletes {#how-transactions-protect-soft-deletes}

Now that the feature works, it is worth stepping back to understand exactly why the transaction is doing the heavy lifting. A cascade operation is several separate writes, and without a transaction each write commits the instant it runs. That means a failure on the third write leaves the first two permanently applied, which is the partial state you are trying to avoid.

A database transaction groups those writes into a single atomic unit. Inside `DB::transaction`, none of the changes become permanent until the closure returns successfully and Laravel issues the commit. If any exception is thrown before that point, Laravel calls rollback, and the database discards every change made since the transaction began. Your soft deletes are just `UPDATE` statements that set `deleted_at`, so they are fully covered by this guarantee; a rolled-back transaction restores those columns to their previous null values as if the archive never started.

The optional `attempts` argument adds resilience on top of atomicity. When multiple requests touch overlapping rows at the same time, the database can detect a deadlock and abort one of them. Passing `attempts: 3` tells Laravel to roll back and replay the entire closure when that happens, up to three times. This is only safe because the closure is atomic; replaying an all-or-nothing operation can never produce a partial result, so a retry either fully succeeds or fully fails.

It is also possible to drive the cascade through Eloquent model events, for example by hooking into the `deleting` event on the `Project` model to soft delete its tasks automatically whenever a project is deleted. That approach moves the cascade closer to the model and can feel more "magical," but it also makes the transaction boundary less obvious and harder to reason about during failures. For a feature where atomicity is the whole point, the explicit service shown here keeps the transaction visible and the control flow easy to follow. Model-event driven cascades are a natural follow-up topic and will be covered in a future article.

## Soft Delete vs Hard Delete {#soft-delete-vs-hard-delete}

Choosing between a soft delete and a hard delete comes down to whether the data has value after the user removes it. Understanding the trade-off helps you decide where to apply the pattern from this tutorial.

A soft delete keeps the row in the table and only flags it as deleted, which means the record can be restored, audited, or reported on later. This is the right choice for business entities like projects, orders, invoices, and user accounts, where accidental deletion is costly and history matters. The cost is that your tables keep growing and you must remember that "deleted" rows still physically exist, which has implications for unique constraints and storage.

A hard delete, performed with `forceDelete` on a soft-deletable model or a plain `delete` on a model without the trait, removes the row permanently. This is appropriate for truly disposable data such as expired tokens, transient cache entries, or records you are legally required to purge. In the test suite you saw `forceDelete` used to permanently clear a project and let the database foreign key cascade remove its tasks. A common pattern is to soft delete first for safety and run a scheduled job that force deletes records older than a retention window, giving users a grace period to recover and your tables a way to stay lean.

## Working with Trashed Records: withTrashed and onlyTrashed {#working-with-trashed-records}

The `SoftDeletes` trait adds a global scope that quietly filters out trashed rows from every query, which is what makes soft deletes feel transparent. Most of the time that is exactly what you want, but archive and restore features specifically need to see the hidden rows, so it is worth being precise about the two scopes that reveal them.

The `withTrashed` scope removes the soft delete filter entirely, returning both active and trashed rows in one result set. You saw it in the controller's `restore` action, where the project is already archived and would otherwise be invisible to `findOrFail`. Reach for `withTrashed` whenever you need a complete view that includes deleted records, such as an admin screen that lists everything.

The `onlyTrashed` scope does the opposite, returning exclusively the rows that have been soft deleted. The restore service used it to find just the tasks that were currently archived so it could bring them back without touching active ones. Use `onlyTrashed` to build a "recycle bin" view or, as in this tutorial, to scope a cascade restore to precisely the right records. The following snippet shows both scopes side by side so the distinction is clear.

```php
// Active projects only (default behavior, trashed rows hidden).
Project::count();

// Active and trashed projects together.
Project::withTrashed()->count();

// Trashed projects only.
Project::onlyTrashed()->count();
```

Running these against a database where one project is archived returns the active count, the total count, and the trashed count respectively, which makes it easy to verify your queries are scoped the way you expect.

## Conclusion {#conclusion}

You built a soft delete feature that is safe even when something goes wrong. By combining Eloquent's `SoftDeletes` trait with a database transaction, archiving a project either removes it and all of its tasks together or leaves everything exactly as it was. Here are the key ideas to carry forward.

- **Soft deletes mark instead of remove.** The `SoftDeletes` trait and the `softDeletes()` migration column let Eloquent flag a row with `deleted_at` so it can be hidden, restored, and audited later.
- **Cascades need an explicit boundary.** Deleting a parent should cascade to its children, and doing that work inside a dedicated service keeps the logic reusable and testable.
- **Transactions make multi-step writes atomic.** Wrapping the cascade in `DB::transaction` means a failure on any step rolls back every earlier step, so you never land in a half-archived state.
- **Automatic rollback is your safety net.** Any exception thrown inside the transaction closure triggers a rollback and re-throws, which the rollback test proves leaves the database untouched.
- **withTrashed and onlyTrashed reveal hidden rows.** Use `withTrashed` for a complete view that includes deleted records and `onlyTrashed` to scope operations to just the archived ones.
- **Choose soft or hard delete by value.** Keep recoverable business data with soft deletes and reserve `forceDelete` for records that are genuinely disposable or past their retention window.
