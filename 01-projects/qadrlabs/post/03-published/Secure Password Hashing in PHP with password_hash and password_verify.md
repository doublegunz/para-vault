---
title: "Secure Password Hashing in PHP with password_hash() and password_verify()"
slug: "secure-password-hashing-in-php-with-password-hash-and-password-verify"
category: "php"
date: "2026-06-17"
status: "draft"
---

# Secure Password Hashing in PHP with password_hash() and password_verify()

You are building a login system, and you reach the part where you have to store the user's password. A quick search turns up `md5()` or `sha1()`, they are one line each, and they seem to do the job. So the password goes into the database as a neat little hash and you move on.

Months later, the database leaks. Because `md5()` and `sha1()` are fast and unsalted, an attacker can run billions of guesses per second on a single GPU and match them against precomputed rainbow tables. Most of your users reuse passwords, so a leak of your site quietly becomes a leak of their email, their banking, and everything else. The hashing you added did almost nothing to slow that down.

The good news is that PHP solved this problem for you a long time ago. The built-in functions `password_hash()` and `password_verify()` generate a unique salt for every password, run a deliberately slow algorithm that punishes brute force, and compare hashes in constant time so timing attacks do not leak information. In this guide you will build a small, reusable `PasswordManager` and a working register and login flow on top of these functions, using nothing but pure PHP.

## Overview {#overview}

Before writing any code, here is a clear picture of what you will end up with and the ideas you will pick up along the way.

### What You'll Build

A reusable `PasswordManager` class plus a small register and login script that hashes new passwords, verifies them on login, and transparently upgrades old hashes to stronger parameters when a user signs in.

### What You'll Learn

- Why `md5()` and `sha1()` are unsafe for passwords
- How to hash a password with `password_hash()` and read the resulting hash string
- How to check a password with `password_verify()` without ever comparing hashes yourself
- How to upgrade outdated hashes on login with `password_needs_rehash()`
- When to choose bcrypt and when to choose Argon2id
- The common pitfalls that quietly weaken password storage

### What You'll Need

- PHP 8.3 or higher installed on your machine. Examples in this article were run on PHP 8.5, where the default bcrypt cost is 12. On PHP 8.4 and later the default cost is also 12; on PHP 8.3 and earlier it is 10.
- A terminal or command prompt
- Any text editor or IDE (VS Code, PhpStorm, etc.)

## Why MD5 and SHA-1 Are Not Safe for Passwords {#why-not-md5-sha1}

Before reaching for the right tool, it helps to understand exactly why the old one fails. The problem with `md5()` and `sha1()` for passwords is not that they are broken in some exotic mathematical sense. The problem is that they were designed to be fast, and for passwords fast is precisely the wrong property.

Create a file called `why-md5-fails.php` and add the following:

```php
<?php
// md5 produces the same digest every time for the same input,
// and it runs instantly. That is exactly what an attacker wants.
echo md5("password123") . "\n";
echo md5("password123") . "\n";
echo sha1("password123") . "\n";
```

Run it from your terminal:

```
php why-md5-fails.php
```

You will get output like this:

```
482c811da5d5b4bc6d497ffa98491e38
482c811da5d5b4bc6d497ffa98491e38
cbfdac6008f9cab4083784cbd1874f76618d2a97
```

Notice that hashing `"password123"` twice produces the exact same digest. That is a deal breaker for passwords. Because there is no salt, identical passwords always map to identical hashes, which means an attacker can precompute a giant lookup table once (a rainbow table) and then reverse millions of leaked hashes instantly. Two users with the same password are also immediately visible as having the same hash.

The second problem is speed. A modern GPU can compute billions of `md5()` or `sha1()` hashes per second. That speed is wonderful for checksums and useless for passwords, because it means an attacker can simply try every common password and every dictionary word in a matter of minutes. A secure password hash has to be slow on purpose and salted by default, which is exactly what PHP's password API gives you.

## Step 1: Hash a Password with password_hash() {#step-1-hash-a-password}

The recommended way to hash a password in modern PHP is `password_hash()`. It picks a strong algorithm, generates a cryptographically secure random salt for you, and applies a configurable work factor so the hash is slow to compute.

Create a file called `password-hash.php`:

```php
<?php
// password_hash() returns a self-describing hash string.
// Run it twice with the same password and you get two different hashes,
// because a unique random salt is generated each time.
echo password_hash("mypassword123", PASSWORD_DEFAULT) . "\n";
echo password_hash("mypassword123", PASSWORD_DEFAULT) . "\n";
```

Run it:

```
php password-hash.php
```

The output looks like this (your values will differ, and that is the point):

```
$2y$12$3nLtvugrOEqWJWwl7beYJOXFq5wNU2Eud99UTPXQSywEG69QhVjs6
$2y$12$i3XIosUJ8ohzwt2XPCyvD.DHOsWBotlOIAfcPIDO5mrqc32VPXhca
```

The same password produced two completely different hashes. This is not a bug; it is the salt at work. Each call generates a new random salt, so even identical passwords end up with different stored hashes, which defeats rainbow tables entirely.

The hash string is also self-describing. Reading `$2y$12$3nLtvugrOEqWJWwl7beYJOXFq5wNU2Eud99UTPXQSywEG69QhVjs6` from left to right:

- `$2y$` is the algorithm identifier for bcrypt.
- `12` is the cost factor. Each increase of one roughly doubles the time it takes to compute the hash. PHP 8.4 raised the default from 10 to 12 to keep pace with faster hardware.
- The remaining 53 characters encode the 22-character salt followed by the actual hash of the password.

Because the algorithm, the cost, and the salt are all baked into this single string, you only need one column in your database to store it. There is no separate salt column to manage, and `PASSWORD_DEFAULT` will keep tracking PHP's recommended algorithm over time.

## Step 2: Verify a Password with password_verify() {#step-2-verify-a-password}

Storing a hash is only half the job. When a user logs in, they send you a plain-text password and you need to check it against the stored hash. You never decrypt the hash, because hashing is one way. Instead you let `password_verify()` re-hash the input with the same salt and compare the results.

Create a file called `password-verify.php`. Paste in one of the hashes you generated in Step 1 as the stored value:

```php
<?php
// A hash that was stored earlier (the result of password_hash()).
$storedHash = '$2y$12$3nLtvugrOEqWJWwl7beYJOXFq5wNU2Eud99UTPXQSywEG69QhVjs6';

// password_verify() re-hashes the input using the salt and cost
// embedded in $storedHash, then compares in constant time.
if (password_verify('mypassword123', $storedHash)) {
    echo "Password is valid\n";
} else {
    echo "Password is invalid\n";
}

if (password_verify('wrongpassword', $storedHash)) {
    echo "Password is valid\n";
} else {
    echo "Password is invalid\n";
}
```

Run it:

```
php password-verify.php
```

The output is:

```
Password is valid
Password is invalid
```

There are two important things happening here. First, `password_verify()` reads the salt and cost straight out of the stored hash string, so you do not have to store or pass them separately. Second, it compares the two hashes in constant time, meaning it always takes the same amount of time whether the first character matches or the last one does. That property closes off timing attacks, where an attacker measures tiny response-time differences to guess a hash byte by byte.

This is also why you must never compare hashes yourself with `==` or `===`. A naive string comparison can short-circuit on the first mismatching byte and leak timing information. Always let `password_verify()` do the comparison.

## Step 3: Build a Reusable PasswordManager Class {#step-3-build-passwordmanager}

Calling `password_hash()` and `password_verify()` directly works, but in a real application you want a single place that owns your password policy. Wrapping the two functions in a small class makes the rest of your code read clearly and gives you one spot to change settings later.

Create a file called `password-manager.php`:

```php
<?php

class PasswordManager
{
    // Hash a plain-text password. Passing null as the options array
    // lets PHP pick the current default cost (12 on PHP 8.4+).
    public function hash(string $password): string
    {
        return password_hash($password, PASSWORD_DEFAULT);
    }

    // Verify a plain-text password against a stored hash.
    public function verify(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }
}

$pm = new PasswordManager();

// Registration: hash the password once and store the result.
$hash = $pm->hash("mypassword123");
echo "Stored hash: {$hash}\n";

// Login: verify the typed password against the stored hash.
echo $pm->verify("mypassword123", $hash) ? "Login success\n" : "Login failed\n";
echo $pm->verify("wrongpassword", $hash) ? "Login success\n" : "Login failed\n";
```

Run it:

```
php password-manager.php
```

You will see output similar to this:

```
Stored hash: $2y$12$.5glnoLI7pFv4X58sJo1autvEs7YnPdl.9nteCna4bbEoCtrME7u2
Login success
Login failed
```

The class itself is intentionally thin. `hash()` takes a plain-text password and returns the hash you would store in your database, while `verify()` takes the typed password plus the stored hash and returns a simple boolean. Your controllers and services now talk to `PasswordManager` instead of sprinkling `password_hash()` calls everywhere, so the day you decide to change algorithms you only edit one file.

## Step 4: Add Automatic Rehashing with password_needs_rehash() {#step-4-automatic-rehashing}

Security parameters do not stay current forever. The default cost was 10 for years, and PHP 8.4 bumped it to 12. If you hashed passwords on an older version, those hashes are now weaker than the ones you create today. You cannot re-hash them in bulk, because you do not store the plain-text passwords. What you can do is upgrade each hash the next time its owner logs in, while you still have the plain-text password in memory.

`password_needs_rehash()` tells you whether a stored hash was made with parameters that differ from your current defaults. Extend the class in a file called `rehash.php`:

```php
<?php

class PasswordManager
{
    public function hash(string $password): string
    {
        return password_hash($password, PASSWORD_DEFAULT);
    }

    public function verify(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }

    // Returns true when the stored hash uses outdated parameters
    // compared to the current default (for example an old cost of 10).
    public function needsRehash(string $hash): bool
    {
        return password_needs_rehash($hash, PASSWORD_DEFAULT);
    }
}

$pm = new PasswordManager();

// Simulate a hash created years ago with the old default cost of 10.
$oldHash = password_hash("mypassword123", PASSWORD_BCRYPT, ['cost' => 10]);
echo "Old hash: {$oldHash}\n";
echo "Needs rehash? " . ($pm->needsRehash($oldHash) ? "yes" : "no") . "\n";

// During a successful login we upgrade the stored hash transparently.
if ($pm->verify("mypassword123", $oldHash) && $pm->needsRehash($oldHash)) {
    $newHash = $pm->hash("mypassword123");
    echo "New hash: {$newHash}\n";
    echo "Needs rehash? " . ($pm->needsRehash($newHash) ? "yes" : "no") . "\n";
}
```

Run it:

```
php rehash.php
```

The output shows the upgrade in action:

```
Old hash: $2y$10$OtEdeAt4Q249llcZV1Qyhuif.ahI5FB9jkf3pRjzUwjFHtExuzB6K
Needs rehash? yes
New hash: $2y$12$EwNtzUJdnAqbMAD1DQjIuuu3xfP7iaEB2/u4e7OORi7NwEa7qMyAu
Needs rehash? no
```

The old hash carries `$2y$10$`, so `needsRehash()` returns `yes`. After a successful `verify()`, the code generates a fresh hash with the current default cost of 12 and, in a real application, would save that new hash back to the database. The next time `needsRehash()` looks at it, the answer is `no`. The order matters: only rehash after the password has been verified, because that is the only moment you legitimately hold the plain-text password.

## Step 5: Try It Out {#step-5-try-it-out}

Now let us put everything together into a flow that resembles a real register and login cycle, including the hash-upgrade path. Create a file called `try-it-out.php`:

```php
<?php

class PasswordManager
{
    public function hash(string $password): string
    {
        return password_hash($password, PASSWORD_DEFAULT);
    }

    public function verify(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }

    public function needsRehash(string $hash): bool
    {
        return password_needs_rehash($hash, PASSWORD_DEFAULT);
    }
}

$pm = new PasswordManager();

// Pretend this array is our "users" database table.
$users = [];

// Scenario 1: a user registers.
$users['alice'] = $pm->hash("correct horse battery staple");
echo "Registered alice\n";

// Scenario 2: alice logs in with the correct password.
$input = "correct horse battery staple";
if ($pm->verify($input, $users['alice'])) {
    echo "Login 1: success\n";
} else {
    echo "Login 1: failed\n";
}

// Scenario 3: alice mistypes her password.
$input = "correct horse battery staplr";
if ($pm->verify($input, $users['alice'])) {
    echo "Login 2: success\n";
} else {
    echo "Login 2: failed\n";
}

// Scenario 4: bob has an old hash (cost 10) that gets upgraded on login.
$users['bob'] = password_hash("hunter2", PASSWORD_BCRYPT, ['cost' => 10]);
echo "Bob stored hash cost: " . substr($users['bob'], 0, 7) . "\n";

$input = "hunter2";
if ($pm->verify($input, $users['bob'])) {
    if ($pm->needsRehash($users['bob'])) {
        $users['bob'] = $pm->hash($input);
        echo "Login 3: success, hash upgraded to cost " . substr($users['bob'], 0, 7) . "\n";
    } else {
        echo "Login 3: success\n";
    }
}
```

Run it:

```
php try-it-out.php
```

The output walks through every scenario:

```
Registered alice
Login 1: success
Login 2: failed
Bob stored hash cost: $2y$10$
Login 3: success, hash upgraded to cost $2y$12$
```

This is the whole lifecycle in miniature. Alice registers and her password is stored as a cost-12 hash. Her correct login succeeds, her mistyped login fails, and neither attempt ever touches the plain-text password again after hashing. Bob arrives with a legacy cost-10 hash, logs in successfully, and his hash is silently upgraded to cost 12 on the way through. Your users never notice any of this, which is exactly how good password handling should feel.

## Choosing Between Bcrypt and Argon2id {#bcrypt-vs-argon2id}

So far every hash has started with `$2y$`, which is bcrypt. That is because `PASSWORD_DEFAULT` still maps to bcrypt in current PHP versions. It is a sensible, battle-tested default, but it is not the only option, and for new projects it is worth knowing the alternative.

PHP also ships `PASSWORD_ARGON2ID`, which selects Argon2id, the algorithm that the OWASP Password Storage Cheat Sheet now recommends as the first choice. Unlike bcrypt, Argon2id is memory-hard, meaning it deliberately consumes a configurable amount of RAM. That makes it far more expensive to attack with GPUs and custom hardware, which are cheap on raw computing power but constrained on memory.

Create a file called `argon2id.php`:

```php
<?php

// Argon2id is only available when PHP was compiled with libsodium
// or, on PHP 8.4+, when the OpenSSL-backed implementation is present.
if (!defined('PASSWORD_ARGON2ID')) {
    echo "Argon2id is not available in this PHP build\n";
    exit;
}

// OWASP suggests at least 19 MiB of memory, 2 iterations, and 1 thread.
$hash = password_hash("mypassword123", PASSWORD_ARGON2ID, [
    'memory_cost' => 19456, // 19 MiB, expressed in KiB
    'time_cost'   => 2,     // number of iterations
    'threads'     => 1,     // degree of parallelism
]);

echo $hash . "\n";
echo (password_verify("mypassword123", $hash) ? "valid" : "invalid") . "\n";
```

Run it:

```
php argon2id.php
```

If your PHP build supports Argon2id, you will see a hash with a different shape:

```
$argon2id$v=19$m=19456,t=2,p=1$OHd5Y1lLOURvN0lzQUxMbA$4r2CZOJ7OID0DdSdnS4dQJfPVBmD5Ov2gGXNumxWeCQ
valid
```

The Argon2id hash openly lists its parameters: `m=19456` is the memory in KiB, `t=2` is the number of iterations, and `p=1` is the degree of parallelism. The same `password_verify()` you have used all along works here too, because it reads those parameters from the hash string just like it does with bcrypt.

So which should you use? If you are starting fresh and your hosting supports Argon2id, prefer it with parameters at or above the OWASP baseline of 19 MiB of memory, 2 iterations, and 1 thread. If you are on shared hosting where Argon2id is unavailable, or you want maximum compatibility, stick with bcrypt and a cost of 12 or higher. Whatever you pick, route it through `password_needs_rehash()` so you can migrate later without disrupting your users. One practical note: do not mix algorithms by hardcoding `PASSWORD_ARGON2ID` in `password_hash()` but `PASSWORD_DEFAULT` in `password_needs_rehash()`, or every hash will look like it needs rehashing forever. Keep both calls referring to the same algorithm.

## Common Password Hashing Pitfalls {#common-pitfalls}

The password API is hard to misuse, but there are a few sharp edges and old habits that still trip developers up. Most of them come from treating passwords like ordinary strings instead of secrets.

The first surprise is that bcrypt only reads the first 72 bytes of a password. Anything beyond that is silently ignored. Create a file called `bcrypt-72-bytes.php` to see it:

```php
<?php

// bcrypt only looks at the first 72 bytes of the password.
// These two different passwords share the same first 72 characters,
// so bcrypt treats them as identical.
$a = str_repeat("a", 72) . "FIRST";
$b = str_repeat("a", 72) . "SECOND";

$hash = password_hash($a, PASSWORD_BCRYPT);

echo "Verify password B against hash of A: ";
echo password_verify($b, $hash) ? "valid (truncated!)\n" : "invalid\n";
```

Run it:

```
php bcrypt-72-bytes.php
```

The result proves the truncation:

```
Verify password B against hash of A: valid (truncated!)
```

Two different passwords verified against each other because their first 72 bytes were identical. For ordinary human passwords this is rarely an issue, but if you support very long passphrases, be aware of the limit, or use Argon2id, which does not have it. Whatever you do, never try to work around the limit by pre-hashing the password with `md5()` or `sha1()` first. That reintroduces null-byte truncation problems and shrinks the input entropy, which makes the result weaker, not stronger.

A few more rules are worth committing to memory:

- **Never store plain-text passwords.** Not in the database, not in logs, not in a "temporary" debug dump. The whole point of hashing is that even you cannot read them.
- **Never generate your own salt.** Older guides showed a `salt` option, but it is deprecated and dangerous. `password_hash()` generates a secure salt for you, and there is no scenario where your handmade salt is better.
- **Always transmit passwords over HTTPS.** A perfect hash protects the database, but a plain-text login form over HTTP hands the password to anyone on the network.
- **Add rate limiting on login.** Slow hashing raises the cost of offline attacks, but you still want to throttle online guessing so an attacker cannot hammer your login endpoint.
- **Size the database column generously.** A bcrypt hash is 60 characters today, but algorithms and parameters change. A `VARCHAR(255)` column gives you room to grow without a migration later.

## Conclusion {#conclusion}

Password storage is one of those areas where the right approach is genuinely easy, as long as you stop reaching for the tools that were never meant for the job. PHP's password API gives you salting, an adjustable work factor, timing-safe comparison, and a clean upgrade path, all behind two functions you can learn in an afternoon. You built a small `PasswordManager` that registers users, verifies logins, and quietly modernizes old hashes, which is everything a real authentication system needs at this layer.

Here are the key takeaways to carry into your next project:

- **Abandon md5() and sha1() for passwords.** They are fast and unsalted, which makes leaked hashes trivial to reverse with rainbow tables and GPUs.
- **Use password_hash() to store passwords.** It generates a unique salt, embeds the algorithm and cost in the hash string, and needs only one database column.
- **Use password_verify() to check passwords.** It reads the salt and cost from the stored hash and compares in constant time, so never roll your own comparison with `==` or `===`.
- **Upgrade hashes with password_needs_rehash().** Re-hash a verified password whenever its parameters fall behind your current default, so security improves over time without bulk migrations.
- **Prefer Argon2id when available, bcrypt with cost 12 otherwise.** Argon2id is memory-hard and OWASP's first recommendation, while bcrypt remains a solid, compatible default.
- **Respect the edges.** Mind bcrypt's 72-byte limit, never pre-hash or store plain text, serve logins over HTTPS, rate-limit attempts, and give the hash column room to grow.
