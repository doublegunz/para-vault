---
title: "Tutorial Laravel 11: Browser Testing Menggunakan Laravel Dusk"
slug: "percobaan-browser-testing-menggunakan-laravel-dusk"
category: "Laravel"
date: "2024-03-01"
status: "published"
---

Halo, di edisi tutorial laravel 11 kali ini kita akan kembali membahas tentang testing. Pada [tutorial testing crud feature](https://qadrlabs.com/post/belajar-laravel-8-testing-crud-feature) sebelumnya kita sudah membahas bagaimana cara melakukan testing menggunakan PHPUnit dan Laravel BrowserKit Testing. Berdasarkan tutorial tersebut saya coba eksplore lebih lanjut di real project dan testing dapat berjalan dengan baik. Namun ada sisi yang tidak dapat kita testing ketika menggunakan kedua tools tersebut. Salah satunya adalah testing fungsionalitas aplikasi yang ada javascript di client side. Oleh karena itu saya coba gunakan tools berbeda untuk melakukan **browser testing aplikasi yang didevelop menggunakan laravel 11 yaitu Laravel Dusk**.

## Apa itu Laravel Dusk?{#apa-itu-laravel-dusk}
Berdasarkan dokumentasi resmi laravel 11, [Laravel Dusk](https://laravel.com/docs/11.x/dusk#introduction) merupakan tools yang menyediakan browser automation dan testing API yang mudah digunakan. Secara default, Dusk tidak mengharuskan kita untuk menginstall JDK di komputer lokal. Sebagai gantinya, Dusk menggunakan instalasi ChromeDriver mandiri. Sebagai alternatif, kita juga bebas menggunakan driver lain.

Dengan menggunakan Laravel Dusk, kita dapat melakukan simulasi apa yang akan dilakukan oleh user. Misalnya pada saat melakukan register di project kita, user akan masuk ke halaman register, lalu user mengisi isian pada form register, setelah itu user klik button Register dan apabila berhasil browser akan menampilkan halaman home atau dashboard. Dengan menggunakan laravel dusk, kita tuliskan skenario apa yang akan dilakukan oleh user pada saat register dan kemudian kita run laravel dusk untuk memulai browser testing.

## Overview{#overview}
Pada tutorial Laravel 11 kali ini kita akan coba gunakan Laravel Dusk untuk browser testing. Sebagai studi kasus, di tutorial kali ini kita akan coba testing fitur register dan fitur login.

Karena fokus kita di tutorial ini adalah browser testing menggunakan laravel dusk, jadi kita tidak akan coding fitur register dan login. Sebagai gantinya, kita gunakan [Laravel Breeze](https://laravel.com/docs/11.x/starter-kits#laravel-breeze) untuk generate fitur register dan fitur login di project kita.

Goal akhir tutorial ini adalah untuk mengetahui apakah kita bisa testing fitur register dan login sesuai dengan skenario testing.

## Persiapan{#persiapan}
Selain requirement untuk proses install laravel, ada persiapan yang harus teman-teman siapkan sebelum mengikuti tutorial ini yaitu menginstall node js dan NPM. NPM ini nanti kita gunakan untuk build assets dari Laravel Breeze. Apabila teman-teman belum install, bisa coba mengikuti tutorial [install multiple node js version menggunakan NVM](https://qadrlabs.com/post/cara-install-multiple-node-js-version-menggunakan-nvm-di-ubuntu-22-04)

Sekarang saya cek dulu versi node js yang saya gunakan di tutorial kali ini.
```
node -v
```
Output di terminal
```
v18.18.2
```

NPM langsung terinstall ketika kita install Nodejs. Sekarang saya cek versi NPM yang saya gunakan.
```
npm -v
```
Output di terminal:
```
9.8.1
```

Selain itu, karena kita menggunakan Laravel 11 dan minimum versi yang bisa digunakan adalah php 8.2, kita perlu cek versi php terlebih dahulu.
```
php -v
```
Output di terminal:
```
PHP 8.2.16 (cli) (built: Mar  7 2024 08:55:56) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.2.16, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.16, Copyright (c), by Zend Technologies
```

## Step 1 - Create Project Baru{#step-1}
Buka terminal lalu kita run command berikut ini untuk membuat project baru menggunakan composer.
```
composer create-project laravel/laravel:^11.0 laravel-dusk-testing-example
```
Tunggu sampai proses create project selesai.

## Step 2 - Install Laravel Dusk{#step-2}
Sekarang kita coba install Laravel dusk di project kita. Untuk menginstall laravel dusk, kita pindah dulu ke direktori project.
```
cd laravel-dusk-testing-example
```

Lalu kita install package laravel dusk menggunakan composer.
```
composer require laravel/dusk --dev
```

Setelah package terinstall, run command berikut.
```
php artisan dusk:install
```

Output:
```
Dusk scaffolding installed successfully.
Downloading ChromeDriver binaries...
ChromeDriver binary successfully installed for version 122.0.6261.69
```

Seperti yang tertulis di output di atas, command di atas generate Dusk scaffolding yang diantaranya termasuk membuat direktori `tests/Browser`, contoh testing menggunakan laravel Dusk dan install driver chrome ke OS kita.

Selanjutnya kita atur konfigurasi `APP_URL` dan juga database di file `.env`.
```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mariadb
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_testing
DB_USERNAME=root
DB_PASSWORD=password
```

**Catatan:**
1. `APP_URL` harus sama dengan URL untuk mengakses project kita di browser. Karena kita akan gunakan `php artisan serve`, jadi kita sesuaikan URLnya seperti di atas.
2. Sebagai percobaan, kita gunakan database MariaDB dengan nama `db_testing` (pastikan teman-teman sudah buat database dengan nama `db_testing`) dan untuk credential database sesuaikan dengan credential database teman-teman.

Selanjutnya kita coba run testing contoh yang sudah tersedia pada saat kita run command `php artisan dusk:install`.

Untuk running laravel dusk, kita run dulu project kita.
```
php artisan serve
```

Karena terminal sudah kita gunakan untuk run command di atas, kita buka tab baru terminal untuk run laravel dusk. 

Sekarang kita coba run browser testing menggunakan command berikut ini.
```
php artisan dusk
```

Output di terminal:
```

   PASS  Tests\Browser\ExampleTest
  ✓ basic example                                                        0.56s  

  Tests:    1 passed (1 assertions)
  Duration: 0.65s

```

## Step 3 - Install dan Setup Laravel Breeze{#step-3}
Pada tahapan ini kita akan gunakan laravel breeze starter kit project kita. Sekarang buka kembali terminal lalu kita install package laravel breeze.
```
composer require laravel/breeze --dev
```

Selanjutnya kita run `breeze:install` untuk memilih stack yang akan digunakan.
```
php artisan breeze:install
```

Setelah kita run command di atas, tampil prompt. Di sini boleh pilih bebas, sebagai contoh:
```
┌ Which Breeze stack would you like to install? ───────────────┐
 │ Blade with Alpine                                            │
 └──────────────────────────────────────────────────────────────┘

 ┌ Would you like dark mode support? ───────────────────────────┐
 │ No                                                           │
 └──────────────────────────────────────────────────────────────┘

 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ PHPUnit                                                      │
 └──────────────────────────────────────────────────────────────┘

```

Tunggu sampai proses install selesai.

```
   INFO  Installing and building Node dependencies.  


added 144 packages, and audited 145 packages in 10s

35 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

> build
> vite build

vite v5.1.4 building for production...
✓ 48 modules transformed.
public/build/manifest.json             0.26 kB │ gzip:  0.13 kB
public/build/assets/app-CB8Dc99X.css  31.65 kB │ gzip:  6.05 kB
public/build/assets/app-9mbrzSRH.js   73.42 kB │ gzip: 27.22 kB
✓ built in 935ms


   INFO  Breeze scaffolding installed successfully.  

```

Setelah proses install selesai, kita run `migrate` command.

```
php artisan migrate
```

Output:
```
   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 40.51ms DONE
  0001_01_01_000001_create_cache_table ........................... 9.74ms DONE
  0001_01_01_000002_create_jobs_table ........................... 31.12ms DONE

```

Pada tahapan ini kita sudah menyiapkan project kita dan sudah tersedia fitur login dan register dari laravel breeze. Jadi selanjutnya kita coba tulis testing untuk kedua fitur ini.

## Step 4 - Testing untuk Feature Register{#step-4}
Kita akan melakukan test untuk fitur register. Berikut ini skenario untuk test fitur register:
1. User membuka halaman register.
2. User mengisi `name`, `email` , `password` dan `konfirmasi password`.
3. User klik button `REGISTER`.
4. Web membuka halaman dashboard user.

Sekarang kita buat class baru untuk testing fitur register. Buka kembali terminal lalu kita run `dusk` command berikut ini.
```
php artisan dusk:make RegisterTest
```

Output di terminal:
```
   INFO  Test [tests/Browser/RegisterTest.php] created successfully.  
```

Seperti yang terlihat di output terminal, `tests/Browser/RegisterTest.php` berhasil digenerate setelah `dusk` command berhasil dirun.

Selanjutnya kita buka file `tests/Browser/RegisterTest.php`, lalu kita  hapus method `testExample()` yang secara default ada dan kita tambahkan method `user_can_register()`.

```php
<?php

namespace Tests\Browser;

use Illuminate\Foundation\Testing\DatabaseMigrations;
use Laravel\Dusk\Browser;
use Tests\DuskTestCase;

class RegisterTest extends DuskTestCase
{
    use DatabaseMigrations;

    /** @test */
    public function user_can_register(): void
    {
        $this->browse(function (Browser $browser) {
	        // 1. User membuka halaman register.
            $browser->visit('/register')
            // 2. User mengisi `name`, `email` , `password` dan `konfirmasi password`.
                    ->type('name', 'User')
                    ->type('email', 'user@example.com')
                    ->type('password', 'password')
                    ->type('password_confirmation', 'password')
            // 3. User klik button `REGISTER`.
                    ->press('REGISTER')
            // 4. Web membuka halaman dashboard user.
                    ->assertPathIs('/dashboard');
        });
    }
}

```

Seperti yang terlihat di baris kode di atas, testing yang kita tulis berdasarkan skenario testing kita.

Setelah selesai coding, jangan lupa save kembali file `tests/Browser/RegisterTest.php`.

Selanjutnya kita coba test fitur register. Sebelumnya saya belum stop `php artisan serve` yang sebelumnya di-run. Jadi kondisi project masih dalam keadaan di-run. 

Sekarang kita run laravel dusk untuk testing fitur register.
```
php artisan dusk
```
Output di terminal:
```
   PASS  Tests\Browser\ExampleTest
  ✓ basic example                                                        0.47s  

   PASS  Tests\Browser\RegisterTest
  ✓ user can register                                                    1.22s  

  Tests:    2 passed (2 assertions)
  Duration: 1.83s


```

Seperti yang terlihat di output terminal di atas, test yang dilakukan bertambah satu dan terdapat keterangan:
```
 PASS  Tests\Browser\RegisterTest
  ✓ user can register                                                    1.22s  
```

Tanda testing fitur register berjalan dengan baik.

## Step 5 - Testing untuk Feature Login {#step-5}
Selanjutnya kita akan melakukan test untuk fitur login. Berikut ini skenario untuk test fitur login:
1. Generate data user baru
2. User membuka halaman login.
3. User mengisi `email` , dan `password`.
4. User klik button `LOG IN`.
5. Web membuka halaman dashboard user.

Selanjutnya kita generate test baru untuk fitur login.
```
php artisan dusk:make LoginTest
```

Output di terminal;

```
   INFO  Test [tests/Browser/LoginTest.php] created successfully.
```
Berdasarkan output di atas, `tests/Browser/LoginTest.php` berhasil digenerate.

Selanjutnya kita buka file `tests/Browser/LoginTest.php`. Sama seperti sebelumnya kita hapus method `testExample()` dan kita tambahkan method `user_can_login()`.
```php
<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Laravel\Dusk\Browser;
use Tests\DuskTestCase;

class LoginTest extends DuskTestCase
{
    use DatabaseMigrations;

    /** @test */
    public function user_can_login(): void
    {
	    // 1. Generate data user baru
        $user = User::factory()->create([
            'email' => 'user@example.com'
        ]);

        $this->browse(function (Browser $browser) use ($user) {
	        // 2. User membuka halaman login.
            $browser->visit('/login')
            // 3. User mengisi `email` , dan `password`.
                    ->type('email', $user->email)
                    ->type('password', 'password')
            // 4. User klik button `LOG IN`.
                    ->press('LOG IN')
            // 5. Web membuka halaman dashboard user.
                    ->assertPathIs('/dashboard');
        });
    }
}

```

Berbeda dengan fitur register, di sini kita generate terlebih dahulu user sebelum memulai skenario test lain.

Setelah selesai save kembali file `tests/Browser/LoginTest.php`.

```
php artisan dusk
```

Output di terminal:
```

   PASS  Tests\Browser\ExampleTest
  ✓ basic example                                                        0.46s  

   PASS  Tests\Browser\LoginTest
  ✓ user can login                                                       1.20s  

   PASS  Tests\Browser\RegisterTest
  ✓ user can register                                                    1.18s  

  Tests:    3 passed (3 assertions)
  Duration: 3.05s



```

Seperti yang terlihat di output di atas, terdapat keterangan:
```
   PASS  Tests\Browser\LoginTest
  ✓ user can login                                                       1.20s  
```

Tanda testing fitur login berjalan dengan baik.

## Penutup{#penutup}
Pada tutorial Laravel 11 kali ini kita sudah coba laravel dusk untuk melakukan browser testing. Testing yang sudah kita lakukan adalah testing fitur register dan testing fitur login. Pada saat kita run laravel dusk, kita bisa lihat hasil testing berjalan dengan baik.