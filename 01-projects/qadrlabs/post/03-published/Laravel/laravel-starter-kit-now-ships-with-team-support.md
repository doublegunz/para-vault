---
title: "Laravel Starter Kit Now Ships with Team Support"
slug: "laravel-starter-kit-now-ships-with-team-support"
category: "Laravel"
date: "2026-03-30"
status: "published"
---

On March 27, 2026, the Laravel team shipped team support for all official starter kits: React, Vue, Svelte, and Livewire. This is a feature that many developers have been waiting for since the new starter kits replaced Jetstream in Laravel 12. Jetstream had built-in teams functionality, but the new kits launched without it. That gap is now officially closed.

When team support is enabled, each user belongs to one or more teams and has a current active team. New users are automatically assigned a personal team upon registration. The starter kits also include ready-made screens for creating teams, switching between teams, inviting members, and managing team settings.

## Overview {#overview}

### What You'll Learn

- How to update the Laravel installer to get team support
- How to create a new Laravel project with team support enabled
- What the team feature looks like out of the box

### What You'll Need

- PHP 8.3 or higher
- Composer installed globally
- Laravel Installer (will be updated in this tutorial)
- A browser to verify the result

![preview](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/preview.webp)


## Update Laravel Installer {#update-installer}

Team support requires Laravel Installer version 5.25.0 or higher. Check your current version first:

```bash
laravel --version
```

Output:

```
laravel --version
Laravel Installer 5.24.9
```

If your version is below 5.25.0, run the update command:

```bash
composer global update laravel/installer
```

Verify the update was successful:

```bash
laravel --version
```

Output:

```
laravel --version
Laravel Installer 5.25.1
```


## Create a New Project {#create-project}

Create a new Laravel project using the `laravel new` command:

```bash
laravel new laravel-teams
```

The installer will prompt you to choose a starter kit. In this example we choose the Vue starter kit, then press `Enter` to continue.

```
laravel new laravel-teams

██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

┌ Which starter kit would you like to install? ────────────────┐
│   ○ None                                                     │
│   ○ React                                                    │
│   ○ Svelte                                                   │
│ › ● Vue                                                      │
│   ○ Livewire                                                 │
└──────────────────────────────────────────────────────────────┘
```

Next, choose the authentication provider. Select `Laravel's built-in authentication` and press `Enter`.

```
laravel new laravel-teams

██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

┌ Which starter kit would you like to install? ────────────────┐
│ Vue                                                          │
└──────────────────────────────────────────────────────────────┘

┌ Which authentication provider do you prefer? ────────────────┐
│ › ● Laravel's built-in authentication                        │
│   ○ WorkOS (Requires WorkOS account)                         │
│   ○ No authentication scaffolding                            │
└──────────────────────────────────────────────────────────────┘
```

This is where team support comes in. A new prompt appears asking whether to add teams support to your application. Select `Yes` and press `Enter`.

```
laravel new laravel-teams

██╗       █████╗  ██████╗   █████╗  ██╗   ██╗ ███████╗ ██╗
██║      ██╔══██╗ ██╔══██╗ ██╔══██╗ ██║   ██║ ██╔════╝ ██║
██║      ███████║ ██████╔╝ ███████║ ██║   ██║ █████╗   ██║
██║      ██╔══██║ ██╔══██╗ ██╔══██║ ╚██╗ ██╔╝ ██╔══╝   ██║
███████╗ ██║  ██║ ██║  ██║ ██║  ██║  ╚████╔╝  ███████╗ ███████╗
╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝

┌ Which starter kit would you like to install? ────────────────┐
│ Vue                                                          │
└──────────────────────────────────────────────────────────────┘

┌ Which authentication provider do you prefer? ────────────────┐
│ Laravel's built-in authentication                            │
└──────────────────────────────────────────────────────────────┘

┌ Would you like to add teams support to your application? ────┐
│ ● Yes / ○ No                                                 │
└──────────────────────────────────────────────────────────────┘
```

The remaining prompts — testing framework and other preferences — can be set freely to whatever suits your project.

```
┌ Which testing framework do you prefer? ──────────────────────┐
│ › ● Pest                                                     │
│   ○ PHPUnit                                                  │
└──────────────────────────────────────────────────────────────┘
```

Output:

```
┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
│ ● Yes / ○ No                                                        │
└─────────────────────────────────────────────────────────────────────┘
```

Wait for the project creation process to finish.

Output:

```

   INFO  Application ready in [laravel-teams]. You can start your local development using:

➜ cd laravel-teams
➜ composer run dev
```


## Verify Team Support {#verify}

Navigate into the project directory:

```bash
cd laravel-teams
```

Start the development server:

```bash
composer run dev
```

Output:

```
composer run dev
> Composer\Config::disableProcessTimeout
> npx concurrently -c "#93c5fd,#c4b5fd,#fb7185,#fdba74" "php artisan serve" "php artisan queue:listen --tries=1 --timeout=0" "php artisan pail --timeout=0" "npm run dev" --names=server,queue,logs,vite --kill-others
[vite]
[vite] > dev
[vite] > vite
[vite]
[logs]
[logs]    INFO  Tailing application logs.                        Press Ctrl+C to exit
[logs]                                                Use -v|-vv to show more details
[queue]
[queue]    INFO  Processing jobs from the [default] queue.
[queue]
[vite] Inertia SSR dev endpoint: /__inertia_ssr
[server]
[server]    INFO  Server running on [http://127.0.0.1:8000].
[server]
[server]   Press Ctrl+C to stop the server
[server]
[vite] 5:47:19 PM [vite] (client) info: Types generated for actions, routes, form variants
[vite]   Plugin: @laravel/vite-plugin-wayfinder
[vite]
[vite]   VITE v8.0.3  ready in 788 ms
[vite]
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[vite]
[vite]   LARAVEL v13.2.0  plugin v3.0.0
[vite]
[vite]   ➜  APP_URL: http://localhost:8000
```

Open `http://localhost:8000` in your browser and go to the register page to create a new account.

![01 register account](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/01-register-account.webp)

After registering, you will land on the dashboard. Notice the new **Team** menu item in the sidebar.

![02 account registered](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/02-register-success.webp)

Click on `Admin's Team` in the sidebar. A `+ New Team` button is available to create additional teams.

![03 click menu](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/03-click-team-menu-at-sidebar.webp)

A modal form appears. Enter a team name and click **Create Team**.

![04 create new team](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/04-create-new-team.webp)

After the team is created, you are taken to the team settings page.

![05 team created](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/05-team-created.webp)

Click the **Teams** sub-menu to see the full list of teams available to your account.

![06 access team list page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-starter-kit-team-support/06-access-team-list-page.webp)


## How Teams Work in the Starter Kit {#how-it-works}

It is worth understanding a few things about how the team implementation works before building on top of it.

**URL-based team context.** When a route is scoped to the current team, the team's slug is included in the URL. For example, the dashboard route becomes `/{current_team}/dashboard`, and team management pages use routes like `settings/teams/{team}`. This is a meaningful improvement over Jetstream's session-based approach, which made it impossible for a user to operate two different team contexts in separate browser tabs at the same time.

**Automatic team assignment.** New users are given a personal team automatically during registration. No additional setup is needed for the first team to exist.

**Built-in access control.** When using the `{current_team}` and `{team}` route parameters, the starter kit automatically verifies that the authenticated user belongs to the requested team before granting access to the route. You get this protection out of the box without writing additional middleware or policies for team membership.

**URL helpers.** To make generating team-aware URLs more convenient, the starter kit registers URL defaults for the authenticated user's current team, so you do not need to manually pass the team slug every time you generate a URL.


## Conclusion {#conclusion}

Team support is now available across all four official Laravel starter kits: React, Vue, Svelte, and Livewire. This closes the last major feature gap between the new starter kits and the old Jetstream setup, with a cleaner implementation to boot.

- **All four starter kits support teams**: React, Vue, Svelte, and Livewire
- **Enabled at project creation time** via a single prompt in the Laravel installer
- **URL-based team context** replaces the session-based approach, allowing multiple team contexts in separate browser tabs
- **Registration automatically creates a personal team** for each new user
- **Built-in team management screens** for creating, switching, inviting, and managing teams are included out of the box
- **Requires Laravel Installer 5.25.0 or higher** — update with `composer global update laravel/installer` before creating new projects