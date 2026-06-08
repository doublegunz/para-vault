---
title: "Tutorial Install Laravel di HP Android via Termux"
slug: "tutorial-install-laravel-di-hp-android-via-termux"
category: "How To Install"
date: "2024-12-02"
status: "published"
---

Setelah kita install composer pada [tutorial sebelumnya](https://qadrlabs.com/post/tutorial-install-dan-setup-composer-di-hp-android-menggunakan-termux), kita bisa install beberapa package dan juga framework. Salah satu framework yang dapat kita install melalui composer adalah laravel. Pertanyaanya adalah apakah kita bisa install laravel di hp android dengan memanfaatkan termux? Pada tutorial ini kita akan coba install laravel menggunakan composer dan termux d hp android.

## Overview{#overview}
Yang akan kita coba pada tutorial ini adalah install laravel di hp android. Selain install, kita juga akan coba setup konfigurasi database dan run project laravel di browser. Beberapa hal yang harus sudah teman-teman persiapkan untuk mengikuti tutorial ini adalah
1. Termux
2. PHP
3. MariaDB
4. Composer
Dan persiapan di atas dapat teman-teman siapkan dengan mengikuti edisi tutorial sebelumnya pada seri tutorial [Persiapan Belajar Coding di HP](https://qadrlabs.com/series/persiapan-belajar-coding-di-hp).

Selanjutnya kita cek terlebih dahulu versi php yang terinstall. Kita buka **termux**, lalu run command berikut ini.
```
php -v
```
Pada saat tutorial ini ditulis, php yang terinstall adalah php versi 8.3.10.

Selanjutnya kita coba start terlebih mariadb service dengan run command berikut ini.
```
mariadbd-safe -u root &
```
Ketika kita run command di atas, tampil output `Starting mariadbd daemon with databases` tanda mariadb service sudah berhasil kita start.

Selanjutnya kita verifikasi apakah composer sudah terinstall dengan run command berikut ini.
```
composer -Version
```
Output yang ditampilkan di termux adalah versi composer yang terinstall dan pada saat tutorial ini ditulis tampil output `Composer version 2.8.3`.

Setelah semuanya sudah kita verifikasi, kita bisa lanjutkan ke step pertama untuk membuat project laravel menggunakan composer.

## Step 1 - Buat project laravel baru {#step-1-buat-project-laravel-baru}
Pada langkah pertama ini kita langsung buat project baru menggunakan composer. Sekarang kita run command berikut ini di termux.
```
composer create-project --prefer-dist laravel/laravel crud-app-example
```

![step 1 - buat project laravel baru menggunakan composer](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/1-buat-project-laravel.jpg)

Kita tunggu sampai proses buat project baru selesai. Apabila telah selesai, kita bisa lihat output di terminal terdapat proses `migrate` command ke database seperti yang terlihat pada gambar berikut ini.

![project selesai dibuat](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/2-project-created.jpg)

Selanjutnya kita pindah ke direktori project.
```
crud-app-example
```
Selanjutnya kita bisa cek versi laravel yang terinstall menggunakan `nano` text editor. Kita buka file `composer.json` menggunakan nano text editor.
```
nano composer.json
```
Pada saat tutorial ini ditulis, laravel yang terinstall adalah laravel versi `^11.31`. Selanjutnya kita bisa keluar dari nano text editor dengan menekan `CTRL`+x.

## Step 2 - Atur Konfigurasi Database {#step-2-atur-konfigurasi-database}
Pada step 1 kita berhasil install laravel dan kalau kita lihat di output yang ditampilkan di termux terdapat proses migrate. Secara default, laravel 11 menggunakan `sqlite` sebagai database. Sekarang kita akan coba gunakan mariaDB yang sudah kita install sebelumnya termasuk credentialnya. Untuk mengatur konfigurasi database, kita akan buka file `.env` menggunakan nano text editor.
```
nano .env
```

Selanjutnya kita atur bagian konfigurasi database file `.env`.
```
DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar
DB_USERNAME=root
DB_PASSWORD=1234
```

Pada file `.env`, kita gunakan `db_belajar` untuk database project, dan kita tambahkan juga credential mariadb dengan username `root` dan juga password `1234` sesuai dengan yang sudah kita set pada bagian [buat password untuk root](https://qadrlabs.com/post/tutorial-install-mysql-di-hp-android-menggunakan-termux#step-3) pada tutorial sebelumnya.

Apabila sudah selesai, kita tekan `CTRL`+o untuk save file `.env` dan `CTRL`+x untuk keluar dari nano text editor.

![isi dari file .env](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/3-edit-file-dotenv.jpg)

## Step 3 - Run Migrate Command {#step-3-run-migrate-command}
Setelah kita atur konfigurasi database, selanjutya kita bisa run `migrate` command.
```
php artisan migrate
```

![Run migrate command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/4-run-migrate-command.jpg)

Karena kita belum buat database `db_belajar`, akan tampil output seperti gambar di atas. Kita pilih `yes`, lalu tekan `enter` untuk melanjutkan.
![proses run migrate command](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/5-run-migrate-command-selesai.jpg)

Pada tahapan ini kita berhasil run migrate command dengan konfigurasi database dari tutorial sebelumnya.

## Step 4 - Uji Coba Run Project {#step-4-uji-coba-run-project}
Sekarang kita akan coba akses project kita di browser. Untuk akses project di browser, tentu kita harus run project terlebih dahulu menggunakan command berikut ini.
```
php artisan serve
```

![run php artisan serve](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/6-run-artisan-server-command.jpg)

Selanjutnya kita akses project melalui url `http://127.0.0.1:8000` di browser. Ketika buka project di browser, kita bisa lihat tampilan default laravel 11 seperti gambar berikut ini.

![akses project di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/termux/tutorial/install-laravel/7-tes-run-di-browser.jpg)

## Penutup {#penutup}
Pada tutorial ini kita sudah coba install laravel di hp android menggunakan composer yang terinstall di termux. Seperti yang sudah kita coba, kita bisa install laravel menggunakan php dan composer yang sudah kita install sebelumnya. Pada saat proses install laravel, kita bisa langsung install tanpa ada kendala. Selain itu kita bisa atur konfigurasi database menggunakan credential mariadb yang sudah kita set di tutorial sebelumnya. Dan ketika kit run migrate command, proses migrate berjalan dengan baik dan juga langsung membuatkan database sesuai dengan nama database yang sudah kita atur di file `.env`. Dan setelah step-step selesai, kita bisa run project laravel di browser.

Di akhir tutorial ini, kita sudah setup project laravel dan dapat kita run di browser. Selanjutnya teman-teman bisa langsung belajar laravel sesuai dengan materi yang ada. Happy Coding!