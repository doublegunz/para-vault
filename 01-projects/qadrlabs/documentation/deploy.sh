#!/bin/bash

set -e

BASE_DIR="/home/gun-gun-priatna/Projects/demo-frontend"
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

git clone \
git@github.com:doublegunz/qadrlabs-frontend.git \
"$NEW_RELEASE"

cd "$NEW_RELEASE"

# ===================================
# Link shared resources
# ===================================

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

composer install \
--no-dev \
--optimize-autoloader \
--no-interaction

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
# Cleanup old releases
# ===================================

echo "🧹 Cleaning old releases..."

cd "$RELEASES_DIR"

ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "✅ Deploy success"