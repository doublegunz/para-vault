---
title: "REST API Authentication With Laravel Sanctum"
slug: "rest-api-authentication-with-laravel-sanctum"
category: "Laravel"
date: "2022-06-03"
status: "published"
---

Halo, pada tutorial Laravel kali ini kita akan membahas bagaimana caranya membuat token based authentication untuk rest api menggunakan Laravel Sanctum. [Laravel Sanctum](https://laravel.com/docs/12.x/sanctum#introduction) merupakan sebuah package yang menyediakan sistem authentication yang ringan untuk SPA (Single Page Application), mobile application, dan simple token based API. 

Dengan menggunakan Sanctum, setiap user aplikasi yang kita kembangkan dapat menggenerate multiple API token untuk akun mereka. Token ini nantinya dapat kita atur dan sesuaikan scopenya untuk proses apa saja yang diijinkan ketika menggunakan token tersebut.

Pada Laravel Sanctum terdapat dua solusi yang dapat digunakan untuk kasus yang berbeda, yaitu API Token dan SPA Authentication. Pada tutorial REST API Authentication ini kita akan menggunakan solusi yang pertama, yaitu API token.

## REST API Authentication With Laravel Sanctum{#table-of-content}

- [Overview](#Overview)
- [Persiapan](#Persiapan)
- [Step 1 - Setup Project](#step-1)
- [Step 2 - Setup Laravel Sanctum Package](#step-2)
- [Step 3 - Create AuthController](#step-3)
- [Step 4 - Definisikan Route](#step-4)
- [Step 5 - Uji Coba](#step-5)
- [Uji Coba Register](#uji-coba-1)
- [Uji Coba Login](#uji-coba-2)
- [Uji Coba Get Data User](#uji-coba-3)
- [Uji Coba Logout](#uji-coba-4)
- [Penutup](#penutup)

## Overview{#Overview}

Pada tutorial REST Api Authentication dengan Laravel Sanctum ini kita akan membuat project sederhana yang menyediakan API endpoint untuk proses register, login, logout dan get data. Pada saat user mengirimkan HTTP Request untuk proses register dan login, sistem akan melakukan proses generate api token. API Token ini nanti akan digunakan untuk proses ambil data user dan juga proses logout.

**Catatan:**
Awalnya tutorial ini disusun dan diujicoba menggunakan laravel 11. Per tanggal 5 Maret 2025, tutorial ini telah diuji coba menggunakan framework [laravel versi 12](https://qadrlabs.com/post/laravel-12).

## Persiapan{#Persiapan}

Sebelum kita mulai, ada tools yang harus kita siapkan terlebih dahulu, yaitu `Postman`. Kita bisa download terlebih dahulu di situs resminnya pada halaman [download](https://www.postman.com/downloads/). Postman ini nanti kita gunakan untuk uji coba Api.

## Step 1 - Setup Project{#step-1}

Install Project Laravel baru menggunakan `composer`.

```
composer create-project --prefer-dist laravel/laravel laravel-sanctum
```

Setelah itu masuk ke direktori project

```
cd laravel-sanctum
```

Buka project menggunakan text editor. Kalau kita pakai visual studio code, kita bisa buka project di visual studio code menggunakan command.

```
code .
```

Setelah itu kita atur konfigurasi database dengan memodifikasi file `.env`.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_api
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

## Step 2 - Setup Laravel Sanctum Package{#step-2}

Versi Laravel pada saat tutorial ini diupdate adalah Laravel versi 11. Pada laravel 11 kita bisa install laravel sanctum dengan run command berikut ini.

```
php artisan install:api
```

Tunggu sampai proses install selesai.

Diakhir proses install, tampil prompt untuk run database migration.

```
One new database migration has been published. Would you like to run all pending database migrations? (yes/no) [yes]:
```

Ketik yes, lalu tekan enter untuk run database migrations.

Apabila database `db_belajar_api` belum kita buat, tampil warning di output terminal.

```
   WARN  The database 'db_belajar_api' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Tekan enter untuk melanjutkan.

```
   WARN  The database 'db_belajar_api' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ........................ 25.71ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ........... 112.94ms DONE
  0001_01_01_000001_create_cache_table ............ 40.82ms DONE
  0001_01_01_000002_create_jobs_table ............ 106.98ms DONE
  2024_05_01_093705_create_personal_access_tokens_table  64.68ms DONE


   INFO  API scaffolding installed. Please add the [Laravel\Sanctum\HasApiTokens] trait to your User model.  

```

Selanjutnya buka file `app/Models/User.php`

Lalu kita tambahkan trait `Laravel\Sanctum\HasApiTokens`.

```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // tambahkan kode ini

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens; // tambahkan kode ini

    // baris kode lainnya
}
```




## Step 3 - Create AuthController{#step-3}

Pada step 3 ini kita akan membuat controller yang akan menangani proses `register`, `login` dan `logout` melalui `api`. Buka kembali terminal, lalu run command berikut ini.

```
php artisan make:controller Api/AuthController
```

Setelah command kita run, kita bisa lihat ada file baru yaitu `AuthController.php` di direktori `app/Http/Controllers/Api`. Buka file `AuthController.php`, lalu kita tambahkan method `register()`, `login()`, dan `logout()`.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|max:255|unique:users',
            'password' => 'required|string|min:8'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors());
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password)
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'data' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]);
    }

    public function login(Request $request)
    {
        if (! Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'message' => 'Unauthorized'
            ], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login success',
            'access_token' => $token,
            'token_type' => 'Bearer'
        ]);
    }

    public function logout()
    {
        Auth::user()->tokens()->delete();
        return response()->json([
            'message' => 'logout success'
        ]);
    }
}

```

Save kembali file `AuthController.php`.

## Step 4 - Definisikan Route{#step-4}

Langkah berikutnya adalah mendefinisikan route. Berbeda dengan tutorial biasanya, karena tutorial ini tentang api, jadi kita definisikan route di file `routes/api.php`. Buka file `routes/api.php`, lalu kita tambahkan route untuk `register`, `login` dan juga `logout`.

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::post('/register', [\App\Http\Controllers\Api\AuthController::class, 'register']);
Route::post('/login', [\App\Http\Controllers\Api\AuthController::class, 'login']);

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
});

```


## Step 5 - Uji Coba{#step-5}

Untuk menguji coba, pertama kita run terlebih dahulu project kita. Buka terminal, lalu run command berikut ini.

```
php artisan serve
```

Setelah itu buka `postman` yang sebelumnya sudah kita siapkan.

### Uji Coba Register{#uji-coba-1}

Untuk menguji fitur register, kita tambahkan POST request di dalam postman. Kita atur terlebih dahulu, method request, url dan data yang akan kita kirim.

1. Pada menu `HTTP request method` kita pilih `POST`,
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/register`, 
3. Pada tab `Body`, kita pilih radio button `form-data`, lalu kita coba masukan sample data `name`, `email` dan `password`, setelah itu kita klik tombol `Send` untuk mengirim POST request.

![Uji Coba Register - setup postman](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/auth-laravel-sanctum/uji-coba-register-1.webp)

![Uji Coba Register - response](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/auth-laravel-sanctum/uji-coba-register-2.webp)

Bisa kita lihat pada gambar di atas, setelah kita kirim POST request terdapat response yang berisi data user, token dan juga token type di panel bawah.

```
{
    "data": {
        "name": "admin",
        "email": "admin@example.com",
        "updated_at": "2022-06-03T02:15:47.000000Z",
        "created_at": "2022-06-03T02:15:47.000000Z",
        "id": 1
    },
    "access_token": "1|0dMRsY6B0EZ92Ij0NZgas0vdAWctMxXtaBEneit2",
    "token_type": "Bearer"
}
```

### Uji Coba Login{#uji-coba-2}

Selanjutnya kita coba proses login, buka kembali postman, lalu kita sesuaikan seperti berikut ini.

1. Pada menu `HTTP request method` kita pilih `POST`,
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/login`, 
3. Pada tab `Body`, kita pilih radio button `form-data`, lalu kita coba masukan sample data `email` dan `password` sesuai dengan yang sudah kita masukan pada saat uji coba register, setelah itu kita klik tombol `Send` untuk mengirim POST request.
   Kurang lebih outputnya seperti di gambar di bawah ini.

![Uji Coba Login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/auth-laravel-sanctum/uji-coba-login-1.webp)

Bisa kita lihat di dalam response terdapat `access_token`.

```
{
    "message": "Login success",
    "access_token": "3|0aJtSOd537OiHyPm1LY9zWw2FLMOonhGHLT3VnMW",
    "token_type": "Bearer"
}
```

Kita catat dulu token tersebut, bisa kita copy dulu ke text editor. Token ini nanti akan kita coba gunakan untuk uji coba ambil data user dan logout.

### Uji Coba Get Data User{#uji-coba-3}

Kalau kita cek kembali di file `routes/api.php`, route untuk ambil data user itu terdapat middleware `auth:sanctum`. Jadi kita perlu memasukan token yang sebelumnya kita dapatkan pada saat uji coba login. Sekarang kita buka kembali postman, lalu kita sesuaikan pengaturannya.

1. Pada menu `HTTP request method` kita pilih `GET`,
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/user`, 
3. Sekarang buka tab `Authorization`, pilih type `Bearer Token`, dan masukan token yang sebelumnya kita dapat pada uji coba login.

Setelah itu kita kirim GET Request dengan menekan tombol `Send`. Kurang lebih tampilan outputnya seperti gambar di bawah ini.

![Uji Coba Get Data User](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/auth-laravel-sanctum/uji-coba-get-data-1.webp)

Pada response yang dikirimkan server, kita bisa lihat datanya sesuai dengan data user yang login.

### Uji Coba Logout{#uji-coba-4}

Sama seperti pada saat kita ambil data user, asumsinya kita sedang dalam keadaan login dan di route untuk logout terdapat `auth:sanctum`. Jadi untuk uji coba logout, kita perlu memasukan token juga. Sekarang kita buka kembali postman, lalu kita sesuaikan pengaturannya.

1. Pada menu `HTTP request method` kita pilih `POST`,
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/logout`, 
3. Sekarang buka tab `Authorization`, pilih type `Bearer Token`, dan masukan token yang sebelumnya kita dapat pada uji coba login.

Setelah itu kita kirim POST request dengan menekan tombol `Send`. Kurang lebih outputnya seperti pada gambar di bawah ini.

![Uji Coba Logout](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/auth-laravel-sanctum/uji-coba-logout-1.webp)

## Penutup{#penutup}

Pada tutorial Laravel kali ini kita sudah belajar bagaimana membuat sebuah project yang menyediakan api endpoint untuk proses register, login, logout, dan get data user menggunakan package Laravel Sanctum. Dengan menggunakan package Laravel Sanctum ini, kita bisa generate api token yang nantinya digunakan pada saat user sudah dalam keadaan login. Dalam tutorial ini kita sudah coba untuk menggunakan API Token untuk proses ambil data user, di mana token ini kita dapatkan pada saat mengirimkan request login. Selain itu kita juga coba gunakan token ini untuk proses logout dan kalau kita coba cek di phpmyadmin, token terhapus setelah proses logout.

Selanjutnya bagaimana? Karena baru pertama kali menggunakan Laravel Sanctum, tentu ada banyak hal yang bisa kita coba dan kita kembangkan, terutama hal yang sebelumnya saya sebutkan terkait ability atau scope. Jadi kita bisa mengatur api token untuk melakukan proses tertentu yang sebelumnya kita definisikan.