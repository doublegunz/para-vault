---
title: "Install Laravel Jetstream di Laravel 12"
slug: "install-laravel-jetstream-di-laravel-12"
category: "Laravel"
date: "2025-03-02"
status: "published"
---

Sama halnya dengan [Laravel Breeze](https://qadrlabs.com/post/install-laravel-breeze-di-laravel-12), Laravel Jetstream tidak tersedia secara default ketika kita memilih starter kit di laravel 12. Ketika kita run laravel installer untuk membuat project laravel 12 baru, tidak ada opsi untuk memilih laravel jetsream sebagai starter kit. 

```
 $ laravel new sample-app

   _                               _
  | |                             | |
  | |     __ _ _ __ __ ___   _____| |
  | |    / _` |  __/ _` \ \ / / _ \ |
  | |___| (_| | | | (_| |\ V /  __/ |
  |______\__,_|_|  \__,_| \_/ \___|_|


 ┌ Which starter kit would you like to install? ────────────────┐
 │ › ● None                                                     │
 │   ○ React                                                    │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Setelah rilis starter kit baru di laravel 12, timbul pertanyaan apakah kita masih bisa install laravel jetstream di project laravel? Untuk menjawab pertanyaan tersebut, kita akan coba bahas di tutorial ini.

## Overview{#overview}

Laravel Jetstream adalah paket resmi yang menyediakan implementasi autentikasi yang lebih canggih untuk aplikasi Laravel. Tidak seperti Laravel Breeze yang menawarkan solusi autentikasi minimalis, Jetstream menyediakan fitur tambahan seperti verifikasi email, autentikasi dua faktor, manajemen sesi, API token, dan manajemen tim.

Pada tutorial ini, kita akan mempelajari cara menginstal Laravel Jetstream di project Laravel 12 baru. Meskipun Laravel 12 memperkenalkan pendekatan baru untuk starter kit dan tidak menyertakan Jetstream sebagai opsi default, kita masih dapat menginstalnya secara manual.

Kita akan menggunakan Jetstream dengan Livewire, salah satu dari dua stack frontend yang didukung oleh Jetstream (yang lainnya adalah Inertia.js). Livewire memungkinkan kita membangun antarmuka yang dinamis tanpa harus menulis JavaScript secara langsung.

Setelah proses instalasi, kita akan menguji fungsionalitas Jetstream dengan mencoba beberapa fitur utamanya, termasuk halaman login, register, dan dashboard aplikasi. Tutorial ini akan membuktikan bahwa Laravel Jetstream masih kompatibel dan dapat digunakan dengan baik di Laravel 12 meskipun tidak lagi menjadi bagian dari opsi starter kit default.

## Step 1: Buat Project Baru {#step-1-buat-project-baru}

Sekarang kita akan membuat project baru tanpa starter kit menggunakan composer.

```
composer create-project --prefer-dist laravel/laravel:^12.0 laravel-12-with-jetstream
```

Kita tunggu sampai proses buat project baru selesai.



## Step 2: Install Laravel Jetstream {#step-2-install-laravel-jetstream}

Setelah project baru berhasil kita buat, selanjutnya kita masuk ke direktori project.

```
cd laravel-12-with-jetstream
```

Lalu kita install package laravel jetstream menggunakan composer.

```
composer require laravel/jetstream
```

Setelah proses install package selesai, selanjutnya kita bisa install auth scaffolding menggunakan laravel jetstream. Sebagai contoh di sini saya akan install Jetstream dengan livewire.

```
php artisan jetstream:install livewire
```

Pada saat kita run command di atas, terdapat proses install auth scaffolding, install dependensi frontend, build asset frontend dan proses migration.



## Step 3: Uji Coba {#step-3-uji-coba}

Laravel jetstream sudah kita berhasil kita install di laravel 12, sekarang kita coba run project kita. Buka terminal lalu run command berikut ini.

```
php artisan serve
```

Output:

```
$ php artisan serve

   INFO  Server running on [http://127.0.0.1:8000].  

  Press Ctrl+C to stop the server

```

Selanjutnya kita akses project di browser melalui `http://127.0.0.1:8000`.

![Akses halaman awal laravel 12](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-jetstream/1-akses-halaman-awal-laravel.png)

Pada halaman yang ditampilkan terdapat link yang menuju ke halaman login dan register. Selanjutnya kita coba akses halaman login.

![Akses halaman login laravel jetstream](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-jetstream/2-akses-halaman-login.png)

Seperti yang terlihat pada gambar di atas, halaman login laravel jetstream dapat diakses dengan baik di laravel 12. Setelah ini kita kembali lagi ke halaman awal, lalu akses halaman register.

![Akses halaman register](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-jetstream/3-akses-halaman-register.png)

Pada gambar di atas, halaman register pun dapat berjalan dengan baik. Di sini kita bisa coba isi form register, lalu tekan tombol REGISTER untuk mencoba daftar ke sistem.

![Akses halaman dashboard laravel jetstream](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-jetstream/4-akses-halaman-dashboard.png)

Ketika kita berhasil daftar, halaman akan dialihkan ke halaman dashboard. Tanda laravel jetstream berfungsi dengan baik di laravel 12.

## Penutup{#penutup}

Pada tutorial ini, kita telah berhasil menginstal dan mengujicoba Laravel Jetstream pada Laravel 12. Meskipun Laravel Jetstream tidak tersedia sebagai opsi starter kit default pada Laravel 12, kita tetap bisa menginstalnya secara manual dengan menggunakan Composer dan Artisan.

Kita telah membuktikan bahwa fitur-fitur Laravel Jetstream seperti halaman login, register, dan dashboard dapat berfungsi dengan baik di Laravel 12. Ini memberikan alternatif bagi para developer yang sudah terbiasa menggunakan Laravel Jetstream dan ingin tetap menggunakannya pada proyek Laravel 12 mereka.

Laravel Jetstream menawarkan fitur authentication yang lebih lengkap dibandingkan dengan Laravel Breeze, termasuk manajemen profil, manajemen tim, dan autentikasi dua faktor. Dengan tutorial ini, Anda dapat memanfaatkan semua fitur tersebut dalam proyek Laravel 12 Anda.

Sebagai kesimpulan, meskipun Laravel 12 memperkenalkan perubahan pada sistem starter kit, kita tetap memiliki fleksibilitas untuk menggunakan Laravel Jetstream jika diperlukan dalam pengembangan aplikasi kita.