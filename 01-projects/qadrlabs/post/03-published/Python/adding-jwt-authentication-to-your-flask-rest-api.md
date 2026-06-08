---
title: "Adding JWT Authentication to Your Flask REST API"
slug: "adding-jwt-authentication-to-your-flask-rest-api"
category: "Python"
date: "2026-04-26"
status: "published"
---

In the [previous tutorial](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite), you built a fully functional CRUD REST API for managing books using Flask and SQLite. The API works, but it has a significant gap: anyone with network access can create, modify, or delete books without identifying themselves. There is no concept of a registered user, no login process, and no way to tell a trusted request from a malicious one.

This tutorial picks up exactly where that one left off. You will add user registration and login endpoints, protect the write operations behind JWT-based authentication, and update the test suite to cover the new behavior. The read endpoints will remain public, which is a deliberate choice for this study case. In a real-world application, you would decide which endpoints require authentication based on your specific requirements.

By the end of this tutorial, your API will issue a signed JSON Web Token when a user logs in, and reject any attempt to create, update, or delete a book if that token is missing or invalid.

## Overview {#overview}

This is Part 2 of the Flask Books API series. The code you will write in this tutorial builds directly on top of the project from Part 1. If you have not completed that tutorial yet, you can read it at [qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite) before continuing here.

### What You'll Build

- A `POST /auth/register` endpoint that accepts a username and password, hashes the password securely, and stores the new user in SQLite
- A `POST /auth/login` endpoint that verifies credentials and returns a signed JWT access token
- Protected versions of the `POST /books`, `PUT /books/<id>`, and `DELETE /books/<id>` endpoints that reject requests without a valid token
- An updated Pytest suite that covers registration, login, and authentication enforcement

### What You'll Learn

- How to install and configure Flask-JWT-Extended alongside an existing Flask app
- How to hash and verify passwords using `werkzeug.security`, which ships with Flask and requires no additional installation
- How to load secrets from a `.env` file using `python-dotenv` so the JWT secret key never lives in your source code
- How to protect individual routes with the `@jwt_required()` decorator
- How to write authenticated test cases by including the `Authorization` header in Pytest requests

### What You'll Need

- The completed Flask Books API project from [Part 1](https://qadrlabs.com/post/building-a-crud-rest-api-with-flask-and-sqlite)
- Python 3.10 or higher
- Basic familiarity with HTTP headers and how tokens are typically passed in API requests

## Step 1: Install the New Dependencies {#step-1-install-dependencies}

This tutorial introduces two new packages to the project. Open your terminal inside the project folder, activate your virtual environment, and install them:

```bash
source .venv/bin/activate
pip install flask-jwt-extended python-dotenv
```

`flask-jwt-extended` is the library that handles everything JWT-related: creating tokens, verifying them on incoming requests, and managing the `@jwt_required()` decorator. `python-dotenv` reads key-value pairs from a `.env` file and loads them into the process environment, so you can keep sensitive values like the JWT secret key out of your source code entirely.

Save the updated dependency list:

```bash
pip freeze > requirements.txt
```

Next, create the `.env` file that will hold your secret key. The `JWT_SECRET_KEY` must be a long, random, unpredictable string. You can generate one directly in the terminal using Python's `secrets` module:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Copy the output, then create `.env` in your project root and paste it in:

```
JWT_SECRET_KEY=paste_your_generated_key_here
```

Now create a `.env.example` file that documents the required variable without exposing its actual value. This file is safe to commit to version control:

```
JWT_SECRET_KEY=your-secret-key-here
```

Finally, make sure the real `.env` file is never committed by adding it to `.gitignore`. If your project does not have a `.gitignore` yet, create one now:

```bash
echo ".env" >> .gitignore
```

Your project root should now contain these new files alongside the ones from Part 1:

```
flask-books-api/
├── .env
├── .env.example
├── .gitignore
├── app.py
├── database.py
├── schema.sql
├── requirements.txt
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── test_books.py
```

## Step 2: Add the Users Table {#step-2-add-users-table}

Authentication requires a place to store user credentials. Open `schema.sql` and add the `users` table below the existing `books` table definition:

```sql
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL
);

CREATE TABLE books (
    id     INTEGER PRIMARY KEY AUTOINCREMENT,
    title  TEXT    NOT NULL,
    author TEXT    NOT NULL,
    year   INTEGER NOT NULL
);
```

There are two important things to notice here. First, the column is named `password_hash`, not `password`. This naming is intentional: your database will never store a plain-text password. It will only ever store the output of a one-way hashing function, and the column name reflects that fact clearly. Second, the `username` column has a `UNIQUE` constraint, which prevents two users from registering with the same username at the database level, even if your application code has a bug.

The `DROP TABLE IF EXISTS users` line at the top also needs to appear before the books drop, because if you ever add a foreign key relationship between the tables, the dependent table must be dropped first. It is a good habit to order your drops in reverse dependency order.

Since the schema has changed, reinitialize the database so the new table is created. This will erase any existing book data you added while testing Part 1:

```bash
flask --app app init-db
```

Expected output:

```
Database initialized successfully.
```

## Step 3: Configure JWT in the App Factory {#step-3-configure-jwt}

Open `app.py`. You need to make four additions: import the new packages, load the `.env` file, add the JWT configuration to `app.config`, and initialize `JWTManager`. You also need to register custom error handlers so that JWT errors return JSON responses instead of Flask's default HTML error pages.

Below is the complete `app.py` after this step. The sections marked with `# [NEW]` are the additions; everything else is unchanged from Part 1:

```python
import os
import click
from dotenv import load_dotenv                  # [NEW]
from flask import Flask, jsonify, request, abort
from flask_jwt_extended import (                # [NEW]
    JWTManager,                                 # [NEW]
    create_access_token,                        # [NEW]
    get_jwt_identity,                           # [NEW]
    jwt_required,                               # [NEW]
)                                               # [NEW]
from database import get_db, close_db, init_db

# [NEW] load_dotenv() reads the .env file and injects its key-value pairs into
# the process environment before create_app() reads them via os.environ.
# Calling it at module level ensures the variables are available immediately
# when the application factory runs.
load_dotenv()


def create_app(test_config=None):
    app = Flask(__name__)

    app.config.from_mapping(
        DATABASE=os.path.join(app.instance_path, "books.db"),
        # [NEW] os.environ.get() reads JWT_SECRET_KEY from the environment,
        # which was populated by load_dotenv() above. The fallback value is
        # only used when running tests, where test_config overrides it anyway.
        JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "dev-only-secret"),
    )

    if test_config is not None:
        app.config.from_mapping(test_config)

    os.makedirs(app.instance_path, exist_ok=True)
    app.teardown_appcontext(close_db)

    # [NEW] Initialize JWTManager and bind it to the app. From this point on,
    # @jwt_required() will use this app's secret key to verify tokens.
    jwt = JWTManager(app)

    # ------------------------------------------------------------------
    # [NEW] JWT Error Handlers
    # ------------------------------------------------------------------

    @jwt.unauthorized_loader
    def missing_token_callback(reason):
        # Called when a protected route receives a request with no token.
        # Without this handler, Flask-JWT-Extended would return a default
        # response that may not match the JSON format the rest of our API uses.
        return jsonify({"error": "Authorization token is missing", "reason": reason}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(reason):
        # Called when a token is present but cannot be decoded or verified,
        # for example if it was tampered with or signed with a different key.
        return jsonify({"error": "Authorization token is invalid", "reason": reason}), 422

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        # Called when a valid token is presented but its expiry time has passed.
        return jsonify({"error": "Authorization token has expired"}), 401

    # ------------------------------------------------------------------
    # Routes (unchanged from Part 1)
    # ------------------------------------------------------------------

    @app.route("/books", methods=["GET"])
    def get_books():
        """Returns a JSON array of all books, ordered by id."""
        db = get_db()
        books = db.execute("SELECT * FROM books ORDER BY id").fetchall()
        return jsonify([dict(book) for book in books])

    @app.route("/books/<int:book_id>", methods=["GET"])
    def get_book(book_id):
        """Returns a single book, or a 404 error if the id does not exist."""
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        return jsonify(dict(book))

    @app.route("/books", methods=["POST"])
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
    # Error Handlers (unchanged from Part 1)
    # ------------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"error": "Method not allowed"}), 405

    # ------------------------------------------------------------------
    # CLI Commands (unchanged from Part 1)
    # ------------------------------------------------------------------

    @app.cli.command("init-db")
    def init_db_command():
        """Initializes the database by running schema.sql."""
        init_db()
        click.echo("Database initialized successfully.")

    return app


app = create_app()
```

You will add the auth routes and the `@jwt_required()` decorators in the next two steps.

## Step 4: Build the Auth Endpoints {#step-4-build-auth-endpoints}

Still inside `create_app`, add the two authentication routes between the JWT error handlers block and the book routes block. In the complete file shown in Step 3, the correct insertion point is right after the `expired_token_callback` function and before the `get_books` route.

```python
    # ------------------------------------------------------------------
    # Auth Routes
    # ------------------------------------------------------------------

    @app.route("/auth/register", methods=["POST"])
    def register():
        """
        Registers a new user.

        Expects a JSON body with 'username' and 'password'. The password
        is never stored as-is; generate_password_hash() runs it through
        a one-way function (pbkdf2:sha256 with a random salt by default)
        and returns a string we can safely write to the database.
        Returns the new user's id and username with a 201 Created status.
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

        # Check for an existing user before attempting the INSERT.
        # Although the UNIQUE constraint would also prevent duplicates,
        # catching it here gives us a cleaner, more specific error message.
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
        Authenticates a user and returns a JWT access token.

        check_password_hash() compares the plain-text password provided
        by the user against the stored hash without ever reversing the hash.
        If the credentials are valid, create_access_token() builds and signs
        a JWT whose 'sub' (subject) claim is set to the user's id as a string.
        Storing the id rather than the username means the token stays valid
        even if the user later changes their username.
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

        # Deliberately return the same error message whether the username
        # does not exist or the password is wrong. Separate messages would
        # tell an attacker which usernames are registered in your system.
        if user is None or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid username or password"}), 401

        # create_access_token() signs the token with JWT_SECRET_KEY.
        # The identity becomes the 'sub' claim inside the token payload.
        # We convert user["id"] to str because Flask-JWT-Extended 4.x
        # expects the identity to be a string-serializable value.
        access_token = create_access_token(identity=str(user["id"]))
        return jsonify({"access_token": access_token}), 200
```

## Step 5: Protect the Book Endpoints {#step-5-protect-book-endpoints}

The only change in this step is adding `@jwt_required()` immediately below the `@app.route(...)` line on `create_book`, `update_book`, and `delete_book`. The body of each function stays exactly as it was in Part 1.

Below is the complete and final `app.py` after all changes across Steps 3, 4, and 5. The `# [NEW]` markers highlight everything that was added in this tutorial compared to Part 1:

```python
import os
import click
from dotenv import load_dotenv                  # [NEW]
from flask import Flask, jsonify, request, abort
from flask_jwt_extended import (                # [NEW]
    JWTManager,                                 # [NEW]
    create_access_token,                        # [NEW]
    get_jwt_identity,                           # [NEW]
    jwt_required,                               # [NEW]
)                                               # [NEW]
from database import get_db, close_db, init_db

# [NEW] Reads the .env file and injects its key-value pairs into the process
# environment before create_app() reads them via os.environ.
load_dotenv()


def create_app(test_config=None):
    app = Flask(__name__)

    app.config.from_mapping(
        DATABASE=os.path.join(app.instance_path, "books.db"),
        JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "dev-only-secret"),  # [NEW]
    )

    if test_config is not None:
        app.config.from_mapping(test_config)

    os.makedirs(app.instance_path, exist_ok=True)
    app.teardown_appcontext(close_db)

    jwt = JWTManager(app)  # [NEW]

    # ------------------------------------------------------------------
    # [NEW] JWT Error Handlers
    # ------------------------------------------------------------------

    @jwt.unauthorized_loader                    # [NEW]
    def missing_token_callback(reason):         # [NEW]
        return jsonify({"error": "Authorization token is missing", "reason": reason}), 401

    @jwt.invalid_token_loader                   # [NEW]
    def invalid_token_callback(reason):         # [NEW]
        return jsonify({"error": "Authorization token is invalid", "reason": reason}), 422

    @jwt.expired_token_loader                   # [NEW]
    def expired_token_callback(jwt_header, jwt_payload):  # [NEW]
        return jsonify({"error": "Authorization token has expired"}), 401

    # ------------------------------------------------------------------
    # [NEW] Auth Routes
    # ------------------------------------------------------------------

    @app.route("/auth/register", methods=["POST"])
    def register():
        """
        Registers a new user.

        Expects a JSON body with 'username' and 'password'. The password
        is never stored as-is; generate_password_hash() runs it through
        a one-way function (pbkdf2:sha256 with a random salt by default)
        and returns a string we can safely write to the database.
        Returns the new user's id and username with a 201 Created status.
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

        # Check for an existing user before attempting the INSERT.
        # Although the UNIQUE constraint would also prevent duplicates,
        # catching it here gives us a cleaner, more specific error message.
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
        Authenticates a user and returns a JWT access token.

        check_password_hash() compares the plain-text password provided
        by the user against the stored hash without ever reversing the hash.
        If the credentials are valid, create_access_token() builds and signs
        a JWT whose 'sub' (subject) claim is set to the user's id as a string.
        Storing the id rather than the username means the token stays valid
        even if the user later changes their username.
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

        # Deliberately return the same error message whether the username
        # does not exist or the password is wrong. Separate messages would
        # tell an attacker which usernames are registered in your system.
        if user is None or not check_password_hash(user["password_hash"], password):
            return jsonify({"error": "Invalid username or password"}), 401

        # create_access_token() signs the token with JWT_SECRET_KEY.
        # The identity becomes the 'sub' claim inside the token payload.
        # We convert user["id"] to str because Flask-JWT-Extended 4.x
        # expects the identity to be a string-serializable value.
        access_token = create_access_token(identity=str(user["id"]))
        return jsonify({"access_token": access_token}), 200

    # ------------------------------------------------------------------
    # Book Routes
    # ------------------------------------------------------------------

    @app.route("/books", methods=["GET"])
    def get_books():
        """Returns a JSON array of all books, ordered by id."""
        db = get_db()
        books = db.execute("SELECT * FROM books ORDER BY id").fetchall()
        return jsonify([dict(book) for book in books])

    @app.route("/books/<int:book_id>", methods=["GET"])
    def get_book(book_id):
        """Returns a single book, or a 404 error if the id does not exist."""
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)
        return jsonify(dict(book))

    @app.route("/books", methods=["POST"])
    @jwt_required()                             # [NEW]
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
    @jwt_required()                             # [NEW]
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
    @jwt_required()                             # [NEW]
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
    # Error Handlers (unchanged from Part 1)
    # ------------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"error": "Method not allowed"}), 405

    # ------------------------------------------------------------------
    # CLI Commands (unchanged from Part 1)
    # ------------------------------------------------------------------

    @app.cli.command("init-db")
    def init_db_command():
        """Initializes the database by running schema.sql."""
        init_db()
        click.echo("Database initialized successfully.")

    return app


app = create_app()
```

The `GET /books` and `GET /books/<id>` endpoints intentionally receive no `@jwt_required()` decorator, which means they remain fully public. In this study case, reading the book catalog requires no authentication. In a real-world application, you would decide whether read access also requires a token based on your product requirements.

When Flask-JWT-Extended sees `@jwt_required()` on a route, it intercepts each incoming request before your function runs. It looks for an `Authorization` header in the format `Bearer <token>`, verifies the token's signature against `JWT_SECRET_KEY`, and checks that the token has not expired. If any of those checks fail, the request never reaches your function and one of the error handlers you registered in Step 3 sends the response instead.

## Step 6: Try It Out {#step-6-try-it-out}

Start the development server:

```bash
flask --app app run
```

### Register a New User

```bash
curl -s -X POST http://127.0.0.1:5000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "securepass123"}'
```

Expected response (status `201 Created`):

```json
{
  "id": 1,
  "username": "alice"
}
```

Notice the response contains `id` and `username` but not `password_hash`. The hash should never leave your server.

### Log In and Save the Token

```bash
curl -s -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "securepass123"}'
```

Expected response (status `200 OK`):

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6..."
}
```

Save the token to a shell variable so you do not have to paste it manually in every subsequent request:

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6..."
```

### Access a Protected Endpoint Without a Token

```bash
curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022}'
```

Expected response (status `401 Unauthorized`):

```json
{
  "error": "Authorization token is missing",
  "reason": "Missing Authorization Header"
}
```

### Access a Protected Endpoint With a Valid Token

```bash
curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
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

### Confirm Public Endpoints Still Work Without a Token

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

### Test an Invalid Login

```bash
curl -s -X POST http://127.0.0.1:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "wrongpassword"}'
```

Expected response (status `401 Unauthorized`):

```json
{
  "error": "Invalid username or password"
}
```

Press `CTRL+C` to stop the development server.

## Step 7: Update the Test Suite {#step-7-update-tests}

The existing tests from Part 1 will break because the `create_book`, `update_book`, and `delete_book` routes now require a token. You need to update those tests and add new ones for registration and login.

### Update conftest.py

Open `tests/conftest.py` and add two new fixtures after the existing ones. The `app` and `client` fixtures from Part 1 remain unchanged:

```python
import os
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
        # Use a fixed, predictable secret key in tests so tokens generated
        # during setup can be verified by the same app instance.
        "JWT_SECRET_KEY": "test-secret-key-for-jwt-auth-32bytes"
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
    """
    Registers a test user and returns their credentials as a dictionary.

    Other fixtures and tests that need an existing user can depend on
    this fixture instead of repeating the registration call themselves.
    """
    client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"},
    )
    return {"username": "testuser", "password": "testpass123"}


@pytest.fixture()
def auth_headers(client, registered_user):
    """
    Logs in with the registered test user and returns a dictionary
    containing the Authorization header ready for use in test requests.

    Any test that calls a protected endpoint can add
    `headers=auth_headers` to the request and the token will be included
    automatically, keeping the test body focused on what is being tested.
    """
    response = client.post("/auth/login", json=registered_user)
    token = response.get_json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
```

### Update test_books.py

The tests that write data need `headers=auth_headers` added to each request. The read tests require no changes. Here is the complete updated `tests/test_books.py`:

```python
import json


# ------------------------------------------------------------------
# Auth Tests
# ------------------------------------------------------------------

def test_register_returns_201(client):
    """POST /auth/register with valid data should create a user and return 201."""
    response = client.post(
        "/auth/register",
        json={"username": "alice", "password": "securepass123"},
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["username"] == "alice"
    assert "id" in data
    # The password hash must never be included in the response.
    assert "password_hash" not in data


def test_register_rejects_duplicate_username(client):
    """Registering the same username twice should return 409 Conflict."""
    client.post("/auth/register", json={"username": "alice", "password": "pass12345"})
    response = client.post(
        "/auth/register",
        json={"username": "alice", "password": "different123"},
    )
    assert response.status_code == 409


def test_register_validates_missing_fields(client):
    """POST /auth/register with missing fields should return 422 with error details."""
    response = client.post("/auth/register", json={"username": "alice"})
    assert response.status_code == 422
    assert "password" in response.get_json()["errors"]


def test_login_returns_access_token(client, registered_user):
    """POST /auth/login with correct credentials should return an access token."""
    response = client.post("/auth/login", json=registered_user)
    assert response.status_code == 200
    assert "access_token" in response.get_json()


def test_login_rejects_wrong_password(client, registered_user):
    """POST /auth/login with an incorrect password should return 401."""
    response = client.post(
        "/auth/login",
        json={"username": registered_user["username"], "password": "wrongpassword"},
    )
    assert response.status_code == 401


# ------------------------------------------------------------------
# Book Tests (read endpoints - unchanged from Part 1)
# ------------------------------------------------------------------

def test_get_books_returns_empty_list(client):
    """GET /books on a fresh database should return an empty JSON array."""
    response = client.get("/books")
    assert response.status_code == 200
    assert response.get_json() == []


def test_get_book_returns_404_for_unknown_id(client):
    """GET /books/<id> with a non-existent id should return a 404 JSON response."""
    response = client.get("/books/999")
    assert response.status_code == 404
    assert "error" in response.get_json()


# ------------------------------------------------------------------
# Book Tests (write endpoints - now require auth_headers)
# ------------------------------------------------------------------

def test_create_book_without_token_returns_401(client):
    """POST /books with no Authorization header should return 401."""
    response = client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
    )
    assert response.status_code == 401


def test_create_book_returns_201(client, auth_headers):
    """POST /books with a valid token and valid data should return the created book."""
    response = client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["title"] == "Fluent Python"
    assert "id" in data


def test_create_book_validates_missing_fields(client, auth_headers):
    """POST /books with missing fields should return 422 even with a valid token."""
    response = client.post(
        "/books",
        json={"title": "Incomplete Book"},
        headers=auth_headers,
    )
    assert response.status_code == 422
    errors = response.get_json()["errors"]
    assert "author" in errors
    assert "year" in errors


def test_get_single_book(client, auth_headers):
    """GET /books/<id> should return the book matching the given id."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    response = client.get("/books/1")
    assert response.status_code == 200
    assert response.get_json()["title"] == "Fluent Python"


def test_update_book_without_token_returns_401(client, auth_headers):
    """PUT /books/<id> with no Authorization header should return 401."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    response = client.put("/books/1", json={"year": 2023})
    assert response.status_code == 401


def test_update_book_changes_only_sent_fields(client, auth_headers):
    """PUT /books/<id> with partial data should update only the fields that were sent."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    response = client.put(
        "/books/1",
        json={"year": 2023},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["year"] == 2023
    assert data["title"] == "Fluent Python"
    assert data["author"] == "Luciano Ramalho"


def test_delete_book(client, auth_headers):
    """DELETE /books/<id> should remove the book and confirm deletion."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    response = client.delete("/books/1", headers=auth_headers)
    assert response.status_code == 200
    assert "message" in response.get_json()

    follow_up = client.get("/books/1")
    assert follow_up.status_code == 404


def test_delete_book_without_token_returns_401(client, auth_headers):
    """DELETE /books/<id> with no Authorization header should return 401."""
    client.post(
        "/books",
        json={"title": "Fluent Python", "author": "Luciano Ramalho", "year": 2022},
        headers=auth_headers,
    )
    response = client.delete("/books/1")
    assert response.status_code == 401
```

Run the full test suite:

```bash
pytest tests/ -v
```

Expected output:

```
============================= test session starts ==============================
platform linux -- Python 3.14.3, pytest-8.3.5, pluggy-1.5.0
rootdir: /path/to/flask-books-api
collected 15 items                                                             

tests/test_books.py::test_register_returns_201 PASSED                    [  6%]
tests/test_books.py::test_register_rejects_duplicate_username PASSED     [ 13%]
tests/test_books.py::test_register_validates_missing_fields PASSED       [ 20%]
tests/test_books.py::test_login_returns_access_token PASSED              [ 26%]
tests/test_books.py::test_login_rejects_wrong_password PASSED            [ 33%]
tests/test_books.py::test_get_books_returns_empty_list PASSED            [ 40%]
tests/test_books.py::test_get_book_returns_404_for_unknown_id PASSED     [ 46%]
tests/test_books.py::test_create_book_without_token_returns_401 PASSED   [ 53%]
tests/test_books.py::test_create_book_returns_201 PASSED                 [ 60%]
tests/test_books.py::test_create_book_validates_missing_fields PASSED    [ 66%]
tests/test_books.py::test_get_single_book PASSED                         [ 73%]
tests/test_books.py::test_update_book_without_token_returns_401 PASSED   [ 80%]
tests/test_books.py::test_update_book_changes_only_sent_fields PASSED    [ 86%]
tests/test_books.py::test_delete_book PASSED                             [ 93%]
tests/test_books.py::test_delete_book_without_token_returns_401 PASSED   [100%]

============================== 15 passed in 1.59s ==============================

```

All 15 tests pass.

The original tests from Part 1 still work as expected, and the new authentication tests verify registration, login, token protection, and access control for protected endpoints.

## How JWT Authentication Works {#how-jwt-works}

Understanding the mechanics behind JWT will help you make better decisions about when to use it, how to configure it, and what its limitations are.

### The Anatomy of a JWT

A JSON Web Token is a string made of three base64url-encoded sections separated by dots: a header, a payload, and a signature. If you decode the header and payload sections of any token your API issues, you will see something like this:

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "fresh": false,
  "iat": 1716300000,
  "jti": "a1b2c3d4-...",
  "type": "access",
  "sub": "1",
  "nbf": 1716300000,
  "exp": 1716300900
}
```

The `sub` (subject) claim holds the user identity you passed to `create_access_token()`, which in this tutorial is the user's id. The `exp` claim is a Unix timestamp indicating when the token expires. Flask-JWT-Extended sets a default expiration of 15 minutes, which you can change by setting `JWT_ACCESS_TOKEN_EXPIRES` in your app config. The `jti` is a unique identifier for this specific token instance.

### Why JWT Is Stateless

In a traditional session-based system, the server stores a session record for every logged-in user. On each request, the client sends a session id, and the server queries its session store to look up who that id belongs to. JWT flips this model: the server stores nothing. The token itself contains all the claims about the user, and those claims are protected by a cryptographic signature rather than a server-side lookup.

When `@jwt_required()` intercepts a request, it takes the token from the `Authorization` header, recomputes the HMAC-SHA256 signature using `JWT_SECRET_KEY`, and compares it against the signature in the token. If they match, the payload has not been tampered with and the claims inside can be trusted. The server never needs to open a database to verify the token.

This is what makes JWT well-suited for APIs, especially ones that may run across multiple server instances: any instance that knows the secret key can verify any token, with no shared session storage required.

### What Happens If the Secret Key Is Compromised

If an attacker obtains your `JWT_SECRET_KEY`, they can sign arbitrary tokens and impersonate any user. This is why the key must be loaded from an environment variable rather than hardcoded in source code, why it must be long and random, and why it must never be committed to version control. If you suspect a key has been exposed, rotating it (changing it to a new value) immediately invalidates all outstanding tokens, which is a useful incident response tool.

### A Note on Logout

JWT's stateless nature creates a genuine challenge for logout. Since the server does not store tokens, there is no server-side record to delete when a user logs out. The standard client-side approach is to delete the token from wherever the client stored it (memory, local storage, or a cookie), which prevents that client from including it in future requests. The token will still be valid on the server until its `exp` time passes, but a well-behaved client will simply not send it.

For many applications, this is an acceptable trade-off. If your application requires true server-side revocation, for example because users can log out and you want the token to be dead immediately, you need to maintain a token blacklist. The typical production approach stores the `jti` claim of revoked tokens in a fast store like Redis. The next tutorial in this series will cover that pattern.

## Conclusion {#conclusion}

You have added a complete JWT authentication layer to the Flask Books API without replacing any of the tools from Part 1. Here are the key ideas to carry forward:

- **Secrets belong in environment variables.** Loading `JWT_SECRET_KEY` from a `.env` file via `python-dotenv` keeps it out of source code, makes rotation easy, and lets different environments (development, staging, production) use different keys without any code changes.
- **Passwords must always be hashed.** `werkzeug.security.generate_password_hash()` applies a salted one-way function before storage. `check_password_hash()` verifies a plain-text input against the stored hash without ever reversing it. These two functions are already available in every Flask project with no additional installation.
- **Return the same error for bad username and bad password.** Distinguishing between the two tells an attacker which usernames are registered. A single generic "Invalid username or password" message removes that information leak.
- **`@jwt_required()` is an interceptor, not a guard inside your function.** Flask-JWT-Extended verifies the token before your route function runs. If verification fails, the custom error handlers you registered take over and your function never executes.
- **The `auth_headers` fixture keeps tests readable.** Centralizing the login flow in a single Pytest fixture means that every test that needs authentication can add `headers=auth_headers` to a request without duplicating register-and-login logic across the test file.
- **JWT logout is client-side by default.** Deleting the token on the client prevents it from being sent in future requests. True server-side revocation requires a blacklist, which will be the focus of the next tutorial in this series.