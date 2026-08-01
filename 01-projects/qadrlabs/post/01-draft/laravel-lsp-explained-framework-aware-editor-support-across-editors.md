# Laravel LSP Explained: Framework-Aware Editor Support Across Editors

A PHP language server can understand classes, methods, parameters, and types, but a Laravel application contains another layer of meaning. A string passed to `route()` may name a route, a value passed to `view()` may point to a Blade file, and a key passed to `config()` may refer to a deeply nested configuration value. When an editor treats those values as ordinary strings, developers lose useful completion, navigation, and error detection.

Laravel LSP addresses that gap with an official, framework-aware language server. It was one of the developer tooling announcements covered in our [Laracon US 2026 recap](https://qadrlabs.com/post/everything-announced-at-laracon-us-2026-laravel-ai-and-cloud-updates). Instead of keeping Laravel intelligence inside one editor, the language server makes it available through the standard Language Server Protocol.

This article explains what Laravel LSP is, which parts of a Laravel application it understands, how editors communicate with it, and what its early development status means for developers who want to try it today.

## Overview {#overview}

This is an informational first look rather than a sequential installation tutorial. You will build a practical mental model of Laravel LSP, examine the capabilities currently documented by the project, and see compact configurations that can be adapted to an editor you already use.

### What You'll Build

- A clear mental model of the editor client, Laravel language server, and application project.
- A small Laravel example that exposes routes, views, and configuration values to editor assistance.
- A minimal Laravel LSP connection for an editor that supports custom language servers.

### What You'll Learn

- What the Language Server Protocol provides and why Laravel needs framework-aware analysis.
- Which Laravel features currently receive completions, hover information, diagnostics, links, definitions, or quick fixes.
- How Laravel LSP finds the correct PHP environment for local and containerized applications.
- Which editors and operating systems the official project supports.
- Why the current pre-1.0 version should shape expectations.

### What You'll Need

- A Laravel application. The examples in this article are suitable for Laravel 13.
- PHP 8.3 or newer for a Laravel 13 development environment. Laravel LSP itself currently declares PHP 8.2 or newer.
- [Composer](https://getcomposer.org/) for the global installation.
- An editor with Laravel LSP integration or support for custom language servers.
- Basic familiarity with Laravel routes, Blade views, and configuration helpers.

## What Is the Language Server Protocol? {#what-is-the-language-server-protocol}

The Language Server Protocol, commonly shortened to LSP, defines how an editor communicates with a separate program that understands a programming language or framework. The editor is the client. It knows how to display a completion menu, underline a problem, open a definition, or show documentation. The language server analyzes the project and sends the relevant information back in a standard format.

This separation prevents every editor from having to implement the same language intelligence independently. A single server can provide capabilities such as:

- **Completions.** Suggest valid values at the current cursor position.
- **Hover information.** Show useful details without opening another file.
- **Diagnostics.** Report invalid or unresolved references while editing.
- **Document links.** Turn framework references into navigable locations.
- **Go to definition.** Open the source represented by a symbol or framework value.
- **Code actions.** Offer a targeted fix for a recognized problem.

An editor may expose those features through different keyboard shortcuts or interface elements, but the underlying request and response model remains consistent. This is what lets Laravel provide official framework knowledge without limiting that knowledge to one editor.

## Why Laravel Needs Framework-Aware Language Support {#why-laravel-needs-framework-aware-language-support}

Laravel makes extensive use of conventions and string-based identifiers. Those APIs are expressive at runtime, but their meaning is not always visible to a tool that only understands PHP syntax and types.

Consider a route and a view registered in a small application:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::view('/dashboard', 'dashboard')->name('dashboard');
```

The application can then refer to both identifiers from a Blade view:

```blade
<a href="{{ route('dashboard') }}">
    {{ config('app.name') }}
</a>
```

All three strings have Laravel-specific meaning. `dashboard` is a named route in the first helper call, `app.name` is a configuration key, and the `dashboard` value registered by `Route::view()` points to `resources/views/dashboard.blade.php`. A generic PHP analyzer may understand the helper signatures, but it cannot necessarily confirm those application-defined values.

Laravel LSP indexes project data so it can provide assistance based on the application itself. The editor can suggest the `dashboard` route, display information about it, warn about an unknown route name, or link a view reference to the corresponding Blade file. General PHP tooling still remains useful for PHP types and symbols. Laravel LSP adds knowledge of the framework layer on top of that foundation.

## How Laravel LSP Works {#how-laravel-lsp-works}

Laravel LSP communicates with its editor client over standard input and output, usually described as `stdio`. The editor launches the `laravel-lsp` command, sends protocol requests to the process, and renders the responses in its own interface.

The connection can be summarized as:

```text
Editor or LSP client
        |
        | Language Server Protocol over stdio
        v
Laravel LSP
        |
        | PHP command used to index project data
        v
Laravel application
```

The [official README](https://github.com/laravel/lsp) recommends launching the server from the Laravel project root whenever possible. That location gives the server the context it needs to find `artisan`, `composer.json`, application files, and project data.

Laravel projects do not all execute PHP in the same way, so the server can detect several common development environments. In its default `auto` mode, it tries Herd, Valet, Sail, Lando, DDEV, and then local PHP. If none of those checks succeeds, it falls back to `php`. An explicit PHP command can override detection when a project has a custom setup.

## What Laravel LSP Can Understand {#what-laravel-lsp-can-understand}

The first-party server covers more than autocomplete. Its documented features combine several LSP capabilities depending on the Laravel area being analyzed.

| Laravel area | Editor assistance |
| --- | --- |
| Routes | Completions, hover information, diagnostics, and links |
| Views and Blade | Completions, hover information, diagnostics, links, and fixes |
| Translations | Key, locale, and parameter completions plus hover information |
| Configuration and environment variables | Completions, hover information, diagnostics, links, and selected fixes |
| Assets and Mix | Completions, hover information, diagnostics, and links |
| Middleware | Completions, hover information, diagnostics, and links |
| Inertia | Page and property completions, links, and diagnostics |
| Livewire components | Completions, hover information, and links |
| Authorization and policies | Completions, hover information, diagnostics, and links |
| Container bindings | Completions, hover information, diagnostics, and links |
| Controller actions | Completions, diagnostics, and links |
| Eloquent and validation rules | Completions |

These features are most useful when identifiers come from the current application. For example, route completion can show names that actually exist in the route collection, while diagnostics can identify a route name that cannot be resolved. View support can connect a string passed to `view()` with its Blade file, and translation support can understand keys and parameters instead of treating the entire call as plain text.

The same idea extends into ecosystem tools. Inertia page and property assistance helps connect backend responses with frontend pages. Livewire support recognizes application components. Authorization support gives policies and abilities more editor context, while container binding support helps with service resolution patterns that would otherwise require searching through providers manually.

Not every Laravel area provides every LSP capability. The official feature table is the safest reference for current coverage, especially while development is moving quickly.

## Using Laravel LSP Across Editors {#using-laravel-lsp-across-editors}

Laravel distributes the language server as a global Composer package. The official installation command is:

```bash
composer global require laravel/lsp
```

Composer's global vendor binary directory must be available on your `PATH` so an editor can launch `laravel-lsp`. The exact directory depends on the operating system and Composer configuration. Running `composer global config bin-dir --absolute` displays the directory for the current machine.

Laravel provides editor integrations for [VS Code](https://github.com/laravel/vs-code-extension), Cursor through the compatible VS Code extension, [Sublime Text](https://github.com/laravel/sublime-extension), and [Zed](https://github.com/laravel/zed-extension). These extensions act as clients and handle the editor-specific connection to the server.

Editors with custom LSP configuration can launch the same command directly. Neovim 0.11 or newer can register Laravel LSP with this configuration:

```lua
vim.lsp.config("laravel_lsp", {
    cmd = { "laravel-lsp" },
    filetypes = { "php", "blade" },
    root_markers = { "artisan", "composer.json", ".git" },
})

vim.lsp.enable("laravel_lsp")
```

The command starts the server, the file types restrict activation to PHP and Blade files, and the root markers help Neovim locate the project directory.

OpenCode can also register Laravel LSP as a custom server in `opencode.json`:

```json
{
    "$schema": "https://opencode.ai/config.json",
    "lsp": {
        "laravel-lsp": {
            "command": ["laravel-lsp"],
            "extensions": [".php", ".blade.php"]
        }
    }
}
```

This configuration tells OpenCode which command to launch and which file extensions should be associated with it. Both examples use the same server binary, even though the clients configure and present it differently.

## Configuration and Project Environments {#configuration-and-project-environments}

Editor clients pass Laravel LSP configuration through the protocol's `initializationOptions` object. Every option is optional, so most projects can begin with automatic detection and the defaults.

The main server options currently include:

- **`phpEnvironment`.** Selects `auto`, `herd`, `valet`, `sail`, `lando`, `ddev`, or `local` PHP detection. Its default is `auto`.
- **`phpCommand`.** Supplies an explicit command and its arguments, such as `["php"]` or `["./vendor/bin/sail", "php"]`. A non-empty value takes precedence over `phpEnvironment`.
- **`definitionProvider`.** Controls whether the server advertises definition support. It is enabled by default.
- **`pestGenerateDocBlocks`.** Controls automatic generation and updating of Pest helper docblocks. It is enabled by default.
- **`pestHelperFilePath`.** Changes the generated Pest helper path from its default at `storage/framework/testing/_pest.php`.

The explicit `phpCommand` option is especially useful when automatic detection does not match how a team runs PHP. A Sail project, for example, can point indexing at `./vendor/bin/sail php`, while another container workflow can provide its own command and arguments.

Feature options are more granular. Completion, diagnostics, hover information, document links, and code actions can be disabled independently for supported Laravel features. All documented feature flags default to `true`. This gives teams a way to avoid duplicate behavior when another editor tool already owns a particular capability.

## Current Status and Supported Platforms {#current-status-and-supported-platforms}

Laravel LSP is public and usable, but its version communicates an important expectation. The latest verified tag when this article was prepared was [`v0.0.29`](https://github.com/laravel/lsp/releases/tag/v0.0.29), published on July 29, 2026. A `0.0.x` version indicates that the project is still before a stable 1.0 release, so features, configuration names, and integration details may continue to change.

The package's [`composer.json`](https://github.com/laravel/lsp/blob/main/composer.json) requires PHP 8.2 or newer. Laravel currently publishes builds for:

- macOS on Arm64 and x64.
- Linux on Arm64 and x64.
- Windows on x64.

Those are the platforms listed by the project today, not a promise about every environment that may work. Developers adopting the server early should check the repository README and tags before relying on a specific configuration in team documentation.

The rapid sequence of pre-1.0 tags also shows that the implementation is active. That makes the repository itself the most reliable source for current installation, feature, and compatibility information while broader Laravel documentation is still developing.

## Why Laravel LSP Matters {#why-laravel-lsp-matters}

Laravel LSP changes where framework intelligence lives. An editor extension can still provide installation, settings, commands, and interface integration, but the server holds the Laravel-aware behavior behind a standard protocol. That distinction makes it possible for several editors to benefit from the same core implementation.

For individual developers, the immediate value is faster navigation and earlier feedback around identifiers that Laravel resolves at runtime. A misspelled route, view, configuration key, or middleware name can become visible during editing instead of appearing after the application reaches that code path.

For teams, a first-party server can make Laravel-specific assistance more consistent across editor preferences. A team does not need every developer to use the same interface before they can share the same underlying understanding of routes, views, translations, Blade components, and other framework concepts.

There is also a broader ecosystem implication. This is an editorial interpretation rather than an official roadmap, but moving Laravel intelligence into a reusable language server creates a foundation for more editor clients and coding tools. The OpenCode configuration already demonstrates that the server can serve more than traditional graphical editors.

Laravel LSP does not make general PHP analysis unnecessary, and its pre-1.0 status means it should be evaluated with realistic expectations. Its significance is that Laravel now has an official place to encode framework-specific editor knowledge and deliver it through an established standard.

## Conclusion {#conclusion}

Laravel LSP brings application-aware assistance to the point where developers spend much of their day: the editor. It understands Laravel concepts that are difficult to infer from PHP syntax alone, while the Language Server Protocol lets that intelligence reach multiple clients.

- **Framework-aware analysis.** Laravel LSP recognizes routes, views, translations, configuration, middleware, bindings, and other application concepts instead of treating their identifiers as ordinary strings.
- **Multiple editor capabilities.** The server can provide completions, hover information, diagnostics, links, definitions, and selected quick fixes according to the feature being analyzed.
- **Editor independence.** Official extensions and custom LSP configurations connect different editors to the same Laravel-aware server.
- **Flexible PHP environments.** Automatic detection covers popular Laravel development tools, while an explicit command supports custom and containerized workflows.
- **Early development status.** The current `0.0.x` versions are usable but still evolving, so the official repository should remain the source of truth.
- **Complementary tooling.** Laravel LSP adds framework knowledge alongside general PHP language analysis rather than replacing it.
