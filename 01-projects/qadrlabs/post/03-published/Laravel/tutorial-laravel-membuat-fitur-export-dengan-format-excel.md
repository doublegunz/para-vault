---
title: "Tutorial Laravel: Membuat Fitur Export Dengan Format Excel"
slug: "tutorial-laravel-membuat-fitur-export-dengan-format-excel"
category: "Laravel"
date: "2024-04-28"
status: "published"
---

Salah satu fitur yang seringkali diminta oleh client ketika membuat laporan adalah fitur export data ke dalam format excel. Dulu untuk membuat fitur export ini saya buat dengan cara manual dan hasilnya seringkali file hasil export format excel ini tidak bisa dibuka. Kabar baiknya sekarang banyak package yang dapat memudahkan kita sebagai developer untuk membuat fitur export excel ini. Di ekosistem framework laravel sendiri terdapat package yang sering digunakan, yaitu package `maatwebsite/excel`. Di edisi tutorial laravel kali ini kita akan coba membuat fitur export excel.

## Overview{#overview}
Pada tutorial laravel kali ini kita akan membuat fitur untuk mengexport data ke dalam format excel. Fitur export excel ini kita buat dengan memanfaatkan salah satu package yang sering digunakan, yaitu package `maatwebsite/excel`.

Untuk studi kasus di tutorial laravel kali ini kita tidak akan membuat project yang kompleks. Projectnya cukup sederhana, kita fokus membuat fitur export file dengan format excel saja, tanpa menambahkan view atau user interface lainnya.

Untuk sample data yang akan kita gunakan di project ini adalah data user. Sample data user ini nanti akan kita coba sediakan dengan cara generate menggunakan tinker.

Untuk isi konten dari hasil export dalam format excel ini kita batasi hanya dengan menampilkan nama dan email saja.

Di akhir tutorial laravel ini, outputnya berupa link atau route yang nanti ketika diakses oleh user akan langsung melakukan proses download file dengan format excel.


## Step 1 - Create Project{#step-1}
Sekarang kita buat project laravel baru menggunakan composer. Buka terminal lalu run command berikut ini untuk membuat project laravel baru.

```
composer create-project --prefer-dist laravel/laravel export-excel-example
```

Tunggu sampai proses create project selesai.

## Step 2 - Setup konfigurasi database{#step-2}
Selanjutnya kita pindah ke direktori project menggunakan command berikut ini.
```
cd export-excel-example
```

Lalu kita buka direktori project di code editor (di sini saya menggunakan visual studi code)
```
code .
```

Di code editor, buka file `.env`, lalu kita sesuaikan konfigurasi database.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_export
DB_USERNAME=root
DB_PASSWORD=password
```

Pada baris kode di atas, saya gunakan koneksi database `mysql` dengan nama database `db_belajar_export`. Untuk credentials mysql sesuaikan dengan username dan password yang teman-teman gunakan.


Selanjutnya kita run command migrate.
```
php artisan migrate
```

Apabila database belum kita buat, tampil warning di output yang ditampilkan di terminal.

```
   WARN  The database 'db_belajar_export' does not exist on the 'mysql' connection.
```

Pilih yes untuk membuat database baru dan melanjutkan proses migrate.

Output yang ditampilkan:

```
$ php artisan migrate

   WARN  The database 'db_belajar_export' does not exist on the 'mysql' connection.

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.

  Creating migration table ...................................... 27.57ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table .......................... 65.35ms DONE
  0001_01_01_000001_create_cache_table .......................... 14.11ms DONE
  0001_01_01_000002_create_jobs_table ........................... 51.25ms DONE

```

## Step 3 - Generate dummy data{#step-3}
Selanjutnya kita generate dummy data menggunakan tinker. Run command berikut ini.

```
php artisan tinker
```

Selanjutnya kita gunakan database factory untuk generate 50 data. Ketik code berikut ini.
```
User::factory()->count(50)->create();
```
Lalu tekan enter untuk memulai proses generate dummy data.

Contoh output yang ditampilkan di terminal:
```
php artisan tinker
Psy Shell v0.12.3 (PHP 8.2.18 — cli) by Justin Hileman
> User::factory()->count(50)->create();
[!] Aliasing 'User' to 'App\Models\User' for this Tinker session.
= Illuminate\Database\Eloquent\Collection {#5112
    all: [
      App\Models\User {#5144
        name: "Andreane Waelchi III",
        email: "wbeahan@example.com",
        email_verified_at: "2024-04-28 08:16:40",
        #password: "$2y$12$HFkHv.hbS6sYYMl60LqZFuywu.dbb0WYX0quU6iDvlEtO3qt/zT5K",
        #remember_token: "nbEqWbWiQK",
        updated_at: "2024-04-28 08:16:40",
        created_at: "2024-04-28 08:16:40",
        id: 2,
      },
      App\Models\User {#5114
        name: "Johnny Roob",
        email: "hermann.anahi@example.com",
        email_verified_at: "2024-04-28 08:16:40",
        #password: "$2y$12$HFkHv.hbS6sYYMl60LqZFuywu.dbb0WYX0quU6iDvlEtO3qt/zT5K",
        #remember_token: "zU6gf623Jg",
        updated_at: "2024-04-28 08:16:40",
        created_at: "2024-04-28 08:16:40",
        id: 3,
      },

        ...

        ...
      App\Models\User {#5190
        name: "Angelica Legros",
        email: "qcummerata@example.net",
        email_verified_at: "2024-04-28 08:16:40",
        #password: "$2y$12$HFkHv.hbS6sYYMl60LqZFuywu.dbb0WYX0quU6iDvlEtO3qt/zT5K",
        #remember_token: "qxul7DB77U",
        updated_at: "2024-04-28 08:16:40",
        created_at: "2024-04-28 08:16:40",
        id: 50,
      },
      App\Models\User {#5191
        name: "Rose Johnston",
        email: "pprohaska@example.net",
        email_verified_at: "2024-04-28 08:16:40",
        #password: "$2y$12$HFkHv.hbS6sYYMl60LqZFuywu.dbb0WYX0quU6iDvlEtO3qt/zT5K",
        #remember_token: "121fpY9R4E",
        updated_at: "2024-04-28 08:16:40",
        created_at: "2024-04-28 08:16:40",
        id: 51,
      },
    ],
  }
```

Setelah selesai, ketik command berikut ini untuk keluar dari `tinker` laravel.
```
exit
```

## Step 4 - Install maatwebsite/excel package{#step-4}
Langkah selanjutnya adalah menginstall package yang akan kita gunakan, yaitu `maatwebsite/excel`. Buka kembali terminal lalu run command berikut ini.

```
composer require maatwebsite/excel
```

Setelah package terinstall, run command berikut ini untuk publish file konfigurasi package teresebut.
```
php artisan vendor:publish --provider="Maatwebsite\Excel\ExcelServiceProvider" --tag=config
```

Output:
```
   INFO  Publishing [config] assets.

  Copying file [vendor/maatwebsite/excel/config/excel.php] to [config/excel.php]  DONE
```

## Step 5 - Create Export class{#step-5}
Selanjutnya kita akan generate class yang akan menangani isi dari file hasil export dengan format excel. Kita akan gunakan command dari package `maatwebsite/excel`. Buka kembali terminal lalu run command berikut ini untuk generate export class.

```
php artisan make:export UsersExport --model=User
```

Output di terminal:
```
   INFO  Export [app/Exports/UsersExport.php] created successfully.
```

Seperti yang terlihat di output yang ditampilkan pada terminal, terdapat file baru ketika kita run command di atas yaitu file `app/Exports/UsersExport.php`.

Selanjutnya kita buka file `app/Exports/UsersExport.php`, lalu kita ubah dan sesuaikan supaya data yang nanti di file hasil export berasal dari file view.

Isi dari file `app/Exports/UsersExport.php`.
```php
<?php

namespace App\Exports;

use App\Models\User;
use Maatwebsite\Excel\Concerns\FromCollection;

class UsersExport implements FromCollection
{
    public function collection()
    {
        return User::all();
    }
}
```

Kita ubah menjadi seperti baris kode berikut ini.

```php
<?php

namespace App\Exports;

use App\Models\User;
use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;

class UsersExport implements FromView
{

    public function view(): View
    {
        return view('exports.users', [
            'users' => User::all()
        ]);
    }
}

```

Save kembali file `app/Exports/UsersExport.php`.

Sekarang kita buat file template yang kita gunakan untuk hasil export, yaitu `resources/views/exports/users.blade.php`.

Setelah itu kita tambahkan baris kode berikut ini di file `resources/views/exports/users.blade.php`.

```html
<table>
    <thead>
    <tr>
        <th>Name</th>
        <th>Email</th>
    </tr>
    </thead>
    <tbody>
    @foreach($users as $user)
        <tr>
            <td width="auto">{{ $user->name }}</td>
            <td width="auto">{{ $user->email }}</td>
        </tr>
    @endforeach
    </tbody>
</table>

```

Save `resources/views/exports/users.blade.php`.


## Step 6 - Create Controller{#step-6}
Sekarang kita buat file controller untuk menangani proses export. Buka kembali terminal, lalu run command berikut ini.

```
php artisan make:controller UserController
```

```
   INFO  Controller [app/Http/Controllers/UserController.php] created successfully.
```


Selanjutnya buka `app/Http/Controllers/UserController.php`, lalu kita tambahkan method `export()`.

```php
<?php

namespace App\Http\Controllers;

use App\Exports\UsersExport;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class UserController extends Controller
{
    public function export()
    {
        return Excel::download(new UsersExport, 'users.xlsx');
    }
}

```

Save kembali file `app/Http/Controllers/UserController.php`.

Pada baris kode di atas, kita gunakan method `download()` dari package `Maatwebsite\Excel` untuk melakukan proses download hasil export dengan format excel.

## Step 7 - Definisikan route{#step-7}

Selanjutnya kita definisikan route untuk proses export excel. Buka file `routes/web.php`, lalu kita tambahkan route baru.

```
Route::get('users/export', [\App\Http\Controllers\UserController::class, 'export'])
->name('users.export');
```

Save kembali file `routes/web.php`.

## Step 8 - Uji Coba{#step-8}
Sekarang kita run project laravel dengan run command berikut ini.
```
php artisan serve
```

Selanjutnya akses url `http://127.0.0.1:8000/users/export` di browser. Ketika kita akses url tersebut, kita bisa lihat kita download hasil export dengan format excel.

Ketika kita buka file excel yang baru saja kita download, kita bisa lihat isi dari file kurang lebih seperti berikut ini.

![isi file hasil export](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/export-excel/file-hasil-export.png)

Data yang ditampilkan sesuai dengan data dari template yang sebelumnya kita buat.


## Penutup{#penutup}
Pada tutorial laravel ini kita sudah coba membuat fitur export excel. Dimulai dengan setup project, menyiapkan sample data, coding fitur export excel dan uji coba download file hasil export ke dalam format excel. Seperti yang terlihat dari hasil uji coba, output file sesuai dengan yang kita rencanakan dengan menampilkan nama dan email saja.