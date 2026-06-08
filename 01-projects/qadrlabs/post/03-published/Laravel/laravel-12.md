---
title: "Laravel 12"
slug: "laravel-12"
category: "Laravel"
date: "2025-02-24"
status: "published"
---

**Laravel 12** resmi dirilis pada 24 Februari 2025, melanjutkan perbaikan dari versi 11.x dengan fokus pada pembaruan dependencies dan pengenalan starter kits inovatif. Mari kita telusuri apa saja yang baru dalam versi terbaru ini.

## Minimal Breaking Changes {#minimal-breaking-changes}

Tim pengembang Laravel kali ini fokus meminimalkan perubahan yang dapat merusak sistem yang sudah ada. Mereka lebih mengutamakan perbaikan kualitas berkelanjutan sepanjang tahun tanpa mengganggu aplikasi yang telah berjalan.

Laravel 12 hadir sebagai "maintenance release" yang relatif kecil, terutama untuk meningkatkan dependencies yang sudah ada. Kabar baiknya, sebagian besar aplikasi Laravel dapat diperbarui ke versi 12 tanpa perlu mengubah kode aplikasi yang sudah ada.

## Starter Kits Aplikasi Baru{#new-starter-kit}

Fitur unggulan Laravel 12 adalah starter kits baru untuk React, Vue, dan Livewire:

- Starter kits React dan Vue memanfaatkan Inertia 2, TypeScript, shadcn/ui, dan Tailwind
- Starter kit Livewire menggunakan library komponen Flux UI berbasis Tailwind dan Laravel Volt

Semua starter kits ini dilengkapi sistem autentikasi bawaan Laravel untuk login, registrasi, reset password, verifikasi email, dan banyak lagi. Sebagai pilihan tambahan, setiap starter kit juga hadir dengan varian yang didukung WorkOS AuthKit, menawarkan autentikasi sosial, passkeys, dan dukungan SSO. WorkOS menyediakan autentikasi gratis untuk aplikasi hingga 1 juta pengguna aktif bulanan.

Dengan munculnya starter kits baru ini, Laravel Breeze dan Laravel Jetstream tidak akan menerima pembaruan tambahan lagi.

## Kebijakan Support{#kebijakan-support}

Setiap versi mayor Laravel memiliki kebijakan support yang jelas:

- Bug fixes tersedia selama 18 bulan setelah rilis
- Security fixes tersedia selama 2 tahun setelah rilis

Untuk library tambahan termasuk Lumen, hanya versi mayor terbaru yang menerima perbaikan bug.



Berikut ini jadwal dukungan laravel:

| Versi | PHP (*)   | Tanggal Rilis    | Bug Fixes Hingga | Security Fixes Hingga |
| ----- | --------- | ---------------- | ---------------- | --------------------- |
| 9     | 8.0 - 8.2 | 8 Februari 2022  | 8 Agustus 2023   | 6 Februari 2024       |
| 10    | 8.1 - 8.3 | 14 Februari 2023 | 6 Agustus 2024   | 4 Februari 2025       |
| 11    | 8.2 - 8.4 | 12 Maret 2024    | 3 September 2025 | 12 Maret 2026         |
| 12    | 8.2 - 8.4 | 24 Februari 2025 | 13 Agustus 2026  | 24 Februari 2027      |

Perhatikan bahwa Laravel selalu mendukung beberapa versi PHP, memberikan fleksibilitas sekaligus mendorong penggunaan versi PHP yang terbaru dan aman. Untuk pengembangan aplikasi baru, disarankan untuk selalu menggunakan versi Laravel dan PHP terbaru untuk mendapatkan fitur terbaru dan dukungan jangka panjang.

## Server Requirements{#server-requirements}

Untuk menjalankan Laravel 12, server web Anda harus memenuhi persyaratan minimum berikut:

* PHP 8.2 atau lebih tinggi
* Extension PHP: Ctype, cURL, DOM, Fileinfo, Filter, Hash, Mbstring, OpenSSL, PCRE, PDO, Session, Tokenizer, dan XML



## Cara Menginstal Laravel 12 {#cara-menginstal-laravel-12}

Terdapat dua cara untuk menginstal laravel 12, yaitu menggunakan laravel installer dan menggunakan composer.

1. Untuk install laravel menggunakan laravel install, kita harus Instal Laravel installer secara global:

   ```
   composer global require laravel/installer
   ```

   Setelah selesai install, buat aplikasi Laravel baru dengan run command berikut ini

   ```
   laravel new example-app
   ```
	 
	 **Keterangan:** Karena [Laravel 13](https://qadrlabs.com/post/laravel-13-is-here-ai-native-features-semantic-search-and-more) telah dirilis pada tanggal 17 Maret 2026, ketika kita run command di atas akan menginstall laravel versi 13. Jadi untuk menginstall laravel 12 sekarang ini hanya dapat diinstall dengan command composer.

2. Untuk install laravel menggunakan composer, kita bisa langsung run command berikut ini

   ```
   composer create-project laravel/laravel:^12.0 example-app
   ```

   

Saat proses instalasi, Laravel akan meminta kita memilih framework testing, database, dan starter kit yang diinginkan.

Setelah aplikasi berhasil diinstall, masuk ke direktori aplikasi dan run command berikut untuk menginstal dependensi JavaScript dan membangun aset:

```
cd example-app
npm install && npm run build
```

Selanjutnya kita run laravel 12 menggunakan command berikut ini.

```
composer run dev
```

Selanjutnya kita bisa akses laravel melalui http://localhost:8000 di browser.

![akses laravel 12 di browser](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/header/laravel-12.png)



## Penutup {#penutup}

Laravel 12 hadir sebagai versi yang mementingkan stabilitas dan peningkatan berkelanjutan dengan fokus pada pembaruan dependencies tanpa memberikan perubahan yang signifikan pada kode yang sudah ada. Versi terbaru ini menawarkan starter kits inovatif untuk React, Vue, dan Livewire yang dilengkapi dengan sistem autentikasi bawaan dan dukungan WorkOS AuthKit.

Dengan kebijakan dukungan yang jelas selama 18 bulan untuk perbaikan bug dan 2 tahun untuk perbaikan keamanan, Laravel 12 memberikan jaminan stabilitas jangka panjang bagi para pengembang. Persyaratan minimum PHP 8.2 dan beberapa ekstensi PHP standar memastikan Laravel 12 dapat berjalan optimal pada server web modern.

Proses instalasi Laravel 12 yang fleksibel, baik melalui Laravel installer maupun Composer, memudahkan pengembang untuk memulai proyek baru dengan cepat. Penghentian pembaruan untuk Laravel Breeze dan Laravel Jetstream menunjukkan komitmen tim pengembang untuk fokus pada teknologi dan alat baru yang lebih efisien.

Bagi pengembang yang ingin memulai proyek baru atau memperbarui aplikasi yang sudah ada, Laravel 12 hadir sebagai pilihan yang solid dengan dukungan jangka panjang hingga Februari 2027 untuk perbaikan keamanan.