---
title: "Practical Codelab: Building a Mobile Application with Laravel and NativePHP"
slug: "practical-codelab-building-a-mobile-application-with-laravel-and-nativephp"
category: "Laravel"
date: "2026-03-06"
status: "published"
---

## Overview {#overview}

In a [previous article](https://qadrlabs.com/post/nativephp-membangun-aplikasi-desktop-dan-mobile-native-dengan-php-dan-laravel), we explored what NativePHP is, how it works under the hood, and why it matters for the PHP community. We discussed its architecture—an embedded PHP runtime bundled directly into native iOS and Android shells—and how it bridges Laravel's powerful backend capabilities with native platform APIs like camera, biometrics, and push notifications.

Now it's time to get hands-on. In this codelab, you will walk through the entire process of setting up a Laravel project and turning it into a working Android mobile application using NativePHP. Rather than building a complex feature set, this tutorial focuses on the foundational workflow: creating a project, installing NativePHP, running the app on an emulator, and verifying that core Laravel features (like authentication) work seamlessly in a native mobile context.

This is an important first step. Once you are comfortable with this workflow, you can begin layering in native features such as camera access, local storage, and push notifications using NativePHP's facade-based API.

### What You'll Build

A fully functional mobile application powered by Laravel 12 and NativePHP, running on an Android emulator. The app uses the React starter kit for its UI and includes working authentication (register, login, logout, and dashboard).

![Initial app screen](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/01-tampilan-awal-laravel.webp)

### What You'll Learn

- How to create a new Laravel project configured for mobile development.
- How to install and configure the `nativephp/mobile` package.
- How to run your Laravel app as a native Android application on an emulator.
- How the development workflow differs between web and native contexts.

### What You'll Need

- A computer running Linux, macOS, or Windows with at least 8 GB of RAM.
- PHP 8.3 or higher and Composer installed.
- Node.js 22 or higher and npm installed.
- Android SDK and at least one Android emulator configured (via Android Studio or command-line tools).
- The Laravel installer (`composer global require laravel/installer`).
- Basic familiarity with Laravel (routing, controllers, Artisan commands).


## Step 1: Create a New Laravel Project {#step-create-project}

Every NativePHP mobile app starts as a standard Laravel project. This means you can develop your UI and business logic in the browser first, then package it as a native app later. Let's begin by scaffolding a fresh Laravel project using the Laravel installer.

Run the following command in your terminal:

```bash
laravel new laravel-app
```

The installer will guide you through several configuration prompts. Here is a walkthrough of each one.

**Choosing a Starter Kit.** Laravel 12 offers several frontend starter kits out of the box. For this codelab, select **React**. This gives us a fully functional single-page application with Inertia.js, which will render nicely inside NativePHP's native web view.

```
 ┌ Which starter kit would you like to install? ────────────────┐
 │   ○ None                                                     │
 │ › ● React                                                    │
 │   ○ Svelte                                                   │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘
```

You could also choose Vue, Svelte, or Livewire—NativePHP is agnostic about your frontend stack since it renders everything through a native web view. However, we use React here for demonstration purposes.

**Choosing an Authentication Provider.** Select **Laravel's built-in authentication**. This is the simplest option and doesn't require any external service accounts.

```
 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘
```

**Choosing a Testing Framework.** Select **Pest** (or PHPUnit if you prefer). This doesn't affect the NativePHP setup.

```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘
```

**Laravel Boost (Optional).** Laravel may ask whether you'd like to install Laravel Boost for AI-assisted coding. You can select **Yes** if you're curious, or skip it—it has no impact on NativePHP.

```
 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ ● Yes / ○ No                                                        │
 └─────────────────────────────────────────────────────────────────────┘
```

If you chose Yes, you'll see follow-up prompts about Boost features (AI Guidelines, Agent Skills, MCP Server Configuration) and third-party guidelines. Select whichever options interest you.

**Running npm install.** When prompted to run `npm install` and build assets, select **Yes**. This ensures that the React frontend is compiled and ready.

```
 ┌ Would you like to run npm install and npm … ───┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘
```

Once everything finishes, you'll see a success message:

```
✓ built in 5.70s
   INFO  Application ready in [laravel-app]. You can start your local development using:

➜ cd laravel-app
➜ composer run dev
```

At this point, you have a fully functional Laravel 12 application with React and authentication scaffolding. You could run `composer run dev` and open it in a browser to verify everything works. In the next step, we'll transform this web app into a native mobile application.


## Step 2: Install the NativePHP Mobile Package {#step-2-install-nativephp}

With our Laravel project ready, it's time to add NativePHP. The `nativephp/mobile` package handles everything needed to run your Laravel app as a native Android (or iOS) application: it bundles an embedded PHP runtime, creates the native project scaffolding, and provides Artisan commands for building and running the app.

First, navigate into your project directory:

```bash
cd laravel-app
```

Then install the NativePHP mobile package via Composer:

```bash
composer require nativephp/mobile
```

This command pulls in the `nativephp/mobile` package along with its dependencies, including the statically-compiled PHP binary that will be embedded into your mobile app. This embedded runtime is what allows your Laravel code to execute directly on the device, without needing a remote server.

### Running the NativePHP Installer

After the package is installed, run the NativePHP installer. This Artisan command sets up and configures your Laravel application to work with the native mobile shell:

```bash
php artisan native:install
```

The installer will ask you a couple of questions.

**Setting the App Bundle ID.** Every mobile app distributed through the App Store or Google Play needs a unique bundle identifier. This is typically in reverse domain notation (e.g., `com.yourcompany.yourapp`). Enter something meaningful for your project:

```
 ┌ What should your app bundle ID be? ──────────────────────────┐
 │ com.example.sampleapp                                        │
 └──────────────────────────────────────────────────────────────┘
```

This value is stored in your `.env` file as `NATIVEPHP_APP_ID` and uniquely identifies your app on the platform stores.

**ICU Support.** The installer asks whether to include an ICU-enabled PHP binary. ICU (International Components for Unicode) is required if you use packages like Filament or PHP's `intl` extension. It adds roughly 30 MB to your app size. For this basic tutorial, select **No**:

```
 ┌ Include ICU-enabled PHP binary for Filament/intl support? ───┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘
```

After answering these prompts, the installer performs several automated steps. Here is the complete output you can expect:

```
  Installing NativePHP for Mobile

  Creating Android project ...................................... 50.30ms DONE
  ICU support ....................................................... Disabled
  Downloading Android PHP binaries ................................... 1s DONE
  Download size ........................................................ 7.6MB
  Extracting PHP binaries ...................................... 152.29ms DONE
  Installing Android libraries .................................. 13.33ms DONE
  Copying native CLI wrapper ..................................... 0.06ms DONE

  NativePHP for Mobile installed successfully!
```

Let's break down what happened here. The installer created an Android project inside a new `nativephp/` directory at the root of your Laravel project. This directory contains a complete Android Studio project (Gradle build files, Kotlin source code, and configuration) that acts as the native shell for your app. It also downloaded a pre-compiled PHP binary (only 7.6 MB in this case, since we skipped ICU) that will be bundled into the APK. This binary is what executes your Laravel code on the device itself.

### Verifying the Environment Variable

Open your `.env` file and confirm that the new environment variable has been added:

```
NATIVEPHP_APP_ID=com.example.sampleapp
```

This ID is used during the build process to identify your application.

### Configuring the Android SDK Path

There is one manual step required. Open the file `nativephp/android/local.properties` and add the path to your Android SDK:

```properties
sdk.dir=/home/your-username/Android/Sdk
```

Replace `/home/your-username/Android/Sdk` with the actual path to your Android SDK installation. On macOS, this is typically `~/Library/Android/sdk`. On Windows, it might be `C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk`. This tells the Gradle build system where to find the Android toolchain.


## Step 3: Run the Project {#step-3-run-project}

Now comes the exciting part—running your Laravel application as a native Android app. Use the following Artisan command:

```bash
php artisan native:run
```

If no physical device is connected, NativePHP will detect this and offer to launch an emulator for you:

```
 No devices found. Attempting to launch an emulator...

 ┌ Select an emulator to launch ────────────────────────────────┐
 │ › ● Medium_Phone_API_36.1                                    │
 └──────────────────────────────────────────────────────────────┘
```

Select your preferred emulator and wait for the build process to complete. Here is what the full output looks like:

```
  Running NativePHP for Android

 Build log: /home/your-username/laravel-app/nativephp/android-build.log

  Updating Android configuration ................................. 2.27ms DONE
  Copying Laravel source ....................................... 680.26ms DONE
  Installing Composer dependencies ................................... 2s DONE
  Optimizing autoloader .............................................. 1s DONE
  Creating bundle archive ............................................ 4s DONE
  Bundle size ....................................................... 42.18 MB
  Build type ........................................................... debug
  App version .......................................................... 1.0.0

BUILD SUCCESSFUL in 28s
40 actionable tasks: 40 executed
  App launched!
```

There's a lot happening under the hood in this step, so let's unpack it. First, NativePHP copies your entire Laravel source code into the Android project's asset directory. Then it runs `composer install` with an optimized autoloader specifically for the mobile context—this ensures only the necessary files are included. Next, it creates a compressed bundle archive of your application (42.18 MB in this case, which includes your code, vendor dependencies, and the PHP runtime). Finally, Gradle compiles the Android project and deploys the debug APK to the emulator.

The first build may take a minute or two because Gradle needs to download its own dependencies. Subsequent builds are faster thanks to caching.


## Step 4: Test the Application {#step-4-test-project}

With the app running on the emulator, let's verify that everything works correctly. Since we chose the React starter kit, the app displays the default Laravel 12 welcome page—the same one you would see in a browser.

**The Home Screen.** The initial screen shows Laravel's default landing page, rendered inside the native web view. The UI is identical to what you'd see in a mobile browser, but it's now running as a standalone native application with its own app icon and process.

![Initial app screen](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/01-tampilan-awal-laravel.webp)

**Testing Registration.** Tap the link to navigate to the registration page. The React starter kit provides a fully styled registration form with name, email, and password fields.

![Register page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/02-tampilan-halaman-register.webp)

Fill in the registration form with test data and submit it:

![Filling out the register form](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/03-test-register.webp)

After tapping "Create Account," the app navigates to the dashboard—confirming that the authentication system, database (SQLite by default), and session handling all work correctly inside the native context.

![Registration successful - dashboard shown](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/04-register-success.webp)

**Testing the Sidebar and Logout.** Tap the sidebar toggle to open the navigation menu. Notice that the sidebar renders the same way it would on a mobile browser—this is because the native web view behaves like a responsive viewport.

![Sidebar open](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/05-test-buka-sidebar.webp)

Tap "Log out" to end the session, then navigate to the login page and sign in with the credentials you just created.

![Login page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/06-test-login.webp)

After logging in, the app returns to the dashboard—confirming that both registration and login flows work as expected.

![Login successful - dashboard shown](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/nativephp/setup-use-nativephp/07-login-success.webp)

What's remarkable here is that we didn't write a single line of mobile-specific code. The entire authentication system—registration, login, session management, CSRF protection—is handled by Laravel exactly as it would be in a web application. NativePHP's embedded PHP runtime executes all of this locally on the device.


## Understanding the Development Workflow {#development}

Now that you have a working NativePHP mobile app, it's important to understand how the development workflow differs from traditional web development.

**Develop in the browser first.** For most of your day-to-day development—building UI components, writing business logic, creating API endpoints—you should work in the browser using the standard Laravel development server (`composer run dev` or `php artisan serve`). This gives you the fast feedback loop you're used to: hot module replacement for your frontend, instant page reloads, and access to browser developer tools.

**Build natively when testing native features.** When you need to test features that depend on the native platform—such as camera access, biometric authentication, push notifications, or device-specific behavior—you must compile and run the app on an emulator or physical device using `php artisan native:run`. Every time you make changes to your code and want to see them reflected in the native app, you need to re-run this command. Unlike browser development, there is no live reload in the native context; each iteration requires a fresh build.

This two-phase workflow is a pragmatic approach. It lets you iterate rapidly on the majority of your application using familiar web tools, while reserving the slower native build cycle for the specific features that require it. As NativePHP continues to mature, the build times and developer experience in the native context will likely improve, but even now, the workflow is manageable for most projects.


## Conclusion {#conclusion}

In this codelab, you went from a blank terminal to a working native Android application powered by Laravel and NativePHP. Let's recap what we covered and the key takeaways.

You created a standard Laravel 12 project with the React starter kit—the same kind of project you might build for any web application. You then installed the `nativephp/mobile` package, which added an embedded PHP runtime and generated the Android project scaffolding. With a single `php artisan native:run` command, your web application was bundled, compiled, and deployed to an Android emulator as a native app. Finally, you verified that core Laravel features like registration, login, and session management work seamlessly in the native context without any mobile-specific code changes.

Here are the key points to remember. First, NativePHP lowers the barrier to mobile development for PHP developers by letting you reuse your existing Laravel knowledge and codebase. Second, the embedded PHP runtime means your Laravel code runs directly on the device—there is no remote server required for the app to function. Third, the development workflow is designed around building in the browser first, then compiling to native when needed. And finally, this tutorial covered only the foundation; NativePHP provides facade-based APIs for native features like `Camera`, `Biometrics`, `PushNotifications`, `Geolocation`, and `SecureStorage` that you can layer on top of this base setup.

From here, you might explore adding native features using NativePHP's plugin system, setting up Bifrost for automated cloud builds and store distribution, or adapting an existing Laravel application for mobile deployment. The foundation you built today is the same starting point for all of these paths.