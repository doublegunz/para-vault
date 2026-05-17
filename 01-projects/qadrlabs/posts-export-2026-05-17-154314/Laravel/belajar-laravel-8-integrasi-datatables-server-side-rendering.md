---
title: "Belajar Laravel 8: Integrasi dataTables Server Side Rendering"
slug: "belajar-laravel-8-integrasi-datatables-server-side-rendering"
category: "Laravel"
date: "2021-09-22"
status: "published"
---

Sebagian besar data yang ditampilkan di karya yang saya buat itu menggunakan dataTables. Oleh karena itu ketika pertama kali belajar laravel 8, saya mencoba untuk mengintegrasikan laravel 8 dengan dataTables untuk menampilkan data di table. Dan kabar baiknya ada library yang bisa kita gunakan untuk mengintegrasikan laravel dengan dengan dataTables, yaitu library Laravel DataTables.

[Laravel DataTables](https://github.com/yajra/laravel-datatables) ini merupakan sebuah package untuk framework Laravel yang menangani penggunaan dataTables secara server side rendering. Selain itu package ini dapat menangani kostomisasi dataTables seperti column editing, row editing, searching, sorting atau ordering, dan juga plugin yang digunakan di dataTables.

## Overview {#overview}

Tutorial ini memberikan panduan langkah demi langkah untuk mengintegrasikan **Laravel 8** dengan **DataTables**, sebuah library populer yang digunakan untuk menampilkan data dalam tabel dengan fitur seperti pencarian, pengurutan, dan paginasi. Dengan menggunakan package **Laravel DataTables**, proses integrasi menjadi lebih mudah karena package ini mendukung rendering server-side, sehingga memungkinkan pengelolaan data dalam jumlah besar secara efisien.

### Apa yang akan dibuild
Dalam Tutorial ini, kita akan membangun aplikasi Laravel 8 sederhana yang menampilkan data pengguna (users) dalam tabel menggunakan **DataTables**. Data yang ditampilkan berasal dari database MySQL, dan tabel tersebut dilengkapi dengan fitur server-side rendering seperti pencarian, pengurutan, dan paginasi. Selain itu, kolom aksi (`action`) juga ditambahkan ke tabel untuk menunjukkan bagaimana kita dapat menyesuaikan tampilan sesuai kebutuhan.

### Apa yang akan dipelajari
1. **Instalasi dan Konfigurasi Laravel DataTables**: Anda akan belajar cara menginstal package **Laravel DataTables** serta cara mengonfigurasinya untuk bekerja dengan Laravel 8.
2. **Setup Database dan Migrasi**: Tutorial ini menjelaskan cara mengatur database dan membuat tabel `users` menggunakan migrasi Laravel.
3. **Pembuatan Dummy Data**: Anda akan mempelajari cara menghasilkan data dummy menggunakan **Tinker** untuk keperluan uji coba.
4. **Integrasi DataTables dengan Frontend**: Anda akan belajar cara mengintegrasikan **DataTables** dengan frontend menggunakan Bootstrap dan jQuery, termasuk instalasi assets melalui npm.
5. **Server-Side Rendering**: Anda akan memahami cara menggunakan class DataTables khusus untuk menangani rendering data secara server-side, termasuk penyesuaian kolom yang ditampilkan.
6. **Routing dan View**: Tutorial ini juga mencakup cara mendaftarkan route untuk halaman tabel dan membuat view Blade untuk menampilkan data.
7. **Uji Coba Aplikasi**: Terakhir, Anda akan melakukan uji coba untuk memastikan bahwa tabel berhasil dirender dengan benar di browser.

Dengan mempelajari Tutorial ini, Anda akan memiliki pemahaman yang solid tentang cara mengintegrasikan **DataTables** ke dalam aplikasi Laravel 8, serta bagaimana memanfaatkan fitur-fiturnya untuk meningkatkan pengalaman pengguna dalam menavigasi data.

## Step 1: Create Project Baru{#step-1}
Pertama kita buat project baru menggunakan `composer`. Sebagai contoh di sini nama projectnya `laravel-datatables`.

```
composer create-project laravel/laravel:^8.0 laravel-datatables
```

## Step 2: Setup database dan file konfigurasi .env{#step-2}
Setelah project kita buat, kita bisa lihat folder baru untuk project kita. Selanjutnya kita buka project di text editor. Lalu kemudian buka file `.env` di text editor, dan kita sesuaikan konfigurasi database, seperti di bawah ini.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_laravel_datatables
DB_USERNAME=userdbkamu
DB_PASSWORD=password

```

Kita akan menggunakan database dengan nama `db_laravel_datatables`, dan untuk credentials mysql, kita sesuaikan dengan username dan password mysql. Sebagai catatan, kalau kita menggunakan xampp, username yang digunakan itu umumnya `root` dan passwordnya dikosongkan. Jadi kita bisa atur konfigurasi database seperti ini.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_laravel_datatables
DB_USERNAME=root
DB_PASSWORD=

```

Setelah mengatur konfigurasi di file `.env`, kita buat database baru sesuai dengan yang ada file `.env`. Kamu boleh pakai apa saja untuk membuat database, boleh buat database lewat `phpmyadmin` ataupun lewat terminal atau cli langsung.

Apabila database sudah kita buat, langkah selanjutnya adalah running migration. Ya, karena kita menggunakan table `users` sebagai studi kasus, jadi di sini kita tidak membuat file migration terlebih dahulu. Kita langsung running migration menggunakan `artisan command`.

```php
php artisan migrate

```

Kita bisa lihat table baru di database `db_laravel_datatables`, salah satunya adalah table `users`. Karena data yang akan kita gunakan sebagai sample data adalah data `users`, kita perlu membuat dummy data terlebih dahulu untuk keperluan uji coba. Untuk generate sample data kita gunakan `tinker`.
```bash
php artisan tinker
```

Selanjutnya run kode ini di dalam cli untuk generate 50 sample data.

```bash
User::factory()->count(50)->create();
```
Setelah itu run command `exit` untuk keluar dari cli.

## Step 3: Install package dan publish assets{#step-3}
Persiapan kita selanjutnya adalah menginstall package `yajra/laravel-datatables`. Buka kembali terminal lalu kita install package menggunakan `command`.

```bash
composer require yajra/laravel-datatables
```

Tunggu sampai proses instalasi package `yajra/laravel-datatables` selesai. Setelah instalasi selesai, selanjutnya kita publish asset dari package tersebut. Run `artisan command` untuk publish asset.

```bash
php artisan vendor:publish --tag=datatables-buttons
```

## Step 4: Setup Laravel UI dan Datatables.net assets{#step-4}
Kita akan menggunakan bootstrap sebagai default tampilan project tutorial ini. Kita akan memanfaatkan package laravel UI. Buka kembali terminal, lalu kita install package tersebut menggunakan `command`.

```bash
composer require laravel/ui --dev
```

Setelah itu kita run `artisan command` berikut ini.

```bash
php artisan ui bootstrap --auth
```

Ketika berhasil running `artisan command` di atas, kita bisa lihat output seperti ini.

```bash
Bootstrap scaffolding installed successfully.
Please run "npm install && npm run dev" to compile your fresh scaffolding.
Authentication scaffolding generated successfully.
```

Ada petunjuk untuk run command `npm install && npm run dev`. Kita running dua `command tersebut`, lalu tunggu sampai proses instalasi selesai.

Datatables menggunakan jquery sebagai dependensinya. Apabila di `package.json` belum ada jquery, kita bisa install terlebih dahulu menggunakan `npm` command.
```
npm install jquery --save-dev
```

Untuk menggunakan datatables, kita harus menginstall datatablesnya terlebih dahulu. Kita coba install melalui `npm` juga. Buka kembali terminal, kemudian kita running command di bawah ini.

```bash
npm install datatables.net-bs4
npm install datatables.net-buttons-bs4
```

Setelah kedua assets untuk datatables terinstall, selanjutnya kita tambahkan datatables di js dan css yang sebelum sudah kita compile.

Buka file `resources/js/bootstrap.js` dan tambahkan baris kode berikut ini pada statement `try-catch`.

```javascript
try {
    window.$ = window.jQuery = require('jquery');

    require('bootstrap');
    require('datatables.net-bs4');
    require('datatables.net-buttons-bs4');
} catch (e) {}
```

Selain js, kita edit juga file `resources/sass/app.scss`. Kita tambahkan baris kode berikut ini untuk import datatables assets.

```css

// Bootstrap
@import '~bootstrap/scss/bootstrap';

// DataTables
@import "~datatables.net-bs4/css/dataTables.bootstrap4.css";
@import "~datatables.net-buttons-bs4/css/buttons.bootstrap4.css";

```

Dua file untuk assets datatables sudah kita register di `boostrap.js` dan `app.scss`, selanjutnya kita compile kembali menggunakan command.
```bash
npm run dev
```

## Step 5: Menampilkan data di dataTables{#step-5}
Semua persiapan kita sudah selesai, selanjutnya kita buat sebuah controller menggunakan `artisan command`.

```bash
php artisan make:controller UserController

```

Selain controller, kita juga perlu sebuah class yang akan menangan dataTables secara server side. Sama seperti controller, class ini kita generate juga menggunakan `artisan command`.

```bash
php artisan datatables:make User
```

Setelah kedua `command` dirun, kita bisa lihat ada dua file baru. Yang pertama adalah file controller `app/Http/Controllers/UserController.php` dan yang kedua adalah file untuk class datatables `app/DataTables/UserDataTable.php`.

Untuk menghandle halaman yang digunakan untuk menampilkan datatables, kita akan menambahkan method baru di dalam class `UserController`. Buka file controller `app/Http/Controllers/UserController.php`, lalu selanjutnya kita tambahkan method `index()`.

```php
<?php

namespace App\Http\Controllers;

use App\DataTables\UserDataTable;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(UserDataTable $dataTable)
    {
        return $dataTable->render('users.index');
    }
}

```

Pada baris kode di atas, kita bisa lihat ada statement `use` sebelum deklarasi class `UserController` karena menggunakan class `UserDatatable` untuk merender halaman di method `index()`.

Selanjutnya kita atur class `UserDatatable`, lalu kita modifikasi bagian method `getColumns()` untuk mengatur data apa saja yang ingin kita tampilkan di table. Sebagai contoh kita ingin menampilkan `id`, `name`, `email`, `updated_at` dan kolom untuk `action`.

```php
<?php

// ... baris kode lainnya

class UserDataTable extends DataTable
{

    public function dataTable($query)
    {
        return datatables()
            ->eloquent($query)
            ->addColumn('action', 'user.action'); // ini untuk menambahkan kolom action
    }

    // ... baris kode lainnya
    
    protected function getColumns()
    {
        return [
            Column::make('id'),
            Column::make('name'),
            Column::make('email'),
            Column::make('updated_at'),
            Column::computed('action')
                ->exportable(false)
                ->printable(false)
                ->width(60)
                ->addClass('text-center'),
        ];
    }

    // ... baris kode lainnya
}

```

Misalkan teman-teman bertanya, darimana kolom `action` itu ditambahkan? Kita bisa lihat di method sebelumnya, yaitu method `dataTable()`. Kita tambahkan method `addColumn('kolomnya', 'isi kolomnya')`, nanti kita bisa tambahkan `Column::make('kolomnya'),` di dalam method `getColumns()`.

Selanjutnya kita akan memodifikasi layout untuk ui project kita. Buka file `resources/views/layouts/app.blade.php`. Pertama kita hapus dulu kode ini yang terdapat di bagian tag `<head>`.
```html
    <!-- Scripts -->
    <script src="{{ asset('js/app.js') }}" defer></script>
```

Lalu kita tambahkan baris kode berikut ini sebelum tag `</body>`.

```html

    <script src="{{ mix('js/app.js') }}"></script>
    <script src="{{ asset('vendor/datatables/buttons.server-side.js') }}"></script>
    @stack('scripts')

```

Sehingga keseluruhan isi file `app.blade.php` menjadi seperti berikut ini.

```html
<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel Datatables @ qadrLabs') }}</title>

    <!-- Fonts -->
    <link rel="dns-prefetch" href="//fonts.gstatic.com">
    <link href="https://qadrlabs.com/cloudme.fonts.googleapis.com/css?family=Nunito" rel="stylesheet">

    <!-- Styles -->
    <link href="{{ asset('css/app.css') }}" rel="stylesheet">
</head>
<body>
    <div id="app">
        <nav class="navbar navbar-expand-md navbar-light bg-white shadow-sm">
            <div class="container">
                <a class="navbar-brand" href="{{ url('/') }}">
                    {{ config('app.name', 'Laravel') }}
                </a>
                <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="{{ __('Toggle navigation') }}">
                    <span class="navbar-toggler-icon"></span>
                </button>

                <div class="collapse navbar-collapse" id="navbarSupportedContent">
                    <!-- Left Side Of Navbar -->
                    <ul class="navbar-nav mr-auto">

                    </ul>

                    <!-- Right Side Of Navbar -->
                    <ul class="navbar-nav ml-auto">
                        <!-- Authentication Links -->
                        @guest
                            @if (Route::has('login'))
                                <li class="nav-item">
                                    <a class="nav-link" href="{{ route('login') }}">{{ __('Login') }}</a>
                                </li>
                            @endif

                            @if (Route::has('register'))
                                <li class="nav-item">
                                    <a class="nav-link" href="{{ route('register') }}">{{ __('Register') }}</a>
                                </li>
                            @endif
                        @else
                            <li class="nav-item dropdown">
                                <a id="navbarDropdown" class="nav-link dropdown-toggle" href="#" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" v-pre>
                                    {{ Auth::user()->name }}
                                </a>

                                <div class="dropdown-menu dropdown-menu-right" aria-labelledby="navbarDropdown">
                                    <a class="dropdown-item" href="{{ route('logout') }}"
                                       onclick="event.preventDefault();
                                                     document.getElementById('logout-form').submit();">
                                        {{ __('Logout') }}
                                    </a>

                                    <form id="logout-form" action="{{ route('logout') }}" method="POST" class="d-none">
                                        @csrf
                                    </form>
                                </div>
                            </li>
                        @endguest
                    </ul>
                </div>
            </div>
        </nav>

        <main class="py-4">
            @yield('content')
        </main>
    </div>

    <script src="{{ mix('js/app.js') }}"></script>
    <script src="{{ asset('vendor/datatables/buttons.server-side.js') }}"></script>
    @stack('scripts')
</body>
</html>

```

Selanjutnya kita buat file view baru `resources/views/users/index.blade.php`. Yep, sebelum membuat file `index.blade.php`, kita buat folder baru dengan nama `users`, lalu kita buat `index.blade.php` di dalam folder tersebut.

Selanjutnya kita tambahkan baris kode berikut ini di dalam file `index.blade.php`.

```html
@extends('layouts.app')

@section('content')
    <div class="container mt-3">
        <div class="row">
            <div class="col-12">
                <div class="card shadow rounded">
                    <div class="card-body">
                        {{ $dataTable->table() }}

                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    {{ $dataTable->scripts() }}
@endpush

```

Keterangan: di baris kode di atas, kita merender datatables dengan menggunakan method `table()` dari objek `$dataTable` yang merupakan instansiasi class `UserDataTable`. Untuk inisiasi datatable server side sendiri sudah ditangani dengan memanggil method `scripts()`.

```html
@push('scripts')
    {{ $dataTable->scripts() }}
@endpush
```

## Step 6: Register Users Route{#step-6}
Tahapan selanjutnya adalah menambahkan route baru di dalam file `routes/web.php`. Kita tambahkan statement `use` untuk load class `UserController`, lalu kita definisikan route untuk menampilkan datatables.

```php
use App\Http\Controllers\UserController;

//.. baris kode lainnya


Route::get('/users', [UserController::class, 'index'])->name('users.index');

```

## Uji coba{#uji-coba}
Untuk uji coba, kita bisa running project kita terlebih dahulu menggunakan `artisan command`.

```bash
php artisan serve

```

Lalu kita akses `http://127.0.0.1:8000/users` di browser. Di halaman ini kita bisa lihat datatables berhasil di render secara server side.

![tampilan datatables ketika project diakses](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel-8/integrasi-datatables/screenshot.png)

## Kesimpulan {#kesimpulan}

Dalam Tutorial ini, kita telah mempelajari cara mengintegrasikan **DataTables** dengan **Laravel 8** menggunakan package **Laravel DataTables** untuk menampilkan data dalam tabel dengan server-side rendering. Proses ini jauh lebih mudah dan efisien dibandingkan dengan pendekatan manual, karena package ini menyediakan fitur-fitur seperti pengaturan kolom, penambahan aksi, pencarian, pengurutan, dan paginasi secara otomatis.

Meskipun kita sudah berhasil membuat tabel sederhana dengan data dari database, masih banyak aspek lain dari package **Laravel DataTables** yang bisa dieksplorasi lebih lanjut. Beberapa di antaranya adalah:

- **Column Editing & Row Editing**: Bagaimana cara mengedit data langsung dari tabel.
- **Searching & Filtering**: Menerapkan filter khusus atau pencarian berdasarkan kolom tertentu.
- **Relasi Antar Tabel**: Menampilkan data yang berasal dari relasi antar tabel, seperti data dari model yang saling terkait.
- **Penggunaan Plugin Tambahan**: Memanfaatkan plugin DataTables lainnya untuk meningkatkan fungsionalitas tabel.

Dengan eksplorasi lebih lanjut, Anda dapat memaksimalkan penggunaan **Laravel DataTables** untuk kebutuhan aplikasi yang lebih kompleks. Integrasi ini tidak hanya mempermudah proses pengembangan, tetapi juga memberikan pengalaman pengguna yang lebih baik dalam menavigasi dan mengelola data dalam jumlah besar.