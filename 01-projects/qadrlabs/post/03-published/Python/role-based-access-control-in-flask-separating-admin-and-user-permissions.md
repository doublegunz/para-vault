---
title: "Role-Based Access Control in Flask: Separating Admin and User Permissions"
slug: "role-based-access-control-in-flask-separating-admin-and-user-permissions"
category: "Python"
date: "2026-04-27"
status: "published"
---

In [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) of this series, you built a CRUD REST API for managing books. In [Part 2](https://qadrlabs.com/post/adding-jwt-authentication-to-your-flask-rest-api), you added JWT authentication so that only logged-in users could create, update, or delete books. But there is still a gap: every registered user has exactly the same level of access. A freshly registered account can delete every book in the database just as easily as the person who set the server up. In most real-world applications, that is not acceptable.

This tutorial closes that gap by introducing Role-Based Access Control, commonly called RBAC. The idea is simple: instead of asking "is this user logged in?", your API will ask "is this user logged in and does their role permit this action?". Write operations will be restricted to users with the `admin` role, while users with the default `user` role can only read. You will accomplish all of this without adding any new dependencies; the tools already in your project are enough.

## Overview {#overview}

This is Part 3 of the Flask Books API series. The code builds directly on the project from Parts 1 and 2. If you have not completed those tutorials, start with [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) and [Part 2](https://qadrlabs.com/post/adding-jwt-authentication-to-your-flask-rest-api) before continuing here.

### What You'll Build

- A two-role permission system where `admin` users can create, update, and delete books, and `user` accounts are limited to reading
- A reusable `role_required` decorator that enforces role checks on any route in a single line
- A Flask CLI command, `flask set-admin`, for promoting any existing user to the admin role
- An updated Pytest suite that tests each role's access, including the 403 Forbidden case

### What You'll Learn

- How to add a `role` column to the `users` table with a safe default value
- How to embed a custom claim into a JWT at login time using `additional_claims`
- How to read that claim back inside a request using `get_jwt()`
- How to write a decorator factory with `functools.wraps` that wraps Flask-JWT-Extended's own token verification
- Why role data belongs in the JWT payload for this use case, and what the trade-offs of that decision are

### What You'll Need

- The completed project from [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) and [Part 2](https://qadrlabs.com/post/adding-jwt-authentication-to-your-flask-rest-api)
- No new packages; this tutorial adds zero new dependencies
- Familiarity with Python decorators and how `functools.wraps` preserves function metadata

## Step 1: Add the Role Column to the Users Table {#step-1-add-role-column}

Every user needs a role, so the first change is to the database schema. Open `schema.sql` and update the `users` table definition:

```sql
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL,
    role          TEXT    NOT NULL DEFAULT 'user'  -- [NEW]
);

CREATE TABLE books (
    id     INTEGER PRIMARY KEY AUTOINCREMENT,
    title  TEXT    NOT NULL,
    author TEXT    NOT NULL,
    year   INTEGER NOT NULL
);
```

The `DEFAULT 'user'` clause is a deliberate security decision rooted in the principle of least privilege. It means that every new account, regardless of how it is created, starts with the most restricted access level. There is no way for a bug in the registration endpoint or an accidental API call to accidentally produce an admin account. Admin status can only be granted through an explicit, deliberate act, which you will build as a CLI command in Step 5.

Since the schema has changed, reinitialize the database:

```bash
flask --app app init-db
```

Expected output:

```
Database initialized successfully.
```

## Step 2: Embed the Role in the JWT at Login {#step-2-embed-role-in-token}

With the `role` column in place, the next step is to make that role visible to the parts of the application that need to enforce access control. The cleanest place to do this is at login time: when a user authenticates and a token is created, the token should carry the user's role as a claim so that subsequent requests can be authorized without any additional database queries.

Open `app.py` and update the `login()` function. The only line that changes is the `create_access_token()` call:

```python
    @app.route("/auth/login", methods=["POST"])
    def login():
        from werkzeug.security import check_password_hash

        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        username = data.get("username", "").strip()
        password = data.get("password", "").strip()

        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400

        db = get_db()
        user = db.execute(
            "SELECT * FROM users WHERE username = ?", (username,)
        ).fetchone()

        if user is None or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid username or password"}), 401

        access_token = create_access_token(
            identity=str(user["id"]),
            # [NEW] additional_claims adds any dictionary of values into the
            # JWT payload alongside the standard claims like 'sub' and 'exp'.
            # The 'role' key will be readable in any protected route via get_jwt().
            # We read the role from the database here at login time, which means
            # the token always reflects the role the user had when they logged in.
            additional_claims={"role": user["role"]},
        )
        return jsonify({"access_token": access_token}), 200
```

Reading the role from the database at login and embedding it in the token is a deliberate performance trade-off. It means every subsequent request can check the user's role by reading the token alone, with no database query. The cost of this approach is that if you change a user's role in the database, their existing token will still carry the old role until it expires. For most applications, this is an acceptable delay given a short token lifetime. You will read more about this trade-off in the conceptual section after the testing step.

## Step 3: Build the role_required Decorator {#step-3-build-role-required-decorator}

Now that the role lives in the token, you need a way to enforce it at the route level. You could check `get_jwt()["role"]` at the top of every protected function, but that approach duplicates the same logic in every route, creates inconsistency, and makes future changes to your authorization logic much harder to manage.

A decorator is the right solution. Create a new file called `decorators.py` in the project root:

```python
from functools import wraps
from flask import jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt


def role_required(*roles):
    """
    A decorator factory that restricts a route to users whose JWT 'role'
    claim matches one of the provided roles.

    Being a factory (a function that returns a decorator) rather than a
    plain decorator means you can call it with arguments:

        @role_required('admin')
        def admin_only(): ...

        @role_required('admin', 'editor')
        def admin_or_editor(): ...

    The *roles syntax collects all arguments into a tuple, so the same
    factory works for any number of allowed roles without any changes.
    """
    def decorator(fn):
        # @wraps(fn) copies the wrapped function's __name__, __doc__, and
        # other metadata onto the wrapper. Without this, Flask's routing
        # system would see multiple routes all named 'wrapper', which causes
        # an "AssertionError: View function mapping is overwriting an existing
        # endpoint function" error when you apply the decorator to more than
        # one route in the same app.
        @wraps(fn)
        def wrapper(*args, **kwargs):
            # verify_jwt_in_request() does everything @jwt_required() does:
            # it looks for the Authorization header, decodes and verifies the
            # token's signature, and checks the expiry time. If any of those
            # checks fail, it raises an exception that our registered error
            # handlers in app.py convert into a 401 JSON response. This means
            # role_required behaves like @jwt_required() for unauthenticated
            # requests and like a role gate for authenticated ones.
            verify_jwt_in_request()

            claims = get_jwt()
            user_role = claims.get("role")

            if user_role not in roles:
                # 403 Forbidden is the correct status code here. The user is
                # authenticated (their token is valid) but not authorized to
                # perform this action. Using 401 would be misleading because
                # it implies the user is not logged in.
                return jsonify({
                    "error": "Access denied",
                    "required_roles": list(roles),
                    "your_role": user_role,
                }), 403

            return fn(*args, **kwargs)
        return wrapper
    return decorator
```

Your project now has a separate `decorators.py` file, which is a cleaner structure than keeping authorization logic inside `app.py`. As the application grows, this file becomes the single place where all custom access control decorators live.

## Step 4: Protect the Book Endpoints by Role {#step-4-protect-endpoints-by-role}

With the decorator ready, protecting the write endpoints is a matter of replacing `@jwt_required()` with `@role_required('admin')` on the three relevant routes. Open `app.py`, add the import for your new decorator, and update the routes.

Below is the complete `app.py` after all changes across Steps 2, 3, and 4. The `# [NEW]` and `# [CHANGED]` markers show exactly what was added or modified compared to Part 2:

```python
import os
import click
from dotenv import load_dotenv
from flask import Flask, jsonify, request, abort
from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    get_jwt_identity,
    # [CHANGED] jwt_required is no longer imported here. The role_required
    # decorator in decorators.py calls verify_jwt_in_request() internally,
    # which provides the same token verification behavior.
)
from database import get_db, close_db, init_db
from decorators import role_required                # [NEW]

load_dotenv()


def create_app(test_config=None):
    app = Flask(__name__)

    app.config.from_mapping(
        DATABASE=os.path.join(app.instance_path, "books.db"),
        JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "dev-only-secret"),
    )

    if test_config is not None:
        app.config.from_mapping(test_config)

    os.makedirs(app.instance_path, exist_ok=True)
    app.teardown_appcontext(close_db)

    jwt = JWTManager(app)

    # ------------------------------------------------------------------
    # JWT Error Handlers (unchanged from Part 2)
    # ------------------------------------------------------------------

    @jwt.unauthorized_loader
    def missing_token_callback(reason):
        return jsonify({"error": "Authorization token is missing", "reason": reason}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(reason):
        return jsonify({"error": "Authorization token is invalid", "reason": reason}), 422

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({"error": "Authorization token has expired"}), 401

    # ------------------------------------------------------------------
    # Auth Routes
    # ------------------------------------------------------------------

    @app.route("/auth/register", methods=["POST"])
    def register():
        """
        Registers a new user with the default 'user' role.

        The role column in the database has DEFAULT 'user', so this endpoint
        does not need to specify a role at all. Every new account starts with
        the least privileged access level.
        """
        from werkzeug.security import generate_password_hash

        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        username = data.get("username", "").strip()
        password = data.get("password", "").strip()

        errors = {}
        if not username:
            errors["username"] = "Username is required"
        if not password:
            errors["password"] = "Password is required"
        elif len(password) < 8:
            errors["password"] = "Password must be at least 8 characters"
        if errors:
            return jsonify({"errors": errors}), 422

        db = get_db()
        existing = db.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone()
        if existing:
            return jsonify({"error": "Username is already taken"}), 409

        password_hash = generate_password_hash(password)
        cursor = db.execute(
            "INSERT INTO users (username, password_hash) VALUES (?, ?)",
            (username, password_hash),
        )
        db.commit()

        return jsonify({"id": cursor.lastrowid, "username": username}), 201

    @app.route("/auth/login", methods=["POST"])
    def login():
        """
        Authenticates a user and returns a JWT with the user's role embedded.
        """
        from werkzeug.security import check_password_hash

        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        username = data.get("username", "").strip()
        password = data.get("password", "").strip()

        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400

        db = get_db()
        user = db.execute(
            "SELECT * FROM users WHERE username = ?", (username,)
        ).fetchone()

        if user is None or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid username or password"}), 401

        access_token = create_access_token(
            identity=str(user["id"]),
            additional_claims={"role": user["role"]},  # [NEW]
        )
        return jsonify({"access_token": access_token}), 200

    # ------------------------------------------------------------------
    # Book Routes
    # ------------------------------------------------------------------

    @app.route("/books", methods=["GET"])
    def get_books():
        """Returns a JSON array of all books. Public, no token required."""
        db = get_db()
        books = db.execute("SELECT * FROM books ORDER BY id").fetchall()
        return jsonify([dict(book) for book in books])

    @app.route("/books/<int:book_id>", methods=["GET"])
    def get_book(book_id):
        """Returns a single book. Public, no token required."""
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        return jsonify(dict(book))

    @app.route("/books", methods=["POST"])
    @role_required("admin")                         # [CHANGED] was @jwt_required()
    def create_book():
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400
        title = data.get("title", "").strip()
        author = data.get("author", "").strip()
        year = data.get("year")
        errors = {}
        if not title:
            errors["title"] = "Title is required"
        if not author:
            errors["author"] = "Author is required"
        if year is None:
            errors["year"] = "Year is required"
        elif not isinstance(year, int):
            errors["year"] = "Year must be an integer"
        if errors:
            return jsonify({"errors": errors}), 422
        db = get_db()
        cursor = db.execute(
            "INSERT INTO books (title, author, year) VALUES (?, ?, ?)",
            (title, author, year),
        )
        db.commit()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (cursor.lastrowid,)
        ).fetchone()
        return jsonify(dict(book)), 201

    @app.route("/books/<int:book_id>", methods=["PUT"])
    @role_required("admin")                         # [CHANGED] was @jwt_required()
    def update_book(book_id):
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400
        title = data.get("title", book["title"])
        author = data.get("author", book["author"])
        year = data.get("year", book["year"])
        db.execute(
            "UPDATE books SET title = ?, author = ?, year = ? WHERE id = ?",
            (title, author, year, book_id),
        )
        db.commit()
        updated = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        return jsonify(dict(updated))

    @app.route("/books/<int:book_id>", methods=["DELETE"])
    @role_required("admin")                         # [CHANGED] was @jwt_required()
    def delete_book(book_id):
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        db.execute("DELETE FROM books WHERE id = ?", (book_id,))
        db.commit()
        return jsonify({"message": f"Book {book_id} deleted successfully"})

    # ------------------------------------------------------------------
    # Error Handlers (unchanged from Part 2)
    # ------------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"error": "Method not allowed"}), 405

    # ------------------------------------------------------------------
    # CLI Commands
    # ------------------------------------------------------------------

    @app.cli.command("init-db")
    def init_db_command():
        """Initializes the database by running schema.sql."""
        init_db()
        click.echo("Database initialized successfully.")

    @app.cli.command("set-admin")                   # [NEW]
    @click.argument("username")
    def set_admin_command(username):
        """Promotes an existing user to the admin role."""
        db = get_db()
        user = db.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone()
        if user is None:
            # click.echo with err=True sends the message to stderr,
            # which is the correct stream for error output in CLI tools.
            click.echo(f"Error: user '{username}' not found.", err=True)
            return
        db.execute(
            "UPDATE users SET role = 'admin' WHERE username = ?", (username,)
        )
        db.commit()
        click.echo(f"Success: '{username}' has been promoted to admin.")

    return app


app = create_app()
```

Your project structure now has one new file compared to Part 2:

```
flask-books-api/
├── .env
├── .env.example
├── .gitignore
├── app.py
├── database.py
├── decorators.py      ← new in this tutorial
├── schema.sql
├── requirements.txt
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── test_books.py
```

## Step 5: Add a CLI Command to Promote a User to Admin {#step-5-cli-promote-admin}

The `set-admin` CLI command was already registered in the `app.py` you wrote in Step 4. This step explains the reasoning behind that design and shows you how to use it in practice.

You might wonder why there is no `POST /auth/register-admin` endpoint. The answer is that such an endpoint would be a serious security vulnerability. Any user, including an attacker, could call it and elevate their own privileges. By keeping admin promotion exclusively in a CLI command, you ensure that only someone with direct terminal access to the server can promote a user. That is the appropriate level of access control for an operation this sensitive.

Start the server, register a regular user, then promote them using the CLI in a separate terminal:

```bash
# First, register a new user through the API
curl -s -X POST http://127.0.0.1:5000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "securepass123"}'
```

Expected response:

```json
{
  "id": 1,
  "username": "alice"
}
```

Now promote alice to admin using the CLI command. Stop the server first if you want to run this in the same terminal, or open a second terminal:

```bash
flask --app app set-admin alice
```

Expected output:

```
Success: 'alice' has been promoted to admin.
```

If you pass a username that does not exist, the command reports the problem cleanly:

```bash
flask --app app set-admin nobody
```

Expected output:

```
Error: user 'nobody' not found.
```

Note that the promotion only takes effect in the next login. If alice is already logged in with an existing token, that token still carries her old `user` role until it expires. She needs to log in again to receive a new token with the `admin` claim embedded. This is an inherent property of stateless JWT, and you will read more about it in the conceptual section.

## Step 6: Try It Out {#step-6-try-it-out}

Start the development server if it is not already running:

```bash
flask --app app run
```

### Scenario A: Admin Access

Register alice, promote her via CLI (as shown in Step 5), then log in to get an admin token:

```bash
curl -s -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "securepass123"}'
```

Expected response:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Save the token and create a book:

```bash
ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022}'
```

Expected response (status `201 Created`):

```json
{
  "author": "Luciano Ramalho",
  "id": 1,
  "title": "Fluent Python",
  "year": 2022
}
```

### Scenario B: Regular User Access

Register a second user as a regular account and log in:

```bash
curl -s -X POST http://127.0.0.1:5000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "bob", "password": "userpass123"}'

curl -s -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "bob", "password": "userpass123"}'
```

Save bob's token, then try to create a book:

```bash
USER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{"title": "Python Crash Course", "author": "Eric Matthes", "year": 2023}'
```

Expected response (status `403 Forbidden`):

```json
{
  "error": "Access denied",
  "required_roles": ["admin"],
  "your_role": "user"
}
```

Bob can still read without any token at all:

```bash
curl -s http://127.0.0.1:5000/books
```

Expected response (status `200 OK`):

```json
[
  {
    "author": "Luciano Ramalho",
    "id": 1,
    "title": "Fluent Python",
    "year": 2022
  }
]
```

### Scenario C: No Token

Without any token, write endpoints return 401 rather than 403, because the request is not authenticated at all:

```bash
curl -s -X DELETE http://127.0.0.1:5000/books/1
```

Expected response (status `401 Unauthorized`):

```json
{
  "error": "Authorization token is missing",
  "reason": "Missing Authorization Header"
}
```

The distinction between 401 and 403 matters. A 401 means "I do not know who you are; please provide credentials." A 403 means "I know who you are, but you are not allowed to do this." Clients can use this distinction to decide whether to show a login prompt (401) or an "access denied" message (403).

Press `CTRL+C` to stop the server.

## Step 7: Update the Test Suite {#step-7-update-tests}

The test suite needs two kinds of updates. First, several existing tests that create or modify books now need `admin_headers` instead of `auth_headers`, because those operations require the admin role. Second, new tests are needed to verify the 403 behavior for regular users. The read tests and the auth tests require no changes at all.

### Update conftest.py

The complete updated `tests/conftest.py` adds one new fixture, `admin_headers`, alongside all the fixtures from Part 2:

```python
import os
import sqlite3
import tempfile
import pytest
from app import create_app
from database import init_db


@pytest.fixture()
def app():
    db_fd, db_path = tempfile.mkstemp()
    app = create_app(test_config={
        "TESTING": True,
        "DATABASE": db_path,
        "JWT_SECRET_KEY": "test-secret-key-for-jwt-auth-32bytes",
    })
    with app.app_context():
        init_db()
    yield app
    os.close(db_fd)
    os.unlink(db_path)


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def registered_user(client):
    """Registers a standard user and returns their credentials."""
    client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"},
    )
    return {"username": "testuser", "password": "testpass123"}


@pytest.fixture()
def auth_headers(client, registered_user):
    """
    Returns Authorization headers for a regular user (role: user).

    This fixture is unchanged from Part 2. In Part 3 it is used specifically
    to test the 403 Forbidden behavior: a valid token with the wrong role.
    """
    response = client.post("/auth/login", json=registered_user)
    token = response.get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def admin_headers(client, app):
    """
    Registers a user, promotes them to admin directly in the test database,
    logs in, and returns the Authorization headers.

    We promote the user via a direct sqlite3 connection rather than through
    the Flask CLI command. Invoking CLI commands inside a Pytest session
    requires additional setup and the result would be identical: the user's
    role column is updated to 'admin', and the next login embeds that role
    into the JWT via the additional_claims we added in Step 2.
    """
    client.post(
        "/auth/register",
        json={"username": "adminuser", "password": "adminpass123"},
    )

    # Update the role directly in the test database file.
    # We use a plain sqlite3 connection here rather than Flask's get_db()
    # because get_db() depends on Flask's g object, which is tied to a
    # request context. Outside of a request, a direct connection is simpler.
    conn = sqlite3.connect(app.config["DATABASE"])
    conn.execute(
        "UPDATE users SET role = 'admin' WHERE username = ?", ("adminuser",)
    )
    conn.commit()
    conn.close()

    response = client.post(
        "/auth/login",
        json={"username": "adminuser", "password": "adminpass123"},
    )
    token = response.get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
```

### Update test_books.py

The following tests are updated compared to Part 2: `test_create_book_returns_201`, `test_create_book_validates_missing_fields`, `test_get_single_book`, `test_update_book_changes_only_sent_fields`, and `test_delete_book` all now use `admin_headers` instead of `auth_headers` for their setup POST requests. The new tests at the bottom cover the 403 Forbidden scenarios that are the core of this tutorial.

Here is the complete `tests/test_books.py`:

```python
# ------------------------------------------------------------------
# Auth Tests (unchanged from Part 2)
# ------------------------------------------------------------------

def test_register_returns_201(client):
    response = client.post(
        "/auth/register",
        json={"username": "alice", "password": "securepass123"},
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["username"] == "alice"
    assert "id" in data
    assert "password_hash" not in data


def test_register_rejects_duplicate_username(client):
    client.post("/auth/register", json={"username": "alice", "password": "pass12345"})
    response = client.post(
        "/auth/register",
        json={"username": "alice", "password": "different123"},
    )
    assert response.status_code == 409


def test_register_validates_missing_fields(client):
    response = client.post("/auth/register", json={"username": "alice"})
    assert response.status_code == 422
    assert "password" in response.get_json()["errors"]


def test_login_returns_access_token(client, registered_user):
    response = client.post("/auth/login", json=registered_user)
    assert response.status_code == 200
    assert "access_token" in response.get_json()


def test_login_rejects_wrong_password(client, registered_user):
    response = client.post(
        "/auth/login",
        json={"username": registered_user["username"], "password": "wrongpassword"},
    )
    assert response.status_code == 401


# ------------------------------------------------------------------
# Book Tests: read endpoints (public, unchanged from Part 2)
# ------------------------------------------------------------------

def test_get_books_returns_empty_list(client):
    response = client.get("/books")
    assert response.status_code == 200
    assert response.get_json() == []


def test_get_book_returns_404_for_unknown_id(client):
    response = client.get("/books/999")
    assert response.status_code == 404
    assert "error" in response.get_json()


# ------------------------------------------------------------------
# Book Tests: write endpoints without token (expect 401)
# ------------------------------------------------------------------

def test_create_book_without_token_returns_401(client):
    response = client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
    )
    assert response.status_code == 401


def test_update_book_without_token_returns_401(client, admin_headers):
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.put("/books/1", json={"year": 2023})
    assert response.status_code == 401


def test_delete_book_without_token_returns_401(client, admin_headers):
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.delete("/books/1")
    assert response.status_code == 401


# ------------------------------------------------------------------
# Book Tests: write endpoints with user role (expect 403)
# ------------------------------------------------------------------

def test_user_cannot_create_book(client, auth_headers):
    """A regular user with a valid token should receive 403 on POST /books."""
    response = client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    assert response.status_code == 403
    data = response.get_json()
    assert data["error"] == "Access denied"
    # The response should tell the client what role is required.
    assert "admin" in data["required_roles"]


def test_user_cannot_update_book(client, admin_headers, auth_headers):
    """A regular user should receive 403 when trying to update a book."""
    # Use admin to create the book first so there is something to update.
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.put(
        "/books/1",
        json={"year": 2023},
        headers=auth_headers,
    )
    assert response.status_code == 403


def test_user_cannot_delete_book(client, admin_headers, auth_headers):
    """A regular user should receive 403 when trying to delete a book."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.delete("/books/1", headers=auth_headers)
    assert response.status_code == 403


# ------------------------------------------------------------------
# Book Tests: write endpoints with admin role (expect success)
# ------------------------------------------------------------------

def test_create_book_returns_201(client, admin_headers):
    response = client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["title"] == "Fluent Python"
    assert "id" in data


def test_create_book_validates_missing_fields(client, admin_headers):
    response = client.post(
        "/books",
        json={"title": "Incomplete Book"},
        headers=admin_headers,
    )
    assert response.status_code == 422
    errors = response.get_json()["errors"]
    assert "author" in errors
    assert "year" in errors


def test_get_single_book(client, admin_headers):
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.get("/books/1")
    assert response.status_code == 200
    assert response.get_json()["title"] == "Fluent Python"


def test_update_book_changes_only_sent_fields(client, admin_headers):
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.put(
        "/books/1",
        json={"year": 2023},
        headers=admin_headers,
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["year"] == 2023
    assert data["title"] == "Fluent Python"
    assert data["author"] == "Luciano Ramalho"


def test_update_book_returns_404_for_unknown_id(client, admin_headers):
    response = client.put(
        "/books/999",
        json={"title": "Ghost Book"},
        headers=admin_headers,
    )
    assert response.status_code == 404


def test_delete_book(client, admin_headers):
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=admin_headers,
    )
    response = client.delete("/books/1", headers=admin_headers)
    assert response.status_code == 200
    assert "message" in response.get_json()
    follow_up = client.get("/books/1")
    assert follow_up.status_code == 404


def test_delete_book_returns_404_for_unknown_id(client, admin_headers):
    response = client.delete("/books/999", headers=admin_headers)
    assert response.status_code == 404
```

Run the full test suite:

```bash
pytest tests/ -v
```

Expected output:

```
collected 20 items                                                             

tests/test_books.py::test_register_returns_201 PASSED                    [  5%]
tests/test_books.py::test_register_rejects_duplicate_username PASSED     [ 10%]
tests/test_books.py::test_register_validates_missing_fields PASSED       [ 15%]
tests/test_books.py::test_login_returns_access_token PASSED              [ 20%]
tests/test_books.py::test_login_rejects_wrong_password PASSED            [ 25%]
tests/test_books.py::test_get_books_returns_empty_list PASSED            [ 30%]
tests/test_books.py::test_get_book_returns_404_for_unknown_id PASSED     [ 35%]
tests/test_books.py::test_create_book_without_token_returns_401 PASSED   [ 40%]
tests/test_books.py::test_update_book_without_token_returns_401 PASSED   [ 45%]
tests/test_books.py::test_delete_book_without_token_returns_401 PASSED   [ 50%]
tests/test_books.py::test_user_cannot_create_book PASSED                 [ 55%]
tests/test_books.py::test_user_cannot_update_book PASSED                 [ 60%]
tests/test_books.py::test_user_cannot_delete_book PASSED                 [ 65%]
tests/test_books.py::test_create_book_returns_201 PASSED                 [ 70%]
tests/test_books.py::test_create_book_validates_missing_fields PASSED    [ 75%]
tests/test_books.py::test_get_single_book PASSED                         [ 80%]
tests/test_books.py::test_update_book_changes_only_sent_fields PASSED    [ 85%]
tests/test_books.py::test_update_book_returns_404_for_unknown_id PASSED  [ 90%]
tests/test_books.py::test_delete_book PASSED                             [ 95%]
tests/test_books.py::test_delete_book_returns_404_for_unknown_id PASSED  [100%]

============================== 20 passed in 2.70s ==============================
```

All 20 tests pass. The 17 tests from Part 2 still work, and the 3 new tests for role enforcement (`test_user_cannot_create_book`, `test_user_cannot_update_book`, `test_user_cannot_delete_book`) verify that the `user` role correctly receives 403 on all write endpoints.

## How Role Claims Work in JWT {#how-role-claims-work}

This section explains the deeper reasoning behind the decisions made in this tutorial, so you can adapt them confidently when your requirements differ.

### Why Store the Role in the Token Rather Than the Database

There are two valid approaches to checking a user's role on each request. The first is what this tutorial implements: read the role from the database at login, embed it as a JWT claim, and then check the claim on every subsequent request without touching the database. The second approach is to store only the user's id in the token and query the database on every single request to look up the current role.

The token-based approach is faster. Every protected endpoint answers the question "what role does this user have?" without opening a database connection. For an API that handles many requests per second, this difference adds up meaningfully.

The database-based approach is more reactive. If you change a user's role in the database, the change takes effect on the very next request because every request re-reads the database. With the token-based approach, a user who just had their admin role revoked continues to have admin access until their token expires, up to 15 minutes by default with Flask-JWT-Extended's settings.

For most applications in the early stages of development, the token-based approach is the right choice. It is simpler, faster, and the delay before a role change takes effect is acceptable when token expiry times are short. If your application needs immediate role revocation, you will need token blacklisting, which is the topic of the next tutorial in this series.

### What get_jwt() Returns

When you call `get_jwt()` inside a protected route, it returns the complete decoded payload of the current request's JWT as a Python dictionary. For a token issued by this API, that dictionary will look something like this:

```json
{
  "fresh": false,
  "iat": 1716300000,
  "jti": "a1b2c3d4-e5f6-...",
  "type": "access",
  "sub": "1",
  "nbf": 1716300000,
  "exp": 1716300900,
  "role": "admin"
}
```

The `role` key is your custom claim. All the other keys are standard JWT claims that Flask-JWT-Extended manages automatically. Because `get_jwt()` reads from the already-decoded token in memory rather than making any I/O calls, it is essentially free in terms of performance.

### Why Role Data Is Safe in JWT But Passwords Are Not

A common source of confusion is understanding what information is appropriate to store in a JWT. The payload is base64url-encoded, not encrypted. Anyone who intercepts a token can trivially decode the header and payload and read every claim inside. The signature only proves that the payload has not been tampered with since it was issued; it does not hide the contents.

This means role names like `"admin"` or `"user"` are completely safe to store in a JWT claim, because knowing that a user has the admin role is not sensitive in itself. What matters is that an attacker cannot forge a token claiming they have the admin role, and the cryptographic signature prevents exactly that.

Password hashes, personal identification numbers, private API keys, and any other data that would be harmful if exposed must never appear in a JWT payload.

### The functools.wraps Requirement

The `@wraps(fn)` line in the `role_required` decorator is easy to overlook, but removing it would break the application in a subtle way. When Flask registers routes, it uses the function's `__name__` attribute as the endpoint name. Without `@wraps(fn)`, every function returned by `role_required`'s inner `decorator` would have the name `wrapper`. Flask would then try to register three endpoints all called `wrapper`, detect the conflict, and raise an `AssertionError` before the server ever starts. The `@wraps(fn)` decorator copies the original function's name, docstring, and other metadata onto the wrapper, so Flask sees three distinct names: `create_book`, `update_book`, and `delete_book`.

## Conclusion {#conclusion}

You have extended the Flask Books API with a two-role permission system built entirely from the tools already in your project. Here are the key ideas to carry forward:

- **Default to least privilege.** The `DEFAULT 'user'` constraint on the role column ensures that every new account is created with the most restricted access level. There is no way to accidentally produce an admin account through the API.
- **Embed role in the token at login, not on every request.** Using `additional_claims={"role": user["role"]}` in `create_access_token()` means role checks cost nothing after the initial login. The trade-off is that role changes do not take effect until the current token expires.
- **A decorator factory is the right abstraction for access control.** The `role_required(*roles)` pattern lets you express permissions in a single readable line per route, keeps the authorization logic in one file, and supports multiple allowed roles without changing the decorator's interface.
- **`@wraps(fn)` is not optional.** Omitting it causes Flask to raise an `AssertionError` about duplicate endpoint names as soon as you apply the decorator to more than one route.
- **401 and 403 are not interchangeable.** A 401 means the request lacks valid credentials. A 403 means the credentials are valid but the user is not permitted to perform this action. The distinction matters for clients and for security auditors reading your logs.
- **Admin promotion belongs in a CLI command, not an API endpoint.** Restricting admin promotion to a CLI command means only someone with server access can perform it. An API endpoint for the same purpose would be a privilege escalation vulnerability.
- **The `admin_headers` test fixture promotes via direct SQL.** Invoking Flask CLI commands inside Pytest requires extra setup. Updating the role column directly through a sqlite3 connection achieves the same result in fewer lines and keeps the fixture focused on what it is actually testing.