<!-- Ebook addendum for Chapter 10. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- **Authentication** is verifying identity: registration, login, and logout. A dedicated `AuthController` keeps it separate from entry logic.
- `unique:users,email` blocks duplicate accounts; `confirmed` requires a matching `password_confirmation` field; `min:8` enforces a minimum length.
- `Hash::make()` turns a password into an irreversible hash. **Never store plain-text passwords.** Password fields must never use `old()`.
- `Auth::login($user)` logs the new user in immediately by creating a session.
- `middleware('guest')` restricts pages to non-authenticated visitors, the counterpart to `middleware('auth')`. With registration working, the temporary `/dev-login` route is removed.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `AuthController` has `showRegister()` and `register()`, and registration routes sit inside the `guest` group.
- `/dev-login` has been deleted.
- Registering with valid data creates a user, logs them in, and lands on `/entries`; duplicate emails, short passwords, and mismatched confirmations each show the right error.

## Exercises {#exercises}

1. Add a `min:2` rule to the `name` field and confirm a single-character name is rejected.
2. Add helper text under the password field describing the minimum length requirement to the user.
3. Change the post-registration redirect so a brand new user lands on `/entries/create` (ready to write their first entry) instead of the listing.

Solutions are in the **Exercise Solutions** section at the back.
