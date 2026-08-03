## 1. Before You Begin

Design patterns are not academic exercises. Every major PHP framework is built on them. Understanding which patterns a framework uses helps you use it more effectively, debug issues faster, and contribute to the codebase. This lesson maps the 23 GoF patterns to their real implementations in Laravel and Symfony, showing familiar framework code from a new perspective: the patterns behind the magic.

### What You'll Learn

- ✅ How Laravel's service container uses Factory and Singleton
- ✅ How middleware is Chain of Responsibility + Decorator
- ✅ How Eloquent events use Observer
- ✅ How filesystem/cache/mail use Strategy
- ✅ How Query Builder uses Builder
- ✅ How Symfony uses patterns differently
- ✅ A complete mapping of all 23 patterns to framework features

### What You'll Need

- All previous lessons completed (1-16)

---

## 2. Laravel Pattern Map

Laravel uses design patterns extensively, often combining multiple patterns in a single feature. Here is a comprehensive mapping:

| Pattern | Laravel Feature | How It Works |
|---------|---------------|--------------|
| **Singleton** | Service container (`$this->app->singleton(...)`) | Shared instances across the app |
| **Factory Method** | Model factories, `$this->app->bind(...)` | Container creates objects via closures |
| **Abstract Factory** | Database connectors (MySQL, PostgreSQL, SQLite) | `DatabaseManager` creates connection families |
| **Builder** | Query Builder, Mail, Notification | `DB::table('users')->where(...)->get()` |
| **Prototype** | `$model->replicate()` | Clones Eloquent models |
| **Adapter** | Filesystem (local, S3, FTP via `Flysystem`) | Uniform API for different storage backends |
| **Bridge** | Cache drivers (file, Redis, Memcached) | `CacheManager` separates cache API from driver |
| **Composite** | Blade component nesting | Components contain child components |
| **Decorator** | Middleware stack | Each middleware wraps the next handler |
| **Facade** | `Cache::get()`, `DB::table()`, `Auth::user()` | Static proxy to container-resolved services |
| **Proxy** | Lazy collections, relationship lazy loading | Delays expensive operations |
| **Flyweight** | Not commonly explicit | Shared configuration objects |
| **Strategy** | Filesystem drivers, Cache drivers, Mail drivers | `config('cache.default')` selects the driver |
| **Observer** | Model events, event/listener system | `UserObserver::created()`, `Event::dispatch()` |
| **Template Method** | Artisan commands (`handle()` method) | Base command defines lifecycle, you override `handle()` |
| **Command** | Artisan commands, queued jobs | `php artisan migrate`, `dispatch(new ProcessOrder)` |
| **Chain of Responsibility** | HTTP middleware pipeline | Request passes through auth, throttle, etc. |
| **State** | Not built-in (use packages like `spatie/laravel-model-states`) | Model state machines |
| **Iterator** | Collections (`collect([...])->map(...)`) | Uniform iteration API |
| **Mediator** | Event dispatcher acts as mediator between listeners | Decouples event producers and consumers |
| **Memento** | Not explicit (database rollback is conceptually similar) | Transaction rollback |
| **Visitor** | Not commonly used in Laravel | Used in code analysis tools |
| **Interpreter** | Blade template engine | Compiles Blade syntax to PHP |

---

## 3. Deep Dive: Middleware as Decorator + CoR

Laravel's middleware combines two patterns. The pipeline passes the request through each middleware (Chain of Responsibility). Each middleware wraps the next handler (Decorator). The following simplified pipeline implementation shows both patterns working together:

```php
// Simplified Laravel middleware pipeline
class Pipeline
{
    private array $pipes = [];

    public function through(array $pipes): static { $this->pipes = $pipes; return $this; }

    public function then(\Closure $destination): mixed
    {
        $pipeline = array_reduce(
            array_reverse($this->pipes),
            fn($carry, $pipe) => fn($request) => $pipe->handle($request, $carry),
            $destination
        );
        return $pipeline(request());
    }
}
```

Each middleware has the same signature: `handle($request, $next)`. It can modify the request, call `$next($request)` to continue, or return early to short-circuit the chain.

---

## 4. Deep Dive: Strategy in Cache/Filesystem

Laravel's `CacheManager` uses Strategy: the driver (file, Redis, Memcached) is selected at runtime via configuration. The following conceptual implementation shows how `CacheManager` resolves a cache store by reading the configured driver name:

```php
// Conceptually:
class CacheManager
{
    public function store(?string $name = null): CacheStore
    {
        $driver = $name ?? config('cache.default');
        return match ($driver) {
            'file'      => new FileStore(...),
            'redis'     => new RedisStore(...),
            'memcached' => new MemcachedStore(...),
        };
    }
}
```

All stores implement the same `CacheStore` interface. Switching from file to Redis requires changing one config value. Zero code changes.

---

## 5. Symfony Pattern Map

Symfony uses patterns with more explicit naming and less "magic" than Laravel.

| Pattern | Symfony Feature |
|---------|----------------|
| Factory | `ContainerBuilder`, service factories |
| Strategy | Security voters, serializer encoders |
| Observer | EventDispatcher, kernel events |
| Decorator | Security firewall layers |
| Composite | Form types (nested forms) |
| Builder | FormBuilder, ContainerBuilder |
| Proxy | Doctrine lazy-loading proxies |
| Template Method | Console commands (`execute()`) |
| Iterator | Finder component (file iteration) |
| Chain of Responsibility | Security authentication providers |
| Mediator | EventDispatcher (routes events between listeners) |

---

## 6. Exercises

**Exercise 1:** Open a Laravel project (or read the source on GitHub). Find the `Illuminate\Cache\CacheManager` class. Identify which pattern it uses and map the Strategy roles (Context, Strategy interface, Concrete strategies).

**Exercise 2:** Trace a request through Laravel's middleware pipeline. Identify how the request moves from one middleware to the next. Draw the chain.

**Exercise 3:** Look at Laravel's `Illuminate\Database\Eloquent\Model::replicate()` method. Identify the pattern and explain how it works.

---

## 7. Next Up - Lesson 18

Every major PHP framework is built on design patterns. Laravel uses Singleton (service container), Factory (bindings and model factories), Strategy (filesystem, cache, mail, and queue drivers), Observer (model events and event/listener system), Decorator combined with Chain of Responsibility (middleware pipeline), and Builder (Query Builder, Mail, Notification). Symfony uses similar patterns with more explicit naming and less "magic." Understanding these patterns means understanding frameworks at the architecture level, not just the API level.

In Lesson 18, you will review the complete pattern catalog, use the pattern selection guide to identify the right tool for each problem, and map out your next steps toward architectural mastery.