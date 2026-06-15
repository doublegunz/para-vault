## 1. Before You Begin

You have built a complete application on your local machine. Lesson 16 produced an optimized Vite build that bundles the CSS and JavaScript Catatku needs in production. The final step is making everything available on the public internet so real users can reach it. Deployment is more than just copying files: you provision a server, install the right software, configure a real database, secure traffic with HTTPS, lock down file permissions, and keep background workers alive after every reboot.

This lesson walks through a real, end-to-end deployment of Catatku to a fresh Ubuntu VPS using Nginx, PHP-FPM 8.3, MariaDB, and Supervisor. You will deploy to a domain that you own yourself, so prepare one before starting: any domain from any registrar (Niagahoster, Namecheap, Cloudflare, and others) works, and a subdomain of a domain you already own is fine too. Because every reader's domain is different, this lesson uses `catatku.example.com` as a placeholder; every time it appears in a command or configuration file, replace it with your own domain. The application is pulled from `https://github.com/qadrLabs/catatku-deploy-demo`, a ready-to-deploy version of Catatku that already includes the Vite build setup from Lesson 16; if you have been following along and pushed your own Catatku to GitHub, clone your personal repository instead. You will obtain a free SSL certificate from Let's Encrypt, configure the production `.env`, set up a secure ownership model where your own deploy user owns the code and `www-data` only reads it (with ACL write access on the two writable directories), run the queue worker as a managed service, and learn a simple `git pull` workflow for shipping future updates. By the end you will have a HTTPS site, a healthy queue worker, and a repeatable deployment script.

### What You'll Build

You will deploy Catatku to an Ubuntu VPS so it is reachable over HTTPS at your own domain. Two queue workers will run permanently under Supervisor, the application files will be owned by your own deploy user (the SSH user you log in as) while `www-data` gets read-only access to the code plus ACL write access to the two directories Laravel must write to, and you will save a short shell script that performs the entire update flow with a single command.

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

### What You'll Learn

- ✅ Provisioning an Ubuntu VPS for Laravel (Nginx, PHP 8.3, MariaDB, Supervisor, Certbot)
- ✅ Pointing DNS and obtaining an SSL certificate via Let's Encrypt
- ✅ Production `.env` configuration with `APP_DEBUG=false`, MariaDB, and database drivers
- ✅ A secure ownership model: your deploy user owns the code, `www-data` is read-only on it, with ACLs granting write access only to `storage/` and `bootstrap/cache/`
- ✅ Optimizing Laravel with `php artisan optimize`
- ✅ Running queue workers permanently with Supervisor (`database` driver)
- ✅ Updating the application with a simple `git pull` workflow

### What You'll Need

- Lesson 16 completed
- An Ubuntu 24.04 VPS with SSH access and `sudo`
- A domain (or subdomain) you own, with access to its DNS management panel; you will point it to the VPS in Section 2, and this lesson uses `catatku.example.com` as a placeholder for it
- A GitHub account that can clone `https://github.com/qadrLabs/catatku-deploy-demo` (or your own Catatku repository)

---

## 2. Provisioning the Server

A clean Ubuntu VPS does not have any of the software Catatku needs. Before you can run a single artisan command, you must install the web server, the database, the PHP runtime with the right extensions, and the supporting tools. Once the software is installed, point the domain to the server so you can obtain an SSL certificate later. This section covers both steps in order.

### Step 1: Install Required Software

SSH into the VPS and update the package list first. Then install Nginx, MariaDB, PHP 8.3 with the extensions Laravel requires, Composer, Git, Supervisor, and Certbot in a single command. This lesson targets Ubuntu 24.04 specifically because its default repository ships PHP 8.3, the version Catatku requires; older Ubuntu releases ship older PHP versions, so the `php8.3-*` packages below would not be found there without adding a third-party repository.

```bash
sudo apt update
sudo apt install -y nginx mariadb-server php8.3-fpm php8.3-cli \
    php8.3-mysql php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip \
    php8.3-bcmath php8.3-gd php8.3-intl php8.3-tokenizer php8.3-fileinfo \
    composer git unzip supervisor certbot python3-certbot-nginx acl
```

Each package plays a specific role. `nginx` is the web server that accepts HTTPS requests from the internet. `mariadb-server` is the production database; it is a drop-in compatible fork of MySQL maintained by the original MySQL authors. `php8.3-fpm` is the FastCGI Process Manager that runs your PHP code behind Nginx, and `php8.3-cli` is the command-line PHP binary Artisan uses. `php8.3-mysql` is the PDO driver Laravel uses to talk to MariaDB (the package keeps the legacy `mysql` name even though it also drives MariaDB). The remaining `php8.3-*` packages enable the extensions Laravel requires for string handling, XML, HTTP, archive files, math, image generation, internationalization, tokenizing, and file metadata. `composer` installs PHP dependencies, `git` pulls your code from GitHub, `unzip` is required by Composer for archive packages, `supervisor` keeps the queue worker running, and the two Certbot packages obtain and auto-renew the Let's Encrypt SSL certificate. `acl` provides the `setfacl` command you will use in Section 3 to grant `www-data` write access to `storage/` and `bootstrap/cache/` without making it the owner of your code.

Ubuntu's default repository often ships an outdated Node.js version, but Vite 8 (the bundler you configured in Lesson 16) requires Node 20.19 or newer, or 22.12 or newer. Node 20 reached its end of life in April 2026 and no longer receives security updates, so a new server should run Node 22 LTS. Install it from the official NodeSource repository.

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
```

The first command adds NodeSource's signed repository for Node.js 22 LTS to apt. The second command installs the `nodejs` package from that repository, which bundles `npm`. Verify the versions with `node -v` (should print `v22.x.x`) and confirm PHP is on 8.3 with `php -v`. With a too-old Node version, `npm run build` will fail with cryptic errors deep inside Vite or its plugins.

```
gungun@qadrlabs:$ node -v
v22.22.3
gungun@qadrlabs:$ php -v
PHP 8.3.6 (cli) (built: May 25 2026 13:12:06) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies
```

Your patch numbers may differ slightly, but the major versions must read `v22` for Node and `8.3` for PHP. If `node -v` still shows an older major version, the NodeSource step did not take effect; re-run the two commands above before continuing.

### Step 2: Point the Domain to the Server

Without a working DNS record, Certbot cannot prove you own the domain and will refuse to issue a certificate. Log into the DNS panel of the provider where you registered your domain (Cloudflare, Niagahoster, Namecheap, etc.) and create an A record that maps your domain to your VPS public IP.

| Type | Name      | Value                |
|------|-----------|----------------------|
| A    | `catatku` | Public IP of the VPS |

The `Name` field contains only the subdomain part, not the full domain: for the placeholder `catatku.example.com`, that part is `catatku`. If you are deploying on a subdomain of your own (for example `app.mydomain.com`), enter that subdomain (`app`) instead. If you are deploying on the root domain itself (for example `mydomain.com` with no subdomain), most providers use `@` as the name.

After saving the record, verify it has propagated by running `dig` from the VPS itself. Remember to replace the placeholder with your own domain.

```bash
dig +short catatku.example.com
```

The output must match your VPS public IP exactly. If the output is empty or shows a different address, wait a few minutes for DNS propagation, then run the command again. Do not move on to the SSL step until `dig` returns the correct IP, otherwise Certbot will fail and you will spend time chasing a problem that is actually DNS-related.

---

## 3. Deploying the Application Code

The server now has the right software and the domain resolves to its IP, so you can pull the application code onto disk. This section clones the repository, installs dependencies, creates the production `.env`, and locks down file ownership and permissions.

### Step 1: Clone the Repository

The conventional location for web applications on Ubuntu is `/var/www`. Create the project directory and give your SSH user ownership so you can run `git clone`, `composer install`, and `npm install` without `sudo` on every command. Your SSH user keeps ownership permanently in this lesson: it is your *deploy user*, the account you use to ship code. In Step 4 you will give `www-data` read access to the code through group membership and write access to just two directories through ACLs, so the web server never needs to own your code.

```bash
sudo mkdir -p /var/www/catatku
sudo chown -R $USER:$USER /var/www/catatku
git clone https://github.com/qadrLabs/catatku-deploy-demo.git /var/www/catatku
cd /var/www/catatku
```

This lesson clones `qadrLabs/catatku-deploy-demo`, a complete version of Catatku that already includes the Vite build configuration you set up in Lesson 16. If you have followed the course and pushed your own Catatku to GitHub, replace the URL above with your personal repository so you deploy the code you actually wrote. Do **not** clone the beginner-course repository here: it stops before the frontend build step, so `npm run build` later in this section would fail with errors because the Vite setup does not exist yet.

`sudo mkdir -p` creates `/var/www/catatku` and any missing parent directories. The `chown -R $USER:$USER` transfers ownership to your current shell user; `$USER` expands to whoever is logged in, so you do not need to type your username manually. `git clone` then copies the repository into the directory. The final `cd` switches into the project root so every subsequent command runs from there. Your deploy user keeps ownership of the code from here on; Step 4 only adjusts the group and adds ACLs so `www-data` can read the code and write to the two directories Laravel needs.

### Step 2: Install PHP and Node Dependencies

Production dependencies are installed without dev packages (Pest, Pint, debug tools) and with an optimized autoloader. The frontend bundle is compiled once into `public/build/` and served as static files from there.

```bash
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

`--no-dev` skips packages listed under `require-dev` in `composer.json`, which keeps the production install smaller and free of development tooling. `--optimize-autoloader` builds a static classmap that Composer uses for autoloading, which speeds up every request by roughly 2x compared to the default PSR-4 traversal. `npm ci` installs Node packages from `package-lock.json` deterministically, so two servers running this command always end up with the exact same `node_modules/` tree. `npm run build` invokes Vite, which compiles your CSS and JavaScript into hashed, minified files inside `public/build/`. After this step, Node and its dependencies are no longer needed at runtime, but you can keep them installed for future rebuilds.

### Step 3: Create the Production `.env` File

Local and production environments must never share an `.env` file. Production needs its own `APP_KEY`, its own database credentials, and `APP_DEBUG=false`. Start by copying the example file and generating a fresh application key.

```bash
cp .env.example .env
php artisan key:generate
```

`cp .env.example .env` creates the working `.env` from the template that ships with the repository. `php artisan key:generate` overwrites the `APP_KEY` line with a freshly generated 32-byte base64 string. This key is used to encrypt sessions and cookies, so each environment must have its own; reusing the local key in production is a security mistake.

Open `/var/www/catatku/.env` in a terminal editor. This lesson uses `nano`, which is installed by default on Ubuntu and is the friendliest choice if you have never edited files over SSH before.

```bash
nano /var/www/catatku/.env
```

Inside nano, use the arrow keys to move around and type normally. When you are done, save with `Ctrl+O` then `Enter`, and exit with `Ctrl+X`. The shortcut hints at the bottom of the screen write `^` for the `Ctrl` key. You will use `nano` again later for the Nginx, Supervisor, and deploy-script files, so the same shortcuts apply throughout this lesson.

Replace the file's contents with the following production configuration. Two values need your attention before saving: replace every occurrence of `catatku.example.com` with your own domain, and keep the `APP_KEY` line that `key:generate` just wrote (the `THE_VALUE_FROM_KEY_GENERATE` placeholder below stands for that generated value, so do not overwrite it).

```env
APP_NAME=Catatku
APP_ENV=production
APP_KEY=base64:THE_VALUE_FROM_KEY_GENERATE
APP_DEBUG=false
APP_URL=https://catatku.example.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=catatku_production
DB_USERNAME=catatku_user
DB_PASSWORD=REPLACE_WITH_A_STRONG_PASSWORD

BROADCAST_CONNECTION=log
CACHE_STORE=database
QUEUE_CONNECTION=database
SESSION_DRIVER=database
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailgun.org
MAIL_PORT=587
MAIL_USERNAME=postmaster@mg.catatku.example.com
MAIL_PASSWORD=REPLACE_WITH_SMTP_PASSWORD
MAIL_FROM_ADDRESS=hello@catatku.example.com
MAIL_FROM_NAME="${APP_NAME}"
```

Walk through the values that matter most. `APP_ENV=production` flips Laravel into production behavior: it hides stack traces from browser output, simplifies error pages, and activates a handful of safety checks. `APP_DEBUG=false` is the single most important production setting; if it is left `true`, every exception page exposes your `.env` values, file paths, and stack traces to anyone on the internet who triggers an error. `APP_URL` must match the domain Nginx serves, otherwise generated URLs (password reset emails, redirects, asset paths in some scenarios) will point to the wrong place. `DB_CONNECTION=mariadb` tells Laravel to use the `mariadb` block in `config/database.php` rather than the older `mysql` block; both work against a MariaDB server, but the dedicated block uses the correct dialect and default options. `CACHE_STORE`, `QUEUE_CONNECTION`, and `SESSION_DRIVER` are all set to `database` so everything is stored in MariaDB: no extra service to install, no extra port to firewall, and capacity that is more than enough for a small to medium site. Finally, `MAIL_MAILER=smtp` plus a real provider (Mailgun shown here, but any SMTP service works) ensures emails actually reach users; never leave `MAIL_MAILER=log` in production because emails would silently pile up in the log file instead of being sent. Notice that there is no `MAIL_SCHEME` line: on port 587, Laravel defaults the scheme to `smtp` and the connection is upgraded to an encrypted one automatically through STARTTLS, so encryption still happens without any extra setting. Only set `MAIL_SCHEME=smtps` if your provider requires port 465. Any other value (such as `tls`) is rejected by the mailer with an "unsupported scheme" exception the first time the application tries to send an email.

### Step 4: Set File Permissions

Wrong permissions are the most common first-deploy failure. The secure model has three rules. First, your deploy user (`$USER`) owns every file and the group is set to `www-data`, so the web server can *read* the code but not modify it. Second, directories use `755` and files use `644`, which gives the group (and therefore `www-data`) read and traverse access but no write access to the code. Third, the only two directories Laravel must write to at runtime, `storage/` and `bootstrap/cache/`, get `775` plus an ACL that grants `www-data` write access, including on files created later.

```bash
sudo chown -R $USER:www-data /var/www/catatku
sudo find /var/www/catatku -type d -exec chmod 755 {} \;
sudo find /var/www/catatku -type f -exec chmod 644 {} \;

sudo chmod 640 /var/www/catatku/.env

sudo chmod -R 775 /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -R  -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -dR -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
```

`chown -R $USER:www-data` keeps your deploy user as the owner and sets the group to `www-data`. This is the heart of the secure model: because `www-data` (the user PHP-FPM runs as) does not own the code and the files are not group-writable, a compromised PHP process cannot rewrite your application's source. The two `find` commands normalize permissions across the whole tree: directories get `755` (`rwxr-xr-x`) so the group can enter them, files get `644` (`rw-r--r--`) so the group can read but not write them. `chmod 640 .env` is tighter still: the `.env` holds your database password and `APP_KEY`, so it is readable only by you (owner) and `www-data` (group), and invisible to every other account on the box.

Do not use `chmod -R 777` anywhere; it grants write access to every user on the system, including any process an attacker manages to run. Instead, the two writable directories get `775` *and* an ACL. The first `setfacl -R` grants the `www-data` user and group `rwX` (`X` adds the execute bit to directories only, never to plain files) on everything currently under `storage/` and `bootstrap/cache/`. The second `setfacl -dR` sets a *default* ACL, which every new file and directory created inside those trees inherits automatically. This is the part a plain `chmod` cannot do: during a deploy *you* write to `bootstrap/cache/` (via `php artisan optimize`), while at runtime *`www-data`* writes to `storage/logs/` and `storage/framework/`. With two different users writing the same directories, a default umask would leave each other's new files unwritable; the default ACL guarantees `www-data` always gets write access regardless of who created the file. If any deployment step later complains about permissions in `storage/logs/laravel.log` or `bootstrap/cache/config.php`, re-run the three `chmod`/`setfacl` commands above.

---

## 4. Setting Up MariaDB

MariaDB was installed in Section 2 but it still has its default state: no production database, no dedicated user, and the root account configured for local socket authentication only. This section secures the server, creates the `catatku_production` database with a restricted user, and runs the application migrations.

### Step 1: Secure MariaDB

Right after install, run the official security script. It sets a root password, removes the anonymous user, drops the test database, and disables remote root login.

```bash
sudo mysql_secure_installation
```

The script asks several questions interactively. Answer them in this order:

1. **Enter current password for root** — press Enter (it is empty on a fresh install).
2. **Switch to unix_socket authentication** — type `Y`. This is the Ubuntu default and lets root log in via `sudo mariadb` without a password, while remote logins stay disabled.
3. **Change the root password** — type `Y`, then type a strong password twice. (Nothing appears on screen as you type the password; that is normal.)
4. **Remove anonymous users** — type `Y`.
5. **Disallow root login remotely** — type `Y`.
6. **Remove test database and access to it** — type `Y`.
7. **Reload privilege tables now** — type `Y`.

These defaults are safe and recommended for any production server. Your session should look like the example below, where every prompt was answered with `Y` (the password entries are hidden as you type).

```
gungun@qadrlabs:$ sudo mysql_secure_installation

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Switch to unix_socket authentication [Y/n] y
Enabled successfully!
Reloading privilege tables..
 ... Success!

Change the root password? [Y/n] y
New password:
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success!

Remove anonymous users? [Y/n] y
 ... Success!

Disallow root login remotely? [Y/n] y
 ... Success!

Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

### Step 2: Create the Production Database and User

Log into MariaDB as root using socket authentication, then create a dedicated database and a user that can only access that one database.

```bash
sudo mariadb
```

Once at the `MariaDB [(none)]>` prompt, run the following SQL.

```sql
CREATE DATABASE catatku_production
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER 'catatku_user'@'localhost' IDENTIFIED BY 'REPLACE_WITH_A_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON catatku_production.* TO 'catatku_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

`utf8mb4` is the character set that supports the full Unicode range, including emoji; using the older `utf8` (which is actually `utf8mb3` in MariaDB) would corrupt 4-byte characters silently. `utf8mb4_unicode_ci` is a case-insensitive collation that handles non-English sorting correctly. The `@'localhost'` suffix on `CREATE USER` restricts the account to local socket and TCP connections, so the user cannot be reached from any external IP. `GRANT ALL PRIVILEGES ON catatku_production.*` gives the user complete control over the Catatku database, but no other database on the server, which limits the blast radius if the application is compromised. The password must be the exact value you set as `DB_PASSWORD` in the `.env` file from Section 3 Step 3.

### Step 3: Run Migrations

With the database created, run the migrations from the project directory as your deploy user. There is no `sudo` here: you own the code, so the command runs as yourself, and any files Laravel writes during migration land in directories the ACLs from Section 3 already make writable by both you and `www-data`.

```bash
cd /var/www/catatku
php artisan migrate --force
```

`--force` is required in production because Laravel asks for an interactive confirmation by default, and that prompt would hang in a non-interactive shell or fail in a script. After the command finishes, verify the migration state with `php artisan migrate:status`; every migration must be listed as `Ran`. This also confirms the application can actually connect to MariaDB using the credentials in `.env`.

### Step 4: Symlink Storage and Optimize

Two final commands wrap up application setup: expose user uploads to the web server, then cache configuration for performance.

```bash
php artisan storage:link
php artisan optimize
```

Run both as your deploy user, no `sudo` needed. `storage:link` creates a symbolic link from `public/storage` to `storage/app/public`. Without this link, the cover images uploaded in Lesson 7 are unreachable from the browser because anything outside `public/` is hidden from Nginx by design. `php artisan optimize` is Laravel 13's single convenience command that compiles configuration, routes, Blade templates, and auto-discovered event mappings into optimized PHP files in `bootstrap/cache/`. It replaces the older sequence of `config:cache`, `route:cache`, `view:cache`, and `event:cache`, and typically reduces request times by 15 to 30 percent because Laravel no longer re-parses those files on every request. If you ever need to clear all of these caches at once, run `php artisan optimize:clear`.

---

## 5. Configuring Nginx and HTTPS

Catatku is installed but Nginx does not know about it yet, and there is no SSL certificate. This section obtains a free certificate from Let's Encrypt and writes the Nginx server block that terminates HTTPS, forwards PHP requests to PHP-FPM, and redirects plain HTTP to HTTPS.

### Step 1: Obtain the SSL Certificate

Let's Encrypt verifies domain ownership by making an HTTP request to a special path on port 80. Because the default Nginx package starts on port 80 immediately after install, you must stop it briefly so Certbot can bind to that port itself.

```bash
sudo systemctl stop nginx
sudo certbot certonly --standalone -d catatku.example.com \
    --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx"
```

`systemctl stop nginx` shuts down the default Nginx service so port 80 is free. `certbot certonly` requests a certificate without trying to edit any Nginx configuration. `--standalone` tells Certbot to run a tiny temporary web server on port 80 to answer the ACME HTTP challenge. The `-d` flag names the domain the certificate is issued for, so pass your own domain here, exactly as you configured it in DNS. After Let's Encrypt validates the challenge, Certbot saves the certificate at `/etc/letsencrypt/live/catatku.example.com/fullchain.pem` and the private key at `/etc/letsencrypt/live/catatku.example.com/privkey.pem`; the directory under `/etc/letsencrypt/live/` is always named after your actual domain.

The `--pre-hook` and `--post-hook` flags solve a problem you would otherwise hit in 90 days. The certificate is only valid for that long, and Certbot installs a systemd timer that renews it automatically; verify the timer with `systemctl list-timers | grep certbot`. But renewal runs the same standalone challenge, which needs port 80, and by then Nginx will be running and occupying that port. Certbot saves both hooks into the renewal configuration under `/etc/letsencrypt/renewal/`, so every automatic renewal stops Nginx for a few seconds and starts it again afterward. Without the hooks, every renewal attempt would fail because the port is busy, and the certificate would silently expire after 90 days. Once Nginx is running (after Step 3 below), test the full renewal flow with `sudo certbot renew --dry-run`; it must report success for your domain.

### Step 2: Create the Nginx Server Block

Create a new server block file dedicated to Catatku. Keep the default site disabled so it does not steal port 80 from your domain.

```bash
sudo nano /etc/nginx/sites-available/catatku
```

Paste the following content into the editor. As with the `.env` file, replace every `catatku.example.com` with your own domain: it appears in both `server_name` directives and in the two certificate paths.

```nginx
server {
    listen 443 ssl http2;
    server_name catatku.example.com;

    ssl_certificate /etc/letsencrypt/live/catatku.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/catatku.example.com/privkey.pem;

    root /var/www/catatku/public;
    index index.php;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    charset utf-8;
    client_max_body_size 10M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

server {
    listen 80;
    server_name catatku.example.com;
    return 301 https://$server_name$request_uri;
}
```

Walk through each piece. `listen 443 ssl http2` accepts HTTPS connections on port 443 and enables HTTP/2 for multiplexed requests, which makes pages with many assets load faster. The two `ssl_certificate` lines point to the Certbot files written in Step 1; if those paths are wrong, Nginx fails to start. `root /var/www/catatku/public` is the security-critical line: Nginx only serves files inside `public/`, so the `.env` file, your source code, and your composer vendor tree are physically outside the document root and cannot be reached by URL. The `X-Frame-Options` and `X-Content-Type-Options` headers protect against clickjacking and MIME-sniffing attacks. `client_max_body_size 10M` matches the cover image upload limits introduced in Lesson 7; raise it if your application accepts larger uploads. The `try_files $uri $uri/ /index.php?$query_string` directive is the standard Laravel routing fallback: try the requested file, then a directory index, otherwise hand the request to `index.php` so Laravel's router can resolve it. The PHP location block forwards `.php` requests to PHP-FPM through its Unix socket, which is faster than a TCP connection on the same machine. The hidden-files block (`location ~ /\.(?!well-known).*`) denies access to any path starting with a dot (`.env`, `.git`, etc.) except `/.well-known/`, which Certbot uses for renewal challenges. The second server block (port 80) responds to every plain HTTP request with a `301` permanent redirect to the HTTPS version.

### Step 3: Enable the Site

Enabling a site in Nginx means symlinking its config from `sites-available/` into `sites-enabled/`. Remove the default site to avoid conflicts on port 80.

```bash
sudo ln -s /etc/nginx/sites-available/catatku /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

The symlink activates the new server block. `rm -f /etc/nginx/sites-enabled/default` removes the default Nginx welcome page so it does not race for port 80. `nginx -t` performs a syntax check; always run it before reload or restart, because a typo will refuse to start the service for every site on this server, not just Catatku. `systemctl restart nginx` (not `reload`) is needed here because Nginx was stopped in Step 1; in normal operation, use `systemctl reload nginx` to apply config changes without dropping existing connections.

### Step 4: Verify in Browser

Open `https://` followed by your own domain in a browser. The Catatku home page should load with the padlock icon indicating a valid certificate. 

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

If you see "502 Bad Gateway", check `sudo systemctl status php8.3-fpm` because Nginx could not reach the PHP-FPM socket. If you see "404 Not Found" on every route except `/`, the `root` directive in the Nginx config is pointing to the wrong directory. If you see a Let's Encrypt error or the browser warns about an invalid certificate, re-check that `dig +short catatku.example.com` returns the right IP and rerun Certbot.

---

## 6. Running the Queue Worker as a Service

In Lesson 13 you ran `php artisan queue:work` in a development terminal and stopped it when you closed the laptop. That approach does not survive an SSH disconnect, a server reboot, or a worker crash. In production you need a process manager that starts the worker on boot, restarts it on crash, and keeps it running 24/7. Supervisor is the standard Linux choice and was installed back in Section 2 Step 1.

### Step 1: Create the Supervisor Config

Each Supervisor-managed process is described by a `.conf` file in `/etc/supervisor/conf.d/`. Create one for the Catatku worker.

```bash
sudo nano /etc/supervisor/conf.d/catatku-worker.conf
```

Paste the following.

```ini
[program:catatku-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/catatku/artisan queue:work database --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/catatku/storage/logs/worker.log
stopwaitsecs=3600
```

Each directive earns its place. `[program:catatku-worker]` names the program; you will use this name with `supervisorctl` to start, stop, or check status. The `process_name` template formats instance names like `catatku-worker_00` and `catatku-worker_01` when multiple parallel workers run. `command` is the actual shell command Supervisor executes: `queue:work database` matches `QUEUE_CONNECTION=database` from your `.env` and tells the worker to read jobs from the `jobs` table in MariaDB. `--sleep=3` waits three seconds between polls when no jobs are pending, which keeps idle CPU usage near zero. `--tries=3` allows each job up to three attempts before being moved to `failed_jobs`. `--max-time=3600` recycles the worker after one hour to release any memory it accumulated. `autostart=true` starts the worker when Supervisor itself starts (which happens on boot). `autorestart=true` brings the worker back automatically if it exits unexpectedly. `user=www-data` runs the worker as the same user as PHP-FPM; this is deliberate. The worker executes your application code to process jobs, so running it as `www-data` (rather than your deploy user) means a compromised job cannot modify the source on disk, exactly the security boundary you set up in Section 3. The worker can still read the code through its group membership and write `worker.log` into `storage/logs/` through the ACL you applied earlier. `numprocs=2` runs two parallel worker instances; raise this number if you observe queue backlogs and your server has spare CPU. `redirect_stderr=true` merges stderr into stdout so a single log file captures everything. `stdout_logfile` directs that combined output to `storage/logs/worker.log`. `stopwaitsecs=3600` gives the worker up to one hour to finish its current job gracefully when Supervisor is asked to stop it, which prevents losing work mid-execution.

### Step 2: Start the Workers

Tell Supervisor to load the new file and start the workers.

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start catatku-worker:*
sudo supervisorctl status
```

The output looks like this:

```
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl reread
catatku-worker: available
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl update
catatku-worker: added process group
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl start catatku-worker:*
gungun@qadrlabs:/var/www/catatku$ sudo supervisorctl status
catatku-worker:catatku-worker_00   STARTING
catatku-worker:catatku-worker_01   STARTING
```

`reread` rescans `/etc/supervisor/conf.d/` for new or changed configurations. `update` applies the changes by stopping or starting any program affected by the rescan. `start catatku-worker:*` starts every instance covered by the program (the `:*` wildcard expands to `catatku-worker_00` and `catatku-worker_01`). `status` lists every Supervisor-managed process. Right after `start`, both entries may briefly show `STARTING` as in the example above; wait a few seconds and run `sudo supervisorctl status` again, and both worker entries must show `RUNNING`. From this moment on, the workers process queued jobs (emails, image processing, notifications, anything dispatched via `dispatch()` in your application) and will restart automatically across reboots and crashes.

---

## 7. Updating the Application with Git Pull

Once Catatku is live, every code change pushed to GitHub needs to be deployed to the server. This section uses the simplest reliable workflow: put the app into maintenance mode, pull the new code, re-install dependencies, rebuild assets, run migrations, refresh caches, restart workers, and bring the app back up. It costs a few seconds of downtime per deploy, which is acceptable for a small-to-medium site like Catatku.

### Step 1: Enter Maintenance Mode

Switch the application into maintenance mode so visitors receive a "Be right back" page instead of a half-deployed state.

```bash
cd /var/www/catatku
php artisan down
```

`php artisan down` writes a flag file at `storage/framework/maintenance.php`. As long as that file exists, every HTTP request returns `HTTP 503 Service Unavailable` with Laravel's default maintenance page. You run this (and every other command in this section) as your deploy user, with no `sudo`. The flag file lands in `storage/framework/`, which the ACL from Section 3 keeps readable by PHP-FPM, so the maintenance page shows correctly.

![maintenance mode](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/02-maintenance-mode.png)

### Step 2: Pull the Latest Code

Pull the latest commit from `origin/main` as your deploy user, the same account that owns the code.

```bash
git pull origin main
```

Because your deploy user owns every file under `/var/www/catatku`, a plain `git pull` just works and every file it creates stays owned by you with the group set to `www-data`. Do not prefix this with `sudo`: running as `root` would create `root`-owned files that PHP-FPM cannot read (confusing `500` errors after deploy), and running as `www-data` would hand the web-facing user write access to your code, defeating the security model from Section 3. Always run code-updating commands as your own deploy user.

### Step 3: Install Updated Dependencies

`composer.lock` and `package-lock.json` may have changed in the new commit. Reinstall both and rebuild the frontend bundle.

```bash
composer install --no-dev --optimize-autoloader
npm ci
npm run build
```

These are exactly the same three commands you ran during the first deploy, run by the same deploy user, so the update flow and the initial flow stay consistent. Running them as your own account (which has a normal home directory) also means Composer and npm find their caches in `~/.composer` and `~/.npm` without any HOME juggling. `composer install` is incremental: it only downloads packages that changed in `composer.lock`. `npm ci` wipes `node_modules/` and reinstalls the exact tree from `package-lock.json`, which is faster and more reliable than `npm install` during deploys. `npm run build` recompiles Vite assets into `public/build/` with fresh content hashes so browsers download the new files instead of serving stale ones from cache.

### Step 4: Run New Migrations

Apply any new migrations that came with the pull. The command is a no-op if there is nothing new to run, so it is safe to include in every deploy.

```bash
php artisan migrate --force
```

`migrate --force` runs only the migrations that have not been recorded in the `migrations` table yet, then records them. Skipping this step is the most common cause of `500` errors right after a deploy: the new code references a column the database does not have, and every request that touches that column fails.

### Step 5: Refresh Cache

The cached config, routes, and views from the previous deploy still describe the old code. Clear and rebuild them.

```bash
php artisan optimize:clear
php artisan optimize
```

`optimize:clear` removes every compiled file under `bootstrap/cache/`. `optimize` recompiles them based on the new code. Doing both ensures Laravel cannot accidentally serve a stale cached route or a Blade view that references a method removed in this deploy.

### Step 6: Restart Queue Workers

Running PHP worker processes still hold the old code in memory. Signal them to exit so Supervisor can start fresh workers with the new code.

```bash
php artisan queue:restart
```

`queue:restart` writes a timestamp to the cache. Each worker checks this timestamp between jobs; when it sees a newer value, the worker finishes its current job and then exits gracefully. Supervisor notices the process is gone and starts a new one (because `autorestart=true`), and that new process loads the new code. Without this step, jobs would keep running against the old code until the workers happen to recycle on their `--max-time` limit.

### Step 7: Exit Maintenance Mode

Take the app out of maintenance mode so real traffic comes back.

```bash
php artisan up
```

`php artisan up` deletes the `storage/framework/maintenance.php` flag file. The next HTTP request is processed normally and your users see the updated site. End-to-end downtime for the whole sequence is usually under a minute.

![preview app](https://cdn.jsdelivr.net/gh/qadrLabs/catatku-deploy-demo@main/docs/screenshot/01-preview-app.png)

### Step 8: Save as a Deploy Script

Running seven commands by hand every time is tedious and error-prone. Save them as a shell script so you can deploy with a single command.

```bash
nano /var/www/catatku/deploy.sh
```

No `sudo` here either: your deploy user owns the directory, so the script is created owned by you and stays runnable without elevation. Paste the following.

```bash
#!/bin/bash
set -e
cd /var/www/catatku
php artisan down
git pull origin main
composer install --no-dev --optimize-autoloader
npm ci
npm run build
php artisan migrate --force
php artisan optimize:clear
php artisan optimize
php artisan queue:restart
php artisan up
echo "Deploy finished."
```

Make it executable. You own the file, so no `sudo` is needed.

```bash
chmod +x /var/www/catatku/deploy.sh
```

`set -e` makes the script abort immediately on the first command that fails, so a broken migration does not silently leave the app half-deployed. Run it as your deploy user with `/var/www/catatku/deploy.sh` (not `sudo`) from now on, and it performs the entire update in order. If any step fails, the app stays in maintenance mode until you fix the problem and finish the script manually with `php artisan up`.

A successful run prints each step as it happens and ends with `Deploy finished.`:

```
gungun@qadrlabs:/var/www/catatku$ ./deploy.sh

   INFO  Application is now in maintenance mode.

From https://github.com/qadrLabs/catatku-deploy-demo
 * branch            main       -> FETCH_HEAD
Already up to date.
Installing dependencies from lock file
Verifying lock file contents can be installed on current platform.
Nothing to install, update or remove
Generating optimized autoload files
> Illuminate\Foundation\ComposerScripts::postAutoloadDump
> @php artisan package:discover --ansi

   INFO  Discovering packages.

  laravel/sanctum ....................................................... DONE
  laravel/tinker ........................................................ DONE
  nesbot/carbon ......................................................... DONE
  nunomaduro/termwind ................................................... DONE

added 63 packages, and audited 64 packages in 4s

> build
> vite build

vite v8.0.16 building client environment for production...
✓ 3 modules transformed.
computing gzip size...
public/build/manifest.json                  2.51 kB │ gzip:  0.43 kB
public/build/assets/app-BK4ejP5Q.css        45.51 kB │ gzip: 10.49 kB
public/build/assets/app-BvRk9kiK.js          0.00 kB │ gzip:  0.02 kB

✓ built in 550ms

   INFO  Nothing to migrate.


   INFO  Clearing cached bootstrap files.

  config ......................................................... 1.99ms DONE
  cache ......................................................... 30.13ms DONE
  compiled ....................................................... 1.28ms DONE
  events ......................................................... 0.84ms DONE
  routes ......................................................... 0.89ms DONE
  views ......................................................... 77.70ms DONE


   INFO  Caching framework bootstrap, configuration, and metadata.

  config ........................................................ 16.78ms DONE
  events ......................................................... 1.86ms DONE
  routes ........................................................ 22.02ms DONE
  views ......................................................... 49.00ms DONE


   INFO  Broadcasting queue restart signal.


   INFO  Application is now live.

Deploy finished.
```

On the very first deploy you will see real output for the `git pull`, dependency installs, and migrations instead of "Already up to date" and "Nothing to migrate"; on later deploys with no new changes the output stays this short. The `From https://github.com/qadrLabs/catatku-deploy-demo` line reflects whichever repository you cloned in Section 3, so it will show your own repository URL if you used a personal one.

---

## 8. Fix the Errors in Your Code

These are the three errors that bite almost every first-time deployer.

**Error 1: Leaving `APP_DEBUG=true` in the production environment.**

This is a security vulnerability. With debug mode on, any exception page exposes `.env` values, file paths, and a full stack trace to whoever triggered the error, including attackers probing the site.

```env
// Wrong:
APP_DEBUG=true

// Correct:
APP_DEBUG=false
```

With `APP_DEBUG=true`, the browser shows database credentials and API keys whenever something throws an exception. With `APP_DEBUG=false`, the browser shows a generic "Server Error" page and the real details go to `storage/logs/laravel.log` where only you can read them. After changing the value, run `php artisan optimize:clear && php artisan optimize` (as your deploy user) so the cached config picks up the new value.

---

**Error 2: Forgetting to run migrations after pulling new code.**

New code often references new columns or tables. If the migration has not run yet, every request that touches the affected model returns a `500` and users see a generic error page.

```bash
// Wrong:
git pull origin main
php artisan up

// Correct:
git pull origin main
php artisan migrate --force
php artisan up
```

In the wrong version, the code now expects a `cover_image` column that does not exist in production yet, and the SQL query fails on the very first request. The correct version always runs `migrate --force` after `git pull`, so the schema catches up before users see the new code. If a migration ever breaks production, `php artisan migrate:rollback` reverts the most recent batch while you investigate.

---

**Error 3: Running deploy commands as the wrong user.**

Code-updating commands must run as your deploy user, the account that owns `/var/www/catatku`. Running as `root` (plain `sudo`) creates `root`-owned files that PHP-FPM cannot read, which surfaces as `500` errors on routes that touch the new files. Running as `www-data` "works" but hands the web-facing user write access to your source code, defeating the secure model from Section 3.

```bash
// Wrong (root-owned files):
sudo git pull origin main

// Also wrong (web user can now write your code):
sudo -u www-data git pull origin main

// Correct (your deploy user owns the code):
git pull origin main
```

The correct version runs as your own deploy user, so files stay owned by you with the group set to `www-data`, the security boundary holds, and PHP-FPM still reads the code through its group membership. If you ever accidentally run a write command as `root`, restore the ownership and ACLs before bringing the site back up:

```bash
sudo chown -R $USER:www-data /var/www/catatku
sudo chmod -R 775 /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -R  -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
sudo setfacl -dR -m u:www-data:rwX,g:www-data:rwX /var/www/catatku/storage /var/www/catatku/bootstrap/cache
```

---

## 9. Exercises

Each exercise extends the production setup with one realistic concern: backups, scheduling, and uptime monitoring. Finish Section 7 first so you have a working deploy script before attempting these.

**Exercise 1:** Write a daily MariaDB backup script that uses `mariadb-dump` to dump `catatku_production` to `/var/backups/catatku/`, compresses the file with `gzip`, and keeps only the last 7 days of backups. Schedule it via cron to run at 02:00 every day.

**Exercise 2:** Laravel's task scheduler runs from `routes/console.php`, but it needs a single cron tick every minute to fire. Add the required entry to `www-data`'s crontab and verify by scheduling a one-off log message that runs every minute, then watching `storage/logs/laravel.log`.

**Exercise 3:** Verify the built-in `/up` health route works at `https://catatku.example.com/up` (with your own domain in place of the placeholder), then sign up at UptimeRobot (free) and configure it to ping that URL every 5 minutes and email you when the status drops out of the 200 range.

---

## 10. Solutions

Compare your work with the references below. Each solution highlights the key decisions rather than every detail.

**Solution for Exercise 1:**

Create `/usr/local/bin/catatku-backup.sh` with the following content.

```bash
#!/bin/bash
set -e

BACKUP_DIR=/var/backups/catatku
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME=catatku_production
DB_USER=catatku_user
DB_PASSWORD=REPLACE_WITH_A_STRONG_PASSWORD

mkdir -p "$BACKUP_DIR"

mariadb-dump --single-transaction --quick \
    -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
    | gzip > "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +7 -delete
```

Make it executable and schedule it.

```bash
sudo chmod +x /usr/local/bin/catatku-backup.sh
sudo crontab -e
```

Add the following crontab line.

```
0 2 * * * /usr/local/bin/catatku-backup.sh >> /var/log/catatku-backup.log 2>&1
```

`mariadb-dump --single-transaction --quick` produces a consistent dump without locking the entire database, which keeps the site responsive during the backup. `gzip` compresses the dump (typically 5-10x smaller for text-heavy SQL). `find ... -mtime +7 -delete` removes any backup older than 7 days, so the disk does not fill up over time. The cron entry runs the script at 02:00 daily and appends both stdout and stderr to `/var/log/catatku-backup.log` so you have an audit trail. Run the script once manually with `sudo /usr/local/bin/catatku-backup.sh` to confirm the first backup succeeds before relying on the schedule.

---

**Solution for Exercise 2:**

Open the crontab of `www-data`.

```bash
sudo crontab -u www-data -e
```

Add the following line.

```
* * * * * cd /var/www/catatku && php artisan schedule:run >> /dev/null 2>&1
```

This single cron entry fires once per minute. Each invocation calls `php artisan schedule:run`, which checks `routes/console.php` for any task whose schedule matches the current minute and dispatches the matching tasks. The `>> /dev/null 2>&1` discards output because `schedule:run` is silent on success; if you want to capture failures, redirect to a real log file instead. To verify the scheduler is working, temporarily add the following to `routes/console.php`.

```php
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Log;

Schedule::call(fn () => Log::info('Scheduler tick'))->everyMinute();
```

Wait a minute, then check `storage/logs/laravel.log` for the `Scheduler tick` entry. Remove the test schedule afterward.

---

**Solution for Exercise 3:**

Laravel 13 registers the `/up` route automatically. You can inspect or change its URI in `bootstrap/app.php`.

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

Visit `https://catatku.example.com/up` (with your own domain) in a browser. A `200 OK` response confirms the application boots without exceptions; a `500` response means something is broken in the boot process and the body of the response will list the failure.

To monitor it externally, sign up at uptimerobot.com (free tier allows 50 monitors at 5-minute intervals), click "Add New Monitor", choose "HTTP(s)" as the type, enter your own `/up` URL, set the monitoring interval to 5 minutes, and add your email as an alert contact. UptimeRobot now pings the health route every five minutes from multiple geographic locations. If two consecutive checks return a non-200 status, you receive an email within seconds. This is the cheapest possible "is my site up?" monitoring and it should be the first observability you add to any production deployment.

---

## Next Up - Lesson 18

In this lesson you took Catatku from a clean Ubuntu VPS to a live HTTPS application at your own domain. You installed Nginx, PHP 8.3, MariaDB, Supervisor, and Certbot; pointed the domain at the server; cloned `https://github.com/qadrLabs/catatku-deploy-demo` (or your own repository) into `/var/www/catatku`; created a production `.env` with `APP_DEBUG=false` and `database` drivers for cache, queue, and session; set up a secure ownership model where your deploy user owns the code and `www-data` only reads it, with ACLs granting write access to `storage/` and `bootstrap/cache/`; obtained a free SSL certificate from Let's Encrypt; wrote an Nginx server block with HTTP-to-HTTPS redirect; ran two Supervisor-managed queue workers; and saved a `deploy.sh` script that updates the site with a single command using `git pull`.

In Lesson 18, you will step back and review the full path you have walked across this course: a recap of all 17 features you added on top of the basic Catatku app, a comparison of beginner versus intermediate Laravel skills, and a roadmap of advanced topics including Livewire, Inertia.js, Scout, Horizon, and Cashier that you can explore next.