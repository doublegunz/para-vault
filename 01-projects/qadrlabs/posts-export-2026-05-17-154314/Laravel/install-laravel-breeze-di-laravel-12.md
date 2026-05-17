---
title: "Install Laravel Breeze di Laravel 12"
slug: "install-laravel-breeze-di-laravel-12"
category: "Laravel"
date: "2025-03-02"
status: "published"
---

Hilangnya Laravel Breeze dari opsi default [starter kit](https://qadrlabs.com/post/laravel-12-starter-kit) di Laravel 12 telah menimbulkan kebingungan di kalangan developer yang mengandalkan komponen ini untuk sistem autentikasi. Saat menjalankan perintah `laravel new app`, banyak pengembang terkejut menemukan bahwa pilihan yang sudah menjadi andalan mereka kini tidak lagi tersedia secara otomatis. Situasi ini tidak hanya mengganggu workflow yang sudah mapan, tetapi juga memunculkan kekhawatiran apakah fitur penting ini masih didukung pada versi terbaru. Tenang saja, meskipun tidak hadir sebagai opsi default, Laravel Breeze sebenarnya masih dapat diimplementasikan dengan mudah pada proyek Laravel 12 Anda. Melalui artikel ini, kami akan memandu Anda langkah demi langkah cara menginstal dan mengonfigurasi Laravel Breeze menggunakan Composer, sehingga Anda dapat terus menggunakan sistem autentikasi yang ringan namun komprehensif tanpa perlu mengubah pola pengembangan yang sudah Anda kuasai.

## Overview{#overview}
Tutorial ini akan memandu Anda melalui proses implementasi Laravel Breeze pada proyek [Laravel 12](https://qadrlabs.com/post/laravel-12), meskipun komponen ini tidak lagi tersedia sebagai starter kit default. Dalam panduan ini, Anda akan mempelajari beberapa hal penting:

1. Cara membuat proyek Laravel 12 baru menggunakan Composer tanpa starter kit bawaan
2. Langkah-langkah menginstal package Laravel Breeze melalui Composer pada proyek yang sudah ada
3. Proses konfigurasi Laravel Breeze dengan pemilihan frontend stack (Blade dengan Alpine) dan fitur tambahan seperti dark mode
4. Cara menjalankan migrasi database untuk tabel-tabel yang dibutuhkan sistem autentikasi
5. Pengujian fungsionalitas Laravel Breeze dengan memeriksa halaman login dan register
6. Pemahaman tentang bagaimana adaptasi terhadap perubahan dalam ekosistem Laravel dapat dilakukan tanpa mengorbankan fitur-fitur yang sudah familiar

Setelah menyelesaikan tutorial ini, Anda akan memiliki sistem autentikasi Laravel Breeze yang berfungsi penuh pada aplikasi Laravel 12 Anda, lengkap dengan halaman login, register, dan fitur-fitur keamanan standar yang telah menjadi andalan dalam pengembangan aplikasi Laravel.

## Step 1: Buat Project Baru {#step-1-buat-project-baru}

Karena laravel breeze tidak tersedia sebagai starter kit ketika kita run `laravel` command untuk membuat project baru, jadi kita buat project baru tanpa starter kit. Untuk membuat project baru kita bisa menggunakan composer atau pun laravel installer.

Pada tutorial ini kita coba buat project laravel 12 baru menggunakan composer.
```
composer create-project --prefer-dist laravel/laravel:^12.0 sample-app-with-breeze
```

Tunggu sampai proses buat project baru selesai.

## Step 2: Install Laravel Breeze {#step-2-install-laravel-breeze}

Selanjutnya kita masuk ke direktori project.

```
cd sample-app-with-breeze
```

Lalu kita install laravel breeze package di project laravel 12.

```
composer require laravel/breeze --dev
```

Setelah composer selesai menginstall laravel breeze package, selanjutnya kita run command `breeze:install`.

```
php artisan breeze:install
```

Setelah kita run command di atas, akan tampil prompt untuk memilih frontend stack dan testing framework. 

```
php artisan breeze:install

 ┌ Which Breeze stack would you like to install? ───────────────┐
 │ Blade with Alpine                                            │
 └──────────────────────────────────────────────────────────────┘

 ┌ Would you like dark mode support? ───────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ Pest                                                         │
 └──────────────────────────────────────────────────────────────┘


```

Setelah selesai memilih frontend stack dan testing framework, proses install akan dimulai termasuk proses `migrate`, install dependensi frontend dan juga build frontend assets.



## Step 3: Uji Coba{#step-3-uji-coba}

Setelah proses install laravel breeze, kita bisa uji coba run project.

```
php artisan serve
```

Output:

```
$ php artisan serve

   INFO  Server running on [http://127.0.0.1:8000].  

  Press Ctrl+C to stop the server

```

Selanjutnya kita akses project di browser melalui `http://127.0.0.1:8000`. Ketika kita akses kita bisa lihat tampilan awal laravel 12 dengan link `Login` dan `Register`. 

![Tampilan awal laravel 12 dengan breeze](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-breeze/1-tampilan-awal-laravel-12.png)



Ketika kita akses halaman login dan register, kita bisa lihat halaman login dan register dari laravel breeze.

![Tampilan halaman login laravel breeze](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-breeze/2-tampilan-login-laravel-breeze.png)



![Tampilan halaman register laravel breeze](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-breeze/3-tampilan-halaman-register-laravel-breeze.png)



## Penutup {#penutup}

Meskipun Laravel terus berkembang dengan rilis starter kit baru pada Laravel 12, kita telah melihat bahwa Laravel Breeze masih dapat diimplementasikan dengan mudah melalui Composer. Proses ini memungkinkan developer yang sudah terbiasa dengan Laravel Breeze untuk tetap menggunakan sistem autentikasi yang familiar tanpa hambatan berarti.

Dalam tutorial ini, kita telah berhasil menginstal Laravel Breeze pada Laravel 12 melalui beberapa langkah sederhana: pembuatan proyek baru menggunakan Composer, instalasi package Laravel Breeze, konfigurasi preferensi stack, dan pengujian fungsionalitas. Hasilnya adalah sistem autentikasi yang lengkap dengan halaman login dan register yang sudah siap digunakan.

Perubahan dalam ekosistem Laravel memang terkadang dapat menimbulkan kekhawatiran bagi developer yang sudah nyaman dengan pola tertentu. Namun, seperti yang ditunjukkan dalam tutorial ini, tim Laravel selalu memastikan bahwa komponen-komponen penting seperti Breeze tetap dapat diakses dan diimplementasikan dengan mudah, meskipun tidak lagi menjadi bagian dari template default.

Dengan memahami proses instalasi dan konfigurasi Laravel Breeze pada Laravel 12 ini, Anda kini memiliki keterampilan untuk mengadaptasi perubahan dalam framework tanpa harus mengorbankan fitur-fitur yang sudah Anda andalkan dalam workflow pengembangan aplikasi. Pendekatan ini memungkinkan Anda untuk terus memanfaatkan keunggulan Laravel terbaru sambil mempertahankan efisiensi dalam implementasi sistem autentikasi yang handal.

Selamat mengembangkan aplikasi dengan Laravel 12 dan Laravel Breeze!