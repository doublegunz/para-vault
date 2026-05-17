---
title: "Laravel 13 Expanded PHP Attributes: A Complete Guide"
slug: "laravel-13-expanded-php-attributes-a-complete-guide"
category: "Laravel"
date: "2026-03-27"
status: "published"
---

Every Laravel developer has written `protected $fillable`, `protected $hidden`, `public $tries`, and `$this->middleware('auth')` hundreds of times. These property-based configurations work, but they scatter settings across class bodies, constructors, and route files.

Laravel 13 changes this by going all-in on PHP attributes. You can now declare configuration above your classes and methods using a clean, declarative syntax. Models, jobs, controllers, console commands, Form Requests, and API resources all support attributes.

This article is a complete reference for every PHP attribute available in Laravel 13, organized by category with before/after examples for each one. All attributes are **optional**. The traditional property-based approach continues to work. You can adopt attributes gradually or stick with properties entirely.


## What Are PHP Attributes? {#what-are-php-attributes}

PHP attributes (introduced in PHP 8.0) are structured metadata that you attach to classes, methods, properties, or parameters. They look like this:

```php
#[Fillable(['title', 'content', 'status'])]
class Post extends Model
{
}
```

The `#[...]` syntax is native PHP. It is not a comment or a docblock. PHP parses attributes at compile time and makes them available via reflection. Laravel reads these attributes during class resolution and applies the configuration automatically.

The key benefit: configuration lives right where it is used, not buried inside the class body or spread across multiple files.


## Eloquent Model Attributes {#eloquent-model-attributes}

These attributes replace the familiar model properties that define mass assignment, serialization, table configuration, and relationships.

### #[Fillable] {#fillable}

Defines which fields can be mass-assigned via `create()`, `update()`, or `fill()`.

**Before:**

```php
class Post extends Model
{
    protected $fillable = ['title', 'slug', 'content', 'status'];
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'slug', 'content', 'status'])]
class Post extends Model
{
}
```

The class body is now empty (aside from relationships and methods). The configuration sits above the class, making it visible at a glance.

### #[Guarded] {#guarded}

Defines which fields are protected from mass assignment. The inverse of `#[Fillable]`.

**Before:**

```php
class User extends Model
{
    protected $guarded = ['id', 'is_admin'];
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Guarded;

#[Guarded(['id', 'is_admin'])]
class User extends Model
{
}
```

### #[Unguarded] {#unguarded}

Disables mass-assignment protection entirely. Equivalent to `protected $guarded = []`.

**Before:**

```php
class Setting extends Model
{
    protected $guarded = [];
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Unguarded;

#[Unguarded]
class Setting extends Model
{
}
```

This is a marker attribute with no parameters. Use it for models where every field should be mass-assignable, like settings or configuration tables.

### #[Hidden] {#hidden}

Hides fields when the model is serialized to JSON or an array (e.g., in API responses or `toArray()` calls).

**Before:**

```php
class User extends Model
{
    protected $hidden = ['password', 'remember_token'];
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Hidden;

#[Hidden(['password', 'remember_token'])]
class User extends Model
{
}
```

### #[Visible] {#visible}

The inverse of `#[Hidden]`. Only the listed fields will be included in serialization.

**Before:**

```php
class User extends Model
{
    protected $visible = ['id', 'name', 'email'];
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Visible;

#[Visible(['id', 'name', 'email'])]
class User extends Model
{
}
```

### #[Appends] {#appends}

Automatically includes accessor values in the model's serialized output.

**Before:**

```php
class User extends Model
{
    protected $appends = ['full_name'];

    public function getFullNameAttribute(): string
    {
        return $this->first_name . ' ' . $this->last_name;
    }
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Appends;

#[Appends(['full_name'])]
class User extends Model
{
    public function getFullNameAttribute(): string
    {
        return $this->first_name . ' ' . $this->last_name;
    }
}
```

### #[Table] {#table}

Configures the table name, primary key, key type, auto-incrementing, timestamps, and date format. This single attribute replaces up to six separate properties.

**Before:**

```php
class ExternalOrder extends Model
{
    protected $table = 'external_orders';
    protected $primaryKey = 'uuid';
    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Table;

#[Table(
    name: 'external_orders',
    key: 'uuid',
    keyType: 'string',
    incrementing: false,
    timestamps: false,
)]
class ExternalOrder extends Model
{
}
```

For simple cases where you only need to change the table name:

```php
#[Table('blog_posts')]
class Post extends Model
{
}
```

### #[Connection] (Model) {#connection-model}

Sets the database connection for the model.

**Before:**

```php
class PageView extends Model
{
    protected $connection = 'analytics';
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Connection;

#[Connection('analytics')]
class PageView extends Model
{
}
```

### #[Touches] {#touches}

Automatically updates the `updated_at` timestamp on parent models when this model is modified.

**Before:**

```php
class Comment extends Model
{
    protected $touches = ['post'];

    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }
}
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\Touches;

#[Touches(['post'])]
class Comment extends Model
{
    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }
}
```

### #[UsePolicy] {#use-policy}

Explicitly associates a policy class with the model. Useful when the policy does not follow Laravel's naming convention.

**Before (in AuthServiceProvider):**

```php
protected $policies = [
    Order::class => OrderPolicy::class,
];
```

**After:**

```php
use Illuminate\Database\Eloquent\Attributes\UsePolicy;
use App\Policies\OrderPolicy;

#[UsePolicy(OrderPolicy::class)]
class Order extends Model
{
}
```

### #[UseResource] and #[UseResourceCollection] {#use-resource}

Associates default API resource and resource collection classes with the model. These are used when you call `$model->toResource()` or `$collection->toResourceCollection()`.

```php
use Illuminate\Database\Eloquent\Attributes\UseResource;
use Illuminate\Database\Eloquent\Attributes\UseResourceCollection;
use App\Http\Resources\PostResource;
use App\Http\Resources\PostCollection;

#[UseResource(PostResource::class)]
#[UseResourceCollection(PostCollection::class)]
class Post extends Model
{
}
```

### Combining Multiple Model Attributes {#combining-model-attributes}

You can stack multiple attributes on a single model for a complete declarative configuration:

```php
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Attributes\Appends;

#[Table('users')]
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
#[Appends(['full_name'])]
class User extends Authenticatable
{
    use HasFactory, Notifiable;

    public function getFullNameAttribute(): string
    {
        return $this->first_name . ' ' . $this->last_name;
    }
}
```

The class body now contains only behavior (methods and relationships). All configuration is visible above the class declaration.


## Queue / Job Attributes {#queue-job-attributes}

These attributes replace the properties you set on queued job classes to control retry behavior, timeouts, connections, and queue names.

### #[Tries] {#tries}

Sets the maximum number of attempts before the job fails.

**Before:**

```php
class ProcessPayment implements ShouldQueue
{
    public $tries = 3;
}
```

**After:**

```php
use Illuminate\Queue\Attributes\Tries;

#[Tries(3)]
class ProcessPayment implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
}
```

### #[Timeout] {#timeout}

Sets the maximum number of seconds the job can run before it is killed.

**Before:**

```php
class GenerateReport implements ShouldQueue
{
    public $timeout = 120;
}
```

**After:**

```php
use Illuminate\Queue\Attributes\Timeout;

#[Timeout(120)]
class GenerateReport implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
}
```

### #[Backoff] {#backoff}

Sets the delay (in seconds) before retrying a failed job. Supports both fixed and exponential backoff.

**Before:**

```php
class SyncInventory implements ShouldQueue
{
    // Fixed: 30 seconds between retries
    public $backoff = 30;

    // Exponential: 10s, 30s, 60s
    // public $backoff = [10, 30, 60];
}
```

**After:**

```php
use Illuminate\Queue\Attributes\Backoff;

// Fixed backoff
#[Backoff(30)]
class SyncInventory implements ShouldQueue
{
}

// Exponential backoff
#[Backoff([10, 30, 60])]
class SyncInventory implements ShouldQueue
{
}
```

### #[MaxExceptions] {#max-exceptions}

Sets the maximum number of unhandled exceptions before the job is considered failed. Different from `#[Tries]`: tries counts all attempts, while max exceptions counts only attempts that throw an exception.

**Before:**

```php
class ImportCsvRows implements ShouldQueue
{
    public $maxExceptions = 3;
}
```

**After:**

```php
use Illuminate\Queue\Attributes\MaxExceptions;

#[MaxExceptions(3)]
class ImportCsvRows implements ShouldQueue
{
}
```

### #[Queue] {#queue-attribute}

Sets which queue the job should be dispatched to.

**Before:**

```php
class SendWelcomeEmail implements ShouldQueue
{
    public $queue = 'high';
}
```

**After:**

```php
use Illuminate\Queue\Attributes\Queue;

#[Queue('high')]
class SendWelcomeEmail implements ShouldQueue
{
}
```

### #[Connection] (Queue) {#connection-queue}

Sets which queue connection the job should use.

**Before:**

```php
class ProcessWebhook implements ShouldQueue
{
    public $connection = 'redis';
}
```

**After:**

```php
use Illuminate\Queue\Attributes\Connection;

#[Connection('redis')]
class ProcessWebhook implements ShouldQueue
{
}
```

### #[UniqueFor] {#unique-for}

Sets how long (in seconds) the unique lock should be held for jobs that implement `ShouldBeUnique`.

**Before:**

```php
class RebuildSearchIndex implements ShouldQueue, ShouldBeUnique
{
    public $uniqueFor = 3600;
}
```

**After:**

```php
use Illuminate\Queue\Attributes\UniqueFor;
use Illuminate\Contracts\Queue\ShouldBeUnique;

#[UniqueFor(3600)]
class RebuildSearchIndex implements ShouldQueue, ShouldBeUnique
{
}
```

### #[FailOnTimeout] {#fail-on-timeout}

When a job times out, mark it as failed immediately instead of retrying. A marker attribute with no parameters.

**Before:**

```php
class CallExternalApi implements ShouldQueue
{
    public $failOnTimeout = true;
}
```

**After:**

```php
use Illuminate\Queue\Attributes\FailOnTimeout;

#[FailOnTimeout]
class CallExternalApi implements ShouldQueue
{
}
```

### Combining Multiple Job Attributes {#combining-job-attributes}

A production-ready job configuration might look like this:

```php
use Illuminate\Queue\Attributes\Connection;
use Illuminate\Queue\Attributes\Queue;
use Illuminate\Queue\Attributes\Tries;
use Illuminate\Queue\Attributes\Timeout;
use Illuminate\Queue\Attributes\Backoff;

#[Connection('redis')]
#[Queue('high')]
#[Tries(3)]
#[Timeout(60)]
#[Backoff([5, 15, 30])]
class ProcessPayment implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function handle(): void
    {
        // Process the payment
    }
}
```

All retry behavior, connection, queue, and timeout configuration is visible at a glance without scrolling through the class body.


## Console Command Attributes {#console-command-attributes}

These attributes replace the `$signature`, `$description`, `$help`, and `$hidden` properties on Artisan command classes.

### #[Signature] {#signature}

Defines the command name, arguments, and options.

**Before:**

```php
class PruneUsers extends Command
{
    protected $signature = 'users:prune {--days=30 : Days of inactivity}';
}
```

**After:**

```php
use Illuminate\Console\Attributes\Signature;

#[Signature('users:prune {--days=30 : Days of inactivity}')]
class PruneUsers extends Command
{
    public function handle(): void
    {
        $days = $this->option('days');
        // ...
    }
}
```

The `Signature` attribute also accepts aliases:

```php
#[Signature('cache:warm', aliases: ['warm-cache'])]
class WarmCache extends Command
{
}
```

### #[Description] {#description}

Sets the command description shown in `php artisan list`.

**Before:**

```php
class SendMarketingEmails extends Command
{
    protected $description = 'Send scheduled marketing emails';
}
```

**After:**

```php
use Illuminate\Console\Attributes\Description;

#[Description('Send scheduled marketing emails')]
class SendMarketingEmails extends Command
{
}
```

### #[Help] {#help}

Sets the extended help text shown when running `php artisan help <command>`.

```php
use Illuminate\Console\Attributes\Help;

#[Help('This command processes all pending orders. Run during off-peak hours.')]
class ProcessOrders extends Command
{
}
```

### #[Hidden] (Console) {#hidden-console}

Hides the command from `php artisan list`. Useful for internal or debug commands.

```php
use Illuminate\Console\Attributes\Hidden;

#[Hidden]
class DebugInternals extends Command
{
}
```

### #[Usage] {#usage}

Adds usage examples to the help output. This attribute is repeatable.

```php
use Illuminate\Console\Attributes\Usage;

#[Usage('users:prune --days=60')]
#[Usage('users:prune --days=30 --dry-run')]
class PruneUsers extends Command
{
}
```

### Combining Console Attributes {#combining-console-attributes}

```php
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Help;
use Illuminate\Console\Attributes\Usage;

#[Signature('posts:generate-embeddings {--force : Regenerate all}')]
#[Description('Generate embeddings for posts')]
#[Help('Processes posts that do not have an embedding. Use --force to regenerate all.')]
#[Usage('posts:generate-embeddings')]
#[Usage('posts:generate-embeddings --force')]
class GeneratePostEmbeddings extends Command
{
    public function handle(): void
    {
        // ...
    }
}
```

No `$signature` or `$description` properties needed. Everything is declared above the class.


## Controller Attributes {#controller-attributes}

These attributes replace middleware definitions in constructors and route files, and authorization checks in controller methods.

### #[Middleware] {#middleware}

Attaches middleware to an entire controller (class-level) or specific methods (method-level). This attribute is repeatable.

**Before:**

```php
class PostController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
        $this->middleware('verified');
    }
}
```

**After:**

```php
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('auth')]
#[Middleware('verified')]
class PostController extends Controller
{
}
```

You can restrict middleware to specific methods with `only` and `except`:

```php
#[Middleware('auth')]
#[Middleware('admin', only: ['destroy'])]
#[Middleware('throttle:60,1', except: ['index', 'show'])]
class PostController extends Controller
{
}
```

Apply middleware to individual methods:

```php
class ReportController extends Controller
{
    #[Middleware('cache.headers:public;max_age=3600')]
    public function show(Report $report)
    {
        return view('reports.show', compact('report'));
    }
}
```

### #[Authorize] {#authorize}

Performs a policy check before the method executes. If the check fails, Laravel returns a 403 response.

**Before:**

```php
class PostController extends Controller
{
    public function edit(Post $post)
    {
        $this->authorize('update', $post);

        return view('posts.edit', compact('post'));
    }
}
```

**After:**

```php
use Illuminate\Routing\Attributes\Controllers\Authorize;

class PostController extends Controller
{
    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }
}
```

The second argument (`'post'`) is the route parameter name, not the variable name. Laravel resolves the model instance from route model binding and passes it to the policy.

For actions that do not require a model instance (like `create`), pass the model class:

```php
#[Authorize('create', [Post::class])]
public function create()
{
    return view('posts.create');
}
```

Restrict to specific methods with `only`:

```php
#[Authorize('manage-users', only: ['edit', 'update', 'destroy'])]
class UserController extends Controller
{
}
```

### Combining Controller Attributes {#combining-controller-attributes}

Here is a fully attributed controller from our [blog tutorial series](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes):

```php
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Illuminate\Routing\Attributes\Controllers\Authorize;

#[Middleware('auth')]
class PostController extends Controller
{
    public function index()
    {
        // Any authenticated user can list posts
    }

    public function create()
    {
        // Any authenticated user can see the create form
    }

    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        // Only the post owner can edit
    }

    #[Authorize('update', 'post')]
    public function update(UpdatePostRequest $request, Post $post)
    {
        // Only the post owner can update
    }

    #[Authorize('delete', 'post')]
    public function destroy(Post $post)
    {
        // Only the post owner can delete
    }
}
```

Authentication is enforced at the class level. Authorization is enforced at the method level, only on methods that need it.


## Form Request Attributes {#form-request-attributes}

These attributes configure how Form Requests handle errors and redirects.

### #[ErrorBag] {#error-bag}

Assigns validation errors to a named error bag, useful when a page has multiple forms.

**Before:**

```php
class CreatePostRequest extends FormRequest
{
    protected $errorBag = 'createPost';
}
```

**After:**

```php
use Illuminate\Foundation\Http\Attributes\ErrorBag;

#[ErrorBag('createPost')]
class CreatePostRequest extends FormRequest
{
    public function rules(): array
    {
        return ['title' => 'required|max:255'];
    }
}
```

### #[RedirectTo] {#redirect-to}

Redirects to a specific URL when validation fails.

**Before:**

```php
class StorePostRequest extends FormRequest
{
    protected $redirect = '/posts/create';
}
```

**After:**

```php
use Illuminate\Foundation\Http\Attributes\RedirectTo;

#[RedirectTo('/posts/create')]
class StorePostRequest extends FormRequest
{
}
```

### #[RedirectToRoute] {#redirect-to-route}

Redirects to a named route when validation fails.

**Before:**

```php
class StorePostRequest extends FormRequest
{
    protected $redirectRoute = 'posts.create';
}
```

**After:**

```php
use Illuminate\Foundation\Http\Attributes\RedirectToRoute;

#[RedirectToRoute('posts.create')]
class StorePostRequest extends FormRequest
{
}
```

### #[StopOnFirstFailure] {#stop-on-first-failure}

Stops validating remaining rules after the first failure. Useful for forms where later fields depend on earlier ones.

**Before:**

```php
class ImportRequest extends FormRequest
{
    protected $stopOnFirstFailure = true;
}
```

**After:**

```php
use Illuminate\Foundation\Http\Attributes\StopOnFirstFailure;

#[StopOnFirstFailure]
class ImportRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'file' => 'required|file|mimes:csv',
            'mapping' => 'required|array',
        ];
    }
}
```


## HTTP Resource Attributes {#http-resource-attributes}

These attributes configure API resource classes.

### #[Collects] {#collects}

Specifies which resource class a resource collection should use for individual items.

**Before:**

```php
class PostCollection extends ResourceCollection
{
    public $collects = PostResource::class;
}
```

**After:**

```php
use Illuminate\Http\Resources\Attributes\Collects;

#[Collects(PostResource::class)]
class PostCollection extends ResourceCollection
{
}
```

### #[PreserveKeys] {#preserve-keys}

Preserves the original collection keys in the response instead of resetting them to sequential numbers.

```php
use Illuminate\Http\Resources\Attributes\PreserveKeys;

#[PreserveKeys]
class UserResource extends JsonResource
{
    // ...
}
```


## Quick Reference Table {#quick-reference}

| Category | Attribute | Replaces | Namespace |
|----------|-----------|----------|-----------|
| **Model** | `#[Fillable]` | `$fillable` | `Illuminate\Database\Eloquent\Attributes` |
| | `#[Guarded]` | `$guarded` | Same |
| | `#[Unguarded]` | `$guarded = []` | Same |
| | `#[Hidden]` | `$hidden` | Same |
| | `#[Visible]` | `$visible` | Same |
| | `#[Appends]` | `$appends` | Same |
| | `#[Table]` | `$table`, `$primaryKey`, etc. | Same |
| | `#[Connection]` | `$connection` | Same |
| | `#[Touches]` | `$touches` | Same |
| | `#[UsePolicy]` | `$policies` array | Same |
| | `#[UseResource]` | Convention-based | Same |
| | `#[UseResourceCollection]` | Convention-based | Same |
| **Queue** | `#[Tries]` | `$tries` | `Illuminate\Queue\Attributes` |
| | `#[Timeout]` | `$timeout` | Same |
| | `#[Backoff]` | `$backoff` | Same |
| | `#[MaxExceptions]` | `$maxExceptions` | Same |
| | `#[Queue]` | `$queue` | Same |
| | `#[Connection]` | `$connection` | Same |
| | `#[UniqueFor]` | `$uniqueFor` | Same |
| | `#[FailOnTimeout]` | `$failOnTimeout` | Same |
| **Console** | `#[Signature]` | `$signature` | `Illuminate\Console\Attributes` |
| | `#[Description]` | `$description` | Same |
| | `#[Help]` | `$help` | Same |
| | `#[Hidden]` | `$hidden` | Same |
| | `#[Usage]` | Manual help text | Same |
| **Controller** | `#[Middleware]` | `$this->middleware()` | `Illuminate\Routing\Attributes\Controllers` |
| | `#[Authorize]` | `$this->authorize()` | Same |
| **Form Request** | `#[ErrorBag]` | `$errorBag` | `Illuminate\Foundation\Http\Attributes` |
| | `#[RedirectTo]` | `$redirect` | Same |
| | `#[RedirectToRoute]` | `$redirectRoute` | Same |
| | `#[StopOnFirstFailure]` | `$stopOnFirstFailure` | Same |
| **Resource** | `#[Collects]` | `$collects` | `Illuminate\Http\Resources\Attributes` |
| | `#[PreserveKeys]` | `$preserveKeys` | Same |


## Conclusion {#conclusion}

Laravel 13 introduces PHP attributes across six major areas of the framework: Eloquent models, queue jobs, console commands, controllers, Form Requests, and API resources. Every attribute is optional and backward compatible. You can adopt them one at a time, one class at a time.

Here are the key takeaways:

- **Attributes are configuration, not behavior.** They declare settings like fillable fields, retry counts, or middleware. They do not change how your code works, only where the configuration lives.
- **The `#[Table]` attribute is the most powerful.** It replaces up to six separate properties (`$table`, `$primaryKey`, `$keyType`, `$incrementing`, `$timestamps`, `$dateFormat`) with a single declaration.
- **Job attributes make queue configuration scannable.** Stacking `#[Tries]`, `#[Timeout]`, `#[Backoff]`, and `#[Queue]` above a job class tells you everything about its retry behavior without reading the class body.
- **Controller attributes keep security visible.** `#[Middleware('auth')]` on the class and `#[Authorize('update', 'post')]` on methods make authentication and authorization requirements obvious at a glance.
- **Mind the namespace.** Controller attributes live in `Illuminate\Routing\Attributes\Controllers`, not `Illuminate\Routing\Attributes`. Model attributes are in `Illuminate\Database\Eloquent\Attributes`. Queue attributes are in `Illuminate\Queue\Attributes`. The quick reference table above lists them all.
- **Pick a style and be consistent.** The worst outcome is mixing attributes and properties randomly across your codebase. If your team adopts attributes, apply them consistently. If you prefer properties, that is equally valid.

For practical examples of these attributes in action, check out our Laravel 13 tutorial series where we use `#[Fillable]` on models, `#[Middleware]` and `#[Authorize]` on controllers, and Form Request classes throughout a real blog application.