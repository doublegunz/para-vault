## 1. Before You Begin

You have just decided to learn Symfony, one of the most powerful and professionally respected PHP frameworks in the world. You are excited, motivated, and ready to build something real. But then you open your laptop and realize you do not even know where to start. This lesson eliminates that friction entirely.

Before writing a single line of Symfony code, you need a working development environment. This means a code editor, a local server that can run PHP and MySQL, the right PHP version, and a Symfony project ready to go. Getting all of this right the first time prevents mysterious errors that have nothing to do with your code.

This lesson covers the full setup process for Windows users. By the end, you will have a Symfony 8 project called Catatku running in your browser, and you will understand the purpose of every folder inside it.

### What You'll Build

You will set up a complete local development environment and create a fresh Symfony 8 project called Catatku, which you will build upon throughout this entire course. By the end of this lesson, you will see a working Symfony welcome page running in your browser.

### What You'll Learn

- ✅ How to install and configure Visual Studio Code as your code editor
- ✅ How to install Laragon as your local server environment
- ✅ How to upgrade PHP to version 8.4, which is required for Symfony 8
- ✅ How to create a new Symfony 8 project using Composer
- ✅ How to navigate the Symfony folder structure
- ✅ How to run the development server using PHP's built-in server

### What You'll Need

- A computer running Windows
- An internet connection for downloading tools and packages
- About 30 to 45 minutes of your time

---

## 2. Installing the Tools

Before creating a Symfony project, you need three things installed: a code editor, a local server environment, and PHP 8.4. This section walks through each one.

### Step 1: Install Visual Studio Code

Visual Studio Code (VS Code) is a free, lightweight code editor built by Microsoft. It has excellent extensions for PHP and Twig, and its integrated terminal will be used throughout this course.

Go to the [official Visual Studio Code website](https://code.visualstudio.com/) and click the **Download** button for Windows. Run the installer and follow the prompts. Accept the default options, including the option to add VS Code to your system PATH.

### Step 2: Install Laragon

Laragon is an all-in-one local development environment for Windows that bundles Apache or Nginx, MySQL, PHP, and Composer into a single installer. It is the fastest way to get a PHP stack running on Windows without manually configuring each component.

Download Laragon from the [official Laragon website](https://laragon.org/index.html).

**Important note:** Since Laragon version 7, the main download page serves a paid version. For the free version, download directly from GitHub:

```text
https://github.com/leokhoa/laragon/releases/download/6.0.0/laragon-wamp.exe
```

After installation, open Laragon and click **Start All** to launch all services. Then add Laragon to your system PATH by going to **Menu > Tools > Path > Add Laragon to Path**. This makes the `php` and `composer` commands available from any terminal.

### Step 3: Upgrade PHP to 8.4

Symfony 8 requires PHP 8.4 or higher. The default Laragon installation ships with an older PHP version, so you need to replace it before creating the project.

Follow these steps to upgrade:

1. Download PHP 8.4 64-bit NTS from [https://windows.php.net/download/](https://windows.php.net/download/).
2. Move the downloaded ZIP file to `C:\laragon\bin\php` and extract it there.
3. In Laragon, go to **Menu > PHP > Version** and select the new PHP 8.4 folder.
4. Optionally switch to Nginx: open **Preferences > Services & Ports**, uncheck Apache, check Nginx, and set the port to 80.
5. Click **Start All** to apply the changes.

Now verify the PHP version in your terminal:

```bash
php -v
```

You should see `PHP 8.4.x` in the output. If you see an older version, Laragon's PATH setting has not taken effect yet. Restart your terminal and try again.

Also verify Composer is available:

```bash
composer --version
```

Both commands must succeed before moving on.

---

## 3. Creating the Symfony Project

With PHP 8.4 and Composer ready, you can now create the Catatku project. This section walks through the three commands that set up the complete project.

### Step 1: Navigate to the Web Root

Open the Laragon terminal and move into the folder where Laragon serves web projects:

```bash
cd C:\laragon\www
```

All files inside `C:\laragon\www` are accessible through your local browser, so this is the correct location for the project.

### Step 2: Create the Symfony Skeleton

Run the following command to create a new Symfony project using the minimal skeleton:

```bash
composer create-project symfony/skeleton:"^8.0" catatku
cd catatku
```

`composer create-project` downloads Symfony and its dependencies into a new folder named `catatku`. The `"^8.0"` version constraint means "any version of Symfony 8.x". The resulting project is minimal: just the framework core with no extras.

Composer prints a long list of installed packages. The last lines of the output end like this:

```text
Symfony operations: 4 recipes (202783ef3a47699481314d26b1312103)
  - Configuring symfony/flex (>=2.4): From github.com/symfony/recipes:main
  - Configuring symfony/framework-bundle (>=8.1): From github.com/symfony/recipes:main
  - Configuring symfony/console (>=5.3): From github.com/symfony/recipes:main
  - Configuring symfony/routing (>=7.4): From github.com/symfony/recipes:main
Executing script cache:clear [OK]
Executing script assets:install public [OK]
```

The exact version numbers depend on the newest Symfony 8 release available when you run the command. This course was tested with Symfony 8.1.

### Step 3: Install the Web Application Dependencies

The skeleton alone does not include Twig, Doctrine, or the Security component. Install all of them with a single command:

```bash
composer require webapp
```

The `webapp` metapackage installs everything a standard web application needs: Twig for templates, Doctrine ORM for database interaction, the Security bundle for authentication, form handling, validation, and other essential components. This is the standard starting point for a Symfony web project.

When the installation finishes, confirm that the console works and check which Symfony version you got:

```bash
php bin/console --version
```

Output:

```text
Symfony v8.1.10 (env: dev, debug: true)
```

`env: dev` and `debug: true` confirm that the project runs in the development environment, which you will look at in section 5. If your version number is slightly different, that is fine, as long as it starts with 8.

### Step 4: Open the Project in VS Code

```bash
code .
```

This opens the entire `catatku` folder in VS Code. From here you can browse files, edit code, and use the integrated terminal for all remaining commands.

---

## 4. Understanding the Symfony Folder Structure

After running `composer require webapp`, the project contains several directories. Most of them you will never touch. Here are the ones that matter for this course:

```text
catatku/
├── config/
│   ├── packages/               ← Bundle configuration (security, doctrine, etc.)
│   └── routes.yaml             ← Route configuration (we use attributes instead)
├── src/
│   ├── Controller/             ← Where controllers live
│   ├── Entity/                 ← Doctrine entity classes (database models)
│   ├── Migrations/             ← Database migration files
│   └── Repository/             ← Database query classes
├── templates/                   ← Twig template files
├── public/
│   └── index.php               ← Application entry point
├── .env                         ← Environment configuration
└── bin/
    └── console                  ← Symfony's CLI tool
```

**`src/Controller/`** is where your application logic lives. Controllers receive incoming HTTP requests, coordinate with the database, and return responses (usually by rendering a Twig template).

**`src/Entity/`** contains Doctrine entity classes. Each class maps to a database table using PHP attributes like `#[ORM\Entity]` and `#[ORM\Column]`. An entity instance represents a single row in that table.

**`src/Repository/`** contains repository classes for database queries. Each entity has a corresponding repository with methods for fetching data. You will use repository methods like `findBy()` and `findOneBy()` extensively.

**`templates/`** is where all Twig template files live. Twig is Symfony's default template engine. It uses `{{ }}` for displaying values, `{% %}` for logic like loops and conditions, and `{# #}` for comments.

**`src/Migrations/`** contains PHP files that define database structure changes. Instead of writing raw SQL by hand, you generate migration files from your entity definitions and run them with a single command.

**`.env`** stores environment-specific configuration. The most important value here is `DATABASE_URL`, which tells Doctrine how to connect to your database.

---

## 5. Configure the Environment and Run the Server

With the project created, there are two final steps: verify the environment configuration and start the development server.

### Step 1: Check the .env File

Open `.env` in the project root and find the `APP_ENV` line:

```env
APP_ENV=dev
```

This value should already be set to `dev`. The `dev` environment enables Symfony's profiler toolbar, detailed error pages, and debug output. You would change this to `prod` only when deploying to a live server.

The `dev` environment is designed for development comfort: errors show full stack traces instead of generic error pages, making it much easier to understand what went wrong.

### Step 2: Start the Development Server

From inside the `catatku` folder, run:

```bash
php -S localhost:8080 -t public
```

This starts PHP's built-in web server, serving files from the `public/` directory on port 8080. Open your browser and go to `http://localhost:8080`. You will see the Symfony welcome page, which confirms that the project is set up correctly.

Keep this terminal running during development. Open a second terminal tab for running other commands like migrations and code generators.

> **Tip:** If you install the Symfony CLI separately (`symfony server:start`), you get HTTPS support and automatic PHP version detection. The built-in PHP server works perfectly for this course, but the Symfony CLI is worth exploring once you are comfortable with the basics.

---

## 6. Getting to Know the Console

Symfony's built-in command-line tool is `bin/console`. Every Symfony command follows the pattern `php bin/console [command]`. Here is a preview of the commands you will encounter throughout this course:

```bash
php bin/console make:controller      # Generate a new controller class
php bin/console make:entity          # Generate a new entity class
php bin/console make:migration       # Create a migration from entity changes
php bin/console doctrine:migrations:migrate  # Run all pending migrations
php bin/console debug:router         # Display all registered routes
php bin/console doctrine:fixtures:load       # Load seed data into the database
```

You do not need to memorize these now. Each command will be reintroduced at the exact moment it is needed. The important thing to know is that `bin/console` is Symfony's code generator, and it saves a significant amount of repetitive typing.

---

## 7. Fix the Errors in Your Code

This section covers the most common setup mistakes beginners make when creating a Symfony project for the first time.

**Error 1: Wrong PHP version.**

The most common cause of Symfony installation failures is running an older PHP version without realizing it. Composer checks the PHP requirement before downloading anything and stops with an error saying that your PHP version does not satisfy the requirement of Symfony 8:

```bash
# Wrong: PHP is still 8.1, so Composer refuses to install Symfony 8
composer create-project symfony/skeleton:"^8.0" catatku

# Correct: confirm PHP 8.4 first, then create the project
php -v
composer create-project symfony/skeleton:"^8.0" catatku
```

Run `php -v` before creating the project. If it shows anything older than 8.4, Laragon is still pointing to the old PHP version. Go to **Menu > PHP > Version** in Laragon, select the new folder, then restart Laragon and your terminal.

**Error 2: Running `composer create-project` from the wrong directory.**

If you run the project creation command from your home directory or desktop, the resulting folder will not be served by Laragon's web server.

```bash
# Wrong:
cd C:\Users\YourName
composer create-project symfony/skeleton:"^8.0" catatku

# Correct:
cd C:\laragon\www
composer create-project symfony/skeleton:"^8.0" catatku
```

Projects must live inside `C:\laragon\www` for Laragon to serve them correctly.

**Error 3: Forgetting `composer require webapp`.**

The skeleton project starts with almost nothing. If you skip the `webapp` step, you will get errors the moment you try to use Twig or Doctrine.

```bash
# Wrong: skipping webapp and starting to build immediately
composer create-project symfony/skeleton:"^8.0" catatku

# Correct:
composer create-project symfony/skeleton:"^8.0" catatku
cd catatku
composer require webapp
```

Run `composer require webapp` inside the project folder immediately after creating the skeleton. The `webapp` metapackage adds Twig, Doctrine, Security, and the other components that every real web application needs.

---

## 8. Exercises

**Exercise 1:** After creating the project, open a terminal inside the `catatku` folder and run `php bin/console list make`. This shows only the commands in the `make` namespace. How many commands start with `make:`? Write down five that sound useful to you.

**Exercise 2:** Open `composer.json` in the project root and find the `"require"` section. List three packages that were installed by `composer require webapp`. For each one, write a one-sentence guess about what it does.

**Exercise 3:** Open `src/Kernel.php` and `config/bundles.php`. Without making any changes, read through both files. `Kernel.php` is surprisingly short. Where do you think Symfony gets the list of bundles to load? Write a one-sentence description of what `config/bundles.php` does in your own words.

---

## 9. Solutions

**Solution for Exercise 1:**

`php bin/console list make` prints a section titled `Available commands for the "make" namespace:`. In the project used to test this course (Symfony 8.1 with the `webapp` package), that section lists 31 lines. Three of them are aliases (`make:functional-test`, `make:subscriber`, and `make:unit-test` point to commands that are already listed), so there are 28 distinct `make:` commands. The exact number depends on which bundles and which MakerBundle version you have installed. Five useful ones for this course are `make:controller`, `make:entity`, `make:migration`, `make:user`, and `make:fixtures`.

**Solution for Exercise 2:**

After running `composer require webapp`, the `"require"` section of `composer.json` will include packages such as:

- `symfony/twig-bundle`: Integrates the Twig template engine into Symfony, allowing controllers to render `.html.twig` files.
- `doctrine/orm`: Provides the Doctrine Object-Relational Mapper, which maps PHP classes to database tables.
- `symfony/security-bundle`: Adds the Symfony Security component for handling authentication and authorization.

**Solution for Exercise 3:**

`Kernel.php` only extends Symfony's base `Kernel` class and uses `MicroKernelTrait`. The trait does the heavy lifting: it reads `config/bundles.php` to know which bundles to load, then loads the configuration in `config/packages/` and the routes in `config/routes.yaml`. `config/bundles.php` is a plain PHP array that lists every installed bundle and the environments it runs in, for example `['all' => true]` for every environment or `['dev' => true]` for development only. A bundle is a reusable package of functionality, similar to a plugin. Symfony Flex adds a line to this file automatically whenever you install a bundle with Composer.

---

## Next Up - Lesson 3

In this lesson, you installed Visual Studio Code, Laragon, and PHP 8.4, then created a Symfony 8 project using `composer create-project` and `composer require webapp`. You ran the development server and explored the project structure. You now understand the role of each major folder and how `bin/console` works.

In Lesson 3, you will create your first routes using `#[Route]` PHP attributes and build your first Twig templates, giving Catatku its first real pages.