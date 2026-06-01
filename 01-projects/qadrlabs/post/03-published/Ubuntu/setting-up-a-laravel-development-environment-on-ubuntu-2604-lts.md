---
title: "Setting Up a Laravel Development Environment on Ubuntu 26.04 LTS"
slug: "setting-up-a-laravel-development-environment-on-ubuntu-2604-lts"
category: "Ubuntu"
date: "2026-04-25"
status: "published"
---

If you have just set up or upgraded to Ubuntu 26.04 LTS "Resolute Raccoon" and you are ready to start building with Laravel, you are already ahead of the game. As we covered in our [overview of Ubuntu 26.04 LTS](https://qadrlabs.com/post/whats-new-in-ubuntu-2604-lts-resolute-raccoon), this release ships PHP 8.5.2 and MySQL 8.4.8 directly from the official Ubuntu archive. That means you get a modern, fully supported stack without adding any third-party PPAs, which removes one of the most common friction points developers encounter when setting up a fresh PHP environment on Ubuntu.

In this tutorial you will set up a complete local Laravel 13 development environment on your Ubuntu 26.04 laptop: PHP 8.5 with all required extensions, Composer, MySQL, and Nginx configured to serve your Laravel project at `http://localhost`.

## Overview {#overview}

This tutorial walks you through every piece of the LEMP stack (Linux, Nginx, MySQL, PHP) that Laravel 13 needs, from a clean Ubuntu 26.04 install to a working Laravel welcome page in your browser. Because Ubuntu 26.04 already bundles PHP 8.5.2, all the pieces you need are available in the standard archive with straightforward `apt install` commands.

### What You'll Build

- A fully working Laravel 13 development environment running on Ubuntu 26.04 LTS
- Nginx configured with a server block to route requests to Laravel's `public` directory
- A dedicated MySQL database and user connected to the Laravel project via the `.env` file
- A verified installation confirmed by a successful database migration and the Laravel welcome page in your browser

### What You'll Learn

- How to install PHP 8.5 and every extension that Laravel 13 requires
- How to install Composer globally and use it to scaffold a new Laravel project
- How to create a dedicated MySQL database and user for development
- How to configure an Nginx server block for a Laravel application
- How to set correct file permissions so Nginx and Laravel can read and write storage files
- How to connect Laravel to MySQL via the `.env` file and verify the connection with `php artisan migrate`

### What You'll Need

- Ubuntu 26.04 LTS installed on your laptop or workstation
- A user account with `sudo` access
- Basic familiarity with the terminal and the `nano` text editor
- Read our [What's New in Ubuntu 26.04 LTS](https://qadrlabs.com/post/whats-new-in-ubuntu-2604-lts-resolute-raccoon) article for background on what changed in this release, particularly around PHP 8.5 and MySQL 8.4

## Step 1: Update the System {#step-1-update-system}

Before installing anything, bring the package index and all installed packages up to date. This ensures you are pulling the latest versions from the archive and avoids dependency conflicts during the steps that follow.

Open a terminal and run:

```bash
sudo apt update && sudo apt upgrade -y
```

You will see a list of packages being downloaded and updated. Once the command finishes with no errors, your system is ready for the next step.

## Step 2: Install PHP 8.5 and Laravel Extensions {#step-2-install-php}

Laravel 13 requires PHP 8.3 or higher, along with a specific set of extensions. Ubuntu 26.04 ships PHP 8.5.2, which satisfies that requirement with room to spare. Install PHP-FPM (the process manager that Nginx will use to execute PHP), the CLI binary, and every extension that Laravel 13 needs:

```bash
sudo apt install -y php8.5-fpm php8.5-cli php8.5-common \
  php8.5-curl php8.5-mbstring php8.5-mysql \
  php8.5-xml php8.5-zip php8.5-bcmath
```

Here is what each package does and why Laravel needs it:

- `php8.5-fpm`: Runs PHP as a background service and accepts requests from Nginx via a Unix socket. Without FPM, Nginx has no way to execute PHP files.
- `php8.5-cli`: Installs the `php` command-line binary, which is required to run Artisan commands and Composer.
- `php8.5-common`: Provides the core PHP shared files. Other extensions depend on it to function.
- `php8.5-curl`: Powers Laravel's HTTP client and Guzzle under the hood. Required for making outbound HTTP requests.
- `php8.5-mbstring`: Handles multi-byte string operations. Laravel uses it extensively for UTF-8 string processing.
- `php8.5-mysql`: Installs both the `pdo_mysql` and `mysqli` drivers, which Laravel's database layer uses to communicate with MySQL.
- `php8.5-xml`: Provides the DOM and XML extensions. Composer and many Laravel packages depend on these for parsing configuration and package manifests.
- `php8.5-zip`: Allows Composer to extract downloaded package archives during installation.
- `php8.5-bcmath`: Supplies arbitrary-precision mathematics functions used by packages such as Laravel Cashier.

Extensions like `ctype`, `fileinfo`, `filter`, `hash`, `openssl`, `pcre`, `session`, and `tokenizer` are either bundled into `php8.5-common` or compiled directly into the PHP binary, so you do not need to install them separately.

Verify that PHP 8.5 is active:

```bash
php -v
```

Expected output:

```
PHP 8.5.2 (cli) (built: Apr  2 2026 08:00:00) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.5.2, Copyright (c), by Zend Technologies
    with Zend OPcache v8.5.2, Copyright (c), by Zend Technologies
```

Confirm that the key Laravel extensions are loaded:

```bash
php -m | grep -E 'curl|mbstring|pdo_mysql|xml|zip|bcmath'
```

Expected output:

```
bcmath
curl
mbstring
pdo_mysql
xml
zip
```

Finally, start the PHP-FPM service and enable it to start automatically on boot:

```bash
sudo systemctl start php8.5-fpm
sudo systemctl enable php8.5-fpm
```

## Step 3: Install Composer {#step-3-install-composer}

Composer is PHP's dependency manager and the tool you will use to create and maintain your Laravel project. The recommended installation method is to download the official installer script from getcomposer.org and place the resulting binary in a system-wide location so it is available from any directory.

Download and run the installer:

```bash
curl -sS https://getcomposer.org/installer | php
```

Move the resulting `composer.phar` file into your system's PATH:

```bash
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
```

Verify the installation:

```bash
composer --version
```

Expected output:

```
Composer version 2.8.x 2026-xx-xx xx:xx:xx
```

The exact minor version depends on what is current at install time. Any `2.x.x` release means Composer is ready.

## Step 4: Install and Configure MySQL {#step-4-install-mysql}

Ubuntu 26.04 ships MySQL 8.4.8 LTS. Install the server package, then start and enable the service:

```bash
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
```

Verify that MySQL is running:

```bash
sudo systemctl status mysql
```

Look for `Active: active (running)` in the output. If you see it, the database server is ready.

### Secure the Installation

Run the built-in security script. It walks you through setting a root password, removing the anonymous user account, and dropping the test database. For a local development machine these steps are not strictly required, but building the habit is worthwhile:

```bash
sudo mysql_secure_installation
```

Follow the prompts. When it asks whether to use the VALIDATE PASSWORD component, you can answer `N` for a development setup to keep things simple.

### Create a Database and User for Laravel

Log in to MySQL as root. On Ubuntu 26.04, the root account uses the `auth_socket` plugin by default, so no password is needed when you prefix the command with `sudo`:

```bash
sudo mysql
```

You will land at the MySQL prompt. Run the following SQL commands, replacing `secret` with a password of your choice:

```sql
CREATE DATABASE laravel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'laravel_user'@'localhost' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Here is what each command does. `CREATE DATABASE` creates a new database using the `utf8mb4` character set, which fully supports Unicode including emoji and is what Laravel defaults to. `CREATE USER` creates a dedicated application user that is restricted to `localhost`, which is the correct scope for a local dev environment. `GRANT ALL PRIVILEGES` gives that user full control over `laravel_db` only, keeping any other databases on the server protected. `FLUSH PRIVILEGES` tells MySQL to reload its grant tables so the new permissions take effect immediately.

Verify the new user can connect:

```bash
mysql -u laravel_user -p laravel_db
```

Enter the password you chose. If you reach the MySQL prompt without an error, the database and user are configured correctly. Type `exit` to leave.

## Step 5: Install Nginx {#step-5-install-nginx}

Nginx will act as the web server for your Laravel project. It receives incoming HTTP requests and delegates PHP execution to PHP-FPM via a Unix socket. The split between Nginx (handling HTTP concerns) and FPM (handling PHP execution) is faster and more resource-efficient than running PHP embedded inside the web server process.

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

Confirm Nginx is running:

```bash
sudo systemctl status nginx
```

Look for `Active: active (running)`. You can also verify it responds to HTTP requests:

```bash
curl -I http://localhost
```

Expected output:

```
HTTP/1.1 200 OK
Server: nginx/1.x.x
Content-Type: text/html
...
```

The `200 OK` status line confirms Nginx is listening and responding.

## Step 6: Create a New Laravel Project {#step-6-create-project}

With PHP, Composer, MySQL, and Nginx ready, you can scaffold a new Laravel project. The standard location for web applications on Debian-based systems is `/var/www`. Create the target directory, then set ownership so both your user account and the `www-data` group (which Nginx runs as) have access:

```bash
sudo mkdir -p /var/www/laravel-app
sudo chown -R $USER:www-data /var/www/laravel-app
```

Now create the Laravel project inside that directory:

```bash
cd /var/www
composer create-project laravel/laravel laravel-app
```

Composer will download the Laravel framework and all its dependencies into `/var/www/laravel-app`. This may take a minute or two depending on your internet connection. Once it finishes, set the correct permissions on the directories that Laravel needs to write to at runtime:

```bash
sudo chown -R $USER:www-data /var/www/laravel-app/storage
sudo chown -R $USER:www-data /var/www/laravel-app/bootstrap/cache
sudo chmod -R 775 /var/www/laravel-app/storage
sudo chmod -R 775 /var/www/laravel-app/bootstrap/cache
```

The `775` permission gives the owner and the group read, write, and execute access, while everyone else gets read and execute only. Laravel writes logs, compiled Blade views, and cached configuration into `storage` and `bootstrap/cache`, so getting permissions right here prevents one of the most common errors in fresh Laravel setups.

Verify the project is in place:

```bash
php /var/www/laravel-app/artisan --version
```

Expected output:

```
Laravel Framework 13.x.x
```

## Step 7: Configure the Environment File {#step-7-configure-env}

Laravel reads all environment-specific configuration from the `.env` file in the project root. This file controls everything from your app name to the database credentials, and it is never committed to version control. Open it in nano:

```bash
nano /var/www/laravel-app/.env
```

Locate the database section and update it to match the MySQL credentials you created in Step 4:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=secret
```

Also confirm the `APP_URL` is set to your local address:

```
APP_URL=http://localhost
```

Save the file with `Ctrl+O`, press `Enter` to confirm the filename, then exit with `Ctrl+X`.

Generate the application key. Laravel uses this key to encrypt session data, cookies, and other sensitive values. Every Laravel project must have a unique key, and Composer does not generate one automatically when you use `create-project` in an existing directory:

```bash
cd /var/www/laravel-app
php artisan key:generate
```

Expected output:

```
   INFO  Application key set successfully.
```

## Step 8: Configure Nginx for Laravel {#step-8-configure-nginx}

Nginx needs a server block that tells it where Laravel's files live and how to forward PHP requests to FPM. Create a new configuration file for the project:

```bash
sudo nano /etc/nginx/sites-available/laravel-app
```

Paste the following configuration:

```nginx
server {
    listen 80;
    server_name localhost;
    root /var/www/laravel-app/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.5-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Several details in this configuration are worth understanding. The `root` directive points to `laravel-app/public`, not to the project root. Laravel's front controller `public/index.php` is the single entry point for every HTTP request. By setting the document root to `public`, the rest of the project files (including `.env`) are completely outside the web-accessible path, so a user cannot request them through the browser.

The `try_files` directive in `location /` first checks whether the requested URI matches a real file or directory on disk. If it does not, the request falls through to `index.php` with the original query string intact. This is what allows Laravel's router to receive and handle every route.

The `fastcgi_pass` line uses the PHP 8.5-FPM socket path specifically. This is the socket file that the `php8.5-fpm` service creates when it starts, and it is how Nginx hands off PHP execution to the correct FPM version.

The final `location` block denies access to any hidden file (a file whose name starts with a dot), which prevents accidental exposure of `.env`, `.git`, and similar files.

Enable the site by creating a symlink in `sites-enabled`, then remove the default Nginx placeholder site:

```bash
sudo ln -s /etc/nginx/sites-available/laravel-app /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
```

Test the Nginx configuration for syntax errors before applying it:

```bash
sudo nginx -t
```

Expected output:

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Reload Nginx to apply the new server block:

```bash
sudo systemctl reload nginx
```

## Step 9: Try It Out {#step-9-try-it-out}

With the full stack configured, verify two things: that Laravel can reach MySQL, and that the welcome page loads in a browser.

### Scenario 1: Verify the Database Connection

Run the default Laravel migrations. This command creates the tables that ship with a fresh Laravel 13 project (users, sessions, cache, and jobs) and is the most reliable way to confirm that Laravel can talk to MySQL with the credentials you provided:

```bash
cd /var/www/laravel-app
php artisan migrate
```

Expected output:

```
   INFO  Preparing database.

  Creating migration table ............................................. 9ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table .............................. 45ms DONE
  0001_01_01_000001_create_cache_table .............................. 12ms DONE
  0001_01_01_000002_create_jobs_table ............................... 18ms DONE
```

If you see this output, Laravel successfully connected to MySQL, created the migration tracking table, and ran all three default migrations. If you see an `Access denied` error instead, double-check the credentials in `.env` against what you created in Step 4, and confirm the `DB_HOST` is `127.0.0.1` rather than `localhost` (using `127.0.0.1` forces PHP to connect via TCP rather than a Unix socket, which is more reliable with the default MySQL configuration on Ubuntu).

### Scenario 2: Open the Laravel Welcome Page

Open your browser and navigate to:

```
http://localhost
```

You should see the Laravel welcome page. If the page loads, your entire stack is working: Nginx received the request, passed it to PHP 8.5-FPM, which executed Laravel, which rendered the welcome view and sent it back through Nginx to your browser.

If the page does not load, check the Nginx error log for clues:

```bash
sudo tail -f /var/log/nginx/error.log
```

The two most common causes in a fresh setup are a permissions error on the `storage` directory (return to Step 6 and re-run the `chown` and `chmod` commands) and a PHP-FPM socket path mismatch. To confirm the socket file exists at the expected path, run:

```bash
ls /var/run/php/
```

You should see `php8.5-fpm.sock` in the output. If the file is there, check that the path in your Nginx configuration matches exactly.

## Conclusion {#conclusion}

You now have a complete Laravel 13 development environment running on Ubuntu 26.04 LTS, built on a LEMP stack that requires no third-party package sources.

- **PHP 8.5.2 ships with Ubuntu 26.04.** No PPAs are needed. All the extensions Laravel 13 requires are available as standard `apt` packages, and extensions like `ctype`, `fileinfo`, `filter`, `hash`, `pcre`, `session`, and `tokenizer` are bundled into the PHP core.
- **PHP-FPM decouples web serving from PHP execution.** Nginx handles HTTP and hands PHP work to FPM over a Unix socket. This is faster than embedding PHP in the web server process and is the pattern used in production Laravel deployments.
- **Dedicated MySQL database and user.** The `laravel_user` account has privileges on `laravel_db` only. This minimal-privilege pattern protects other databases on the same server and is a good habit to build from day one.
- **Nginx document root points to `public`.** Laravel's entire project directory lives under `/var/www/laravel-app`, but Nginx only serves files from `public`. Everything else, including `.env` and all application code, is outside the web-accessible path.
- **Correct permissions on `storage` and `bootstrap/cache`.** The `775` permission with `$USER:www-data` ownership gives both your terminal sessions and the Nginx/FPM process the write access they need, without opening the directories to the world.
- **`php artisan migrate` as the connection test.** Running migrations verifies the full database connection chain in one command: credentials, driver, and database name. If it passes, the environment is correctly wired together.