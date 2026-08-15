---
title: "Cara Menggunakan Command php artisan dev di Laravel 13"
slug: "cara-menggunakan-php-artisan-dev-di-laravel-13"
original_title: "How to Use the php artisan dev Command in Laravel 13"
original_slug: "how-to-use-the-php-artisan-dev-command-in-laravel-13"
category: "Laravel"
date: "2026-08-15"
status: "draft"
---

Ada satu kebiasaan lama yang mungkin kamu kenali juga. Setiap kali mulai ngoding project Laravel, hal pertama yang saya lakukan bukan membuka teks editor, tapi membuka terminal. Lalu tab baru. Lalu tab baru lagi. Satu tab untuk `php artisan serve`, satu untuk `npm run dev`, satu untuk queue worker, dan satu lagi untuk memantau log. Empat tab, semuanya jalan, dan setengah jam kemudian saya sudah lupa tab nomor tiga itu isinya apa. Kalau ada yang error, ritualnya jadi klik satu-satu sambil menebak-nebak.

Dulu masalah ini sudah dijawab dengan `composer run dev`, yang pernah kita bahas di tutorial [Cara Menggunakan Composer Run Dev di Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11). Satu command, empat process, beres. Nah, waktu Laravel 13.16.0 rilis dan saya menulis rangkumannya di [What's New in Laravel 13.16.0](https://qadrlabs.com/post/whats-new-in-laravel-13160-artisan-dev-whenenum-and-flexible-json-schema-validation#artisan-dev-command), ada satu command baru yang bikin saya berhenti sejenak: `php artisan dev`.

Dan pertanyaan itu pun muncul. *"Lho, kalau sudah ada `composer run dev`, buat apa lagi bikin command Artisan yang kerjanya sama? Apa bedanya? Terus project lama saya kudu pindah nggak?"*

Ternyata jawabannya lumayan menarik, apalagi setelah Laravel 13.25.0 rilis beberapa hari lalu dan mengganti mesin di balik command ini. Dari rasa penasaran itu, jadilah tutorial ini.

## Overview{#overview}

Di tutorial ini kita akan membedah command `php artisan dev` di **Laravel 13** dari sisi praktisnya. Kita mulai dari bikin project Laravel 13 yang fresh, menjalankan command-nya, lalu berkenalan dengan empat process bawaan yang dia nyalakan sekaligus. Setelah itu kita utak-atik daftar process-nya lewat class `DevCommands` di `AppServiceProvider`, kita kasih warna, kita ganti port server, sampai kita saring process mana saja yang mau ikut jalan dengan `only` dan `except`.

Yang bikin seru, sejak **Laravel 13.25.0** yang rilis tanggal 11 Agustus 2026, command ini tidak lagi memakai npm package `concurrently` seperti zaman `composer run dev`. Sekarang dia pakai `@laravel/multiplex`, sebuah UI terminal beneran dengan tab per-process, fitur search, dan restart otomatis kalau ada process yang mati. Jadi kalau kamu sempat baca artikel 13.16.0 saya yang menyebut `concurrently`, bagian itu sudah ketinggalan zaman. :)

Di step terakhir kita juga akan bahas cara pindah dari `composer run dev` ke `php artisan dev`, khusus buat teman-teman yang project-nya masih di Laravel 11 atau 12.

Semua output terminal di tutorial ini saya ambil apa adanya dari hasil uji coba langsung, jadi kamu bisa membandingkan dengan hasil di mesinmu sendiri. Lalu, apa saja langkahnya? *Check this out, ya!*

**Daftar Isi**
- [Overview](#overview)
- [Step 1 - Persiapan Development](#step-1-persiapan-development)
- [Step 2 - Menjalankan php artisan dev untuk Pertama Kali](#step-2-menjalankan-artisan-dev)
- [Step 3 - Kustomisasi Process dengan DevCommands](#step-3-kustomisasi-devcommands)
- [Step 4 - Filter Process dengan only dan except](#step-4-filter-process)
- [Step 5 - Migrasi dari composer run dev ke php artisan dev](#step-5-migrasi)
- [Step 6 - Uji Coba](#step-6-uji-coba)
- [Penutup](#penutup)
- [Referensi](#referensi)

## Step 1 - Persiapan Development {#step-1-persiapan-development}

Sebelum mulai, alangkah baiknya kita berdoa dulu supaya codingnya lancar. :)

Sudah?

Oke, sekarang kita cek dulu peralatan yang dipakai. Spesifikasi mesin saya saat tutorial ini ditulis adalah sebagai berikut:

1. PHP 8.5.6
2. Node v22.15.1
3. npm 10.9.2
4. Composer 2.10.0
5. Laravel Installer 5.31.0
6. macOS

Ada satu syarat yang penting banget dan tidak boleh kamu lewatkan: **`php artisan dev` butuh Node versi 22.13 ke atas** untuk bisa menampilkan UI tab-nya. Kalau Node kamu di bawah itu, atau kamu pakai Windows, Laravel akan otomatis jatuh (*fallback*) ke package `concurrently` yang lama dan tampilan tab-nya tidak muncul. Fungsinya tetap jalan kok, cuma tampilannya saja yang lebih sederhana. Jadi sebelum lanjut, coba cek dulu:

```bash
node -v
```

Kalau Node-mu sudah aman, yuk kita bikin project barunya. Masuk ke folder kerja kamu, lalu ketik:

```bash
laravel new dev-command-demo
```

Kalau kamu lebih suka pakai Composer langsung, boleh juga:

```bash
composer create-project laravel/laravel dev-command-demo
```

Command di atas akan mengunduh dan menyiapkan project Laravel yang fresh dengan nama folder `dev-command-demo`. Kalau Laravel Installer bertanya soal starter kit atau testing framework, pilih saja yang paling sederhana, karena di tutorial ini kita memang fokus ke command `dev`-nya, bukan ke fiturnya.

Setelah itu masuk ke folder project dan install dependency JavaScript-nya:

```bash
cd dev-command-demo
npm install
```

Langkah `npm install` ini wajib, ya. Soalnya package `@laravel/multiplex` yang jadi mesin tampilan `php artisan dev` diinstall dari sini. Kalau dilewat, process `vite` bakal error dan UI tab-nya tidak akan muncul.

Sekarang kita pastikan dulu versi Laravel-nya sudah benar:

```bash
php artisan --version
```

Di mesin saya hasilnya seperti ini:

```
Laravel Framework 13.25.0
```

Pastikan versimu **13.25.0 atau lebih baru**, ya. Kenapa? Karena UI tab dari `@laravel/multiplex` baru masuk di versi ini. Kalau kamu masih di rentang 13.16 sampai 13.24, command `php artisan dev` tetap ada dan tetap bisa dipakai, tapi mesinnya masih `concurrently` dan tampilannya beda dengan screenshot di tutorial ini.

Kita juga bisa mengintip isi `package.json` untuk melihat sendiri package apa yang dipasang Laravel:

```json
"devDependencies": {
    "@tailwindcss/vite": "^4.0.0",
    "concurrently": "^10.0.3",
    "laravel-vite-plugin": "^3.1",
    "tailwindcss": "^4.0.0",
    "vite": "^8.0.0"
},
"optionalDependencies": {
    "@laravel/multiplex": "^0.4.1"
}
```

Menarik, kan? `@laravel/multiplex` didaftarkan sebagai `optionalDependencies`, bukan dependency wajib. Artinya kalau instalasinya gagal di mesin kamu (misalnya karena Node-nya terlalu tua), `npm install` tidak ikut gagal. Dan `concurrently` masih nangkring di `devDependencies` justru karena dia yang jadi cadangan saat multiplex tidak bisa dipakai. Jadi Laravel sudah menyiapkan rencana B sejak awal. :D

## Step 2 - Menjalankan php artisan dev untuk Pertama Kali {#step-2-menjalankan-artisan-dev}

Persiapan sudah beres, sekarang bagian yang paling ditunggu. Kita jalankan command-nya dan lihat apa yang terjadi. Ketik perintah ini di terminal:

```bash
php artisan dev
```

Cuma segitu. Tidak ada konfigurasi, tidak ada flag, tidak ada yang perlu disiapkan lagi. Dari satu command ini Laravel akan menyalakan empat process sekaligus di satu jendela terminal.

Nah, sebelum lihat hasilnya, kita kenalan dulu dengan siapa saja yang dinyalakan. Empat process bawaannya begini:

| Nama | Command |
| --- | --- |
| `server` | `php artisan serve` |
| `queue` | `php artisan queue:listen --tries=1 --timeout=0` |
| `logs` | `php artisan pail --timeout=0` |
| `vite` | `npm run dev` |

Daftar ini saya ambil langsung dari source code framework di `vendor/laravel/framework/src/Illuminate/Foundation/DevCommands.php`, tepatnya di method `registerDefaults()`. Kenapa saya sebutkan? Karena dokumentasi resminya masih menulis process `server` sebagai `php artisan serve --host=localhost`, padahal di 13.25.0 yang benar-benar terdaftar cuma `php artisan serve` tanpa opsi `--host`. Kalau ada beda antara dokumentasi dan source code, percaya saja pada source code-nya. :)

Ada satu detail lagi yang jarang disebut. Process `logs` cuma didaftarkan **kalau fungsi `pcntl_fork()` tersedia** di instalasi PHP kamu. Ekstensi `pcntl` ini biasanya tidak aktif di Windows, jadi jangan kaget kalau di sana process `logs` tidak ikut muncul dan yang jalan cuma tiga. Bukan bug, memang begitu desainnya.

Sekarang, hasil uji coba di mesin saya. Ini output aslinya:

```
  vite │ 
  vite │ > dev
  vite │ > vite
  vite │ 
 queue │ 
 queue │  INFO Processing jobs from the [default] queue. 
 queue │ 
  logs │ 
  logs │  INFO Tailing application logs. Press Ctrl+C to exit 
  logs │  Use -v|-vv to show more details 
server │ 
server │  INFO Server running on [http://127.0.0.1:8000]. 
server │ 
server │  Press Ctrl+C to stop the server
server │ 
  vite │ 
  vite │   VITE v8.2.1  ready in 2031 ms
  vite │ 
  vite │   ➜  Local:   http://localhost:5173/
  vite │   ➜  Network: use --host to expose
  vite │ 
  vite │   LARAVEL v13.25.0  plugin v3.2.0
  vite │ 
  vite │   ➜  APP_URL: http://localhost:8000
  vite │ [laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
```

Perhatikan bagian paling kiri. Setiap baris output diberi label nama process-nya, jadi kamu langsung tahu pesan itu datang dari mana. Server jalan di `http://127.0.0.1:8000`, Vite di `http://localhost:5173`, queue worker sudah siap menunggu job, dan Pail sudah mulai memantau log. Semuanya dari satu terminal. *yeay!*

**Catatan:** output di atas itu tampilan **inline mode**, yaitu mode yang otomatis dipakai kalau output-nya dialihkan ke file atau dijalankan di CI. Saya sengaja pakai mode ini supaya teksnya bisa saya salin utuh ke artikel. Kalau kamu menjalankannya langsung di terminal biasa, yang muncul bukan teks berjejer seperti ini, melainkan UI tab yang jauh lebih rapi.

\* \* \*

Nah, soal UI tab itu. Inilah yang baru di Laravel 13.25.0. Setiap process punya tab sendiri di sidebar, output-nya bisa di-scroll dan di-search, dan kamu bisa me-restart satu process tanpa mengganggu yang lain. Kalau kamu keluar dari command-nya, seluruh output tetap ditulis balik ke scrollback terminal, jadi log-nya tidak hilang begitu saja.

Ini beberapa tombol yang paling sering saya pakai:

| Tombol | Fungsi |
| --- | --- |
| `1` sampai `9` | Loncat ke tab sesuai nomornya |
| `Up` / `Down` atau `j` / `k` | Pindah tab, atau scroll isi tab |
| `g` / `G` | Loncat ke paling atas / paling bawah |
| `r` | Restart process yang sedang dipilih |
| `c` | Bersihkan output tab yang sedang aktif |
| `/` | Buka pencarian |
| `s` | Pindah ke stream mode (semua output jadi satu aliran) |
| `t` | Balik lagi ke tabbed mode |
| `q` | Keluar |

Daftar tombol ini saya ambil dari README package `@laravel/multiplex` versi 0.4.2 yang terpasang di `node_modules`, jadi sudah sesuai dengan yang benar-benar jalan di project ini.

Tombol `r` itu penyelamat banget, ngomong-ngomong. Dulu kalau Vite ngambek, saya harus matikan semuanya lalu jalankan ulang dari awal. Sekarang tinggal pilih tab `vite`, tekan `r`, dan process itu saja yang lahir kembali. :)

Oh iya, kalau ada process yang crash, Laravel akan me-restart-nya otomatis setelah jeda sebentar. Kalau kamu lagi tidak ingin perilaku itu, misalnya karena sedang men-debug kenapa sebuah process mati, matikan saja dengan flag berikut:

```bash
php artisan dev --no-restart
```

## Step 3 - Kustomisasi Process dengan DevCommands {#step-3-kustomisasi-devcommands}

Sampai sini `php artisan dev` memang belum terasa jauh berbeda dari `composer run dev`. Sama-sama menyalakan empat process, kan? Nah, bedanya baru kelihatan begitu kita mau menambah process sendiri.

Zaman `composer run dev`, menambah process artinya menyunting satu baris string panjang di dalam `composer.json`. Tidak ada autocomplete, tidak ada pengecekan dari static analysis, dan salah satu tanda kutip saja bisa bikin seluruh script rusak. Sekarang daftarnya kita susun dari PHP, di tempat yang wajar, yaitu service provider.

Yuk kita coba. Buka file `app/Providers/AppServiceProvider.php` dengan teks editor kesayanganmu, lalu ubah isinya jadi seperti ini. *Type this syntax ya!*

```php
<?php

namespace App\Providers;

use Illuminate\Foundation\DevCommands;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        DevCommands::artisan('serve --host=localhost --port=9000', 'server');

        DevCommands::artisan('schedule:work', 'scheduler')->orange();

        DevCommands::nodeExec(
            'tailwindcss -i resources/css/app.css -o public/css/app.css --watch',
            'tailwind'
        )->green();

        DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');
    }
}
```

Jangan lupa simpan filenya dengan menekan `ctrl+s`.

Sekarang kita bedah satu per satu, karena ada empat cara mendaftar yang berbeda di situ dan masing-masing punya kegunaannya sendiri.

**`DevCommands::artisan()`** otomatis menambahkan awalan `php artisan` di depan command yang kamu tulis. Makanya untuk menjalankan scheduler kita cukup menulis `schedule:work`, tidak perlu `php artisan schedule:work`. Baris pertama juga memakai method ini, tapi ada trik di sana yang akan kita bahas sebentar lagi.

**`DevCommands::nodeExec()`** menambahkan awalan command *exec* dari package manager yang terdeteksi, jadi biasanya `npx`. Pasangannya adalah **`DevCommands::node()`** yang menambahkan awalan command *run*, jadi `npm run`. Contohnya `DevCommands::node('storybook', 'storybook')` akan jalan sebagai `npm run storybook`. Ini juga yang dipakai Laravel untuk mendaftarkan process `vite` bawaan tadi.

**`DevCommands::register()`** tidak menambahkan awalan apa pun. Command-nya dijalankan mentah-mentah seperti kamu mengetiknya sendiri di terminal. Ini pilihan yang tepat untuk hal-hal di luar ekosistem Laravel dan Node, misalnya menjalankan `stripe listen` untuk memantau webhook, atau seperti contoh kita, sekadar `tail -f` ke file log.

Argumen kedua di setiap method itu adalah **nama process**, yang nantinya jadi label di tab terminal. Nama ini sebenarnya opsional, dan kalau dikosongkan Laravel akan menebak dari kata pertama command kamu. Tapi saran saya, tulis saja namanya secara eksplisit. Selain lebih jelas dibaca, kamu juga terhindar dari tabrakan nama kalau ada dua command yang kata pertamanya kebetulan sama.

\* \* \*

Soal warna, kamu lihat ada `->orange()` dan `->green()` di kode tadi. Method warna yang tersedia ada enam, yaitu `blue()`, `purple()`, `pink()`, `orange()`, `green()`, dan `yellow()`. Kalau enam warna itu kurang cocok dengan selera atau tema terminalmu, pakai `->color()` dan masukkan nilai hex enam digit seperti pada process `tail` di atas. Perlu dicatat, hex-nya harus enam digit penuh, ya. Penulisan singkat seperti `#fff` akan ditolak.

Sekarang bagian yang paling saya suka. Coba perhatikan lagi baris pertama:

```php
DevCommands::artisan('serve --host=localhost --port=9000', 'server');
```

Kita mendaftarkan process dengan nama `server`, padahal Laravel sudah punya process bawaan dengan nama yang persis sama. Apa yang terjadi? Apakah jadi dobel dan port-nya rebutan?

Tidak. Kalau kamu mendaftarkan process dengan nama yang sama dengan process bawaan, punyamu akan **menggantikan** yang bawaan. Jadi inilah cara resmi untuk mengubah port development server tanpa perlu menyentuh apa pun selain baris ini. Rapi, kan? :D

Untuk membuktikan semuanya benar-benar terdaftar, kita tidak perlu menjalankan process-nya. Ada command khusus buat mengintip daftarnya:

```bash
php artisan dev:list
```

Dan ini output aslinya di mesin saya:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tailwind npx tailwindcss -i resources/css/app.css -o public/css/app.css --watch .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 queue php artisan queue:listen --tries=1 --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [7] dev commands
```

Coba kita baca bareng-bareng, karena output ini bercerita banyak.

Pertama, jumlahnya **7**, bukan 8. Padahal kita menambah empat process ke empat process bawaan. Ini bukti kalau `server` milik kita benar-benar menggantikan `server` bawaan, bukan menambahinya. Dan lihat baris `server` paling atas, command-nya sudah pakai port 9000 punya kita.

Kedua, kolom paling kanan menunjukkan **dari mana** setiap process didaftarkan. Punya kita tertulis `App\Providers\AppServiceProvider@boot`, sementara yang bawaan tertulis `Illuminate\Foundation\Providers\ArtisanServiceProvider@boot`. Kalau suatu saat ada process aneh nongol di daftarmu, kolom ini yang akan memberitahu siapa pelakunya.

Ketiga, urutannya tidak acak. Process yang kamu daftarkan sendiri selalu naik ke atas, di atas process bawaan Laravel.

Keempat, `nodeExec` tadi benar-benar diterjemahkan jadi `npx tailwindcss ...`. Cocok seperti yang kita harapkan. Dan process `vite` bawaan tetap `npm run dev` karena project ini memang pakai npm. Kalau di project kamu ada file `bun.lock`, `pnpm-lock.yaml`, atau `yarn.lock`, Laravel akan mendeteksinya sendiri dan menyesuaikan command-nya tanpa perlu kamu atur. Buat yang penasaran soal Bun, kita pernah bahas di tutorial [Cara Menggunakan Bun di Laravel](https://qadrlabs.com/post/cara-menggunakan-bun-di-laravel-package-manager-alternatif-npm).

## Step 4 - Filter Process dengan only dan except {#step-4-filter-process}

Ada hari-hari di mana kita tidak butuh semuanya jalan. Misalnya hari ini kamu cuma mau merapikan tampilan halaman depan. Yang kamu perlukan cuma server dan Vite. Queue worker dan log tailing? Cuma bikin terminal ramai dan kipas laptop berisik.

Untuk itu ada dua method yang sangat gampang dipakai, yaitu `only()` dan `except()`. Tambahkan salah satunya di `boot()`, setelah semua pendaftaran process tadi:

```php
DevCommands::except('queue', 'logs');
```

Method `except()` menjalankan semua process **kecuali** yang namanya kamu sebutkan. Simpan filenya, lalu kita cek lagi daftarnya:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tailwind npx tailwindcss -i resources/css/app.css -o public/css/app.css --watch .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

Dari 7 tinggal 5. Process `queue` dan `logs` betul-betul hilang dari daftar. :)

Sekarang kita coba yang sebaliknya. Ganti baris tadi jadi seperti ini:

```php
DevCommands::only('server', 'vite');
```

Kalau `except()` bekerja dengan cara mencoret, `only()` bekerja dengan cara memilih. Yang jalan **hanya** process yang namanya kamu sebutkan, sisanya diabaikan semua. Hasilnya:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [2] dev commands
```

Dua process saja, persis seperti yang kita minta. Perhatikan juga bahwa `only()` tidak pandang bulu. Process `scheduler`, `tailwind`, dan `tail` yang kita daftarkan sendiri pun ikut tersaring keluar karena namanya tidak masuk daftar.

Karena filter ini ditulis di PHP, kamu bisa membungkusnya dengan logika. Contohnya, mesin yang berat bisa menjalankan versi ringan lewat variabel di file `.env` masing-masing:

```php
if (env('DEV_LIGHT_MODE', false)) {
    DevCommands::only('server', 'vite');
}
```

Ini salah satu hal yang dulu praktis mustahil dilakukan dengan script di `composer.json`, karena isinya cuma string mati tanpa kemampuan mengambil keputusan.

## Step 5 - Migrasi dari composer run dev ke php artisan dev {#step-5-migrasi}

Oke, sekarang bagian buat teman-teman yang project-nya masih di Laravel 11 atau 12 dan sudah terlanjur nyaman dengan `composer run dev`. Pertanyaannya sederhana: perlu pindah tidak, dan kalau pindah gimana caranya?

Jawaban singkatnya, `php artisan dev` baru tersedia mulai Laravel 13.16.0. Jadi selama project kamu masih di 11 atau 12, `composer run dev` tetap jadi pilihan yang benar dan tidak ada yang salah dengan itu. Kalau kamu memang berencana upgrade, ada panduannya di tutorial [How to Upgrade Laravel 12 to Laravel 13](https://qadrlabs.com/post/how-to-upgrade-laravel-12-to-laravel-13-a-step-by-step-guide).

Sebagai gambaran, ini perbandingan keduanya:

| Aspek | `composer run dev` | `php artisan dev` |
| --- | --- | --- |
| Tempat mendaftar process | String di `composer.json` | Kode PHP di service provider |
| Autocomplete dan static analysis | Tidak ada | Ada |
| Mesin penggerak | `concurrently` | `@laravel/multiplex` (sejak 13.25.0) |
| Tampilan output | Baris berlabel warna | Tab per-process, bisa scroll dan search |
| Restart satu process saja | Tidak bisa | Bisa, tekan `r` |
| Restart otomatis saat crash | Tidak ada | Ada |
| Filter process per-mesin | Praktis tidak bisa | Bisa, lewat `only()` dan `except()` |
| Syarat Node | Bebas | 22.13 ke atas untuk UI tab |

Nah, sekarang bagian yang mungkin bikin kamu lega. Setelah upgrade ke Laravel 13, **kamu sebenarnya tidak wajib mengubah kebiasaan apa pun**. Coba intip `composer.json` di project Laravel 13 yang fresh:

```json
"scripts": {
    "dev": [
        "Composer\\Config::disableProcessTimeout",
        "@php artisan dev"
    ]
}
```

Iya, kamu benar. Script `dev`-nya masih ada, tapi isinya sekarang cuma meneruskan ke `@php artisan dev`. Jadi kalau jari kamu sudah hafal mengetik `composer run dev`, silakan lanjut saja, hasilnya sama persis. Laravel sengaja menyiapkan jembatan ini supaya tidak ada yang perlu diubah paksa.

Yang perlu kamu lakukan cuma satu hal: **hapus kustomisasi lama** di `composer.json`. Kalau selama ini kamu punya blok panjang seperti ini dari zaman Laravel 11:

```json
"scripts": {
    "dev": [
      "Composer\\Config::disableProcessTimeout",
      "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail\" \"npm run dev\" --names=server,queue,logs,vite"
    ]
}
```

Blok itu sekarang bisa diganti dengan versi ringkas yang cuma memanggil `@php artisan dev`. Karena kalau kamu biarkan, project kamu tetap memanggil `concurrently` secara langsung dan kamu tidak akan pernah mendapat UI tab-nya.

Terus kustomisasi yang tadinya ada di string itu pindah ke mana? Ke `AppServiceProvider`, dengan padanan seperti ini:

| Di `composer.json` (cara lama) | Di `AppServiceProvider` (cara baru) |
| --- | --- |
| Satu string command di dalam `concurrently` | Satu panggilan `DevCommands::register()` atau `::artisan()` |
| Opsi `--names=server,queue,logs,vite` | Argumen kedua di tiap pendaftaran |
| Opsi `-c "#93c5fd,#c4b5fd,..."` | Method warna seperti `->orange()` atau `->color('#93c5fd')` |
| Menghapus satu command dari string | `DevCommands::except('nama')` |

Jadi misalnya dulu kamu menambahkan Reverb ke dalam string `concurrently`, sekarang cukup satu baris:

```php
DevCommands::artisan('reverb:start', 'reverb')->purple();
```

Jauh lebih enak dibaca daripada menyelipkan tanda kutip di tengah-tengah string JSON yang sudah penuh sesak. :D

## Step 6 - Uji Coba {#step-6-uji-coba}

Waktunya membuktikan semuanya jalan. Kita rapikan dulu `AppServiceProvider`, kali ini dengan konfigurasi yang lebih realistis. Kita pakai server di port 9000, tambahkan scheduler dan tail log, lalu buang queue worker karena di percobaan ini kita tidak punya job apa pun untuk diproses.

```php
public function boot(): void
{
    DevCommands::artisan('serve --host=localhost --port=9000', 'server');

    DevCommands::artisan('schedule:work', 'scheduler')->orange();

    DevCommands::register('tail -f storage/logs/laravel.log', 'tail')->color('#ff6347');

    DevCommands::except('queue');
}
```

Simpan filenya, lalu kita pastikan dulu daftarnya sudah sesuai harapan sebelum benar-benar dijalankan:

```bash
php artisan dev:list
```

Hasilnya:

```
 server php artisan serve --host=localhost --port=9000 .. App\Providers\AppServiceProvider@boot
 scheduler php artisan schedule:work .. App\Providers\AppServiceProvider@boot
 tail tail -f storage/logs/laravel.log .. App\Providers\AppServiceProvider@boot
 logs php artisan pail --timeout=0 .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot
 vite npm run dev .. Illuminate\Foundation\Providers\ArtisanServiceProvider@boot

 Showing [5] dev commands
```

Lima process, `queue` sudah tidak ada, dan `server` sudah pakai port 9000. Sesuai pesanan. Sekarang jalankan:

```bash
php artisan dev
```

Dan ini output aslinya:

```
     vite │ 
     vite │ > dev
     vite │ > vite
     vite │ 
scheduler │ 
scheduler │  INFO Running scheduled tasks. 
scheduler │ 
     logs │ 
     logs │  INFO Tailing application logs. Press Ctrl+C to exit 
     logs │  Use -v|-vv to show more details 
     vite │ 
     vite │   VITE v8.2.1  ready in 226 ms
     vite │ 
     vite │   ➜  Local:   http://localhost:5173/
     vite │   ➜  Network: use --host to expose
     vite │ [laravel:fonts] Optimized font fallbacks require the optional "fontaine" package. Install it, or set "optimizedFallbacks: false" on your fonts to disable the feature.
     vite │ 
     vite │   LARAVEL v13.25.0  plugin v3.2.0
     vite │ 
     vite │   ➜  APP_URL: http://localhost:8000
   server │ 
   server │  INFO Server running on [http://localhost:9000]. 
   server │ 
   server │  Press Ctrl+C to stop the server
   server │ 
   server │  2026-08-15 19:45:41 / .. ~ 505.59ms
```

Coba perhatikan baris `server`. Dia jalan di `http://localhost:9000`, bukan di port 8000 seperti bawaannya. Berarti penggantian process yang kita lakukan di Step 3 benar-benar bekerja. Process `scheduler` juga sudah melapor `Running scheduled tasks.`, dan tidak ada satu pun baris berlabel `queue` di sana karena sudah kita saring dengan `except()`.

Baris paling bawah itu bonus. `2026-08-15 19:45:41 / .. ~ 505.59ms` adalah catatan request yang masuk saat saya membuka `http://localhost:9000` di browser, dan servernya membalas dengan status 200. Halaman welcome Laravel muncul dengan normal.

*Tadaaa!!!* Lima process jalan bareng dari satu terminal, dengan port dan warna sesuai keinginan kita, tanpa perlu membuka lima tab terminal. :D

Kalau kamu menjalankan ini langsung di terminal (bukan dialihkan ke file seperti yang saya lakukan untuk menyalin teksnya), yang muncul adalah UI tab-nya. Coba tekan `2` untuk loncat ke tab `scheduler`, tekan `/` untuk mencari sesuatu di dalam log, atau tekan `r` untuk me-restart process yang sedang kamu pilih. Setelah puas, tekan `q` untuk keluar dan semua process akan berhenti bersamaan.

## Penutup{#penutup}

Sampai juga kita di ujung tutorial. Sepanjang perjalanan tadi kita sudah berkenalan dengan `php artisan dev` di Laravel 13, mulai dari menjalankannya polos tanpa konfigurasi apa pun, mengenali empat process bawaan beserta keanehan kecilnya seperti process `logs` yang bergantung pada `pcntl_fork`, sampai menyusun daftar process kita sendiri lewat `DevCommands` di `AppServiceProvider`. Kita juga sempat mengganti port server dengan cara mendaftarkan ulang nama process yang sama, memberi warna pada tiap label, menyaring process dengan `only()` dan `except()`, dan menutupnya dengan panduan pindah dari `composer run dev`.

Kalau boleh saya rangkum dalam satu kalimat, bedanya `php artisan dev` dengan pendahulunya bukan pada apa yang dia jalankan, tapi pada di mana daftarnya kamu tulis. Begitu daftar itu pindah dari string JSON ke kode PHP, tiba-tiba semuanya jadi mungkin: autocomplete, percabangan logika, filter per-mesin, dan warna yang bisa kamu atur satu-satu.

Project yang kita buat di sini tentu masih sangat sederhana. Kita cuma menjalankan scheduler dan `tail` sebagai contoh, padahal di project sungguhan justru di situlah command ini bersinar. Coba deh daftarkan hal-hal yang selama ini bikin kamu buka terminal tambahan. Reverb untuk websocket dengan `DevCommands::artisan('reverb:start', 'reverb')`, Horizon untuk memantau queue, listener webhook Stripe lewat `DevCommands::register()`, atau bahkan Storybook dengan `DevCommands::node()`. Semakin banyak process yang bisa kamu satukan, semakin terasa manfaatnya.

Ada beberapa hal yang sengaja tidak kita bahas mendalam di sini supaya tutorialnya tetap fokus, misalnya pengaturan ukuran buffer output, mode `stream` dan `inline` yang bisa dijadikan default lewat `DevCommands::stream()`, atau opsi `--timestamps` dan `--json`. Kalau kamu penasaran, coba jalankan `php artisan help dev` dan lihat sendiri opsi apa saja yang tersedia. Siapa tahu ada yang pas dengan kebutuhanmu.

Kalau kamu belum sempat mengikuti dari awal, tutorial [Cara Menggunakan Composer Run Dev di Laravel 11](https://qadrlabs.com/post/cara-menggunakan-composer-run-dev-di-laravel-11) bisa jadi bacaan pembanding yang bagus, dan rangkuman [What's New in Laravel 13.16.0](https://qadrlabs.com/post/whats-new-in-laravel-13160-artisan-dev-whenenum-and-flexible-json-schema-validation#artisan-dev-command) memuat fitur-fitur lain yang rilis bareng command ini.

Kalau ada bagian yang belum jelas atau hasil di mesinmu berbeda, jangan sungkan tulis di kolom komentar ya. Terutama buat pengguna Windows, saya penasaran seperti apa tampilan fallback `concurrently`-nya di sana.

Semangat terus ya! Selamat belajar.. Semoga menyenangkan.. :D

## Referensi:{#referensi}

- [Laravel Documentation: The Dev Command](https://laravel.com/docs/13.x/artisan#the-dev-command)
- [Laravel Documentation: Customizing Dev Processes](https://laravel.com/docs/13.x/artisan#customizing-dev-processes)
- [Laravel Documentation: Filtering Dev Processes](https://laravel.com/docs/13.x/artisan#filtering-dev-processes)
- [Laravel Documentation: Tailing Log Messages Using Pail](https://laravel.com/docs/13.x/logging#tailing-log-messages-using-pail)
- [laravel/multiplex on GitHub](https://github.com/laravel/multiplex)
- [Laravel News: Pause All Queues and a New artisan dev UI in Laravel 13.25](https://laravel-news.com/laravel-13-25-0)
