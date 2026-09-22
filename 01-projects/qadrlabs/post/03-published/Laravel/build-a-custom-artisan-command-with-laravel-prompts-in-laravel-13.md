---
title: "Build a Custom Artisan Command with Laravel Prompts in Laravel 13"
slug: "build-a-custom-artisan-command-with-laravel-prompts-in-laravel-13"
category: "Laravel"
date: "2023-08-15"
status: "draft"
id_version: "membuat-custom-laravel-artisan-command-menggunakan-laravel-prompt"
---

# Build a Custom Artisan Command with Laravel Prompts in Laravel 13

Creating user accounts with manual queries feels convenient until you forget to hash a password or enter an email that already exists. Repeating this work without validation makes mistakes easy to miss. With a custom Artisan command and Laravel Prompts, you can guide an operator through entering valid data directly in the terminal.

This tutorial updates the Laravel 10 example to a new Laravel 13 project using the Laravel Installer. We still build the `make:user` command, but all input is now interactive and the password is not displayed as plain text. This is a new-project tutorial, not an upgrade procedure for an existing application.

## Overview {#overview}

We will use the default users table and SQLite so we can focus on the command. The example was tested with PHP 8.5.9, Laravel Installer 5.32.0, Laravel Framework 13.32.0, and Laravel Prompts 0.3.24.

### What You'll Build

- A `make:user` command that asks for a name, email, and password.
- Input validation before the user is saved to the database.
- Eight Pest cases for user creation, hashing, and invalid-input rejection.

### What You'll Learn

- Create a project with the Laravel Installer.
- Build a custom Artisan command with Laravel Prompts.
- Hide password input and store a hash.
- Test an interactive command and its database results.

### What You'll Need

- PHP 8.3 or later is required by Laravel 13. To follow the setup tested here, use PHP 8.4 or later with the SQLite extension enabled, because Pest 5.2.1 installed by the installer requires PHP 8.4+.
- Composer and the Laravel Installer available in your terminal.
- A macOS, Linux, or Windows with WSL terminal for the interactive Laravel Prompts interface.
- Basic familiarity with PHP, Eloquent, migrations, and the terminal.

## Step 1: Create a Laravel 13 Project {#step-1-create-project}

Open a terminal in your working directory. If the Laravel Installer is not available yet, install it with the following command.

```bash
composer global require laravel/installer
```

This command installs the installer globally. Make sure the global Composer binary directory is on your terminal PATH. If the installer is already installed, you can update it with the following command.

```bash
composer global update laravel/installer
```

Next, create a new project with SQLite and Pest.

```bash
laravel new custom-command-laravel --no-interaction --database=sqlite --pest --no-boost
cd custom-command-laravel
php artisan --version
```

The installer uses SQLite, installs Pest, and skips the Boost installation. The `--no-interaction` option makes setup run without interactive answers. This command follows the Laravel version selected by the installer, so confirm that the version check shows 13.x. The version output from testing this tutorial was:

```text
Laravel Framework 13.32.0
```

Laravel Prompts is already included in Laravel 13, so it does not need a separate package installation step. See the [Laravel installation documentation](https://laravel.com/docs/13.x/installation) and [Laravel Prompts installation](https://laravel.com/docs/13.x/prompts#installation) for details.

## Step 2: Check the Database and User Model {#step-2-prepare-database}

The installer prepares a local SQLite database. Run the migrations to make sure the required tables exist.

```bash
php artisan migrate
```

In the test project, the installer had already run the migrations, so the result was:

```text

   INFO  Nothing to migrate.  

```

If any migrations are still pending, Laravel will run them first. You do not need to create a MySQL database or add database credentials for this example.

Open `app/Models/User.php`. The default model in the tested project already has the following attributes. Check that its contents match, then save the file if you make any adjustments.

```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
```

The `#[Fillable]` attribute allows the name, email, and password to be populated through mass assignment. The `#[Hidden]` attribute hides the password and remember token when the model is serialized. The `hashed` cast preserves the model’s default hashing behavior. Check its syntax:

```bash
php -l app/Models/User.php
```

```text
No syntax errors detected in app/Models/User.php
```

## Step 3: Create the Interactive Command {#step-3-create-command}

Create the command class using the Artisan generator.

```bash
php artisan make:command MakeUser
```

This command creates `app/Console/Commands/MakeUser.php`. Open that file, replace its contents with the following complete code, and save it.

```php
<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

use function Laravel\Prompts\password;
use function Laravel\Prompts\text;

class MakeUser extends Command
{
    protected $signature = 'make:user';

    protected $description = 'Create a user through interactive prompts';

    public function handle(): int
    {
        // Validate each answer before moving to the next prompt.
        $name = text(
            label: 'What is your name?',
            required: 'The name field is required.',
            validate: ['name' => 'required|string|max:255'],
            transform: fn (string $value) => trim($value),
        );

        $email = text(
            label: 'What is your email?',
            required: 'The email field is required.',
            validate: ['email' => 'required|email|max:255|unique:users,email'],
            transform: fn (string $value) => trim($value),
        );

        // Hide the password while it is typed; do not accept it as an argument.
        $password = password(
            label: 'What is your password?',
            required: 'The password field is required.',
            validate: ['password' => 'required|string|min:8'],
        );

        $user = User::create([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password),
        ]);

        $this->info("User {$user->name} created successfully.");

        return self::SUCCESS;
    }
}
```

The `make:user` signature no longer accepts optional arguments. The `text()` function asks for the name and email, trims leading and trailing whitespace, and validates each value before continuing. The name is required and must not exceed 255 characters. The email must have a valid format, must not exceed 255 characters, and must not already exist in the users table.

The `password()` function hides the characters being typed and requires at least eight characters. `Hash::make()` produces a hash before the data is saved with `User::create()`. Hashing is not reversible encryption for recovering the original password. The command then displays the user’s name and returns `self::SUCCESS`.

Check that Laravel recognizes the new command.

```bash
php artisan help make:user
```

```text
Description:
  Create a user through interactive prompts

Usage:
  make:user

Options:
  -h, --help            Display help for the given command. When no command is given display help for the list command
      --silent          Do not output any message
  -q, --quiet           Only errors are displayed. All other output is suppressed
  -V, --version         Display this application version
      --ansi|--no-ansi  Force (or disable --no-ansi) ANSI output
  -n, --no-interaction  Do not ask any interactive question
      --env[=ENV]       The environment the command should run under
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug
```

Classes in the default command directory are discovered automatically. The output above shows a signature without user-data arguments. Run the command interactively, without an option that disables interaction.

## Step 4: Try It Out {#step-4-try-it-out}

Now we will check the terminal flow, the stored data, and the automated tests. Use the following local example data to make the results easy to compare.

### Create a User from the Terminal

```bash
php artisan make:user
```

Enter `Admin` as the name, `admin@example.com` as the email, and `demo-password-123` as the example password. Press Enter after each answer. The password is displayed as masking characters, not its original text. The final line on success is:

```text
User Admin created successfully.
```

That example name does not grant administrator permissions. The command creates a regular user using the default model.

Check the record through Tinker, displaying only the name and email.

```bash
php artisan tinker --execute="dump(App\Models\User::where('email', 'admin@example.com')->first(['name', 'email'])->toArray());"
```

```text
array:2 [
  "name" => "Admin"
  "email" => "admin@example.com"
] // vendor/psy/psysh/src/ExecutionClosure.php(41) : eval()'d code:1
```

This result shows data from the local SQLite database. The password is deliberately excluded from the inspection query.

### Try Invalid Input

Run the command again. Try an empty name, a malformed email, an email that already exists, or a password shorter than eight characters. The prompt displays an error and keeps waiting for a valid answer. Delete the incorrect answer before typing its replacement. For a duplicate email, use a new address to continue.

No new user is saved until all input passes validation. You can cancel before saving with Ctrl+C.

### Add Eight Pest Cases

Create `tests/Feature/MakeUserTest.php`, add the following code, and save it. Pest was installed by the installer, so it does not need to be installed again.

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

it('creates a user from interactive input', function () {
    $this->artisan('make:user')
        ->expectsQuestion('What is your name?', 'Admin')
        ->expectsQuestion('What is your email?', 'admin@example.com')
        ->expectsQuestion('What is your password?', 'demo-password-123')
        ->expectsOutput('User Admin created successfully.')
        ->assertExitCode(0);

    $this->assertDatabaseHas('users', [
        'name' => 'Admin',
        'email' => 'admin@example.com',
    ]);
    $this->assertDatabaseCount('users', 1);
});

it('stores a password hash', function () {
    $this->artisan('make:user')
        ->expectsQuestion('What is your name?', 'Admin')
        ->expectsQuestion('What is your email?', 'admin@example.com')
        ->expectsQuestion('What is your password?', 'demo-password-123')
        ->assertExitCode(0);

    $user = User::where('email', 'admin@example.com')->firstOrFail();

    expect($user->password)->not->toBe('demo-password-123');
    expect(Hash::check('demo-password-123', $user->password))->toBeTrue();
});

it('rejects invalid input', function (string $field, string $invalid, string $error) {
    if ($invalid === 'taken@example.com') {
        User::factory()->create(['email' => $invalid]);
    }

    $command = $this->artisan('make:user');

    // Stop at the invalid field; Laravel ends invalid prompts during tests.
    foreach ([
        'name' => ['What is your name?', 'Admin'],
        'email' => ['What is your email?', 'admin@example.com'],
        'password' => ['What is your password?', 'demo-password-123'],
    ] as $key => [$question, $answer]) {
        if ($key === $field) {
            $command->expectsQuestion($question, $invalid)
                ->expectsOutputToContain($error);
            break;
        }

        $command->expectsQuestion($question, $answer);
    }

    $command->assertExitCode(1)->run();

    $this->assertDatabaseMissing('users', ['email' => 'admin@example.com']);
    $this->assertDatabaseCount('users', $invalid === 'taken@example.com' ? 1 : 0);
})->with([
    'empty name' => ['name', '', 'The name field is required.'],
    'long name' => ['name', str_repeat('a', 256), 'The name field must not be greater than 255 characters.'],
    'empty email' => ['email', '', 'The email field is required.'],
    'invalid email' => ['email', 'not-an-email', 'The email field must be a valid email address.'],
    'duplicate email' => ['email', 'taken@example.com', 'The email has already been taken.'],
    'short password' => ['password', 'short', 'The password field must be at least 8 characters.'],
]);
```

The first two tests check user creation and password hashing. The third test runs for six datasets, giving eight cases in total. Each rejected input must produce a validation message and must not add a record. In the duplicate-email case, the one pre-existing record must remain the only record.

Laravel uses prompt fallbacks when running tests. Invalid input ends the command with exit code 1 in test mode, so the test does not send a corrected answer. In an interactive terminal, the prompt keeps asking for a valid answer. This difference explains why the test assertions do not reproduce the entire input-correction interaction.

The `RefreshDatabase` trait isolates each test’s data. The default `phpunit.xml` configuration uses in-memory SQLite, so the tests do not delete the user you created manually. Run the command-specific tests:

```bash
php artisan test --colors=never --filter=MakeUserTest
```

```text

   PASS  Tests\Feature\MakeUserTest
  ✓ it creates a user from interactive input                             0.15s  
  ✓ it stores a password hash                                            0.01s  
  ✓ it rejects invalid input with dataset "empty name"                   0.01s  
  ✓ it rejects invalid input with dataset "long name"                    0.01s  
  ✓ it rejects invalid input with dataset "empty email"                  0.01s  
  ✓ it rejects invalid input with dataset "invalid email"                0.01s  
  ✓ it rejects invalid input with dataset "duplicate email"              0.02s  
  ✓ it rejects invalid input with dataset "short password"               0.01s  

  Tests:    8 passed (48 assertions)
  Duration: 0.28s

```

Finally, run all project tests to make sure the default tests still pass.

```bash
php artisan test --colors=never
```

```text

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

   PASS  Tests\Feature\MakeUserTest
  ✓ it creates a user from interactive input                             0.08s  
  ✓ it stores a password hash                                            0.01s  
  ✓ it rejects invalid input with dataset "empty name"                   0.01s  
  ✓ it rejects invalid input with dataset "long name"                    0.01s  
  ✓ it rejects invalid input with dataset "empty email"                  0.01s  
  ✓ it rejects invalid input with dataset "invalid email"                0.01s  
  ✓ it rejects invalid input with dataset "duplicate email"              0.01s  
  ✓ it rejects invalid input with dataset "short password"               0.01s  

  Tests:    10 passed (50 assertions)
  Duration: 0.31s

```

Test durations may differ on your machine. The output above was copied from testing the tutorial; all eight command cases and both default tests passed.

## Understanding Laravel Prompts {#understanding-laravel-prompts}

Laravel Prompts provides terminal input with validation and an interactive interface. In this example, Artisan runs the command, Prompts collects answers, and Eloquent saves the user after the answers are valid. This separation keeps the flow easy to follow without adding a controller or route.

### Hidden Passwords and Hashing

Hiding input protects the terminal display, while hashing protects the stored representation of the password. They serve different purposes. The default `hashed` cast recognizes an existing hash, so the value from `Hash::make()` is not hashed twice. The test with `Hash::check()` confirms that the example password still matches the stored hash.

### Validation and Terminal Support

Unique-email validation provides feedback before saving. The default database unique index remains the final safeguard if two processes try to create the same email at the same time. This example does not add special handling for concurrent write conflicts.

Laravel Prompts supports macOS, Linux, and Windows through WSL. Environments that do not support that interface can use fallbacks, so prompt appearance may differ. Automated tests verify command behavior; the terminal check confirms that hidden input works visually.

For more detail, read [Laravel Prompts](https://laravel.com/docs/13.x/prompts), [Artisan Console](https://laravel.com/docs/13.x/artisan), [Console Tests](https://laravel.com/docs/13.x/console-tests), and [Eloquent Attribute Casting](https://laravel.com/docs/13.x/eloquent-mutators#attribute-casting).

## Conclusion {#conclusion}

You now have an interactive command for creating users in Laravel 13, with validation and repeatable tests.

- **Laravel Installer.** SQLite and Pest provide the tutorial foundation without configuring a separate database server.
- **Laravel Prompts.** Name, email, and password input is guided directly from the terminal.
- **Validation and hashing.** Data is checked before saving, the password is hidden while typing, and only a hash is stored.
- **Pest.** Eight cases test user creation, hashing, and invalid-input rejection.

