<!-- Ebook addendum for Chapter 11. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- `Auth::attempt($credentials)` looks up the user and verifies the password in one call, returning `true` or `false`.
- `session()->regenerate()` after login prevents **session fixation**. Login errors are deliberately **vague** to avoid leaking which emails exist.
- `back()->withErrors([...])->onlyInput('email')` returns to the form with errors and keeps only the email. The **three-step logout** is `Auth::logout()`, `session()->invalidate()`, `session()->regenerateToken()`, and logout must be a **POST** route.
- `->name('login')` is required so the `auth` middleware can redirect guests. `/entries` now lives inside `middleware('auth')`, making it fully private.
- The `index()` query becomes `auth()->user()->entries()->latest()->get()`, scoping results to the current user automatically.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- Login and logout work; the login route is named `login`; logout uses POST with `@csrf`.
- `/entries` is inside the `auth` group, and `index()` uses `auth()->user()->entries()`.
- All six test scenarios from the chapter pass, including multi-user privacy: one account never sees another's entries.

## Exercises {#exercises}

1. Add a "Remember me" checkbox to the login form and pass its value as the second argument to `Auth::attempt($credentials, $remember)`.
2. Add a flash success message ("You have been logged out.") that appears on the login page after logging out.
3. In the navigation bar, show the logged-in user's total entry count next to their name.

Solutions are in the **Exercise Solutions** section at the back.
