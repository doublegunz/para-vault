---
title: "Tutorial Dockerize Aplikasi Laravel 12: Memahami Containerisasi untuk Development Environment"
slug: "tutorial-dockerize-aplikasi-laravel-12-memahami-containerisasi-untuk-development-environment"
category: "Laravel"
date: "2025-06-14"
status: "published"
---

Tutorial ini akan membawa Anda memahami secara mendalam bagaimana melakukan containerisasi aplikasi Laravel 12 menggunakan Docker. Kita akan mempelajari konsep-konsep fundamental Docker sambil membangun environment development yang robust dan mudah digunakan.

## Overview{#overview}

Sebelum kita mulai membangun setup Docker, mari kita pahami terlebih dahulu apa yang sebenarnya terjadi ketika kita "mengdockerize" sebuah aplikasi Laravel. Docker pada dasarnya adalah platform yang memungkinkan kita untuk mengemas aplikasi beserta semua dependensinya ke dalam sebuah "container" yang portable dan lightweight.

Bayangkan Docker container seperti sebuah kotak yang berisi semua hal yang dibutuhkan aplikasi untuk berjalan. Di dalam kotak ini terdapat sistem operasi, runtime environment, libraries, dan kode aplikasi kita. Yang menarik dari kotak ini adalah, dia dapat berjalan secara konsisten di mana pun kita tempatkan, baik di laptop development, server staging, maupun server production.

Untuk aplikasi Laravel, kita akan membangun beberapa container yang bekerja sama layaknya sebuah orkestra. Setiap container memiliki peran spesifik dan berkomunikasi satu sama lain melalui network internal Docker. Container pertama akan menjalankan PHP dan Laravel aplikasi kita. Container kedua akan bertindak sebagai web server menggunakan Nginx. Container ketiga akan menyediakan database MySQL, dan container keempat akan menjalankan Redis untuk caching.

Pendekatan multi-container ini memberikan kita fleksibilitas luar biasa. Jika suatu saat kita ingin mengganti MySQL dengan PostgreSQL, kita hanya perlu mengganti satu container tanpa mempengaruhi yang lain. Begitu juga jika kita ingin melakukan scaling, kita bisa menjalankan multiple instance dari container PHP tanpa perlu menduplikasi database.

Selama tutorial ini, kita akan membangun pemahaman tentang bagaimana setiap piece bekerja, mengapa kita memilih konfigurasi tertentu, dan bagaimana semuanya bekerja bersama-sama untuk menciptakan development environment yang powerful.

## Step 1: Memahami Struktur Project dan Persiapan Awal{#step-1-memahami-struktur-project-dan-persiapan-awal}

Langkah pertama dalam journey dockerisasi adalah memahami struktur project yang akan kita bangun. Ketika kita bekerja dengan Docker, kita perlu memikirkan aplikasi tidak hanya sebagai kumpulan file PHP, tetapi sebagai ecosystem yang terdiri dari berbagai services yang saling bergantung.

Mari kita mulai dengan membuat project Laravel baru. Jika Anda belum memiliki aplikasi Laravel, jalankan command berikut di terminal:

```bash
composer create-project laravel/laravel laravel-docker-app
```

Command ini akan membuat project Laravel fresh yang akan menjadi foundation kita. Setelah project terbuat, navigasikan ke direktori tersebut:

```bash
cd laravel-docker-app
```

Sekarang, mari kita pahami struktur direktori yang akan kita buat untuk Docker setup. Kita akan menambahkan direktori `docker` yang akan berisi semua konfigurasi container kita:

```
laravel-docker-app/
├── docker/                 # Direktori khusus untuk konfigurasi Docker
│   ├── nginx/              # Konfigurasi web server
│   │   └── default.conf
│   └── php/                # Konfigurasi PHP container
│       ├── Dockerfile
│       └── php.ini
├── docker-compose.yml      # Orchestration file untuk multiple containers
├── .dockerignore          # File yang mengatur apa yang tidak di-copy ke container
├── .env.docker           # Environment variables khusus untuk Docker
└── ... (file Laravel lainnya)
```

Struktur ini mungkin terlihat rumit pada awalnya, namun setiap file memiliki tujuan spesifik. Direktori `docker/nginx` akan berisi konfigurasi web server yang akan menerima request HTTP dan meneruskannya ke aplikasi PHP kita. Direktori `docker/php` akan berisi instructions tentang bagaimana membangun container yang menjalankan kode Laravel kita.

File `docker-compose.yml` adalah maestro yang mengatur semua container kita. File ini mendefinisikan bagaimana setiap container dibuat, bagaimana mereka berkomunikasi, dan bagaimana data dibagi di antara mereka. Analoginya seperti konduktor orkestra yang memastikan setiap musician (container) memainkan bagiannya pada waktu yang tepat.

Buka project di code editor Anda:

```bash
code .
```

Sekarang kita siap untuk mulai membangun infrastructure Docker kita step by step.

## Step 2: Membangun PHP Container - The Heart of Our Application{#step-2-membangun-php-container-the-heart-of-our-application}

Container PHP adalah jantung dari setup kita karena di sinilah kode Laravel kita akan berjalan. Untuk memahami bagaimana membangunnya, kita perlu memahami konsep Dockerfile terlebih dahulu.

Dockerfile adalah seperti resep masakan yang memberitahu Docker bagaimana cara membangun container kita. Setiap baris dalam Dockerfile adalah sebuah instruction yang akan dieksekusi secara sequential untuk membuat container image kita.

Mari kita mulai dengan membuat direktori untuk konfigurasi PHP:

```bash
mkdir -p docker/php
```

Sekarang buat file `docker/php/Dockerfile`. Dockerfile ini akan menjadi blueprint untuk container PHP kita:

```
FROM php:8.3-fpm-alpine

# Install system dependencies yang dibutuhkan Laravel
# Setiap package di sini memiliki tujuan spesifik untuk mendukung extensions PHP
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    icu-dev

# Penjelasan detail setiap package:
# git - Untuk composer dan version control
# curl - Untuk HTTP requests
# libpng-dev - Untuk image processing (GD extension)
# libxml2-dev - Untuk XML processing
# zip/unzip - Untuk compression utilities
# oniguruma-dev - Untuk mbstring extension
# libzip-dev - Untuk zip extension
# freetype-dev - Untuk advanced image processing
# libjpeg-turbo-dev - Untuk JPEG image support
# libwebp-dev - Untuk WebP image support
# icu-dev - Untuk internationalization

# Compile dan install PHP extensions yang dibutuhkan Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        intl \
        opcache

# Install Redis extension untuk caching dan sessions
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Copy Composer dari official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy seluruh aplikasi ke dalam container
COPY . .

# Install dependencies PHP menggunakan Composer
RUN composer install --optimize-autoloader

# Buat direktori yang dibutuhkan Laravel
RUN mkdir -p /var/www/html/storage/logs \
    && mkdir -p /var/www/html/storage/framework/cache \
    && mkdir -p /var/www/html/storage/framework/sessions \
    && mkdir -p /var/www/html/storage/framework/views \
    && mkdir -p /var/www/html/bootstrap/cache

# Set proper ownership dan permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html/storage -type f -exec chmod 664 {} \; \
    && find /var/www/html/storage -type d -exec chmod 775 {} \; \
    && find /var/www/html/bootstrap/cache -type f -exec chmod 664 {} \; \
    && find /var/www/html/bootstrap/cache -type d -exec chmod 775 {} \;

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Expose port 9000 dan start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]

```

Sekarang mari kita buat konfigurasi PHP yang optimal untuk development. Buat file `docker/php/php.ini`:

```ini
[PHP]
; Waktu maksimum eksekusi script (5 menit untuk development)
; Ini berguna ketika kita menjalankan seeder atau migration yang berat
max_execution_time = 300

; Waktu maksimum untuk parsing request data
max_input_time = 300

; Memori maksimum yang bisa digunakan setiap script
; 512MB cukup generous untuk development Laravel
memory_limit = 512M

; Ukuran maksimum file upload
; Ini penting jika aplikasi kita memiliki fitur upload file
upload_max_filesize = 100M

; Jumlah maksimum file yang bisa diupload sekaligus
max_file_uploads = 20

; Ukuran maksimum POST data
; Harus lebih besar atau sama dengan upload_max_filesize
post_max_size = 100M

[opcache]
; OPcache adalah PHP accelerator yang menyimpan compiled bytecode
; Ini sangat meningkatkan performance aplikasi PHP
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
```

Pemahaman tentang setiap setting ini penting karena akan mempengaruhi bagaimana aplikasi Laravel kita berjalan. OPcache, misalnya, adalah fitur yang sering diabaikan namun bisa meningkatkan performance hingga 50% dengan menyimpan compiled PHP code di memory.

## Step 3: Membangun Nginx Container - The Gateway to Our Application{#step-3-membangun-nginx-container-the-gateway-to-our-application}

Nginx dalam setup kita berperan sebagai reverse proxy dan web server. Untuk memahami mengapa kita membutuhkan Nginx, bayangkan sebuah restaurant. PHP-FPM adalah chef yang memasak makanan (memproses request), sedangkan Nginx adalah pelayan yang menerima pesanan dari customer (web browser) dan mengantar makanan yang sudah jadi.

Konfigurasi Nginx yang tepat sangat crucial karena dia adalah first point of contact untuk semua HTTP requests. Mari kita buat direktori untuk konfigurasi Nginx:

```bash
mkdir -p docker/nginx
```

Sekarang buat file `docker/nginx/default.conf`:

```nginx
# Definisikan upstream untuk PHP-FPM
# "php" di sini merujuk ke nama service di docker-compose.yml
upstream php-fpm {
    server php:9000;
}

server {
    # Listen di port 80 untuk HTTP requests
    listen 80;
    server_name localhost;
    
    # Document root mengarah ke direktori public Laravel
    # Ini adalah best practice Laravel - semua requests harus melalui public/
    root /var/www/html/public;
    index index.php index.html;

    # Security headers untuk melindungi aplikasi dari common attacks
    # X-Frame-Options mencegah clickjacking
    add_header X-Frame-Options "SAMEORIGIN" always;
    # X-Content-Type-Options mencegah MIME type sniffing
    add_header X-Content-Type-Options "nosniff" always;
    # X-XSS-Protection mengaktifkan XSS filtering di browser
    add_header X-XSS-Protection "1; mode=block" always;
    # Referrer-Policy mengontrol informasi referrer yang dikirim
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    # Content-Security-Policy membantu mencegah XSS attacks
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Konfigurasi Gzip compression untuk mengurangi bandwidth usage
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

    # Location block utama untuk handling Laravel routes
    # try_files sangat penting di sini - dia mencari file secara urutan
    # Jika file tidak ditemukan, request diteruskan ke index.php
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Location block khusus untuk file PHP
    # Di sinilah magic terjadi - Nginx berkomunikasi dengan PHP-FPM
    location ~ \.php$ {
        # Teruskan request ke upstream PHP-FPM yang sudah kita definisikan
        fastcgi_pass php-fpm;
        fastcgi_index index.php;
        
        # SCRIPT_FILENAME harus tepat agar PHP bisa menemukan file yang benar
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        
        # Include parameter FastCGI standard
        include fastcgi_params;
        
        # Timeout settings untuk request yang membutuhkan waktu lama
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_connect_timeout 300;
    }

    # Blokir akses ke hidden files (.env, .git, dll)
    # Ini sangat penting untuk keamanan
    location ~ /\. {
        deny all;
    }

    # Optimisasi untuk static assets
    # Browser akan cache file ini selama 1 tahun
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt|tar|woff|svg|ttf|eot|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Optimisasi untuk favicon dan robots.txt
    # Tidak perlu log setiap request ke file ini
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    # Mencegah akses langsung ke direktori storage
    # Ini adalah security measure yang penting
    location ^~ /storage {
        deny all;
    }

    # Logging configuration
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
```

Konfigurasi Nginx ini sudah dioptimalkan untuk Laravel dan mencakup banyak best practices. Security headers melindungi aplikasi dari berbagai jenis attack, gzip compression mengurangi bandwidth usage, dan caching rules memastikan static assets di-cache dengan efisien.

## Step 4: Orchestrating dengan Docker Compose - Bringing It All Together{#step-4-orchestrating-dengan-docker-compose-bringing-it-all-together}

Docker Compose adalah tool yang memungkinkan kita mendefinisikan dan menjalankan multi-container Docker applications. Jika Dockerfile adalah resep untuk membuat satu container, maka docker-compose.yml adalah master plan yang mengatur bagaimana semua container bekerja bersama.

Konsep yang perlu dipahami di sini adalah bahwa setiap service dalam Docker Compose berjalan dalam isolated environment namun dapat berkomunikasi satu sama lain melalui network internal. Ini memberikan kita keuntungan isolation (jika satu service crash, yang lain tetap berjalan) sekaligus connectivity.

Buat file `docker-compose.yml` di root project:

```yaml
version: '3.8'

# Services adalah tempat kita mendefinisikan semua container yang dibutuhkan
services:
  # PHP Service - ini adalah jantung aplikasi Laravel kita
  php:
    # Build container dari Dockerfile yang sudah kita buat
    build:
      context: .                          # Build context adalah current directory
      dockerfile: docker/php/Dockerfile   # Path ke Dockerfile kita
    container_name: laravel_php
    restart: unless-stopped               # Restart otomatis jika container crash
    working_dir: /var/www/html
    
    # Volume mapping memungkinkan sharing file antara host dan container
    # Ini sangat penting untuk development agar perubahan code langsung terlihat
    volumes:
      - ./:/var/www/html                                    # Mount source code
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/99-custom.ini  # Mount PHP config
    
    # Networks memungkinkan containers berkomunikasi satu sama lain
    networks:
      - laravel_network
    
    # Dependencies memastikan urutan startup yang benar
    # PHP container akan menunggu MySQL dan Redis ready sebelum start
    depends_on:
      - mysql
      - redis

  # Nginx Service - web server dan reverse proxy
  nginx:
    # Menggunakan official Nginx image dengan Alpine Linux
    image: nginx:alpine
    container_name: laravel_nginx
    restart: unless-stopped
    
    # Port mapping - map port 8080 di host ke port 80 di container
    # Ini memungkinkan kita akses aplikasi via http://localhost:8080
    ports:
      - "8080:80"
    
    volumes:
      # Mount source code agar Nginx bisa serve static files
      - ./:/var/www/html
      # Mount konfigurasi Nginx yang sudah kita buat
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    
    networks:
      - laravel_network
    
    # Nginx membutuhkan PHP container untuk memproses PHP files
    depends_on:
      - php

  # MySQL Service - database server
  mysql:
    # MySQL 8.0 adalah versi LTS yang stable dan performant
    image: mysql:8.0
    container_name: laravel_mysql
    restart: unless-stopped
    
    # Environment variables untuk konfigurasi MySQL
    # Ini akan digunakan untuk setup database saat pertama kali container dibuat
    environment:
      MYSQL_DATABASE: laravel_db
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_USER: laravel_user
      MYSQL_PASSWORD: laravel_password
    
    # Port mapping untuk akses database dari host (opsional)
    ports:
      - "3306:3306"
    
    # Volume untuk persistence data
    # Tanpa ini, data akan hilang ketika container dihapus
    volumes:
      - mysql_data:/var/lib/mysql
    
    networks:
      - laravel_network
    
    # Command untuk menggunakan native password authentication
    # Ini diperlukan untuk kompatibilitas dengan beberapa MySQL clients
    command: --default-authentication-plugin=mysql_native_password

  # Redis Service - untuk caching dan session storage
  redis:
    # Redis 7 dengan Alpine Linux untuk ukuran yang minimal
    image: redis:7-alpine
    container_name: laravel_redis
    restart: unless-stopped
    
    ports:
      - "6379:6379"
    
    # Volume untuk persistence Redis data
    volumes:
      - redis_data:/data
    
    networks:
      - laravel_network
    
    # Command untuk enable AOF (Append Only File) persistence
    # Ini memastikan data Redis tidak hilang saat restart
    command: redis-server --appendonly yes

# Networks definition
# Bridge network memungkinkan containers berkomunikasi menggunakan nama service
networks:
  laravel_network:
    driver: bridge

# Volumes definition untuk data persistence
# Named volumes ini dikelola oleh Docker dan persisten across container restarts
volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
```

Setiap bagian dalam docker-compose.yml ini memiliki tujuan spesifik. Environment variables di MySQL service, misalnya, akan digunakan oleh MySQL container untuk membuat database dan user saat pertama kali dijalankan. Volume mapping memungkinkan kita melakukan development dengan hot reload - perubahan code langsung terlihat tanpa perlu rebuild container.

## Step 5: Environment Configuration - Making It All Connect{#step-5-environment-configuration-making-it-all-connect}

Environment configuration adalah aspek yang sering diabaikan namun sangat crucial dalam Docker setup. Laravel menggunakan file `.env` untuk menyimpan configuration settings, dan ketika kita menggunakan Docker, kita perlu menyesuaikan settings ini agar aplikasi bisa berkomunikasi dengan services yang berjalan di containers lain.

Konsep penting yang perlu dipahami adalah bahwa dalam Docker network, containers berkomunikasi menggunakan nama service, bukan localhost atau IP address. Ketika container PHP ingin connect ke database, dia tidak menggunakan `localhost:3306`, tetapi `mysql:3306` dimana `mysql` adalah nama service yang kita definisikan di docker-compose.yml.

Buat file `.env.docker` yang akan menjadi template environment untuk Docker setup:

```
# Application Settings
APP_NAME="Laravel Docker App"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
# URL aplikasi menggunakan port yang di-expose oleh Nginx container
APP_URL=http://localhost:8080

# Database Configuration
# Yang perlu diperhatikan di sini adalah DB_HOST menggunakan nama service 'mysql'
# bukan 'localhost', karena database berjalan di container terpisah
DB_CONNECTION=mysql
DB_HOST=mysql                 # Nama service di docker-compose.yml
DB_PORT=3306
DB_DATABASE=laravel_db        # Sesuai dengan MYSQL_DATABASE di docker-compose.yml
DB_USERNAME=laravel_user      # Sesuai dengan MYSQL_USER di docker-compose.yml  
DB_PASSWORD=laravel_password  # Sesuai dengan MYSQL_PASSWORD di docker-compose.yml

# Cache Configuration
# Redis digunakan untuk caching karena lebih performant daripada file-based cache
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Redis Configuration
# Sama seperti database, Redis host menggunakan nama service
REDIS_HOST=redis              # Nama service di docker-compose.yml
REDIS_PASSWORD=null
REDIS_PORT=6379

# Logging
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

# Broadcast & Queue (untuk development menggunakan sync)
BROADCAST_CONNECTION=log
QUEUE_CONNECTION=sync
```

Perbedaan utama antara `.env` biasa dan `.env.docker` adalah dalam hostname untuk services eksternal. Dalam development normal, kita mungkin menggunakan `DB_HOST=localhost`, namun dalam Docker setup, setiap service berjalan di container terpisah dengan hostname masing-masing.

## Step 6: Creating .dockerignore - Optimizing the Build Process{#step-6-creating-dockerignore-optimizing-the-build-process}

File `.dockerignore` berfungsi mirip seperti `.gitignore`, namun untuk Docker build process. File ini sangat penting untuk optimisasi karena menentukan file dan direktori mana yang tidak akan di-copy ke dalam Docker image saat build process berlangsung.

Konsep yang perlu dipahami adalah bahwa setiap file yang di-copy ke Docker image akan menambah ukuran image tersebut. File yang tidak diperlukan di dalam container sebaiknya tidak di-copy untuk menjaga image tetap lean dan mempercepat build process.

Buat file `.dockerignore` di root project:

```
# Git repository files - tidak diperlukan di dalam container
.git
.gitignore

# Docker Compose file - tidak perlu di-copy ke dalam image
docker-compose.yml
docker-compose.*.yml

# Dockerfile tidak perlu di-copy ke dalam image (sudah digunakan untuk build)
docker/*/Dockerfile

# Environment files - akan di-mount sebagai volume atau di-set via environment variables
.env
.env.*

# Dependencies yang akan di-install via package manager di dalam container
node_modules/
vendor/

# IDE specific files - tidak relevan di dalam container
.vscode/
.idea/
*.swp
*.swo

# OS specific files
.DS_Store
Thumbs.db

# Laravel specific directories yang akan di-generate atau di-mount
storage/app/*
storage/framework/cache/*
storage/framework/sessions/*
storage/framework/views/*
storage/logs/*
bootstrap/cache/*

# Testing files - untuk development container tidak diperlukan
.phpunit.result.cache
phpunit.xml

# Documentation files
README.md
*.md

# Tapi KEEP configuration files yang dibutuhkan untuk build
!docker/php/php.ini
!docker/nginx/default.conf

```

Setiap entry dalam `.dockerignore` ini memiliki alasan spesifik. Directory `vendor/`, misalnya, dikecualikan karena kita akan menjalankan `composer install` di dalam container, sehingga tidak perlu meng-copy dependency yang mungkin berbeda platform dari host machine.

## Step 7: Building and Running - Bringing Everything to Life{#step-7-building-and-running-bringing-everything-to-life}

Sekarang saatnya untuk melihat semua piece yang sudah kita buat bekerja bersama. Proses ini akan memberikan kita pemahaman tentang bagaimana Docker build process bekerja dan bagaimana containers berkomunikasi satu sama lain.

Pertama, mari kita copy environment configuration untuk Docker:

```bash
cp .env.docker .env
```

Langkah ini penting karena Laravel membutuhkan file `.env` untuk berjalan. Kita menggunakan konfigurasi khusus Docker yang sudah disesuaikan dengan nama services di docker-compose.yml.

Sekarang mari kita build dan jalankan semua containers:

```bash
docker-compose up -d --build
```

Mari kita breakdown command ini. `docker-compose up` adalah command untuk menjalankan services yang didefinisikan di docker-compose.yml. Flag `-d` menjalankan containers di background (detached mode), sehingga kita masih bisa menggunakan terminal. Flag `--build` memaksa Docker untuk rebuild images jika ada perubahan.

Ketika command ini dijalankan, Docker akan melakukan beberapa tahap:

Pertama, Docker akan membaca docker-compose.yml dan memahami dependency tree. Dia akan mengetahui bahwa Nginx depend on PHP, dan PHP depend on MySQL dan Redis. Berdasarkan informasi ini, Docker akan start containers dalam urutan yang benar.

Kedua, untuk PHP service, Docker akan menjalankan build process berdasarkan Dockerfile yang sudah kita buat. Proses ini meliputi download base image, install system dependencies, compile PHP extensions, dan copy application code.

Ketiga, untuk services lain (Nginx, MySQL, Redis), Docker akan download official images yang sudah pre-built dan menjalankannya dengan konfigurasi yang kita berikan.

Untuk memantau progress dan troubleshoot jika ada masalah, kita bisa melihat logs:

```bash
docker-compose logs -f
```

Flag `-f` akan mengikuti logs secara real-time, mirip seperti `tail -f`. Kita akan melihat logs dari semua containers, yang sangat berguna untuk debugging.

Setelah semua containers berjalan, kita perlu melakukan beberapa setup Laravel:

```bash
# Generate application key
docker-compose exec php php artisan key:generate

# Run database migrations
docker-compose exec php php artisan migrate

# Clear various caches
docker-compose exec php php artisan optimize:clear
```
🔎 Penjelasannya:

1. **`docker-compose exec php`**
   → `php` yang pertama adalah **nama service/container** sesuai dengan definisi di `docker-compose.yml`.
   Biasanya ada service bernama `php` yang berisi PHP + Laravel environment.

2. **`php artisan ...`**
   → `php` yang kedua adalah **command yang dijalankan di dalam container**, yaitu menjalankan interpreter PHP untuk mengeksekusi file `artisan`.

Jadi arti lengkapnya:
➡️ **Jalankan command `php artisan ...` di dalam container bernama `php`.**

Contoh lain biar lebih jelas:

* Kalau servicenya bernama `app`, perintahnya akan jadi:

  ```bash
  docker-compose exec app php artisan migrate
  ```
* Kalau servicenya bernama `laravel-php`, maka:

  ```bash
  docker-compose exec laravel-php php artisan optimize:clear
  ```

📌 Jadi **dua kali `php` itu bukan duplikasi**, tapi konteks yang berbeda:

* yang pertama = nama service/container
* yang kedua = binary PHP di dalam container


Selanjutnya kita atur permission:
```
docker-compose exec php chown -R www-data:www-data storage/ bootstrap/cache/
docker-compose exec php chmod -R 755 storage/ bootstrap/cache/

```
📌 Penjelasan singkat:

* `docker-compose exec php` → masuk ke dalam container service `php` yang didefinisikan di `docker-compose.yml`.
* `chown -R www-data:www-data ...` → mengubah kepemilikan folder `storage/` dan `bootstrap/cache/` beserta seluruh isinya ke user dan group `www-data`.
* `chmod -R 755 ...` → memberi hak akses **rwxr-xr-x** (pemilik full, lainnya bisa baca & eksekusi) untuk kedua folder itu.

Dua folder ini memang *wajib writable* oleh Laravel agar fitur **cache, logs, dan compiled views** berjalan normal. Kalau tidak, biasanya muncul error seperti `The stream or file "/var/www/html/storage/logs/laravel.log" could not be opened`.

## Step 8: Understanding Container Communication{#step-8-understanding-container-communication}

Salah satu aspek paling menarik dari setup Docker kita adalah bagaimana containers berkomunikasi satu sama lain. Pemahaman tentang konsep ini sangat penting untuk troubleshooting dan pengembangan lebih lanjut.

Dalam Docker Compose, semua services yang didefinisikan dalam file yang sama secara otomatis terhubung dalam network yang sama. Network ini bertindak seperti LAN virtual dimana setiap container memiliki hostname sesuai dengan nama servicenya.

Mari kita lihat bagaimana komunikasi terjadi dalam setup kita:

Ketika browser mengirim HTTP request ke `http://localhost:8080`, request ini diterima oleh Nginx container karena kita sudah melakukan port mapping `8080:80`. Nginx kemudian melihat konfigurasinya dan mengetahui bahwa untuk file PHP, dia harus meneruskan request ke `php:9000`.

Nama `php` di sini bukan IP address, melainkan hostname yang secara otomatis di-resolve oleh Docker's built-in DNS. Docker akan mentranslate `php` menjadi IP address internal container PHP.

Container PHP, setelah memproses request Laravel, mungkin perlu mengakses database. Laravel configuration kita menggunakan `DB_HOST=mysql`, yang sekali lagi akan di-resolve oleh Docker DNS menjadi IP address container MySQL.

Kita bisa memverifikasi komunikasi ini dengan masuk ke dalam container dan melakukan test:

```bash
# Masuk ke PHP container
docker-compose exec php sh
```
Output:
```
$ docker-compose exec php sh
/var/www/html #
```
Selanjutnya kita coba test koneksi ke mysql
```
ping mysql
```
Output:
```
PING mysql (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.129 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.137 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.146 ms
64 bytes from 172.19.0.3: seq=3 ttl=64 time=0.107 ms
64 bytes from 172.19.0.3: seq=4 ttl=64 time=0.117 ms
64 bytes from 172.19.0.3: seq=5 ttl=64 time=0.106 ms
```
Untuk stop ping, kita bisa tekan `ctrl`+`c`.
Output:
```
^C
--- mysql ping statistics ---
6 packets transmitted, 6 packets received, 0% packet loss
round-trip min/avg/max = 0.106/0.123/0.146 ms

```

Selanjutnya kita bisa coba tes koneksi ke Redis
```

# Test koneksi ke Redis
ping redis
```
Output yang ditampilkan
```
/var/www/html # ping redis
PING redis (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.154 ms
64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.113 ms
64 bytes from 172.19.0.2: seq=2 ttl=64 time=0.113 ms
64 bytes from 172.19.0.2: seq=3 ttl=64 time=0.113 ms
64 bytes from 172.19.0.2: seq=4 ttl=64 time=0.129 ms
```

Untuk stop ping, seperti sebelumnya kita bisa tekan `ctrl`+`c`.
Output:
```
^C
--- redis ping statistics ---
5 packets transmitted, 5 packets received, 0% packet loss
round-trip min/avg/max = 0.113/0.124/0.154 ms
/var/www/html # 

```

Untuk keluar container kita bisa run command
```
exit
```

Jika semuanya dikonfigurasi dengan benar, ping command akan berhasil seperti contoh output di atas, menunjukkan bahwa containers bisa saling berkomunikasi.

## Step 9: Development Workflow - Making Development Seamless{#step-9-development-workflow-making-development-seamless}

Setelah semua containers berjalan, mari kita pahami bagaimana workflow development akan berlangsung. Salah satu keuntungan utama dari setup Docker kita adalah bahwa development experience tetap familiar meskipun aplikasi berjalan di dalam containers.

Karena kita menggunakan volume mounting untuk source code (`./:/var/www/html`), setiap perubahan yang kita buat di code editor akan langsung ter-reflect di dalam container. Ini berarti kita tidak perlu rebuild image setiap kali mengubah code.

Mari kita test ini dengan membuat perubahan sederhana:

Tambahkan route berikut di `routes/web.php`:

```php
Route::get('/docker-test', function () {
    return response()->json([
        'message' => 'Laravel is running in Docker!',
        'database' => DB::connection()->getPdo() ? 'Connected' : 'Disconnected',
        'cache' => Cache::get('test') ?: 'Cache working',
        'timestamp' => now()->toISOString(),
    ]);
});
```

Sekarang akses `http://localhost:8080/docker-test` di browser. Anda akan melihat response JSON yang menunjukkan bahwa Laravel berjalan dengan baik dan terhubung ke database serta cache.
```
{
    "message": "Laravel is running in Docker!",
    "database": "Connected",
    "cache": "Cache working",
    "timestamp": "2025-07-23T14:12:16.135735Z"
}
```

Untuk menjalankan Artisan commands, kita menggunakan `docker-compose exec`:

```bash
# Membuat migration baru
docker-compose exec php php artisan make:migration create_posts_table

# Menjalankan migration
docker-compose exec php php artisan migrate

# Membuat model
docker-compose exec php php artisan make:model Post

# Clear cache
docker-compose exec php php artisan cache:clear
```

## Step 10: Database Management and Persistence{#step-10-database-management-and-persistence}

Salah satu aspek penting dalam Docker setup adalah memahami bagaimana data persistence bekerja. Tanpa proper volume management, data database kita akan hilang setiap kali container dihapus.

Dalam setup kita, kita menggunakan named volume `mysql_data` untuk menyimpan data MySQL. Volume ini dikelola oleh Docker dan akan persisten meskipun container dihapus dan dibuat ulang.

Mari kita explore bagaimana database management bekerja dalam setup Docker kita:

```bash
# Akses MySQL CLI dari dalam container
docker-compose exec mysql mysql -u laravel_user -p laravel_db
```

Masukkan password `laravel_password` ketika diminta. Sekarang Anda berada di dalam MySQL CLI dan bisa menjalankan SQL commands secara langsung.

Untuk backup database, kita bisa menggunakan mysqldump:

```bash
# Backup database ke file
docker-compose exec mysql mysqldump -u laravel_user -p laravel_db > backup.sql
```

Untuk restore dari backup:

```bash
# Restore database dari backup
docker-compose exec -T mysql mysql -u laravel_user -p laravel_db < backup.sql
```

Flag `-T` digunakan karena kita mengirim input melalui stdin.

Jika kita ingin melihat data yang tersimpan di volume:

```bash
# Inspect volume
docker volume inspect laravel-docker-app_mysql_data

# List semua volumes
docker volume ls
```

Untuk development, kita mungkin ingin melakukan fresh install database. Buat script `scripts/fresh-db.sh`:

```bash
#!/bin/bash

echo "🔄 Resetting database..."

# Stop containers
docker-compose down

# Remove database volume
docker volume rm laravel-docker-app_mysql_data

# Start containers again
docker-compose up -d

# Wait for MySQL to be ready
sleep 30

# Run fresh migrations
docker-compose exec php php artisan migrate:fresh --seed

echo "✅ Database reset complete!"
```

Script ini akan menghapus semua data database dan menjalankan migrations dari awal.

## Step 11: Redis Cache Management{#step-11-redis-cache-management}

Redis dalam setup kita berfungsi sebagai cache store dan session storage. Pemahaman tentang bagaimana Redis bekerja dalam context Docker akan membantu kita mengoptimalkan performance aplikasi.

Laravel secara default akan menggunakan Redis untuk cache dan sessions berdasarkan konfigurasi di `.env`. Kita bisa memverifikasi koneksi Redis:

```bash
# Akses Redis CLI
docker-compose exec redis redis-cli

# Test basic commands
ping
set test_key "Hello Docker"
get test_key
keys *
exit
```

Dalam Laravel, kita bisa test cache functionality:

```bash
# Masuk ke Tinker
docker-compose exec php php artisan tinker

# Test cache
Cache::put('docker_test', 'This is cached in Redis', 60);
Cache::get('docker_test');
exit
```

Redis juga menyimpan sessions Laravel jika kita menggunakan `SESSION_DRIVER=redis`. Ini memberikan beberapa keuntungan dibanding file-based sessions, terutama untuk scalability.

Untuk monitoring Redis performance:

```bash
# Monitor Redis commands real-time
docker-compose exec redis redis-cli monitor

# Get Redis info
docker-compose exec redis redis-cli info
```

Jika kita ingin flush semua cache:

```bash
# Flush Redis cache
docker-compose exec php php artisan cache:clear

# Atau langsung via Redis CLI
docker-compose exec redis redis-cli flushall
```

## Step 12: Troubleshooting Common Issues{#step-12-troubleshooting-common-issues}

Dalam development menggunakan Docker, kita akan menghadapi berbagai issues yang specific to containerized environment. Memahami cara troubleshoot issues ini akan sangat membantu productivity kita.

**Issue 1: Permission Problems**

Salah satu issue yang paling sering terjadi adalah permission problems, terutama dengan direktori `storage` dan `bootstrap/cache`. Ini terjadi karena perbedaan user ID antara host dan container.

```bash
# Check current permissions
docker-compose exec php ls -la storage/

# Fix permissions jika diperlukan
docker-compose exec php chown -R www-data:www-data storage/
docker-compose exec php chmod -R 755 storage/
```

**Issue 2: Database Connection Problems**

Jika Laravel tidak bisa connect ke database, ada beberapa hal yang perlu dicek:

```bash
# Verify MySQL container is running
docker-compose ps mysql

# Check MySQL logs for errors
docker-compose logs mysql

# Test database connection dari PHP container
docker-compose exec php php artisan tinker
# Kemudian jalankan: DB::connection()->getPdo();
```

**Issue 3: Container Startup Issues**

Kadang-kadang containers gagal start karena port conflicts atau resource limitations:

```bash
# Check for port conflicts
netstat -tulpn | grep :8080
netstat -tulpn | grep :3306

# Check Docker resources
docker system df
docker stats

# Restart with fresh containers
docker-compose down
docker-compose up -d --force-recreate
```

**Issue 4: Performance Issues**

Jika aplikasi berjalan lambat dalam Docker:

```bash
# Check container resource usage
docker stats

# Verify OPcache is working
docker-compose exec php php -i | grep opcache

# Check for disk I/O issues
docker-compose exec php time php artisan config:cache
```

Untuk debugging yang lebih mendalam, kita bisa mengaktifkan debug mode dan melihat logs secara real-time:

```bash
# Edit .env dan set APP_DEBUG=true dan LOG_LEVEL=debug

# Watch logs real-time
docker-compose logs -f php
```

## Step 13: Creating Helper Scripts for Development{#step-13-creating-helper-scripts-for-development}

Untuk memaksimalkan efficiency dalam development, mari kita buat beberapa helper scripts yang akan mempermudah daily tasks. Scripts ini akan mengautomate common operations dan membuat Docker development experience lebih seamless.

Buat direktori `scripts` dan beberapa helper scripts:

```bash
mkdir scripts
```

**Setup Script (`scripts/setup.sh`)**

```bash
#!/bin/bash

echo "🚀 Setting up Laravel Docker environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Copy environment file if not exists
if [ ! -f .env ]; then
    echo "📄 Copying environment file..."
    cp .env.docker .env
else
    echo "⚠️  .env file already exists. Skipping copy."
fi

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Generate application key if not set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "🔑 Generating application key..."
    docker-compose exec php php artisan key:generate
fi

# Run migrations
echo "📊 Running database migrations..."
docker-compose exec php php artisan migrate --force

# Clear and cache configs
echo "🧹 Optimizing Laravel..."
docker-compose exec php php artisan config:clear
docker-compose exec php php artisan cache:clear
docker-compose exec php php artisan route:clear
docker-compose exec php php artisan view:clear

echo "✅ Setup complete!"
echo "🌐 Your application is running at: http://localhost:8080"
echo "💾 Database is available at: localhost:3306"
echo "🗄️  Redis is available at: localhost:6379"
```

**Development Script (`scripts/dev.sh`)**

```bash
#!/bin/bash

echo "🛠️  Starting development environment..."

# Start containers
docker-compose up -d

# Show status
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "🌐 Available Services:"
echo "  - Laravel App: http://localhost:8080"
echo "  - MySQL: localhost:3306"
echo "  - Redis: localhost:6379"

echo ""
echo "💡 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - PHP shell: docker-compose exec php sh"
echo "  - Artisan: docker-compose exec php php artisan [command]"
echo "  - Stop: docker-compose down"
```

**Fresh Install Script (`scripts/fresh.sh`)**

```bash
#!/bin/bash

echo "🔄 Performing fresh installation..."

# Stop and remove containers
docker-compose down -v

# Remove images (optional, uncomment if needed)
# docker-compose down --rmi all

# Start fresh
docker-compose up -d --build

# Wait for services
sleep 30

# Fresh migrations with seeding
echo "📊 Running fresh migrations..."
docker-compose exec php php artisan migrate:fresh --seed

# Clear everything
echo "🧹 Clearing caches..."
docker-compose exec php php artisan optimize:clear

echo "✅ Fresh installation complete!"
```

Buat scripts executable:

```bash
chmod +x scripts/*.sh
```

## Step 14: Understanding Docker Best Practices in Our Setup{#step-14-understanding-docker-best-practices-in-our-setup}

Sekarang setelah kita memiliki working Docker setup, mari kita review beberapa best practices yang sudah kita implementasikan dan mengapa mereka penting.

**1. Multi-stage Builds dan Layered Architecture**

Dalam Dockerfile kita, setiap `RUN` instruction menciptakan layer baru. Kita menggabungkan multiple commands dalam satu `RUN` instruction untuk mengurangi jumlah layers dan ukuran final image:

```
# Good practice - single layer
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev

# Bad practice - multiple layers
RUN apk add --no-cache git
RUN apk add --no-cache curl
RUN apk add --no-cache libpng-dev
```

**2. Proper Volume Management**

Kita menggunakan dua jenis volumes dalam setup kita:

- **Bind mounts** untuk source code development (`./:/var/www/html`)
- **Named volumes** untuk data persistence (`mysql_data`, `redis_data`)

Bind mounts memungkinkan hot reload untuk development, sementara named volumes memastikan data tidak hilang ketika containers di-recreate.

**3. Network Isolation**

Dengan mendefinisikan custom network `laravel_network`, kita memastikan bahwa containers kita isolated dari containers lain yang mungkin berjalan di system yang sama. Ini juga memungkinkan containers berkomunikasi menggunakan service names.

**4. Health Checks dan Dependencies**

Dependencies yang kita definisikan dengan `depends_on` memastikan startup order yang benar. Meskipun ini tidak menjamin bahwa service benar-benar ready (hanya bahwa container sudah started), ini adalah langkah pertama yang baik.

**5. Security Considerations**

Beberapa security measures yang sudah kita implementasikan:

- Menggunakan non-root user (`www-data`) untuk menjalankan PHP-FPM
- Tidak expose unnecessary ports ke host
- Menggunakan environment variables untuk sensitive data
- Implementing proper file permissions

## Step 15: Monitoring dan Maintenance{#step-15-monitoring-dan-maintenance}

Untuk menjaga Docker environment tetap healthy, kita perlu memahami cara monitoring dan maintenance yang proper.

**Monitoring Resource Usage**

```bash
# Monitor real-time resource usage
docker stats

# Check disk usage
docker system df

# See detailed volume information
docker volume ls
docker volume inspect laravel-docker-app_mysql_data
```

**Regular Cleanup**

Docker memiliki tendensi untuk mengakumulasi unused images, containers, dan volumes over time:

```bash
# Clean up stopped containers, unused networks, images, dan build cache
docker system prune -f

# Remove unused volumes (hati-hati dengan command ini!)
docker volume prune -f

# Remove specific unused images
docker image prune -f
```

**Log Management**

Docker logs bisa grow quite large over time. Untuk development, kita bisa limit log size:

```yaml
# Tambahkan ke service configuration di docker-compose.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

**Health Monitoring**

Buat script `scripts/health-check.sh`:

```bash
#!/bin/bash

echo "🏥 Docker Environment Health Check"
echo "=================================="

# Check if all containers are running
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "🔍 Application Health:"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ $response -eq 200 ]; then
    echo "✅ Application is responding (HTTP $response)"
else
    echo "❌ Application is not responding (HTTP $response)"
fi

echo ""
echo "🗄️  Database Connection:"
docker-compose exec php php artisan tinker --execute="
try {
    DB::connection()->getPdo();
    echo '✅ Database connection OK';
} catch (Exception \$e) {
    echo '❌ Database connection failed: ' . \$e->getMessage();
}
"

echo ""
echo "🗃️  Redis Connection:"
if docker-compose exec redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis connection OK"
else
    echo "❌ Redis connection failed"
fi
```

## Penutup{#penutup}

Dalam tutorial ini, kita telah membangun pemahaman mendalam tentang bagaimana melakukan containerisasi aplikasi Laravel menggunakan Docker. Pengaturan yang kita buat bukan hanya sekedar "solusi yang berfungsi", tetapi pondasi yang kokoh untuk pengembangan yang dapat diperluas dan dipelihara dengan baik.

### Konsep Utama Yang Telah Kita Pelajari

**Dasar-dasar Docker dalam Konteks Laravel**  
Kita memahami bahwa Docker bukan hanya alat untuk mengemas aplikasi, tetapi platform yang mengubah cara kita berpikir tentang arsitektur aplikasi. Dengan memisahkan tanggung jawab ke beberapa kontainer, kita menciptakan sistem yang modular dan tahan banting.

**Komunikasi Kontainer dan Jaringan**  
Pemahaman tentang bagaimana kontainer berkomunikasi melalui jaringan Docker sangat penting untuk pemecahan masalah dan penskalaan. Konsep penemuan layanan menggunakan nama layanan adalah dasar yang akan berguna ketika kita beralih ke platform orkestrasi seperti Kubernetes.

**Persistensi Data dan Pengelolaan Volume**  
Perbedaan antara bind mounts dan named volumes, serta kapan menggunakan masing-masing, adalah pengetahuan penting untuk setiap alur kerja pengembangan berbasis Docker.

**Pengelolaan Konfigurasi**  
Cara mengelola konfigurasi khusus lingkungan menggunakan variabel lingkungan dan pemasangan berkas memberikan kita fleksibilitas untuk melakukan deployment ke berbagai lingkungan tanpa perubahan kode.

### Alur Kerja Pengembangan Yang Telah Kita Bangun

Pengaturan yang kita buat memungkinkan pengalaman pengembangan yang lancar. Pengembang baru dapat mengatur seluruh lingkungan dengan satu perintah, dan perubahan kode langsung tercermin tanpa perlu membangun ulang kontainer. Ini adalah peningkatan produktivitas yang signifikan untuk tim pengembangan.

Skrip dan alat yang kita buat memungkinkan tugas-tugas umum dapat diotomatisasi, mengurangi beban kognitif dan memungkinkan pengembang fokus pada logika bisnis daripada masalah infrastruktur.

### Pondasi untuk Pertumbuhan

Pengaturan Docker yang kita buat adalah pondasi yang solid untuk pertumbuhan ke arah yang lebih canggih:

- **Arsitektur Mikroservis**: Pemahaman tentang komunikasi kontainer akan memudahkan transisi ke mikroservis
- **Integrasi Integrasi/Pengiriman Berkelanjutan**: Pengembangan berbasis kontainer memudahkan integrasi dengan jalur integrasi berkelanjutan
- **Deployment Cloud**: Citra Docker yang kita buat dapat di-deploy ke berbagai platform cloud dengan modifikasi minimal
- **Orkestrasi**: Pengaturan ini dapat menjadi titik awal untuk mempelajari Kubernetes atau Docker Swarm

### Praktik Terbaik Yang Telah Terinternalisasi

Melalui pengalaman langsung membangun pengaturan ini, kita telah menginternalisasi beberapa praktik terbaik:

- **Pendekatan mengutamakan keamanan** dengan izin pengguna yang tepat dan isolasi jaringan
- **Optimasi kinerja** melalui caching layer dan alokasi sumber daya yang tepat
- **Kemudahan pemeliharaan** melalui dokumentasi yang jelas dan skrip otomatis
- **Kemudahan debugging** melalui pengaturan logging dan monitoring yang tepat

### Selanjutnya

Ekosistem Docker terus berkembang, dan pondasi yang kita bangun di tutorial ini akan memudahkan kita untuk mengadopsi teknologi baru. Konsep seperti orkestrasi kontainer, service mesh, dan pengembangan cloud-native semuanya dibangun berdasarkan dasar-dasar yang sudah kita pelajari.

Yang terpenting, kita sekarang memiliki pola pikir untuk memikirkan aplikasi sebagai kumpulan layanan daripada entitas monolitik. Ini adalah perubahan paradigma yang berharga tidak hanya untuk pengembangan Laravel, tetapi untuk pengembangan perangkat lunak secara umum.

Tutorial ini memberikan kita lebih dari sekedar pengaturan Docker yang berfungsi - dia memberikan kita pemahaman yang lebih dalam tentang praktik dan alat pengembangan modern yang akan relevan untuk tahun-tahun mendatang. Dengan pondasi ini, kita siap untuk menjelajahi topik lanjutan seperti deployment produksi, monitoring, dan scaling yang akan kita bahas di artikel berikutnya.

### Repositori Project
Repositori implementasi tutorial dapat diakses pada link github: [https://github.com/qadrLabs/laravel-docker-app](https://github.com/qadrLabs/laravel-docker-app)