---
title: "Install Starter Kit Alternatif Dengan Blade dan Bootstrap di laravel 12"
slug: "install-starter-kit-alternatif-dengan-blade-dan-bootstrap-di-laravel-12"
category: "Laravel"
date: "2025-03-09"
status: "published"
---

Seperti yang sudah kita bahas tentang [Laravel 12](https://qadrlabs.com/post/laravel-12) di beberapa artikel sebelumnya, kita dapat memilih opsi stack yang digunakan dari beberapa opsi stack yang tersedia seperti React, Vue dan livewire di Laravel Starter Kit baru. Untuk developer yang sudah berpengalaman hal ini dapat memudahkan dalam pengembangan aplikasi. Namun dari sudut pandang pemula yang baru belajar boleh jadi ini menjadi challenge yang harus dihadapi. Selain dari stack frontend yang digunakan, laravel juga kini menggunakan Tailwindcss dan hal ini boleh jadi membuat pemula yang terbiasa menggunakan bootstrap harus mempelajari tailwindcss terlebih dahulu. Oleh karena dalam tutorial ini kita akan mencoba menggunakan starter kit alternatif yang sudah memiliki auth scaffolding, ramah pemula, hanya menggunakan blade dan juga bootstrap.



## Overview {#overview}

Pada tutorial ini kita akan menggunakan Starter Kit alternatif dengan menginstall package Laravel UI. [Laravel UI](https://github.com/laravel/ui) merupakan package yang menyediakan simple authentication scaffolding. Package ini menggunakan bootstrap sebagai css framework dan juga masih menggunakan blade sehingga pemula dapat dengan mudah memodifikasi dan mengembangkan project tanpa harus mempelajari stack yang kompleks. 

Dalam tutorial ini kita akan coba setup laravel UI ini pada project Laravel 12. Dimulai dari install, generate auth scaffolding dengan bootstrap sebagai css, lalu coba run project. Di akhir tutorial ini kita mendapatkan starter kit alternatif dengan fitur login, register dan halaman home untuk user yang terdaftar.



![Halaman home untuk user](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-laravel-ui/4-tampilan-dashboard.png)

Tools yang akan kita gunakan pada tutorial ini:

1. `composer`.
2. `npm`, digunakan untuk install dependensi dan build asset frontend.

Sebelum kita mulai, kita cek terlebih dahulu. Pada saat tutorial ini disusun saya menggunakan PHP versi 8.2.

```
$ php -v
PHP 8.2.27 (cli) (built: Dec 24 2024 06:29:37) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.27, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.27, Copyright (c), by Zend Technologies
    with Xdebug v3.4.1, Copyright (c) 2002-2025, by Derick Rethans

```

Selain itu nodejs yang terinstall adalah versi `20.12.2`.

```
$ node -v
v20.12.2
```

Sedangkan `npm` yang saya gunakan adalah versi `10.5.0`.

```
$ npm -v
10.5.0
```

Setelah semuanya siap, teman-teman bisa mulai mengikuti tutorial ini.

## Step 1: Buat Project {#step-1-buat-project}

Pertama kita buat project baru menggunakan composer.

```
composer create-project --prefer-dist laravel/laravel:^12.0  laravel-12-bootstrap
```

Tunggu sampai project baru selesai dibuat.

## Step 2: Atur Konfigurasi {#step-2-atur-konfigurasi}

Selanjutnya kita masuk ke direktori project, yaitu `laravel-12-bootstrap`.

```
cd laravel-12-bootstrap
```

Kemudian kita buka project menggunakan visual studio code (atau code editor lain).

```
code .
```

Setelah command di atas kita run, project akan dibuka di code editor visual studio code.

Selanjutnya kita buka file `.env`, lalu kita sesuai app url dan konfigurasi database.

```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password
```

Save kembali file `.env`.

Setelah kita atur konfigurasi project, kita run migrate command.

```
php artisan migrate
```

Apabila database `db_belajar_laravel` belum kita buat, akan tampil prompt berikut ini.

```
$ php artisan migrate

   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘


```

Pilih `yes`, lalu tekan `enter` untuk melanjutkan.

## Step 3: Install Laravel UI {#step-3-install-laravel-ui}

Sekarang kita akan install package laravel UI. Untuk menginstall package tersebut, buka termina lalu run command berikut ini.

```
composer require laravel/ui
```

Tunggu sampai proses install package laravel ui selesai.

## Step 4: Generate Auth Scaffolding with Bootstrap {#step-4-generate-auth-scaffolding-with-bootstrap}

Setelah package terinstall, kita bisa generate auth scaffolding menggunakan `ui` command. 

```
php artisan ui bootstrap --auth
```

Selanjutnya akan tampil prompt untuk me-replace file `Controller.php`.

```
$ php artisan ui bootstrap --auth

  The [Controller.php] file already exists. Do you want to replace it? (yes/no) [yes]
❯ 

```

Ketik `yes`, lalu tekan `enter` untuk melanjutkan.

```
$ php artisan ui bootstrap --auth

  The [Controller.php] file already exists. Do you want to replace it? (yes/no) [yes]
❯ yes

   INFO  Authentication scaffolding generated successfully.  

   INFO  Bootstrap scaffolding installed successfully.  

   WARN  Please run [npm install && npm run dev] to compile your fresh scaffolding.  


```

Selanjutnya kita install dependensi frontend menggunakan `npm`.

```
npm install
```

**Catatan:** Karena kita akan menggunakan composer untuk run project, jadi proses build assets frontend ini kita skip dulu.

## Step 5: Run Project {#step-5-run-project}

Sekarang kita akan coba run project kita. Untuk run project kita akan gunakan command berikut ini.

```
composer run dev
```

Output:

```
$ composer run dev
> Composer\Config::disableProcessTimeout
> npx concurrently -c "#93c5fd,#c4b5fd,#fb7185,#fdba74" "php artisan serve" "php artisan queue:listen --tries=1" "php artisan pail --timeout=0" "npm run dev" --names=server,queue,logs,vite
[queue] 
[queue]    INFO  Processing jobs from the [default] queue.  
[queue] 
[logs] 
[logs]    INFO  Tailing application logs.                        Press Ctrl+C to exit  
[logs]                                                Use -v|-vv to show more details  
[vite] 
[vite] > dev
[vite] > vite
[vite] 
[vite] 
[vite]   VITE v6.2.1  ready in 190 ms
[vite] 
[vite]   ➜  Local:   http://localhost:5173/
[vite]   ➜  Network: use --host to expose
[vite] 
[vite]   LARAVEL v12.1.1  plugin v1.2.0
[vite] 
[vite]   ➜  APP_URL: http://127.0.0.1:8000
[server] 
[server]    INFO  Server running on [http://127.0.0.1:8000].  
[server] 
[server]   Press Ctrl+C to stop the server
[server] 


```

Seperti yang ditampilkan pada output pada terminal, kita run project dan juga run vite development secara bersamaan.



Selanjutnya kita akses `http://127.0.0.1:8000` di browser untuk run project kita. Ketika kita buka, akan tampil halaman awal laravel 12, lengkap dengan link login dan register.

![Halaman awal project laravel 12](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-laravel-ui/1-tampilan-awal.png)

Selanjutnya kita bisa buka halaman login dengan menekan link Login di kanan atas. Selanjutnya akan membuka halaman login.

![Halaman login project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-laravel-ui/2-tampilan-login.png)

Seperti yang terlihat pada screenshot di atas, tampilan halaman login dari package laravel ui menggunakan bootstrap. Kita bisa cek halaman ini dengan membuka file `resources/views/auth/login.blade.php`.

```
@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Login') }}</div>

                <div class="card-body">
                    <form method="POST" action="{{ route('login') }}">
                        @csrf

                        <div class="row mb-3">
                            <label for="email" class="col-md-4 col-form-label text-md-end">{{ __('Email Address') }}</label>

                            <div class="col-md-6">
                                <input id="email" type="email" class="form-control @error('email') is-invalid @enderror" name="email" value="{{ old('email') }}" required autocomplete="email" autofocus>

                                @error('email')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                @enderror
                            </div>
                        </div>

                        <div class="row mb-3">
                            <label for="password" class="col-md-4 col-form-label text-md-end">{{ __('Password') }}</label>

                            <div class="col-md-6">
                                <input id="password" type="password" class="form-control @error('password') is-invalid @enderror" name="password" required autocomplete="current-password">

                                @error('password')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                @enderror
                            </div>
                        </div>

                        <div class="row mb-3">
                            <div class="col-md-6 offset-md-4">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="remember" id="remember" {{ old('remember') ? 'checked' : '' }}>

                                    <label class="form-check-label" for="remember">
                                        {{ __('Remember Me') }}
                                    </label>
                                </div>
                            </div>
                        </div>

                        <div class="row mb-0">
                            <div class="col-md-8 offset-md-4">
                                <button type="submit" class="btn btn-primary">
                                    {{ __('Login') }}
                                </button>

                                @if (Route::has('password.request'))
                                    <a class="btn btn-link" href="{{ route('password.request') }}">
                                        {{ __('Forgot Your Password?') }}
                                    </a>
                                @endif
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

```

Seperti yang terlihat pada baris kode di atas, code untuk view halaman login menggunakan blade saja, tanpa stack yang kompleks. 

Selain itu kita bisa juga buka halaman layouts untuk project, yaitu file `resources/views/layouts/app.blade.php`.

```
<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Laravel') }}</title>

    <!-- Fonts -->
    <link rel="dns-prefetch" href="//fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=Nunito" rel="stylesheet">

    <!-- Scripts -->
    @vite(['resources/sass/app.scss', 'resources/js/app.js'])
</head>
<body>
    <div id="app">
        <nav class="navbar navbar-expand-md navbar-light bg-white shadow-sm">
            <div class="container">
                <a class="navbar-brand" href="{{ url('/') }}">
                    {{ config('app.name', 'Laravel') }}
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="{{ __('Toggle navigation') }}">
                    <span class="navbar-toggler-icon"></span>
                </button>

                <div class="collapse navbar-collapse" id="navbarSupportedContent">
                    <!-- Left Side Of Navbar -->
                    <ul class="navbar-nav me-auto">

                    </ul>

                    <!-- Right Side Of Navbar -->
                    <ul class="navbar-nav ms-auto">
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
                                <a id="navbarDropdown" class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false" v-pre>
                                    {{ Auth::user()->name }}
                                </a>

                                <div class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
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
</body>
</html>

```

Sama seperti halaman login, layout aplikasi pun menggunakan blade. Karena kita menggunakan vite, kita load css dan js menggunakan script berikut.

```
<!-- Scripts -->
@vite(['resources/sass/app.scss', 'resources/js/app.js'])
```

Kode `@vite(['resources/sass/app.scss', 'resources/js/app.js'])` adalah sintaks Blade (template engine Laravel) yang digunakan untuk mengintegrasikan aset statis (CSS/JS) yang dikelola oleh **Vite** ke dalam aplikasi Laravel.

Untuk css, di sini kita bisa lihat bootstrap di file `resources/sass/app.scss`.

```
// Fonts
@import url('https://fonts.bunny.net/css?family=Nunito');

// Variables
@import 'variables';

// Bootstrap
@import 'bootstrap/scss/bootstrap';

```

Sedangkan file `resources/js/app.js` berisi baris kode berikut.

```
import './bootstrap';

```

Baris kode di atas bukan untuk merujuk ke file `resources/js/bootstrap.js`.

```
import 'bootstrap'; // import library bootstrap js

// baris kode lainnya

```

Sedangkan pada file `resources/js/bootstrap.js` terdapat baris kode untuk Mengimpor library **Bootstrap CSS/JS** yang terdapat di direktori `node_modules`, yang merupakan kode javascript untuk Bootstrap CSS.



Selanjutnya kita akan cek halaman register. 

Karena kita belum membuat akun, kita bisa akses halaman register terlebih dahulu dengan menekan link Register.

![Halaman register project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-laravel-ui/3-tampilan-register.png)

Sama halnya dengan halaman login, halaman register pun hanya menggunakan blade. Kita bisa cek kode di file `resources/views/auth/register.blade.php`.

```
@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Register') }}</div>

                <div class="card-body">
                    <form method="POST" action="{{ route('register') }}">
                        @csrf

                        <div class="row mb-3">
                            <label for="name" class="col-md-4 col-form-label text-md-end">{{ __('Name') }}</label>

                            <div class="col-md-6">
                                <input id="name" type="text" class="form-control @error('name') is-invalid @enderror" name="name" value="{{ old('name') }}" required autocomplete="name" autofocus>

                                @error('name')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                @enderror
                            </div>
                        </div>

                        <div class="row mb-3">
                            <label for="email" class="col-md-4 col-form-label text-md-end">{{ __('Email Address') }}</label>

                            <div class="col-md-6">
                                <input id="email" type="email" class="form-control @error('email') is-invalid @enderror" name="email" value="{{ old('email') }}" required autocomplete="email">

                                @error('email')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                @enderror
                            </div>
                        </div>

                        <div class="row mb-3">
                            <label for="password" class="col-md-4 col-form-label text-md-end">{{ __('Password') }}</label>

                            <div class="col-md-6">
                                <input id="password" type="password" class="form-control @error('password') is-invalid @enderror" name="password" required autocomplete="new-password">

                                @error('password')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                @enderror
                            </div>
                        </div>

                        <div class="row mb-3">
                            <label for="password-confirm" class="col-md-4 col-form-label text-md-end">{{ __('Confirm Password') }}</label>

                            <div class="col-md-6">
                                <input id="password-confirm" type="password" class="form-control" name="password_confirmation" required autocomplete="new-password">
                            </div>
                        </div>

                        <div class="row mb-0">
                            <div class="col-md-6 offset-md-4">
                                <button type="submit" class="btn btn-primary">
                                    {{ __('Register') }}
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

```

Selanjutnya kita bisa coba isi form register untuk membuat akun baru. Dan setelah kita berhasil daftar, kita akan diarahkan ke halaman Home untuk user.

![Halaman home project](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-12-with-laravel-ui/4-tampilan-dashboard.png)

Untuk kode halaman home, kita bisa cek di file `resources/views/home.blade.php`.

```
@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Dashboard') }}</div>

                <div class="card-body">
                    @if (session('status'))
                        <div class="alert alert-success" role="alert">
                            {{ session('status') }}
                        </div>
                    @endif

                    {{ __('You are logged in!') }}
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

```



## Penutup {#penutup}

Tutorial ini telah memperlihatkan cara mengimplementasikan starter kit alternatif di Laravel 12 menggunakan Laravel UI dengan Blade dan Bootstrap. Pendekatan ini sangat bermanfaat bagi pemula yang belum familiar dengan Tailwind CSS atau framework JavaScript modern seperti React dan Vue.

Dengan menggunakan Laravel UI, kita mendapatkan authentication scaffolding yang lengkap dengan tampilan responsif berbasis Bootstrap CSS, meliputi halaman login, register, dan dashboard. Ini memberikan fondasi yang solid untuk memulai pengembangan aplikasi Laravel tanpa perlu mempelajari teknologi baru sekaligus.

Meskipun Laravel kini lebih condong pada Tailwind CSS dan framework JavaScript modern dalam starter kit defaultnya, opsi menggunakan Blade dan Bootstrap tetap relevan terutama untuk proyek-proyek yang membutuhkan pendekatan yang lebih sederhana atau bagi tim yang sudah terbiasa dengan Bootstrap.

Setelah menguasai dasar-dasar Laravel dengan Blade dan Bootstrap, Anda dapat secara bertahap memperluas pengetahuan dan mencoba teknologi frontend lainnya sesuai kebutuhan proyek di masa mendatang. Starter kit alternatif ini membuktikan fleksibilitas Laravel yang tetap memungkinkan pengembang menggunakan tools yang paling sesuai dengan kebutuhan mereka.