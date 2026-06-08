---
title: "Building a CRUD REST API with Flask and SQLite"
slug: "building-a-crud-rest-api-with-flask-and-sqlite"
category: "Python"
date: "2026-04-26"
status: "published"
---

Many Python developers hit the same wall when they want to build their first REST API. They search for a tutorial, and the first result tells them to install five packages before writing a single line of application code. An ORM, a migration tool, a serializer, a validation library, and then Flask itself. The complexity is front-loaded, and it obscures something important: a fully functional CRUD API needs very few moving parts. Flask gives you a routing layer, request parsing, and response building. SQLite is already part of Python's standard library. That is genuinely everything you need to get started.

In this tutorial, you will build a REST API for managing a book collection from scratch, using only Flask and sqlite3. By the end, you will have five working endpoints, structured error handling, and a complete automated test suite powered by Pytest.

## Overview {#overview}

This tutorial walks you through building a REST API step by step, starting from an empty folder and ending with a tested, running server. The approach is intentionally minimal: every piece of code you write has a clear, direct purpose, so you can understand the full picture before adding more complexity in future tutorials.

### What You'll Build

- A RESTful CRUD API for a `books` resource, with endpoints for listing all books, retrieving a single book, creating, updating, and deleting records, all stored in a local SQLite database.

### What You'll Learn

- How to structure a Flask project using the application factory pattern
- How Flask's `g` object and `current_app` manage per-request database connections
- How to execute raw SQL with sqlite3 and return results as JSON
- How to validate incoming request data and return structured error responses
- How to register a Flask CLI command for one-time setup tasks
- How to write a complete Pytest test suite for a Flask API using temporary databases

### What You'll Need

- Python 3.10 or higher (the tutorial was verified on Python 3.14.3)
- `pip` for installing packages; on Debian and Ubuntu, use `python3` and `pip3` instead of `python` and `pip`
- `curl` or Postman for manually testing endpoints
- Familiarity with Python fundamentals: functions, dictionaries, and modules

## Step 1: Project Setup {#step-1-project-setup}

Before writing any Flask code, you need a clean project folder with a virtual environment. A virtual environment isolates your project's dependencies from other Python projects on your machine, so different projects can use different versions of the same package without conflicts.

On Debian and Ubuntu systems, the Python executable is named `python3`, not `python`. Running `python` without the `3` suffix will result in a "command not found" error unless you have separately installed the `python-is-python3` package. All commands in this tutorial use `python3` explicitly so they work correctly on any Linux distribution.

Open your terminal and run the following commands:

```bash
mkdir flask-books-api
cd flask-books-api
python3 -m venv .venv
```

Now activate the virtual environment. On macOS and Linux:

```bash
source .venv/bin/activate
```

On Windows:

```bash
.venv\Scripts\activate
```

Once activated, your terminal prompt will show the environment name. Now install the two packages you need for this tutorial:

```bash
pip install flask pytest
```

Flask is the only external dependency for the API itself. Pytest handles the automated tests. When the installation finishes, create the project files you will fill in during the next steps:

```bash
touch app.py database.py schema.sql requirements.txt
mkdir tests
touch tests/__init__.py tests/conftest.py tests/test_books.py
```

Save the current dependencies to `requirements.txt` so anyone cloning the project can install them with one command:

```bash
pip freeze > requirements.txt
```

Your project structure now looks like this:

```
flask-books-api/
├── app.py
├── database.py
├── schema.sql
├── requirements.txt
└── tests/
    ├── __init__.py
    ├── conftest.py
    └── test_books.py
```

## Step 2: Define the Database Schema {#step-2-define-the-database-schema}

The `books` table is straightforward: a primary key that SQLite manages automatically, a title, an author, and a publication year. Open `schema.sql` and write the following:

```sql
DROP TABLE IF EXISTS books;

CREATE TABLE books (
    id     INTEGER PRIMARY KEY AUTOINCREMENT,
    title  TEXT    NOT NULL,
    author TEXT    NOT NULL,
    year   INTEGER NOT NULL
);
```

The `DROP TABLE IF EXISTS` line means you can safely re-run this file to reset the database during development without getting an error if the table already exists. `AUTOINCREMENT` tells SQLite to assign a new, never-reused integer to each row's `id`, even if rows were previously deleted. The `NOT NULL` constraints enforce that every book must have a title, author, and year at the database level, even though you will also validate these fields in Python before any data reaches the database.

## Step 3: Create the Database Helper {#step-3-create-the-database-helper}

Open `database.py`. This file contains three small functions that handle the complete lifecycle of a database connection: opening it, closing it, and setting up the initial schema.

```python
import sqlite3
from flask import g, current_app


def get_db():
    """
    Returns the database connection for the current request.

    Flask's 'g' object is a special namespace that stores data during
    a single application context, which corresponds to one HTTP request.
    If a connection already exists in g, we reuse it; otherwise, we open
    a new one. This guarantees we never open more than one connection
    per request, no matter how many times get_db() is called.
    """
    if "db" not in g:
        g.db = sqlite3.connect(
            # current_app points to the Flask app handling this request.
            # DATABASE holds the path to the .db file, which we define
            # in app.py. Using the config makes it easy to swap the path
            # during testing without touching this file.
            current_app.config["DATABASE"],
            detect_types=sqlite3.PARSE_DECLTYPES,
        )
        # With row_factory set to sqlite3.Row, query results behave like
        # dictionaries. This lets us write row["title"] instead of row[1],
        # which is much more readable and less error-prone.
        g.db.row_factory = sqlite3.Row

    return g.db


def close_db(e=None):
    """
    Closes the database connection at the end of the application context.

    Flask calls this function automatically because we register it with
    app.teardown_appcontext() inside create_app(). The e parameter is
    the exception that caused the teardown, if any; we can safely ignore it.
    """
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    """
    Reads schema.sql and executes it against the current database.

    current_app.open_resource() opens a file relative to the folder where
    app.py lives, so schema.sql must sit in the same directory as app.py.
    """
    db = get_db()
    with current_app.open_resource("schema.sql") as f:
        db.executescript(f.read().decode("utf8"))
```

The three functions form a complete lifecycle: `get_db` opens or reuses a connection, `close_db` closes it when the request ends, and `init_db` executes the schema. Flask's `g` object is the key mechanism here. It is not a traditional global variable; it exists only for the duration of a single application context. Each HTTP request gets a fresh `g`, so database connections are always isolated between requests.

## Step 4: Build the Flask Application {#step-4-build-the-flask-application}

Open `app.py`. This file does three things: it defines a `create_app` factory function that builds and configures the Flask application, it registers all five API routes as inner functions, and it exposes a CLI command for initializing the database.

```python
import os
import click
from flask import Flask, jsonify, request, abort
from database import get_db, close_db, init_db


def create_app(test_config=None):
    """
    Application factory function.

    Creating the app inside a function instead of at module level means
    you can call create_app() multiple times with different configurations.
    This is the standard Flask pattern for making applications testable,
    because tests can call create_app(test_config={...}) to get a fresh
    instance pointing at a temporary database.
    """
    app = Flask(__name__)

    # Default configuration stores books.db inside Flask's 'instance' folder.
    # The instance folder sits outside the source tree and is not committed
    # to version control. It is the right place for generated files like
    # database files and secret keys.
    app.config.from_mapping(
        DATABASE=os.path.join(app.instance_path, "books.db"),
    )

    # If test_config is passed (e.g., from conftest.py), override the defaults.
    if test_config is not None:
        app.config.from_mapping(test_config)

    # Ensure the instance folder exists before Flask tries to write the db file.
    os.makedirs(app.instance_path, exist_ok=True)

    # Register close_db so Flask calls it automatically at the end of every
    # request, regardless of whether the request succeeded or raised an error.
    app.teardown_appcontext(close_db)

    # ------------------------------------------------------------------
    # Routes
    # ------------------------------------------------------------------

    @app.route("/books", methods=["GET"])
    def get_books():
        """Returns a JSON array of all books, ordered by id."""
        db = get_db()
        books = db.execute("SELECT * FROM books ORDER BY id").fetchall()
        # dict(book) converts a sqlite3.Row object into a plain Python
        # dictionary, which jsonify() can serialize to a JSON string.
        return jsonify([dict(book) for book in books])

    @app.route("/books/<int:book_id>", methods=["GET"])
    def get_book(book_id):
        """Returns a single book, or a 404 error if the id does not exist."""
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            # abort() raises an HTTP exception. Our registered error handler
            # below catches it and returns a JSON response instead of HTML.
            abort(404)
        return jsonify(dict(book))

    @app.route("/books", methods=["POST"])
    def create_book():
        """
        Creates a new book.

        Expects a JSON body with 'title', 'author', and 'year'. Returns the
        created book object with its assigned id and a 201 Created status code.
        All validation errors are collected and returned together in a single
        response, so the client does not have to fix one problem at a time.
        """
        data = request.get_json()

        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        # Extract and sanitize input values.
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
        # The ? placeholders and the values tuple are the correct way to
        # pass user data into SQL. Never use Python string formatting here;
        # that would open the door to SQL injection attacks.
        cursor = db.execute(
            "INSERT INTO books (title, author, year) VALUES (?, ?, ?)",
            (title, author, year),
        )
        db.commit()

        # cursor.lastrowid holds the id SQLite assigned to the row we just
        # inserted. We use it to fetch and return the complete new record.
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (cursor.lastrowid,)
        ).fetchone()
        return jsonify(dict(book)), 201

    @app.route("/books/<int:book_id>", methods=["PUT"])
    def update_book(book_id):
        """
        Updates an existing book.

        Only the fields present in the request body are changed. Any field
        omitted from the request body keeps its current database value.
        Returns the complete updated book object.
        """
        db = get_db()
        book = db.execute(
            "SELECT * FROM books WHERE id = ?", (book_id,)
        ).fetchone()
        if book is None:
            abort(404)

        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body must be JSON"}), 400

        # Fall back to the current database value for any field not in the request.
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
        """Deletes a book by id and returns a confirmation message."""
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
    # Error Handlers
    # ------------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        # Without custom error handlers, Flask returns HTML error pages.
        # API clients expect JSON, so we intercept these errors here.
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

    return app


# Create the default app instance so Flask's CLI and direct execution
# can discover the application without any extra configuration.
app = create_app()
```

The `create_app` function is the central idea in this file. It is called the application factory pattern, and it means the app object is not created when the module is imported; it is created when `create_app()` is explicitly called. This distinction matters because it lets tests call `create_app(test_config={...})` to get a completely fresh app instance with a different database path, separate from the main application. You will see this in action in Step 6.

## Step 5: Try It Out {#step-5-try-it-out}

Before writing tests, run the API manually to confirm everything is wired up correctly. Start by initializing the database with the CLI command you registered in `app.py`:

```bash
flask --app app init-db
```

Expected output:

```
Database initialized successfully.
```

This created an `instance/` folder in your project root containing `books.db`. Now start the development server:

```bash
flask --app app run
```

Expected output:

```
 * Serving Flask app 'app'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:5000
Press CTRL+C to quit
```

Open a second terminal window and test each endpoint with `curl`.

### Create a Book

```bash
curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
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

Add a second book so the list endpoint has something interesting to return:

```bash
curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Python Crash Course", "author": "Eric Matthes", "year": 2023}'
```

### List All Books

```bash
curl -s http://127.0.0.1:5000/books
```

Expected response:

```json
[
  {
    "author": "Luciano Ramalho",
    "id": 1,
    "title": "Fluent Python",
    "year": 2022
  },
  {
    "author": "Eric Matthes",
    "id": 2,
    "title": "Python Crash Course",
    "year": 2023
  }
]
```

### Get a Single Book

```bash
curl -s http://127.0.0.1:5000/books/1
```

Expected response:

```json
{
  "author": "Luciano Ramalho",
  "id": 1,
  "title": "Fluent Python",
  "year": 2022
}
```

### Update a Book

```bash
curl -s -X PUT http://127.0.0.1:5000/books/1 \
  -H "Content-Type: application/json" \
  -d '{"year": 2023}'
```

Expected response:

```json
{
  "author": "Luciano Ramalho",
  "id": 1,
  "title": "Fluent Python",
  "year": 2023
}
```

Notice that only `year` changed. The `title` and `author` fields kept their original values because the update route falls back to the current database value for any field not included in the request body.

### Delete a Book

```bash
curl -s -X DELETE http://127.0.0.1:5000/books/1
```

Expected response:

```json
{
  "message": "Book 1 deleted successfully"
}
```

### Test Validation and 404 Handling

Try creating a book with missing fields to verify that validation works:

```bash
curl -s -X POST http://127.0.0.1:5000/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Incomplete Book"}'
```

Expected response (status `422 Unprocessable Entity`):

```json
{
  "errors": {
    "author": "Author is required",
    "year": "Year is required"
  }
}
```

Try fetching a book with an id that does not exist:

```bash
curl -s http://127.0.0.1:5000/books/999
```

Expected response (status `404`):

```json
{
  "error": "Resource not found"
}
```

Everything works as expected. Press `CTRL+C` to stop the development server.

## Step 6: Write the Tests with Pytest {#step-6-write-the-tests-with-pytest}

Manual testing with `curl` confirms the happy paths, but it does not protect you from regressions when you change code later. A Pytest suite automates this verification and runs in seconds. Open `tests/conftest.py` and write the two fixtures that every test will depend on:

```python
import os
import tempfile
import pytest
from app import create_app
from database import init_db


@pytest.fixture()
def app():
    """
    Creates a Flask app instance configured for testing.

    We use tempfile.mkstemp() to create a real temporary file on disk
    rather than an in-memory SQLite database. The reason: sqlite3 creates
    a brand new, empty database for every connection it opens to ':memory:'.
    Since Flask opens a fresh connection for each incoming request, an
    in-memory database would be empty again by the time the second request
    in a single test runs. A temp file on disk persists across all the
    requests a single test makes, then gets cleaned up afterward.
    """
    db_fd, db_path = tempfile.mkstemp()

    app = create_app(test_config={
        "TESTING": True,
        "DATABASE": db_path,
    })

    with app.app_context():
        init_db()

    yield app

    # Cleanup: close the OS-level file descriptor and delete the temp file
    # after each test finishes, so tests never share state with each other.
    os.close(db_fd)
    os.unlink(db_path)


@pytest.fixture()
def client(app):
    """
    Returns a Flask test client bound to the test app.

    The test client lets us make HTTP requests to the application without
    starting a real server. It behaves exactly like requests from curl or
    a browser, but runs entirely in memory during the test process.
    """
    return app.test_client()
```

Now open `tests/test_books.py`. Each test function receives the `client` fixture automatically through Pytest's dependency injection. When Pytest sees that a test function has a parameter named `client`, it calls the `client` fixture from `conftest.py`, which in turn calls the `app` fixture, giving every test a fresh database and a ready-to-use HTTP client.

```python
import json


def test_get_books_returns_empty_list(client):
    """GET /books on a fresh database should return an empty JSON array."""
    response = client.get("/books")
    assert response.status_code == 200
    assert response.get_json() == []


def test_create_book_returns_201(client):
    """POST /books with valid data should return the created book with its new id."""
    response = client.post(
        "/books",
        data=json.dumps({
            "title": "Fluent Python",
            "author": "Luciano Ramalho",
            "year": 2022,
        }),
        content_type="application/json",
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["title"] == "Fluent Python"
    assert data["author"] == "Luciano Ramalho"
    assert data["year"] == 2022
    # The API should have assigned an id automatically.
    assert "id" in data


def test_create_book_validates_missing_fields(client):
    """POST /books with missing fields should return 422 with error details for each field."""
    response = client.post(
        "/books",
        data=json.dumps({"title": "Incomplete Book"}),
        content_type="application/json",
    )
    assert response.status_code == 422
    errors = response.get_json()["errors"]
    # Both missing fields should appear in a single response.
    assert "author" in errors
    assert "year" in errors


def test_get_single_book(client):
    """GET /books/<id> should return the book matching the given id."""
    client.post(
        "/books",
        data=json.dumps({
            "title": "Fluent Python",
            "author": "Luciano Ramalho",
            "year": 2022,
        }),
        content_type="application/json",
    )
    response = client.get("/books/1")
    assert response.status_code == 200
    assert response.get_json()["title"] == "Fluent Python"


def test_get_book_returns_404_for_unknown_id(client):
    """GET /books/<id> with a non-existent id should return a 404 JSON response."""
    response = client.get("/books/999")
    assert response.status_code == 404
    assert "error" in response.get_json()


def test_update_book_changes_only_sent_fields(client):
    """PUT /books/<id> with partial data should update only the fields that were sent."""
    client.post(
        "/books",
        data=json.dumps({
            "title": "Fluent Python",
            "author": "Luciano Ramalho",
            "year": 2022,
        }),
        content_type="application/json",
    )
    response = client.put(
        "/books/1",
        data=json.dumps({"year": 2023}),
        content_type="application/json",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["year"] == 2023
    # Fields not included in the request should remain unchanged.
    assert data["title"] == "Fluent Python"
    assert data["author"] == "Luciano Ramalho"


def test_update_book_returns_404_for_unknown_id(client):
    """PUT /books/<id> with a non-existent id should return 404."""
    response = client.put(
        "/books/999",
        data=json.dumps({"title": "Ghost Book"}),
        content_type="application/json",
    )
    assert response.status_code == 404


def test_delete_book(client):
    """DELETE /books/<id> should remove the book and confirm deletion."""
    client.post(
        "/books",
        data=json.dumps({
            "title": "Fluent Python",
            "author": "Luciano Ramalho",
            "year": 2022,
        }),
        content_type="application/json",
    )
    response = client.delete("/books/1")
    assert response.status_code == 200
    assert "message" in response.get_json()

    # Confirm the book is actually gone by trying to fetch it.
    follow_up = client.get("/books/1")
    assert follow_up.status_code == 404


def test_delete_book_returns_404_for_unknown_id(client):
    """DELETE /books/<id> with a non-existent id should return 404."""
    response = client.delete("/books/999")
    assert response.status_code == 404
```

Run the full test suite from the project root:

```bash
pytest tests/ -v
```

Expected output:

```
============================= test session starts ==============================
platform darwin -- Python 3.12.3, pytest-8.3.5, pluggy-1.5.0
rootdir: /path/to/flask-books-api
collected 9 items

tests/test_books.py::test_get_books_returns_empty_list PASSED           [ 11%]
tests/test_books.py::test_create_book_returns_201 PASSED                [ 22%]
tests/test_books.py::test_create_book_validates_missing_fields PASSED   [ 33%]
tests/test_books.py::test_get_single_book PASSED                        [ 44%]
tests/test_books.py::test_get_book_returns_404_for_unknown_id PASSED    [ 55%]
tests/test_books.py::test_update_book_changes_only_sent_fields PASSED   [ 66%]
tests/test_books.py::test_update_book_returns_404_for_unknown_id PASSED [ 77%]
tests/test_books.py::test_delete_book PASSED                            [ 88%]
tests/test_books.py::test_delete_book_returns_404_for_unknown_id PASSED [100%]

============================== 9 passed in 0.42s ===============================
```

All 9 tests pass. Because each test gets its own isolated temporary database, tests never share state or interfere with each other, regardless of the order Pytest runs them.

## How Flask Handles Requests Under the Hood {#how-flask-handles-requests}

Understanding what happens between a `curl` command leaving your terminal and a JSON response arriving back will help you debug issues and extend the API with confidence. There are three mechanisms worth understanding in depth: the request context, the `g` object, and `jsonify`.

### The Request Context and Context-Local Objects

When Flask receives an HTTP request, it creates a **request context** for that specific request. This is what makes `request` and `g` appear to work like simple module-level globals, even though Flask can technically handle multiple requests concurrently. In reality, `request` and `g` are **context-local** objects. Behind the scenes, Flask maintains a stack of active contexts. Each request gets its own entry on the stack, and when you access `request.get_json()`, Flask looks up the context for the current request and reads its data, not the data for any other request happening at the same time.

This design gives you the ergonomics of a global variable (no passing `request` through every function call) without the correctness problems of a true global (no data leaking between requests).

### The g Object and Connection Reuse

`g` is a blank namespace that lives and dies with the application context, which in a normal web request maps to a single request-response cycle. The pattern in `get_db()` uses `g` to cache the database connection: the first call within a request opens a connection and stores it in `g.db`; every subsequent call within the same request returns the cached connection. When the request ends, Flask tears down the application context and calls every function registered with `app.teardown_appcontext`, including `close_db`, which removes the connection from `g` and closes it.

This matters for correctness: opening a new database connection for every SQL query in a single request would be wasteful and could cause subtle consistency problems. The `g` pattern ensures that all queries within one request share one connection and, by extension, one transaction.

### jsonify and Status Codes

`jsonify()` takes a Python dictionary or list, serializes it to a JSON string, and wraps it in a Flask `Response` object with the `Content-Type: application/json` header already set. When you write `return jsonify(dict(book))`, Flask sends that response with a default `200 OK` status. To send a different status code, return a tuple where the second element is the integer status: `return jsonify({...}), 201`. This is why the create endpoint returns `201 Created` while the read endpoints return `200 OK`.

### abort() and Error Handlers

`abort(404)` raises an `HTTPException` with a 404 status code. Without a custom error handler, Flask would respond with an HTML 404 page, which is useless for an API client expecting JSON. The `@app.errorhandler(404)` decorator registers a function that intercepts every `abort(404)` raised anywhere in the application and returns a JSON error response instead. This separation is clean: route handlers focus on the happy path and call `abort()` when something is wrong; the error handler in one place decides how errors are formatted for the client.

## Conclusion {#conclusion}

You have built a complete REST API from an empty folder using only Flask and Python's built-in sqlite3 library. Here are the key ideas to take away from this tutorial:

- **Application factory pattern.** Wrapping app creation inside `create_app()` means you can instantiate separate app objects with different configurations. Tests get their own app pointing at a temporary database, while production uses the real one, all from the same codebase.
- **Flask's `g` object manages per-request state.** Storing the database connection in `g` ensures you never accidentally share a connection between requests, and Flask closes it automatically when each request ends.
- **`sqlite3.Row` makes column access readable.** Setting `conn.row_factory = sqlite3.Row` lets you access query results by column name rather than numeric index. A single call to `dict(row)` converts the result to a JSON-serializable Python dictionary.
- **Collect all validation errors before responding.** Checking every required field and returning all problems at once gives API clients the full picture in a single response, instead of forcing them to fix one issue, resubmit, discover the next issue, and repeat.
- **Parameterized queries prevent SQL injection.** Every SQL statement in this tutorial uses `?` placeholders and passes values as a separate tuple. Never build SQL strings with Python string formatting or f-strings using user-supplied data.
- **Temporary files make API tests reliable.** Using `tempfile.mkstemp()` in test fixtures creates a real database file that persists across all the requests a single test makes, then gets deleted after the test finishes. This avoids the pitfall of in-memory SQLite databases disappearing between requests.

The next tutorial in this series will add JWT-based authentication to these endpoints, so only registered users can create, update, and delete books.