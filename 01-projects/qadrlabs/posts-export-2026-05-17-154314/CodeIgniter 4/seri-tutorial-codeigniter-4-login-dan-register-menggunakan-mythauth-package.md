---
title: "Seri Tutorial CodeIgniter 4: Login dan Register menggunakan Myth:Auth Package"
slug: "seri-tutorial-codeigniter-4-login-dan-register-menggunakan-mythauth-package"
category: "CodeIgniter 4"
date: "2022-05-08"
status: "published"
---

Setelah melewati beberapa waktu yang lama akhirnya seri tutorial [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4) kembali. Pada edisi tutorial kali ini saya coba menuliskan percobaan memakai salah satu package yang menangani auth pada CodeIgniter 4, yaitu Myth:Auth package. Dengan menggunakan Myth:Auth ini, kita akan coba mengembangkan fitur login dan register. Kalau di [edisi tutorial sebelumnya](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-membuat-fitur-login-dan-register), kita sudah coba mengembangkan fitur login dan register dari nol, sekarang kita coba pakai package khusus auth. Apakah ada bedanya? Yuk kita coba~!

## Web App Overview{#overview}
Dalam tutorial ini, kita tidak akan membangun aplikasi web yang kompleks. Sebagai gantinya, fokus utama kita adalah menambahkan **Myth:Auth**, sebuah package otentikasi khusus untuk CodeIgniter 4, ke dalam proyek baru yang baru saja diinstal. Tujuan utama kita adalah mengintegrasikan dua fitur penting, yaitu **login** dan **registrasi pengguna (register)**.

Secara default, Myth:Auth memerlukan pengguna untuk mengaktifkan akun mereka melalui email setelah melakukan registrasi. Namun, dalam tutorial ini, kita juga akan belajar cara **menonaktifkan fitur aktivasi email** dengan melakukan override pada konfigurasi bawaan Myth:Auth. Selain itu, kita akan mencoba menerapkan **filter login** untuk memastikan bahwa hanya pengguna yang sudah login yang dapat mengakses halaman tertentu. Jika pengguna belum login, mereka akan dialihkan secara otomatis ke halaman login.

Dengan pendekatan ini, kita dapat memahami bagaimana package Myth:Auth dapat membantu mempermudah pengembangan fitur autentikasi tanpa harus membangun semuanya dari awal.

## Step 1 - Setup Project{#step-1}
Pertama kita install dulu CodeIgniter 4 menggunakan `composer`.
```bash
composer create-project codeigniter4/appstarter sample-app
```

Setelah proses install CodeIgniter 4 selesai, kita masuk ke direktori project.
```bash
cd sample-app
```

Lalu selanjutnya kita buat file `.env` dengan cara copy file `env` yang sudah ada di direktori project.
```bash
cp env .env
```

Di sini kita akan atur konfigurasi project kita. Buka file `.env` di text editor, lalu hapus tanda `#` untuk pengaturan environment, base url, konfigurasi database dan sesuaikan value-nya.

```
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = db_ci4
database.default.username = root
database.default.password = password
database.default.DBDriver = MySQLi
```

Pada baris kode di atas, kita atur `environment` dengan value `development` supaya pesan error ditampilkan ketika ada error atau bug pada saat development. Selain itu kita juga mengatur base urlnya dengan value localhost. Dan pengaturan terakhir adalah konfigurasi database, seperti username, password dan nama database. Sebagai contoh di sini kita isi username = `root`, password = `password` dan nama database = `db_ci4`.

Selanjutnya kita buat database baru dengan nama `db_ci4`. Kita bisa buat database melalui phpmyadmin ataupun terminal.

## Step 2 - Install Myth:Auth Package{#step-2}
Setelah setup project selesai, berikutnya kita install Myth:Auth. Supaya mempermudah development ketika ada update dari package, kita akan coba install Myth:Auth menggunakan `composer`. Buka kembali terminal, lalu run command berikut ini.

```bash
composer require myth/auth
```
Output:
```bash
Using version ^1.0 for myth/auth
./composer.json has been updated
Running composer update myth/auth
Loading composer repositories with package information
Updating dependencies
Lock file operations: 1 install, 0 updates, 0 removals
  - Locking myth/auth (v1.0.1)
Writing lock file
Installing dependencies from lock file (including require-dev)
Package operations: 1 install, 0 updates, 0 removals
  - Installing myth/auth (v1.0.1): Extracting archive
Generating autoload files
29 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
```

Seperti yang terlihat pada output di terminal, versi myth auth yang terinstall pada saat tutorial ini dibuat adalah versi 1.0.1.

## Step 3 - Setup Konfigurasi Myth:Auth{#step-3}
Setelah proses install selesai, selanjutnya kita akan coba atur beberapa konfigurasi dari Myth:Auth. 

Pertama kita buka file `app/Config/Validation.php`, lalu kita tambahkan rule validasi dari myth auth pada di properti `$ruleSets`.
```php
<?php

// ... baris kode sebelumnya

class Validation
{
    //--------------------------------------------------------------------
    // Setup
    //--------------------------------------------------------------------

    /**
     * Stores the classes that contain the
     * rules that are available.
     *
     * @var string[]
     */
    public $ruleSets = [
        Rules::class,
        FormatRules::class,
        FileRules::class,
        CreditCardRules::class,
        \Myth\Auth\Authentication\Passwords\ValidationRules::class // tambahkan ini
    ];

    
    // ... baris kode selanjutnya
}

```

Selanjutnya buka file `app/Config/Filters.php`, lalu tambahkan `login`, `role` dan `permission` pada properti `$aliases`.

```php
<?php

// ... baris kode sebelumnya

use Myth\Auth\Filters\LoginFilter; // tambahkan ini
use Myth\Auth\Filters\PermissionFilter; // tambahkan ini
use Myth\Auth\Filters\RoleFilter; // tambahkan ini


class Filters extends BaseConfig
{
    /**
     * Configures aliases for Filter classes to
     * make reading things nicer and simpler.
     *
     * @var array
     */
    public $aliases = [
        'csrf'          => CSRF::class,
        'toolbar'       => DebugToolbar::class,
        'honeypot'      => Honeypot::class,
        'invalidchars'  => InvalidChars::class,
        'secureheaders' => SecureHeaders::class,
        'login' => LoginFilter::class, // tambahkan ini
        'role' => RoleFilter::class, // tambahkan ini
        'permission' => PermissionFilter::class // tambahkan ini
    ];

    // ... baris kode selanjutnya
}
```

Selanjutnya untuk over-ride atau menimpa konfigurasi dari Myth:Auth kita bisa buat class baru di direktori `app/Config` yang merupakan ekstensi class dari package Myth:Auth. 

**Keterangan:** Ada baiknya kita tidak mengedit langsung apa yang ada di direktori `vendor/myth/auth/src/Config/`, jadi ketika ada update dari package Myth:Auth, kita tidak perlu mengedit lagi file konfigurasi yang ada di direktori package tersebut.

Misalkan kita ingin over-ride pengaturan Auth-nya. Untuk percobaan di tutorial ini, kita tidak perlu fitur `aktivasi email` pada saat register, jadi kita ingin menonaktifkan pengaturannya. Kita buat dulu file `app/Config/Auth.php`, lalu kita extends dari class `Myth\Auth\Config\Auth`.

```php
<?php namespace Config;

use CodeIgniter\Config\BaseConfig;
use Myth\Auth\Config\Auth as AuthConfig;

class Auth extends AuthConfig
{
    
    // isi class Auth

}

```

Langkah selanjutnya kita override pengaturan aktivasi email menjadi `null` sehingga kita tidak perlu aktivasi email dulu pada saat uji coba project ini. Kita tambahkan properti `$requireActivation` dan kita isi value-nya menjadi null.

```php
<?php namespace Config;

use CodeIgniter\Config\BaseConfig;
use Myth\Auth\Config\Auth as AuthConfig;

class Auth extends AuthConfig
{
    
    /**
     * --------------------------------------------------------------------
     * Require Confirmation Registration via Email
     * --------------------------------------------------------------------
     *
     * When enabled, every registered user will receive an email message
     * with an activation link to confirm the account.
     *
     * @var string|null Name of the ActivatorInterface class
     */
    public $requireActivation = null;

}
```

Save file `app/Config/Auth.php`.

Kalau kita perhatikan dalam file `vendor/myth/auth/src/Config/Auth.php` ini, selain pengaturan untuk aktivasi email, ada beberapa pengaturan lain, seperti view yang digunakan untuk masing-masing fitur, direktori view layout, field untuk login apakah pakai email atau username, pengaturan apakah perlu ada fitur registrasi, pengaturan remember me, dan lain-lain.

Setelah setting konfigurasi yang cukup panjang, selanjutnya kita run file migration dari package.
```bash
php spark migrate -all
```

Output setelah kita run migration kurang lebih seperti ini.
```bash
CodeIgniter v4.1.9 Command Line Tool - Server Time: 2022-05-07 07:24:11 UTC-05:00

Running all new migrations...
    Running: (Myth\Auth) 2017-11-20-223112_Myth\Auth\Database\Migrations\CreateAuthTables
Done migrations.
```

Kalau kita cek database `db_ci4` menggunakan phpmyadmin ataupun cli untuk mysql, kita bisa lihat ada table baru bawaan package Myth:Auth yang selanjutnya bisa kita gunakan untuk fitur Authentication dan Authorization.


## Step 4 - Penggunaan Filter{#step-4}
Pada tahapan ini kita akan mencoba untuk menggunakan filter pada controller `app/Controllers/Home.php`, supaya user tidak bisa langsung mengakses halaman Home dan harus login terlebih dahulu.

Ada dua cara untuk penggunaan filter login (pengecekan apakah user sudah login), kita bisa menggunakan global restriction dan single route restriction. Di sini kita coba atur filter pada route. Sekarang buka file `app/Config/Routes.php`, lalu temukan baris kode berikut ini.
```php
$routes->get('/', 'Home::index');
```

Kita tambahkan filter login yang sebelumnya sudah kita definisikan di properti `$aliases` pada file `app/Config/Filters.php`. Route setelah kita tambahkan menjadi seperti ini.
```php
$routes->get('/', 'Home::index', ['filter' => 'login']);
```

Meski route untuk controller `Home` sudah kita tambahkan filter, kita masih bisa akses controller `Home` tanpa login dengan url `localhost:8080/index.php/home`. Supaya user mesti login terlebih dahulu pada saat akses controller `app/Controllers/Home.php` dengan url tersebut, kita bisa tambahkan route baru untuk filter url ini.
```php
$routes->get('/home', 'Home::index', ['filter' => 'login']);
```
Jadi di dalam file `app/Config/Routes.php`, ada dua routes yang sudah kita definisikan.

```php

/*
 * --------------------------------------------------------------------
 * Route Definitions
 * --------------------------------------------------------------------
 */

// We get a performance increase by specifying the default
// route since we don't have to scan directories.
$routes->get('/', 'Home::index', ['filter' => 'login']);
$routes->get('/home', 'Home::index', ['filter' => 'login']);
```

Setelah selesai, save kembali file `app/Config/Routes.php`.

## Step 5 - Run Project{#step-5}
Untuk run project, kita run command berikut ini di terminal.
```bash
php spark serve
```

Selanjutnya buka url `http://localhost:8080` di browser dan kita bisa lihat web ter-redirect ke halaman login. Kita bisa tes project kita dengan cara buat akun terlebih dahulu dengan klik link `Need an account?`, buat akun baru dan coba login. 

**Catatan**
Apabila ketika uji coba validasi pada saat register tampil error berikut:
```
Fatal error: Could not check compatibility between Myth\Auth\Authentication\Passwords\CompositionValidator::check(string $password, ?CodeIgniter\Entity\Entity $user = null): bool and Myth\Auth\Authentication\Passwords\ValidatorInterface::check(string $password, ?CodeIgniter\Entity $user = null): bool, because class CodeIgniter\Entity is not available
```

Teman-teman dapat baca cara fix error di catatan [Fix Error Myth Auth Package CodeIgniter 4 because class CodeIgniter\Entity is not available](https://qadrlabs.com/note/fix-error-myth-auth-package-codeigniter-4-because-class-codeigniterentity-is-not-available/view).

## Penutup{#penutup}
Dalam tutorial ini, kita telah mempelajari cara menggunakan salah satu package khusus untuk menangani autentikasi di CodeIgniter 4, yaitu **Myth:Auth**. Mulai dari proses instalasi package, pengaturan konfigurasi dasar, hingga melakukan override terhadap konfigurasi bawaan Myth:Auth, kita juga mencoba menerapkan filter login untuk mengamankan halaman tertentu. Dari percobaan ini, kita dapat menyimpulkan bahwa dengan menggunakan Myth:Auth, kita tidak perlu lagi mengembangkan fitur autentikasi dari nol. Package ini sudah menyediakan hampir semua fitur yang dibutuhkan untuk menangani autentikasi, seperti login, registrasi, dan manajemen pengguna.

Namun, selain Myth:Auth, ada alternatif package lain yang juga sangat populer dan patut dicoba, yaitu **CodeIgniter Shield**. CodeIgniter Shield adalah package resmi yang dikembangkan oleh tim CodeIgniter, dan dirancang untuk memberikan solusi autentikasi yang lebih modern dan fleksibel. Jika Anda ingin menjelajahi lebih lanjut tentang bagaimana menggunakan CodeIgniter Shield, Anda dapat mengikuti tutorial berikut: [Tutorial CodeIgniter 4 Login dan Register Menggunakan CodeIgniter Shield](https://qadrlabs.com/post/tutorial-codeigniter-4-login-dan-register-menggunakan-codeigniter-shield).

Dengan adanya berbagai pilihan package autentikasi seperti Myth:Auth dan CodeIgniter Shield, pengembangan aplikasi web menjadi lebih efisien dan terstruktur. Anda dapat memilih package yang paling sesuai dengan kebutuhan proyek Anda.