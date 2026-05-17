---
title: "Build a Mini Service Container in PHP to Understand Dependency Injection"
slug: "build-a-mini-service-container-in-php-to-understand-dependency-injection"
category: "php"
date: "2026-04-28"
status: "published"
---

You type-hint a class in a controller constructor and Laravel hands you a fully resolved object, like magic. You call `app()->make(SomeService::class)` and all its nested dependencies appear, already wired together. But when someone asks you *how* that actually works under the hood, things get fuzzy fast. That gap becomes a real problem the moment you need to debug a tricky service binding, write your own service provider, or understand why your interface is not resolving to the right implementation. The solution is not to read more documentation. It is to build the thing yourself, from scratch, in about 100 lines of PHP.

In this tutorial, you will build a mini IoC container that does exactly what Laravel's container does at its core: manual binding, singleton support, interface-to-implementation mapping, and automatic dependency resolution using PHP's Reflection API. No framework, no magic. By the end, the magic will have a name.

## Overview {#overview}

This tutorial is self-contained and runs as a plain PHP project. You do not need Laravel installed. The goal is to isolate the container concept from the framework so that the mechanics are completely visible.

### What You'll Build

- A `Container` class with `bind()`, `singleton()`, `instance()`, and `make()` methods
- Autowiring support via PHP's `ReflectionClass` API, so the container resolves dependencies it has never seen before
- A working order notification system (the "app") that the container wires together automatically
- A live swap demo showing how changing one binding changes behavior across the whole system without touching any business logic

### What You'll Learn

- What a service container actually does step by step, not just conceptually
- How `bind()` differs from `singleton()` at the instance level
- How PHP Reflection reads constructor parameters at runtime to resolve dependencies recursively
- How binding an interface to a concrete class works and why it matters for testability
- How this maps back to what you do every day in Laravel

### What You'll Need

- PHP 8.1 or higher
- Composer (for PSR-4 autoloading only; no third-party packages required)
- Comfortable with PHP interfaces, type hints, and basic OOP

## Step 1: Project Setup {#step-1-project-setup}

Start by creating a clean directory for the project. All the interesting code lives in the `src/` folder, and a single `index.php` at the root acts as the entry point.

Create the project directory and move into it:

```bash
mkdir mini-container && cd mini-container
```

Create a `composer.json` file with just one concern: PSR-4 autoloading.

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
```

This tells Composer that any class in the `App\` namespace maps to the `src/` folder. Run the following command to generate the autoloader:

```bash
composer dump-autoload
```

Now create the folder structure. You can do this manually or with the shell:

```bash
mkdir -p src/Contracts src/Services
touch src/Container.php src/Contracts/LoggerInterface.php src/Contracts/MailerInterface.php
touch src/Services/FileLogger.php src/Services/SmtpMailer.php src/Services/SlackMailer.php
touch src/Services/OrderService.php src/Services/OrderController.php
touch index.php
```

Your final structure will look like this:

```
mini-container/
├── composer.json
├── index.php
└── src/
    ├── Container.php
    ├── Contracts/
    │   ├── LoggerInterface.php
    │   └── MailerInterface.php
    └── Services/
        ├── FileLogger.php
        ├── SmtpMailer.php
        ├── SlackMailer.php
        ├── OrderService.php
        └── OrderController.php
```

## Step 2: Create the Application Classes {#step-2-create-application-classes}

Before building the container itself, set up the application classes it will manage. The scenario is a simple order notification system: when an order is placed, the system logs the action and sends a confirmation email. This requires four components wired together in a chain.

Open `src/Contracts/LoggerInterface.php` and add the following:

```php
<?php

namespace App\Contracts;

interface LoggerInterface
{
    public function log(string $message): void;
}
```

Open `src/Contracts/MailerInterface.php`:

```php
<?php

namespace App\Contracts;

interface MailerInterface
{
    public function send(string $to, string $subject, string $body): void;
}
```

Both interfaces define a contract. Nothing in the rest of the system depends on a specific class; everything depends on these contracts. That is the design decision that makes swapping implementations possible later.

Open `src/Services/FileLogger.php`:

```php
<?php

namespace App\Services;

use App\Contracts\LoggerInterface;

class FileLogger implements LoggerInterface
{
    public function log(string $message): void
    {
        // Simulate writing to a log file by printing a timestamped line
        echo '[LOG] ' . date('H:i:s') . ' - ' . $message . PHP_EOL;
    }
}
```

Open `src/Services/SmtpMailer.php`:

```php
<?php

namespace App\Services;

use App\Contracts\MailerInterface;

class SmtpMailer implements MailerInterface
{
    public function send(string $to, string $subject, string $body): void
    {
        // Simulate dispatching an email over SMTP
        echo '[MAIL] To: ' . $to . ' | Subject: ' . $subject . ' | Body: ' . $body . PHP_EOL;
    }
}
```

Open `src/Services/SlackMailer.php`. This second implementation of `MailerInterface` will be used later to demonstrate how swapping a binding changes behavior across the whole system:

```php
<?php

namespace App\Services;

use App\Contracts\MailerInterface;

class SlackMailer implements MailerInterface
{
    public function send(string $to, string $subject, string $body): void
    {
        // Simulate posting a Slack notification instead of an email
        echo '[SLACK] Notification to: ' . $to . ' | ' . $subject . PHP_EOL;
    }
}
```

Open `src/Services/OrderService.php`. This class does the actual business logic. Notice that its constructor asks for interfaces, not concrete classes:

```php
<?php

namespace App\Services;

use App\Contracts\LoggerInterface;
use App\Contracts\MailerInterface;

class OrderService
{
    public function __construct(
        private MailerInterface $mailer,
        private LoggerInterface $logger
    ) {}

    public function placeOrder(string $customerEmail, string $product): void
    {
        // Log the event first, then send the confirmation
        $this->logger->log('Order placed: ' . $product . ' for ' . $customerEmail);

        $this->mailer->send(
            $customerEmail,
            'Order Confirmation',
            'Your order for ' . $product . ' has been placed successfully.'
        );
    }
}
```

Open `src/Services/OrderController.php`. This is the entry point, the class that a real HTTP request would reach:

```php
<?php

namespace App\Services;

class OrderController
{
    public function __construct(private OrderService $orderService) {}

    public function store(string $email, string $product): void
    {
        $this->orderService->placeOrder($email, $product);
        echo '[CONTROLLER] Order request handled.' . PHP_EOL;
    }
}
```

To feel the pain the container solves, write this in `index.php` temporarily and run it:

```php
<?php

require 'vendor/autoload.php';

use App\Services\FileLogger;
use App\Services\SmtpMailer;
use App\Services\OrderService;
use App\Services\OrderController;

// Manual wiring: every dependency is your responsibility
$logger      = new FileLogger();
$mailer      = new SmtpMailer();
$orderService = new OrderService($mailer, $logger);
$controller  = new OrderController($orderService);

$controller->store('alice@example.com', 'Mechanical Keyboard');
```

This works, but it scales poorly. With four classes, four lines of setup is manageable. In a real application with 20 to 50 services, this becomes a maintenance burden. The container takes this wiring off your hands. Clear `index.php` and proceed to build it.

## Step 3: Build the Container with Manual Binding {#step-3-build-container-manual-binding}

Open `src/Container.php`. The container at its core is a key-value store: you register something under a name ("bind" it), and later you retrieve it by that same name ("resolve" or "make" it).

```php
<?php

namespace App;

class Container
{
    // Stores registered factories or class name mappings: abstract => closure|string
    protected array $bindings = [];

    // Stores already-resolved singleton instances: abstract => object
    protected array $instances = [];

    /**
     * Register a binding in the container.
     *
     * The $factory can be a closure that builds and returns the service,
     * or a concrete class name string that the container will resolve.
     */
    public function bind(string $abstract, callable|string $factory): void
    {
        $this->bindings[$abstract] = $factory;
    }

    /**
     * Register a pre-built object directly.
     *
     * Useful when you have already constructed an instance and just want
     * the container to hand it out on every make() call.
     */
    public function instance(string $abstract, object $instance): void
    {
        $this->instances[$abstract] = $instance;
    }

    /**
     * Resolve (make) an instance of the given abstract from the container.
     */
    public function make(string $abstract): object
    {
        // If a singleton instance was previously cached, return it immediately
        if (isset($this->instances[$abstract])) {
            return $this->instances[$abstract];
        }

        // If a binding is registered, use it to resolve the instance
        if (isset($this->bindings[$abstract])) {
            $factory = $this->bindings[$abstract];

            if (is_callable($factory)) {
                // The factory is a closure; call it and pass the container itself
                // so the closure can resolve further dependencies if needed
                return $factory($this);
            }

            // The binding is a string (a concrete class name); resolve it recursively
            return $this->make($factory);
        }

        // No binding found; nothing to fall back on yet
        throw new \Exception("No binding found for [{$abstract}]. Did you forget to bind it?");
    }
}
```

Save the file and do a quick sanity check in `index.php`:

```php
<?php

require 'vendor/autoload.php';

use App\Container;
use App\Services\SmtpMailer;
use App\Services\FileLogger;
use App\Services\OrderService;
use App\Services\OrderController;
use App\Contracts\MailerInterface;
use App\Contracts\LoggerInterface;

$container = new Container();

// Register every class manually using closures
$container->bind(LoggerInterface::class, fn($c) => new FileLogger());
$container->bind(MailerInterface::class, fn($c) => new SmtpMailer());
$container->bind(OrderService::class, fn($c) => new OrderService(
    $c->make(MailerInterface::class),
    $c->make(LoggerInterface::class)
));
$container->bind(OrderController::class, fn($c) => new OrderController(
    $c->make(OrderService::class)
));

$controller = $container->make(OrderController::class);
$controller->store('alice@example.com', 'Mechanical Keyboard');
```

Run it:

```bash
php index.php
```

Expected output:

```
[LOG] 10:15:30 - Order placed: Mechanical Keyboard for alice@example.com
[MAIL] To: alice@example.com | Subject: Order Confirmation | Body: Your order for Mechanical Keyboard has been placed successfully.
[CONTROLLER] Order request handled.
```

It works. But the binding closures are already verbose. Notice how each closure explicitly calls `$c->make()` for every sub-dependency. This is exactly the boilerplate that autowiring eliminates.

## Step 4: Add Autowiring with PHP Reflection {#step-4-add-autowiring-reflection}

The most powerful feature of any modern container is the ability to resolve a class and all its nested dependencies automatically, without you registering every single one. Laravel calls this "zero-configuration resolution." The mechanism that makes it possible is PHP's `ReflectionClass` API.

The idea is straightforward: instead of being told how to build a class, the container reads the class's constructor signature using Reflection, figures out what each parameter requires, resolves those dependencies recursively, and then constructs the class with them.

Open `src/Container.php` and replace the `make()` method, then add the new `build()` method below it:

```php
/**
 * Resolve an instance of the given abstract from the container.
 *
 * If no manual binding exists, it falls through to autowiring via Reflection.
 */
public function make(string $abstract): object
{
    // Return a cached singleton instance if one exists
    if (isset($this->instances[$abstract])) {
        return $this->instances[$abstract];
    }

    // If a binding is registered, use it
    if (isset($this->bindings[$abstract])) {
        $factory = $this->bindings[$abstract];

        if (is_callable($factory)) {
            return $factory($this);
        }

        // Binding points to a concrete class; re-enter make() with the concrete name
        $abstract = $factory;
    }

    // No binding found; attempt to build the class automatically using Reflection
    return $this->build($abstract);
}

/**
 * Use PHP Reflection to instantiate a class and inject its constructor dependencies.
 *
 * This is the heart of "zero-configuration resolution." The container inspects
 * the constructor, resolves each typed parameter recursively, and then calls
 * newInstanceArgs() to construct the class with those resolved values.
 */
protected function build(string $concrete): object
{
    $reflector = new \ReflectionClass($concrete);

    // Interfaces and abstract classes cannot be instantiated directly.
    // If we reach here with one, the developer forgot to bind it.
    if (! $reflector->isInstantiable()) {
        throw new \Exception(
            "Class [{$concrete}] is not instantiable. "
            . "If it is an interface or abstract class, bind it to a concrete implementation first."
        );
    }

    $constructor = $reflector->getConstructor();

    // If the class has no constructor, there are no dependencies to resolve
    if ($constructor === null) {
        return new $concrete();
    }

    // Loop over every constructor parameter and resolve it
    $dependencies = array_map(function (\ReflectionParameter $param) use ($concrete) {
        $type = $param->getType();

        // A null type or a built-in type (string, int, bool, etc.) cannot be
        // resolved from the container automatically; check for a default value
        if ($type === null || $type->isBuiltin()) {
            if ($param->isDefaultValueAvailable()) {
                return $param->getDefaultValue();
            }

            throw new \Exception(
                "Cannot resolve primitive parameter [{$param->getName()}] "
                . "in [{$concrete}]. Provide a default value or bind it manually."
            );
        }

        // The parameter is a class or interface type; resolve it from the container.
        // This call is recursive: if the dependency itself has dependencies,
        // make() will resolve those too before returning.
        return $this->make($type->getName());
    }, $constructor->getParameters());

    // Construct the class with the resolved dependencies injected as arguments
    return $reflector->newInstanceArgs($dependencies);
}
```

With autowiring in place, you can strip most of the manual bindings from `index.php`. The only bindings you need now are the ones that map interfaces to their concrete implementations, because Reflection cannot guess which class implements an interface on its own:

```php
<?php

require 'vendor/autoload.php';

use App\Container;
use App\Services\SmtpMailer;
use App\Services\FileLogger;
use App\Services\OrderController;
use App\Contracts\MailerInterface;
use App\Contracts\LoggerInterface;

$container = new Container();

// These two lines are the only bindings needed.
// Everything else is resolved automatically by Reflection.
$container->bind(MailerInterface::class, SmtpMailer::class);
$container->bind(LoggerInterface::class, FileLogger::class);

$controller = $container->make(OrderController::class);
$controller->store('alice@example.com', 'Mechanical Keyboard');
```

Run it:

```bash
php index.php
```

```
[LOG] 10:15:30 - Order placed: Mechanical Keyboard for alice@example.com
[MAIL] To: alice@example.com | Subject: Order Confirmation | Body: Your order for Mechanical Keyboard has been placed successfully.
[CONTROLLER] Order request handled.
```

Same result, far less configuration. The container walked the entire dependency chain: `OrderController` needs `OrderService`, `OrderService` needs `MailerInterface` and `LoggerInterface`, both of those have bindings pointing to their concrete classes, and those concrete classes have no further dependencies. All of that happened in one `$container->make(OrderController::class)` call.

## Step 5: Add Singleton Support {#step-5-add-singleton-support}

Right now, every call to `make()` produces a new instance. Sometimes that is fine. A logger, however, is a good candidate for a shared instance: you want one logger for the life of the application, not a fresh one every time something needs to log.

The `singleton()` method wraps the factory in a closure that caches the result in `$this->instances` after the first resolution. Every subsequent `make()` call returns the same cached object.

Add the `singleton()` method to `src/Container.php`:

```php
/**
 * Register a singleton binding.
 *
 * The factory runs only once. After the first resolution, the resulting
 * instance is stored in $this->instances and returned directly on every
 * subsequent make() call, bypassing the factory entirely.
 */
public function singleton(string $abstract, callable|string $factory): void
{
    $this->bindings[$abstract] = function (Container $container) use ($abstract, $factory) {
        // Build the instance using the provided factory or concrete class name
        $instance = is_callable($factory)
            ? $factory($container)
            : $container->build($factory);

        // Cache it so make() returns this exact object from now on
        $container->instances[$abstract] = $instance;

        return $instance;
    };
}
```

Update `index.php` to use `singleton()` for the logger, and add a test to confirm the identity check:

```php
<?php

require 'vendor/autoload.php';

use App\Container;
use App\Services\SmtpMailer;
use App\Services\FileLogger;
use App\Services\OrderController;
use App\Contracts\MailerInterface;
use App\Contracts\LoggerInterface;

$container = new Container();

$container->bind(MailerInterface::class, SmtpMailer::class);
$container->singleton(LoggerInterface::class, FileLogger::class);

$controller = $container->make(OrderController::class);
$controller->store('alice@example.com', 'Mechanical Keyboard');

echo PHP_EOL;

// Verify that singleton() returns the same object on repeated calls
$logger1 = $container->make(LoggerInterface::class);
$logger2 = $container->make(LoggerInterface::class);

echo '[SINGLETON TEST] Same instance? ' . ($logger1 === $logger2 ? 'YES' : 'NO') . PHP_EOL;
```

```bash
php index.php
```

```
[LOG] 10:15:30 - Order placed: Mechanical Keyboard for alice@example.com
[MAIL] To: alice@example.com | Subject: Order Confirmation | Body: Your order for Mechanical Keyboard has been placed successfully.
[CONTROLLER] Order request handled.

[SINGLETON TEST] Same instance? YES
```

The `===` operator in PHP checks object identity (same instance in memory, not just equal values). The singleton works correctly.

## Step 6: Swap the Implementation {#step-6-swap-implementation}

This is where the payoff for programming against interfaces becomes concrete. The `OrderService` class knows nothing about `SmtpMailer`. It only knows about `MailerInterface`. That means you can change what `MailerInterface` resolves to without touching a single line of business logic.

Add a second binding block to `index.php` that replaces the mailer and places another order:

```php
echo PHP_EOL;
echo '--- Switching to Slack notifications ---' . PHP_EOL;
echo PHP_EOL;

// Rebind the interface to a different implementation
$container->bind(MailerInterface::class, \App\Services\SlackMailer::class);

// Resolve a fresh OrderController; OrderService will now receive a SlackMailer
$controller2 = $container->make(OrderController::class);
$controller2->store('bob@example.com', 'Standing Desk');
```

```bash
php index.php
```

```
[LOG] 10:15:30 - Order placed: Mechanical Keyboard for alice@example.com
[MAIL] To: alice@example.com | Subject: Order Confirmation | Body: Your order for Mechanical Keyboard has been placed successfully.
[CONTROLLER] Order request handled.

[SINGLETON TEST] Same instance? YES

--- Switching to Slack notifications ---

[LOG] 10:15:30 - Order placed: Standing Desk for bob@example.com
[SLACK] Notification to: bob@example.com | Order Confirmation
[CONTROLLER] Order request handled.
```

One `bind()` call changed the entire behavior of the notification channel. `OrderService` and `OrderController` were not touched. This is dependency inversion in practice, not just in theory.

## Step 7: Try It All Together {#step-7-try-it-out}

Here is the complete, final `index.php` that exercises every feature of the container:

```php
<?php

require 'vendor/autoload.php';

use App\Container;
use App\Services\SmtpMailer;
use App\Services\SlackMailer;
use App\Services\FileLogger;
use App\Services\OrderController;
use App\Contracts\MailerInterface;
use App\Contracts\LoggerInterface;

$container = new Container();

// Interface-to-concrete bindings; everything else is resolved automatically
$container->bind(MailerInterface::class, SmtpMailer::class);
$container->singleton(LoggerInterface::class, FileLogger::class);

// Scenario 1: Place an order with SMTP mailer
echo '=== Scenario 1: SMTP Mailer ===' . PHP_EOL;
$controller = $container->make(OrderController::class);
$controller->store('alice@example.com', 'Mechanical Keyboard');

echo PHP_EOL;

// Scenario 2: Verify singleton behavior
echo '=== Scenario 2: Singleton Check ===' . PHP_EOL;
$logger1 = $container->make(LoggerInterface::class);
$logger2 = $container->make(LoggerInterface::class);
echo '[SINGLETON TEST] Same instance? ' . ($logger1 === $logger2 ? 'YES' : 'NO') . PHP_EOL;

echo PHP_EOL;

// Scenario 3: Swap the mailer without touching any service class
echo '=== Scenario 3: Slack Mailer (swap) ===' . PHP_EOL;
$container->bind(MailerInterface::class, SlackMailer::class);
$controller2 = $container->make(OrderController::class);
$controller2->store('bob@example.com', 'Standing Desk');
```

Run the complete demo:

```bash
php index.php
```

```
=== Scenario 1: SMTP Mailer ===
[LOG] 10:15:30 - Order placed: Mechanical Keyboard for alice@example.com
[MAIL] To: alice@example.com | Subject: Order Confirmation | Body: Your order for Mechanical Keyboard has been placed successfully.
[CONTROLLER] Order request handled.

=== Scenario 2: Singleton Check ===
[SINGLETON TEST] Same instance? YES

=== Scenario 3: Slack Mailer (swap) ===
[LOG] 10:15:30 - Order placed: Standing Desk for bob@example.com
[SLACK] Notification to: bob@example.com | Order Confirmation
[CONTROLLER] Order request handled.
```

All three scenarios pass. The container is complete.

## How PHP Reflection Powers Autowiring {#how-php-reflection-powers-autowiring}

The `build()` method you wrote relies entirely on PHP's `ReflectionClass` API. This is worth understanding in detail, because it is the same mechanism that drives Laravel's zero-configuration resolution.

When you call `new \ReflectionClass($concrete)`, PHP produces an object that represents the class itself as a first-class value. You can inspect it without instantiating it. The most important methods in this context are `getConstructor()`, which returns a `ReflectionMethod` for the `__construct` method, and `getParameters()`, which returns an array of `ReflectionParameter` objects, one per constructor argument.

Each `ReflectionParameter` exposes the parameter's name, type hint, and whether it has a default value. The `getType()` call returns a `ReflectionType` object. Calling `isBuiltin()` on that type tells you whether it is a primitive (like `string`, `int`, or `bool`) or a class reference. If it is a class reference, you have a full class name and can call `$this->make()` on it recursively.

That recursion is the key. `OrderController` triggers `build(OrderController::class)`. That finds `OrderService` in the constructor. `build(OrderService::class)` runs next, finds `MailerInterface` and `LoggerInterface`. For both of those, `make()` finds a registered binding and resolves it to the concrete class. Those concrete classes have no constructor parameters, so `build()` returns `new $concrete()` directly. The call stack then unwinds, assembling the full object graph from the bottom up.

One important edge case: calling `$reflector->isInstantiable()` before attempting to build is essential. Interfaces and abstract classes will always return `false` here, which means the container fails with a clear error message instead of a cryptic PHP fatal error. That is why "is not instantiable; did you forget to bind it?" is a more helpful error than a generic instantiation failure.

## From This Mini Container to Laravel's Container {#from-mini-container-to-laravel}

The concepts you just implemented map directly to what you already use in Laravel every day.

Your `bind()` corresponds to `$this->app->bind()` inside a service provider's `register()` method. The closure pattern is identical: Laravel's `bind()` also accepts a closure that receives the container instance as its first argument.

Your `singleton()` corresponds to `$this->app->singleton()`. The caching behavior is the same. Laravel also offers `$this->app->scoped()` for request-scoped singletons, which resets between HTTP requests without resetting between sub-requests in the same process.

Your `build()` method using `ReflectionClass` is conceptually the same as what Laravel does in `Illuminate\Container\Container::build()`. Laravel's version handles additional cases such as variadic parameters, union types, and contextual bindings (where the same interface resolves to a different implementation depending on which class is being built). The Reflection approach is identical.

The `AppServiceProvider::register()` method in a Laravel application is simply the place where you register your manual `bind()` and `singleton()` calls before the application boots. Everything in `register()` that you have been writing since you started using Laravel is the same three-step pattern: pick an abstract name, point it at a concrete class or closure, and let the container's Reflection-based `build()` method handle the rest automatically.

## Conclusion {#conclusion}

Building this container from scratch reveals that there is no magic in how modern PHP frameworks handle dependency injection. The entire system rests on two ideas working together: a key-value store for registered bindings, and PHP Reflection for reading constructor signatures at runtime.

- **`bind()` creates a new instance on every resolution.** The factory closure runs every time `make()` is called with that abstract, making it suitable for stateless or lightweight services that should not be shared.
- **`singleton()` caches the first resolved instance.** After the initial build, the container returns the same object reference on every subsequent call, which is the right choice for shared stateful services like loggers, connections, and configuration objects.
- **Autowiring uses `ReflectionClass` to read constructor signatures.** The container resolves each typed parameter recursively, walking the full dependency tree automatically. You only need to register bindings for interfaces or classes that require non-resolvable constructor arguments.
- **Interface bindings are the key to swappable behavior.** When your classes depend on interfaces instead of concrete types, you can change an entire layer of your application (mailer, logger, storage) by updating a single `bind()` call in a service provider. No business logic changes required.
- **Laravel's `app()->bind()`, `app()->singleton()`, and zero-configuration resolution are the same patterns, scaled up.** Laravel's container adds contextual binding, tagging, method injection, and rebinding callbacks on top of this foundation. The foundation itself, however, is exactly what you just built.

Understanding this foundation makes service providers readable instead of mysterious, debugging container errors approachable instead of frustrating, and writing your own package bindings feel like a natural extension of patterns you already know.