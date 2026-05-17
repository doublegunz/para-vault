---
title: "Run Laravel Project menggunakan Laravel Octane dan FrankenPHP"
slug: "run-laravel-project-menggunakan-laravel-octane-dan-frankenphp"
category: "Laravel"
date: "2024-12-25"
status: "published"
---

## Pendahuluan {#pendahuluan}

Apakah Anda sering merasa frustrasi dengan waktu load aplikasi Laravel yang terlalu lama? Atau mungkin Anda memerlukan solusi untuk menangani trafik tinggi tanpa menguras resource server? Kabar baiknya Laravel Octane dengan FrankenPHP dapat menjadi solusi untuk kedua masalah tersebut. Tutorial kali ini kami tulis sebagai tanggapan terkait masalah tersebut dan juga kebutuhan banyak developer yang ingin meningkatkan performa aplikasi laravel mereka tanpa harus menghabiskan banyak waktu untuk menangani konfigurasi yang kompleks. Dengan menggabungkan Laravel Octane dengan FrankenPHP memungkinkan kita untuk membangun aplikasi dengan kecepatan tinggi dan efisiensi yang luar biasa. Pada tutorial ini kita akan coba bahas seperti apa langkah-langkah menggunakan Laravel Octane dan FrankenPHP dalam aplikasi yang dibangun menggunakan Laravel. 

## Apa Itu FrankenPHP? {#apa-itu-frankenphp}
Kita sudah pernah bahas FrankenPHP di artikel sebelumnya yaitu [Install FrankenPHP di Ubuntu 24.04](https://qadrlabs.com/post/install-frankenphp-di-ubuntu-2404), sebagai pengingat FrankenPHP adalah server PHP modern yang dirancang untuk mendukung aplikasi web dengan performa tinggi [^1]. Dibangun dengan teknologi mutakhir di atas Caddy Web Server, FrankenPHP memungkinkan pengembang untuk menjalankan aplikasi berbasis PHP dengan lebih efisien.  

Salah satu fitur utama FrankenPHP adalah integrasinya yang mendalam dengan Laravel Octane, menjadikannya pilihan ideal bagi pengembang Laravel. Dengan kemampuan seperti request handling yang cepat, low-latency, dan manajemen koneksi yang efisien, FrankenPHP memastikan aplikasi Anda tetap responsif bahkan dalam kondisi lalu lintas tinggi.  

## Apa Itu Laravel Octane? {#apa-itu-laravel-octane}
Laravel Octane adalah salah satu Laravel Package dari ekosistem laravel yang dirancang untuk meningkatkan performa aplikasi kita dengan menjalankan aplikasi menggunakan server aplikasi berdaya tinggi [^2]. Laravel Octane memuat aplikasi kita sekali, menyimpannya di memori, dan kemudian memproses permintaan dengan kecepatan yang sangat tinggi. Octane mendukung berbagai server seperti Swoole, RoadRunner, dan FrankenPHP. Pada artikel ini kita akan coba membahas Penggunaan Laravel Octane dengan FrankenPHP.

## Overview {#overview}
Pada tutorial ini kita akan gunakan Laravel Octane dan FrankenPHP di dalam project Laravel. Dalam menggunakan Laravel Octane kita akan mempelajari
1. Cara menginstal Laravel Octane dan mengonfigurasinya dengan FrankenPHP.  
2. Langkah-langkah menjalankan aplikasi Laravel menggunakan Laravel Octane dan FrankenPHP.  
3. Manfaat menggunakan Laravel Octane dalam meningkatkan performa aplikasi Anda.  

Sebagai studi kasus, kita akan setup project Laravel sederhana yang menggunakan Laravel Octane sebagai mesin utamanya dan running project menggunakan server FrankenPHP.

## Daftar Isi {#daftar-isi}
1. [Pendahuluan](#pendahuluan)  
2. [Apa Itu FrankenPHP?](#apa-itu-frankenphp)  
3. [Apa Itu Laravel Octane?](#apa-itu-laravel-octane)  
4. [Overview](#overview)  
5. [Step 1: Membuat Project Laravel](#step-1-create-laravel-project)  
6. [Step 2: Instal Laravel Octane dan FrankenPHP](#step-2-install-laravel-octane-with-frankenphp)  
7.  [Step 3: Menjalankan Proyek Laravel](#step-3-run-laravel-project)  
8. [Penutup](#penutup)  

## Step 1: Membuat Project Laravel {#step-1-create-laravel-project}
Pertama kita buat terlebih dahulu project laravel yang akan kita gunakan sebagai studi kasus tutorial. Untuk buat project, buka terminal lalu run command berikut ini.
   ```bash
   composer create-project --prefer-dist laravel/laravel sample-app
   ```  
Tunggu sampai proses install laravel selesai.

Apabila proses install selesai, selanjutnya kita pindah ke direktori project `sample-app` menggunakan command berikut ini.
   ```bash
   cd sample-app
   ```  

## Step 2: Instal Laravel Octane dengan FrankenPHP {#step-2-install-laravel-octane-with-frankenphp}
Setelah proyek Laravel kita buat, langkah berikutnya adalah menginstal Laravel Octane dan mengonfigurasinya dengan FrankenPHP. Kita buka kembali terminal, lalu run command berikut ini untuk install Laravel Octane.
	```
	composer require laravel/octane
	```
Setelah laravel octane terinstall, selanjutnya run command berikut ini untuk install Konfigurasi file Octane ke aplikasi kita.
   ```bash
   php artisan octane:install
   ```  
Selanjutnya tampil prompt untuk memilih server aplikasi, kita pilih `FrankenPHP`, lalu tekan `enter`.
   Output:  
   ```bash
$ php artisan octane:install

 ┌ Which application server you would like to use? ─────────────┐
 │ frankenphp                                                   │
 └──────────────────────────────────────────────────────────────┘

   ```  
Jika binary FrankenPHP tidak ditemukan di sistem kita, Laravel Octane akan meminta izin untuk mengunduhnya. Pilih `Yes` dan tekan `enter` untuk melanjutkan.  

   Output:  
   ```bash
    ┌ Unable to locate FrankenPHP binary. Should Octane download the binary for… ┐
    │ Yes                                                                        │
    └────────────────────────────────────────────────────────────────────────────┘
   ```  
Selanjutnya kita tunggu sampai proses download FrankenPHP binary selesai.
```
php artisan octane:install

 ┌ Which application server you would like to use? ─────────────┐
 │ frankenphp                                                   │
 └──────────────────────────────────────────────────────────────┘

 ┌ Unable to locate FrankenPHP binary. Should Octane download the binary for… ┐
 │ Yes                                                                        │
 └────────────────────────────────────────────────────────────────────────────┘

37% [▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░]  61731150/165855064 bytes
```


Setelah instalasi selesai, jalankan perintah berikut untuk melihat daftar file di root project:  
```bash
ls
```  
Output yang ditampilkan:  
```bash
$ ls
app      bootstrap      composer.lock  database    package.json  postcss.config.js  README.md  routes   tailwind.config.js  vendor
artisan  composer.json  config         frankenphp  phpunit.xml   public             resources  storage  tests               vite.config.js
```  
Kita akan melihat file `frankenphp` di direktori root, menandakan bahwa instalasi berhasil.  

Setelah proses setup Laravel Octane dan frankenPHP selesai, kita buka file `.env` di root project dan cari variabel `OCTANE_SERVER`. Kita akan melihat value sebagai berikut:  
```
OCTANE_SERVER=frankenphp
```  

Variabel ini memastikan bahwa Laravel Octane menggunakan FrankenPHP sebagai server utama.  


## Step 3: Menjalankan Proyek Laravel {#step-3-run-laravel-project}
Setelah semua konfigurasi selesai, saatnya run proyek Laravel kita. Untuk run project menggunakan laravel octane, buka kembali terminal lalu run command berikut ini
```
php artisan octane:start
```  
Output yang ditampilkan di terminal seperti berikut ini.
```bash
php artisan octane:start

   INFO  Server running….


  Local: http://127.0.0.1:8000

  Press Ctrl+C to stop the server
```  

Selanjutnya kita bisa akses `http://127.0.0.1:8000` di browser kita untuk melihat project Laravel berjalan menggunakan Laravel Octane dan FrankenPHP.  Pada saat akses, kita coba akses beberapa kali dan berikut ini output yang ditampilkan di terminal.
```
  200    GET / ....................................................... 78.04 ms
  200    GET /favicon.ico ............................................. 5.08 ms
  200    GET / ....................................................... 28.10 ms
```
Selanjutnya kita stop terlebih dahulu menggunakan `CTRL` + `C`.

Sebagai pembanding, kita coba run menggunakan command berikut.
```
php artisan serve
```
Output yang ditampilkan:
```
php artisan serve

   INFO  Server running on [http://127.0.0.1:8000].

  Press Ctrl+C to stop the server
```

Lalu kita buka project di browser dan kita akses beberapa kali. Berikut hasil yang ditampilkan di output terminal.
```
  2026-01-01 19:03:04 / .......................................... ~ 505.72ms
  2026-01-01 19:03:04 / ................................................ ~ 3s
  2026-01-01 19:03:07 ............................................... ~ 6m 2s
```

## Penutup {#penutup}
Melalu tutorial ini, kita telah berhasil implementasikan Laravel Octane dengan FrankenPHP dan membuktikan peningkatan performa yang signifikan. Dari hasil pengujian sederhana, terlihat bahwa response time menggunakan Laravel Octane ( 28-78ms) jauh lebih cepat dibandingkan menggunakan `php artisan serve` yang mencapai ratusan milidetik hingga beberapa detik. Perbedaan ini terjadi karena Laravel Octane memuat aplikasi sekali ke memori dan tetap *persistent*, sehingga tidak perlu melakukan bootstrap ulang untuk setiap request.
Kombinasi laravel octane dan FrankenPHP menawarkan solusi praktis bagi developer yang ingin meningkatkan performa aplikasi tanpa konfigurasi kompleks. Meskipun tutorial ini menggunakan contoh sederhana, manfaat sebenarnya akan terasa lebih signifikan pada aplikasi dengan skala lebih besar dan trafik tinggi.

### Key Takeaways
1. Performa lebih cepat. Laravel Octane menyimpan aplikasi di memori sehingga menghilangkan overhead bootstrap pada setiap request, menghasilkan response time yang konsisten dan cepat.
2. Instalasi sederhana. Hanya butuh tiga langkah utama: install package Octane, jalankan `octane:install` dan pilih FrankenPHP sebagai server.
3. FrankenPHP sebagai modern server. Dibangun di atas Caddy Web Server, FrankenPHP menawarkan low latency dan manajemen koneksi yang efisien untuk manangani trafik tinggi.
4. Perbedaan Signifikan dengan Built-in Server. Pengujian menunjukkan `octane:start` memberikan response time pulihan milidetik, sementara `artisan serve` bisa mencapai beberapa detaik.
5. Cocok untuk production. Laravel Octane dengan FrankenPHP dirancang untuk menangani beban production dengan efisien.

### Referensi
[^1]: Dokumentasi Resmi FrankenPHP https://frankenphp.dev/docs
[^2]: Dokumentasi Laravel Octane https://laravel.com/docs/12.x/octane