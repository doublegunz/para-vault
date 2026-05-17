---
title: "Dockerize Laravel 13 with FrankenPHP: A Modern Containerization Approach"
slug: "dockerize-laravel-13-with-frankenphp-a-modern-containerization-approach"
category: "Laravel"
date: "2026-04-08"
status: "published"
---

In our [previous Docker tutorial](https://qadrlabs.com/post/tutorial-dockerize-aplikasi-laravel-12-memahami-containerisasi-untuk-development-environment), we containerized a Laravel 12 application using the traditional Nginx + PHP-FPM stack. That setup requires two separate containers for web serving: Nginx receives HTTP requests and forwards them to PHP-FPM via FastCGI. It works, but it adds complexity. You manage two containers, two configuration files, and a communication layer between them.

FrankenPHP changes this fundamentally. Created by Symfony core team member Kevin Dunglas, FrankenPHP is a modern PHP application server built on top of Caddy. It replaces both Nginx and PHP-FPM with a single binary. One container handles HTTP requests and executes PHP code. No FastCGI, no upstream configuration, no separate web server. It also ships with automatic HTTPS, HTTP/2, HTTP/3, Gzip compression, and security headers out of the box.

In this tutorial, we will dockerize a Laravel 13 application using FrankenPHP, MySQL, and Redis. The result is a simpler, more performant setup with fewer moving parts than the traditional stack.


## Overview {#overview}

We will build a Docker development environment for Laravel 13 using FrankenPHP as the application server. Instead of the four-container setup from our previous tutorial (PHP-FPM, Nginx, MySQL, Redis), we will use three containers: FrankenPHP (replaces both PHP-FPM and Nginx), MySQL, and Redis.

### What You'll Build

- A FrankenPHP container that serves your Laravel 13 application with automatic HTTPS, HTTP/2, and HTTP/3.
- A MySQL 8.0 container for the database with persistent storage.
- A Redis container for caching and session storage.
- A Docker Compose configuration that orchestrates all three services.
- Helper scripts for common development tasks.

### What You'll Learn

- How FrankenPHP differs from the traditional Nginx + PHP-FPM stack.
- How to write a Dockerfile using the official FrankenPHP image with `install-php-extensions`.
- How to configure a Caddyfile for Laravel applications.
- How to set up Docker Compose for a multi-container Laravel environment.
- How to manage database persistence with Docker volumes.
- How to run Artisan commands inside containers.
- How to troubleshoot common Docker issues with FrankenPHP.

### What You'll Need

- Docker and Docker Compose installed.
- Composer installed globally (for creating the Laravel project).
- Basic understanding of Docker concepts (images, containers, volumes).
- Familiarity with Laravel (models, migrations, Artisan commands).


## FrankenPHP vs Nginx + PHP-FPM {#frankenphp-vs-nginx-phpfpm}

Before we start building, let's understand why FrankenPHP simplifies the stack.

In the traditional setup from our [previous tutorial](https://qadrlabs.com/post/tutorial-dockerize-aplikasi-laravel-12-memahami-containerisasi-untuk-development-environment), a request flows through two containers:

```
Browser -> Nginx Container (port 80) -> PHP-FPM Container (port 9000) -> Laravel
```

Nginx receives the HTTP request, checks if it is a static file (CSS, JS, images), and if it is a PHP file, forwards it to PHP-FPM via the FastCGI protocol. This requires configuring `upstream php-fpm { server php:9000; }` in the Nginx config and managing two separate containers.

With FrankenPHP, the flow is simpler:

```
Browser -> FrankenPHP Container (port 80/443) -> Laravel
```

FrankenPHP handles both HTTP serving and PHP execution in a single process. It is built on Caddy (a modern web server written in Go) with PHP embedded directly into it. No FastCGI, no inter-container communication for PHP processing.

Here is a side-by-side comparison:

| Aspect                     | Nginx + PHP-FPM                 | FrankenPHP              |
| -------------------------- | ------------------------------- | ----------------------- |
| Containers for web serving | 2 (Nginx + PHP-FPM)             | 1                       |
| Configuration files        | `default.conf` + `php.ini`      | `Caddyfile` + `php.ini` |
| HTTPS                      | Manual (certbot or self-signed) | Automatic (built-in)    |
| HTTP/2 and HTTP/3          | Requires configuration          | Enabled by default      |
| Gzip compression           | Manual configuration            | Built-in                |
| Security headers           | Manual configuration            | Built-in defaults       |
| Static file serving        | Nginx handles directly          | Caddy handles directly  |
| PHP execution              | FastCGI protocol to PHP-FPM     | Embedded in the server  |
| Laravel Octane             | Requires separate setup         | Native support          |


## Step 1: Create a Laravel 13 Project {#step-1-create-project}

Start with a fresh Laravel 13 project:

```bash
composer create-project laravel/laravel laravel-frankenphp
```

Navigate into the project directory:

```bash
cd laravel-frankenphp
```

We will add the Docker configuration files to this project. Here is the directory structure we will create:

```
laravel-frankenphp/
  docker/
    php/
      Dockerfile
      Caddyfile
      php.ini
  docker-compose.yml
  .dockerignore
  .env.docker
  ... (Laravel files)
```

Compared to the previous tutorial, we no longer need a `docker/nginx/` directory. The Caddyfile replaces the Nginx configuration, and it lives alongside the Dockerfile in `docker/php/`.


## Step 2: Create the FrankenPHP Dockerfile {#step-2-create-dockerfile}

Create the directory for the PHP/FrankenPHP configuration:

```bash
mkdir -p docker/php
```

Create `docker/php/Dockerfile`:

```
FROM dunglas/frankenphp:php8.4-alpine

# Install PHP extensions using the built-in installer
# This is much simpler than the manual compile process in the PHP-FPM setup
RUN install-php-extensions \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache \
    redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
# FrankenPHP expects the application in /app
WORKDIR /app

# Copy application files
COPY . .

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-dev

# Create required Laravel directories
RUN mkdir -p storage/logs \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    bootstrap/cache

# Set permissions
RUN chown -R www-data:www-data /app \
    && chmod -R 775 storage bootstrap/cache

# Copy custom configuration files
COPY docker/php/Caddyfile /etc/caddy/Caddyfile
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# FrankenPHP exposes ports 80 (HTTP), 443 (HTTPS), and 443/udp (HTTP/3)
EXPOSE 80 443

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
```

Compare this with the PHP-FPM Dockerfile from the previous tutorial. The biggest difference is `install-php-extensions`. In the PHP-FPM setup, we had to install system dependencies (`apk add libpng-dev libxml2-dev ...`), configure extensions manually (`docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp`), and compile them (`docker-php-ext-install -j$(nproc) pdo_mysql mbstring ...`). With FrankenPHP, the `install-php-extensions` script handles all of that in a single command.

The `CMD` starts FrankenPHP with our custom Caddyfile. No need for `php-fpm` as the command because FrankenPHP handles both HTTP serving and PHP execution.

**Note:** We use the `php8.4-alpine` base image tag because Laravel 13 dependencies (specifically Symfony 8 components) require PHP 8.4+. Using an older version like PHP 8.3 configures a lower PHP runtime version, causing Composer to fail during the image build.

Save the file.


## Step 3: Create the Caddyfile {#step-3-create-caddyfile}

The Caddyfile replaces the Nginx `default.conf` from the previous tutorial. Create `docker/php/Caddyfile`:

```
{
    # Enable FrankenPHP
    frankenphp

    # Disable automatic HTTPS for local development
    # Remove this line for production to enable automatic Let's Encrypt certificates
    auto_https off

    # Set global options
    order php_server before file_server
}

:80 {
    # Set the document root to Laravel's public directory
    root * /app/public

    # Enable Gzip and Brotli compression
    encode zstd br gzip

    # Handle PHP requests through FrankenPHP
    php_server
}
```

This entire Caddyfile replaces the 80+ line Nginx configuration from the previous tutorial. Let's compare:

**What Nginx needed explicitly that Caddy handles automatically:**

- Security headers (`X-Frame-Options`, `X-Content-Type-Options`, etc.) are built into Caddy's defaults.
- Gzip compression required manual configuration in Nginx. Caddy's `encode` directive handles Gzip, Brotli, and Zstandard in one line.
- The `try_files $uri $uri/ /index.php?$query_string` pattern in Nginx is handled by `php_server` in Caddy. The `php_server` directive automatically tries the file, then falls back to `index.php`.
- Blocking access to hidden files (`.env`, `.git`) is handled by Caddy's default file server behavior.
- Static file caching headers are handled by Caddy automatically.

The `auto_https off` directive disables automatic HTTPS for local development. In production, remove this line and FrankenPHP will automatically obtain and renew Let's Encrypt SSL certificates for your domain.

Save the file.


## Step 4: Create the PHP Configuration {#step-4-create-php-config}

Create `docker/php/php.ini`:

```ini
[PHP]
; Maximum execution time (5 minutes for development)
max_execution_time = 300

; Maximum input parsing time
max_input_time = 300

; Maximum memory per script
memory_limit = 512M

; Maximum upload file size
upload_max_filesize = 100M

; Maximum number of files that can be uploaded at once
max_file_uploads = 20

; Maximum POST data size
post_max_size = 100M

[opcache]
; OPcache stores compiled PHP bytecode in memory
; This significantly improves performance
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
```

This is the same PHP configuration from the previous tutorial. The OPcache settings work identically in FrankenPHP because it uses the same PHP runtime underneath.

Save the file.


## Step 5: Create Docker Compose {#step-5-create-docker-compose}

Create `docker-compose.yml` in the project root:

```yaml
services:
  # FrankenPHP Service - replaces both Nginx and PHP-FPM
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    container_name: laravel_app
    restart: unless-stopped
    ports:
      - "8080:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./:/app
      - ./docker/php/Caddyfile:/etc/caddy/Caddyfile
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/99-custom.ini
    networks:
      - laravel_network
    depends_on:
      - mysql
      - redis

  # MySQL Service
  mysql:
    image: mysql:8.0
    container_name: laravel_mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: laravel_db
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_USER: laravel_user
      MYSQL_PASSWORD: laravel_password
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - laravel_network
    command: --default-authentication-plugin=mysql_native_password

  # Redis Service
  redis:
    image: redis:7-alpine
    container_name: laravel_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - laravel_network
    command: redis-server --appendonly yes

networks:
  laravel_network:
    driver: bridge

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
```

Compare this with the previous tutorial's `docker-compose.yml`. We went from four services to three. The `php` and `nginx` services are replaced by a single `app` service. The port mapping `8080:80` maps the host port 8080 to FrankenPHP's HTTP port. The `443:443` and `443:443/udp` mappings are for HTTPS and HTTP/3 respectively (useful when you enable automatic HTTPS in production).

The MySQL and Redis services are identical to the previous tutorial. The only change is that `depends_on` now points to `app` instead of `php` and `nginx`.

Save the file.


## Step 6: Create the Environment Configuration {#step-6-create-env-config}

Create `.env.docker` in the project root:

```
APP_NAME="Laravel FrankenPHP"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL=http://localhost:8080

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password

CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

BROADCAST_CONNECTION=log
QUEUE_CONNECTION=sync
```

The environment configuration is almost identical to the previous tutorial. The key concept remains the same: `DB_HOST=mysql` and `REDIS_HOST=redis` use Docker service names instead of `localhost` because each service runs in its own container and Docker's internal DNS resolves service names to container IP addresses.

Save the file.


## Step 7: Create the .dockerignore File {#step-7-create-dockerignore}

Create `.dockerignore` in the project root:

```
.git
.gitignore
docker-compose.yml
docker-compose.*.yml
.env
.env.*
node_modules/
vendor/
.vscode/
.idea/
*.swp
*.swo
.DS_Store
Thumbs.db
storage/app/*
storage/framework/cache/*
storage/framework/sessions/*
storage/framework/views/*
storage/logs/*
bootstrap/cache/*
.phpunit.result.cache
phpunit.xml
README.md
*.md
!docker/php/Caddyfile
!docker/php/php.ini
```

This is the same `.dockerignore` from the previous tutorial, with the Nginx-specific exclusions removed and the Caddyfile added to the keep list.

Save the file.


## Step 8: Build and Run the Containers {#step-8-build-and-run}

Copy the environment configuration:

```bash
cp .env.docker .env
```

Build and start all containers:

**Important Note:** Before running the containers, ensure that you stop any local `apache2` or `mysql` services running on your host machine to avoid port conflicts (especially ports 80, 443, and 3306). On Linux, you can stop them by running:
```bash
sudo service apache2 stop
sudo service mysql stop
```

Now, run the following command to start the containers:

```bash
docker compose up -d --build
```

Docker will build the FrankenPHP image from our Dockerfile, pull the MySQL and Redis images, and start all three containers. The build process is faster than the PHP-FPM setup because `install-php-extensions` handles dependency resolution automatically instead of requiring manual system package installation.

Watch the logs to verify everything starts correctly:

```bash
docker compose logs -f
```

Once all containers are running, perform the initial Laravel setup:

```bash
# Generate application key
docker compose exec app php artisan key:generate

# Run database migrations
docker compose exec app php artisan migrate

# Clear caches
docker compose exec app php artisan optimize:clear
```

Note: in the previous tutorial, the exec command targeted the `php` service (`docker compose exec php php artisan ...`). Now it targets the `app` service because FrankenPHP combines the web server and PHP runtime into one container.

Set proper permissions:

```bash
docker compose exec app chown -R www-data:www-data storage/ bootstrap/cache/
docker compose exec app chmod -R 775 storage/ bootstrap/cache/
```


## Step 9: Verify the Setup {#step-9-verify-setup}

Open your browser and navigate to `http://localhost:8080`. You should see the Laravel welcome page.

To verify all services are connected, add a test route. Open `routes/web.php` and add:

```php
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

Route::get('/docker-test', function () {
    return response()->json([
        'message' => 'Laravel is running with FrankenPHP!',
        'php_sapi' => php_sapi_name(),
        'database' => DB::connection()->getPdo() ? 'Connected' : 'Disconnected',
        'cache' => Cache::store('redis')->put('test', 'working', 60) ? 'Redis working' : 'Redis failed',
        'timestamp' => now()->toISOString(),
    ]);
});
```

Navigate to `http://localhost:8080/docker-test`. You should see:

```json
{
  message: "Laravel is running with FrankenPHP!",
  php_sapi: "frankenphp",
  database: "Connected",
  cache: "Redis working",
  timestamp: "2026-04-07T14:28:11.856405Z"
}
```

Notice `php_sapi_name()` returns `frankenphp` instead of `fpm-fcgi` (which is what the PHP-FPM setup returns). This confirms FrankenPHP is serving your application directly, not through FastCGI.

### Verify Container Communication

You can verify that containers can communicate with each other by pinging from inside the app container:

```bash
docker compose exec app sh
```

Once inside the container:

```bash
ping mysql
```

You should see successful pings:

```
PING mysql (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.129 ms
```

Press `Ctrl+C` to stop, then test Redis:

```bash
ping redis
```

Press `Ctrl+C` to stop, then exit the container:

```bash
exit
```


## Step 10: Development Workflow {#step-10-development-workflow}

The development workflow is the same as the previous tutorial because we use volume mounting (`./:/app`). Every change you make in your code editor is immediately reflected inside the container without rebuilding.

### Running Artisan Commands

```bash
# Create a migration
docker compose exec app php artisan make:migration create_posts_table

# Run migrations
docker compose exec app php artisan migrate

# Create a model
docker compose exec app php artisan make:model Post

# Clear cache
docker compose exec app php artisan cache:clear

# Enter Tinker
docker compose exec app php artisan tinker
```

### Database Access

```bash
# Access MySQL CLI
docker compose exec mysql mysql -u laravel_user -p laravel_db
```

Enter `laravel_password` when prompted.

### Redis Access

```bash
# Access Redis CLI
docker compose exec redis redis-cli

# Test basic commands
ping
set test_key "Hello FrankenPHP"
get test_key
exit
```

### Stopping and Starting

```bash
# Stop all containers
docker compose down

# Stop and remove volumes (WARNING: deletes database data)
docker compose down -v

# Start containers
docker compose up -d

# Rebuild and start
docker compose up -d --build
```


## Step 11: Create Helper Scripts {#step-11-create-helper-scripts}

Create a `scripts` directory with helper scripts for common tasks:

```bash
mkdir scripts
```

**Setup Script (`scripts/setup.sh`):**

```bash
#!/bin/bash

echo "Setting up Laravel FrankenPHP environment..."

if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

if [ ! -f .env ]; then
    echo "Copying environment file..."
    cp .env.docker .env
fi

echo "Building and starting Docker containers..."
docker compose up -d --build

echo "Waiting for services to initialize..."
sleep 20

if ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating application key..."
    docker compose exec app php artisan key:generate
fi

echo "Running database migrations..."
docker compose exec app php artisan migrate --force

echo "Setting permissions..."
docker compose exec app chown -R www-data:www-data storage/ bootstrap/cache/
docker compose exec app chmod -R 775 storage/ bootstrap/cache/

echo "Clearing caches..."
docker compose exec app php artisan optimize:clear

echo ""
echo "Setup complete!"
echo "Application: http://localhost:8080"
echo "Database:    localhost:3306"
echo "Redis:       localhost:6379"
```

**Fresh Install Script (`scripts/fresh.sh`):**

```bash
#!/bin/bash

echo "Performing fresh installation..."

docker compose down -v
docker compose up -d --build

sleep 20

docker compose exec app php artisan migrate:fresh --seed
docker compose exec app php artisan optimize:clear
docker compose exec app chown -R www-data:www-data storage/ bootstrap/cache/

echo "Fresh installation complete!"
```

Make the scripts executable:

```bash
chmod +x scripts/*.sh
```

Run the setup:

```bash
./scripts/setup.sh
```


## Troubleshooting {#troubleshooting}

### Permission Problems

The most common issue with FrankenPHP in Docker is file permission conflicts between the host and container:

```bash
# Fix permissions
docker compose exec app chown -R www-data:www-data storage/ bootstrap/cache/
docker compose exec app chmod -R 775 storage/ bootstrap/cache/
```

### Port Conflicts

If port 8080 or 443 is already in use:

```bash
# Check which process is using the port
lsof -i :8080
lsof -i :443

# Change the port in docker-compose.yml
# e.g., "9090:80" instead of "8080:80"
```

### Database Connection Problems

```bash
# Check if MySQL container is running
docker compose ps mysql

# Check MySQL logs
docker compose logs mysql

# Test connection from app container
docker compose exec app php artisan tinker
# Then run: DB::connection()->getPdo();
```

### Container Startup Issues

```bash
# Check all container statuses
docker compose ps

# View logs for a specific container
docker compose logs app

# Restart with fresh containers
docker compose down
docker compose up -d --force-recreate
```

### FrankenPHP-Specific: ARM64 Compatibility

If you are running on Apple Silicon (M1/M2/M3) and encounter segmentation faults, add the platform specification to the app service in `docker-compose.yml`:

```yaml
app:
    platform: linux/amd64
    build:
      # ...
```

This forces Docker to use x86_64 emulation via Rosetta 2. Performance may be slightly lower, but it resolves compatibility issues.


## Traditional Stack vs FrankenPHP: Summary {#traditional-vs-frankenphp}

After building both setups across two tutorials, here is the final comparison:

| Aspect                        | Nginx + PHP-FPM (Previous Tutorial)    | FrankenPHP (This Tutorial)             |
| ----------------------------- | -------------------------------------- | -------------------------------------- |
| Total containers              | 4 (Nginx, PHP-FPM, MySQL, Redis)       | 3 (FrankenPHP, MySQL, Redis)           |
| Web server config             | `default.conf` (80+ lines)             | `Caddyfile` (15 lines)                 |
| PHP extension install         | Manual (apk add + configure + compile) | `install-php-extensions` (one command) |
| HTTPS                         | Manual (certbot/self-signed)           | Automatic (built-in Let's Encrypt)     |
| HTTP/2 and HTTP/3             | Requires Nginx configuration           | Enabled by default                     |
| Inter-container communication | Nginx to PHP-FPM via FastCGI           | Not needed (single container)          |
| Docker Compose services       | `php`, `nginx`, `mysql`, `redis`       | `app`, `mysql`, `redis`                |
| Build complexity              | Higher (system deps + compile)         | Lower (one-liner extensions)           |
| Production readiness          | Requires additional hardening          | Production-ready defaults              |
| Laravel Octane support        | Separate setup required                | Native integration                     |
| `php_sapi_name()`             | `fpm-fcgi`                             | `frankenphp`                           |


## Conclusion {#conclusion}

In this tutorial, we dockerized a Laravel 13 application using FrankenPHP, MySQL, and Redis. Compared to the traditional Nginx + PHP-FPM setup from our [previous tutorial](https://qadrlabs.com/post/tutorial-dockerize-aplikasi-laravel-12-memahami-containerisasi-untuk-development-environment), the FrankenPHP approach is simpler, requires fewer containers, and provides more features out of the box.

Here are the key takeaways:

- **FrankenPHP replaces both Nginx and PHP-FPM.** One container handles HTTP serving and PHP execution. No FastCGI protocol, no upstream configuration, no inter-container communication for web requests.
- **The Caddyfile is dramatically simpler than Nginx config.** 15 lines replace 80+ lines. Security headers, compression, and the try_files pattern are handled automatically by Caddy's defaults.
- **`install-php-extensions` eliminates manual compilation.** Instead of installing system dependencies, configuring, and compiling each extension, one command handles everything. This makes the Dockerfile shorter and less error-prone.
- **Automatic HTTPS is built in.** For production, remove `auto_https off` from the Caddyfile, set your domain in `SERVER_NAME`, and FrankenPHP automatically obtains and renews Let's Encrypt certificates.
- **The development workflow is identical.** Volume mounting, Artisan commands, database access, and Redis management work the same way regardless of whether you use FrankenPHP or PHP-FPM.
- **Container communication remains the same.** Services still communicate using Docker service names (`mysql`, `redis`) through Docker's internal DNS. The only change is that there is no communication between a web server container and a PHP container because they are the same container.
- **FrankenPHP supports Laravel Octane natively.** If you need even higher performance, you can add Laravel Octane with the FrankenPHP driver and run your application in worker mode, keeping it in memory between requests.