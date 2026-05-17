---
title: "Percobaan Upgrade Versi Laravel 8 ke Laravel 10"
slug: "percobaan-upgrade-versi-laravel-8-ke-laravel-10"
category: "Laravel"
date: "2023-08-20"
status: "published"
---

Setiap pengembang web pasti pernah mengalami momen "Ah, sudah ada versi baru lagi?" Begitu juga yang saya rasakan saat mengerjakan proyek dengan Laravel 8. Di tengah kesibukan development, notifikasi update Laravel terbaru muncul di timeline. Seperti smartphone yang terus meminta update, framework pun demikian - selalu ada versi yang lebih baru, lebih aman, dan lebih baik. Namun berbeda dengan update smartphone yang cukup dengan satu klik, proses upgrade framework memerlukan pendekatan yang lebih hati-hati. Saya masih ingat bagaimana deg-degan nya saat pertama kali mencoba upgrade proyek client dari Laravel 8 ke versi terbaru. Untuk menghindari risiko, saya memutuskan untuk melakukan "latihan" terlebih dahulu dengan proyek sederhana. Dan di sinilah cerita itu bermula - sebuah perjalanan upgrade Laravel yang akan saya bagikan lengkap dengan tantangan dan solusinya.

## Overview{#overview}
Proses upgrade framework Laravel dari versi lama ke versi terbaru memerlukan pendekatan yang sistematis dan terencana. Tutorial ini akan memandu Anda melakukan upgrade bertahap dari Laravel 8 ke Laravel 10 melalui proyek sederhana yang telah disiapkan.

### What You'll Learn
- Cara mengidentifikasi dan mempersiapkan requirement untuk setiap versi Laravel
- Teknik upgrade bertahap untuk meminimalisir risiko kegagalan
- Strategi pengujian untuk memastikan aplikasi tetap berfungsi setelah upgrade
- Penanganan dependensi dan library pihak ketiga dalam proses upgrade
- Best practices dalam proses migrasi framework

### Upgrade Steps
Tutorial ini akan dibagi menjadi dua tahap utama:
1. **Upgrade Laravel 8 ke Laravel 9**
   - Penyesuaian requirement PHP dan composer
   - Migrasi dependensi dan konfigurasi
   - Pengujian fungsionalitas

2. **Upgrade Laravel 9 ke Laravel 10**
   - Update komponen inti dan library
   - Migrasi fitur yang deprecated
   - Verifikasi kompatibilitas

### Learning Outcomes
Setelah mengikuti tutorial ini, Anda akan dapat:
- Melakukan upgrade Laravel secara bertahap dan aman
- Memahami proses validasi setiap tahap upgrade
- Mengatasi kendala umum dalam proses upgrade
- Mengimplementasikan teknik serupa untuk proyek Anda sendiri

Mari kita mulai dengan mempersiapkan environment development yang diperlukan untuk proses upgrade ini.

## Persiapan{#persiapan}
Sebelum  mencoba proses update versi laravel 8 ke versi laravel 10 ini, ada beberapa hal yang harus diperhatikan dan tentu harus dipersiapkan terlebih dahulu. Berikut ini adalah tools yang saya gunakan.
1. Versi PHP yang saya gunakan ketika percobaan update ini ada dua versi yaitu versi 8.0 dan versi 8.1. Untuk proses switch versi php sudah saya tulis di postingan [sebelumnya](https://qadrlabs.com/post/tutorial-setup-dan-menggunakan-multiple-version-php-di-ubuntu)
2. Composer versi `Composer version 2.3.5`
3. Project yang akan digunakan sebagai uji coba proses update dengan Laravel versi 8.
4. Menggunakan `phpunit` untuk testing di awal dan di akhir.

Sekarang kita coba cek versi php terlebih dahulu. Buka terminal, lalu run command di bawah ini.
```bash
php -v
```

Output ketika command di run.
```
PHP 8.0.30 (cli) (built: Jul  3 2025 16:39:43) ( NTS )
Copyright (c) The PHP Group
Zend Engine v4.0.30, Copyright (c) Zend Technologies
    with Zend OPcache v8.0.30, Copyright (c), by Zend Technologies
    with Xdebug v3.4.5, Copyright (c) 2002-2025, by Derick Rethans


```
Output di atas adalah versi PHP yang digunakan ketika di awal percobaan.

Sekarang kita coba clone project dari sample repositori. Sample repositori dapat diakses di link berikut.

```
https://github.com/qadrLabs/belajar-laravel-8-testing-crud-feature
```

Selanjutnya kita buka terminal, lalu clone repositori ini menggunakan `git clone`
```bash
git clone https://github.com/qadrLabs/belajar-laravel-8-testing-crud-feature.git
```
Selanjutnya masuk ke direktori project
```bash
cd belajar-laravel-8-testing-crud-feature
```
 
Lalu kita copy `.env.example` menjadi `.env` 
```bash
cp .env.example .env
```

Selanjutnya kita sesuaikan credentials database di file ini.

Selanjutnya kita install dependensi dengan run command.

```bash
composer install
```

Lalu kita generate key menggunakan command ```
```bash
php artisan key:generate
```

Selanjutnya kita run command
```bash
php artisan migrate
```

Sekarang kita coba run testing terlebih dahulu untuk memastikan tidak terdapat error.
```bash
vendor/bin/phpunit
```

Output ketika command di atas kita run.
```bash
$ vendor/bin/phpunit 
PHPUnit 9.5.9 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 00:00.077, Memory: 22.00 MB

OK (2 tests, 4 assertions)


```

Oke, sekarang kita mulai percobaan upgrade versi 8 ke versi 9.

## Step 1 - Upgrade Laravel versi 8 ke Laravel versi 9{#step-1}

Sekarang kita buka file `composer.json` terlebih dahulu. Lalu kita sesuaikan versi php sesuai dengan requirement php untuk laravel versi 9. Temukan baris kode berikut ini di file `composer.json`.

```json
"require": {
        "php": "^7.3|^8.0",

		// ... baris kode lainnya
    },
```

Lalu kita ubah versi phpnya menjadi `^8.0.2`.
```json
    "require": {
        "php": "^8.0.2",

		// ... baris kode lainnya
    },
```

Selanjutnya kita ubah versi `laravel/framework` dan library `nunomaduro/collision`.
```json
    "require": {

        "laravel/framework": "^9.0",
        
        // ... baris kode lainnya
    },
    "require-dev": {
    
        "nunomaduro/collision": "^6.1",
        
	    // ... baris kode lainnya
    },
```

Lalu yang terakhir ubah library `facade/ignition` dengan `"spatie/laravel-ignition": "^1.0"`

```json
    "require-dev": {
        "spatie/laravel-ignition": "^1.0",
        
		// .. baris kode lainnya
    },
```

Save kembali file `composer.json`.

Selanjutnya kita update menggunakan command
```
composer update
```

Tunggu sampai proses update framework dan library selesai.

Apabila sudah selesai, kita coba run kembali testing untuk memastikan semuanya berjalan dengan baik.
```bash
vendor/bin/phpunit
```

```bash
$ vendor/bin/phpunit
PHPUnit 9.6.29 by Sebastian Bergmann and contributors.

..                                                                  2 / 2 (100%)

Time: 00:00.204, Memory: 26.00 MB

OK (2 tests, 4 assertions)


```

Oke tidak ada error atau apapun tanda proses upgrade laravel versi 8 ke laravel 9 berhasil.

Sebagai alternatif boleh juga buka projectnya langsung di browser. Run command.
```bash
php artisan serve
```
Lalu buka `http://127.0.0.1:8000` di browser. Apabila tidak ada error tandanya proses upgrade berhasil.

## Step 2 - Upgrade Laravel versi 9 ke Laravel versi 10{#step-2}
Sebelum melanjutkan proses upgrade versi laravel, kita harus ganti dulu versi PHP yang digunakan untuk memenuhi syarat requirement penggunaan Laravel versi 10, yaitu PHP versi 8.1 ke atas.

Setelah versi PHP diubah, kita cek kembali versi php yang digunakan  untuk memastikan. 

```bash
php -v
```

Output ketika command di run.
```
$ php -v
PHP 8.1.33 (cli) (built: Jul  3 2025 16:16:18) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.1.33, Copyright (c) Zend Technologies
    with Zend OPcache v8.1.33, Copyright (c), by Zend Technologies


```

Oke requirement pertama sudah terpenuhi.

Requirement berikutnya adalah composer yang digunakan yaitu composer `2.2.0` atau lebih besar. 

Sekarang kita cek versi `composer`.
```
composer --version
```
Output ketika command dirun.
```
$ composer --version
Composer version 2.7.4 2024-04-22 21:17:03


```

Output di atas adalah `composer` yang saya gunakan.

Oke requirement untuk composer juga sudah terpenuhi. 

Sekarang kita lanjutnkan proses upgrade dari laravel versi 9 ke laravel versi 10.

Langkah pertama adalah menyesuiakan versi PHP sesuai dengan requirement laravel 10. Buka kembali file `composer.json`, 

```json
    "require": {
        "php": "^8.0.2",

	    // ... baris kode lainnya
    },
```

lalu kita sesuaikan versi php nya.

```json
    "require": {
        "php": "^8.1",
        
        // ... baris kode lainnya
    },
```

Langkah kedua adalah update dependensi yang digunakan. Temukan laravel dan library di bawah ini.

```json
    "require": {
		// ... baris kode lainnya
        "laravel/framework": "^9.0",
        "laravel/sanctum": "^2.11",
        
	    // ... baris kode lainnya
    },
    "require-dev": {
        "spatie/laravel-ignition": "^1.0",

		// ... baris kode lainnya
    },
```

Lalu kita sesuaikan versinya dan tambahkan library `doctrine/dbal`.
```json
"require": {

        "laravel/framework": "^10.0",
        "laravel/sanctum": "^3.2",
        "doctrine/dbal": "^3.0"

		// ... baris kode lainnya
    },
    "require-dev": {
        "spatie/laravel-ignition": "^2.0",

		// ... baris kode lainnya
    },
```



Karena kita menggunakan `phpunit` untuk testing kita perlu menyesuikan library nya juga.
```json
    "require-dev": {
        // ... baris kode lainnya
        
        "nunomaduro/collision": "^6.1",
        "phpunit/phpunit": "^9.3.3"
    },
```

Kita sesuikan versi phpunit dan library `nunomaduro/collision`.
```json
    "require-dev": {
        // ... baris kode lainnya
        
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.0"
    },
```

Langkah selanjutnya adalh modifikasi versi minimum stability menjadi `stable`.
```
"minimum-stability": "stable",
```

Karena core Laravel 10 sudah menyediakan CORS middleware, kita hapus `fruitcake/laravel-cors` dependensi.

```json
    "require": {
        "php": "^8.1",
        "fruitcake/laravel-cors": "^2.0", // hapus ini
        "guzzlehttp/guzzle": "^7.0.1",
        "laravel/framework": "^10.0",
        "laravel/sanctum": "^3.2",
        "laravel/tinker": "^2.5",
        "doctrine/dbal": "^3.0"
    },
```


Setelah library dihapus, berikut ini adalah dependensi yang sudah kita sesuaikan.
```json
    "require": {
        "php": "^8.1",
        "guzzlehttp/guzzle": "^7.0.1",
        "laravel/framework": "^10.0",
        "laravel/sanctum": "^3.2",
        "laravel/tinker": "^2.5",
        "doctrine/dbal": "^3.0"
    },
    "require-dev": {
        "spatie/laravel-ignition": "^2.0",
        "fakerphp/faker": "^1.9.1",
        "laravel/sail": "^1.0.1",
        "mockery/mockery": "^1.4.2",
        "nunomaduro/collision": "^7.0",
        "phpunit/phpunit": "^10.0"
    },
    "minimum-stability": "stable",
```

Karena terdapat kode yang menggunakan library `fruitcake/laravel-cors`, kita perlu menghapus penggunaannya dan menyesuaikan dengan code dari laravel. 

Buka file `app/Http/Kernel.php`, lalu temukan baris kode berikut ini.

```php
    protected $middleware = [

		// ... baris kode lainnya

        \Fruitcake\Cors\HandleCors::class, // temukan class ini
		// ... baris kode lainnya
    ];
```

Lalu kita sesuaikan menjadi baris kode berikut.
```php
    protected $middleware = [
        // ... baris kode lainnya
    
        \Illuminate\Http\Middleware\HandleCors::class,
       
       // ... baris kode lainnya
    ];

```

Save kembali file `app/Http/Kernel.php`.

Langkah selanjutnya adalah update juga library third party yang digunakan. Ini langkah opsional, karena di sample project ada library tambahan untuk testing jadi kita coba update juga.

Buka kembali file `composer.json`, lalu temukan baris kode berikut ini.

```json
    "require-dev": {
    
        "laravel/browser-kit-testing": "^6.4",
        // ... baris kode lainnya
    },
```

Kita sesuaikan dengan versi library yang support laravel 10.
```json
    "require-dev": {

        "laravel/browser-kit-testing": "^7.0",
        // ... baris kode lainnya
    },
```


Sekarang kita mulai proses update framework dan dependensi yang sudah kita sesuaikan dengan run command.
```bash
composer update
```

Tunggu sampai proses update selesai.

Setelah selesai kita coba run testing menggunakan command.
```bash
vendor/bin/phpunit
```
Output ketika dirunnya ternyata perlu ada penyesuaian konfigurasi phpunit untuk versi terbaru.
```bash
$ vendor/bin/phpunit
PHPUnit 10.5.58 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.1.33
Configuration: /home/gun-gun-priatna/learning-lab/testing-tutorial/belajar-laravel-8-testing-crud-feature/phpunit.xml

..                                                                  2 / 2 (100%)

Time: 00:00.214, Memory: 28.00 MB

OK, but there were issues!
Tests: 2, Assertions: 4, PHPUnit Deprecations: 1.

```

Sekarang kita coba sesuaikan konfigurasi phpunit dengan run command.
```bash
vendor/bin/phpunit --migrate-configuration
```

Output di terminal menampilkan prosesnya.
```bash
$ vendor/bin/phpunit --migrate-configuration
PHPUnit 10.5.58 by Sebastian Bergmann and contributors.

Created backup:         /home/gun-gun-priatna/learning-lab/testing-tutorial/belajar-laravel-8-testing-crud-feature/phpunit.xml.bak
Migrated configuration: /home/gun-gun-priatna/learning-lab/testing-tutorial/belajar-laravel-8-testing-crud-feature/phpunit.xml


```

Sekarang kita coba run kembali phpunit.
```bash
vendor/bin/phpunit 
```
Output:
```bash
$ vendor/bin/phpunit
PHPUnit 10.5.58 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.1.33
Configuration: /home/gun-gun-priatna/learning-lab/testing-tutorial/belajar-laravel-8-testing-crud-feature/phpunit.xml

..                                                                  2 / 2 (100%)

Time: 00:00.083, Memory: 26.00 MB

OK (2 tests, 4 assertions)


```

Ya, tidak ada error ketika kita run testing. Ini tandanya prosees upgrade dari laravel versi 9 ke laravel versi 10 berhasil.

Tentu untuk memastikan bisa run project di browser secara langsung. Run command.
```bash
php artisan serve
```
Lalu buka  `http://127.0.0.1:8000/post` di browser. Apabila tidak terdapat error, ini tandanya proses upgrade berhasil.

Sekarang kita cek versi laravel menggunakan command di bawah ini.
```bash
php artisan --version
```

Output:
```bash
$ php artisan --version
Laravel Framework 10.49.1
```

## Penutup{#penutup}
Tutorial ini telah membahas proses upgrade Laravel secara bertahap dari versi 8 ke versi 10. Beberapa poin penting yang dapat kita simpulkan:

### Achievements
- Berhasil melakukan upgrade Laravel 8 ke Laravel 9
- Sukses melanjutkan upgrade ke Laravel 10
- Mempertahankan fungsionalitas aplikasi yang dibuktikan dengan passing tests
- Menangani perubahan dependensi dan library dengan baik

### Key Takeaways
- Pentingnya pendekatan bertahap dalam proses upgrade
- Manfaat penggunaan testing untuk validasi setiap tahap
- Pemahaman tentang requirement dan kompatibilitas antar versi
- Teknik penanganan deprecated features dan library

### Next Steps
Untuk implementasi di proyek produksi, disarankan untuk:
- Membuat backup sebelum memulai proses upgrade
- Mendokumentasikan setiap perubahan yang dilakukan
- Melakukan testing yang lebih komprehensif
- Mempersiapkan rollback plan jika diperlukan

Dengan mengikuti langkah-langkah yang telah dibahas, Anda dapat menerapkan proses serupa untuk upgrade Laravel di proyek Anda sendiri dengan lebih percaya diri.