---
title: "Why Go Doesn't Have Try-Catch: Understanding Go Error Handling from First Principles"
slug: "why-go-doesnt-have-try-catch-understanding-go-error-handling-from-first-principles"
category: "Golang"
date: "2026-04-22"
status: "published"
---

If you recently switched to Go from Java, Python, or C#, you have probably experienced this moment: you sit down to read a file or call an HTTP endpoint, and you reach for `try-catch` out of habit. It is not there. Go does not have exceptions. Instead, every function that can fail returns an error as an ordinary second return value, and you are expected to check it with `if err != nil` on almost every line. At first glance, this looks like verbose boilerplate. A single function that opens a file, reads it, and parses its contents might have four or five of these checks in a row. Surely there is a more elegant solution?

There is not, and that is the point. Go's error handling is not a workaround for a missing language feature. It is the outcome of a deliberate philosophy: errors should be visible, local, and treated as normal outcomes rather than exceptional events. Once you understand that philosophy and the four patterns built on top of it, the verbosity starts to feel like clarity, not noise.

In this article, you will build a small CLI program called `userstore` that reads user data from a text file and looks up individual users by name. You will apply each of the four core error handling patterns to this program, one by one, watching the code become progressively more informative and robust as you go.

## Overview {#overview}

This article is structured as a progressive conceptual guide. Each section introduces a pattern by first explaining the problem it solves, then demonstrating it inside the same evolving `userstore` program. The code at the end of each section is complete and runnable, so you can verify the behavior at every stage.

### What You'll Build

- A `userstore` CLI that reads `users.txt`, validates input, and looks up a user by name.
- Four progressively richer versions of the same program, each applying a distinct error handling pattern on top of the previous one.
- A final version that combines all four patterns: basic error return, error wrapping, sentinel errors, and custom error types.

### What You'll Learn

- Why Go uses return values for errors instead of exceptions, and what the philosophical reasoning is behind that decision.
- How to use `if err != nil` correctly, and how `defer` handles resource cleanup on both success and error paths.
- How to add context to errors using `fmt.Errorf` and the `%w` wrapping verb.
- How to define sentinel errors and check for them correctly using `errors.Is`, even through multiple layers of wrapping.
- How to create custom error types that carry structured data, and how to extract them with `errors.As`.
- What the genuine trade-offs of Go's approach are, and how experienced Go developers work around the common pain points.

### What You'll Need

- Go 1.21 or later installed (available at [go.dev/dl](https://go.dev/dl))
- A terminal and any text editor
- Basic familiarity with Go syntax: variables, functions, and structs

## In Go, Errors Are Just Values {#errors-are-values}

To understand Go's approach, it helps to start with what an error actually is at the language level. In most object-oriented languages, an exception is a special runtime object that gets "thrown," causing the call stack to unwind until some `catch` block intercepts it. The control flow is implicit. You can have a hundred lines of code inside a single `try` block, and when an exception arrives, you cannot tell which of those lines threw it without inspecting the exception object or adding logging.

Go takes a fundamentally different approach. The `error` type is a built-in interface with exactly one method:

```go
// The built-in error interface.
// Any type that implements Error() string satisfies it.
// There is nothing special or magical about it.
type error interface {
    Error() string
}
```

That means an error is just a value, like a string or an integer. A function signals failure by returning this value as part of its return signature. The Go convention is to return the error as the last value:

```go
// This function returns two things: the normal result (a string),
// and an error explaining what went wrong. If nothing went wrong, error is nil.
func doSomething() (string, error) { ... }
```

Compare reading a file in Java versus Go. In Java, the exception can bubble up from anywhere inside the `try` block:

```java
// Java: the exception can come from deep inside the try block.
// You cannot tell from reading this code which line caused it.
try {
    File file = new File("users.txt");
    Scanner scanner = new Scanner(file);
    // ...more lines that could also throw
} catch (FileNotFoundException e) {
    System.err.println("file not found: " + e.getMessage());
}
```

In Go, every potentially-failing call has its own check, right below it:

```go
// Go: control flow is always top-to-bottom. There are no jumps.
file, err := os.Open("users.txt")
if err != nil {
    fmt.Fprintf(os.Stderr, "error: %v\n", err)
    return
}
defer file.Close() // schedules cleanup to run when this function returns
// continue with file...
```

The Go version is more verbose, but every line that can fail is immediately followed by a decision about what to do with that failure. What you read is exactly what runs.

To see this in practice, start by creating a new directory for the project and initializing a Go module inside it. The `mkdir` command creates the directory, `cd` moves into it, and `go mod init` sets up the module with the name `userstore`. This name is used as the import path for internal packages.

```
mkdir userstore
cd userstore
go mod init userstore
```

Next, create `users.txt` in the same directory with a few entries. Each line follows the format `name,email` — a username and an email address separated by a comma. This is the data file your CLI will read.

```
alice,alice@example.com
bob,bob@example.com
charlie,charlie@example.com
```

Now create `main.go` with the first version of the program. This version defines a `readUserFile` function that opens the file at a given path, reads every line, splits each line on the first comma to extract the username and email, and stores the result in a map. The `main` function calls `readUserFile`, checks for errors, and prints the loaded users. Each step that can fail is followed immediately by an `if err != nil` check:

```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// readUserFile opens the file at path and returns a map of username to email.
// If anything goes wrong, it returns nil and an error describing what failed.
// The caller is responsible for deciding what to do with that error.
func readUserFile(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		// Return nil for the map (no usable data) and the raw error.
		return nil, err
	}
	// defer schedules file.Close() to run when readUserFile returns,
	// whether that return is normal or due to an error further below.
	// This guarantees we never leak the file descriptor.
	defer file.Close()

	users := make(map[string]string)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		// SplitN with n=2 splits only on the first comma,
		// so the email address is always captured whole.
		parts := strings.SplitN(line, ",", 2)
		if len(parts) == 2 {
			users[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
	}

	// bufio.Scanner does not return errors from Scan() directly.
	// We must check scanner.Err() after the loop finishes.
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return users, nil
}

func main() {
	users, err := readUserFile("users.txt")
	if err != nil {
		// fmt.Fprintf to os.Stderr is the idiomatic way to print errors in CLIs.
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Users loaded:")
	for name, email := range users {
		fmt.Printf("  %s -> %s\n", name, email)
	}
}
```

Use `go run` to compile and execute `main.go` in a single step without producing a binary on disk. This is the fastest way to run a Go program during development:

```
go run main.go
```

Expected output:

```
Users loaded:
  alice -> alice@example.com
  bob -> bob@example.com
  charlie -> charlie@example.com
```

Now simulate a missing file to see the error path in action. The `mv` command renames `users.txt` to `users.txt.bak`, temporarily hiding it from the program:

```
mv users.txt users.txt.bak
go run main.go
```

```
error: open users.txt: no such file or directory
```

Restore the file with another `mv` before continuing to the next section:

```
mv users.txt.bak users.txt
```

This is already useful, but the error message has a problem that becomes obvious in larger programs. The message `open users.txt: no such file or directory` comes from the operating system. It tells you what OS-level thing went wrong, but says nothing about which part of your application triggered it, or why that file was being opened. That is the problem the next pattern solves.

## Go's Philosophy: Explicit is Better {#go-philosophy}

Before diving into the more advanced patterns, it is worth spending a moment on the philosophy behind the design, because it shapes every decision you will make when writing Go error handling.

The Go team documented this thinking explicitly: errors are normal outcomes of operations, not exceptional events. A file that does not exist is not an unexpected disaster; it is a predictable condition that your program should know how to handle. Try-catch encourages treating errors as edge cases that get bundled into a catch block somewhere far from where the problem occurred. Go pushes back against this by requiring you to handle the error at the exact place where it happens, in the same function where the failing call was made.

This design also has a practical consequence that matters for code review and maintainability. In Go, every function that returns an error forces the caller to make a visible decision: handle it, return it, or explicitly ignore it by assigning it to `_`. There is no way to accidentally propagate an error upward through three layers of function calls without every intermediate function showing evidence of it. In each function in the chain, the presence of `error` in the return signature is itself a signal: this function knows something below it can fail.

The phrase the Go team uses is "explicit is better than implicit." It is the same reasoning behind Go's decision to have no operator overloading, no implicit type conversions, and no hidden control flow. The code you read is the code that runs.

## Adding Context with Error Wrapping {#pattern-wrapping}

The basic `return nil, err` pattern works for small programs, but it produces error messages that lose context as they travel up the call stack. If `readUserFile` is three levels deep in your application and it returns a raw error from `os.Open`, the caller at the top sees only `open users.txt: no such file or directory`. That tells you what went wrong at the OS level, but nothing about which of your functions triggered it.

Go 1.13 introduced error wrapping to solve this. The idea is simple: instead of returning the original error directly, you wrap it inside a new error that adds a context message. You do this using `fmt.Errorf` with the `%w` verb:

```go
// %w wraps the original error inside a new one.
// The message adds your context; the original error is preserved inside.
return nil, fmt.Errorf("readUserFile: could not open %q: %w", path, err)
```

The resulting error message is now: `readUserFile: could not open "users.txt": open users.txt: no such file or directory`. More importantly, the original error is not discarded; it is preserved inside the wrapper. This allows callers to inspect the underlying error programmatically, which is exactly what the next two patterns depend on.

Update `main.go` with the following changes. `readUserFile` now wraps every error it encounters with a context prefix that includes the function name and the file path being processed. A new `findUser` function is also added, which looks up a name in the loaded map and returns a plain formatted error when the name is not found. The `main` function is updated to call `findUser` for two names: one that exists and one that does not:

```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// readUserFile now wraps every error with context, so the caller sees
// which function failed and which file it was working with.
func readUserFile(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		// fmt.Errorf with %w creates a new error that wraps the original.
		// The caller can still access the original err through the chain.
		return nil, fmt.Errorf("readUserFile: opening %q: %w", path, err)
	}
	defer file.Close()

	users := make(map[string]string)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, ",", 2)
		if len(parts) == 2 {
			users[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("readUserFile: scanning %q: %w", path, err)
	}

	return users, nil
}

// findUser looks up a user by name in the users map.
// For now, it returns a simple formatted error when the user is not found.
func findUser(users map[string]string, name string) (string, error) {
	email, ok := users[name]
	if !ok {
		// A plain fmt.Errorf without %w creates an error with no wrapped value.
		// We will improve this in the next section using a sentinel error.
		return "", fmt.Errorf("findUser: no user named %q", name)
	}
	return email, nil
}

func main() {
	users, err := readUserFile("users.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	// Look up "alice" (exists) and "zara" (does not exist).
	for _, name := range []string{"alice", "zara"} {
		email, err := findUser(users, name)
		if err != nil {
			fmt.Fprintf(os.Stderr, "lookup failed: %v\n", err)
			continue
		}
		fmt.Printf("Found: %s -> %s\n", name, email)
	}
}
```

Run the updated program to confirm the new error messages appear correctly:

```
go run main.go
```

Expected output:

```
Found: alice -> alice@example.com
lookup failed: findUser: no user named "zara"
```

The error message is now much more informative. When something fails, you can immediately see which function was involved and what data it was working with. This becomes invaluable when debugging production issues.

There is still a limitation in `findUser`, though. The error it returns for a missing user is just a formatted string. If the caller wants to take a different action specifically when a user is not found (versus, say, a file permission error), it has no reliable way to distinguish between the two. Comparing error message strings is fragile: a typo in the message breaks the comparison silently. The correct solution is a sentinel error.

## Sentinel Errors and errors.Is {#pattern-sentinel}

A sentinel error is a predefined, package-level error value that represents a specific condition. The name "sentinel" comes from the idea of a named guard: it is a single, fixed value that code can check against to recognize a particular failure.

You have likely already used sentinel errors without realizing it. `io.EOF` is a sentinel error returned when a reader reaches the end of its input. `sql.ErrNoRows` is a sentinel that the `database/sql` package returns when a query returns no results. These are not dynamically created messages; they are stable, named values that callers can depend on across versions.

Defining your own sentinel is straightforward. By convention, sentinel error variables start with `Err` and live at the package level:

```go
// ErrUserNotFound is the sentinel for "this user does not exist in the store."
var ErrUserNotFound = errors.New("user not found")
```

Once this sentinel exists, `findUser` can return it (wrapped with context using `%w`), and any caller at any depth in the call stack can recognize the condition using `errors.Is`.

Why `errors.Is` instead of direct `==` comparison? Because once an error is wrapped with `fmt.Errorf` and `%w`, it is no longer the same object as the original sentinel. The wrapped error contains the sentinel inside it, but direct equality fails. `errors.Is` traverses the entire chain of wrapped errors, unwrapping layer by layer, until it finds a match or runs out of layers:

```go
// Direct equality fails for wrapped errors:
err == ErrUserNotFound   // false: err is a wrapper, not the sentinel itself

// errors.Is searches the chain and finds the sentinel inside the wrapper:
errors.Is(err, ErrUserNotFound)   // true
```

This is why you should always use `errors.Is` rather than `==` when checking for a specific error. It is correct for both wrapped and unwrapped errors.

Update `main.go` with the following changes. A package-level `ErrUserNotFound` sentinel is declared using `errors.New`. The `findUser` function is updated to return this sentinel (wrapped with `%w` to preserve context). The `main` function is updated to use `errors.Is` to distinguish a "not found" failure from any other kind of error:

```go
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"
)

// ErrUserNotFound is returned by findUser when the requested name
// does not exist in the user store.
var ErrUserNotFound = errors.New("user not found")

func readUserFile(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("readUserFile: opening %q: %w", path, err)
	}
	defer file.Close()

	users := make(map[string]string)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, ",", 2)
		if len(parts) == 2 {
			users[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("readUserFile: scanning %q: %w", path, err)
	}

	return users, nil
}

// findUser now returns ErrUserNotFound wrapped with %w for missing users.
// This lets callers use errors.Is to detect the specific condition,
// while still getting the context (the name that was looked up) in the message.
func findUser(users map[string]string, name string) (string, error) {
	email, ok := users[name]
	if !ok {
		return "", fmt.Errorf("findUser %q: %w", name, ErrUserNotFound)
	}
	return email, nil
}

func main() {
	users, err := readUserFile("users.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	for _, name := range []string{"alice", "zara"} {
		email, err := findUser(users, name)
		if err != nil {
			// errors.Is correctly identifies ErrUserNotFound even though
			// findUser wrapped it inside another error with fmt.Errorf %w.
			if errors.Is(err, ErrUserNotFound) {
				fmt.Fprintf(os.Stderr, "no such user: %q\n", name)
			} else {
				fmt.Fprintf(os.Stderr, "unexpected error: %v\n", err)
			}
			continue
		}
		fmt.Printf("Found: %s -> %s\n", name, email)
	}
}
```

Run the program again to confirm that the caller now handles a missing user differently from a generic error:

```
go run main.go
```

Expected output:

```
Found: alice -> alice@example.com
no such user: "zara"
```

The caller can now distinguish a "user not found" condition from any other error, without comparing strings. The sentinel travels through the error chain intact, and `errors.Is` surfaces it reliably regardless of how many wrapping layers exist between the sentinel and the final check.

Sentinel errors work well when the caller only needs to know which specific error occurred. But sometimes the caller needs more than just recognition; it needs to read structured data from the error itself. That requires a custom error type.

## Custom Error Types and errors.As {#pattern-custom-types}

A sentinel error is just a fixed string with a name. If the caller needs to read fields from the error (for example, which form field failed validation, or what value was rejected), a sentinel cannot help. You need a custom error type: a struct that implements the `error` interface and carries whatever structured data is useful.

Any struct that has an `Error() string` method satisfies the `error` interface. Beyond that method, you can add whatever fields make sense:

```go
// ValidationError carries structured information about a validation failure.
// Unlike a sentinel, it can tell the caller exactly which field was invalid
// and why, as typed fields rather than a formatted string.
type ValidationError struct {
	Field   string // the name of the input field that failed
	Message string // a human-readable reason
}

// Error implements the error interface.
func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation failed for %q: %s", e.Field, e.Message)
}
```

To extract a custom error type from an error chain (which may have multiple wrapping layers), you use `errors.As`. While `errors.Is` checks for a specific error value by identity, `errors.As` checks for a specific error type and, if found, assigns it to a variable so you can access its fields directly:

```go
var valErr *ValidationError
if errors.As(err, &valErr) {
	// valErr is now the concrete *ValidationError from inside the chain.
	// You can read valErr.Field and valErr.Message as structured data.
	fmt.Printf("field %q is invalid: %s\n", valErr.Field, valErr.Message)
}
```

The `&valErr` syntax (a pointer to a pointer) is the correct signature for `errors.As`. The function needs a pointer to the target type variable so it can assign the found value to it.

Now update `main.go` with the final version of `userstore`. This version adds a `ValidationError` struct and a `validateUsername` function that checks whether the provided username is non-empty after trimming whitespace. The program now reads the username from a command-line argument (via `os.Args`) instead of hardcoding it, so all four error paths can be exercised by passing different values at runtime. All four patterns from the previous sections are present in this final version:

```go
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"
)

// --- Error definitions ---

// ErrUserNotFound signals that a username does not exist in the user store.
var ErrUserNotFound = errors.New("user not found")

// ValidationError carries structured data about a failed input validation.
// Use this when the caller needs to know not just that validation failed,
// but which field failed and why, as typed data.
type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation failed for %q: %s", e.Field, e.Message)
}

// --- Business logic ---

// validateUsername checks that name is non-empty after trimming whitespace.
// It returns a *ValidationError if the check fails, nil otherwise.
func validateUsername(name string) error {
	if strings.TrimSpace(name) == "" {
		return &ValidationError{
			Field:   "username",
			Message: "cannot be empty or whitespace-only",
		}
	}
	return nil
}

// readUserFile opens the file at path and returns a map of username to email.
// All errors are wrapped with context about the function and the file path.
func readUserFile(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("readUserFile: opening %q: %w", path, err)
	}
	defer file.Close()

	users := make(map[string]string)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, ",", 2)
		if len(parts) == 2 {
			users[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("readUserFile: scanning %q: %w", path, err)
	}

	return users, nil
}

// findUser looks up name in the users map.
// It returns ErrUserNotFound (wrapped with context) when name does not exist.
func findUser(users map[string]string, name string) (string, error) {
	email, ok := users[name]
	if !ok {
		return "", fmt.Errorf("findUser %q: %w", name, ErrUserNotFound)
	}
	return email, nil
}

// --- Entry point ---

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: userstore <username>")
		os.Exit(1)
	}

	username := os.Args[1]

	// Pattern 4 (custom error type): validate the input before doing any I/O.
	// This keeps validation errors separate from runtime errors.
	if err := validateUsername(username); err != nil {
		var valErr *ValidationError
		// errors.As searches the error chain for a *ValidationError.
		// If found, it assigns the value to valErr so we can read its fields.
		if errors.As(err, &valErr) {
			fmt.Fprintf(os.Stderr, "invalid input -- field: %s, reason: %s\n",
				valErr.Field, valErr.Message)
		} else {
			fmt.Fprintf(os.Stderr, "validation error: %v\n", err)
		}
		os.Exit(1)
	}

	// Pattern 1 + 2 (basic return + wrapping): load the file with contextual errors.
	users, err := readUserFile("users.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "error loading user store: %v\n", err)
		os.Exit(1)
	}

	// Pattern 3 (sentinel + errors.Is): distinguish "not found" from other failures.
	email, err := findUser(users, username)
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			fmt.Fprintf(os.Stderr, "no user named %q found in the store\n", username)
		} else {
			fmt.Fprintf(os.Stderr, "unexpected lookup error: %v\n", err)
		}
		os.Exit(1)
	}

	fmt.Printf("Found: %s -> %s\n", username, email)
}
```

Run the program with different inputs to exercise all four error paths. First, look up a user that exists:

```
go run main.go alice
```
Output:
```
Found: alice -> alice@example.com
```

Next, look up a user that does not exist. This triggers the sentinel error path via `errors.Is`:

```
go run main.go zara
```
Output:
```
no user named "zara" found in the store
```

Next, pass a blank string surrounded by quotes. The shell passes it as a single argument consisting only of whitespace, which fails the validation check and triggers the `ValidationError` path via `errors.As`:

```
go run main.go "   "
```
Output:
```
invalid input -- field: username, reason: cannot be empty or whitespace-only
```

Finally, simulate a missing data file by renaming `users.txt` before running the program, then restore it afterward:

```
mv users.txt users.txt.bak && go run main.go alice
```
Output:
```
error loading user store: readUserFile: opening "users.txt": open users.txt: no such file or directory
```

Now let’s restore the file again.
```
mv users.txt.bak users.txt
```

All four patterns are now working together in a single coherent program. Each error condition produces a distinct, informative message, and each one is handled differently based on its type or identity rather than string comparison.

## Understanding the Error Chain {#error-chain}

It is worth pausing to visualize what `fmt.Errorf` with `%w` actually produces under the hood, because this explains why `errors.Is` and `errors.As` work the way they do.

When `findUser` returns `fmt.Errorf("findUser %q: %w", name, ErrUserNotFound)`, the result is a layered structure. The outer error holds the formatted message and a reference to the inner error:

```
outer: "findUser \"zara\": user not found"
    wraps: ErrUserNotFound  ("user not found")
```

When you call `errors.Is(err, ErrUserNotFound)`, Go does not compare just the top-level error. It calls `Unwrap()` on the outer error to retrieve the inner one, and checks if that matches. If there were more layers of wrapping, it would keep unwrapping until it either finds a match or reaches `nil`.

`errors.As` works identically, but checks type rather than value. It walks the chain looking for an error whose concrete type matches the target type. This means a `*ValidationError` will be found even if it was wrapped by an intermediate function that added more context using `%w`.

This chain behavior is why the consistent use of `%w` throughout your codebase matters. If you wrap an error with `fmt.Errorf("something: %v", err)` instead of `%w`, the original error is not preserved inside the new one. The string contains the original message, but the chain is broken. `errors.Is` and `errors.As` will not be able to find anything inside it.

A useful mental rule is this: use `%w` when you want callers to be able to inspect the inner error programmatically. Use `%v` only when you are converting an error into a log message or a final output string, where inspection is no longer needed.

## The Real Trade-offs {#trade-offs}

Any honest treatment of Go error handling has to acknowledge that the approach has real downsides alongside its advantages. The carousel that inspired this article said it well: you either love it or hate it, and both reactions are understandable.

On the positive side, every error is visible at the call site. Code review is more effective because error handling is never hidden in distant catch blocks. The control flow is always linear and top-to-bottom, which means there are no surprise jumps. Debugging a failure is often as simple as reading the error message top to bottom, because the chain of wrapped messages forms a readable breadcrumb trail through the call stack.

On the negative side, the `if err != nil` repetition is real and cannot be wished away. A function that calls five things that can fail will have five of these checks, and they can dominate the visual weight of the function body. This is the most common complaint from Go newcomers, and it is legitimate. The language has no shorthand for it.

There is also the problem of missing stack traces. In Java, every exception automatically carries a complete stack trace. In Go, if you return a bare `err` without wrapping it, the error arrives at the top with no record of the path it traveled:

```go
// Problematic: err arrives at the caller with no context about the path it took.
return nil, err

// Better: always add at least the function name when propagating errors upward.
return nil, fmt.Errorf("myFunction: %w", err)
```

If you consistently wrap errors as they bubble up, each layer adding its function name, the final error message at the top effectively becomes a readable call trace: `main: readUserFile: opening "users.txt": open users.txt: no such file or directory`. This is not automatic like Java's stack trace, but it is predictable and human-readable.

Finally, errors can still be silently ignored in Go, just explicitly. Assigning the error to `_` makes the intent visible, but it is still possible to write code that intentionally discards errors in ways that cause bugs. Linters like `staticcheck` and `errcheck` exist specifically to catch unchecked error returns in CI pipelines, and enabling them is considered a standard practice in production Go projects.

## Conclusion {#conclusion}

Go's decision to use return values for errors rather than exceptions is not a limitation you have to work around. It is a design philosophy that prioritizes explicitness, local reasoning, and predictable control flow. Once you understand the four core patterns, you have the tools to handle any error situation cleanly and idiomatically.

- **Errors are values, not events.** The `error` interface is just a type with one method. Every function that can fail returns an error as its last value, and the caller decides what to do with it immediately at the call site, not somewhere else in a catch block.
- **`defer` is your cleanup mechanism.** Place `defer resource.Close()` immediately after a successful resource acquisition. This guarantees the cleanup runs when the function returns, whether that return is normal or the result of an error path.
- **Wrap errors with `fmt.Errorf` and `%w` to add context.** Always add your function name and relevant data when propagating an error upward. Each layer of wrapping becomes a step in a human-readable breadcrumb trail through your codebase.
- **Use sentinel errors for specific, recognizable conditions.** Define `var ErrSomething = errors.New(...)` at the package level when callers need to handle a particular failure distinctly. Always check sentinels with `errors.Is`, not `==`, so that wrapping does not break the comparison.
- **Use custom error types when the caller needs structured data.** If the caller needs to read typed fields from the error (not just recognize it), define a struct implementing `error` and use `errors.As` to extract it from the chain.
- **The boilerplate is the design.** The verbosity of `if err != nil` is intentional. It keeps error handling visible, local, and impossible to accidentally skip. Accept it, wrap consistently, and let linters enforce that no error goes unchecked.