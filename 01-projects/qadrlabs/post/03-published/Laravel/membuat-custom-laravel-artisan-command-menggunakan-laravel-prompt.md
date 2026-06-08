---
title: "Membuat Custom Laravel Artisan Command menggunakan Laravel Prompt"
slug: "membuat-custom-laravel-artisan-command-menggunakan-laravel-prompt"
category: "Laravel"
date: "2023-08-15"
status: "published"
---

Sebagai developer Laravel yang aktif menangani berbagai proyek web, saya sering menghadapi tantangan untuk mengotomatisasi tugas-tugas berulang. Suatu hari, ketika sedang mengembangkan sistem manajemen konten untuk klien enterprise, saya menemukan bottleneck yang signifikan dalam proses deployment dan konfigurasi sistem. Tim kami membutuhkan cara yang lebih efisien untuk mengelola command-line operations.

Laravel, dengan Artisan Command-nya yang powerful, sebenarnya sudah menyediakan solusi untuk masalah ini. Namun, pengalaman berinteraksi dengan CLI traditional terkadang kurang intuitif bagi anggota tim yang baru. Momentum perubahan datang saat Laravel mengumumkan peluncuran Laravel Prompt di Laracon US pada 19 Juli 2023 - sebuah package yang mengubah cara kita berinteraksi dengan command line.

Dalam tutorial mendalam ini, saya akan membagikan pengalaman dan panduan langkah demi langkah dalam mengimplementasikan custom command menggunakan Laravel Prompt. Anda akan mempelajari bagaimana mengubah command line biasa menjadi interface yang interaktif dan user-friendly, meningkatkan produktivitas tim development secara signifikan.

## Apa itu Laravel Prompt{#apa-itu-laravel-prompt}

Laravel Prompts adalah inovasi terbaru dalam ekosistem Laravel yang mentransformasi pengalaman command line interface (CLI) menjadi lebih interaktif dan user-friendly. [Package resmi Laravel](https://laravel.com/docs/11.x/prompts) ini membawa pengalaman form berbasis browser ke dalam terminal Anda, lengkap dengan fitur placeholder text, validasi real-time, dan interface yang intuitif.

### Keunggulan Laravel Prompts

- **Interface yang Modern**: Menghadirkan tampilan CLI yang elegan dan mudah dipahami
- **Validasi Real-time**: Memastikan input pengguna sesuai dengan kriteria yang dibutuhkan
- **Cross-platform Compatibility**: Bekerja sempurna di berbagai sistem operasi
- **Fleksibilitas Tinggi**: Dapat diintegrasikan dengan berbagai proyek PHP berbasis CLI

### Contoh Implementasi Praktis

Mari kita lihat bagaimana Laravel Prompts bekerja dalam contoh pembuatan controller. Ketika Anda menjalankan perintah:

```
php artisan make:controller

 ┌ What should the controller be named? ────────────────────────┐
 │ E.g. UserController                                          │
 └──────────────────────────────────────────────────────────────┘
```

Setelah memasukkan nama "UserController", interface akan menampilkan opsi tipe controller:

```
php artisan make:controller

 ┌ What should the controller be named? ────────────────────────┐
 │ UserController                                               │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which type of controller would you like? ────────────────────┐
 │ › ● Empty                                                    │
 │   ○ Resource                                                 │
 │   ○ Singleton                                                │
 │   ○ API                                                      │
 │   ○ Invokable                                                │
 └──────────────────────────────────────────────────────────────┘
```

Setelah memilih tipe controller, Anda dapat menentukan model yang akan digunakan:

```
php artisan make:controller

 ┌ What should the controller be named? ────────────────────────┐
 │ UserController                                               │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which type of controller would you like? ────────────────────┐
 │ Resource                                                     │
 └──────────────────────────────────────────────────────────────┘

 ┌ What model should this resource controller be for? (Optional) ┐
 │ User                                                          │
 └───────────────────────────────────────────────────────────────┘

   INFO  Controller [app/Http/Controllers/UserController.php] created successfully.  
```

## Overview{#overview}
Pada tutorial kali ini kita akan membuat custom artisan command laravel untuk menambahkan user baru, yaitu `make:user`. Ketika command ini kita run, nanti kita akan diminta untuk memasukan nama, email dan password. Setelah kita input name, email dan password, user baru akan ditambahkan ke database.

## Step 1 - Buat Project Baru{#step-1}
Sekarang kita buat project baru menggunakan `composer`. Buka terminal lalu run command di bawah ini.

```bash
composer create-project laravel/laravel:^10.0 custom_command_laravel
```

## Step 2 - Set Konfigurasi Database{#step-2}
Setelah project baru berhasil kita buat di langkah sebelumnya, sekarang kita atur konfigurasi database. Buka file `.env` di text editor, lalu sesuaikan *credentials* mysql dan database yang akan kita gunakan untuk project kali ini.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_custom_command
DB_USERNAME=admin
DB_PASSWORD=password
```

Selanjutnya jangan lupa buat database baru dengan nama `db_custom_command` (atau sesuai dengan nama database yang kamu atur di file `.env`).

Setelah database kita buat, selanjutnya kita run migration file yang sudah tersedia secara default menggunakan command di bawah ini.
```bash
php artisan migrate
```

## Step 3 - Install Laravel Prompt{#step-3}
Langkah selanjutnya adalah install package laravel prompt melalui composer. 
```
composer require laravel/prompts
```

Tunggu sampai proses install melalui composer selesai. Setelah

## Step 4 - Buat Command baru `make:user`{#step-4}
Sekarang kita generate command baru melalui `artisan` command di bawah ini.
```bash
php artisan make:command MakeUser
```

Output ketika command di atas kita run.
```bash
$ php artisan make:command MakeUser

   INFO  Console command [app/Console/Commands/MakeUser.php] created successfully.  

```

Selanjutnya kita buka file `app/Console/Commands/MakeUser.php` dan kita sesuaikan dengan baris kode berikut ini.

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;


use App\Models\User;
use function Laravel\Prompts\text;
use Illuminate\Support\Facades\Hash;


class MakeUser extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'make:user {name?} {email?} {password?}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Create user for application';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $name = $this->argument('name') ?: text('What is your name?');
        $email = $this->argument('email') ?: text('What is your email?');
        $password = $this->argument('password')?: text('What is your password?');

        $user = User::create([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password)
        ]);

        $this->info("User {$user->name} created successfully");
    }
}

```

**Penjelasan Kode**:

1. `use Illuminate\Console\Command;`: Baris kode ini digunakan untuk mengimpor kelas Command dari namespace Illuminate\Console. Kelas Command digunakan sebagai dasar untuk membuat perintah dalam Laravel.

2. `use App\Models\User;`: Baris kode ini digunakan untuk mengimpor kelas User dari namespace App\Models. Kelas User mewakili model pengguna dalam aplikasi Laravel.

3. `use function Laravel\Prompts\text;`: Baris kode ini digunakan untuk mengimpor fungsi `text()` dari namespace Laravel\Prompts. Fungsi ini digunakan untuk meminta input teks dari pengguna melalui terminal.

4. `use Illuminate\Support\Facades\Hash;`: Ini mengimpor kelas Hash dari namespace Illuminate\Support\Facades. Kelas Hash digunakan untuk mengenkripsi kata sandi.

5. `class MakeUser extends Command`: Ini mendefinisikan kelas `MakeUser` yang mengextend kelas `Command`, artinya kelas ini adalah turunan dari kelas `Command`.

6. `$signature = 'make:user {name?} {email?} {password?}';`: Ini mendefinisikan tanda tangan perintah. Ketika kita menjalankan perintah ini dari terminal, kita dapat memberikan tiga argumen opsional: nama, email, dan password.

7. `$description = 'Create user for application';`: Ini mendefinisikan deskripsi dari perintah, yang akan muncul saat kita menjalankan perintah `php artisan list`.

8. `public function handle()`: Ini mendefinisikan metode `handle()` yang akan dijalankan ketika perintah ini dipanggil.

9. Di dalam metode `handle()`, kode mengambil input dari pengguna menggunakan `text()` untuk nama, email, dan password. Jika argumen tidak diberikan, pengguna akan diminta untuk memasukkan nilai melalui terminal.

10. Selanjutnya, kelas `User` digunakan untuk membuat pengguna baru dengan menggunakan nilai-nilai yang diambil dari input pengguna. Kata sandi juga di-hash menggunakan kelas `Hash` sebelum disimpan dalam basis data.

11. `$this->info("User {$user->name} created successfully");`: Ini menampilkan pesan notifikasi di terminal setelah pengguna berhasil dibuat.


## Step 5 - Uji Coba{#step-5}
Sekarang kita coba run custom command yang baru saja kita buat. Buka kembali terminal lalu kita run command-nya.
```bash
php artisan make:user
```

Output ketika command berhasil dirun.

php artisan make:user
```
 ┌ What is your name? ──────────────────────────────────────────┐
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
```

Kita coba isi dengan `admin`, lalu enter.
```
php artisan make:user

 ┌ What is your name? ──────────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ What is your email? ─────────────────────────────────────────┐
 │                                                              │
 └──────────────────────────────────────────────────────────────┘


```

Kita coba isi email dengan `admin@example.com`, lalu tekan enter kembali. Lalu yang terakhir kita isi password.
```
php artisan make:user            

 ┌ What is your name? ──────────────────────────────────────────┐
 │ admin                                                        │
 └──────────────────────────────────────────────────────────────┘

 ┌ What is your email? ─────────────────────────────────────────┐
 │ admin@example.com                                            │
 └──────────────────────────────────────────────────────────────┘

 ┌ What is your password? ──────────────────────────────────────┐
 │ password                                                     │
 └──────────────────────────────────────────────────────────────┘

User admin created successfully
```

Ketika kita cek database, terdapat user baru yang berhasil ditambahkan di table `users`.

## Penutup{#penutup}

Laravel Prompt telah membawa revolusi signifikan dalam cara kita berinteraksi dengan command line interface. Meskipun pembuatan custom command sudah menjadi fitur standar Laravel sejak lama, kehadiran Laravel Prompt menghadirkan dimensi baru dalam pengembangan CLI yang lebih modern dan user-friendly.

### Keuntungan Menggunakan Laravel Prompt

- **Peningkatan User Experience**: Interface yang lebih intuitif memudahkan developer pemula maupun berpengalaman
- **Efisiensi Workflow**: Proses input dan validasi yang lebih cepat dan akurat
- **Reduced Error Rate**: Validasi real-time membantu mencegah kesalahan input
- **Maintainability**: Kode yang lebih terstruktur dan mudah dipelihara

### Langkah Selanjutnya

Untuk mengembangkan kemampuan Anda dalam membuat custom command dengan Laravel Prompt, berikut beberapa rekomendasi:

1. Eksplorasi fitur-fitur advanced Laravel Prompt
2. Implementasikan pada proyek nyata
3. Berkontribusi pada komunitas dengan membagikan custom command yang Anda buat
4. Ikuti update terbaru Laravel Prompt di [dokumentasi resmi](https://laravel.com/docs/11.x/prompts)

Laravel Prompt tidak hanya mengubah cara kita berinteraksi dengan CLI, tetapi juga membuka peluang baru dalam pengembangan tools dan utilities yang lebih powerful untuk ekosistem Laravel. Selamat mencoba dan jangan ragu untuk bereksperimen dengan kemampuan Laravel Prompt dalam proyek Anda berikutnya!