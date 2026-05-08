# Dokumentasi Deployment Laravel Atomic Release

## Overview

Dokumentasi ini menjelaskan setup deployment Laravel menggunakan:

- Apache2
- PHP-FPM 8.5
- Atomic Release Deployment
- Symlink Release
- Shared Storage
- Shared .env
- Auto Cleanup Release
- Secure Sudoers
- Rollback Ready

Struktur deployment ini mirip dengan konsep deployment modern seperti:

- Envoyer
- Deployer
- Capistrano

---

# 1. Persiapan Direktori

## Struktur Direktori

```bash
mkdir -p /home/gun-gun-priatna/Projects/waruna/{releases,shared}
```

Buat direktori shared Laravel:

```bash
mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/storage
mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/bootstrap/cache
```

---

# 2. Permission Direktori

## Set ownership

```bash
sudo chown -R gun-gun-priatna:www-data /home/gun-gun-priatna/Projects/waruna
```

## Set permission folder

```bash
find /home/gun-gun-priatna/Projects/waruna -type d -exec chmod 775 {} \;
```

## Set permission file

```bash
find /home/gun-gun-priatna/Projects/waruna -type f -exec chmod 664 {} \;
```

## Supaya file baru otomatis ikut group www-data

```bash
find /home/gun-gun-priatna/Projects/waruna -type d -exec chmod g+s {} \;
```

## Permission storage Laravel

```bash
chmod -R 775 /home/gun-gun-priatna/Projects/waruna/shared/storage
chmod -R 775 /home/gun-gun-priatna/Projects/waruna/shared/bootstrap/cache
```

---

# 3. Setup Shared .env

Copy file .env aplikasi:

```bash
cp .env /home/gun-gun-priatna/Projects/waruna/shared/.env
```

Pastikan konfigurasi database benar:

```env
APP_ENV=production
APP_DEBUG=false

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nama_database
DB_USERNAME=username_database
DB_PASSWORD=password_database
```

---

# 4. Setup Apache

## Enable module Apache

```bash
sudo a2enmod rewrite
sudo a2enmod proxy_fcgi
sudo a2enmod setenvif
sudo a2enmod ssl
```

---

# 5. Setup Virtual Host Apache

Buat file:

```bash
sudo nano /etc/apache2/sites-available/waruna.test.conf
```

Isi file:

```apache
# This configuration is used for create custom virtual host with following configuration defined using variable:
# - Change root directory
# - Using SSL
# - Change PHP version using PHP FPM

define ROOT "/home/gun-gun-priatna/Projects/waruna/current/public"
define SITE waruna.test
define CERT waruna.test
define PHP_VERSION "8.5"

<VirtualHost *:80>
    ServerName ${SITE}
    DocumentRoot "${ROOT}"

    <Directory "${ROOT}">
        Options -Indexes +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost"
    </FilesMatch>
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${SITE}
    DocumentRoot "${ROOT}"

    <Directory "${ROOT}">
        Options -Indexes +SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost"
    </FilesMatch>

    SSLCertificateFile /home/gun-gun-priatna/Projects/ssl/certs/${CERT}.pem
    SSLCertificateKeyFile /home/gun-gun-priatna/Projects/ssl/certs/${CERT}-key.pem
</VirtualHost>
</IfModule>
```

---

# 6. Enable Site Apache

```bash
sudo a2ensite waruna.test.conf
sudo systemctl reload apache2
```

---

# 7. Setup Sudoers untuk PHP-FPM Reload

## Buka sudoers

```bash
sudo visudo
```

Tambahkan:

```text
Cmnd_Alias PHPFPM_RELOAD = /usr/bin/systemctl reload php8.5-fpm
gun-gun-priatna ALL=(root) NOPASSWD: PHPFPM_RELOAD
```

Konfigurasi ini hanya mengizinkan:

```bash
sudo /usr/bin/systemctl reload php8.5-fpm
```

Tanpa password.

Bukan full root access.

---

# 8. Setup Deploy Script

## Hapus script lama

```bash
rm -f ~/deploy.sh
```

## Buat deploy.sh

```bash
nano ~/deploy.sh
```

Isi file:

```bash
#!/bin/bash

set -e

BASE_DIR="/home/gun-gun-priatna/Projects/waruna"
RELEASES_DIR="$BASE_DIR/releases"
SHARED_DIR="$BASE_DIR/shared"
CURRENT_LINK="$BASE_DIR/current"

KEEP_RELEASES=5

TIMESTAMP=$(date +%Y%m%d%H%M%S)
NEW_RELEASE="$RELEASES_DIR/$TIMESTAMP"

echo "🚀 Deploy started at $TIMESTAMP"

# ===================================
# Clone latest code
# ===================================
git clone git@github.com:doublegunz/waruna.git "$NEW_RELEASE"

cd "$NEW_RELEASE"

# ===================================
# Link shared resources FIRST
# ===================================
# =========================
# 2. Link shared files
# =========================

rm -rf storage
ln -sfn "$SHARED_DIR/storage" storage

rm -f .env
ln -sfn "$SHARED_DIR/.env" .env

# ===================================
# Ensure required directories exist
# ===================================
mkdir -p bootstrap/cache

mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs

# ===================================
# Install dependencies
# ===================================
composer install --no-dev --optimize-autoloader

# ===================================
# Laravel optimization
# ===================================
php artisan optimize:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# ===================================
# Run migration
# ===================================
php artisan migrate --force

# ===================================
# Public storage symlink
# ===================================
rm -rf public/storage

ln -sfn \
"$SHARED_DIR/storage/app/public" \
public/storage

# ===================================
# Atomic release switch
# ===================================
PREVIOUS_RELEASE=$(readlink -f "$CURRENT_LINK" || true)

ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

# ===================================
# Reload PHP-FPM
# ===================================
sudo /usr/bin/systemctl reload php8.5-fpm

# ===================================
# Health check
# ===================================
sleep 2

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://waruna.store)

if [ "$HTTP_CODE" != "200" ]; then

    echo "❌ Deploy failed"

    if [ -n "$PREVIOUS_RELEASE" ]; then
        echo "↩ Rolling back..."

        ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

        sudo /usr/bin/systemctl reload php8.5-fpm
    fi

    exit 1
fi

# ===================================
# Cleanup old releases
# ===================================
echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "✅ Deploy success"
```

---

# 9. Set Executable Permission

```bash
chmod +x ~/deploy.sh
```

---

# 10. Jalankan Deploy

```bash
~/deploy.sh
```

---

# 11. Struktur Final Deployment

```text
waruna/
├── current -> releases/20260508080000
├── releases/
│   ├── 20260508070000
│   ├── 20260508075000
│   └── 20260508080000
└── shared/
    ├── .env
    ├── storage/
    └── bootstrap/cache/
```

---

# 12. Rollback Manual

Lihat release:

```bash
ls -dt /home/gun-gun-priatna/Projects/waruna/releases/*
```

Rollback:

```bash
ln -sfn /home/gun-gun-priatna/Projects/waruna/releases/20260508070000 \
/home/gun-gun-priatna/Projects/waruna/current
```

Reload PHP-FPM:

```bash
sudo /usr/bin/systemctl reload php8.5-fpm
```

---

# 13. Cleanup Release Lama

Deploy script otomatis menyimpan:

```bash
KEEP_RELEASES=5
```

Release lebih lama otomatis dihapus.

---

# 14. Keamanan Konfigurasi

## Apache

```apache
Options -Indexes +SymLinksIfOwnerMatch
```

Lebih aman dibanding:

```apache
+FollowSymLinks
```

Karena symlink hanya diizinkan jika owner cocok.

---

## AllowOverride

Gunakan:

```apache
AllowOverride All
```

Karena Laravel membutuhkan:

- RewriteRule
- Options
- .htaccess Laravel

---

## Sudoers Aman

Jangan gunakan:

```text
NOPASSWD: ALL
```

Gunakan:

```text
Cmnd_Alias PHPFPM_RELOAD = /usr/bin/systemctl reload php8.5-fpm
gun-gun-priatna ALL=(root) NOPASSWD: PHPFPM_RELOAD
```

Supaya hanya bisa reload PHP-FPM.

---

# 15. Troubleshooting

## Error: Options not allowed here

Penyebab:

```apache
AllowOverride FileInfo
```

Solusi:

```apache
AllowOverride All
```

---

## Error: Access denied for user 'forge'

Penyebab:

`.env` belum dilink sebelum artisan command.

Pastikan urutan:

```bash
ln -sfn "$SHARED_DIR/.env" .env
```

Dilakukan sebelum:

```bash
php artisan migrate
```

---

## Error: Symbolic link not allowed

Pastikan Apache menggunakan:

```apache
Options -Indexes +SymLinksIfOwnerMatch
```

Dan owner directory konsisten.

---

# 16. Rekomendasi Next Step

Untuk production-grade deployment berikutnya bisa ditambahkan:

- GitHub Actions
- Health Check
- Auto Rollback
- Queue Restart
- Horizon Restart
- Deploy Lock
- Zero Downtime Migration
- Maintenance Window Strategy
- Monitoring
- Log Aggregation
- Backup Automation

