
os: ubuntu 26.04


```
mkdir -p /home/gun-gun-priatna/Projects/waruna/{releases,shared}

mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/storage
mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/bootstrap/cache
```



```
chown -R gun-gun-priatna:www-data /home/gun-gun-priatna/Projects/waruna

find /home/gun-gun-priatna/Projects/waruna -type d -exec chmod 775 {} \;
find /home/gun-gun-priatna/Projects/waruna -type f -exec chmod 664 {} \;

# supaya semua file baru ikut group www-data
find /home/gun-gun-priatna/Projects/waruna -type d -exec chmod g+s {} \;
```

```
chmod -R 775 /home/gun-gun-priatna/Projects/waruna/shared/storage
chmod -R 775 /home/gun-gun-priatna/Projects/waruna/shared/bootstrap/cache
```

struktur shared

```
mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/storage
mkdir -p /home/gun-gun-priatna/Projects/waruna/shared/bootstrap/cache

chmod -R 775 /home/gun-gun-priatna/Projects/waruna/shared
```

buat file .env
```
cp .env.example /home/gun-gun-priatna/Projects/waruna/shared/.env

```

catatan dari qween
```
    <Directory "${ROOT}">
        Options -Indexes +SymLinksIfOwnerMatch
        AllowOverride FileInfo
        Require all granted
    </Directory>
```

rekomendasi menggunakan `SymLinksIfOwnerMatch`, karena rekomendasi dari chatgpt memiliki celah.


setup supaya bisa restart
```
sudo visudo
```

```
Cmnd_Alias PHPFPM_RELOAD = /usr/bin/systemctl reload php8.5-fpm
gun-gun-priatna ALL=(root) NOPASSWD: PHPFPM_RELOAD
```



hapus script lama
```
rm -f ~/deploy.sh
```

deploy.sh
```
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

# =========================
# 1. Clone repo
# =========================
git clone git@github.com:doublegunz/waruna.git "$NEW_RELEASE"

cd "$NEW_RELEASE"

# =========================
# 2. Install dependency
# =========================
composer install --no-dev --optimize-autoloader

# =========================
# 3. Link shared files
# =========================
ln -sfn "$SHARED_DIR/.env" .env
ln -sfn "$SHARED_DIR/storage" storage

# =========================
# 4. Laravel setup
# =========================
php artisan config:clear || true
php artisan cache:clear || true

php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan migrate --force

# =========================
# 5. Storage link (public)
# =========================
rm -rf public/storage
ln -sfn "$SHARED_DIR/storage/app/public" public/storage

# =========================
# 6. Switch release (atomic)
# =========================
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

# =========================
# 7. Reload PHP-FPM
# =========================
sudo /usr/bin/systemctl reload php8.4-fpm

# =========================
# 8. Cleanup old releases
# =========================
echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "✅ Deploy success"
```


set permission
```
chmod +x ~/deploy.sh
```

run deploy
```
~/deploy.sh
```