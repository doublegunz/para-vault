# Laravel MCP 1.0 Is Stable: What's New and What Changes for Your Application

In our [previous Laravel MCP tutorial](https://qadrlabs.com/post/build-an-mcp-server-in-laravel-so-ai-agents-can-query-your-content), we built a content server that lets an AI agent search published articles, retrieve their contents, and inspect library statistics. That example used `laravel/mcp` v0.9.4. It demonstrated how application data becomes useful to an agent when the application exposes a small, deliberate set of operations.

Laravel MCP has now reached [v1.0.0](https://github.com/laravel/mcp/releases/tag/v1.0.0). For developers maintaining an integration, the questions are practical: what changes in the protocol, which clients can still connect, and which parts of an existing application deserve another look?

The release brings a new protocol flow, compatibility for older clients, and improvements to authentication, testing, and input handling. Understanding those changes helps you decide where an upgrade needs attention.

## Overview {#overview}

This article covers the stable milestone and its implications for Laravel applications that expose or consume MCP services. The earlier content server remains our practical reference; here, the focus is the release itself.

There are two useful comparisons. The [release changelog](https://github.com/laravel/mcp/releases/tag/v1.0.0) compares `v1.0.0-beta.1` with `v1.0.0`, while the [upgrade guide](https://github.com/laravel/mcp/blob/v1.0.0/UPGRADE.md) explains the broader move from 0.9 to 1.0. Keeping those baselines separate matters: the final stable release includes finishing work on a larger transition.

## What the 1.0 Milestone Means {#what-the-1-0-milestone-means}

The appeal of Laravel MCP is that an application can offer an explicit interface to AI clients while keeping its business logic in Laravel. You decide which operations exist, what input they accept, and what data they return.

Our content server illustrates that boundary. The agent chooses a search term and calls a tool; the application decides which articles are visible. The same design can serve other domains, such as searching internal documentation or looking up an order. Each operation still needs rules appropriate to its data and users.

Version 1.0 gives teams a stable release to evaluate as a dependency. The most useful evidence behind that milestone is the work on interoperability and testing discussed below. Application readiness still depends on the integration: its permissions, expected clients, and failure handling need to fit the environment where it runs.

The distinction between server and client is also useful throughout this release. A Laravel MCP server exposes your application's capabilities. The Laravel MCP client connects your application to another MCP server. Some changes affect one side; others affect both.

## A New Protocol Flow with Legacy Client Support {#a-new-protocol-flow-with-legacy-client-support}

The modern flow uses protocol revision `2026-07-28` and `server/discover`. Protocol information travels with individual requests in `params._meta`, including the protocol version and client capabilities. The [v1.0.0 server implementation](https://github.com/laravel/mcp/blob/v1.0.0/src/Server.php) validates that metadata when handling modern requests.

This changes the starting point for anyone who writes protocol messages directly. In the previous tutorial, our terminal commands opened with `initialize`, followed by `notifications/initialized`. Modern requests carry their own protocol context instead of depending on that opening exchange.

Laravel MCP also supports the older flow on the same endpoint. The [legacy compatibility change](https://github.com/laravel/mcp/pull/341) keeps `initialize` clients working alongside modern clients and exempts legacy requests from the new HTTP header checks. This gives existing integrations a transition path while client implementations adopt the newer protocol.

For readers of the earlier tutorial, that is the relevant distinction: its handshake represents the legacy flow. It should no longer be described as the only way an MCP interaction starts. Compatibility support also should not be read as a promise that every client version and every optional capability behaves identically.

## OAuth and Authenticated MCP Connections {#oauth-and-authenticated-mcp-connections}

Authentication involves more than rejecting a request without credentials. A client also needs enough information to begin the authorization process. The release improves that exchange and the metadata used around it.

### Challenges on Protected Routes

The [OAuth challenge fix](https://github.com/laravel/mcp/pull/322) adjusts middleware priority so OAuth-protected MCP routes can add the authentication challenge to a `401` response produced by authentication middleware. That makes the rejection useful to a client trying to establish access.

For an application exposing private information, this improves the connection process. Your application's authorization rules still decide what the authenticated caller may do with that information.

### Client Identity and Authorization Metadata

The release also carries support for optional `logo_uri` and `client_uri` registration metadata. Values are stored when the OAuth client table has the corresponding columns, and the published authorization view can display the logo and client link. This was [ported from v0.9.5](https://github.com/laravel/mcp/pull/342), so it is part of 1.0 without being exclusive to it.

On the consuming side, the [upgrade guide](https://github.com/laravel/mcp/blob/v1.0.0/UPGRADE.md#client-id-metadata-documents) describes Client ID Metadata Documents: an HTTPS URL identifies a public client through a JSON document. This path has no client secret. The client can still fall back to dynamic registration. OAuth redirects also require the authorization server to advertise PKCE support with `S256`.

## Better Testing and Protocol Conformance {#better-testing-and-protocol-conformance}

A tool can produce the correct result and still be exposed to the wrong caller, or fail to appear when it should. The testing additions make registration behavior easier to check directly.

The [registration assertions](https://github.com/laravel/mcp/pull/333) let tests inspect a server's tools, prompts, and resources through `tools()`, `prompts()`, and `resources()`, then use `assertRegistered()` or `assertNotRegistered()`. These checks exercise conditional registration through `shouldRegister()`. A [separate addition](https://github.com/laravel/mcp/pull/334) adds `assertNotRegistered()` to `TestResponse` as well.

That distinction is useful when reviewing a server. Tests can cover both what an operation returns and whether the operation is available in the first place. Registration tests complement the authorization checks inside application behavior.

The package also adds a [local MCP conformance runner](https://github.com/laravel/mcp/pull/327) for its server and client implementations. It checks protocol behavior against the reference suite and uses a baseline to identify unexpected failures. This is package development infrastructure, separate from the Pest tests you write for your own tools.

Its value is earlier detection of interoperability regressions. The presence of the runner does not mean every conformance scenario passes; the baseline is part of how the checks are interpreted.

## Smaller Changes That Improve Everyday Development {#smaller-changes-that-improve-everyday-development}

Several smaller additions address familiar friction when handling structured arguments or repeatedly querying a server.

### Nested Input with Dot Notation

Request input now supports Laravel-style paths such as `filters.category`. The [implementation uses `data_get()`](https://github.com/laravel/mcp/blob/v1.0.0/src/Request.php), allowing code to read nested arguments through the request API.

One compatibility detail deserves attention: a nested path and a literal key containing a dot are different. The [change discussion](https://github.com/laravel/mcp/pull/336) calls out that `limit.items` now traverses nested data rather than falling back to a top-level key with that exact spelling. Existing schemas with dotted property names deserve review.

### Notification Parameter Validation

The release adds [parameter shape validation for JSON-RPC notifications](https://github.com/laravel/mcp/pull/331). Malformed parameters are handled as a protocol validation problem instead of escaping into a PHP type error. This improves diagnostics when an incoming message has the wrong structure.

### Client Caching That Follows Server Hints

Response caching is [opt-in through `withCache()`](https://github.com/laravel/mcp/pull/326). The Laravel MCP client then uses server hints, including lifetime and scope, to determine whether a result can be cached. Installing 1.0 alone does not enable it.

For repeated discovery or resource reads, eligible cached results can avoid another request. Private responses also need appropriate caller isolation, for which the API provides a configurable discriminator. The practical benefit depends on the server's hints and the application's access patterns; there is no fixed performance gain implied by the release.

## What Existing Applications Should Review {#what-existing-applications-should-review}

The integration boundary is the most useful place to start an upgrade review. Code that manually assembles messages needs closer attention than code that only defines application tools.

For modern HTTP requests, review `MCP-Protocol-Version` and `Mcp-Method`, plus `Mcp-Name` where required. These must agree with the request body. The [header middleware](https://github.com/laravel/mcp/blob/v1.0.0/src/Server/Middleware/ValidateMcpHeaders.php) rejects mismatches with HTTP 400, so endpoint tests must reflect the protocol they exercise.

The [0.9-to-1.0 upgrade guide](https://github.com/laravel/mcp/blob/v1.0.0/UPGRADE.md) also identifies removed session APIs: `Request::sessionId()`, `Request::setSessionId()`, and `MCP-Session-Id`. Applications needing correlation must supply their own identifier. Review listeners for the removed `SessionInitialized` event and OAuth storage that assumes a client secret is always present.

These checks help separate application behavior from transport assumptions. Keep the actual client versions you use in the review, alongside tests for input validation, visibility, and access control.

## Conclusion {#conclusion}

Laravel MCP 1.0 brings a stable release together with changes that matter when applications and AI clients interact. The strongest takeaways are practical:

- **Protocol evolution.** Modern requests carry protocol context individually, while legacy client support provides a transition path.
- **Authentication interoperability.** OAuth challenges and client metadata improve how connections are established and presented to users.
- **More focused testing.** Registration assertions cover capability visibility, while the package's conformance runner helps detect protocol regressions.
- **Useful input and caching improvements.** Nested arguments become easier to read, and opted-in clients can reuse responses when the server permits it.
- **A concrete upgrade review.** Check transport assumptions and application boundaries before adopting the new release. For the practical server design behind this discussion, return to our [Laravel MCP content server tutorial](https://qadrlabs.com/post/build-an-mcp-server-in-laravel-so-ai-agents-can-query-your-content).
