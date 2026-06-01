---
title: "Mencegah Destructive Command Running di Laravel"
slug: "mencegah-destructive-command-running-di-laravel"
category: "Laravel"
date: "2025-02-19"
status: "published"
---

## Introduction{#introduction}
Pernahkah Anda merasa was-was saat menjalankan perintah Artisan di terminal? Apalagi jika perintah tersebut memiliki potensi besar untuk menghapus data penting di lingkungan produksi. Nah, jangan khawatir! Laravel, framework PHP yang terkenal dengan kepraktisannya, punya solusi canggih untuk masalah ini. Fitur ini memungkinkan Anda mencegah destructive command—seperti migrasi database atau penghapusan massal—dari berjalan di lingkungan produksi. 

Dalam artikel **Mencegah Destructive Command Running di Laravel**, kita akan membahas bagaimana fitur ini bekerja, bagaimana Anda bisa menggunakannya dalam proyek Laravel Anda, serta tips praktis untuk melindungi aplikasi dari kerusakan tidak disengaja. Jadi, apakah Anda siap untuk belajar cara melindungi aplikasi Anda dengan lebih baik?

## Overview{#overview}
Artikel ini akan membahas secara mendalam tentang fitur baru di Laravel yang memungkinkan Anda mencegah destructive command berjalan di lingkungan produksi. Kami akan mulai dengan menjelaskan apa itu destructive command dan mengapa mereka bisa menjadi ancaman serius bagi aplikasi Anda. Lalu, kami akan menyelami bagaimana Laravel menangani masalah ini melalui trait `Illuminate\Console\Prohibitable`.

Anda juga akan mempelajari:
- Bagaimana menerapkan fitur ini di proyek Laravel Anda.
- Contoh kasus nyata di mana fitur ini sangat berguna.
- Cara membuat perintah Artisan kustom Anda sendiri yang dilengkapi dengan proteksi ini.
- Tips tambahan untuk meningkatkan keamanan aplikasi Anda.

Jika Anda adalah seorang developer Laravel pemula atau bahkan senior, artikel ini akan memberikan wawasan baru yang pasti akan membantu Anda menghindari kesalahan fatal di masa depan. Yuk, simak lebih lanjut!

## Apa Itu Destructive Command? Mengapa Harus Dicegah?{#apa-itu-perintah-destructive-mengapa-harus-dicegah}

Sebelum kita menyelami teknisnya, mari kita pahami dulu apa yang dimaksud dengan "destructive command". Istilah ini merujuk pada perintah-perintah yang dapat menyebabkan kerusakan signifikan pada aplikasi Anda, terutama di lingkungan produksi. Contohnya termasuk perintah seperti `php artisan migrate:fresh`, yang akan menghapus seluruh tabel database Anda dan membuat ulang dari awal. Bayangkan jika perintah ini dijalankan di server produksi—data pelanggan, transaksi, hingga informasi penting lainnya bisa lenyap dalam sekejap!

Lalu, kenapa perintah semacam ini harus dicegah? Jawabannya sederhana: kesalahan manusia. Bahkan developer paling berpengalaman sekalipun bisa saja salah ketik atau lupa memeriksa apakah terminal mereka terhubung ke server produksi atau lokal. Sebuah klik salah atau tekanan tombol Enter yang terburu-buru bisa berakibat fatal. Oleh karena itu, Laravel hadir dengan fitur yang dirancang khusus untuk mencegah hal ini terjadi.

## Memahami Trait `Prohibitable` di Laravel{#memahami-trait-prohibitable-di-laravel}

Salah satu fitur baru yang diperkenalkan di Laravel 11.9 adalah trait `Illuminate\Console\Prohibitable`. Trait ini memberikan metode `prohibit()` yang dapat digunakan untuk menentukan apakah suatu perintah boleh dijalankan atau tidak. Fitur ini pertama kali diusulkan oleh Jason McCreary dan Joel Clermont melalui PR #51376 di GitHub pada Mei 2024.

Jadi, bagaimana cara kerjanya? Sederhananya, Anda dapat menggunakan metode `prohibit()` untuk memblokir perintah tertentu agar tidak berjalan di lingkungan produksi. Misalnya, jika Anda mencoba menjalankan `php artisan migrate:fresh` di server produksi, Laravel akan memberikan peringatan seperti ini:

```
WARN  This command is prohibited from running in this environment.
```

Fitur ini sangat berguna karena tidak hanya memberikan peringatan tetapi juga sepenuhnya memblokir perintah tersebut agar tidak dieksekusi. Dengan kata lain, Anda tidak perlu khawatir lagi tentang kesalahan fatal akibat destructive command.

## Cara Mencegah Destructive Command Bawaan Laravel{#cara-mencegah-perintah-destructive-bawaan-laravel}
Laravel sudah menyertakan beberapa destructive command bawaan yang secara default dilengkapi dengan proteksi ini. Beberapa di antaranya adalah:
- `migrate:fresh`
- `migrate:refresh`
- `migrate:reset`
- `migrate:rollback`
- `migrate:wipe`

Untuk mengaktifkan proteksi ini, Anda cukup menambahkan beberapa baris kode di file `AppServiceProvider`. Berikut adalah contohnya:

```php
declare(strict_types=1);

namespace App\Providers;

use Illuminate\Database\Console\Migrations\FreshCommand;
use Illuminate\Database\Console\Migrations\RefreshCommand;
use Illuminate\Database\Console\Migrations\ResetCommand;
use Illuminate\Database\Console\Migrations\RollbackCommand;
use Illuminate\Database\Console\WipeCommand;
use Illuminate\Support\ServiceProvider;

final class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        WipeCommand::prohibit($this->app->isProduction());
        FreshCommand::prohibit($this->app->isProduction());
        ResetCommand::prohibit($this->app->isProduction());
        RefreshCommand::prohibit($this->app->isProduction());
        RollbackCommand::prohibit($this->app->isProduction());
    }
}
```

## Membuat Perintah Artisan Kustom dengan Proteksi{#membuat-perintah-artisan-kustom-dengan-proteksi}

Selain perintah bawaan Laravel, Anda juga bisa menerapkan proteksi ini pada perintah Artisan kustom yang Anda buat sendiri. Misalnya, bayangkan Anda memiliki perintah untuk menghapus semua data dari layanan pihak ketiga seperti Midtrans. Tentu saja, Anda tidak ingin perintah ini dijalankan di lingkungan produksi!

Sekarang kita coba generate command baru.
```
php artisan make:command ClearMidtransData
```
Output:
```
   INFO  Console command [C:\laragon\www\belajar_laravel\app\Console\Commands\ClearMidtransData.php] created successfully.
```

Selanjutnya kita tambahkan baris kode berikut pada file `app\Console\Commands\ClearMidtransData.php`.

```php
declare(strict_types=1);

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Console\Prohibitable;

final class ClearMidtransData extends Command
{
    use Prohibitable;

    protected $signature = 'app:clear-midtrans-data';

    public function handle(): int
    {
        if ($this->isProhibited()) {
            return self::FAILURE;
        }

        // Logika untuk menghapus data Midtrans...
    }
}
```

Setelah itu, Anda tinggal menambahkan proteksi di `AppServiceProvider`:

```php
<?php

namespace App\Providers;

// baris kode lainnya

use App\Console\Commands\ClearMidtransData; // tambahkan ini

class AppServiceProvider extends ServiceProvider
{
    // baris kode lainnya

    public function boot(): void
    {
        WipeCommand::prohibit($this->app->isProduction());
        FreshCommand::prohibit($this->app->isProduction());
        ResetCommand::prohibit($this->app->isProduction());
        RefreshCommand::prohibit($this->app->isProduction());
        RollbackCommand::prohibit($this->app->isProduction());
        ClearMidtransData::prohibit($this->app->isProduction());
    }
}

```

## Simulasi Uji Coba {#simulasi-uji-coba}
Sekarang kita akan simulasi skenario run destructive command dengan konfigurasi `production`. Untuk simulasi, kita ubah terlebih dahulu file `.env`. Kita setting environment menjadi `production`.
```
APP_ENV=production
APP_DEBUG=false
```
Save kembali file `.env`.

Selanjutnya kita coba run salah satu destructive command.
```
php artisan migrate:fresh

```

Ketika command di atas kita run, tampil warning di output terminal.
```
   WARN  This command is prohibited from running in this environment.
```

Selanjutnya kita coba run perintah kostum:
```
php artisan app:clear-midtrans-data

```
Output yang ditampilkan:
```
   WARN  This command is prohibited from running in this environment.
```

## Tips Tambahan untuk Keamanan Aplikasi{#tips-tambahan-untuk-keamanan-aplikasi}
Meskipun fitur `Prohibitable` sangat membantu dalam mencegah destructive command berjalan di lingkungan produksi, ada beberapa langkah tambahan yang bisa Anda ambil untuk melindungi aplikasi Laravel Anda. Berikut adalah beberapa tips yang bisa Anda terapkan:

1. Gunakan Environment Variables dengan Bijak
Pastikan Anda menggunakan environment variables (`env`) dengan benar. Misalnya, selalu pastikan bahwa file `.env` di server produksi tidak mengandung data sensitif yang tidak perlu. Juga, jangan lupa untuk membatasi akses ke file ini agar hanya developer atau admin yang berwenang yang bisa mengaksesnya.

2. Aktifkan Maintenance Mode Saat Melakukan Pembaruan
Jika Anda sedang melakukan pembaruan besar pada aplikasi, gunakan mode maintenance Laravel untuk sementara waktu menonaktifkan akses pengguna ke aplikasi. Ini bisa dilakukan dengan menjalankan perintah:
```bash
php artisan down
```
Setelah selesai, aktifkan kembali aplikasi dengan:
```bash
php artisan up
```

3. Backup Database Secara Berkala
Tidak peduli seberapa aman Anda merasa, selalu backup database secara berkala. Laravel menyediakan cara mudah untuk melakukan backup dengan package seperti [Spatie Laravel Backup](https://github.com/spatie/laravel-backup). Dengan package ini, Anda bisa mengotomatiskan proses backup dan menyimpannya di cloud storage seperti AWS S3.

4. Batasi Akses ke Terminal Produksi
Ini mungkin terdengar sepele, tapi sering kali kesalahan fatal terjadi karena akses terminal produksi terlalu mudah didapat. Pastikan hanya orang-orang tertentu—misalnya, DevOps atau senior developer—yang memiliki akses ke server produksi. Selain itu, gunakan alat seperti SSH key-based authentication untuk memastikan bahwa hanya orang-orang yang berwenang yang bisa masuk ke server.

5. Gunakan Fitur Rollback untuk Migrasi
Laravel memiliki fitur rollback bawaan yang memungkinkan Anda "membatalkan" migrasi jika sesuatu berjalan salah. Sebelum menjalankan migrasi baru, pastikan Anda sudah siap untuk rollback jika diperlukan. Ini bisa menjadi penyelamat saat Anda menemui bug atau kesalahan dalam skrip migrasi.

## Kesimpulan{#kesimpulan}
Mencegah destructive command berjalan di Laravel adalah langkah penting dalam melindungi aplikasi Anda dari kerusakan yang tidak disengaja. Dengan fitur `Prohibitable`, Laravel memberikan solusi elegan dan efektif untuk memblokir perintah-perintah berbahaya agar tidak dieksekusi di lingkungan produksi. 

Dalam artikel **Mencegah Destructive Command Running di Laravel**, kita telah membahas bagaimana fitur ini bekerja, bagaimana Anda bisa menggunakannya untuk perintah bawaan Laravel, serta cara membuat perintah Artisan kustom yang dilengkapi dengan proteksi. Kami juga memberikan tips tambahan untuk meningkatkan keamanan aplikasi Anda secara keseluruhan.

Ingatlah, meskipun Laravel memberikan banyak fitur canggih untuk melindungi aplikasi Anda, tanggung jawab utama tetap ada di tangan Anda sebagai developer. Jadi, pastikan Anda selalu waspada, teliti, dan bijak dalam mengelola aplikasi Anda. Setelah semua, lebih baik mencegah daripada mengobati, bukan?

Semoga artikel ini bermanfaat bagi Anda. Jangan ragu untuk mencoba fitur `Prohibitable` di proyek Laravel Anda sendiri dan lihat betapa praktisnya fitur ini! Terima kasih sudah membaca, dan sampai jumpa di artikel berikutnya.