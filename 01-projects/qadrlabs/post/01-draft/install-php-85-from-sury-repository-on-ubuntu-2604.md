# How to Install PHP 8.5 and PHP-FPM from packages.sury.org on Ubuntu 26.04 for Laravel and Nginx

The Ondrej PPA used to be the standard answer for running a newer PHP than Ubuntu ships, and a [previous article](https://qadrlabs.com/post/cara-install-php-85-menggunakan-ppa-ondrej-php-di-ubuntu-2504) showed a workaround for Ubuntu 25.04 by pointing the PPA at the `noble` suite. That trick no longer helps on Ubuntu 26.04 (codename `resolute`). The Launchpad page for the PPA now announces that the repository is being merged into `packages.sury.org/php`, and that the new location is the canonical way to get PHP packages for Ubuntu Resolute.

The catch is that a fresh Ubuntu 26.04 machine often already has PHP, either from the official Ubuntu archive or from an earlier experiment. Adding a second source on top of an existing installation without cleaning up first leads to mixed package versions, a php-fpm socket that nginx no longer finds, and a `502 Bad Gateway` on a site that worked yesterday. A careful removal followed by a clean install avoids all of that.

In this tutorial, we will inspect and safely remove the PHP packages that come from Ubuntu, add the `packages.sury.org` repository, install PHP 8.5 with PHP-FPM and the extensions Laravel needs, and connect it to nginx.

## Overview {#overview}

This tutorial is a hands-on migration. We start from a machine that already has PHP installed from the Ubuntu archive, remove it without damaging nginx or the rest of the system, and replace it with PHP 8.5 from the Sury repository. Every command is explained, and the final step verifies the setup with a real Laravel project.

### What You'll Build

- A clean Ubuntu 26.04 environment with the Ubuntu-provided PHP packages removed.
- The `packages.sury.org/php` repository configured with its signing keyring.
- PHP 8.5 CLI and PHP-FPM with the common extensions for Laravel development.
- An nginx server block that sends `.php` requests to the PHP 8.5 FPM socket.

### What You'll Learn

- How to find out where an installed PHP comes from before touching it.
- How to check what depends on PHP-FPM so nothing breaks unexpectedly.
- How to back up package selections and configuration files before removal.
- How to preview a removal with a dry run before running it for real.
- How to add the Sury repository and confirm that apt now prefers it.
- How to wire PHP-FPM to nginx and test the result with Laravel.

### What You'll Need

- Ubuntu 26.04 (`resolute`) with a user that has `sudo` access.
- nginx already installed.
- Basic comfort with the terminal and with editing files using `nano`.
- [Composer](https://getcomposer.org) and the [Laravel installer](https://laravel.com/docs/13.x/installation) if you want to run the final Laravel check.

## Step 1: Check What Is Already Installed {#step-1-check-what-is-already-installed}

Before removing anything, we need to know exactly what is on the machine and where it came from. Removing packages you do not understand is how a working development environment turns into a broken one.

First, check the PHP version and the path of the `php` binary.

```bash
php -v
which php
```

The first command prints the version and, on the third line, who built this PHP. The second shows which binary the shell runs. Output:

```
$ php -v
which php
PHP 8.5.4 (cli) (built: Oct 19 2026 14:35:18) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.4, Copyright (c) Zend Technologies
    with Xdebug v3.5.0, Copyright (c) 2002-2025, by Derick Rethans
    with Zend OPcache v8.5.4, Copyright (c), by Zend Technologies
/usr/bin/php

```

Next, list every PHP-related package that apt knows about.

```bash
dpkg -l | grep -i php
```

`dpkg -l` lists installed packages and `grep -i php` keeps only the lines that mention PHP. Packages that start with `ii` are installed. Output:

```
$ dpkg -l | grep -i php
rc  libapache2-mod-php8.4                            8.4.11-1ubuntu1.1                          amd64        server-side, HTML-embedded scripting language (Apache 2 module)
ii  libapache2-mod-php8.5                            8.5.4-0ubuntu1.5                           amd64        server-side, HTML-embedded scripting language (Apache 2 module)
ii  php                                              2:8.5+99ubuntu1                            all          server-side, HTML-embedded scripting language (default)
ii  php-bz2                                          2:8.5+99ubuntu1                            all          bzip2 module for PHP [default]
ii  php-cli                                          2:8.5+99ubuntu1                            all          command-line interpreter for the PHP scripting language (default)
.
.
.
.
.
.
.
ii  php8.5-zip                                       8.5.4-0ubuntu1.5                           amd64        Zip module for PHP

```

Then confirm where the PHP-FPM package comes from.

```bash
apt-cache policy php8.5-fpm
```

The `Installed` and `Candidate` lines show the version, and the lines below show the repository that provides it. If the origin points to `archive.ubuntu.com` or `security.ubuntu.com`, the package comes from Ubuntu itself. Output:

```
$ apt-cache policy php8.5-fpm
php8.5-fpm:
  Installed: 8.5.4-0ubuntu1.5
  Candidate: 8.5.4-0ubuntu1.5
  Version table:
 *** 8.5.4-0ubuntu1.5 500
        500 http://archive.ubuntu.com/ubuntu resolute-updates/universe amd64 Packages
        500 http://security.ubuntu.com/ubuntu resolute-security/universe amd64 Packages
        100 /var/lib/dpkg/status
     8.5.4-0ubuntu1 500
        500 http://archive.ubuntu.com/ubuntu resolute/universe amd64 Packages

```

Finally, check whether PHP-FPM is running.

```bash
systemctl status php8.5-fpm
```

Output:

```
$ systemctl status php8.5-fpm
● php8.5-fpm.service - The PHP 8.5 FastCGI Process Manager
     Loaded: loaded (/usr/lib/systemd/system/php8.5-fpm.service; enabled; prese>
     Active: active (running) since Mon 2026-11-02 21:51:49 WIB; 15h ago
 Invocation: 080ff8496bb9484e9b220d955dd90b7c
       Docs: man:php-fpm8.5(8)
   Main PID: 1832 (php-fpm8.5)
     Status: "Processes active: 0, idle: 2, Requests: 0, slow: 0, Traffic: 0.00>
      Tasks: 3 (limit: 18282)
     Memory: 20.7M (peak: 26.4M)
        CPU: 3.550s
     CGroup: /system.slice/php8.5-fpm.service
             ├─1832 "php-fpm: master process (/etc/php/8.5/fpm/php-fpm.conf)"
             ├─1893 "php-fpm: pool www"
             └─1894 "php-fpm: pool www"

```

After this step we know which packages we are about to replace. Adjust the version number (`php8.5-fpm`) in these commands if your machine has a different PHP version installed.

## Step 2: Check What Depends on PHP-FPM {#step-2-check-what-depends-on-php-fpm}

Stopping PHP-FPM affects every site that sends requests to its socket. Before we stop it, let's find out which nginx configuration points to it.

```bash
grep -rn "fastcgi_pass" /etc/nginx/sites-enabled/ /etc/nginx/conf.d/
```

This searches all enabled nginx site files for the `fastcgi_pass` directive, which tells nginx where PHP-FPM listens. Output:

```
$ grep -rn "fastcgi_pass" /etc/nginx/sites-enabled/ /etc/nginx/conf.d/

```

Now list the sockets that are actually open.

```bash
ss -lnx | grep php
```

`ss -lnx` lists listening Unix sockets. A line such as `/run/php/php8.5-fpm.sock` means the Ubuntu PHP-FPM is serving requests right now. Output:

```
$ ss -lnx | grep php

u_str LISTEN 0      4096                                                             /run/php/php8.5-fpm.sock 23728             * 0   


```

The first command printed nothing, even though the sites are enabled. The reason is that every file in `sites-enabled` is a symbolic link, and `grep -r` does not follow symbolic links. Use `grep -Rn` (capital `R`) instead when you search these folders, and the matching `fastcgi_pass` lines will show up.

Write down the sites that use `/run/php/php8.5-fpm.sock`. They will return `502 Bad Gateway` between Step 4 and Step 8, which is expected, and we will reconnect them in Step 8.

## Step 3: Back Up Package Selections and Configuration {#step-3-back-up-package-selections-and-configuration}

A removal is easy to undo only if we kept a record of what existed. These three commands take a few seconds and give us a way back.

```bash
dpkg --get-selections | grep -i php > ~/php-apt-selections.txt
sudo cp -a /etc/php ~/php-etc-backup
sudo cp -a /etc/nginx ~/nginx-etc-backup
```

The first command saves the list of installed PHP packages to a text file, so we can reinstall the same set later. The second copies the whole PHP configuration folder, including `php.ini` and the FPM pool files. The third copies the nginx configuration. The `-a` flag keeps permissions and timestamps.

Now confirm the current nginx configuration is valid, so we know any later error was introduced by our changes.

```bash
sudo nginx -t
```

Output:

```
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

```

## Step 4: Remove the Ubuntu PHP Packages {#step-4-remove-the-ubuntu-php-packages}

Now we remove the PHP packages from the Ubuntu archive. We do this in three small moves: stop the service, preview the removal, and then run it.

Stop PHP-FPM first, so no process is holding the socket.

```bash
sudo systemctl stop php8.5-fpm
```

Next, simulate the removal. The `-s` flag tells apt to only show what it would do and change nothing.

```bash
sudo apt-get -s remove 'php*'
```

Read the output carefully. The quoted `'php*'` pattern matches every package whose name starts with `php`, so the list should contain only PHP packages. If `nginx` or any package you want to keep appears in the list of packages to be removed, stop here and review the list before continuing. Output:

```
$ sudo apt-get -s remove 'php*'
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Note, selecting 'php8.4-pdo' for glob 'php*'
Note, selecting 'php-composer-metadata-minifier' for glob 'php*'
.
.
.
.
The following packages will be REMOVED:
  libapache2-mod-php8.5 php php-bz2 php-cli php-common php-curl php-fpm php-gd
  php-intl php-mbstring php-mysql php-pgsql php-redis php-sqlite3 php-tidy
  php-xml php-zip php8.5 php8.5-bz2 php8.5-cli php8.5-common php8.5-curl
  php8.5-fpm php8.5-gd php8.5-igbinary php8.5-intl php8.5-mbstring
  php8.5-mysql php8.5-pgsql php8.5-readline php8.5-redis php8.5-sqlite3
  php8.5-tidy php8.5-xdebug php8.5-xml php8.5-zip
0 upgraded, 0 newly installed, 36 to remove and 33 not upgraded.

.
.
.
.
Remv php8.5-pgsql [8.5.4-0ubuntu1.5] [php8.5-tidy:amd64 php8.5-sqlite3:amd64 php8.5-readline:amd64 ]
Remv php8.5-readline [8.5.4-0ubuntu1.5] [php8.5-tidy:amd64 php8.5-sqlite3:amd64 ]
Remv php8.5-sqlite3 [8.5.4-0ubuntu1.5] [php8.5-tidy:amd64 ]
Remv php8.5-tidy [8.5.4-0ubuntu1.5]

```

If the list contains only PHP packages, run the real removal.

```bash
sudo apt remove 'php*'
```

We use `remove` rather than `purge` on purpose. `remove` deletes the program files but keeps the configuration under `/etc/php`, which is a safer default while we are still verifying the migration. Once everything works, `sudo apt purge 'php*'` can clean up the leftover configuration.

Then clean up the dependencies that were only installed for PHP. Again, preview first.

```bash
sudo apt-get -s autoremove
```

If the list looks reasonable, run it.

```bash
sudo apt autoremove
```

Finally, verify that no PHP packages remain installed and that nginx itself is untouched.

```bash
dpkg -l | grep -i php
nginx -v
```

The first command should print nothing, or only packages in the `rc` state, which means "removed, configuration kept". Output:

```
$ dpkg -l | grep -i php
nginx -v
rc  libapache2-mod-php8.4                            8.4.11-1ubuntu1.1                          amd64        server-side, HTML-embedded scripting language (Apache 2 module)

.
.
.
rc  php8.5-xml                                       8.5.4-0ubuntu1.5                           amd64        DOM, SimpleXML, XML, and XSL module for PHP
rc  php8.5-zip                                       8.5.4-0ubuntu1.5                           amd64        Zip module for PHP
nginx version: nginx/1.28.3 (Ubuntu)

```

## Step 5: Remove Old Ondrej PPA Files {#step-5-remove-old-ondrej-ppa-files}

If you followed the earlier Ubuntu 25.04 tutorial or added `ppa:ondrej/php` in the past, an old source file may still be on the machine. A leftover source that points to a suite that no longer exists makes `apt update` print errors on every run, so we remove it before adding the new repository.

```bash
ls /etc/apt/sources.list.d/ | grep -i -E "ondrej|sury"
```

This lists any file that mentions Ondrej or Sury. Output:

```
$ ls /etc/apt/sources.list.d/ | grep -i -E "ondrej|sury"
ondrej-ubuntu-php-plucky.sources
ondrej-ubuntu-php-plucky.sources.save

```

For each Ondrej PPA file in the list (for example `ondrej-ubuntu-php-plucky.sources`), remove it. Replace the file name with the one shown on your machine.

```bash
sudo rm /etc/apt/sources.list.d/ondrej-ubuntu-php-plucky.sources
```

Then refresh the package list and make sure it finishes without errors.

```bash
sudo apt update
```

Output:

```
$ sudo apt update
Get:1 https://dl.google.com/linux/chrome-stable/deb stable InRelease [2,548 B]
Hit:2 https://brave-browser-apt-release.s3.brave.com stable InRelease  
.
.
.
Fetched 3,471 kB in 10s (348 kB/s) 

```

## Step 6: Add the Sury Repository {#step-6-add-the-sury-repository}

Now we add the new repository. The steps below follow the official instructions at [packages.sury.org/php/README.txt](https://packages.sury.org/php/README.txt).

Install the small tools the script needs.

```bash
sudo apt-get update
sudo apt-get -y install lsb-release ca-certificates curl
```

`lsb-release` gives us the Ubuntu codename, `ca-certificates` lets `curl` verify HTTPS connections, and `curl` downloads the keyring. Next, download and install the signing keyring.

```bash
sudo curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
sudo dpkg -i /tmp/debsuryorg-archive-keyring.deb
```

The keyring is a small package that places the repository's public key in `/usr/share/keyrings/`. Apt uses this key to confirm that every package really comes from Sury and was not changed in transit.

Now create the repository file.

```bash
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
```

This writes a single line to `/etc/apt/sources.list.d/php.list`. The `signed-by` option ties the repository to its own key, and `$(lsb_release -sc)` expands to `resolute` on Ubuntu 26.04. Check the result.

```bash
cat /etc/apt/sources.list.d/php.list
```

Output:

```
$ cat /etc/apt/sources.list.d/php.list
deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ resolute main

```

Refresh the package list.

```bash
sudo apt-get update
```

Output:

```
$ sudo apt-get update
Hit:1 https://dl.google.com/linux/chrome-stable/deb stable InRelease
Hit:2 https://packages.microsoft.com/repos/code stable InRelease               
Get:3 https://packages.sury.org/php resolute InRelease [6,103 B]               
.
.
.                       
Get:5 https://packages.sury.org/php resolute/main amd64 Packages [141 kB]      
.
.
.
Fetched 147 kB in 1s (106 kB/s)
Reading package lists... Done

```

Look for a line that contains `packages.sury.org/php resolute` in the output. Finally, confirm that apt now prefers the Sury package.

```bash
apt-cache policy php8.5-fpm
```

The `Candidate` version should now come from `https://packages.sury.org/php resolute/main`. Output:

```
 apt-cache policy php8.5-fpm
php8.5-fpm:
  Installed: (none)
  Candidate: 8.5.12-1+0~20261021.27+ubuntu26.04~1.gbp1a3e8a
  Version table:
     8.5.12-1+0~20261021.27+ubuntu26.04~1.gbp1a3e8a 500
        500 https://packages.sury.org/php resolute/main amd64 Packages
     8.5.4-0ubuntu1.5 500
        500 http://archive.ubuntu.com/ubuntu resolute-updates/universe amd64 Packages
        500 http://security.ubuntu.com/ubuntu resolute-security/universe amd64 Packages
        100 /var/lib/dpkg/status
     8.5.4-0ubuntu1 500
        500 http://archive.ubuntu.com/ubuntu resolute/universe amd64 Packages

```

## Step 7: Install PHP 8.5, PHP-FPM, and Laravel Extensions {#step-7-install-php-85-php-fpm-and-laravel-extensions}

With the repository in place, we can install PHP. For a Laravel project served by nginx, we need the CLI (for Artisan and Composer), PHP-FPM (for nginx), and the extensions the framework expects.

```bash
sudo apt install php8.5-cli php8.5-fpm php8.5-common php8.5-mbstring php8.5-xml php8.5-curl php8.5-zip php8.5-bcmath php8.5-intl php8.5-gd php8.5-mysql php8.5-sqlite3
```

Here is what each part does:

- `php8.5-cli` provides the `php` command used by Artisan and Composer.
- `php8.5-fpm` provides the FastCGI process manager that nginx talks to.
- `php8.5-mbstring`, `php8.5-xml`, `php8.5-curl`, and `php8.5-zip` are required by Laravel and Composer.
- `php8.5-bcmath` and `php8.5-intl` are used by many packages for number and locale handling.
- `php8.5-gd` handles image processing.
- `php8.5-mysql` and `php8.5-sqlite3` cover the two databases used most often in Laravel projects. Add `php8.5-pgsql` or `php8.5-redis` if your project needs them.

Output:

```
$ sudo apt install php8.5-cli php8.5-fpm php8.5-common php8.5-mbstring php8.5-xml php8.5-curl php8.5-zip php8.5-bcmath php8.5-intl php8.5-gd php8.5-mysql php8.5-sqlite3
Installing:                     
  php8.5-bcmath  php8.5-curl  php8.5-intl      php8.5-sqlite3
  php8.5-cli     php8.5-fpm   php8.5-mbstring  php8.5-xml
  php8.5-common  php8.5-gd    php8.5-mysql     php8.5-zip

Installing dependencies:
  libargon2-1  libzip5  php-common  php8.5-readline

Suggested packages:
  php-pear
.
.
.
.
```

Press `y`, then `enter`, when apt asks for confirmation. After the installation finishes, verify the version.

```bash
php -v
```

The version number is what tells the two builds apart. Before the migration it was `8.5.4`, and now it is `8.5.12`, the version provided by the Sury repository. The build line still says `Built by Ubuntu` because the Sury packages are built for Ubuntu as well, so do not use that line to tell the sources apart. Output:

```
$ php -v
PHP 8.5.12 (cli) (built: Oct 21 2026 08:07:33) (NTS)
Copyright (c) The PHP Group
Built by Ubuntu
Zend Engine v4.5.12, Copyright (c) Zend Technologies
    with Zend OPcache v8.5.12, Copyright (c), by Zend Technologies

```

List the loaded extensions to confirm the install.

```bash
php -m
```

Output:

```
$ php -m
[PHP Modules]
bcmath
calendar
Core
ctype
curl
date
dom
exif
.
.
.
.
[Zend Modules]
Zend OPcache

```

If you ever install more than one PHP version from Sury, each one has its own binary such as `php8.4` and `php8.5`. The `update-alternatives --config php` command lets you choose which one answers to plain `php`.

## Step 8: Connect PHP-FPM to Nginx {#step-8-connect-php-fpm-to-nginx}

PHP-FPM is installed, so let's make sure it is running and enabled at boot.

```bash
sudo systemctl enable --now php8.5-fpm
systemctl status php8.5-fpm
```

`enable --now` starts the service immediately and also starts it on every boot. Output:

```
$ sudo systemctl enable --now php8.5-fpm
systemctl status php8.5-fpm
Synchronizing state of php8.5-fpm.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable php8.5-fpm
● php8.5-fpm.service - The PHP 8.5 FastCGI Process Manager
     Loaded: loaded (/usr/lib/systemd/system/php8.5-fpm.service; enabled; prese>
     Active: active (running) since Tue 2026-11-03 13:18:05 WIB; 1min 14s ago
 Invocation: e868fc64086d4e949a5fbbf97d27ca15
       Docs: man:php-fpm8.5(8)
   Main PID: 177059 (php-fpm8.5)
     Status: "Processes active: 0, idle: 2, Requests: 0, slow: 0, Traffic: 0.00>
      Tasks: 3 (limit: 18282)
     Memory: 12.9M (peak: 15.3M)
        CPU: 102ms
     CGroup: /system.slice/php8.5-fpm.service
             ├─177059 "php-fpm: master process (/etc/php/8.5/fpm/php-fpm.conf)"
             ├─177060 "php-fpm: pool www"
             └─177061 "php-fpm: pool www"

Nov 03 13:18:04 qadrlabs systemd[1]: Starting php8.5-fpm.service - The PHP 8.5 >

.
.
.
```

Now confirm that the socket exists.

```bash
ls -l /run/php/
```

Output:

```
$ ls -l /run/php/
total 0
lrwxrwxrwx 1 root     root     30 Nov  2 21:51 php-fpm.sock -> /etc/alternatives/php-fpm.sock
srw-rw---- 1 www-data www-data  0 Nov  3 13:18 php8.5-fpm.sock

```

The socket path is `/run/php/php8.5-fpm.sock`. Open your Laravel site configuration. The file name below is an example, so use your own.

```bash
sudo nano /etc/nginx/sites-available/myapp.test
```

A minimal server block for Laravel looks like this.

```nginx
server {
    listen 80;
    server_name myapp.test;

    # Laravel serves everything from the public folder
    root /home/your-user/sandbox/myapp/public;
    index index.php;

    location / {
        # Send unknown paths to Laravel's front controller
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;

        # Must match the socket created by PHP-FPM
        fastcgi_pass unix:/run/php/php8.5-fpm.sock;
    }

    location ~ /\.(?!well-known).* {
        # Never serve hidden files such as .env
        deny all;
    }
}
```

Replace `your-user` in the `root` line with your own Linux username, or with the full path to your project. The block is a template, so if you paste it as it is, nginx cannot find the `public` folder and the site will not show your Laravel app. Run `echo $HOME` if you are not sure about the path.

The `root` points to Laravel's `public` folder, so source code and `.env` are never exposed. The `try_files` line hands routes like `/posts/1` to `index.php`. The `fastcgi_pass` line is the important one for this tutorial: it must match the socket from the previous command. If your existing sites already use `/run/php/php8.5-fpm.sock`, they need no change, because the new package creates the same socket path.

Save the file with `CTRL+O`, exit with `CTRL+X`, then test and reload nginx.

```bash
sudo nginx -t
sudo systemctl reload nginx
```

`nginx -t` checks the syntax and `reload` applies the change without dropping existing connections. Output:

```
~/sandbox$ sudo nginx -t
sudo systemctl reload nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

```

If the site is new, enable it and add the hostname to `/etc/hosts`.

```bash
sudo ln -s /etc/nginx/sites-available/myapp.test /etc/nginx/sites-enabled/
echo "127.0.0.1 myapp.test" | sudo tee -a /etc/hosts
```

## Step 9: Try It Out with a Laravel Project {#step-9-try-it-out-with-a-laravel-project}

Finally, let's prove the whole chain works: Composer, PHP 8.5, PHP-FPM, and nginx. We create a throwaway project under `~/sandbox`, outside any repository.

```bash
mkdir -p ~/sandbox && cd ~/sandbox
laravel new myapp --no-interaction --database=sqlite --pest --no-boost
cd myapp
```

Check that Laravel runs on the new PHP.

```bash
php artisan about
```

Output:

```
$ php artisan about

  Environment ................................................................  
  Application Name ................................................... Laravel  
  Laravel Version .................................................... 13.39.0  
  PHP Version ......................................................... 8.5.12  
  Composer Version .................................................... 2.10.0  
  Environment .......................................................... local  
  Debug Mode ......................................................... ENABLED  
  URL ......................................................... localhost:8000  
  Maintenance Mode ....................................................... OFF  
  Timezone ............................................................... UTC  
  Locale .................................................................. en  
```

The environment section should list PHP version `8.5.x`. Make sure nginx can read and write what Laravel needs.

```bash
sudo chown -R $USER:www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache
```

Now open `http://myapp.test` in the browser. You should see the Laravel welcome page. To confirm that PHP-FPM, not the CLI, served the request, use `curl`.

```bash
curl -I http://myapp.test
```

Output:

```
$ curl -I http://myapp.test
HTTP/1.1 200 OK
Server: nginx/1.28.3 (Ubuntu)
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Cache-Control: no-cache, private
Date: Tue, 03 Nov 2026 06:33:07 GMT
Set-Cookie: XSRF-TOKEN=eyJpdiI6IkF6S3UrdkhhVG8xdW1xc1VZNUwzV3c9PSIsInZhbHVlIjoiWGxmbnIvTXl0c3MxTWFMbkZlbVZjL3RaV25URW15eUJwSjZ0eDFJV2prSTBXNWQ5SXdJMzVFbk51ajc2Vnhpd0VpZ0xQMFNJcUUyQ1RzT0NuVTUwaHZkS09wTlcxaGx1N2VkS0NTM2lpQVlGYmtTcEI1dVY5SGZPbGNSYm52bnMiLCJtYWMiOiI5NTE0MTE5OGQzYTQ0ODA4YjhiY2ZkYWE4MWI5ZjI3MDIyNzE1MDU1Y2Y0NzQyNmU3YWFiOWQ4NDRiNjg0N2M5IiwidGFnIjoiIn0%3D; expires=Tue, 03 Nov 2026 08:33:07 GMT; Max-Age=7200; path=/; samesite=lax
Set-Cookie: laravel-session=eyJpdiI6IjRuVUhrUWIyTE1DRmtpUE04WXRQWUE9PSIsInZhbHVlIjoibzBvRk80MUF3MkF3MWx4eFVwVVNMckw5Sjg3RmpSRFYyRHN6YWhpcm1xbWlXQnJCeFlmdTkrTU5YVi9RMVZldVNjWXNQQmswK3daYmQvTW9VOW95bmxScFN6QTJ0OGZ0NENiSzJobWh4ZmloWG1QZE9iZi9CVlFnWERGSDYzaisiLCJtYWMiOiIzYzBmNDRiNWI5OTNjMjUyMzE0MTQwZWYzNmU2N2E2NTQ3Njk4ZGYxMzU2ZDk4ZGE2NWJiMjY3NjZjMzFmYTljIiwidGFnIjoiIn0%3D; expires=Tue, 03 Nov 2026 08:33:07 GMT; Max-Age=7200; path=/; httponly; samesite=lax


```

A `200 OK` response alone is not enough, because nginx also answers `200` for its own default page. The two `Set-Cookie` headers (`XSRF-TOKEN` and `laravel-session`) are the proof: only Laravel sets them, so the request went through nginx, the PHP-FPM socket, and PHP 8.5. The `Cache-Control: no-cache, private` header points the same way, since static files served by nginx would carry `Last-Modified` and `ETag` instead.

## Why Use packages.sury.org Instead of the Launchpad PPA {#why-use-packages-sury-org-instead-of-the-launchpad-ppa}

The Launchpad PPA only published packages for Ubuntu LTS releases, and it is being folded into `packages.sury.org/php`. The new repository is the same project, maintained by the same person, with the same package names such as `php8.5-fpm`. The practical differences are the source line, which now uses `packages.sury.org/php` with a `signed-by` keyring, and the fact that Ubuntu Resolute is served from the new repository directly.

The Launchpad page notes that Ubuntu Jammy and Ubuntu Noble can still use the PPA for now, and that a migration path for previous releases will be provided later. So the steps in this article apply to Ubuntu 26.04, while older LTS releases should follow the instructions on the Launchpad page.

## Troubleshooting {#troubleshooting}

These are the problems you are most likely to meet after the migration.

- **502 Bad Gateway.** nginx cannot reach PHP-FPM. Compare the `fastcgi_pass` path in your site file with the output of `ls /run/php/`, and check that `php8.5-fpm` is active.
- **`php -v` still shows the old version (8.5.4).** The shell may have cached the old path. Run `hash -r`, or open a new terminal, then check `which php`.
- **apt still installs the Ubuntu version.** Run `apt-cache policy php8.5-fpm` and confirm that the Sury version has the higher candidate. If not, check that `/etc/apt/sources.list.d/php.list` exists and that `sudo apt update` ran without errors.
- **`apt update` complains about a missing Release file.** An old Ondrej source file is probably still present. Repeat Step 5.
- **Permission denied in `storage/logs`.** The PHP-FPM user (`www-data`) cannot write to Laravel's folders. Repeat the `chown` and `chmod` commands from Step 9.

## Conclusion {#conclusion}

We replaced the PHP that ships with Ubuntu 26.04 by a PHP 8.5 build from the Sury repository, and we did it without leaving nginx or the rest of the system in a broken state. The main points to remember are:

- **Inspect before you remove.** `dpkg -l`, `apt-cache policy`, and `systemctl status` tell you where PHP comes from and what is running before any change is made.
- **Back up and preview.** Saving package selections and `/etc` folders, and running `apt-get -s` first, turn a risky removal into a reversible one.
- **Use `remove` before `purge`.** Keeping the configuration files until the new setup works gives you a safe path back.
- **Clean old PPA files.** A leftover Ondrej source file breaks `apt update`, so remove it before adding the new repository.
- **Use packages.sury.org on Ubuntu 26.04.** The Launchpad PPA is being merged into it, and it needs a signing keyring plus a `php.list` file based on `lsb_release -sc`.
- **Match the socket path.** nginx `fastcgi_pass` and the PHP-FPM socket must be the same, otherwise requests end in a `502`.
- **Verify end to end.** A real Laravel project served through nginx proves that the CLI, FPM, extensions, and web server all work together.
