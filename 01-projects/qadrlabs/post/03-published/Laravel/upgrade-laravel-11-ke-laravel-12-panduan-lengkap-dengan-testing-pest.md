---
title: "Upgrade Laravel 11 ke Laravel 12: Panduan Lengkap dengan Testing Pest"
slug: "upgrade-laravel-11-ke-laravel-12-panduan-lengkap-dengan-testing-pest"
category: "Laravel"
date: "2025-02-25"
status: "published"
---

Melanjutkan seri artikel tentang Laravel 12 yang telah kita bahas di artikel [Laravel 12](https://qadrlabs.com/post/laravel-12) sebelumnya, kali ini kita akan mempelajari cara mengupgrade aplikasi Laravel 11 ke versi terbaru Laravel 12. Seperti yang telah kita ketahui, Laravel 12 dirilis pada 24 Februari 2025 dengan fokus pada minimal breaking changes dan pembaruan dependencies. Keunggulan ini memudahkan proses upgrade aplikasi yang sudah ada tanpa perlu melakukan perubahan kode yang signifikan. Dalam tutorial step-by-step ini, kita akan belajar cara mengupgrade aplikasi CRUD sederhana yang telah kita kembangkan sebelumnya, sambil memastikan bahwa semua test yang ditulis menggunakan Pest tetap berjalan dengan baik. Tutorial ini merupakan kelanjutan dari seri pembelajaran kita tentang [development CRUD app dengan Laravel 11](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11) dan implementasi [testing menggunakan Pest](https://qadrlabs.com/post/testing-menggunakan-pest).

## Overview {#overview}

Dalam tutorial ini, kita akan melanjutkan perjalanan pengembangan aplikasi Laravel dengan mengupgrade proyek dari Laravel 11 ke Laravel 12. Tutorial ini merupakan kelanjutan dari seri pembelajaran yang telah kita bahas sebelumnya di QadrLabs, dimulai dengan [percobaan development CRUD app sederhana menggunakan Laravel 11](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11) yang kemudian dilengkapi dengan implementasi [testing menggunakan Pest](https://qadrlabs.com/post/testing-menggunakan-pest).

Apa yang akan Anda pelajari dalam panduan ini:

- Cara memverifikasi versi PHP yang kompatibel dengan Laravel 12
- Langkah-langkah mengupdate dependensi di composer.json untuk upgrade ke Laravel 12
- Proses upgrade framework Laravel yang aman untuk aplikasi CRUD yang telah kita bangun sebelumnya
- Teknik memverifikasi keberhasilan upgrade
- Cara memastikan testing dengan Pest tetap berfungsi setelah upgrade

Goal dari panduan ini adalah membimbing Anda melakukan upgrade aplikasi CRUD sederhana yang telah kita kembangkan dari Laravel 11 ke Laravel 12, sambil memastikan bahwa semua test yang telah kita tulis menggunakan Pest tetap berjalan dengan baik. Dengan demikian, kita tidak hanya mempelajari cara mengupgrade framework, tetapi juga pentingnya memiliki suite testing yang komprehensif untuk memastikan aplikasi tetap berfungsi setelah perubahan besar seperti upgrade framework.

Setelah menyelesaikan tutorial ini, Anda akan memiliki pemahaman yang lebih baik tentang siklus hidup pengembangan aplikasi Laravel, dari pembuatan aplikasi CRUD sederhana, implementasi testing, hingga proses upgrade ke versi terbaru framework.

## Persiapan {#persiapan}

Akses repositori Belajar [Testing with Pest](https://github.com/qadrLabs/testing-with-pest-sample), lalu ikuti petunjuk setup di README. 

Apabila selesai setup run command berikut untuk run testing menggunakan pest.

```
php artisan test
```

Output yang ditampilkan

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.12s  

   PASS  Tests\Feature\ManagePostTest
  ✓ it can display the user index page                                   0.17s  
  ✓ it can display the create user form                                  0.03s  
  ✓ it can store a new user                                              0.03s  
  ✓ it can display the edit user form                                    0.03s  
  ✓ it can update a user                                                 0.03s  
  ✓ it can delete a user                                                 0.02s  

  Tests:    8 passed (22 assertions)
  Duration: 0.52s

```

Output di atas menunjukkan bahwa semua test berhasil dijalankan tanpa error. Ini menjadi baseline kita sebelum melakukan upgrade ke Laravel 12. Dengan memastikan semua test berjalan dengan baik sebelum upgrade, kita dapat dengan mudah mengidentifikasi masalah yang mungkin muncul setelah proses upgrade.

## Step 1 - Verifikasi Versi PHP yang digunakan {#step-1-verifikasi-versi-php-yang-digunakan}

Buka terminal lalu run command berikut ini untuk cek versi php.

```
php -v
```

Output:

```
PHP 8.2.27 (cli) (built: Dec 24 2024 06:29:37) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.27, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.27, Copyright (c), by Zend Technologies
    with Xdebug v3.4.1, Copyright (c) 2002-2025, by Derick Rethans

```



## Step 2 - Update Dependensi{#step-2-update-dependensi}

Selanjutnya buka `composer.json`, lalu temukan framework laravel pada baris kode berikut ini.

```
    "require": {
        "php": "^8.2",
        "laravel/framework": "^11.0",
        "laravel/tinker": "^2.9"
    },
```

Selanjutnya kita ubah versi framework laravel menjadi versi `^12.0`.

```
    "require": {
        "php": "^8.2",
        "laravel/framework": "^12.0",
        "laravel/tinker": "^2.10.1"
    },
```

Apabila telah selesai save kembali file `composer.json`.

Selanjutnya kita akan coba langsung update dependensi dengan run command berikut ini.

```
composer update
```

Tunggu sampai proses update selesai.



## Step 3 - Verifikasi Versi Laravel{#step-3-verifikasi-versi-laravel}

Proses upgrade laravel ke laravel 12 sudah selesai. Selanjutnya kita verifikasi versi laravel di project kita. Untuk verifikasi versi laravel, run command berikut ini di terminal.

```
php artisan --version
```

Output:

```
$ php artisan --version
Laravel Framework 12.32.5

```

Seperti yang terlihat pada output yang ditampilkan, versi laravel sudah berhasil diupgrade ke laravel versi `12.32.5`.



## Step 4 - Run Testing{#step-4-run-testing}

Sekarang kita coba run kembali testing menggunakan command berikut ini.

```
php artisan test
```

Output yang ditampilkan:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

   PASS  Tests\Feature\ManagePostTest
  ✓ it can display the user index page                                   0.14s  
  ✓ it can display the create user form                                  0.02s  
  ✓ it can store a new user                                              0.03s  
  ✓ it can display the edit user form                                    0.02s  
  ✓ it can update a user                                                 0.02s  
  ✓ it can delete a user                                                 0.02s  

  Tests:    8 passed (22 assertions)
  Duration: 0.44s


```

Seperti yang terlihat pada output di atas, testing berjalan dengan baik dan tidak ada error yang ditampilkan.

## Step 5 - Update Laravel Installer (Opsional) {#step-5-update-laravel-installer}

Sebagai langkah terakhir, kita akan membahas cara mengupdate Laravel Installer. Langkah ini bersifat opsional dan tidak berkaitan langsung dengan proses upgrade Laravel 11 ke Laravel 12 yang telah kita lakukan. Namun, mengupdate Laravel Installer sangat bermanfaat jika Anda berencana untuk membuat project Laravel baru dengan memanfaatkan starter kit terbaru yang diperkenalkan di Laravel 12.

Seperti yang telah kita bahas di [artikel Laravel 12](https://qadrlabs.com/post/laravel-12), versi terbaru ini menghadirkan starter kits inovatif untuk React, Vue, dan Livewire yang menggantikan Laravel Breeze dan Jetstream. Untuk mengakses starter kits baru ini, Anda perlu memastikan Laravel Installer pada sistem Anda sudah terbaru.

Untuk mengupdate Laravel Installer, jalankan perintah berikut di terminal:

```bash
composer global update laravel/installer
```

Setelah proses update selesai, Anda dapat memverifikasi versi Laravel Installer dengan perintah:

```bash
laravel --version
```

Dengan Laravel Installer yang sudah diupdate, Anda kini dapat membuat project Laravel 12 baru dengan berbagai pilihan starter kit modern. Coba buat project baru dengan perintah:

```bash
laravel new my-new-project
```

Selama proses instalasi, Laravel akan menawarkan pilihan framework testing, database, dan starter kit yang ingin Anda gunakan. Anda dapat memilih salah satu starter kit baru seperti React dengan Inertia, Vue dengan Inertia, atau Livewire dengan Flux UI untuk memulai pengembangan aplikasi dengan teknologi terkini.

Mengupdate Laravel Installer ini melengkapi perjalanan kita dari upgrade aplikasi yang sudah ada hingga persiapan untuk memulai project baru dengan Laravel 12.

## Penutup {#penutup}

Seperti yang telah kita pelajari di artikel ini, proses upgrade Laravel 11 ke Laravel 12 terbukti relatif mudah dan tanpa hambatan berarti. Hal ini sejalan dengan komitmen tim Laravel yang telah kami bahas dalam [artikel sebelumnya](https://qadrlabs.com/post/laravel-12) tentang fokus pada minimal breaking changes. Pendekatan "maintenance release" yang diadopsi Laravel 12 memungkinkan kita melakukan upgrade dengan aman tanpa perlu mengubah struktur kode aplikasi yang sudah ada.

Melalui tutorial ini, kita telah melihat bagaimana aplikasi CRUD sederhana yang dilengkapi dengan testing menggunakan Pest dapat diupgrade dengan langkah-langkah yang terstruktur. Yang lebih penting, semua test tetap berjalan dengan baik setelah upgrade, membuktikan bahwa Laravel 12 memang dirancang dengan mempertimbangkan kompatibilitas mundur.

Proses upgrade yang mulus ini menunjukkan pentingnya memiliki suite testing yang komprehensif. Dengan adanya test, kita dapat dengan cepat memverifikasi bahwa aplikasi tetap berfungsi sebagaimana mestinya setelah upgrade framework. Hal ini menjadi salah satu praktik terbaik dalam pengembangan aplikasi modern.

Kami mendorong Anda untuk mengupgrade aplikasi Laravel 11 ke Laravel 12 dan memanfaatkan pembaruan dependencies serta peningkatan performa yang ditawarkan. Dengan dukungan untuk Laravel 12 yang akan berlangsung hingga Februari 2027 untuk perbaikan keamanan, investasi waktu Anda untuk upgrade saat ini akan memberi manfaat jangka panjang bagi aplikasi Anda.

Selamat mengembangkan aplikasi dengan Laravel 12 dan tetap ikuti seri tutorial kami berikutnya untuk eksplorasi lebih dalam tentang fitur-fitur terbaru Laravel dan praktik pengembangan terbaik.