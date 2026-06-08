---
title: "Percobaan Upgrade Laravel 10 ke Laravel 11"
slug: "percobaan-upgrade-laravel-10-ke-laravel-11"
category: "Laravel"
date: "2024-03-13"
status: "published"
---

Pada hari selasa 12 Maret 2024 lalu, laravel 11 telah dirilis. Dan pada [dokumentasi resmi laravel](https://laravel.com/docs/11.x/releases#support-policy) disebutkan, untuk laravel versi sebelumnya, yaitu Laravel 10 akan disupport sampai 4 Februari 2025. Berdasarkan info tersebut menjadi salah satu hal yang perlu dipikirkan, apakah project yang saat ini dibangun menggunakan laravel 10 perlu diupgrade ke laravel 11? Sebelum percobaan ke real project, di tutorial kali ini kita akan coba upgrade Laravel 10 ke Laravel 11 pada project sederhana terlebih dahulu.

## Overview{#overview}
Pada percobaan kali ini kita akan mencoba untuk upgrade project sederhana yang didevelop menggunakan laravel 10 ke laravel 11. Untuk studi kasus, kita akan coba upgrade project dari tutorial [develop crud app laravel 10](https://qadrlabs.com/post/memulai-belajar-laravel-10-dan-tailwindcss-untuk-membangun-crud-app). Di akhir percobaan ini, crud app tersebut dapat berjalan dengan baik.

## Persiapan{#persiapan}
Untuk melakukan upgrade, alangkah baiknya kita sudah menambahkan automated testing di project kita. Oleh karena itu teman-teman bisa coba clone project dari [repositori ini](https://github.com/gungunpriatna/testing-crud-laravel-10). Selanjutnya teman-teman dapat mengikuti panduan pada file `README.md`.

Apabila project sudah teman-teman clone dan setup, selanjutnya coba run command berikut ini.
```
php artisan test
```

Output yang ditampilkan:
```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.07s  

   PASS  Tests\Feature\ManagePostsTest
  ✓ user can create a post                                               0.05s  
  ✓ user can browse posts index page                                     0.01s  
  ✓ user can edit existing post                                          0.02s  
  ✓ user can delete existing post                                        0.01s  

  Tests:    6 passed (26 assertions)
  Duration: 0.20s

```

## Step 1 - Menggunakan PHP 8.2 {#step-1-use-php8.2}
Berikutnya kita cek versi php yang terinstall.
```
php -v
```
Output yang ditampilkan:
```
PHP 8.2.16 (cli) (built: Mar  7 2024 08:55:56) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.16, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.16, Copyright (c), by Zend Technologies

```

Di sini saya sudah setup versi php ke php 8.2. Berdasarkan dokumentasi resmi laravel, versi minimum PHP yang digunakan untuk laravel 11 adalah PHP 8.2. Oleh karena itu kita mesti install versi php 8.2 terlebih dahulu atau bisa juga gunakan php switcher dari [tutorial setup dan menggunakan multiple version php](https://qadrlabs.com/post/tutorial-setup-dan-menggunakan-multiple-version-php-di-ubuntu).

## Step 2 - Update Project Dependensi{#step-2-update-dependensi}
Selanjutnya kita buka file `composer.json`. Kita bisa lihat baris kode berikut ini di file `composer.json`.

```
"require": {  
    "php": "^8.1",   
    "laravel/framework": "^10.10",  
    "laravel/sanctum": "^3.3",  
    "laravel/tinker": "^2.8"  
},
```
Lalu kita ubah menjadi seperti berikut ini.
```
"require": {  
    "php": "^8.2",   
    "laravel/framework": "^11.0",  
    "laravel/sanctum": "^4.0",  
    "laravel/tinker": "^2.9"  
},
```

Selanjutnya cek bagian `require-dev`:
```
"require-dev": {    
    "nunomaduro/collision": "^7.0",  
},
```
Ubah menjadi:
```
"require-dev": {   
    "nunomaduro/collision": "^8.1",  
},
```


Save kembali file `composer.json`.

Selanjutnya kita run composer untuk mengupdate dependensi.

```
composer update
```
Tunggu sampai proses update dependensi selesai.

## Step 3 - Uji Coba{#step-3-uji-coba}
Karena kita menggunakan automated testing, jadi untuk menguji coba kita tidak perlu run project lalu cek satu persatu feature di project.

Sekarang kita buka kembali terminal, lalu run command berikut ini untuk mengecek apakah proses upgrade berhasil atau gagal.
```
php artisan test
```

Output di terminal:
```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.08s  

   PASS  Tests\Feature\ManagePostsTest
  ✓ user can create a post                                               0.05s  
  ✓ user can browse posts index page                                     0.01s  
  ✓ user can edit existing post                                          0.01s  
  ✓ user can delete existing post                                        0.01s  

  Tests:    6 passed (26 assertions)
  Duration: 0.20s

```

Ya, testing masih berjalan dengan baik dan tidak ditemukan error.

Selanjutnya kita cek versi laravel di project kita.
```
php artisan --version
```
Output yang ditampilkan:
```
$ php artisan --version
Laravel Framework 11.0.3
```
Bisa kita lihat di output yang ditampilkan di terminal, versi laravel sudah berhasil diupgrade dan versi saat percobaan ini dilakukan adalah versi `11.0.3`.

## Penutup{#penutup}
Pada percobaan kali ini kita sudah coba untuk mengupgrade versi laravel ke laravel versi 11 pada project sebelumnya didevelop menggunakan laravel 10. Setelah kita testing menggunakan `php artisan test`, kita bisa lihat project dapat berjalan dengan baik. Selain itu kita juga sudah pastikan versi laravel di project menggunakan command `php artisan --version` dan versi laravel sudah berhasil diupgrade.