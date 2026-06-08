---
title: "Tutorial CodeIgniter 4: Refactor Login Feature Menggunakan Filter Class"
slug: "tutorial-codeigniter-4-refactor-login-feature-menggunakan-filter-class"
category: "CodeIgniter 4"
date: "2022-06-13"
status: "published"
---

Pada tutorial sebelumnya kita sudah belajar bagaimana cara membuat login dan register menggunakan myth:auth package. Pada saat proses uji coba, kita bisa lihat ketika mengakses halaman home sebelum login, kita akan diarahkan ke halaman login. Setelah kita pelajari kodenya, halaman home ini dilengkapi dengan filter `login` dari package myth:auth yang berfungsi untuk mengecek apakah user sudah login atau belum sebelum mengakses controller home. 

Setelah mencoba package tersebut, saya kembali teringat dengan tutorial codeigniter 4 tentang [membuat fitur login dan register](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-membuat-fitur-login-dan-register) yang sebelumnya saya tulis tepat setelah codeigniter 4 rilis. Mari kita perhatikan kembali kode untuk mengecek apakah user sudah login atau belum misalnya pada controller `Dashboard.php`.
```php
<?php namespace App\Controllers;

class Dashboard extends BaseController
{
    public function index()
    {
        if (! $this->isLoggedIn()) {
            return redirect()->to('/');
        }

        $data = [
            'title' => 'Dashboard | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('dashboard', $data);
    }

    private function isLoggedIn() : bool
    {
        if (session()->get('logged_in')) {
            return true;
        }

        return false;
    }

}
```

Ya, proses pengecekan saya gunakan method `isLoggedIn()` yang langsung didefinisikan di dalam class `Dashboard` dan digunakan langsung di dalam method yang ingin diproteksi, yaitu method `index()`. Pada saat tulisan tersebut dibuat, saya masih belum eksplore lebih lanjut tentang codeigniter 4 dan belum mengetahui adanya class `controller filter` yang bisa digunakan untuk menangani tugas tersebut. 

Sebagai info, [`Controller Filter`](https://codeigniter4.github.io/userguide/incoming/filters.html) class adalah class sederhana yang berfungsi sebagai middleware atau sebuah layer yang menjembatani antara request dan controller. Berdasarkan dokumentasinya, controller filter class akan melakukan sebuah proses sebelum atau sesudah controller dieksekusi. Dari fungsinya tersebut, umumnya class ini memiliki dua method, yaitu `before()` dan `after()` yang nantinya dapat kita isi dengan kode yang akan di-run sebelum dan sesudah controller sesuai dengan kode yang diterapkan pada masing-masing method tersebut.

Ada banyak contoh penggunaan yang dapat dilakukan controller filter class ini. Selain fitur pengecekan status login, beberapa contoh task yang bisa dilakukan oleh class `filter` ini.
* Melakukan proteksi CSRF terhadap request yang datang.
* Membatasi area yang dapat diakses oleh user berdasarkan role.
* Melakukan pembatasan rate / rate limiting terhadap endpoint tertentu.
* Menampilkan halaman `Maintenance`.
* dan lain-lain.

Dari percobaan tutorial menggunakan myth:auth, saya terinspirasi untuk melakukan refactor codingan hasil tutorial tentang membuat fitur login dan register. Jadi nanti saya akan coba mengecek kembali codingan mana yang terdapat logika untuk pengecekan apakah user sudah login atau belum, lalu memisahkan codenya dan kita buatkan menjadi satu class filter sesudah dengan fungsinya. 

Berbeda dengan mendefinisikan berupa method dalam class, dengan melakukan refactor dan membuat class baru ini nantinya bisa digunakan di controller lainnya untuk melakukan task yang sama. Menarik bukan? Yuk sekarang kita coba mulai!

## Tutorial CodeIgniter 4: Refactor Login Feature Menggunakan Filter Class{#table-of-content}
* Overview
* Persiapan
* Step 1 - Buat Controller Filter Class
* Step 2 - Buat Alias untuk Filter Class
* Step 3 - Set Filter di route login dan dashboard
* Step 4 - Hapus Code yang tidak dipakai
* Step 5 - Uji Coba
* Penutup

## Overview{#overview}
Seperti yang sudah disebutkan sebelumnya, pada percobaan kali ini saya akan coba refactor codingan yang terdapat logika untuk pengecekan apakah user sudah login atau belum, lalu memisahkan logika tersebut dan kita buatkan dalam satu class khusus, yaitu controller filter class. 

Setelah saya baca-baca kembali ada dua class controller yang terdapat logika pengecekan status login, yang pertama `Dashboard.php` dan yang kedua `LoginController.php`. Dua controller ini memiliki logika pengecekan status login yang berbeda, yang pertama pengecekan otentikasi dan yang kedua redirect ketika sudah diotentikasi. 

Dari tujuan pengecekan ini nanti kita buat dua class `controller filter` dengan nama `Authenticate` dan `RedirectIfAuthenticated`. Setelah itu kita coba implementasikan class `filter` ini dan hapus kode yang fungsinya sudah digantikan oleh class `filter`.

## Persiapan{#persiapan}
Project yang akan digunakan dalam proses refactor untuk menggunakan filter class adalah project hasil dari tutorial codeigniter 4 tentang [membuat fitur login dan register](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-membuat-fitur-login-dan-register). Untuk teman-teman yang akan mengikuti percobaan refactor kali ini boleh coba dulu tutorial tersebut sampai selesai. Setelah itu kita bisa sama-sama coba refactor.

## Step 1 - Buat Controller Filter Class{#step-1}
Pertama kita buat filter class yang akan menangani tugas untuk me-redirect ke halaman login ketika user dalam keadaan belum login. Buka terminal lalu run command berikut ini untuk generate filter class.

```
php spark make:filter Authenticate
```

Setelah kita run command di atas, kita bisa lihat ada file baru, yaitu `app/Filters/Authenticate.php`. Sekarang kita buka file `app/Filters/Authenticate.php` di text editor, lalu kita modifikasi method `before()`.
```php
<?php

// ... baris kode lainnya

class Authenticate implements FilterInterface
{

    public function before(RequestInterface $request, $arguments = null)
    {
        if (! session('logged_in')) {
            return redirect()->to(site_url('login'));
        }
    }

    // .. baris kode lainnya
}

```

Pada baris kode di atas kita bisa lihat terdapat pengecekan session dengan key `logged_in`, di mana session `logged_in` ini bernilai true apabila user sudah berhasil melakukan login. Dalam method `before()`, apabila user belum login atau value session `logged_in` ini bernilai false, maka user akan dialihkan ke halaman login.

Selanjutnya kita buat filter class kedua yang akan menangani tugas me-redirect ke halaman dashboard apabila user sudah dalam keadaan login. Buka kembali terminal lalu kita run command berikut ini untuk generate filter class dengan nama `RedirectIfAuthenticated`.
```
php spark make:filter RedirectIfAuthenticated
```

Setelah kita run command di atas, kita bisa lihat ada file baru hasil generate, yaitu `app/Filters/RedirectIfAuthenticated.php`. Selanjutnya kita modifikasi method `before()` dari class `RedirectIfAuthenticated`.
```php
<?php

// .. baris kode lainnya

class RedirectIfAuthenticated implements FilterInterface
{

    public function before(RequestInterface $request, $arguments = null)
    {
        if (session('logged_in')) {
            return redirect()->to(site_url('dashboard'));
        }

    }
		
		// .. baris kode lainnya
}

```
Berbeda dengan filter class sebelumnya, class ini melakukan pengecekan dengan keadaan yang berbeda. Bisa kita lihat pada method `before()`, terdapat pengecekan session `logged_in`, dengan kondisi apabila session `logged_in` ini bernilai true atau user sudah berhasil login, maka user akan di-redirect ke halaman dashboard.

## Step 2 - Buat Alias untuk Filter Class{#step-2}
Setelah selesai membuat filter class, selanjutnya kita atur konfigurasinya. Kita tambahkan alias supaya filter class ini mudah digunakan dan tidak perlu menuliskan class dengan namespace yang lengkap. Sekarang kita buka file konfigurasi filter, yaitu `app/Config/Filters.php`, lalu kita tambahkan alias `authenticate` dan `redirectIfAuthenticated` pada property `$aliases`.

```php
<?php

// ... baris kode lainnya

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
        'authenticate' => \App\Filters\Authenticate::class, // tambahkan ini
        'redirectIfAuthenticated' => \App\Filters\RedirectIfAuthenticated::class, // tambahkan ini
    ];

    // ... baris kode lainnya
}
```

Jadi nanti ketika alias ini digunakan, misalnya di route, akan merujuk ke masing-masing filter class.

## Step 3 - Set Filter di route login dan dashboard{#step-3}
Langkah selanjutnya adalah mengubah route dan menerapkan filter yang sudah kita buat sebelumnya. Kita buka file konfigurasi untuk routes, yaitu file `app/Config/Routes.php`.

Berdasarkan dokumentasinya, cara terbaik untuk menerapkan filter pada route adalah dengan cara setting `false` pada pengaturan `auto-route`. Pada `app\Config\Routing.php` temukan baris kode berikut ini.
```php
    public bool $autoRoute = false;
```

Pastikan value atribute `$autoRoute` bernilai `false`.

Selanjutnya buka file `app/Config/Routes.php`, lalu temukan baris kode route untuk `login`.
```php
$routes->group('login', function ($routes) {
    $routes->get('/', 'LoginController::index');
    $routes->post('/', 'LoginController::login');
});
```

Kita tambahkan filter `redirectIfAuthenticated` pada route login.
```php
$routes->group('login', ['filter' => 'redirectIfAuthenticated'], function ($routes) {
    $routes->get('/', 'LoginController::index');
    $routes->post('/', 'LoginController::login');
});
```

Setelah itu temukan baris kode untuk `dashboard`.
```php
$routes->get('/dashboard', 'Dashboard::index');
```
Kita tambahkan filter `authenticate` pada route dashboard.
```php
$routes->get('/dashboard', 'Dashboard::index', ['filter' => 'authenticate']);
```

Kedua filter sudah kita terapkan pada masing-masing route. Jadi ketika user mengakses halaman login ataupun dashboard, kode yang ada di method `before()` dari masing-masing filter class yang akan dieksekusi sebelum controller.

## Step 4 - Hapus Code yang tidak dipakai{#step-4}
Pada langkah sebelumnya, kita sudah menerapkan filter pada route sehingga ketika route login dan dashboard diakses terdapat pengecekan session login dan user akan diarahkan sesuai dengan value session login. Karena kode dengan fungsi yang sama sudah kita pisahkan dan kita buatkan menjadi filter class, sekarang kita bisa hapus kode tersebut.

Pertama buka controller `app/Controllers/LoginController.php`, lalu kita hapus method `isLoggedIn()` dan penggunaannya pada method `index()`.
```php
<?php 

// ... baris kode lainnya

class LoginController extends BaseController
{
    // ... baris kode lainnya

    public function index()
    {
        // implementasi method isLoggedIn yang akan dihapus
        if ($this->isLoggedIn()) {
            return redirect()->to(base_url('dashboard'));
        }

        $data = [
            'title' => 'Login | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('auth/login', $data);
    }

    // ... baris kode lainnya

    // method yang akan dihapus
    private function isLoggedIn(): bool
    {
        if (session()->get('logged_in')) {
            return true;
        }

        return false;
    }
}

```

Setelah kita hapus kode tersebut, maka keseluruhan class `LoginController` menjadi seperti baris kode di bawah ini.

```php
<?php namespace App\Controllers;

use App\Models\UserModel;

class LoginController extends BaseController
{
    protected $model;

    public function __construct()
    {
        $this->model = new UserModel();
        $this->helpers = ['form', 'url'];
    }

    public function index()
    {
        $data = [
            'title' => 'Login | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('auth/login', $data);
    }

    public function login()
    {
        $data = $this->request->getPost(['email', 'password']);

        if (! $this->validateData($data, [
            'email' => 'required',
            'password' => 'required'
        ])) {
            return $this->index();
        }

        $email = $this->request->getPost('email');
        $password = $this->request->getPost('password');

        $credentials = ['email' => $email];

        $user = $this->model->where($credentials)
            ->first();

        if (! $user) {
            session()->setFlashdata('error', 'Email atau password anda salah.');
            return redirect()->back();
        }

        $passwordCheck = password_verify($password, $user['password']);

        if (! $passwordCheck) {
            session()->setFlashdata('error', 'Email atau password anda salah.');
            return redirect()->back();
        }

        $userData = [
            'name' => $user['name'],
            'email' => $user['email'],
            'logged_in' => TRUE
        ];

        session()->set($userData);
        return redirect()->to(base_url('dashboard'));
    }
}
```

Selanjutnya buka controller untuk dashboard, yaitu `app/Controllers/Dashboard.php`. Sama seperti sebelumnya, kita coba hapus method `isLoggedIn()` dan penggunaannya.
```php
<?php namespace App\Controllers;

class Dashboard extends BaseController
{
    public function index()
    {
        // implementasi method isLoggedIn yang akan dihapus
        if (! $this->isLoggedIn()) {
            return redirect()->to('/');
        }

        $data = [
            'title' => 'Dashboard | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('dashboard', $data);
    }

    // method yang akan dihapus
    private function isLoggedIn() : bool
    {
        if (session()->get('logged_in')) {
            return true;
        }

        return false;
    }
}
```

Dan berikut ini adalah class controller `Dashboard` setelah kode yang tidak digunakan kita hapus.
```php
<?php namespace App\Controllers;

use App\Controllers\BaseController;

class Dashboard extends BaseController
{
    public function index()
    {
        $data = [
            'title' => 'Dashboard | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('dashboard', $data);
    }
}
```

## Step 5 - Uji Coba{#step-5}
Untuk proses uji coba `filter` kali ini tidak dilengkapi gambar, karena ketika mengakses halaman yang dilengkapi `filter` langsung mengarah ke halaman lainnya. Jadi di sini hanya dituliskan skenario uji coba nya saja.

Sekarang kita coba run project kita menggunakan `spark` command.
```
php spark serve
```

Setelah itu kita bisa akses project kita di url ini.
```
http://localhost:8080
```

Setelah kita akses url di atas, kita bisa lihat web menampilkan halaman home dan sekarang kita bisa mulai uji coba.

Uji coba pertama adalah test filter `Authenticate` class dengan cara mencoba akses langsung halaman dashboard dengan mengunjungi url:
```
http://localhost:8080/dashboard
```

Ekspektasi ketika kita akses url di atas, halaman web akan diarahkan ke halaman `login` karena kita belum login. Ini tandanya `Authenticate` filter class berjalan dengan baik. 

Selanjutnya uji coba akses langsung halaman login untuk mengecek apakah filter `RedirectIfAuthenticated` berjalan baik atau tidak. Karena perlu akun untuk login, kita bisa coba register terlebih dahulu. Lalu setelah itu kita bisa langsung coba login menggunakan akun yang sudah didaftarkan. Kemudian selanjutnya kita bisa coba akses kembali halaman login dengan kondisi kita sudah berhasil login.
```
http://localhost:8080/login
```
Ekspektasi ketika url di atas kita akses, kita akan kembali ke halaman dashboard. Tanda filter `RedirectIfAuthenticated` berjalan dengan baik.

## Penutup{#penutup}
Pada tutorial codeigniter 4 kali ini kita telah mencoba untuk refactor feature login dari seri tutorial sebelumnya. Di sini kita sudah belajar bagaimana memisahkan kode yang dapat digunakan secara berulang dan mengubah kode tersebut menjadi class terpisah. Di mulai dari membuat `filter` class, setting `alias`, dan set filter di route. Setelah kita tambahkan `filter` dan menghapus kode yang sudah tidak kita gunakan, pada saat kita mengakses halaman dengan kondisi yang tidak sesuai, web akan diarahkan ke halaman sesuai dengan url tujuan yang arahkan di method `before()` di masing-masing `filter` class. Secara fungsional sama dengan kodingan yang sebelumnya, tetapi di sini kita bisa memisahkan kode yang nantinya digunakan secara berulang.