# Dokumentasi Setup SIAK

## Environment

- OS: Ubuntu 26.04
- Web Server: Nginx
- PHP: PHP 7.4 via Homebrew
- SSL: mkcert
- Database: PostgreSQL
- Project Root: `/var/www/html/siak`

---

# 1. Install PHP 7.4 Menggunakan Homebrew

## Tambahkan PHP Tap

```bash
brew tap shivammathur/php
```

## Install PHP 7.4

```bash
brew install shivammathur/php/php@7.4
```

## Verifikasi

```bash
/home/linuxbrew/.linuxbrew/opt/php@7.4/bin/php -v
```

---

# 2. Menjalankan PHP-FPM 7.4

## Start Service

```bash
brew services start shivammathur/php/php@7.4
```

## Cek Status

```bash
brew services list
```

---

# 3. Konfigurasi PHP-FPM Socket

Edit file:

```bash
nano /home/linuxbrew/.linuxbrew/etc/php/7.4/php-fpm.d/www.conf
```

Cari:

```ini
listen = 127.0.0.1:9074
```

Ganti menjadi:

```ini
listen = /home/gun-gun-priatna/php74-fpm.sock

listen.owner = gun-gun-priatna
listen.group = www-data
listen.mode = 0660
```

Restart PHP-FPM:

```bash
brew services restart php@7.4
```

Verifikasi socket:

```bash
ls -lah ~/php74-fpm.sock
```

---

# 4. Setup SSL Menggunakan mkcert

## Install Root CA

```bash
mkcert -install
```

## Generate SSL Certificate

Masuk ke folder SSL:

```bash
cd ~/Projects/ssl/certs
```

Generate SSL:

```bash
mkcert siak.test
```

Hasil:

```text
siak.test.pem
siak.test-key.pem
```

---

# 5. Konfigurasi Nginx Virtual Host

## Buat File Virtual Host

```bash
sudo nano /etc/nginx/sites-available/siak.test
```

Isi konfigurasi:

```nginx
server {
    listen 80;
    server_name siak.test;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;

    server_name siak.test;

    root /var/www/html/siak;
    index index.php index.html;

    ssl_certificate /home/gun-gun-priatna/Projects/ssl/certs/siak.test.pem;
    ssl_certificate_key /home/gun-gun-priatna/Projects/ssl/certs/siak.test-key.pem;

    client_max_body_size 100M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;

        fastcgi_pass unix:/home/gun-gun-priatna/php74-fpm.sock;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

---

# 6. Enable Virtual Host

```bash
sudo ln -s /etc/nginx/sites-available/siak.test /etc/nginx/sites-enabled/
```

---

# 7. Tambahkan Hosts Entry

Edit:

```bash
sudo nano /etc/hosts
```

Tambahkan:

```text
127.0.0.1 siak.test
```

---

# 8. Test dan Reload Nginx

## Test Konfigurasi

```bash
sudo nginx -t
```

## Reload Nginx

```bash
sudo systemctl reload nginx
```

---

# 9. Permission Project

## Set Ownership

```bash
sudo chown -R $USER:www-data /var/www/html/siak
```

## Set Permission

```bash
sudo chmod -R 775 /var/www/html/siak
```

Jika terdapat folder upload:

```bash
sudo chgrp -R www-data /var/www/html/siak/uploads
sudo chmod -R 775 /var/www/html/siak/uploads
```

---

# 10. Test PHP

Buat file:

```bash
nano /var/www/html/siak/info.php
```

Isi:

```php
<?php phpinfo();
```

Buka browser:

```text
https://siak.test/info.php
```

Pastikan versi PHP:

```text
PHP 7.4.x
```

---

# 11. Restore Database PostgreSQL

## Lokasi Backup

```text
/home/gun-gun-priatna/Documents/ARCHIVE/projects/ict/siak_log.backup
```

## Membuat Database

```bash
sudo -u postgres createdb siak_log
```

## Restore Database

```bash
sudo -u postgres pg_restore \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  -d siak_log \
  /home/gun-gun-priatna/Documents/ARCHIVE/projects/ict/siak_log.backup
```

---

# 12. Verifikasi Database

Masuk PostgreSQL:

```bash
sudo -u postgres psql siak_log
```

Lihat tabel:

```sql
\dt
```

---

# 13. Menjalankan PHP 7.4 Secara Manual

## Cek Versi

```bash
/home/linuxbrew/.linuxbrew/opt/php@7.4/bin/php -v
```

## Menjalankan Artisan

```bash
/home/linuxbrew/.linuxbrew/opt/php@7.4/bin/php artisan serve
```

## Menjalankan Composer

```bash
/home/linuxbrew/.linuxbrew/opt/php@7.4/bin/php $(which composer) install
```

---

# 14. Struktur Project

## Project

```text
/var/www/html/siak
```

## SSL Certificates

```text
~/Projects/ssl/certs
```

## Nginx Virtual Host

```text
/etc/nginx/sites-available
/etc/nginx/sites-enabled
```

---

# 15. Troubleshooting

## 502 Bad Gateway

Cek socket:

```bash
ls -lah ~/php74-fpm.sock
```

Cek php-fpm:

```bash
ps aux | grep php-fpm
```

Restart php-fpm:

```bash
brew services restart php@7.4
```

---

## SSL Warning

Install mkcert root CA:

```bash
mkcert -install
```

---

## Cek Log Nginx

```bash
sudo tail -f /var/log/nginx/error.log
```

---

# 16. Command Penting

## Reload Nginx

```bash
sudo systemctl reload nginx
```

## Restart Nginx

```bash
sudo systemctl restart nginx
```

## Restart PHP-FPM

```bash
brew services restart php@7.4
```

## Cek Service PHP

```bash
brew services list
```

---

# 17. Catatan

- PHP sistem Ubuntu tetap menggunakan PHP bawaan.
- PHP 7.4 hanya digunakan untuk project legacy.
- Menggunakan PHP-FPM terpisah lebih aman dan scalable.
- Setup ini mendukung multi versi PHP.
- SSL local development menggunakan mkcert.



