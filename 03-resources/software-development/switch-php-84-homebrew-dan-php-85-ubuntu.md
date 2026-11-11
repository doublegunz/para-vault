# Switch PHP 8.4 Homebrew dan PHP 8.5 Ubuntu

## Konteks

Dokumentasi ini melanjutkan catatan [[dokumentasi_setup_siak_ubuntu_26_nginx_php_74]].

Environment saat dokumentasi dibuat:

- OS: Ubuntu 26.04
- Project: `/home/gun-gun-priatna/Projects/kp-project`
- Local domain: `https://kp-project.test`
- PHP Homebrew: PHP 8.4.22
- PHP Ubuntu: PHP 8.5.4
- PHP requirement project: `^8.4.0`

Kondisi CLI saat ini:

```bash
command -v php
# /usr/bin/php

php -v
# PHP 8.5.4 ...
# Built by Ubuntu
```

PHP 8.4 dari Homebrew sudah terpasang sebagai formula `keg-only` di:

```text
/home/linuxbrew/.linuxbrew/opt/php@8.4
```

Karena bersifat `keg-only`, executable PHP 8.4 tidak otomatis dihubungkan ke `/home/linuxbrew/.linuxbrew/bin/php`. Akibatnya, perintah `php` tetap menemukan `/usr/bin/php` milik Ubuntu.

## Perbedaan PHP CLI dan PHP-FPM Nginx

Ada dua konfigurasi terpisah:

1. `php -v`, `php artisan`, dan Composer menggunakan PHP CLI yang ditemukan melalui `PATH`.
2. `kp-project.test` menggunakan PHP-FPM yang ditentukan oleh `fastcgi_pass` pada konfigurasi Nginx.

Konfigurasi Nginx `kp-project.test` saat ini menggunakan socket PHP 8.4 Homebrew:

```nginx
fastcgi_pass unix:/home/gun-gun-priatna/php84-fpm.sock;
```

Mengganti versi PHP CLI tidak otomatis mengganti versi PHP yang digunakan oleh Nginx, begitu juga sebaliknya.

## 1. Menjadikan PHP 8.4 Homebrew sebagai PHP CLI

### Hanya untuk terminal yang sedang aktif

Jalankan:

```bash
export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/bin:/home/linuxbrew/.linuxbrew/opt/php@8.4/sbin:$PATH"
hash -r
```

Verifikasi:

```bash
command -v php
php -v
```

Hasil yang diharapkan:

```text
/home/linuxbrew/.linuxbrew/opt/php@8.4/bin/php
PHP 8.4.22 ...
```

Perubahan ini hanya berlaku pada terminal tersebut. Terminal baru tetap menggunakan konfigurasi dari `~/.bashrc`.

### Jadikan PHP 8.4 sebagai default permanen

Edit `~/.bashrc`:

```bash
nano ~/.bashrc
```

Tambahkan setelah baris `brew shellenv`, atau letakkan di bagian akhir file:

```bash
export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/sbin:$PATH"
```

Terapkan konfigurasi:

```bash
source ~/.bashrc
hash -r
```

Verifikasi:

```bash
command -v php
php -v
```

Tidak perlu menjalankan `brew link --force php@8.4`. Mengatur `PATH` lebih sederhana untuk environment multi-versi dan lebih mudah dikembalikan ke PHP Ubuntu.

## 2. Switch Kembali ke PHP 8.5 Ubuntu

### Hanya untuk terminal yang sedang aktif

Tempatkan `/usr/bin` di depan `PATH`:

```bash
export PATH="/usr/bin:$PATH"
hash -r
```

Verifikasi:

```bash
command -v php
php -v
```

Hasil yang diharapkan:

```text
/usr/bin/php
PHP 8.5.4 ...
Built by Ubuntu
```

PHP 8.5 juga dapat dijalankan secara eksplisit tanpa mengubah `PATH`:

```bash
/usr/bin/php8.5 -v
/usr/bin/php8.5 artisan --version
```

### Jadikan PHP 8.5 Ubuntu sebagai default permanen

Edit kembali `~/.bashrc`:

```bash
nano ~/.bashrc
```

Hapus atau beri komentar pada dua baris PHP 8.4:

```bash
# export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/bin:$PATH"
# export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/sbin:$PATH"
```

Kemudian mulai ulang shell:

```bash
exec bash
```

Verifikasi:

```bash
command -v php
php -v
```

Pada sistem ini, `/usr/bin/php` sudah dikelola oleh Ubuntu dan mengarah ke PHP 8.5. Karena itu, setelah path PHP Homebrew dihapus, perintah `php` kembali menggunakan PHP 8.5 Ubuntu.

`update-alternatives` hanya diperlukan jika terdapat beberapa paket PHP Ubuntu. Jangan masukkan PHP Homebrew ke `update-alternatives`; kelola PHP Homebrew melalui `PATH`.

Untuk melihat pilihan PHP dari paket Ubuntu:

```bash
update-alternatives --display php
```

Jika suatu saat ada beberapa versi PHP Ubuntu, pilih versinya dengan:

```bash
sudo update-alternatives --config php
```

## 3. Shortcut untuk Sering Switch PHP CLI

Jika sering berpindah versi, tambahkan konfigurasi berikut di bagian akhir `~/.bashrc` sebagai pengganti dua baris `export PATH` permanen di atas:

```bash
if [[ -z "${PHP_BASE_PATH:-}" ]]; then
    export PHP_BASE_PATH="$PATH"
fi

use-php84() {
    local php84_prefix="/home/linuxbrew/.linuxbrew/opt/php@8.4"

    export PATH="$php84_prefix/bin:$php84_prefix/sbin:$PHP_BASE_PATH"
    hash -r

    command -v php
    php -v
}

use-php85() {
    export PATH="$PHP_BASE_PATH"
    hash -r

    command -v php
    php -v
}
```

Terapkan konfigurasi:

```bash
source ~/.bashrc
```

Gunakan PHP 8.4 Homebrew:

```bash
use-php84
```

Gunakan PHP 8.5 Ubuntu:

```bash
use-php85
```

Shortcut ini mengganti `PATH` untuk terminal aktif. Terminal baru kembali menggunakan nilai awal `PHP_BASE_PATH`, yaitu PHP 8.5 Ubuntu, sampai `use-php84` dijalankan.

## 4. Verifikasi PHP untuk Composer dan Artisan

Setelah switch, cek PHP CLI sebelum menjalankan command project:

```bash
cd /home/gun-gun-priatna/Projects/kp-project

command -v php
php -v
php artisan --version
composer check-platform-reqs
```

Composer yang menggunakan shebang `/usr/bin/env php` akan mengikuti executable `php` pertama pada `PATH`.

Requirement PHP project adalah:

```json
"php": "^8.4.0"
```

Constraint tersebut menerima PHP 8.4 dan PHP 8.5, selama seluruh dependency project juga kompatibel dengan versi yang dipilih.

## 5. Jika Ingin Mengganti PHP untuk `kp-project.test`

Bagian ini hanya diperlukan jika yang ingin diganti bukan PHP CLI, tetapi PHP yang melayani request dari Nginx.

### Tetap Menggunakan PHP 8.4 Homebrew

Pastikan socket PHP 8.4 tersedia:

```bash
ls -lah /home/gun-gun-priatna/php84-fpm.sock
```

Konfigurasi Nginx:

```nginx
fastcgi_pass unix:/home/gun-gun-priatna/php84-fpm.sock;
```

### Menggunakan PHP 8.5 Ubuntu

Pastikan service PHP-FPM 8.5 aktif:

```bash
sudo systemctl status php8.5-fpm
```

Edit virtual host:

```bash
sudo nano /etc/nginx/sites-available/kp-project.test
```

Ganti socket:

```nginx
fastcgi_pass unix:/run/php/php8.5-fpm.sock;
```

Test dan reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Untuk kembali ke PHP 8.4 Homebrew, kembalikan `fastcgi_pass` ke:

```nginx
fastcgi_pass unix:/home/gun-gun-priatna/php84-fpm.sock;
```

Lalu jalankan kembali `sudo nginx -t` dan reload Nginx.

## Ringkasan Command

Gunakan PHP 8.4 Homebrew pada terminal aktif:

```bash
export PATH="/home/linuxbrew/.linuxbrew/opt/php@8.4/bin:/home/linuxbrew/.linuxbrew/opt/php@8.4/sbin:$PATH"
hash -r
```

Gunakan PHP 8.5 Ubuntu pada terminal aktif:

```bash
export PATH="/usr/bin:$PATH"
hash -r
```

Cek versi yang benar-benar digunakan:

```bash
command -v php
php -v
```
