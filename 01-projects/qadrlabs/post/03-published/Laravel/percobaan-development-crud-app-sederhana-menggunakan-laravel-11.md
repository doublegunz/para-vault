---
title: "Tutorial Laravel 11: Development Sample Aplikasi CRUD"
slug: "percobaan-development-crud-app-sederhana-menggunakan-laravel-11"
category: "Laravel"
date: "2024-02-15"
status: "published"
---

Laravel 11 telah dirilis pada 12 Maret 2024 lalu, membawa berbagai fitur dan peningkatan yang menarik untuk para developer. Di tutorial ini, kita akan langsung praktek membuat aplikasi CRUD (Create, Read, Update, Delete) sederhana menggunakan Laravel 11. Tutorial ini dirancang khusus untuk pemula yang ingin memahami dasar-dasar Laravel 11 melalui contoh praktis yang bisa langsung diterapkan. Kita akan gunakan codebase dari versi Laravel sebelumnya, sehingga Anda bisa melihat bagaimana kemudahan migrasi ke versi terbaru. Bahkan jika Anda masih belajar versi Laravel sebelumnya, tutorial ini akan membantu Anda memahami perbedaan dan kesamaannya dengan Laravel 11.

Dalam tutorial ini, kita akan membuat aplikasi pengelolaan user dengan fitur lengkap mulai dari menampilkan daftar user, menambah user baru, mengubah data user yang sudah ada, hingga menghapus data user. Mari kita mulai belajar sambil praktik langsung!

## Overview{#overview}
Tutorial CRUD Laravel 11 ini akan memandu Anda membuat aplikasi pengelolaan user dari awal hingga akhir. Kita akan membangun fitur-fitur esensial yang sering digunakan dalam pengembangan aplikasi web modern.

### Fitur yang Akan Dibuat
- **View User List**: Menampilkan daftar user dengan pagination
- **Create User**: Form untuk menambahkan user baru dengan validasi
- **Update User**: Form untuk mengubah data user yang sudah ada
- **Delete User**: Fungsi untuk menghapus data user

### Teknologi yang Digunakan
- Laravel 11 sebagai backend framework
- Bootstrap 5 untuk styling dan komponen UI
- SQLite sebagai database default
- Route Resource untuk pengelolaan endpoint API

### Prasyarat
- PHP 8.2 atau lebih tinggi
- Composer untuk instalasi Laravel
- Text editor (VSCode, Sublime, atau editor lainnya)
- Pemahaman dasar tentang PHP dan Laravel

### Yang Akan Anda Pelajari
- Setup project Laravel 11 dengan konfigurasi terbaru
- Implementasi CRUD operations dengan Laravel
- Penggunaan Route Resource untuk API endpoints
- Form handling dan validasi data
- Pagination dan flash messages
- Database migrations dan model relationships

Setelah menyelesaikan tutorial ini, Anda akan memiliki pemahaman yang solid tentang bagaimana membangun fitur CRUD menggunakan Laravel 11, serta dapat mengembangkan aplikasi serupa untuk kebutuhan Anda sendiri.

Mari kita mulai dengan persiapan environment development!

## Persiapan{#persiapan}
Berdasarkan dokumentasi laravel [bagian server requirement](https://laravel.com/docs/11.x/deployment#server-requirements) yang saya baca, minimal PHP yang dapat kita gunakan adalah PHP 8.2. Jadi sekarang kita cek dulu versi PHPnya. Kita buka terminal lalu run command berikut ini.
```
php -v
```
Output setelah command kita run:
```
PHP 8.2.15 (cli) (built: Jan 20 2024 14:17:05) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.15, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.15, Copyright (c), by Zend Technologies
```

Jika outputnya bukan PHP 8.2, teman-teman bisa mengikuti tutorial [setup dan menggunakan multiple version PHP](https://qadrlabs.com/post/tutorial-setup-dan-menggunakan-multiple-version-php-di-ubuntu) supaya dapat pindah versi PHP dengan mudah. 

## Step 1 - Create Laravel Project{#step-1}
Sekarang kita coba buat project laravel baru menggunakan `composer`. Buka kembali terminal lalu run command berikut ini untuk membuat project laravel 11 baru.
```
 composer create-project laravel/laravel:^11.0 crud-app-example

```

Setelah proses create project selesai, di output yang ditampilkan terdapat output berikut ini.
```
84 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
> @php artisan vendor:publish --tag=laravel-assets --ansi --force

   INFO  No publishable resources for tag [laravel-assets].  

> @php artisan key:generate --ansi

   INFO  Application key set successfully.  

> @php -r "file_exists('database/database.sqlite') || touch('database/database.sqlite');"
> @php artisan migrate --ansi

   INFO  Preparing database.  

  Creating migration table ....................................... 9.14ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 20.65ms DONE
  0001_01_01_000001_create_cache_table ........................... 6.03ms DONE
  0001_01_01_000002_create_jobs_table ........................... 16.75ms DONE

```

Bisa kita perhatikan di atas, terdapat pembuatan database baru.
```
@php -r "file_exists('database/database.sqlite') || touch('database/database.sqlite');"
```
Dan kalau kita buka file `.env`, kita bisa lihat database default yang digunakan Laravel 11 itu adalah sqlite.

```
DB_CONNECTION=sqlite
```

Selain itu di output di atas, terdapat output seperti berikut ini.
```
@php artisan migrate --ansi

   INFO  Preparing database.  

  Creating migration table ....................................... 9.14ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 20.65ms DONE
  0001_01_01_000001_create_cache_table ........................... 6.03ms DONE
  0001_01_01_000002_create_jobs_table ........................... 16.75ms DONE

```
Kita bisa lihat dari output di atas, command `artisan migrate` langsung dieksekusi setelah create project laravel 11 baru.

Karena database sudah tersedia dan command `migrate` sudah di running, kita akan coba lanjutkan untuk development fitur CRUD.

## Step 2 - Coding Fitur View Daftar User{#step-2}
Pada tahapan sebelumnya kita sudah membuat project laravel 11 baru, dan sekarang kita coba masuk ke direktori project.
```
cd crud-app-example
```

Setelah itu kita coba buat controller baru menggunakan command berikut ini.
```
php artisan make:controller UserController --model=User --resource

```

Output:
```
   INFO  Controller [app/Http/Controllers/UserController.php] created successfully.  
```

Selanjutnya buka file `app/Http/Controllers/UserController.php`, lalu kita modifikasi method `index()` untuk menampilkan halaman daftar user.
```php
<?php

// BARIS KODE LAINNYA

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $users = User::latest()->paginate(10);
        return view('users.index', compact('users'));
    }


    // BARIS KODE LAINNYA
}

```

Selanjutnya kita buat file view baru `resources/views/users/index.blade.php`. Pada file `resources/views/users/index.blade.php`, kita sesuaikan dengan baris kode berikut ini.
```

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>User List - Tutorial CRUD Laravel 11 @ qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-12">

            <h4>User List</h4>

            <!-- Notifikasi menggunakan flash session data -->
            @if (session('message'))
                <div class="alert alert-success">
                    {{ session('message') }}
                </div>
            @endif

            <div class="card border-0 shadow rounded">
                <div class="card-body">
                    <a href="{{ route('user.create') }}" class="btn btn-md btn-success mb-3 float-end">New
                        User</a>

                    <table class="table table-bordered mt-1 text-center">
                        <thead>
                        <tr>
                            <th scope="col">Name</th>
                            <th scope="col">Email</th>
                            <th scope="col">Create At</th>
                            <th scope="col">Action</th>
                        </tr>
                        </thead>
                        <tbody>
                        @forelse ($users as $user)
                            <tr>
                                <td>{{ $user->name }}</td>
                                <td>{{ $user->email }}</td>
                                <td>{{ $user->created_at->format('d-m-Y') }}</td>
                                <td>
                                    <form onsubmit="return confirm('Apakah Anda Yakin ?');"
                                          action="{{ route('user.destroy', $user->id) }}" method="POST">
                                        <a href="{{ route('user.edit', $user->id) }}"
                                           class="btn btn-sm btn-primary">EDIT</a>
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-danger">DELETE</button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td class="text-center text-mute" colspan="4">Data user tidak tersedia</td>
                            </tr>
                        @endforelse
                        </tbody>
                    </table>

                    {{ $users->links() }}
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

</body>

</html>

```

Pada baris kode di atas, terdapat `{{ $users->links() }}` yang berfungsi untuk menampilkan pagination. Selain itu kita bisa lihat terdapat baris kode berikut ini.

```
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
```

Tanda di halaman daftar user ini, kita menggunakan `bootstrap` versi 5. Karena secara default, untuk UI menggunakan Tailwind, kita perlu menyesuaikan terlebih dahulu untuk menggunakan pagination laravel.

Sekarang kita sesuaikan terlebih dahulu supaya project laravel 11 menggunakan bootstrap. Buka file `app/Providers/AppServiceProvider.php`. Lalu kita sesuaikan menjadi baris kode berikut ini.

```php
<?php

namespace App\Providers;

use Illuminate\Pagination\Paginator; // tambahkan baris kode ini
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{

    // BARIS KODE LAINNYA

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Paginator::useBootstrapFive(); // tambahkan baris kode ini
    }
}

```

Bisa kita lihat di baris kode di atas, kita gunakan bootstrap 5 di project laravel 11 kita.

Sekarang kita definisikan route baru yang akan menangani fitur CRUD di project Laravel 11. Buka file `routes/web.php`, lalu kita sesuaikan seperti baris kode berikut ini.

```
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', [\App\Http\Controllers\UserController::class, 'index']);
Route::resource('user', \App\Http\Controllers\UserController::class);

```
Setelah selesai, save kembali file `routes/web.php`.

Dari dua definisi rute yang Anda berikan, mari kita bahas masing-masingnya:

1. **Rute untuk Menampilkan Halaman Utama:**

```php
Route::get('/', [\App\Http\Controllers\UserController::class, 'index']);
```

Rute ini menetapkan URL root ('/') untuk mengarah ke method `index()` di `UserController`. Ketika nanti kita running project, metode `index()` di `UserController` akan dipanggil untuk menampilkan halaman utama.

2. **Resourceful Route untuk Pengelolaan User:**

```php
Route::resource('user', \App\Http\Controllers\UserController::class);
```

Rute ini menggunakan method `resource()` yang disediakan oleh Laravel untuk membuat rute CRUD lengkap untuk pengelolaan entitas user. Ini akan secara otomatis menangani berbagai operasi CRUD seperti create, read, update, dan delete.

Ini adalah daftar rute yang dibuat oleh `Route::resource('user', \App\Http\Controllers\UserController::class)`:

- **GET** `/user`: Menampilkan daftar semua pengguna.
- **GET** `/user/create`: Menampilkan formulir untuk membuat pengguna baru.
- **POST** `/user`: Menyimpan data pengguna yang baru.
- **GET** `/user/{id}`: Menampilkan detail pengguna dengan ID tertentu.
- **GET** `/user/{id}/edit`: Menampilkan formulir untuk mengedit pengguna dengan ID tertentu.
- **PUT/PATCH** `/user/{id}`: Memperbarui data pengguna dengan ID tertentu.
- **DELETE** `/user/{id}`: Menghapus pengguna dengan ID tertentu.

Dengan menggunakan `Route::resource()`, kita bisa mendapatkan rute lengkap untuk pengelolaan user dengan sedikit kode.

## Step 3 - Coding Fitur Create User{#step-3}
Pada tahapan ini kita akan menambahkan fitur untuk menambahkan user baru. Sekarang kita buka kembali file `app/Http/Controllers/UserController.php`, lalu kita modifikasi method `create()` untuk menampilkan halaman form tambah user baru.
```php
<?php

// BARIS KODE LAINNYA

class UserController extends Controller
{
    // BARIS KODE LAINNYA

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('users.create');
    }

    // BARIS KODE LAINNYA
}


```

Selanjutnya kita buat file view baru `resources/views/users/create.blade.php`. Sekarang kita sesuaikan `resources/views/users/create.blade.php` seperti baris kode berikut ini.

```
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Create New User - Tutorial CRUD Laravel 11 @ qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>

<div class="container mt-5 mb-5">
    <div class="row">
        <div class="col-md-12">

            <h4>Create New User</h4>

            <div class="card border-0 shadow rounded">
                <div class="card-body">

                    <form action="{{ route('user.store') }}" method="POST">
                        @csrf

                        <div class="mb-3">
                            <label for="name">Name</label>
                            <input type="text" class="form-control @error('name') is-invalid @enderror"
                                   name="name" value="{{ old('name') }}" required>

                            <!-- error message untuk name -->
                            @error('name')
                            <div class="invalid-feedback" role="alert">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>

                        <div class="mb-3">
                            <label for="email">Email Address</label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   name="email" value="{{ old('email') }}" required>

                            <!-- error message untuk email -->
                            @error('email')
                            <div class="invalid-feedback" role="alert">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>

                        <div class="mb-3">
                            <label for="password">Password</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   name="password" required>

                            <!-- error message untuk password -->
                            @error('password')
                            <div class="invalid-feedback" role="alert">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>

                        <div class="mb-3">
                            <label for="password_confirmation">Confirm Password</label>
                            <input type="password" class="form-control"
                                   name="password_confirmation" required>

                        </div>


                        <button type="submit" class="btn btn-md btn-primary">Save</button>
                        <a href="{{ route('user.index') }}" class="btn btn-md btn-secondary">back</a>

                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

</body>

</html>

```

Pada baris kode di atas, terdapat baris kode berikut ini.
```
<form action="{{ route('user.store') }}" method="POST">
```

Action dari form tambah data user diarahkan ke method `store()`, di controller `UserController`. Sekarang kita modifikasi method `store()` untuk menangani proses menambahkan user baru ke table `users`.
```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash; // tambahkan ini

class UserController extends Controller
{
    
    // BARIS KODE LAINNYA

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed'
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password)
        ]);

        return redirect()
            ->route('user.index')
            ->with('message', 'New user created successfully');
    }

    // BARIS KODE LAINNYA
}

```

Karena untuk hash password kita menggunakan function `make()` dari `Illuminate\Support\Facades\Hash`, jangan lupa menambahkan statement `use Illuminate\Support\Facades\Hash;` sebelum deklarasi class `UserControoler`.

Setelah kita selesai coding untuk method `store()`, jangan lupa save kembali file `app/Http/Controllers/UserController.php`.

## Step 4 - Coding Fitur Edit User{#step-4}
Pada step ini kita tambahkan fitur untuk mengedit data user.

Buka kembali file `app/Http/Controllers/UserController.php`, lalu kita modifikasi method `edit()` untuk menampilkan halaman form edit.
```php
<?php

// BARIS KODE LAINNYA

class UserController extends Controller
{
    

    // BARIS KODE LAINNYA

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $user)
    {
        return view('users.edit', compact('user'));
    }

    // BARIS KODE LAINNYA
}

```

Selanjutnya kita buat file view baru `resources/views/users/edit.blade.php`. Kemudian kita sesuaikan menjadi baris kode berikut ini.

```
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Edit User - Tutorial CRUD Laravel 11 @ qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
</head>

<body>

<div class="container mt-5 mb-5">
    <div class="row">
        <div class="col-md-12">

            <h4>Edit User</h4>

            <div class="card border-0 shadow rounded">
                <div class="card-body">

                    <form action="{{ route('user.update', $user) }}" method="POST">
                        @csrf
                        @method('PUT')

                        <div class="mb-3">
                            <label for="name">Name</label>
                            <input type="text" class="form-control @error('name') is-invalid @enderror"
                                   name="name" value="{{ old('name', $user->name) }}" required>

                            <!-- error message untuk name -->
                            @error('name')
                            <div class="invalid-feedback">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>

                        <div class="mb-3">
                            <label for="email">Email Address</label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   name="email" value="{{ old('email', $user->email) }}" required>

                            <!-- error message untuk email -->
                            @error('email')
                            <div class="invalid-feedback">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>

                        <div class="mb-3">
                            <label for="password">Password</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   name="password" value="{{ old('password') }}">

                            <!-- error message untuk password -->
                            @error('password')
                            <div class="invalid-feedback">
                                {{ $message }}
                            </div>
                            @enderror
                        </div>


                        <button type="submit" class="btn btn-md btn-primary">Update</button>
                        <a href="{{ route('user.index') }}" class="btn btn-md btn-secondary">back</a>

                    </form>
                </div>
            </div>
        </div>
    </div>
</div>


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

</body>

</html>

```

Karena action form mengarah ke method `update()` di controller class `UserController`, sekarang kita modifikasi method `update()` untuk menangani proses update data user.
```php
<?php

// BARIS KODE LAINNYA

class UserController extends Controller
{
    
    // BARIS KODE LAINNYA

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, User $user)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,'.$user->id,
        ]);

        $user->name = $request->name;
        $user->email = $request->email;

        if (! empty($request->get('password'))) {
            $user->password = Hash::make($request->password);
        }
        $user->save();

        return redirect()
            ->route('user.index')
            ->with('message', 'User updated successfully');
    }

    // BARIS KODE LAINNYA
    
}

```
Setelah selesai, save kembali file `app/Http/Controllers/UserController.php`.

## Step 5 - Coding Fitur Delete User{#step-5}
Fitur terakhir dari aplikasi CRUD laravel 11 ini adalah fitur untuk delete data user. 

Sekarang buka kembali file `app/Http/Controllers/UserController.php`, lalu kita modifikasi method `destroy()` yang menangani proses delete data user.
```
<?php


// BARIS KODE LAINNYA

class UserController extends Controller
{
    
    // BARIS KODE LAINNYA

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        $user->delete();
        return redirect()
            ->route('user.index')
            ->with('message', 'User deleted successfully');
    }
}

```

Setelah selesai save kembali file `app/Http/Controllers/UserController.php`.

## Step 6 - Uji Coba Project {#step-6}
Setelah menyelesaikan semua fitur CRUD, saatnya kita menguji aplikasi. Berikut langkah-langkah untuk testing aplikasi:

1. Jalankan development server dengan command:
```bash
php artisan serve
```

2. Buka browser dan akses `http://localhost:8000`. Anda akan melihat halaman daftar user.

3. Mari uji setiap fitur yang telah kita buat:
   - **Create**: Klik tombol "New User" dan isi form untuk menambah user baru
   - **Read**: Perhatikan daftar user yang ditampilkan beserta paginationnya
   - **Update**: Klik tombol "EDIT" pada salah satu user dan ubah datanya
   - **Delete**: Klik tombol "DELETE" untuk menghapus user

4. Testing Validasi:
   - Coba submit form dengan email yang sudah ada
   - Coba submit form dengan password yang terlalu pendek
   - Coba submit form dengan field kosong

5. Testing Pagination:
   - Tambahkan beberapa user hingga melebihi 10 data
   - Pastikan pagination berfungsi dengan baik
   - Cek tampilan nomor halaman

Jika semua fitur berjalan dengan baik, selamat! Anda telah berhasil membuat aplikasi CRUD menggunakan Laravel 11. Jika menemui error, periksa kembali langkah-langkah sebelumnya atau cek log error di terminal.

Tips: Untuk development yang lebih baik, Anda bisa menggunakan tools seperti Laravel Debugbar atau Clockwork untuk memonitor query dan performance aplikasi.

## Penutup{#penutup}
Pada seri tutorial laravel 11 edisi kali ini, kita sudah coba mengembangkan project laravel 11 dengan fitur CRUD untuk mengelola data user. Pada edisi kali ini kita coba menggunakan codebase dari seri tutorial laravel sebelumnya dan setelah kita uji coba codebase masih berfungsi dengan baik. Ini artinya kita tidak perlu khawatir ketika masih mempelajari laravel versi sebelumnya, karena ilmunya masih bisa kita gunakan di Laravel 11 ini.

Selain codebase, terdapat perbedaan pada saat kita membuat project laravel 11 baru menggunakan composer, yaitu database default yang digunakan di laravel 11 ini adalah sqlite dan kita bisa lihat dari outputnya terdapat proses running command `artisan migrate` setelah proses create project laravel 11.

Demikian percobaan development CRUD App sederhana Laravel 11 ini. Terima kasih sudah mengikuti sampai akhir. 

## Selanjutnya gimana?{#next}
Di seri tutorial [Belajar Laravel 11](https://qadrlabs.com/series/belajar-laravel-11), kita akan coba explore beberapa hal lainnya di antaranya:
- [Menggunakan Database MySQL di laravel 11](https://qadrlabs.com/post/menggunakan-database-mysql-di-laravel-11)
- [Menggunakan Database MariaDB di laravel 11](https://qadrlabs.com/post/menggunakan-mariadb-di-laravel-11)
- [Browser Testing menggunakan Laravel Dusk](https://qadrlabs.com/post/percobaan-browser-testing-menggunakan-laravel-dusk)
- [Testing menggunakan Pest](https://qadrlabs.com/post/testing-menggunakan-pest)