---
title: "Making HTTP Requests with the JavaScript Fetch API"
slug: "making-http-requests-with-the-javascript-fetch-api"
category: "JavaScript"
date: "2026-04-13"
status: "published"
---

Making HTTP requests from a browser used to mean writing `XMLHttpRequest` code: manually opening a connection, setting up `onreadystatechange` callbacks, checking `readyState`, parsing the response, and handling errors in ways that varied between browsers. The code worked, but it was verbose, hard to read, and easy to get wrong. JavaScript has evolved significantly since then. The Fetch API is the browser's native, modern answer to HTTP requests. It is built on Promises, integrates cleanly with `async/await`, and is available as a global function in every major browser without installing anything. This tutorial walks through everything you need to know to use it confidently, from a basic GET request all the way to building a reusable wrapper that handles errors and timeouts.

## What is the Fetch API? {#what-is-fetch-api}

The Fetch API is a browser-native interface for making HTTP requests from JavaScript. It was introduced to replace `XMLHttpRequest`, an older API that used callbacks and was notoriously verbose to work with. Fetch is built on Promises, which means it integrates naturally with `async/await` and produces code that reads almost like synchronous logic.

Because Fetch is part of the browser itself, there is nothing to install. You call `fetch()` as a global function anywhere in your JavaScript, and it returns a Promise that resolves to a `Response` object representing the server's reply.

There is one behavior that surprises almost every developer the first time they encounter it: a Fetch promise only rejects on network-level failures, such as when there is no internet connection or the domain cannot be resolved. HTTP error responses like 404 or 500 do not cause the promise to reject. From Fetch's perspective, receiving a 404 response was a successful network operation. It is your responsibility to check whether the response indicates success or failure. We will cover this in detail with a concrete example later in the tutorial.

## Overview {#overview}

This tutorial builds a series of small, self-contained HTML files that you can open directly in your browser. Each file demonstrates a specific Fetch API concept with output displayed on the page itself, so you do not need to open the browser console to see what is happening.

### What You'll Build

A set of browser-based demos that cover the complete HTTP request lifecycle using only built-in JavaScript, including GET, POST, PUT, and DELETE requests, proper error handling, request timeouts with `AbortSignal`, and a reusable fetch wrapper function.

### What You'll Learn

By following this tutorial, you will learn how to:

- Make GET, POST, PUT, and DELETE requests using the Fetch API.
- Parse JSON responses and construct JSON request bodies manually.
- Correctly detect HTTP errors using `response.ok` and `response.status`.
- Set request timeouts using `AbortSignal.timeout()`.
- Build a reusable `httpRequest()` wrapper that consolidates error handling and default headers.

### What You'll Need

Before getting started, make sure you have:

- A modern browser (Chrome, Firefox, Edge, or Safari).
- A text editor (Visual Studio Code recommended).
- No additional tools, frameworks, or package managers are required.

All examples in this tutorial use json placeholder from `https://jsonplaceholder.typicode.com`, a free public API that simulates a REST backend without requiring authentication or setup.


## Step 1: Create the Project Structure {#step-1-create-project}

Open a terminal and create a new folder for this project:

```
mkdir fetch-demo
cd fetch-demo
```

All files in this tutorial will live inside this folder. Throughout the tutorial, we will create multiple HTML files, each demonstrating one concept. You can open each file by double-clicking it in your file explorer, or by dragging it into a browser window.


## Step 2: Make a GET Request {#step-2-get-request}

A GET request is the most common type of HTTP request. It asks the server to return a resource without modifying anything. Let's start here.

Create a new file called `01-get.html` inside the `fetch-demo` folder and add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>01 - GET Request</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
    </style>
</head>
<body>
    <h2>01 - GET Request</h2>
    <div id="output"></div>

    <script>
        // A small helper that appends text to the #output div.
        // This lets us see results on the page without opening DevTools.
        function log(text) {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        // The async keyword lets us use await inside this function.
        // We wrap the entire operation in try/catch to handle both
        // network failures and unexpected runtime errors.
        async function getPost() {
            label('Fetching post with ID 1...');

            try {
                // fetch() takes a URL as its first argument.
                // For a GET request, this is all you need — GET is the default method.
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1');

                // response.ok is true when the status code is in the 200-299 range.
                // We MUST check this manually — Fetch does not throw on 404 or 500.
                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                // response.json() reads the response body and parses it as JSON.
                // It also returns a Promise, so we await it.
                const post = await response.json();

                log(`Status: ${response.status} ${response.statusText}`);
                log(JSON.stringify(post, null, 2));

            } catch (error) {
                log(`Error: ${error.message}`);
            }
        }

        getPost();
    </script>
</body>
</html>
```

Save the file. Open `01-get.html` in your browser by double-clicking it in the file explorer. You should see the following output appear on the page:

```
Status: 200 OK
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum..."
}
```

Two things in this code deserve attention. First, `response.json()` is a separate async call that must be awaited. The `fetch()` function gives you the raw `Response` object first, and you then decide how to read the body: `response.json()` for JSON, `response.text()` for plain text, or `response.blob()` for binary data like images. Second, note that we check `response.ok` before calling `response.json()`. If the server returns a 404, `response.json()` would still succeed but return an error payload. Checking `response.ok` first ensures we never treat an error response as successful data.


## Step 3: Make a POST Request {#step-3-post-request}

A POST request sends data to the server, typically to create a new resource. Unlike a GET request, it requires additional configuration: the HTTP method, a `Content-Type` header so the server knows the format of the body, and the request body itself.

Create a new file called `02-post.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>02 - POST Request</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
    </style>
</head>
<body>
    <h2>02 - POST Request</h2>
    <div id="output"></div>

    <script>
        function log(text) {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        async function createPost() {
            label('Creating a new post...');

            // This is the data we want to send to the server.
            const newPost = {
                title:  'Learning the Fetch API',
                body:   'No external libraries required.',
                userId: 1,
            };

            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts', {
                    // The second argument to fetch() is an options object.
                    // For anything other than GET, we specify the method here.
                    method: 'POST',

                    headers: {
                        // We must tell the server what format the body is in.
                        // Without this header, the server may not parse the body correctly.
                        'Content-Type': 'application/json',
                    },

                    // JSON.stringify() converts our JavaScript object to a JSON string.
                    // Fetch does not do this automatically — it must be done manually.
                    body: JSON.stringify(newPost),
                });

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                const created = await response.json();

                log(`Status: ${response.status} ${response.statusText}`);
                log(JSON.stringify(created, null, 2));

            } catch (error) {
                log(`Error: ${error.message}`);
            }
        }

        createPost();
    </script>
</body>
</html>
```

Save the file and open `02-post.html` in your browser. You should see:

```
Status: 201 Created
{
  "title": "Learning the Fetch API",
  "body": "No external libraries required.",
  "userId": 1,
  "id": 101
}
```

The server responded with status `201 Created` and returned the new resource, complete with the `id` it assigned to it. Notice that `id: 101` was assigned by the server and was not part of our request body. JSONPlaceholder simulates this behavior to mirror how a real REST API would respond.

Two steps that are easy to overlook when writing a POST request for the first time: calling `JSON.stringify()` on the request body before sending, and calling `response.json()` on the response after receiving it. Both are required explicitly because the Fetch API works with raw strings at the transport layer, not JavaScript objects.


## Step 4: Make PUT and DELETE Requests {#step-4-put-delete}

PUT and DELETE requests follow the same pattern as POST. The main difference is the HTTP method and, for DELETE, that there is typically no request body to send.

Create a new file called `03-put-delete.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>03 - PUT and DELETE Requests</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
    </style>
</head>
<body>
    <h2>03 - PUT and DELETE Requests</h2>
    <div id="output"></div>

    <script>
        function log(text) {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        // PUT: Replace the entire resource at the given URL with new data.
        // Use PUT when you want to fully overwrite an existing record.
        async function updatePost() {
            label('Updating post with ID 1 (PUT)...');

            const updatedPost = {
                id:     1,
                title:  'Updated Title via Fetch API',
                body:   'This content has been fully replaced.',
                userId: 1,
            };

            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1', {
                    method:  'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body:    JSON.stringify(updatedPost),
                });

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                const result = await response.json();

                log(`Status: ${response.status} ${response.statusText}`);
                log(JSON.stringify(result, null, 2));

            } catch (error) {
                log(`Error: ${error.message}`);
            }
        }

        // DELETE: Remove the resource at the given URL.
        // There is no request body — just the method and the URL.
        async function deletePost() {
            label('Deleting post with ID 1 (DELETE)...');

            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1', {
                    method: 'DELETE',
                });

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                // A successful DELETE typically returns an empty body with status 200.
                // We call response.text() instead of response.json() to safely read
                // whatever the server sends back, even if it is an empty string.
                const body = await response.text();

                log(`Status: ${response.status} ${response.statusText}`);
                log(`Response body: "${body}" (empty body is normal for DELETE)`);

            } catch (error) {
                log(`Error: ${error.message}`);
            }
        }

        // Run both in sequence so we can see both results on the page.
        async function run() {
            await updatePost();
            await deletePost();
        }

        run();
    </script>
</body>
</html>
```

Save the file and open `03-put-delete.html` in your browser. You should see:

```
Updating post with ID 1 (PUT)...
Status: 200 OK
{
  "id": 1,
  "title": "Updated Title via Fetch API",
  "body": "This content has been fully replaced.",
  "userId": 1
}

Deleting post with ID 1 (DELETE)...
Status: 200 OK
Response body: "{}" (empty body is normal for DELETE)
```

The PUT request returns the full updated resource, while the DELETE request returns an empty object, which is JSONPlaceholder's convention for a successful deletion. In a real API, a DELETE might return `200 OK` with a message, `204 No Content` with an empty body, or `200 OK` with the deleted record. This is why we use `response.text()` rather than `response.json()` for the DELETE response: it safely handles an empty body without throwing a JSON parse error.


## Step 5: Understand Error Handling Correctly {#step-5-error-handling}

The most important behavior to understand about the Fetch API is how it handles HTTP errors, because it is different from what most developers expect coming from other HTTP tools. This difference is subtle enough that it is responsible for a significant share of bugs in applications built with Fetch.

The Fetch promise only rejects on actual network failures. A response with status 404 or 500 is still a resolved promise because the server successfully returned a response. If you do not check `response.ok`, your code will silently treat error responses as success.

This step demonstrates both cases concretely. Create a new file called `04-error-handling.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>04 - Error Handling</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
        .ok    { color: #4ec9b0; }
        .error { color: #f48771; }
    </style>
</head>
<body>
    <h2>04 - Error Handling</h2>
    <div id="output"></div>

    <script>
        function log(text, type = 'normal') {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            if (type === 'ok')    pre.classList.add('ok');
            if (type === 'error') pre.classList.add('error');
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        // CASE 1: A successful request (status 200).
        // Nothing surprising here — this is the happy path.
        async function fetchExistingPost() {
            label('Case 1: Fetching a post that exists (ID 1)...');
            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1');

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                const data = await response.json();
                log(`Status: ${response.status} — Success. Title: "${data.title}"`, 'ok');

            } catch (error) {
                log(`Caught: ${error.message}`, 'error');
            }
        }

        // CASE 2: A 404 response — the resource does not exist.
        //
        // This is the critical case. Without the response.ok check,
        // the code below would NOT enter the catch block. It would happily
        // call response.json() on the error response and return that data
        // as if the request had succeeded.
        //
        // JSONPlaceholder returns an empty object {} for missing resources,
        // so without response.ok, our app would think it got a valid post.
        async function fetchMissingPost() {
            label('Case 2: Fetching a post that does NOT exist (ID 99999)...');
            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/99999');

                // Remove this check and the catch block will never run,
                // even though the server returned 404.
                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status} ${response.statusText}`);
                }

                const data = await response.json();
                log(`Status: ${response.status} — Success: ${JSON.stringify(data)}`, 'ok');

            } catch (error) {
                log(`Caught: ${error.message}`, 'error');
            }
        }

        // CASE 3: A genuine network failure.
        // This IS the case where Fetch rejects the promise automatically.
        // We simulate it by pointing to a non-existent domain.
        async function fetchWithNetworkError() {
            label('Case 3: Fetching from a domain that does not exist...');
            try {
                // This URL will fail at the DNS level — no server will respond.
                const response = await fetch('https://this-domain-does-not-exist-12345.xyz/posts');

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status}`);
                }

                const data = await response.json();
                log(`Success: ${JSON.stringify(data)}`, 'ok');

            } catch (error) {
                // For network failures, error is a TypeError with a message
                // like "Failed to fetch" or "NetworkError when attempting to fetch resource".
                log(`Caught: ${error.name} — ${error.message}`, 'error');
            }
        }

        async function run() {
            await fetchExistingPost();
            await fetchMissingPost();
            await fetchWithNetworkError();
        }

        run();
    </script>
</body>
</html>
```

Save the file and open `04-error-handling.html` in your browser. You should see:

```
Case 1: Fetching a post that exists (ID 1)...
Status: 200 — Success. Title: "sunt aut facere repellat..."

Case 2: Fetching a post that does NOT exist (ID 99999)...
Caught: HTTP error: 404 Not Found

Case 3: Fetching from a domain that does not exist...
Caught: TypeError — Failed to fetch
```

Read the three cases carefully. Case 1 is the happy path: everything works. Case 2 is where the Fetch-specific behavior matters: the promise resolved successfully, but we caught the error because we checked `response.ok` and threw manually. Without that check, Case 2 would have printed a "Success" message despite receiving a 404. Case 3 is the only scenario where Fetch itself rejects the promise, and the error is a `TypeError`, not an HTTP status error.

The mental model to internalize is this: with Fetch, the `catch` block handles two fundamentally different things. A rejected promise means the network call itself failed before a response arrived. A resolved promise with `response.ok === false` means the server responded, but with an error status. Both situations require handling, and only one of them triggers a rejection automatically.


## Step 6: Set a Request Timeout {#step-6-timeout}

Fetch does not have a built-in timeout option. By default, a fetch request will wait as long as the browser's default network timeout, which can be several minutes. For a real application, this is too long. Users will assume something is broken long before the browser gives up.

The modern solution is `AbortSignal.timeout()`, which was added to browsers alongside improvements to the `AbortController` API. You pass a signal to the fetch options object, and the browser automatically cancels the request after the specified number of milliseconds.

Create a new file called `05-timeout.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>05 - Request Timeout</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
        .ok    { color: #4ec9b0; }
        .error { color: #f48771; }
    </style>
</head>
<body>
    <h2>05 - Request Timeout</h2>
    <div id="output"></div>

    <script>
        function log(text, type = 'normal') {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            if (type === 'ok')    pre.classList.add('ok');
            if (type === 'error') pre.classList.add('error');
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        // CASE 1: A generous timeout — the request should complete in time.
        async function fetchWithGenerousTimeout() {
            label('Case 1: Fetching with a 5000ms timeout (should succeed)...');

            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1', {
                    // AbortSignal.timeout(ms) returns a signal that automatically
                    // fires after the specified number of milliseconds.
                    // The browser cancels the request when the signal fires.
                    signal: AbortSignal.timeout(5000),
                });

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status}`);
                }

                const data = await response.json();
                log(`Success: "${data.title}"`, 'ok');

            } catch (error) {
                // It is important to distinguish between a timeout and other errors.
                // A timeout produces a DOMException with name 'TimeoutError'.
                // A user-triggered abort produces name 'AbortError'.
                if (error.name === 'TimeoutError') {
                    log(`Timed out: The request took too long.`, 'error');
                } else {
                    log(`Error (${error.name}): ${error.message}`, 'error');
                }
            }
        }

        // CASE 2: An extremely short timeout — the request will be cancelled
        // before the server has a chance to respond.
        async function fetchWithShortTimeout() {
            label('Case 2: Fetching with a 1ms timeout (will time out)...');

            try {
                const response = await fetch('https://jsonplaceholder.typicode.com/posts/1', {
                    // 1 millisecond is not enough time for any real network request.
                    // This lets us see the TimeoutError in action.
                    signal: AbortSignal.timeout(1),
                });

                if (!response.ok) {
                    throw new Error(`HTTP error: ${response.status}`);
                }

                const data = await response.json();
                log(`Success: "${data.title}"`, 'ok');

            } catch (error) {
                if (error.name === 'TimeoutError') {
                    log(`Timed out: Request cancelled after 1ms.`, 'error');
                } else {
                    log(`Error (${error.name}): ${error.message}`, 'error');
                }
            }
        }

        async function run() {
            await fetchWithGenerousTimeout();
            await fetchWithShortTimeout();
        }

        run();
    </script>
</body>
</html>
```

Save the file and open `05-timeout.html` in your browser. You should see:

```
Case 1: Fetching with a 5000ms timeout (should succeed)...
Success: "sunt aut facere repellat provident occaecati..."

Case 2: Fetching with a 1ms timeout (will time out)...
Timed out: Request cancelled after 1ms.
```

The `error.name === 'TimeoutError'` check in the catch block is important. When a request is cancelled due to a timeout, the browser throws a `DOMException` with `name` set to `'TimeoutError'`. This is distinct from `'AbortError'`, which is thrown when you cancel a request manually using `AbortController.abort()`. Checking the name lets you give users a precise error message: "the server took too long to respond" is more useful than "something went wrong."

`AbortSignal.timeout()` is supported in all modern browsers. If you need to support older browsers or need the ability to cancel a request manually in addition to a timeout, you can combine `AbortController` with `AbortSignal.any()`, but `AbortSignal.timeout()` alone is the cleanest solution for the common case.


## Step 7: Build a Reusable Fetch Wrapper {#step-7-wrapper}

Every example so far has repeated the same logic: set the `Content-Type` header, call `JSON.stringify()` on the body, check `response.ok`, and handle errors in a `catch` block. In a real application, this repetition quickly becomes a maintenance burden. If you decide to change the default timeout or add an authorization header, you would have to update every single fetch call.

The solution is to extract this shared logic into a reusable wrapper function. This is the same principle as the service layer pattern in a Laravel application: centralize the HTTP logic in one place, and let the rest of the codebase call it without worrying about the details.

We will split this step into two files: a `http.js` module that contains the wrapper, and a `06-wrapper.html` file that uses it.

First, create a new file called `http.js` inside the `fetch-demo` folder:

```javascript
// http.js
// A minimal, reusable HTTP client built on the Fetch API.
// All shared configuration lives here: default headers, timeout,
// JSON serialization, and error handling.

const DEFAULT_TIMEOUT_MS = 8000;

/**
 * Make an HTTP request and return the parsed JSON response.
 *
 * @param {string} url     - The endpoint URL.
 * @param {object} options - Fetch options: method, body, headers, etc.
 * @returns {Promise<any>} - The parsed JSON response body.
 * @throws {Error}         - Throws on network failure, timeout, or HTTP error.
 */
async function httpRequest(url, options = {}) {
    // Merge the caller's headers on top of the defaults.
    // The spread operator lets the caller override any default header.
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers,
    };

    // If the caller passes a body, stringify it.
    // If not (e.g. a GET request), leave it as-is (undefined).
    const body = options.body !== undefined
        ? JSON.stringify(options.body)
        : undefined;

    try {
        const response = await fetch(url, {
            ...options,
            headers,
            body,
            // Apply a default timeout to every request.
            // The caller can override this by passing their own signal.
            signal: options.signal ?? AbortSignal.timeout(DEFAULT_TIMEOUT_MS),
        });

        // Centralized HTTP error check.
        // Every non-2xx response is treated as an error, consistently.
        if (!response.ok) {
            // Attempt to parse the error response body for a server message.
            // If parsing fails, fall back to the HTTP status text.
            let errorMessage;
            try {
                const errorBody = await response.json();
                errorMessage = errorBody.message ?? response.statusText;
            } catch {
                errorMessage = response.statusText;
            }

            throw new Error(`HTTP ${response.status}: ${errorMessage}`);
        }

        // Handle responses with no body (e.g. 204 No Content).
        const contentType = response.headers.get('Content-Type') ?? '';
        if (!contentType.includes('application/json')) {
            return null;
        }

        return response.json();

    } catch (error) {
        // Re-throw with a consistent message depending on the error type.
        if (error.name === 'TimeoutError') {
            throw new Error(`Request timed out after ${DEFAULT_TIMEOUT_MS}ms: ${url}`);
        }
        // Re-throw all other errors (HTTP errors from above, network failures, etc.)
        throw error;
    }
}

// Convenience wrappers for the four common HTTP methods.
// These keep the call sites clean and self-documenting.

function get(url, options = {}) {
    return httpRequest(url, { ...options, method: 'GET' });
}

function post(url, body, options = {}) {
    return httpRequest(url, { ...options, method: 'POST', body });
}

function put(url, body, options = {}) {
    return httpRequest(url, { ...options, method: 'PUT', body });
}

function del(url, options = {}) {
    return httpRequest(url, { ...options, method: 'DELETE' });
}

// Export the wrapper and convenience functions.
// Files that import this module get the full client without
// copying a single line of fetch logic.
export { httpRequest, get, post, put, del };
```

Save `http.js`. Now create `06-wrapper.html` to use it:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>06 - Reusable Wrapper</title>
    <style>
        body { font-family: monospace; padding: 24px; background: #f5f5f5; }
        h2   { color: #333; }
        pre  {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
        }
        .label { font-weight: bold; color: #555; margin-top: 16px; }
        .ok    { color: #4ec9b0; }
        .error { color: #f48771; }
    </style>
</head>
<body>
    <h2>06 - Reusable Wrapper</h2>
    <div id="output"></div>

    <!--
        type="module" is required to use ES module import/export syntax.
        It also means the script runs in strict mode automatically.

        IMPORTANT: Because this file uses ES modules, it must be served
        over HTTP, not opened directly as a file://.
        Use VS Code Live Server, or run: npx serve fetch-demo
        then open http://localhost:3000/06-wrapper.html in your browser.
    -->
    <script type="module">
        import { get, post, put, del } from './http.js';

        function log(text, type = 'normal') {
            const output = document.getElementById('output');
            const pre = document.createElement('pre');
            pre.textContent = text;
            if (type === 'ok')    pre.classList.add('ok');
            if (type === 'error') pre.classList.add('error');
            output.appendChild(pre);
        }

        function label(text) {
            const output = document.getElementById('output');
            const p = document.createElement('p');
            p.className = 'label';
            p.textContent = text;
            output.appendChild(p);
        }

        async function run() {

            // GET — no headers, no body, no timeout configuration needed.
            label('GET /posts/1');
            try {
                const post1 = await get('https://jsonplaceholder.typicode.com/posts/1');
                log(JSON.stringify(post1, null, 2), 'ok');
            } catch (e) {
                log(e.message, 'error');
            }

            // POST — pass the data as the second argument, no JSON.stringify needed.
            label('POST /posts');
            try {
                const created = await post('https://jsonplaceholder.typicode.com/posts', {
                    title:  'Posted via the wrapper',
                    body:   'The wrapper handles Content-Type and JSON.stringify.',
                    userId: 1,
                });
                log(JSON.stringify(created, null, 2), 'ok');
            } catch (e) {
                log(e.message, 'error');
            }

            // PUT — same pattern as POST.
            label('PUT /posts/1');
            try {
                const updated = await put('https://jsonplaceholder.typicode.com/posts/1', {
                    id:     1,
                    title:  'Updated via the wrapper',
                    body:   'PUT replaces the entire resource.',
                    userId: 1,
                });
                log(JSON.stringify(updated, null, 2), 'ok');
            } catch (e) {
                log(e.message, 'error');
            }

            // DELETE — no body needed.
            label('DELETE /posts/1');
            try {
                await del('https://jsonplaceholder.typicode.com/posts/1');
                log('Deleted successfully.', 'ok');
            } catch (e) {
                log(e.message, 'error');
            }

            // HTTP error — the wrapper throws automatically on non-2xx status.
            label('GET /posts/99999 (will produce HTTP 404)');
            try {
                await get('https://jsonplaceholder.typicode.com/posts/99999');
            } catch (e) {
                log(e.message, 'error');
            }

        }

        run();
    </script>
</body>
</html>
```

Save `06-wrapper.html`.

Because this file uses ES module syntax (`import`/`export`), browsers require it to be served over HTTP rather than opened directly as a `file://` URL. If you have VS Code with the Live Server extension installed, right-click `06-wrapper.html` and choose "Open with Live Server". Alternatively, if you have Node.js available, run the following command from inside the `fetch-demo` folder:

```
npx serve .
```

Then open `http://localhost:3000/06-wrapper.html` in your browser. You should see:

```
GET /posts/1
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident...",
  "body": "quia et suscipit..."
}

POST /posts
{
  "title": "Posted via the wrapper",
  "body": "The wrapper handles Content-Type and JSON.stringify.",
  "userId": 1,
  "id": 101
}

PUT /posts/1
{
  "id": 1,
  "title": "Updated via the wrapper",
  "body": "PUT replaces the entire resource.",
  "userId": 1
}

DELETE /posts/1
Deleted successfully.

GET /posts/99999 (will produce HTTP 404)
HTTP 404: Not Found
```

The call sites are now concise and intention-revealing. All of the mechanics, the `Content-Type` header, the `JSON.stringify()` call, the `response.ok` check, and the `AbortSignal.timeout()` configuration, live in `http.js`. If you need to add an authorization header to every request, or change the default timeout from 8 seconds to 5, you change one file and every call in the application picks up the change immediately.


## When to Use Direct Fetch vs a Wrapper {#direct-fetch-vs-wrapper}

Now that we have built both approaches, it is worth understanding when each one is appropriate, because they serve different contexts well.

Direct `fetch()` calls are perfectly suitable for simple, one-off requests where you control the entire flow and there is no meaningful repetition. A script that fetches a single endpoint to display data on a page does not need a wrapper. Adding one would introduce indirection without adding value.

A wrapper like `http.js` starts earning its keep as soon as you have multiple request call sites that share the same requirements. Default headers, timeout behavior, JSON serialization, and centralized error handling are things you do not want to repeat in every file. The wrapper enforces consistency: every request in the application behaves the same way, and changes to that behavior only need to be made in one place. This is the same principle behind service layers in backend frameworks: push shared mechanics to the edge, and keep the business logic clean.

The other thing the wrapper gives you is a controlled extension point. If you later need to attach an authorization token to every outgoing request, you add it once to `http.js`. If you want to log every failed request to an error tracking service, you add it once to the `catch` block. Without the wrapper, both of those changes would require touching every file that makes a network request.


## Conclusion {#conclusion}

The Fetch API has been available in browsers since 2015 and has reached full maturity in all major browsers. It is not a workaround or a compromise. It is the platform's own answer to HTTP requests, and it is capable of handling everything a typical web application needs.

Here are the key takeaways from this tutorial:

- **`fetch()` is a global function available in all modern browsers.** It requires no installation and no external dependencies.
- **A Fetch promise only rejects on network failures, not HTTP errors.** Always check `response.ok` before reading the response body. Without this check, a 404 or 500 response is silently treated as success.
- **JSON must be handled manually in both directions.** Use `JSON.stringify()` when sending a body, and `await response.json()` when reading a JSON response. The Fetch API works with raw strings at the transport layer, so the conversion is always your responsibility.
- **`AbortSignal.timeout(ms)` adds request timeouts cleanly.** Always set a timeout for real application requests. Check `error.name === 'TimeoutError'` in the catch block to give users a meaningful error message.
- **A reusable wrapper eliminates repetition.** Centralizing headers, serialization, error handling, and timeout configuration in a single `http.js` module means application code stays clean, and changes to shared behavior only need to be made once.
- **ES module `import`/`export` requires an HTTP server.** Files that use `import` must be served over HTTP, not opened as `file://` URLs. Use VS Code Live Server or `npx serve` for local development.