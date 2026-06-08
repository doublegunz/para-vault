---
title: "Tutorial Laravel 11: Membuat fitur Login With Google menggunakan Laravel Socialite"
slug: "membuat-fiitur-login-with-google-menggunakan-laravel-socialite"
category: "Laravel"
date: "2024-03-17"
status: "published"
---

Salah satu cara untuk memudahkan user login ke dalam aplikasi yang kita kembangkan adalah dengan menambahkan opsi login menggunakan platform media sosial, seperti facebook, google, github dan lainnya. Untuk menambahkan fitur ini, framework laravel sendiri memiliki package yang menangani autentikasi sosial menggunakan Oauth provider, yaitu Laravel Socialite. Pada tutorial Laravel 11 ini kita akan coba salah satu Oauth Provider, yaitu Google, untuk login ke dalam aplikasi menggunakan Laravel Socialite.

## Apa itu Laravel Socialite?{#apa-itu-laravel-socialite}
[Laravel Socialite](https://github.com/laravel/socialite) adalah package yang dapat kita gunakan untuk mengintegrasikan Oauth ke dalam aplikasi yang kita bangun menggunakan laravel. Laravel Socialite menyediakan antarmuka yang ekspresif dan lancar untuk otentikasi OAuth dengan Facebook, Twitter, Google, LinkedIn, GitHub, GitLab, dan Bitbucket. Selain adaptor yang secara resmi disediakan, adaptor untuk platform lain tersedia melalui situs web [Socialite Providers](https://socialiteproviders.com/) yang digerakkan oleh komunitas.

## Overview{#overview}
Pada edisi tutorial laravel 11 ini kita akan coba menambahkan fitur Login With Google menggunakan Laravel Socialite. Untuk studi kasus login, tentu kita perlu halaman lain, misalnya halaman dashboard yang diakses setelah kita berhasil login. Oleh karena itu kita juga akan gunakan salah satu starter kit laravel untuk menangani hal ini, yaitu [Laravel Jetstream](https://jetstream.laravel.com/introduction.html). 

Jadi pada tutorial kali ini kita gunakan starter kit yang kita generate menggunakan Laravel Jetstream. Selanjutnya kita tambahkan button Login With Google di halaman login.

Goal dari tutorial kali ini cukup sederhana yaitu kita bisa login menggunakan akun google kita.

## Persiapan{#persiapan}
Karena kita akan menggunakan google sebagai oauth provider, tentu kita perlu persiapan terlebih dahulu untuk mendapatkan client id dan client secret yang nantinya kita gunakan untuk pengaturan Laravel Socialite.

Untuk membuat oauth client, buka halaman https://console.cloud.google.com/apis/dashboard lalu pilih menu **Credentials**.

![access google developer console](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/01-access-google-developer-console.png)


Pada halaman Credentials, tekan button **Create Credentials**, lalu pilih sub menu  **Oauth client ID.**
![access halaman create oauth client id](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/02-access-halaman-create-credentials-oauth.png)

Pada halaman Create OAuth client ID, pilih **Web Application** pada field Application type, lalu isi nama project (Sebagai contoh: Web Client 2), lalu tambahkan Authorized redirect URIs (contoh: `http://127.0.0.1:8000/oauth/google/callback`). Setelah isian lengkap, click button **Create**.
![create oauth client id](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/03-create-oauth-client-id.png)


Setelah selesai akan ditampilan client ID dan client secret.

![Get client id dan secret ](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/04-get-client-id-dan-secret.png)

Simpan terlebih dahulu Client ID dan Client Secret. Client ID dan Client secret ini nanti kita gunakan untuk setup socialite.

## Step 1 - Create Project Laravel{#step-1-create-project-laravel}
Sekarang kita buat project laravel baru menggunakan `composer`. Buka terminal, lalu run command berikut ini untuk membuat project laravel baru.
```
composer create-project laravel/laravel:^11.0 login-with-google-example
```

Tunggu sampai proses selesai.
## Step 2 - Setup Konfigurasi Database{#step-2-setup-konfigurasi-database}
Setelah selesai membuat project baru, buka project di code editor (misalnya visual studio code). Lalu buka file `.env`, lalu kita atur konfigurasi databasenya.
```
DB_CONNECTION=mysql  
DB_HOST=127.0.0.1  
DB_PORT=3306  
DB_DATABASE=db_belajar  
DB_USERNAME=root  
DB_PASSWORD=password
```

Setelah selesai, save kembali file `.env`.

Jangan lupa buat juga database sesuai dengan nama database yang ditulis di file `.env`. Sebagai contoh di sini saya membuat database `db_belajar`.

## Step 3 - Menambahkan package Laravel Jetstream {#step-3-add-jetstream}
Seperti yang sudah disebutkan sebelumnya, kita akan menggunakan salah satu starter kit dari laravel, yaitu laravel jetstream.

Buka kembali terminal, lalu run command berikut ini untuk menambahkan package Laravel Jetstream.
```
composer require laravel/jetstream
```

Setelah selesai, kita install laravel jetstream menggunakan command berikut ini.
```
php artisan jetstream:install livewire
```

Tunggu sampai proses install dan build selesai. Setelah proses build selesai, tampil output berikut ini.

```
vite v5.1.6 building for production...
✓ 47 modules transformed.
public/build/manifest.json             0.26 kB │ gzip:  0.13 kB
public/build/assets/app-D86C2c9c.css  54.90 kB │ gzip:  9.19 kB
public/build/assets/app-CifqVuM1.js   29.83 kB │ gzip: 11.98 kB
✓ built in 1.12s


 ┌ New database migrations were added. Would you like to re-run your migrati… ┐
 │ Yes                                                                        │
 └────────────────────────────────────────────────────────────────────────────┘
```
Pilih yes untuk re-run `migrate` command.

## Step 4 - Setting Socialite{#step-4-setting-socialite}
Pada tahapan ini kita akan tambahkan package Laravel Socialite ke dalam project kita. Buka kembali terminal, lalu kita tambahkan package laravel socialite menggunakan composer.
```
composer require laravel/socialite
```

Setelah kita tambahkan laravel socialite, selanjutnya buka file konfigurasi `bootstrap/providers.php`, lalu tambahkan laravel socialite.

```
<?php

return [
    App\Providers\AppServiceProvider::class,
    App\Providers\FortifyServiceProvider::class,
    App\Providers\JetstreamServiceProvider::class,
    Laravel\Socialite\SocialiteServiceProvider::class, // tambahkan ini
];

```

Selanjutnya buka file konfigurasi `config/services.php`, lalu tambahkan baris kode berikut ini untuk menambahkan credentials oauth provider dari google.

```
<?php

return [

    // BARIS KODE LAINNYA....

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URI'),
    ],
];

```

Sekarang kita buka kembali file `.env`, lalu tambahkan baris kode berikut ini dan sesuaikan valuenya dengan client id dan client secret yang sebelumnya sudah kita dapatkan di step sebelumnya (Bagian Persiapan).
```
GOOGLE_CLIENT_ID=google-client-id-kamu  
GOOGLE_CLIENT_SECRET=google-client-secret-kamu  
GOOGLE_REDIRECT_URI=http://127.0.0.1:8000/oauth/google/callback
```

## Step 5 - Menambahkan field baru di table users{#step-5-add-field-di-table-users}
Untuk menyimpan data oauth provider dari google, kita perlu menambahkan field baru ke dalam table `users`.

Untuk menambahkan field baru di table `users`, buka terminal, lalu run command berikut ini.
```
php artisan make:migration google_social_auth_id --table=users

```
Output yang ditampilkan:
```
   INFO  Migration [database/migrations/2024_01_09_071503_google_social_auth_id.php] created successfully. 

```

Selanjutnya buka file migration yang sudah kita generate, lalu sesuaikan menjadi baris kode berikut ini.
```
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('gauth_id')->nullable();
            $table->string('gauth_type')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('gauth_id');
            $table->dropColumn('gauth_type');
        });
    }
};

```

Pada baris kode di atas, kita menambahkan `gauth_id` dan `gauth_type` ke dalam table `users`.

Selanjutnya kita run migrate di terminal.
```
php artisan migrate
```
Output:
```
  INFO  Running migrations.  

  2014_10_12_000000_create_users_table ............................. 13ms DONE
  2014_10_12_100000_create_password_reset_tokens_table .............. 6ms DONE
  2014_10_12_200000_add_two_factor_columns_to_users_table .......... 10ms DONE
  2019_08_19_000000_create_failed_jobs_table ....................... 21ms DONE
  2019_12_14_000001_create_personal_access_tokens_table ............ 30ms DONE
  2024_01_09_070536_create_sessions_table .......................... 30ms DONE
  2024_01_09_071503_google_social_auth_id .......................... 11ms DONE

```

Karena kita menambahkan field baru, kita perlu sesuaikan mass assignment yang dijinkan ketika mebuat user baru. Sekarang kita buka file `app/Models/User.php`, lalu sesuaikan property `$fillable`.
```
<?php

// baris kode lainnya

class User extends Authenticatable
{
    
    // baris kode lainnya

    protected $fillable = [
        'name',
        'email',
        'password',
        'gauth_id', // tambahkan ini
        'gauth_type', // tambahkan ini
    ];

    // baris kode lainnya
}

```

Jangan lupa save kembali file `app/Models/User.php`.

## Step 6 - Buat Controller Baru{#step-6-create-new-controller}
Sekarang kita buat controller baru untuk menangani proses autentikasi menggunakan oauth provider. Buka kembali terminal, lalu run command berikut ini.
```
php artisan make:controller OauthController
```
Output:
```
 INFO  Controller [app/Http/Controllers/OauthController.php] created successfully.  
```

Untuk mengautentikasi pengguna menggunakan OAuth provider, kita memerlukan dua `method`: satu untuk mengarahkan pengguna ke OAuth provider, dan satu lagi untuk menerima callback dari provider setelah autentikasi. 

Sekarang kita buka `app/Http/Controllers/OauthController.php`, lalu kita tambahkan dua method baru.

```
<?php

namespace App\Http\Controllers;

use Auth;
use Laravel\Socialite\Facades\Socialite;
use Exception;
use App\Models\User;

class OauthController extends Controller
{
    public function redirectToProvider()
    {
        return Socialite::driver('google')->redirect();
    }
    public function handleProviderCallback()
    {
        try {

            $user = Socialite::driver('google')->user();

            $finduser = User::where('gauth_id', $user->id)->first();

            if($finduser){

                Auth::login($finduser);

                return redirect('/dashboard');

            }else{
                $newUser = User::create([
                    'name' => $user->name,
                    'email' => $user->email,
                    'gauth_id'=> $user->id,
                    'gauth_type'=> 'google',
                    'password' => encrypt('admin@123')
                ]);

                Auth::login($newUser);

                return redirect('/dashboard');
            }

        } catch (Exception $e) {
            dd($e->getMessage());
        }
    }
}


```

Setelah selesai save kembali file `app/Http/Controllers/OauthController.php`.
## Step 7 - Register Route Baru{#step-7-register-route}
Pada tahapan ini kita tambahkan route baru di file `routes/web.php`. Buka file `routes/web.php`, lalu kita tambahkan dua route baru untuk mengarahkan pengguna ke OAuth provider, dan route untuk menerima callback dari provider setelah autentikasi. 
```
Route::get('oauth/google', [\App\Http\Controllers\OauthController::class, 'redirectToProvider'])->name('oauth.google');  
Route::get('oauth/google/callback', [\App\Http\Controllers\OauthController::class, 'handleProviderCallback'])->name('oauth.google.callback');
```

Setelah selesai, save kembali file `routes/web.php`.

## Step 8 - Modifikasi View Halaman Login{#step-8-modifikasi-view-halaman-login}
Seperti yang sudah disebutkan sebelumnya, kita akan menambahkan button **Login with Google** di halaman login.

Sekarang kita buka file `resources/views/auth/login.blade.php`, lalu temukan tombol login berikut ini.

```
<x-button class="ms-4">  
    {{ __('Log in') }}  
</x-button>
```

Tepat di bawah tombol login, tambahkan button login with google.
```
<x-button class="ms-4">  
    {{ __('Log in') }}  
</x-button>  
  
<!-- TAMBAHKAN BUTTON LOGIN WITH GOOGLE-->  
<a href="{{ route('oauth.google') }}" style="margin-top: 0px !important;background: #C84130;color: #ffffff;padding: 8px;border-radius:6px;" class="items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white text-center uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150 ms-4">  
    <strong>Login with Google</strong>  
</a>  
<!-- END OF BUTTON LOGIN WITH GOOGLE-->
```

Sehingga keseluruhan file `resources/views/auth/login.blade.php` menjadi seperti berikut ini.
```
<x-guest-layout>
    <x-authentication-card>
        <x-slot name="logo">
            <x-authentication-card-logo />
        </x-slot>

        <x-validation-errors class="mb-4" />

        @if (session('status'))
            <div class="mb-4 font-medium text-sm text-green-600">
                {{ session('status') }}
            </div>
        @endif

        <form method="POST" action="{{ route('login') }}">
            @csrf

            <div>
                <x-label for="email" value="{{ __('Email') }}" />
                <x-input id="email" class="block mt-1 w-full" type="email" name="email" :value="old('email')" required autofocus autocomplete="username" />
            </div>

            <div class="mt-4">
                <x-label for="password" value="{{ __('Password') }}" />
                <x-input id="password" class="block mt-1 w-full" type="password" name="password" required autocomplete="current-password" />
            </div>

            <div class="block mt-4">
                <label for="remember_me" class="flex items-center">
                    <x-checkbox id="remember_me" name="remember" />
                    <span class="ms-2 text-sm text-gray-600">{{ __('Remember me') }}</span>
                </label>
            </div>

            <div class="flex items-center justify-end mt-4">
                @if (Route::has('password.request'))
                    <a class="underline text-sm text-gray-600 hover:text-gray-900 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" href="{{ route('password.request') }}">
                        {{ __('Forgot your password?') }}
                    </a>
                @endif

                <x-button class="ms-4">
                    {{ __('Log in') }}
                </x-button>
                    
                <!-- TAMBAHKAN BUTTON LOGIN WITH GOOGLE-->
                <a href="{{ route('oauth.google') }}" style="margin-top: 0px !important;background: #C84130;color: #ffffff;padding: 8px;border-radius:6px;" class="items-center px-4 py-2 bg-gray-800 border border-transparent rounded-md font-semibold text-xs text-white text-center uppercase tracking-widest hover:bg-gray-700 focus:bg-gray-700 active:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition ease-in-out duration-150 ms-4">
                    <strong>Login with Google</strong>
                </a>
                <!-- END OF BUTTON LOGIN WITH GOOGLE-->

            </div>
        </form>
    </x-authentication-card>
</x-guest-layout>

```

Jangan lupa save kembali file `resources/views/auth/login.blade.php`.

## Step 9 - Uji Coba{#step-9-uji-coba}
Setelah proses coding project kita selesai, seperti biasa kita akan uji coba project login with google menggunakan laravel socialite.

Untuk menguji coba, kita run terlebih dahulu project kita.
```
php artisan serve
```

Kemudian kita akses halaman login `http://127.0.0.1:8000/login`. Pada halaman login kita bisa lihat ada button LOGIN WITH GOOGLE.

![Akses halaman login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/05-run-project.png)

Kita coba klik button LOGIN WITH GOOGLE. Selanjutnya kita login pakai akun gmail dan selanjutnya kita akan dialihkan ke halaman dashboard.

![login berhasil](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/login-with-google-laravel-socialite/06-login-success.png)

## Penutup{#penutup}
Pada edisi tutorial laravel 11 ini kita sudah coba menambahkan fitur login with google menggunakan Laravel Socialite. Dan kita bisa menarik kesimpulan, Laravel socialite ini memudahkan integrasi dengan oauth provider, dengan proses konfigurasi yang mudah, dan proses mendapatkan data user pun mudah. Selain menggunakan google, kita juga dapat menggunakan oauth provider lainnya, misalnya  Facebook, Twitter, LinkedIn, GitHub, GitLab, Bitbucket, Slack atau provider yang didukung komunitas.

**Update:**
Tutorial ini telah diujicoba kembali menggunakan laravel 12 per tanggal 21 September 2025.