# Build a Searchable Knowledge Base with Python and SQLite, Without AI

A team's documentation can grow faster than its ability to find answers. Deployment instructions, troubleshooting notes, and internal policies end up scattered across Markdown files, turning a simple lookup into a manual search. A small Python application can make those documents searchable and return relevant passages with their sources, using Flask and SQLite full-text search.

The application in this tutorial borrows the document ingestion, chunking, and retrieval stages commonly used in retrieval-augmented generation (RAG). It stops at retrieval: the browser displays original passages and links to their source documents. There are no embeddings, language models, external AI services, or generated answers.

## Overview {#overview}

The project is a local knowledge base for a small collection of Markdown documents. Python reads those files, SQLite stores a searchable snapshot, and Flask provides a browser interface. The examples use a fictional team's operations documentation so that every search can be traced back to text included in this tutorial.

### What You'll Build

- A command that indexes Markdown files from a `knowledge/` directory.
- A search page that returns up to ten relevant passages with document titles, filenames, and line ranges.
- A source page that displays the indexed document and lets a search result link directly to its starting line.
- A repeatable indexing workflow for adding, editing, and removing documents.

### What You'll Learn

- Split documents into passages while retaining source locations.
- Store source documents and passages in SQLite.
- Translate ordinary search text into a controlled FTS5 query.
- Rank matching passages with BM25 and display their original text.
- Explain where lexical retrieval differs from semantic retrieval and answer generation.

### What You'll Need

- Python 3.12 or later, with `venv` and `pip` available.
- A Python SQLite build with FTS5 enabled. Step 1 includes a compatibility check.
- Basic familiarity with Python functions, SQL, and HTML.
- A terminal, text editor, and browser.
- Internet access to install Flask. Searching the sample knowledge base then runs locally.

No previous QadrLabs tutorial is required. The commands use a POSIX shell on Linux or macOS; Windows PowerShell activation is shown separately. This is a local application, with no login, file upload, or production deployment setup.

## Step 1: Set Up the Project {#step-1-set-up-the-project}

Start with a dedicated directory. The only third-party Python dependency is Flask; document processing and database access use the standard library.

```bash
mkdir python-knowledge-base
cd python-knowledge-base
python3 -m venv .venv
source .venv/bin/activate
```

These commands create and activate an isolated environment. On Windows PowerShell, use `py -3 -m venv .venv` to create it and `.venv\Scripts\Activate.ps1` to activate it. Use Python 3.12 or later for that environment.

Create `requirements.txt` with the following content, then save it:

```text
Flask>=3.1,<3.2
```

This keeps the example on the Flask 3.1 release line while allowing patch updates. Install it and check the active Python version:

```bash
python -m pip install -r requirements.txt
python --version
```

The installation should complete successfully, and the version command should report Python 3.12 or later. Package installation messages vary by platform and installed versions.

Next, check FTS5 using the same Python interpreter that will run the app:

```bash
python -c "import sqlite3; db = sqlite3.connect(':memory:'); db.execute('CREATE VIRTUAL TABLE probe USING fts5(body)'); db.close(); print('FTS5 is available')"
```

Expected output:

```text
FTS5 is available
```

The command creates a temporary in-memory search table. An error such as `no such module: fts5` means the SQLite library linked to this Python interpreter lacks FTS5 support. Use a Python installation linked to an FTS5-enabled SQLite build, recreate the virtual environment, and repeat the check. Installing a separate SQLite command-line program does not necessarily change Python's linked library. See the [SQLite FTS5 build documentation](https://www.sqlite.org/fts5.html#compiling_and_using_fts5) for the relevant build options.

Create the content and template directories:

```bash
mkdir knowledge templates static
```

These directories should now exist inside the project. As the tutorial progresses, the final structure will be:

```text
python-knowledge-base/
├── requirements.txt
├── documents.py
├── index.py
├── search.py
├── app.py
├── knowledge/
│   ├── deployment.md
│   ├── backups.md
│   └── troubleshooting.md
├── templates/
│   ├── base.html
│   ├── search.html
│   └── document.html
├── static/
│   └── style.css
└── instance/
    └── knowledge.db
```

The indexing command creates `instance/knowledge.db`. It is derived data that can be rebuilt from `knowledge/`.

## Step 2: Create the Sample Knowledge Base {#step-2-create-the-sample-knowledge-base}

Use a small, explicit collection before indexing real documentation. These three files provide distinct search terms and enough overlap to illustrate passage ranking.

Create `knowledge/deployment.md`, paste the following content, and save it:

```markdown
# Deployment Guide

## Prepare a release

Run the application checks before deploying a release. Record the release identifier in the deployment log.

## Restart workers

After deployment, restart the queue workers so they load the new application code. Check the worker logs before marking the release complete.

## Roll back a release

If the health check fails, restore the previous release and restart the workers. Record the rollback reason in the deployment log.
```

The headings provide context for the operational instructions. The worker restart passage will become the main example for a multiword search.

Create and save `knowledge/backups.md`:

```markdown
# Database Backups

## Backup schedule

Create a database backup every night at 02:00 UTC. Keep daily backups for seven days and monthly backups for twelve months.

## Restore a backup

Restore the backup into an isolated database first. Verify the table counts and run application checks before replacing live data.

## Recovery records

Record the backup timestamp and restoration result in the recovery log. A successful backup job does not prove that the backup can be restored.
```

This document distinguishes storing a backup from verifying recovery. Searching for `backup` should lead to passages from this file.

Create and save `knowledge/troubleshooting.md`:

```markdown
# Troubleshooting Notes

## Database connection errors

If the application cannot connect to the database, check the hostname, port, and credentials. Confirm that the database service is running.

## Queue backlog

A growing queue backlog can indicate stopped workers or slow jobs. Inspect worker logs and check job duration before increasing worker capacity.

## Disk pressure

If disk space is low, inspect application logs and expired temporary files. Follow the retention policy before deleting any backup files.
```

This file adds related terms without repeating the deployment instructions. Save all three files and confirm that Python can see them:

```bash
python -c "from pathlib import Path; print('\n'.join(p.name for p in sorted(Path('knowledge').glob('*.md'))))"
```

Expected output:

```text
backups.md
deployment.md
troubleshooting.md
```

The filenames are sorted to make this check predictable. Keep the sample files unchanged until the first search works.

## Step 3: Split Documents into Searchable Passages {#step-3-split-documents-into-searchable-passages}

Each result needs enough surrounding text to be useful and a location that can be checked. Store the original line numbers while splitting the document instead of trying to recover them after a search.

Create `documents.py` with the complete code below, then save it:

```python
from dataclasses import dataclass
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
KNOWLEDGE_DIR = BASE_DIR / "knowledge"
DB_PATH = BASE_DIR / "instance" / "knowledge.db"


@dataclass(frozen=True)
class Passage:
    start_line: int
    end_line: int
    body: str


@dataclass(frozen=True)
class Document:
    path: str
    title: str
    body: str


def split_passages(text: str, max_chars: int = 1200) -> list[Passage]:
    if max_chars < 1:
        raise ValueError("max_chars must be positive")

    lines = text.splitlines()
    passages = []
    pending = []
    start_line = 1
    size = 0

    for number, line in enumerate(lines, start=1):
        # Blank lines separate paragraphs; they do not become search results.
        if not line.strip():
            if pending:
                passages.append(
                    Passage(start_line, number - 1, "\n".join(pending))
                )
                pending = []
                size = 0
            continue

        # Split a large paragraph at a line boundary to retain exact locations.
        added_size = len(line) + (1 if pending else 0)
        if pending and size + added_size > max_chars:
            passages.append(
                Passage(start_line, number - 1, "\n".join(pending))
            )
            pending = []
            size = 0

        if not pending:
            start_line = number
        size += len(line) + (1 if pending else 0)
        pending.append(line)

    if pending:
        passages.append(Passage(start_line, len(lines), "\n".join(pending)))

    return passages


def read_documents() -> list[Document]:
    if not KNOWLEDGE_DIR.is_dir():
        raise FileNotFoundError(f"Missing directory: {KNOWLEDGE_DIR}")

    documents = []
    for path in sorted(KNOWLEDGE_DIR.rglob("*.md")):
        # Only ingest regular files that resolve inside the knowledge directory.
        if not path.is_file() or not path.resolve().is_relative_to(
            KNOWLEDGE_DIR.resolve()
        ):
            continue

        body = path.read_text(encoding="utf-8")
        if not body.strip():
            continue

        title = next(
            (
                line[2:].strip()
                for line in body.splitlines()
                if line.startswith("# ") and line[2:].strip()
            ),
            path.stem,
        )
        documents.append(
            Document(path.relative_to(KNOWLEDGE_DIR).as_posix(), title, body)
        )

    return documents


if __name__ == "__main__":
    for document in read_documents():
        print(f"{document.path}: {document.title}")
        for passage in split_passages(document.body):
            print(f"  lines {passage.start_line}-{passage.end_line}")
```

`Document` represents one source file. `Passage` represents a contiguous piece of that file, including its starting and ending lines. Paths are relative to `knowledge/`, so results do not expose an absolute home-directory path.

Blank lines separate passages. A multiline paragraph can also split at a line boundary when it exceeds the target size. The 1,200-character limit is deliberately soft: an individual line longer than that remains intact. This preserves line-based citations but means very long source lines produce long results.

This is a text splitter, not a complete Markdown parser. Headings become their own passages, and blank lines inside code fences also split passages. The example collection is prose-oriented; documents with complex tables or code blocks would benefit from a Markdown-aware splitter later.

Run the inspection command:

```bash
python documents.py
```

For the unchanged sample collection, expect three document names, each followed by seven passage ranges. The beginning should look like this:

```text
backups.md: Database Backups
  lines 1-1
  lines 3-3
  lines 5-5
  lines 7-7
  lines 9-9
  lines 11-11
  lines 13-13
```

Those ranges correspond to the Markdown lines, including the effect of blank lines on numbering. They will also be used by the source page.

## Step 4: Build the SQLite Search Index {#step-4-build-the-sqlite-search-index}

Keep a source snapshot in a normal SQLite table and searchable passages in an FTS5 table. Both are rebuilt together so the displayed sources match the text that was indexed.

Create `index.py`, add the following code, and save it:

```python
import sqlite3
from contextlib import closing

from documents import DB_PATH, read_documents, split_passages


def rebuild_index() -> tuple[int, int]:
    # Read every source before changing the database. A read error aborts early.
    documents = read_documents()
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    passage_count = 0

    with closing(sqlite3.connect(DB_PATH)) as connection:
        # Explicit BEGIN includes schema creation and replacement in one unit.
        with connection:
            connection.execute("BEGIN")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS documents (
                    id INTEGER PRIMARY KEY,
                    path TEXT NOT NULL UNIQUE,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE VIRTUAL TABLE IF NOT EXISTS passages USING fts5(
                    body,
                    document_id UNINDEXED,
                    start_line UNINDEXED,
                    end_line UNINDEXED,
                    tokenize = 'unicode61'
                )
                """
            )

            connection.execute("DELETE FROM passages")
            connection.execute("DELETE FROM documents")

            for document in documents:
                cursor = connection.execute(
                    "INSERT INTO documents (path, title, body) VALUES (?, ?, ?)",
                    (document.path, document.title, document.body),
                )
                document_id = cursor.lastrowid

                for passage in split_passages(document.body):
                    connection.execute(
                        """
                        INSERT INTO passages
                            (body, document_id, start_line, end_line)
                        VALUES (?, ?, ?, ?)
                        """,
                        (
                            passage.body,
                            document_id,
                            passage.start_line,
                            passage.end_line,
                        ),
                    )
                    passage_count += 1

    return len(documents), passage_count


if __name__ == "__main__":
    try:
        document_count, passage_count = rebuild_index()
    except (OSError, UnicodeError, sqlite3.Error) as error:
        raise SystemExit(f"Indexing failed: {error}") from error

    print(f"Indexed {document_count} documents and {passage_count} passages.")
```

The `documents` table retains the original text. Only `passages.body` is searchable; the three `UNINDEXED` columns carry source metadata. Document titles are displayed through the join added in Step 5, but they are not copied into every passage's searchable text. A heading in the source is still searchable as its own passage.

The transaction replaces the collection as a unit. An insertion error rolls back the replacement instead of leaving half an index. Reading files before opening the write transaction also means an unreadable source leaves the previous index untouched.

`closing()` closes the connection explicitly. Python's connection context manager handles commit and rollback but does not close the connection itself. The [Python sqlite3 documentation](https://docs.python.org/3.12/library/sqlite3.html#how-to-use-the-connection-context-manager) describes this distinction.

Build the index:

```bash
python index.py
```

Expected output for the three unchanged sample files:

```text
Indexed 3 documents and 21 passages.
```

Running the command again replaces the index, so it should report the same counts rather than double them. An existing but empty `knowledge/` directory intentionally produces an empty index. A missing directory produces an error.

This full rebuild is suitable for a small local collection. It regenerates document IDs, so refresh search results after reindexing rather than keeping old source URLs as permanent bookmarks.

## Step 5: Retrieve Relevant Passages {#step-5-retrieve-relevant-passages}

Accept ordinary search text instead of exposing the full FTS5 query language. This keeps quotes, punctuation, and operator-like words from unexpectedly changing how the form behaves.

Create `search.py` with the following code and save it:

```python
import re
import sqlite3
import sys
from contextlib import closing

from documents import DB_PATH


MAX_QUERY_CHARS = 200


def connect_database() -> sqlite3.Connection:
    if not DB_PATH.is_file():
        raise FileNotFoundError("Search index missing. Run python index.py first.")

    # Web searches read the index; they never create or modify database files.
    connection = sqlite3.connect(DB_PATH.as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    return connection


def build_match_query(query: str) -> str:
    if len(query) > MAX_QUERY_CHARS:
        raise ValueError(f"Use at most {MAX_QUERY_CHARS} characters.")

    # Keep letters and numbers, remove duplicates, and quote every token.
    tokens = list(dict.fromkeys(re.findall(r"[^\W_]+", query.lower())))
    if not tokens:
        raise ValueError("Enter at least one word or number.")

    return " OR ".join(f'"{token}"' for token in tokens)


def search_passages(query: str) -> list[sqlite3.Row]:
    match_query = build_match_query(query)
    with closing(connect_database()) as connection:
        return connection.execute(
            """
            SELECT
                documents.id AS document_id,
                documents.path,
                documents.title,
                passages.body,
                passages.start_line,
                passages.end_line,
                bm25(passages) AS score
            FROM passages
            JOIN documents ON documents.id = passages.document_id
            WHERE passages MATCH ?
            ORDER BY score ASC, documents.path ASC, passages.start_line ASC
            LIMIT 10
            """,
            (match_query,),
        ).fetchall()


def get_document(document_id: int) -> sqlite3.Row | None:
    with closing(connect_database()) as connection:
        return connection.execute(
            "SELECT id, path, title, body FROM documents WHERE id = ?",
            (document_id,),
        ).fetchone()


if __name__ == "__main__":
    query = " ".join(sys.argv[1:]).strip()
    try:
        results = search_passages(query)
    except (ValueError, OSError, sqlite3.Error) as error:
        raise SystemExit(str(error)) from error

    if not results:
        print("No matching passages.")

    for result in results:
        print(
            f"{result['path']} "
            f"(lines {result['start_line']}-{result['end_line']})"
        )
        print(result["body"])
        print()
```

The query `restart workers` becomes `"restart" OR "workers"`. A passage can match either word; BM25 ranks the matching passages. Punctuation is discarded, so entering a quoted phrase does not request exact phrase matching. Words such as `OR` are treated as literal search terms, not user-supplied operators.

There are two separate safeguards here. SQL placeholders keep values separate from SQL statements. Token extraction and quoting control the expression interpreted by FTS5. A placeholder alone would not stop an invalid FTS expression from producing a search syntax error.

FTS5's `bm25()` returns lower values for better matches, which is why the query orders by ascending score. The filename and starting line break ties. The score is a ranking value, not a probability that a passage answers the question. See the [FTS5 BM25 documentation](https://www.sqlite.org/fts5.html#the_bm25_function).

Try one focused search:

```bash
python search.py "credentials"
```

Expected output:

```text
troubleshooting.md (lines 5-5)
If the application cannot connect to the database, check the hostname, port, and credentials. Confirm that the database service is running.

```

This search matches one passage in the sample collection. Now try a term absent from all three documents:

```bash
python search.py "quasar"
```

Expected output:

```text
No matching passages.
```

No matching text means no result. The application does not manufacture an answer to fill the gap.

## Step 6: Build the Web Interface {#step-6-build-the-web-interface}

The browser interface uses the same retrieval function as the terminal command. Search results link to the indexed source snapshot, keeping the passage and source page consistent even if a Markdown file changes before the next rebuild.

### Add the Flask application

Create `app.py`, paste the following code, and save it:

```python
import sqlite3

from flask import Flask, abort, render_template, request

from search import MAX_QUERY_CHARS, get_document, search_passages


app = Flask(__name__)


@app.get("/")
def index():
    query = request.args.get("q", "").strip()
    results = []
    error = None
    status = 200

    # An initial visit or an empty form shows guidance instead of running MATCH.
    if query:
        try:
            results = search_passages(query)
        except ValueError as exception:
            error = str(exception)
            status = 400
        except FileNotFoundError:
            error = "Search index missing. Run python index.py first."
            status = 503
        except sqlite3.Error:
            app.logger.exception("Knowledge base search failed")
            error = "The search index is unavailable. Check the server terminal."
            status = 503

    return render_template(
        "search.html",
        query=query,
        results=results,
        error=error,
        max_query_chars=MAX_QUERY_CHARS,
    ), status


@app.get("/documents/<int:document_id>")
def document(document_id):
    try:
        source = get_document(document_id)
    except FileNotFoundError:
        abort(503, description="Search index missing. Run python index.py first.")
    except sqlite3.Error:
        app.logger.exception("Knowledge base source lookup failed")
        abort(503, description="The source index is unavailable.")

    if source is None:
        abort(404)

    return render_template(
        "document.html",
        document=source,
        lines=source["body"].splitlines(),
    )
```

`GET /` accepts the `q` parameter. Invalid search text returns the form with a message, while an unavailable index returns HTTP 503. The source route looks up an integer database ID instead of accepting an arbitrary filesystem path.

### Create the templates

Create and save `templates/base.html`:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{% block title %}Team Knowledge Base{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <main class="container">
        <header>
            <a href="{{ url_for('index') }}">Team Knowledge Base</a>
            <p>Find original passages in the team's documentation.</p>
        </header>
        {% block content %}{% endblock %}
    </main>
</body>
</html>
```

The shared layout supplies a responsive viewport, stylesheet, and navigation back to search. Create and save `templates/search.html`:

```html
{% extends "base.html" %}
{% block content %}
<h1>Search the documentation</h1>
<form action="{{ url_for('index') }}" method="get">
    <label for="query">Search words</label>
    <div class="search-controls">
        <input id="query" name="q" type="search" value="{{ query }}"
               maxlength="{{ max_query_chars }}"
               placeholder="For example: restart workers"
               aria-describedby="search-help">
        <button type="submit">Search</button>
    </div>
    <p id="search-help">Results may match any search word. Try specific terms.</p>
</form>

{% if error %}
    <p class="message" role="alert">{{ error }}</p>
{% elif query %}
    <h2>Results for “{{ query }}”</h2>
    {% if results %}
        <p>Showing {{ results|length }} matching passages, up to 10.</p>
        {% for result in results %}
            <article class="result">
                <h3>
                    <a href="{{ url_for('document', document_id=result['document_id'], _anchor='line-' ~ result['start_line']) }}">
                        {{ result['title'] }}
                    </a>
                </h3>
                <p class="source">{{ result['path'] }} · Lines {{ result['start_line'] }} to {{ result['end_line'] }}</p>
                <pre class="passage">{{ result['body'] }}</pre>
            </article>
        {% endfor %}
    {% else %}
        <p>No matching passages. Try another word from the documentation.</p>
    {% endif %}
{% else %}
    <p>Enter a topic such as backups, credentials, or queue workers.</p>
{% endif %}
{% endblock %}
```

Each result displays the full passage rather than a generated summary. Several results can belong to the same document because the retrieval unit is a passage. The source link includes a fragment such as `#line-5`.

Create and save `templates/document.html`:

```html
{% extends "base.html" %}
{% block title %}{{ document['title'] }} | Team Knowledge Base{% endblock %}
{% block content %}
<h1>{{ document['title'] }}</h1>
<p class="source">{{ document['path'] }}</p>
<p>This is the indexed source snapshot. Reindex to include file changes.</p>
<div class="document" aria-label="Source document with line numbers">
    {% for line in lines %}
        <div class="source-line" id="line-{{ loop.index }}">
            <a class="line-number" href="#line-{{ loop.index }}"
               aria-label="Line {{ loop.index }}">{{ loop.index }}</a>
            <code>{{ line }}</code>
        </div>
    {% endfor %}
</div>
{% endblock %}
```

The source is shown as text, including Markdown markers. Each line has an anchor, and the stylesheet will highlight the targeted line. Flask enables automatic escaping for HTML templates, so document text remains text rather than executable HTML. Keep that behavior and do not add `|safe` to document content. See [Flask's template documentation](https://flask.palletsprojects.com/en/stable/templating/).

### Add local styling and open the app

Create and save `static/style.css`:

```css
:root {
    font-family: system-ui, sans-serif;
    color: #182235;
    background: #f3f5f8;
    line-height: 1.6;
}

* { box-sizing: border-box; }
body { margin: 0; }
a { color: #174ea6; }
.container { max-width: 900px; margin: 0 auto; padding: 24px 16px; }
header { margin-bottom: 32px; }
label { display: block; font-weight: 600; margin-bottom: 8px; }
.search-controls { display: flex; gap: 12px; }
input, button { font: inherit; border-radius: 6px; padding: 10px 14px; }
input { flex: 1; min-width: 0; border: 1px solid #67758a; }
button { border: 1px solid #174ea6; background: #174ea6; color: white; cursor: pointer; }
:focus-visible { outline: 3px solid #8c3f00; outline-offset: 3px; }
.result, .document { background: white; border: 1px solid #c5cddb; border-radius: 8px; }
.result { margin: 16px 0; padding: 20px; }
.result h3 { margin-top: 0; }
.source { color: #45546b; overflow-wrap: anywhere; }
.passage { white-space: pre-wrap; overflow-wrap: anywhere; font: inherit; }
.message { border-left: 4px solid #a12622; background: #fff0ee; padding: 12px; }
.document { padding: 12px 0; }
.source-line { display: grid; grid-template-columns: 4rem minmax(0, 1fr); padding-right: 12px; }
.source-line:target { background: #fff0b3; }
.line-number { text-align: right; padding-right: 16px; }
.source-line code { white-space: pre-wrap; overflow-wrap: anywhere; min-height: 1.6em; }

@media (max-width: 520px) {
    .search-controls { flex-direction: column; }
    .result { padding: 14px; }
}
```

The layout keeps the form usable on narrow screens and wraps long passages. Styling is served locally, so the interface does not depend on an external CSS service.

Start the development server from the project directory:

```bash
python -m flask --app app run
```

Open `http://127.0.0.1:5000`. Expect a search form with the heading **Search the documentation**. Search for `credentials`, then select the result title. The source page should open at line 5 and highlight that line.

The command uses Flask's development server on the local machine. It is suitable for following this tutorial; a production service needs a separate deployment setup. The [Flask quickstart](https://flask.palletsprojects.com/en/stable/quickstart/#a-minimal-application) documents this server workflow.

## Step 7: Try It Out {#step-7-try-it-out}

Use the scenarios below to check the behavior against the supplied documents. Keep the browser open and use a second terminal, with the same virtual environment activated, for indexing commands.

### Check search behavior and source links

Run these searches in the browser. The expected behavior follows from the sample text and the query rules defined above.

| Input or action | Expected behavior |
| --- | --- |
| `credentials` | One passage from `troubleshooting.md`, line 5. |
| `CREDENTIALS` | The same matching passage as the lowercase query. |
| `restart workers` | Passages containing either word, including deployment instructions. Results appear in relevance order. |
| `backup` | Passages containing that token, including the backup instructions and the disk-pressure note. |
| `credentials!!!` | The same result as `credentials`; punctuation is discarded. |
| `!!!` | A validation message asking for a word or number. |
| An empty search | Initial search guidance without querying the index. |
| `quasar` | A no-results message. |
| Select a result title | The indexed source opens at the passage's starting line. |
| Open `/documents/999999` with this sample index | HTTP 404 because that document ID does not exist. |

For an additional escaping check, search for `<script>alert(1)</script>`. The query should be displayed as text in the results heading, without executing JavaScript. It may produce no matches or matches for extracted tokens; it is treated as search text, not HTML.

Avoid interpreting the top result as a verified answer. Ranking chooses passages based on word statistics, and the source link provides the context needed to assess them.

### Add and edit a document

Create `knowledge/access.md`, paste the following content, and save it:

```markdown
# Access Requests

Request repository access through the engineering help desk. Include the repository name and the reason for access.
```

Before rebuilding, search for `repository`. The original index should return no results because it has not read the new file.

Run:

```bash
python index.py
```

Expected output:

```text
Indexed 4 documents and 23 passages.
```

Repeat the browser search. A result from `access.md` should now appear. Next, replace that file's second paragraph with:

```markdown
Request repository access through the platform support portal. Include the repository name and the reason for access.
```

Save the file. Before reindexing, the source page should still show the help-desk instruction because it displays the stored snapshot. Run `python index.py` again; the expected count remains four documents and 23 passages. Refresh the search and open the new result to see the platform support instruction.

This workflow makes updates explicit: editing a source does not silently change the searchable snapshot.

### Remove a document and rebuild again

Delete only the sample `knowledge/access.md` file using the editor or file manager, then run:

```bash
python index.py
```

Expected output:

```text
Indexed 3 documents and 21 passages.
```

Searching for `repository` should once again produce no results. Running the indexing command one more time should keep the same counts, confirming that repeated indexing does not append duplicate passages.

## How Retrieval Works Without AI {#how-retrieval-works-without-ai}

The application separates finding source material from writing an answer. That separation makes it possible to build useful document retrieval without adding a model or a generation service.

### Follow the document and query paths

The document path is `Markdown files → passages with line ranges → SQLite index`. The search path is `query text → literal search terms → ranked passages → source snapshot`.

The application stores the complete document as well as its passages. That duplicates some text, but it keeps source navigation simple and ensures the displayed evidence matches the indexed version. For a small local collection, the clarity is useful; a large corpus would need a different storage and update strategy.

### Understand lexical matching

This implementation searches words in the indexed text. It does not automatically understand that differently worded questions may express the same intent. For example, `credentials` occurs in the sample collection, while `password` does not. The latter will not find the former through semantic similarity.

There is also no stemming or synonym expansion in the chosen configuration. A natural-language question can contain many common words, and the OR query can return passages matching those words even when they do not address the intended question. Specific keywords make the behavior easier to predict.

The lightweight Python tokenizer is designed for the English examples. It is not an exact reimplementation of SQLite's Unicode tokenizer or a multilingual language-processing system. Collections in other languages need language-appropriate evaluation before adopting the same query processing unchanged.

### Recognize the boundary with RAG

RAG combines retrieval with a generation stage that uses retrieved material as context. This project implements the retrieval side and exposes the evidence directly. Python is the implementation language; the absence of AI comes from the selected algorithms and dependencies, not from the language itself.

The application cannot synthesize a policy from several documents, resolve conflicting instructions, or infer an answer that the source text does not state. A source citation makes a passage inspectable, but it does not establish that the source is current or correct.

### Choose extensions based on the collection

For a larger version, useful next steps include Markdown-aware chunking, curated synonyms, filters by document category, and incremental indexing. A production knowledge base would also need access control that limits both search results and source pages to the documents a user may read.

The current rebuild reads the collection into memory and replaces the entire index in one transaction. That is a deliberate fit for a small local knowledge base, rather than a background indexing service for a large organization.

## Conclusion {#conclusion}

The finished application turns a directory of Markdown files into a searchable local reference. Each result remains a passage from the documentation, with a direct path back to the source that produced it.

- **Retrieval without generation.** Python and SQLite can return useful source passages without embeddings or a language model.
- **Traceable passages.** Relative filenames and line ranges connect each result to the indexed source snapshot.
- **Explicit updates.** Rebuilding the index applies additions, edits, and removals together instead of accumulating duplicate passages.
- **Predictable search rules.** Literal query terms and BM25 ranking provide a clear starting point, with limitations around synonyms and natural-language intent.
- **Context remains essential.** The source page supports verification; a high ranking alone does not make a passage a complete or authoritative answer.
