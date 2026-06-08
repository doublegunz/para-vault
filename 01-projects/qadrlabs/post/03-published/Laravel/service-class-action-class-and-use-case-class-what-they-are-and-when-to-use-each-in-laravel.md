---
title: "Service Class, Action Class, and Use Case Class: What They Are and When to Use Each in Laravel"
slug: "service-class-action-class-and-use-case-class-what-they-are-and-when-to-use-each-in-laravel"
category: "Laravel"
date: "2026-04-18"
status: "published"
---

Every Laravel tutorial eventually tells you to move business logic out of the controller. The advice is consistent. But the destination varies. Some articles say build a Service class. Others argue for Action classes. If you have been reading about Clean Architecture, you have also seen Use Case classes described as the proper home for application logic. After enough reading, you are more confused than you were before you started.

Without a clear mental model for each option, most developers pick one at random and apply it everywhere. The result is either a `UserService` that balloons to three thousand lines and forty methods, or an `app/Actions` folder with so many files that it takes thirty seconds to find the one you need, or an elaborate Use Case structure with DTOs and interfaces that adds four new files every time you change a form field. None of these outcomes is what the original advice intended.

These three patterns are not competing alternatives. Each one solves a different organizational problem. Service classes group related operations by topic. Action classes isolate a single operation. Use Case classes express a business intent in framework-agnostic terms. Once you understand what problem each one is solving, the choice becomes obvious rather than arbitrary. This article walks through all three using the same feature: user registration.

## Overview {#overview}

Here is a clear picture of what you will build, learn, and need before diving in.

### What You'll Build

You will implement user registration three times, once with each pattern. Each version starts from a simple initial implementation, gets tested, and is then refactored into its idiomatic form. By the end, you will have three working implementations of the same feature, a unit test suite for each, and a comparison table to guide future decisions.

### What You'll Learn

- The mental model behind each pattern and why it exists
- How to write a Service Class, an Action Class, and a Use Case Class for the same feature
- How to write unit tests for each pattern using `Mail::fake()` and `RefreshDatabase`
- How to refactor an initial draft toward idiomatic code while keeping tests green
- A decision framework for choosing the right pattern on your next feature

### What You'll Need

- Laravel 11 or higher
- PHP 8.2 or higher
- Composer and Artisan
- Familiarity with basic Laravel concepts: controllers, models, validation, and mail

## The Problem: A Fat Controller {#fat-controller}

Before looking at solutions, it helps to see the problem clearly. This is a typical controller method for user registration that has not been refactored yet. It will serve as the shared baseline for all three patterns in this article.

```php
<?php

// app/Http/Controllers/UserController.php

namespace App\Http\Controllers;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class UserController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Create the user record.
        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        // Send a welcome email.
        Mail::to($user->email)->send(new WelcomeMail($user));

        // Issue a Sanctum token.
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token'   => $token,
        ], 201);
    }
}
```

This controller method does four distinct things: it validates the request, creates the user, sends an email, and generates a token. None of the business logic inside it (user creation, email sending) can be reused from an Artisan command, a queue job, or an API controller without copying the code. It is also difficult to unit test in isolation because everything is coupled to the HTTP layer.

All three patterns in this article address the same structural problem. The difference is in how they organize the solution.

## Service Class {#service-class}

The Service Class pattern organizes logic by **entity or domain topic**, not by individual operation. Think of a `UserService` as the class that knows how to do everything related to a `User`: register, update, suspend, change password, verify email. This is the most common pattern in the Laravel community and appears in the majority of open-source Laravel projects.

A Service Class is designed to grow. Its methods share a context because they all operate on the same type of data. That shared context makes the class easy to navigate: if you need to touch user logic, you go to `UserService`.

### Characteristics of a Service Class

A Service Class is named after a noun that represents a domain entity or a capability: `UserService`, `OrderService`, `InvoiceService`, `PaymentService`. It has multiple public methods, each responsible for one operation on that entity. It is typically injected via the constructor using Laravel's service container. It can be reused from web controllers, API controllers, Artisan commands, and queue jobs without modification.

### Initial Implementation

Extract the registration logic from the controller into a `UserService`:

```php
<?php

// app/Services/UserService.php

namespace App\Services;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class UserService
{
    public function register(array $data): User
    {
        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        Mail::to($user->email)->send(new WelcomeMail($user));

        return $user;
    }
}
```

The controller now delegates to the service and stays focused on HTTP concerns:

```php
<?php

// app/Http/Controllers/UserController.php

namespace App\Http\Controllers;

use App\Services\UserService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    // Laravel's service container resolves UserService automatically
    // when the controller is instantiated, no manual wiring needed.
    public function __construct(private readonly UserService $userService) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $this->userService->register($validated);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token'   => $token,
        ], 201);
    }
}
```

### Testing the Service Class

Because `UserService` is a plain PHP class with no dependency on the HTTP layer, you can instantiate it directly in a unit test. Create the test file:

```php
<?php

// tests/Unit/Services/UserServiceTest.php

namespace Tests\Unit\Services;

use App\Mail\WelcomeMail;
use App\Models\User;
use App\Services\UserService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class UserServiceTest extends TestCase
{
    use RefreshDatabase;

    private UserService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new UserService();
    }

    public function test_register_creates_user_in_database(): void
    {
        // Mail::fake() intercepts all outgoing mail so the test does not
        // attempt to connect to a real mail server.
        Mail::fake();

        $user = $this->service->register([
            'name'     => 'John Doe',
            'email'    => 'john@example.com',
            'password' => 'secret123',
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', ['email' => 'john@example.com']);
    }

    public function test_register_sends_welcome_email(): void
    {
        Mail::fake();

        $this->service->register([
            'name'     => 'John Doe',
            'email'    => 'john@example.com',
            'password' => 'secret123',
        ]);

        // Mail::assertSent() verifies that the mail was queued by the fake driver,
        // without any real network call.
        Mail::assertSent(WelcomeMail::class, fn ($mail) => $mail->hasTo('john@example.com'));
    }
}
```

Run the tests:

```bash
php artisan test tests/Unit/Services/UserServiceTest.php
```

Expected output:

```
PASS  Tests\Unit\Services\UserServiceTest
✓ register creates user in database                            0.21s
✓ register sends welcome email                                 0.09s

Tests:    2 passed (4 assertions)
Duration: 0.32s
```

Both tests pass against the initial implementation.

### Refactoring the Service Class

The initial `register()` method mixes two distinct responsibilities: building the user record and sending the email. This is acceptable in the first pass, but as the service grows it becomes harder to test each part independently. Refactor by extracting private helper methods. At the same time, add an `update()` method to illustrate what Service Classes are designed for: grouping multiple related operations.

Here is the `register()` method before the refactor:

```php
// Before: password hashing and email sending are both inline
public function register(array $data): User
{
    $user = User::create([
        'name'     => $data['name'],
        'email'    => $data['email'],
        'password' => Hash::make($data['password']),
    ]);

    Mail::to($user->email)->send(new WelcomeMail($user));

    return $user;
}
```

And here is the refactored version of the complete service:

```php
<?php

// app/Services/UserService.php (refactored)

namespace App\Services;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class UserService
{
    public function register(array $data): User
    {
        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => $this->hashPassword($data['password']),
        ]);

        $this->sendWelcomeEmail($user);

        return $user;
    }

    // update() lives naturally in UserService because it operates on
    // the same entity. Teams can find it here without searching elsewhere.
    public function update(User $user, array $data): User
    {
        $user->update([
            'name'  => $data['name']  ?? $user->name,
            'email' => $data['email'] ?? $user->email,
        ]);

        return $user->fresh();
    }

    private function hashPassword(string $password): string
    {
        return Hash::make($password);
    }

    private function sendWelcomeEmail(User $user): void
    {
        Mail::to($user->email)->send(new WelcomeMail($user));
    }
}
```

Run the tests again to confirm the refactor did not break anything:

```bash
php artisan test tests/Unit/Services/UserServiceTest.php
```

Expected output:

```
PASS  Tests\Unit\Services\UserServiceTest
✓ register creates user in database                            0.19s
✓ register sends welcome email                                 0.08s

Tests:    2 passed (4 assertions)
Duration: 0.29s
```

Same two tests, same four assertions, still green.

### When to Use a Service Class

Use a Service Class when you have multiple operations on the same entity that will be called from different entry points. If your registration logic also needs to be called from an Artisan command to import bulk users and from a queue job triggered by an OAuth callback, `UserService::register()` can be called from all three without duplication.

It also fits teams that prefer to navigate code by entity. When a developer asks "how do we handle user updates?", pointing them to `UserService` gives them a single, coherent place to look.

### The Trade-off

Service Classes are prone to growing without a natural stopping point. A `UserService` that starts with `register()` and `update()` can accumulate `suspend()`, `reactivate()`, `changePassword()`, `verifyEmail()`, and `impersonate()` over time. At some point the class becomes a catch-all that is harder to test because each method pulls in different dependencies. This is often the signal to start considering Action classes.

## Action Class {#action-class}

The Action Class pattern flips the organizational axis. Instead of grouping by entity, you group by **operation**. One class does exactly one thing. This makes each piece of logic extremely easy to find, test, and modify in isolation. An Action Class is named as a verb-noun pair that reads like a command: `CreateUser`, `SendWelcomeEmail`, `ApproveOrder`, `ArchiveInvoice`.

Action classes became popular in the Laravel community partly because large Service classes were producing exactly the growth problem described above. Breaking them into individual operation classes imposes a natural size limit: each file stays small because it has exactly one public method.

### Characteristics of an Action Class

An Action Class is named as a command: verb plus noun. It has one public method, typically `execute()` or `handle()`. That method does not receive a `Request` object and does not return a `Response`. It can depend on other Action classes through constructor injection, which makes composition explicit and testable.

### Initial Implementation

Create a `CreateUserAction` that handles user creation directly:

```php
<?php

// app/Actions/CreateUserAction.php

namespace App\Actions;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class CreateUserAction
{
    public function execute(array $data): User
    {
        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        Mail::to($user->email)->send(new WelcomeMail($user));

        return $user;
    }
}
```

The controller calls the action:

```php
<?php

// app/Http/Controllers/UserController.php

namespace App\Http\Controllers;

use App\Actions\CreateUserAction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct(private readonly CreateUserAction $action) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $this->action->execute($validated);
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token'   => $token,
        ], 201);
    }
}
```

### Testing the Action Class

```php
<?php

// tests/Unit/Actions/CreateUserActionTest.php

namespace Tests\Unit\Actions;

use App\Actions\CreateUserAction;
use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class CreateUserActionTest extends TestCase
{
    use RefreshDatabase;

    private CreateUserAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new CreateUserAction();
    }

    public function test_execute_creates_user_in_database(): void
    {
        Mail::fake();

        $user = $this->action->execute([
            'name'     => 'Jane Doe',
            'email'    => 'jane@example.com',
            'password' => 'secret123',
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', ['email' => 'jane@example.com']);
    }

    public function test_execute_sends_welcome_email(): void
    {
        Mail::fake();

        $this->action->execute([
            'name'     => 'Jane Doe',
            'email'    => 'jane@example.com',
            'password' => 'secret123',
        ]);

        Mail::assertSent(WelcomeMail::class, fn ($mail) => $mail->hasTo('jane@example.com'));
    }
}
```

Run the tests:

```bash
php artisan test tests/Unit/Actions/CreateUserActionTest.php
```

Expected output:

```
PASS  Tests\Unit\Actions\CreateUserActionTest
✓ execute creates user in database                             0.18s
✓ execute sends welcome email                                  0.09s

Tests:    2 passed (4 assertions)
Duration: 0.28s
```

### Refactoring via Composition

The initial `CreateUserAction` has a problem: its `execute()` method does two things. It creates a user record and sends an email. The spirit of an Action class is one operation per class. An email send is its own operation, separate from database persistence.

Here is the initial `execute()` method that does both:

```php
// Before: user creation and email sending are combined in one execute()
public function execute(array $data): User
{
    $user = User::create([
        'name'     => $data['name'],
        'email'    => $data['email'],
        'password' => Hash::make($data['password']),
    ]);

    // This responsibility belongs in a separate action.
    Mail::to($user->email)->send(new WelcomeMail($user));

    return $user;
}
```

Refactor by splitting into three files. `CreateUserAction` becomes responsible only for database persistence:

```php
<?php

// app/Actions/CreateUserAction.php (refactored)

namespace App\Actions;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class CreateUserAction
{
    // This method now has exactly one job: persist a user record.
    public function execute(array $data): User
    {
        return User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
    }
}
```

`SendWelcomeEmailAction` handles the email:

```php
<?php

// app/Actions/SendWelcomeEmailAction.php

namespace App\Actions;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmailAction
{
    public function execute(User $user): void
    {
        Mail::to($user->email)->send(new WelcomeMail($user));
    }
}
```

`RegisterUserAction` composes both. This is the action the controller calls:

```php
<?php

// app/Actions/RegisterUserAction.php

namespace App\Actions;

use App\Models\User;

class RegisterUserAction
{
    // Inject the two granular actions. Laravel's container resolves them
    // automatically when RegisterUserAction is type-hinted in a controller.
    public function __construct(
        private readonly CreateUserAction        $createUser,
        private readonly SendWelcomeEmailAction  $sendWelcomeEmail,
    ) {}

    public function execute(array $data): User
    {
        $user = $this->createUser->execute($data);
        $this->sendWelcomeEmail->execute($user);

        return $user;
    }
}
```

Update the controller to use `RegisterUserAction`:

```php
<?php

// app/Http/Controllers/UserController.php (updated to use RegisterUserAction)

namespace App\Http\Controllers;

use App\Actions\RegisterUserAction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct(private readonly RegisterUserAction $action) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $this->action->execute($validated);
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token'   => $token,
        ], 201);
    }
}
```

Write a test for the composed `RegisterUserAction`:

```php
<?php

// tests/Unit/Actions/RegisterUserActionTest.php

namespace Tests\Unit\Actions;

use App\Actions\CreateUserAction;
use App\Actions\RegisterUserAction;
use App\Actions\SendWelcomeEmailAction;
use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class RegisterUserActionTest extends TestCase
{
    use RefreshDatabase;

    private RegisterUserAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        // Construct the composed action manually for full control in the test.
        $this->action = new RegisterUserAction(
            new CreateUserAction(),
            new SendWelcomeEmailAction(),
        );
    }

    public function test_execute_creates_user_in_database(): void
    {
        Mail::fake();

        $user = $this->action->execute([
            'name'     => 'Jane Doe',
            'email'    => 'jane@example.com',
            'password' => 'secret123',
        ]);

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', ['email' => 'jane@example.com']);
    }

    public function test_execute_sends_welcome_email(): void
    {
        Mail::fake();

        $this->action->execute([
            'name'     => 'Jane Doe',
            'email'    => 'jane@example.com',
            'password' => 'secret123',
        ]);

        Mail::assertSent(WelcomeMail::class, fn ($mail) => $mail->hasTo('jane@example.com'));
    }
}
```

Run the tests:

```bash
php artisan test tests/Unit/Actions/RegisterUserActionTest.php
```

Expected output:

```
PASS  Tests\Unit\Actions\RegisterUserActionTest
✓ execute creates user in database                             0.20s
✓ execute sends welcome email                                  0.08s

Tests:    2 passed (4 assertions)
Duration: 0.30s
```

The composed action passes the same two tests. Each granular action can also be tested independently, which means a failure in `SendWelcomeEmailAction` will pinpoint exactly where the problem is without needing to debug a larger class.

### When to Use an Action Class

Use an Action Class when a single operation is complex enough to deserve its own home but does not belong to a growing family of related operations. The pattern is especially well-suited for operations that are unique in their behavior, such as approving a document, archiving an order, or generating a report. These do not fit naturally inside a `DocumentService` that also handles creation and updates.

Action classes also work well when the same operation is called from multiple contexts. Because `RegisterUserAction` has no knowledge of HTTP, a queue job or an Artisan command can call `$action->execute($data)` with the same interface.

### The Trade-off

A codebase built entirely on Action classes can accumulate hundreds of files. Navigation requires consistent naming conventions and a folder structure that mirrors the domain well. The benefit of finding any single operation quickly is balanced by the cost of deciding the right name and folder for every new operation. Teams that adopt this pattern benefit from agreeing on naming rules before starting.

## Use Case Class {#use-case-class}

The Use Case Class pattern comes from Clean Architecture, the set of principles introduced by Robert C. Martin. In that model, a Use Case represents a specific business intent, expressed in terms the business would recognize rather than in terms of the framework. It is similar to an Action class in that it has one public method, but it carries an additional structural commitment: the method accepts a plain Data Transfer Object (DTO) rather than a raw array or a framework class.

That commitment enforces a boundary. Because the Use Case receives a DTO and returns a domain object, it has no reason to import `Illuminate\Http\Request`. This means the same Use Case can be called from an HTTP controller, a queue job, and an Artisan command without modification, because none of those entry points is baked into the Use Case's interface.

### Characteristics of a Use Case Class

A Use Case Class is named as a business intent: `RegisterUser`, `PlaceOrder`, `ApproveApplication`. It has one public method named `execute()`, which receives a typed DTO and returns a result. It does not import any HTTP classes from the framework. The controller is responsible for translating the `Request` into a DTO before calling the Use Case.

### Initial Implementation

Start with a basic `RegisterUserUseCase` that still uses individual string parameters. This is a common first draft before introducing a DTO:

```php
<?php

// app/UseCases/RegisterUserUseCase.php (initial, without DTO)

namespace App\UseCases;

use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class RegisterUserUseCase
{
    // Three separate string parameters work, but the signature is fragile:
    // it is easy to accidentally swap $name and $email when calling this method.
    public function execute(string $name, string $email, string $password): User
    {
        $user = User::create([
            'name'     => $name,
            'email'    => $email,
            'password' => Hash::make($password),
        ]);

        Mail::to($user->email)->send(new WelcomeMail($user));

        return $user;
    }
}
```

### Testing the Initial Use Case

```php
<?php

// tests/Unit/UseCases/RegisterUserUseCaseTest.php

namespace Tests\Unit\UseCases;

use App\Mail\WelcomeMail;
use App\Models\User;
use App\UseCases\RegisterUserUseCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class RegisterUserUseCaseTest extends TestCase
{
    use RefreshDatabase;

    private RegisterUserUseCase $useCase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->useCase = new RegisterUserUseCase();
    }

    public function test_execute_creates_user_in_database(): void
    {
        Mail::fake();

        $user = $this->useCase->execute('Alice', 'alice@example.com', 'secret123');

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', ['email' => 'alice@example.com']);
    }

    public function test_execute_sends_welcome_email(): void
    {
        Mail::fake();

        $this->useCase->execute('Alice', 'alice@example.com', 'secret123');

        Mail::assertSent(WelcomeMail::class, fn ($mail) => $mail->hasTo('alice@example.com'));
    }
}
```

Run the tests:

```bash
php artisan test tests/Unit/UseCases/RegisterUserUseCaseTest.php
```

Expected output:

```
PASS  Tests\Unit\UseCases\RegisterUserUseCaseTest
✓ execute creates user in database                             0.19s
✓ execute sends welcome email                                  0.08s

Tests:    2 passed (4 assertions)
Duration: 0.29s
```

### Refactoring to Introduce the DTO

The initial version passes tests, but it has two problems. First, the method signature has three positional string parameters. When the registration form grows to include a `phone` or `company` field, the signature grows too, and every call site must be updated. Second, and more importantly for a Use Case, positional string parameters are not a typed contract. A caller can pass the arguments in the wrong order and the error will only surface at runtime.

Here is the original `execute()` signature that grows brittle as fields are added:

```php
// Before: positional parameters are fragile and hard to extend
public function execute(string $name, string $email, string $password): User
```

Create the DTO. A `readonly` class in PHP 8.2 is the natural fit: its properties cannot be changed after construction, which makes it a reliable data container:

```php
<?php

// app/DTOs/RegisterUserDTO.php

namespace App\DTOs;

// readonly ensures no property can be accidentally mutated after the
// DTO is built from the request. The data is locked in at construction.
final readonly class RegisterUserDTO
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
    ) {}
}
```

Update the Use Case to accept the DTO:

```php
<?php

// app/UseCases/RegisterUserUseCase.php (refactored)

namespace App\UseCases;

use App\DTOs\RegisterUserDTO;
use App\Mail\WelcomeMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class RegisterUserUseCase
{
    // The DTO is the contract. Adding a new field to registration means
    // adding a property to RegisterUserDTO, not changing this signature.
    public function execute(RegisterUserDTO $dto): User
    {
        $user = User::create([
            'name'     => $dto->name,
            'email'    => $dto->email,
            'password' => Hash::make($dto->password),
        ]);

        Mail::to($user->email)->send(new WelcomeMail($user));

        return $user;
    }
}
```

The controller's job is to translate the HTTP request into the DTO. The Use Case never sees the `Request` object:

```php
<?php

// app/Http/Controllers/UserController.php

namespace App\Http\Controllers;

use App\DTOs\RegisterUserDTO;
use App\UseCases\RegisterUserUseCase;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct(private readonly RegisterUserUseCase $useCase) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // The controller handles the translation between HTTP and domain.
        // Named arguments make it impossible to accidentally swap fields.
        $dto = new RegisterUserDTO(
            name:     $validated['name'],
            email:    $validated['email'],
            password: $validated['password'],
        );

        $user = $this->useCase->execute($dto);
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'token'   => $token,
        ], 201);
    }
}
```

Update the test to use the DTO:

```php
<?php

// tests/Unit/UseCases/RegisterUserUseCaseTest.php (updated)

namespace Tests\Unit\UseCases;

use App\DTOs\RegisterUserDTO;
use App\Mail\WelcomeMail;
use App\Models\User;
use App\UseCases\RegisterUserUseCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class RegisterUserUseCaseTest extends TestCase
{
    use RefreshDatabase;

    private RegisterUserUseCase $useCase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->useCase = new RegisterUserUseCase();
    }

    public function test_execute_creates_user_in_database(): void
    {
        Mail::fake();

        $dto  = new RegisterUserDTO('Alice', 'alice@example.com', 'secret123');
        $user = $this->useCase->execute($dto);

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', ['email' => 'alice@example.com']);
    }

    public function test_execute_sends_welcome_email(): void
    {
        Mail::fake();

        $dto = new RegisterUserDTO('Alice', 'alice@example.com', 'secret123');
        $this->useCase->execute($dto);

        Mail::assertSent(WelcomeMail::class, fn ($mail) => $mail->hasTo('alice@example.com'));
    }
}
```

Run the tests:

```bash
php artisan test tests/Unit/UseCases/RegisterUserUseCaseTest.php
```

Expected output:

```
PASS  Tests\Unit\UseCases\RegisterUserUseCaseTest
✓ execute creates user in database                             0.18s
✓ execute sends welcome email                                  0.09s

Tests:    2 passed (4 assertions)
Duration: 0.27s
```

The same behavior is verified by the same number of assertions. Adding `phone` or `referral_code` to the registration form now means adding a property to `RegisterUserDTO`. The Use Case signature does not change, and neither do the call sites in other entry points (jobs, commands) that already have a DTO in hand.

### When to Use a Use Case Class

Use a Use Case Class when the same business operation must run from multiple, fundamentally different entry points: an HTTP controller, a queue job that processes a CSV import, and an Artisan command. Because the Use Case depends only on a DTO and not on the `Request` object, all three entry points can call it with the same interface.

It is also the right choice for teams that apply Clean Architecture or Domain-Driven Design, where a strict boundary between the application layer and the framework layer is an architectural requirement rather than a preference.

### The Trade-off

Use Case classes require more boilerplate than the other two patterns. Every new feature needs at minimum a DTO and a Use Case class. For simple CRUD features where the same logic will never be called from more than one entry point, this overhead is not justified. The pattern earns its cost only when the framework-agnosticism it provides is a real requirement for the feature in question.

## Side-by-Side Comparison {#comparison}

Now that all three implementations are complete, the differences are concrete rather than theoretical. The table below summarizes the key characteristics.

| Aspect | Service Class | Action Class | Use Case Class |
|---|---|---|---|
| Methods per class | Multiple | One | One |
| Organized by | Entity or domain | Single operation | Business intent |
| Naming convention | `UserService` | `CreateUser` | `RegisterUser` |
| Input | Array or primitives | Array or primitives | DTO |
| Framework dependency | Acceptable | Acceptable | Minimized by design |
| Grows naturally to | Multi-method service | Composed granular actions | DTO + typed contract |
| Best fit for | Small to medium apps, entity-centric navigation | Any app size, operation-heavy features | Medium to large apps, Clean Architecture |

### How to Decide

Three questions lead to the right choice for any given feature.

**Does this logic belong to a set of related operations on the same entity?** If you are building `register()` today but know you will also need `update()`, `suspend()`, and `changePassword()` on the same `User` model, a Service Class is the right home. The related methods grow together in one place, and the team navigates to `UserService` any time they need to touch user logic.

**Is this a single, distinct operation that might be reused or composed with others?** If the operation is self-contained and does not share context with other operations on the same entity, an Action Class keeps it focused. `ApproveApplication` does not belong in an `ApplicationService` alongside unrelated `Archive` and `Duplicate` operations. It belongs in its own class, callable from anywhere.

**Does this logic need to run identically from HTTP, queue, and CLI, or does your team apply Clean Architecture?** If you need the framework boundary enforced structurally, not just as a convention, Use Cases with DTOs provide that guarantee. The DTO ensures that no HTTP class leaks into the core logic, which means the logic can be called from any entry point without modification.

It is also worth noting that these three patterns are not mutually exclusive. A `UserService` can internally call a `SendWelcomeEmailAction`. A `RegisterUserUseCase` can delegate persistence to a repository that itself uses Eloquent. Choosing a pattern for one feature does not lock the entire codebase into that pattern forever.

## Conclusion {#conclusion}

The question "where do I put my business logic?" does not have one answer in Laravel. It has three answers with distinct trade-offs, and the right one depends on how the logic is organized and how it will be called.

- **Service Class groups by entity.** Use it when you have multiple operations on the same domain object and want a single place to find them all. It is the lowest-ceremony option and the easiest to start with on a new project.
- **Action Class groups by operation.** Use it when each operation is distinct and may be reused or composed with other operations. One class, one method, one job: the name of the class describes exactly what it does, and the file size stays naturally small.
- **Use Case Class groups by business intent with a typed input contract.** Use it when the same logic must run from HTTP, queue, and CLI without modification, or when your team enforces a hard boundary between framework code and domain logic. The DTO is the key element: it replaces raw arrays and positional parameters with a named, typed contract.
- **The choice is about navigation and coupling, not class size.** A Service with two methods is not worse than two Action classes. The decision should come from how your team wants to find code and how much isolation from the framework your project genuinely requires.
- **All three patterns can coexist in the same project.** A `UserService` for CRUD, an `ApproveOrderAction` for a complex workflow, and a `ProcessRefundUseCase` for a flow that must also run from a payment gateway webhook are all valid in the same codebase, as long as each choice is intentional.
- **`Mail::fake()` is essential in unit tests for classes that send email.** Call it before invoking any method that dispatches mail. Without it, the test will attempt a real connection and fail in most CI environments.
- **Test the extracted class directly, not the controller.** Because all three patterns move logic out of the HTTP layer, you can write focused unit tests that instantiate the Service, Action, or Use Case directly. The test suite is faster, the failure messages are more precise, and you never need to boot the router to verify that a user was saved to the database.