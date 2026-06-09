## How to Use This Book {#how-to-use-this-book}

This book is built to be read in order, from the first chapter to the last. Each chapter assumes you have done the one before it, because the application grows one chapter at a time. This short section explains how the book is laid out, what you need installed, the conventions used in the text, and how to get the source code.

### Read in Order, Build as You Go {#read-in-order}

The book is organized into six parts and twelve chapters. Each chapter is a single step in building Catatku, and each step builds directly on the last. You will get the most out of the book by typing the code yourself rather than copying and pasting. The small friction of typing is where a lot of the learning actually happens.

At the end of every chapter you will find three things:

- **Key Takeaways**, a short list of the core ideas from the chapter so they stick.
- **Checkpoint**, a quick list to confirm your app is in the right state before moving on.
- **Exercises**, a few challenges to extend the app on your own. Full solutions are in the **Exercise Solutions** section at the back, so try them yourself first.

### What You Will Need {#what-you-will-need}

Before you start building, make sure you have the following available. Chapter 2 walks through installing all of it step by step, so do not worry if you have none of it yet.

- **PHP 8.3 or higher.** Laravel 13 requires at least PHP 8.3.
- **Composer.** The package manager for PHP. Laravel and its dependencies are installed through Composer.
- **MySQL.** The database we will use to store user accounts and journal entries.
- **A code editor.** VS Code is the most popular choice and has excellent PHP and Laravel extensions.

Chapter 2 uses **Laragon 6** on Windows, which bundles PHP, MySQL, and a local server in a single free installer. If you are on macOS or Linux, install PHP, Composer, and MySQL with your usual package manager, then rejoin the chapter at the project creation step.

### Code Conventions {#code-conventions}

Code in this book follows a few simple conventions so you always know what you are looking at.

Commands you run in a terminal are shown in a shell block:

```bash
php artisan serve
```

Application code is shown in a language block, with the file path noted in the surrounding text so you know where it goes:

```php
Route::get('/', function () {
    return view('home');
});
```

When only part of a file changes, only the relevant lines are shown rather than the whole file. The text around the snippet tells you where the change belongs.

You will also see two kinds of callout throughout the book:

> **Security note:** highlights a decision that protects user data or the application. These are worth slowing down for.

> **Key Takeaways:** at the end of each chapter, the core ideas distilled into a short list.

### Getting the Source Code {#getting-the-source-code}

You can build the entire app by following the text alone. If you get stuck, the complete source code is available so you can compare your work against a known-good version.

The repository is organized so that each chapter has its own checkpoint, letting you jump in at the start of any chapter with the app in the correct state. Full instructions for downloading the code, the repository layout, and how to run a finished checkpoint are in **Appendix D: Getting the Source Code** at the back of the book.

A reminder from the license: the source code is yours to use in your own personal and commercial projects. Please do not redistribute the book itself.

### If You Get Stuck {#if-you-get-stuck}

Programming means meeting errors. That is normal, not a sign you are doing it wrong. When something breaks, read the error message carefully, because Laravel's messages are usually specific about what went wrong. **Appendix B: Troubleshooting Common Errors** collects the problems beginners hit most often, with fixes. **Appendix C: Glossary** defines the terms used in the book if any are unfamiliar.

With that, you are ready. Head to Chapter 1 to see exactly what you are about to build.
