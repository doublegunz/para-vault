# Appendix D: Getting the Source Code

You can build the entire Catatku app by typing along with the book, and typing the code yourself is genuinely the best way to learn. But it helps to have a known-good copy to compare against when something does not work, or to jump straight to the start of a chapter if you want to skip ahead. This appendix explains how the source code is organized and how to use it.

## Where to Download {#where-to-download}

The complete source code for Catatku is available to you as a book reader. The download link is provided on the book's product page at qadrlabs.com, on the same page where you bought the book. If you bought through Gumroad or LemonSqueezy, the link is included with your purchase receipt.

> A reminder from the license at the front of the book: the source code is yours to use in your own personal and commercial projects. Please do not redistribute the book file itself.

## How the Repository Is Organized {#repository-organization}

The repository is structured so that each chapter has its own checkpoint. This lets you start at the beginning of any chapter with the application already in the correct state from all the previous chapters. The checkpoints are organized so that, for example, the Chapter 8 checkpoint contains everything built through Chapter 7, ready for you to add the create form.

A typical Laravel project layout, which is what you will find inside each checkpoint, looks like this:

```
catatku/
├── app/
│   ├── Http/
│   │   └── Controllers/    EntryController, AuthController
│   └── Models/             Entry, User
├── database/
│   └── migrations/         the entries table migration
├── resources/
│   └── views/              home, entries/, auth/, components/
├── routes/
│   └── web.php             all application routes
└── .env.example            a template for your environment file
```

The `.env` file itself is not included, because it holds secrets and is never committed. Instead you get a `.env.example` to copy.

## Running a Finished Checkpoint {#running-a-checkpoint}

To run any checkpoint of the app on your machine, the steps are the same ones you learned in the book, just applied to code you downloaded instead of code you wrote:

```bash
cd catatku
composer install
cp .env.example .env
php artisan key:generate
```

Then open `.env` and set your database credentials (with Laragon's defaults, `DB_USERNAME=root` and an empty `DB_PASSWORD`). Create the tables and start the server:

```bash
php artisan migrate
php artisan serve
```

Open `http://127.0.0.1:8000` and the app will be running. If you are at a checkpoint from Chapter 6 or later, you can insert some seed data through Tinker exactly as described in Chapter 6 to see entries on screen.

## Using the Code to Debug {#using-the-code-to-debug}

When your own version misbehaves, the fastest way to find the problem is to compare your file against the matching file in the checkpoint. Look first at the file the error points to. Small differences, a missing `@csrf`, a route declared in the wrong order, a field name that does not match a validation rule, are the usual culprits, and **Appendix B: Troubleshooting Common Errors** covers the most common ones.

Treat the source code as a reference, not a replacement for writing your own. The understanding you are building comes from the typing and the debugging, not from having a finished copy.
