---
title: "Cara Menggunakan Composer Run Dev di Laravel 11"
slug: "cara-menggunakan-composer-run-dev-di-laravel-11"
category: "Laravel"
date: "2024-11-03"
status: "published"
---

Masih ingat saat-saat harus membuka 3-4 terminal berbeda hanya untuk menjalankan project Laravel? Saya sendiri sering mengalami situasi ini - satu terminal untuk `php artisan serve`, satu lagi untuk `npm run dev`, belum lagi kalau perlu menjalankan queue worker dan memantau log. Kadang saking banyaknya terminal yang terbuka, saya sampai bingung mana yang mana!

Kabar gembiranya, pada tanggal 16 Oktober 2024, Tim Laravel merilis versi 11.28 yang membawa angin segar bagi para developer. Salah satu fitur yang paling menarik adalah command `composer run dev` yang diintegrasikan langsung ke dalam Laravel skeleton. Fitur ini berawal dari pull request yang dibuat oleh Taylor Otwell pada 11 Oktober 2024 ([PR #6463](https://github.com/laravel/laravel/pull/6463)).

Update ini tidak hanya membawa command `composer run dev`, tetapi juga menghadirkan konfigurasi default Tailwind CSS. Artinya, Anda bisa langsung menggunakan Tailwind tanpa perlu instalasi starter kit tambahan - sebuah kemudahan yang sangat membantu terutama bagi mereka yang ingin bereksperimen dengan Tailwind tanpa setup yang rumit.

## Apa itu Composer Run Dev di Laravel?{#pengertian}
`composer run dev` adalah script baru yang diperkenalkan dalam Laravel 11.3.0. Script ini memungkinkan Anda menjalankan beberapa perintah development secara bersamaan dengan satu command sederhana.

### Perintah yang Dijalankan{#perintah}
Script ini akan mengeksekusi beberapa perintah penting secara concurrent:
- `php artisan serve` - Menjalankan development server
- `php artisan queue:listen --tries=1` - Memulai queue listener
- `php artisan pail` - Menampilkan real-time logs
- `npm run dev` - Menjalankan Vite development server

## Cara Mengimplementasikan Composer Run Dev{#implementasi}
Jika Anda menggunakan Laravel versi terbaru, script ini sudah tersedia secara default. Namun, Anda juga bisa menambahkannya secara manual di project yang sudah ada.

### Konfigurasi di composer.json{#konfigurasi}

Tambahkan kode berikut ke dalam file `composer.json` Anda:

```json
"scripts": {
    "dev": [
      "Composer\\Config::disableProcessTimeout",
      "npx concurrently -c \"#93c5fd,#c4b5fd,#fb7185,#fdba74\" \"php artisan serve\" \"php artisan queue:listen --tries=1\" \"php artisan pail\" \"npm run dev\" --names=server,queue,logs,vite"
    ]
}
```

### Mengatasi Error Saat Pertama Kali Menjalankan{#troubleshooting}

Ketika pertama kali menjalankan `composer run dev`, Anda mungkin akan menemui beberapa error seperti ini:

```bash
[queue] 
[queue]    INFO  Processing jobs from the [default] queue.  
[queue] 
[logs] 
[logs]    ERROR  Command "pail" is not defined. Did you mean one of these?  
[logs] 
[logs]   ⇂ sail:add  
[logs]   ⇂ sail:install  
[logs]   ⇂ sail:publish  
[logs] 
[logs] php artisan pail --timeout=0 exited with code 1
[vite] 
[vite] > dev
[vite] > vite
[vite] 
[vite] sh: 1: vite: not found
[vite] npm run dev exited with code 127
[server] 
[server]    INFO  Server running on [http://127.0.0.1:8000].  
```

Jangan khawatir! Error ini muncul karena ada beberapa package yang belum terinstall. Mari kita atasi satu per satu:

1. **Error Laravel Pail**
   ```bash
   composer require laravel/pail
   ```
   Package ini diperlukan untuk fitur logging real-time yang lebih baik.

2. **Error Vite Not Found**
   ```bash
   npm install
   ```
   Perintah ini akan menginstall semua dependencies JavaScript yang diperlukan, termasuk Vite.

Setelah menginstall kedua package tersebut, coba jalankan kembali `composer run dev`. Sekarang seharusnya semua service akan berjalan dengan lancar.

### Keunggulan Fitur{#keunggulan}

1. **Color-coded Output**: Setiap perintah memiliki warna berbeda, memudahkan identifikasi output dari masing-masing proses
2. **Efisiensi Waktu**: Tidak perlu menjalankan multiple terminal windows
3. **Terintegrasi**: Semua layanan development berjalan secara bersamaan
4. **Real-time Logging**: Includes Laravel Pail untuk monitoring log secara real-time

## Tentang Laravel Pail{#laravel-pail}

Laravel Pail adalah package logging terbaru yang diintegrasikan ke dalam Laravel. Package ini memberikan kemampuan monitoring log yang lebih baik dan real-time, memudahkan proses debugging aplikasi Anda.

## Tips Penggunaan{#tips}

1. Pastikan semua dependencies terinstall (`composer install` dan `npm install`)
2. Jalankan `composer run dev` di terminal
3. Tunggu hingga semua service berjalan
4. Akses aplikasi melalui URL yang ditampilkan di terminal

## Kesimpulan{#kesimpulan}

Dengan adanya `composer run dev`, Laravel semakin memudahkan workflow development para programmer. Fitur ini tidak hanya menghemat waktu tetapi juga membuat proses development menjadi lebih terorganisir dan efisien.

*Kata Kunci: Laravel 11, composer run dev, Laravel development, PHP artisan, npm run dev, Laravel Pail, development workflow, Laravel queue, concurrent commands*