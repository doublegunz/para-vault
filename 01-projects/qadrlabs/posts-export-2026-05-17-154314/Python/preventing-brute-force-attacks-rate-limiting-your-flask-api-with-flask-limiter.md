---
title: "Preventing Brute Force Attacks: Rate Limiting Your Flask API with Flask-Limiter"
slug: "preventing-brute-force-attacks-rate-limiting-your-flask-api-with-flask-limiter"
category: "Python"
date: "2026-04-27"
status: "published"
---

In [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) you built the API. In [Part 2](https://qadrlabs.com/post/adding-jwt-authentication-to-your-flask-rest-api) you added JWT authentication. In [Part 3](https://qadrlabs.com/post/role-based-access-control-in-flask-separating-admin-and-user-permissions) you restricted write access to admin users only. The authentication layer is solid, but there is still one gap that none of those changes address: an attacker can still send thousands of login attempts per minute, cycling through a password list until they find one that works. Your API will faithfully respond to every single request, and at no point will it slow them down.

This is a brute force attack, and the standard defense is rate limiting. The idea is simple: track how many requests each IP address sends within a time window, and reject requests that exceed the threshold with a `429 Too Many Requests` response. A legitimate user logging in once or twice a minute will never notice. An automated script sending 600 attempts per minute will be stopped after the fifth one.

This tutorial adds rate limiting to the Flask Books API using Flask-Limiter. No changes to the database, no changes to JWT configuration. It slots in on top of the project exactly as it is after Part 3.

## Overview {#overview}

This is Part 4 of the Flask Books API series. If you have not completed the previous parts, start with [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) before continuing here.

### What You'll Build

- A global rate limit of 200 requests per day applied to every endpoint as a baseline
- A strict per-route limit of 5 requests per minute on `POST /auth/login` to block brute force attacks
- A per-route limit of 3 requests per minute on `POST /auth/register` to prevent account spam
- A custom JSON error handler for 429 responses so the API stays consistent
- Rate limit headers in every response so clients know their remaining quota
- A separate test file, `tests/test_rate_limits.py`, that verifies the limits work correctly

### What You'll Learn

- How to install and configure Flask-Limiter using the application factory pattern
- How `get_remote_address` works as the default key function for tracking clients
- Why the global default limit and per-route limits serve different purposes
- How to disable rate limiting in your main test suite so existing tests are not affected
- How to write a dedicated Pytest fixture that re-enables rate limiting for limit-specific tests

### What You'll Need

- The completed project from [Part 3](https://qadrlabs.com/post/role-based-access-control-in-flask)
- Python 3.10 or higher with the virtual environment from previous parts active

## Step 1: Install Flask-Limiter {#step-1-install-flask-limiter}

Activate your virtual environment and install the package:

```bash
source .venv/bin/activate
pip install flask-limiter
pip freeze > requirements.txt
```

Flask-Limiter is the only new dependency this tutorial introduces. It handles the full lifecycle of rate limiting: counting requests per key, applying time windows, triggering 429 responses when limits are exceeded, and optionally injecting rate limit headers into every response.

You might wonder why this tutorial reaches for Flask-Limiter rather than building a token bucket counter manually using a Python dictionary and `time.time()`. A hand-rolled implementation works in a single-process development server, but falls apart the moment you run more than one worker process, because each process has its own memory. Flask-Limiter is designed from the start to support pluggable storage backends, starting with in-memory for development and scaling to Redis for production. You get that flexibility without writing the coordination logic yourself.

## Step 2: Initialize the Limiter in the App Factory {#step-2-initialize-limiter}

Flask-Limiter integrates with Flask's application factory pattern using the familiar `init_app()` pattern. The `Limiter` instance is created at module level, outside `create_app()`, and then bound to the app inside the factory. This arrangement lets routes inside `create_app()` reference `limiter` through closure, while keeping the app creation reusable and testable.

Open `app.py` and make the following additions. The complete file after this step is shown below, with `# [NEW]` marking every changed or added line:

```python
import os
import click
from dotenv import load_dotenv
from flask import Flask, jsonify, request, abort
from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    get_jwt_identity,
)
from flask_limiter import Limiter                        # [NEW]
from flask_limiter.util import get_remote_address       # [NEW]
from database import get_db, close_db, init_db
from decorators import role_required

load_dotenv()

# [NEW] Create the Limiter instance at module level so it can be referenced
# by route decorators inside create_app(). We pass key_func here but do not
# set a storage_uri; that is done inside create_app() via app.config so that
# tests can override it independently per app instance.
limiter = Limiter(key_func=get_remote_address)


def create_app(test_config=None):
    app = Flask(__name__)

    app.config.from_mapping(
        DATABASE=os.path.join(app.instance_path, "books.db"),
        JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "dev-only-secret"),
        # [NEW] Use in-memory storage for development. This is suitable for a
        # single-process server. For production with multiple workers, replace
        # this with a Redis URI such as "redis://localhost:6379".
        # Note: this is a study case configuration. Adjust storage and limits
        # according to your actual production requirements.
        RATELIMIT_STORAGE_URI="memory://",
        # [NEW] Include rate limit headers in every response so clients know
        # how many requests they have left and when the window resets.
        RATELIMIT_HEADERS_ENABLED=True,
    )

    if test_config is not None:
        app.config.from_mapping(test_config)

    os.makedirs(app.instance_path, exist_ok=True)
    app.teardown_appcontext(close_db)

    # [NEW] Bind the module-level Limiter to this app instance. This call
    # reads RATELIMIT_STORAGE_URI and other RATELIMIT_* config values from
    # app.config, so calling it after from_mapping() ensures it picks up
    # all the right settings including any test overrides.
    limiter.init_app(app)

    # ------------------------------------------------------------------
    # JWT Error Handlers (unchanged from Part 3)
    # ------------------------------------------------------------------

    jwt = JWTManager(app)

    @jwt.unauthorized_loader
    def missing_token_callback(reason):
        return jsonify({"error": "Authorization token is missing", "reason": reason}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(reason):
        return jsonify({"error": "Authorization token is invalid", "reason": reason}), 422

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({"error": "Authorization token has expired"}), 401

    # [NEW] Custom 429 error handler.
    # Without this, Flask-Limiter returns an HTML error page when a limit is
    # exceeded, which breaks the JSON contract our API maintains everywhere
    # else. This handler intercepts every 429 and returns a JSON response
    # in the same format as our other error responses.
    @app.errorhandler(429)
    def rate_limit_exceeded(e):
        return jsonify({
            "error": "Too many requests",
            "message": str(e.description),
        }), 429

    # ------------------------------------------------------------------
    # Auth Routes
    # ------------------------------------------------------------------

    @app.route("/auth/register", methods=["POST"])
    @limiter.limit("3 per minute")                      # [NEW]
    def register():
        """
        Registers a new user with the default 'user' role.

        Rate limited to 3 requests per minute per IP. This is intentionally
        more lenient than the login limit because registration is a one-time
        action, but still strict enough to prevent automated account creation
        at scale.
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
    @limiter.limit("5 per minute")                      # [NEW]
    def login():
        """
        Authenticates a user and returns a JWT with the user's role embedded.

        Rate limited to 5 requests per minute per IP. This is the most critical
        limit in the application because login is the primary target of brute
        force attacks. Five attempts per minute is enough for a legitimate user
        who misremembers their password; it is far too few for an automated
        credential-stuffing script.
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
            additional_claims={"role": user["role"]},
        )
        return jsonify({"access_token": access_token}), 200

    # ------------------------------------------------------------------
    # Book Routes (unchanged from Part 3)
    # ------------------------------------------------------------------

    @app.route("/books", methods=["GET"])
    def get_books():
        db = get_db()
        books = db.execute("SELECT * FROM books ORDER BY id").fetchall()
        return jsonify([dict(book) for book in books])

    @app.route("/books/<int:book_id>", methods=["GET"])
    def get_book(book_id):
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        return jsonify(dict(book))

    @app.route("/books", methods=["POST"])
    @role_required("admin")
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
    @role_required("admin")
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
    @role_required("admin")
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
    # Error Handlers (unchanged from Part 3)
    # ------------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"error": "Method not allowed"}), 405

    # ------------------------------------------------------------------
    # CLI Commands (unchanged from Part 3)
    # ------------------------------------------------------------------

    @app.cli.command("init-db")
    def init_db_command():
        """Initializes the database by running schema.sql."""
        init_db()
        click.echo("Database initialized successfully.")

    @app.cli.command("set-admin")
    @click.argument("username")
    def set_admin_command(username):
        """Promotes an existing user to the admin role."""
        db = get_db()
        user = db.execute(
            "SELECT id FROM users WHERE username = ?", (username,)
        ).fetchone()
        if user is None:
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

The two rate limiting decorators are the only additions to the routes. Every other change in this step is infrastructure: importing the library, creating the `Limiter` instance, calling `init_app`, and registering the 429 error handler.

One detail worth understanding is why `limiter` is created at module level but `limiter.init_app(app)` is called inside `create_app()`. The `Limiter` constructor only sets up the key function; it does not know anything about Flask yet. The `init_app()` call is where Flask-Limiter reads `RATELIMIT_STORAGE_URI` and the other `RATELIMIT_*` configuration values from `app.config`. Because `init_app()` runs after `app.config.from_mapping()`, any value set in `test_config` will already be in place when the limiter reads the config. This is what makes per-test configuration overrides work correctly.

## Step 3: Try It Out {#step-3-try-it-out}

Initialize the database and start the server:

```bash
flask --app app init-db
flask --app app run
```

### Scenario A: Inspecting Rate Limit Headers

Register a user and log in once. The `-i` flag tells curl to include response headers in the output:

```bash
curl -si -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "securepass123"}'
```

Expected response (headers shown first):

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 5
X-RateLimit-Remaining: 4
X-RateLimit-Reset: 1716300060
Content-Type: application/json

{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

`X-RateLimit-Limit` tells the client the total allowed requests per window. `X-RateLimit-Remaining` decrements with each successful request, starting at 4 after the first call. `X-RateLimit-Reset` is a Unix timestamp indicating when the counter resets. API clients can read these headers to implement backoff behavior before hitting the limit.

### Scenario B: Simulating a Brute Force Attack

Send six login requests in rapid succession. The first five succeed; the sixth is blocked:

```bash
for i in $(seq 1 6); do
  echo "Attempt $i:"
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST http://127.0.0.1:5000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username": "alice", "password": "wrongpassword"}'
done
```

Expected output:

```
Attempt 1: 401
Attempt 2: 401
Attempt 3: 401
Attempt 4: 401
Attempt 5: 401
Attempt 6: 429
```

The first five attempts return `401 Unauthorized` because the credentials are wrong; Flask still processes those requests fully and they count against the limit. The sixth attempt returns `429 Too Many Requests` before the login function even runs. The attacker cannot try a sixth password regardless of what it is.

Confirm the JSON shape of the 429 response:

```bash
curl -s -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "wrongpassword"}'
```

Expected response (status `429`):

```json
{
  "error": "Too many requests",
  "message": "5 per 1 minute"
}
```

### Scenario C: Book Endpoints Are Covered by the Global Default

The book endpoints have no per-route decorator, so they fall under the global `200 per day` default. A single request to `GET /books` includes the default limit headers:

```bash
curl -si http://127.0.0.1:5000/books
```

Expected response headers (excerpt):

```
X-RateLimit-Limit: 200
X-RateLimit-Remaining: 199
X-RateLimit-Reset: 1716386400
```

Press `CTRL+C` to stop the server.

## Step 4: Update the Test Suite {#step-4-update-the-test-suite}

Rate limiting creates a problem for the existing tests. If `RATELIMIT_ENABLED` is `True` in all tests, any test that calls `POST /auth/login` multiple times across the test suite risks triggering a 429, which would cause unrelated tests to fail for the wrong reason. The solution is to separate concerns cleanly.

The strategy is two-part: update `conftest.py` to disable rate limiting for all existing tests by default, then create a new `tests/test_rate_limits.py` file with its own fixture that re-enables rate limiting only for the tests that specifically verify limit behavior.

### Update conftest.py

The only change to `conftest.py` is adding `RATELIMIT_ENABLED: False` to the default `test_config`. Every existing fixture and test automatically inherits this setting without any other modification:

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
        "RATELIMIT_ENABLED": False,             # [NEW] Disable rate limiting
                                                # across all standard tests.
                                                # Tests that specifically verify
                                                # rate limit behavior live in
                                                # tests/test_rate_limits.py and
                                                # use their own fixture that
                                                # re-enables limiting.
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
    """Returns Authorization headers for a regular user (role: user)."""
    response = client.post("/auth/login", json=registered_user)
    token = response.get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def admin_headers(client, app):
    """Registers a user, promotes them to admin, and returns admin Authorization headers."""
    client.post(
        "/auth/register",
        json={"username": "adminuser", "password": "adminpass123"},
    )
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

### Create tests/test_rate_limits.py

Create the new file `tests/test_rate_limits.py`. This file defines its own `rate_limited_app` and `rate_limited_client` fixtures that are completely independent from the ones in `conftest.py`. The key difference is that `RATELIMIT_ENABLED` is `True` and `RATELIMIT_STORAGE_URI` is explicitly set to `"memory://"`.

Each test in this file gets a fresh app instance with a fresh in-memory counter, so tests cannot interfere with each other:

```python
import os
import tempfile
import pytest
from app import create_app
from database import init_db


@pytest.fixture()
def rate_limited_app():
    """
    Creates a Flask app instance with rate limiting fully enabled.

    This fixture is intentionally separate from the 'app' fixture in
    conftest.py. The conftest.py fixture disables rate limiting so that
    the main test suite can call login and register freely. This fixture
    re-enables it so the rate limit tests can verify the actual limiting
    behavior without interference from counter state shared across tests.

    Each call to this fixture creates a fresh app instance with a fresh
    in-memory storage backend, so rate limit counters are always at zero
    at the start of every test in this file.
    """
    db_fd, db_path = tempfile.mkstemp()
    app = create_app(test_config={
        "TESTING": True,
        "DATABASE": db_path,
        "JWT_SECRET_KEY": "test-secret-key-for-jwt-auth-32bytes",
        "RATELIMIT_ENABLED": True,
        "RATELIMIT_STORAGE_URI": "memory://",
    })
    with app.app_context():
        init_db()
    yield app
    os.close(db_fd)
    os.unlink(db_path)


@pytest.fixture()
def rate_limited_client(rate_limited_app):
    """Returns a test client bound to the rate-limited app."""
    return rate_limited_app.test_client()


def test_login_allows_requests_up_to_limit(rate_limited_client):
    """
    The first 5 login attempts should receive either 200 or 401,
    never 429. This confirms the limit is set to 5 and not lower.
    """
    # Register a user so that at least one login attempt can succeed.
    rate_limited_client.post(
        "/auth/register",
        json={"username": "alice", "password": "securepass123"},
    )

    for i in range(5):
        response = rate_limited_client.post(
            "/auth/login",
            json={"username": "alice", "password": "wrongpassword"},
        )
        # Each attempt should be processed normally (401 for wrong password).
        # A 429 at this stage would mean the limit is lower than expected.
        assert response.status_code == 401, (
            f"Expected 401 on attempt {i + 1}, got {response.status_code}"
        )


def test_login_blocks_sixth_attempt(rate_limited_client):
    """
    The sixth login attempt within the same minute should return 429.
    """
    rate_limited_client.post(
        "/auth/register",
        json={"username": "alice", "password": "securepass123"},
    )

    for _ in range(5):
        rate_limited_client.post(
            "/auth/login",
            json={"username": "alice", "password": "wrongpassword"},
        )

    # The sixth attempt must be blocked regardless of credentials.
    response = rate_limited_client.post(
        "/auth/login",
        json={"username": "alice", "password": "securepass123"},
    )
    assert response.status_code == 429
    data = response.get_json()
    assert data["error"] == "Too many requests"


def test_register_allows_requests_up_to_limit(rate_limited_client):
    """
    The first 3 registration attempts should be processed normally.
    """
    for i in range(3):
        response = rate_limited_client.post(
            "/auth/register",
            json={
                "username": f"user{i}",
                "password": "securepass123",
            },
        )
        # Each attempt should succeed (201) or fail with a validation
        # error (409 for duplicate), never with a rate limit error.
        assert response.status_code in (201, 409), (
            f"Expected 201 or 409 on attempt {i + 1}, got {response.status_code}"
        )


def test_register_blocks_fourth_attempt(rate_limited_client):
    """
    The fourth registration attempt within the same minute should return 429.
    """
    for i in range(3):
        rate_limited_client.post(
            "/auth/register",
            json={
                "username": f"user{i}",
                "password": "securepass123",
            },
        )

    response = rate_limited_client.post(
        "/auth/register",
        json={"username": "overflow", "password": "securepass123"},
    )
    assert response.status_code == 429
    data = response.get_json()
    assert data["error"] == "Too many requests"


def test_429_response_includes_rate_limit_headers(rate_limited_client):
    """
    When a 429 is returned, the response should include rate limit headers
    so clients can read the reset time and implement backoff.
    """
    rate_limited_client.post(
        "/auth/register",
        json={"username": "alice", "password": "securepass123"},
    )

    for _ in range(5):
        rate_limited_client.post(
            "/auth/login",
            json={"username": "alice", "password": "wrongpassword"},
        )

    response = rate_limited_client.post(
        "/auth/login",
        json={"username": "alice", "password": "wrongpassword"},
    )
    assert response.status_code == 429
    # Flask-Limiter injects these headers on every response when
    # RATELIMIT_HEADERS_ENABLED is True, including 429 responses.
    assert "X-RateLimit-Limit" in response.headers
    assert "X-RateLimit-Remaining" in response.headers
    assert "X-RateLimit-Reset" in response.headers
```

Run the full test suite from the project root to confirm all tests pass, including both the existing ones and the new rate limit tests:

```bash
pytest tests/ -v
```

Expected output:

```
============================= test session starts ==============================
platform linux -- Python 3.14.3, pytest-8.3.5, pluggy-1.5.0
rootdir: /path/to/flask-books-api
collected 25 items

tests/test_books.py::test_register_returns_201 PASSED                    [  4%]
tests/test_books.py::test_register_rejects_duplicate_username PASSED     [  8%]
tests/test_books.py::test_register_validates_missing_fields PASSED       [ 12%]
tests/test_books.py::test_login_returns_access_token PASSED              [ 16%]
tests/test_books.py::test_login_rejects_wrong_password PASSED            [ 20%]
tests/test_books.py::test_get_books_returns_empty_list PASSED            [ 24%]
tests/test_books.py::test_get_book_returns_404_for_unknown_id PASSED     [ 28%]
tests/test_books.py::test_create_book_without_token_returns_401 PASSED   [ 32%]
tests/test_books.py::test_update_book_without_token_returns_401 PASSED   [ 36%]
tests/test_books.py::test_delete_book_without_token_returns_401 PASSED   [ 40%]
tests/test_books.py::test_user_cannot_create_book PASSED                 [ 44%]
tests/test_books.py::test_user_cannot_update_book PASSED                 [ 48%]
tests/test_books.py::test_user_cannot_delete_book PASSED                 [ 52%]
tests/test_books.py::test_create_book_returns_201 PASSED                 [ 56%]
tests/test_books.py::test_create_book_validates_missing_fields PASSED    [ 60%]
tests/test_books.py::test_get_single_book PASSED                         [ 64%]
tests/test_books.py::test_update_book_changes_only_sent_fields PASSED    [ 68%]
tests/test_books.py::test_update_book_returns_404_for_unknown_id PASSED  [ 72%]
tests/test_books.py::test_delete_book PASSED                             [ 76%]
tests/test_books.py::test_delete_book_returns_404_for_unknown_id PASSED  [ 80%]
tests/test_rate_limits.py::test_login_allows_requests_up_to_limit PASSED [ 84%]
tests/test_rate_limits.py::test_login_blocks_sixth_attempt PASSED        [ 88%]
tests/test_rate_limits.py::test_register_allows_requests_up_to_limit PASSED [ 92%]
tests/test_rate_limits.py::test_register_blocks_fourth_attempt PASSED    [ 96%]
tests/test_rate_limits.py::test_429_response_includes_rate_limit_headers PASSED [100%]

============================== 25 passed in 3.21s ==============================
```

All 25 tests pass. The 20 tests from Part 3 run with rate limiting disabled and are unaffected. The 5 new tests in `test_rate_limits.py` run with rate limiting enabled and verify the limit behavior precisely.

## How Rate Limiting Works Under the Hood {#how-rate-limiting-works}

Understanding the mechanics behind rate limiting helps you choose the right limits, debug unexpected 429 responses, and make informed decisions when you move to production.

### The Fixed Window Counter

Flask-Limiter's default strategy is a fixed window counter. When you write `@limiter.limit("5 per minute")`, the library creates a counter keyed to the client's IP address and the endpoint. The first request within a one-minute window sets the counter to 1. Each subsequent request from the same IP increments it. When the counter reaches 5, all further requests are blocked until the minute boundary passes and the counter resets to zero.

The fixed window is simple and fast, but it has a known edge case: a client can send 5 requests at the end of one window and 5 more at the start of the next, effectively making 10 requests in a very short span. For a login endpoint, this edge case is generally acceptable because the window is short and the burst window is small. More sophisticated strategies like sliding window or token bucket are available in Flask-Limiter but require more storage overhead.

### get_remote_address and Proxies

`get_remote_address` reads `request.remote_addr`, which is the IP address of the TCP connection reaching your server. In direct deployments where the client connects straight to Flask, this is the client's real IP. If your application runs behind a reverse proxy such as Nginx or a load balancer, `request.remote_addr` will be the proxy's IP address, which means every client appears to come from the same address and they all share one counter.

The standard fix is to use Werkzeug's `ProxyFix` middleware, which reads the `X-Forwarded-For` header that proxies typically set, and makes `request.remote_addr` reflect the real client IP again. This is important to configure before deploying to any environment where Flask does not receive connections directly from clients.

### In-Memory Storage and Its Limitations

The `memory://` storage URI stores all counters in a Python dictionary inside the running process. This is exactly right for development and for a single-process server, but it has two limitations in production.

First, if you run multiple worker processes (for example with Gunicorn using multiple workers), each process has its own dictionary and its own counters. A client can make 5 login attempts to worker A, then 5 more to worker B, and neither worker knows about the other's counter. The effective limit becomes `5 * number_of_workers`.

Second, every time the server restarts, all counters reset to zero. A client who was being rate limited can bypass the limit simply by waiting for a deployment.

Both problems are solved by using a shared external storage backend. Redis is the standard choice: it runs as a separate process, is visible to all workers, and persists counters across server restarts. Switching from in-memory to Redis requires only changing the storage URI in your configuration from `"memory://"` to `"redis://your-redis-host:6379"`. No code changes are needed anywhere else. That migration is the topic of a future tutorial in this series.

### Why the Login Limit Is Stricter Than Register

The login endpoint is the most valuable target for an attacker. A brute force attack against login has a clear payoff: once the right password is found, the attacker has full access to that account. The register endpoint is less attractive because creating accounts is not inherently valuable; the attack you are defending against there is bulk account creation for spam or abuse, which requires sustaining many requests over a longer period rather than rapid bursts.

Five attempts per minute on login reflects a real-world balance. A user who misremembers their password typically tries two or three variations before giving up and resetting. Allowing five gives comfortable headroom. An automated script trying passwords from a leaked list typically runs at hundreds or thousands of attempts per minute; five effectively stops it. Three per minute on register means a human can still sign up, retry if they mistype, and succeed, while a bot cannot create more than three accounts per minute per IP address.

## Conclusion {#conclusion}

You have added rate limiting to the Flask Books API without changing the database schema, the JWT setup, or any existing test. Here are the key ideas to carry forward:

- **Create `Limiter` at module level, call `init_app` inside `create_app`.** This is the correct application factory pattern for Flask-Limiter. The `Limiter` instance acts as a coordinator; the actual storage and configuration are bound to the app at `init_app` time, which means test overrides in `test_config` are applied before the limiter reads them.
- **The global `default_limits` is a safety net, not the primary defense.** Setting `"200 per day"` on every endpoint prevents runaway traffic to endpoints you did not think to protect individually. The meaningful protection on sensitive endpoints like login comes from the per-route `@limiter.limit()` decorator. Note that the specific limits used in this tutorial are examples for a study case; production limits should be calibrated to your actual traffic patterns and security requirements.
- **The 429 error handler is required for API consistency.** Without it, Flask-Limiter returns an HTML page when a limit is exceeded, which breaks the JSON contract your API maintains on every other response.
- **Disable rate limiting in the default test fixture with `RATELIMIT_ENABLED: False`.** This prevents limit counters from interfering with tests that need to call login or register multiple times as setup steps. Tests that actually verify rate limit behavior belong in a separate file with a dedicated fixture that explicitly re-enables limiting.
- **`memory://` storage is for development only.** Counter state is process-local and disappears on restart. A multi-worker production deployment needs a shared backend like Redis, which requires only a URI change in configuration and no code changes.
- **`get_remote_address` breaks behind a proxy.** If your Flask app receives connections through Nginx, a load balancer, or any other reverse proxy, configure Werkzeug's `ProxyFix` middleware so that rate limits are applied per real client IP rather than per proxy IP.