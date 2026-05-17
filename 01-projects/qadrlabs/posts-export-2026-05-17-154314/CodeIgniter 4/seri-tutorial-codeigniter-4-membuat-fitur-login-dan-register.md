---
title: "Seri Tutorial CodeIgniter 4: Membuat Fitur Login Dan Register"
slug: "seri-tutorial-codeigniter-4-membuat-fitur-login-dan-register"
category: "CodeIgniter 4"
date: "2020-03-01"
status: "published"
---

Pada tutorial sebelumnya, kita telah membahas tentang **[CRUD di CodeIgniter 4](https://qadrlabs.com/post/seri-tutorial-codeigniter-4-crud-codeigniter-4)**. Kali ini, kita akan melanjutkan **seri tutorial Belajar CodeIgniter 4** dengan membangun aplikasi sederhana yang menerapkan fitur **authentication**, seperti **login dan register** menggunakan CodeIgniter 4. Tutorial ini merupakan bagian dari seri lengkap yang dapat Anda akses di [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4). 

Tutorial ini awalnya merupakan eksperimen yang saya lakukan sejak CodeIgniter 4 resmi dirilis pada Februari 2024 lalu. Pertanyaan menarik yang muncul adalah: **Apakah kode lama masih bisa digunakan?** *Hmm*, menarik, bukan? Yuk, kita coba!

**Sebagai catatan**, pada update terbaru per **8 Mei 2024**, tutorial ini tidak hanya menggunakan kode lama, tetapi juga menerapkan kode baru, terutama untuk bagian **validasi form**.

## **Overview** {#overview}
Dalam tutorial ini, kita akan membangun sebuah **aplikasi platform belajar koding sederhana** yang dilengkapi dengan fitur **login dan register**. Studi kasus ini terinspirasi oleh maraknya platform belajar online yang sering kita temui di berbagai grup pemrograman. Berikut adalah fitur-fitur yang akan kita buat:
1. **Halaman Home**: Landing page sederhana sebagai pintu masuk aplikasi.
2. **Fitur Register**: Pendaftaran user baru ke dalam sistem.
3. **Fitur Login**: Memungkinkan user untuk masuk ke platform menggunakan akun yang telah terdaftar.
4. **Fitur Dashboard**: Halaman yang dapat diakses setelah user berhasil login.
5. **Fitur Logout**: Memungkinkan user untuk keluar dari sistem.

#### **Alur Penggunaan Aplikasi**
Alur penggunaan aplikasi ini cukup sederhana:
1. User membuka website platform belajar.
2. User mendaftar melalui halaman **register**.
3. Setelah mendaftar, user dapat **login** menggunakan email dan password yang telah didaftarkan.
4. Setelah login, user akan diarahkan ke halaman **dashboard**.
5. User dapat **logout** untuk keluar dari sistem.

Data yang akan disimpan ke database pun cukup sederhana, meliputi:
- **Nama**: Nama lengkap user.
- **Email**: Alamat email user.
- **Password**: Kata sandi yang di-hash untuk keamanan.

Dengan kebutuhan yang sudah jelas, mari kita bahas langkah-langkah detail dalam membuat fitur **Login dan Register di CodeIgniter 4**. *Check this out, ya!*

---

### **Apa yang Akan Kita Pelajari?**
Dalam tutorial ini, Anda akan mempelajari:
- Cara menginstal dan mengkonfigurasi **CodeIgniter 4**.
- Cara membuat dan mengelola database menggunakan **Migration**.
- Cara mengimplementasikan fitur **login dan register** dengan validasi form.
- Cara membuat tampilan UI sederhana dengan **Templating**.
- Cara mengelola session untuk autentikasi user.

---

### **Apa Saja Langkah-Langkahnya?**
Tertarik untuk mempelajari lebih lanjut? Yuk, simak langkah-langkah lengkapnya di bawah ini! 

---

**Daftar Isi**
- [Overview](#overview)
- [Step 1: Instalasi CodeIgniter 4](#step-1-instalasi)
- [Step 2: Konfigurasi Project](#step-2-konfigurasi)
- [Step 3: Membuat Database](#step-3-create-database)
- [Step 4: Membuat file migration](#step-4-create-migration-file)
- [Step 5: Membuat template UI](#step-5-create-ui-template)
- [Step 6: Membuat halaman utama website](#step-6-create-home-page)
- [Step 7: Membuat fitur register](#step-7-create-register-feature)
- [Step 8: Membuat fitur login](#step-8-create-login-feature)
- [Step 9: Membuat fitur logout](#step-9-create-logout-feature)
- [Uji Coba](#uji-coba)
- [Kesimpulan](#kesimpulan)

---

**Yuk, mulai langkah pertama!**

---

## Step 1: Instalasi CodeIgniter 4 {#step-1-instalasi}
Seperti biasa, langkah pertama kita adalah menginstall framework CodeIgniter 4. Nah, kita install CodeIgniter 4 menggunakan ```composer```. Misalkan kamu mau pakai cara lain itu boleh.

Oke, kita buka terminal atau cmd, lalu kita jalankan *command* ini di terminal / cmd:

```
composer create-project codeigniter4/appstarter platform-belajar
```

Baik, kita tunggu dulu sampai proses instalasi codeigniter 4 selesai.

## Step 2: Konfigurasi Project {#step-2-konfigurasi}
Ada dua cara untuk melakukan konfigurasi project di codeigniter 4, yang pertama dengan cara mengedit langsung file config yang ada di direktori `app/Config` dan cara kedua adalah melalui file `.env`. Di serial tutorial CodeIgniter 4 ini kita akan selalu menggunakan cara kedua, yaitu melalui file `.env`.

Buka kembali terminal, kita masuk ke folder project terlebih dahulu sebelum mengatur konfigurasi dengan *command*:
```
cd platform-belajar
```

Selanjutnya kita copy file dan rename file `env` menjadi ```.env``` yang sudah ada di project kita. Buka lagi terminal, lalu kita jalankan *command* ini:

```
cp env .env
```

**Catatan**: Bisa juga langsung copy dan rename file `env` menjadi `.env` langsung tanpa menggunakan command.

Setelah `command` di atas kita run, kita bisa lihat file baru `.env` di folder root project kita.

Kita buka project kita di text editor (di sini saya menggunakan Visual Studio Code), ketik *command*:

```
code .
```

Misalkan pakai text editor lain, misalnya sublime text, bisa coba buka langsung dengan memilih menu  `File` di text editor, lalu pilih menu `Open Folder` lalu pilih folder project ini, yaitu `platform-belajar`.

Kita bisa lihat ada file `.env`yang telah kita buat sebelumnya. 

Selanjutnya buka file `.env`, lalu kita sesuaikan konfigurasi seperti baris kode di bawah ini:

```
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = platform_belajar
database.default.username = root
database.default.password = 
database.default.DBDriver = MySQLi
```

**Catatan:** di bagian password, sesuaikan dengan password MySQL teman-teman. Jika passwordnya kosong, tidak perlu diisi seperti yang saya contohkan di atas.

## Step 3: Membuat Database {#step-3-create-database}
Nah di file ```.env``` tadi kita kan sudah tambahkan pengaturan database, dan nama databasenya itu ```platform_belajar```. Jadi langkah kita selanjutnya, kita buat database sesuai dengan nama database di file ```.env```. Buka phpMyAdmin, lalu buat database baru dengan nama ```platform_belajar```.

## Step 4: Membuat file migration {#step-4-create-migration-file}
Pada tahapan ini, kita akan membuat table baru untuk menyimpan data user. Untuk membuat table baru, kita akan menggunakan fitur migration CodeIgniter 4. Nah untuk nama ```table``` nya kita sesuaikan saja dengan namanya dengan data yang akan disimpan, yaitu ```users```. Kita buat file migration untuk membuat table ```users```. Buka kembali ```terminal``` / ```cmd```, lalu jalankan *command* berikut ini untuk membuat file migration:

```
php spark make:migration Users
```
Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:32:04 UTC+00:00

File created: APPPATH\Database\Migrations\2024-05-08-073205_Users.php
```


Selanjutnya kita bisa lihat file baru yang dibuat *command* di atas di direktori ```app/Database/Migrations``` dan memiliki nama dengan format ```YYYY-MM-DD-HHIISS_namatable.php``` misalnya ```2024-05-08-073205_Users.php``` sesuai dengan timestamp ketika filenya dibuat. Buka file ```xxxx-xx-xx-xxxxxx_Users.php``` lalu sesuaikan kodenya menjadi seperti berikut ini:

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Users extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type' => 'INT',
                'unsigned' => TRUE,
                'auto_increment' => TRUE
            ],
            'name' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
            ],
            'email' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
                'unique' => TRUE,
            ],
            'password' => [
                'type' => 'VARCHAR',
                'constraint' => 255,
                'null' => FALSE,
            ],
            'created_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ],
            'updated_at' => [
                'type' => 'datetime',
                'null' => TRUE
            ]
        ]);

        $this->forge->addKey('id', TRUE);
        $this->forge->createTable('users');
    }

    //--------------------------------------------------------------------

    public function down()
    {
        $this->forge->dropTable('users');
    }
}
```

Selanjutnya kita run perintah ```migrate``` di terminal atau cmd. Buka terminal atau cmd lalu jalankan *command*:

```
php spark migrate
```

Output:
```bash
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:36:44 UTC+00:00

Running all new migrations...
        Running: (App) 2024-05-08-073205_App\Database\Migrations\Users
Migrations complete.
```

Nah, ketika kita cek di phpMyAdmin, kita bisa melihat table baru di database ```platform_belajar```, ada table ```migrations``` dan table ```users```.

## Step 5: Membuat template UI {#step-5-create-ui-template}
Untuk `view` di project platform belajar ini, kita akan menggunakan templating UI, supaya kita tidak mengulang-ngulang kode HTML untuk bagian header dan footer project kita. Kita buat folder baru terlebih dahulu di direktori ```app/Views``` dengan nama ```layouts```. Setelah itu, kita buat file baru yang digunakan untuk templating UI di dalam folder tersebut (```app/Views/layouts```) dengan nama ```main.php```. Kita sama-sama ketik baris kode ini ya.. 

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="<?= csrf_token() ?>" content="<?= csrf_hash() ?>">
    <title><?= $title; ?></title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
</head>

<body>

    <!-- Content -->
    <?= $this->renderSection('content') ?>

    <!-- /.Content -->


    <footer class="text-center mt-5">
        <p><em><small>Seri Tutorial CodeIgniter 4: Login dan Register CodeIgniter @ <a href="https://qadrlabs.com/">qadrlabs.com</a></small></em></p>
    </footer>
    <script src="https://code.jquery.com/jquery-3.4.1.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>

</body>

</html>

```

Kita save file `main.php` setelah selesai coding untuk templating UI.

## Step 6: Membuat halaman utama website {#step-6-create-home-page}
Halaman utama website ini akan kita gunakan sebagain halaman yang pertama kali ditampilkan ketika project kita diakses. Jika kita lihat di project kita, secara default ada controller yang digunakan untuk halaman utama, yaitu controller `Home`. Pada tahapan ini kita tidak perlu membuat controller baru, kita coba modifikasi controller `Home` yang sudah ada.

Nah selanjutnya kita akan memodifikasi halaman tampilan awal CodeIgniter 4, yaitu halaman ```home.php```. Kita buat tampilan home ini, kita tambahkan link menuju halaman login dan register. Oke selanjutnya kita modifikasi dulu controllernya. Buka file controller ```Home.php``` yang ada di direktori ```app/Controllers```. Nah kita modifikasi menjadi:
```php

<?php namespace App\Controllers;

class Home extends BaseController
{
    public function index()
    {
        $data = [
            'title' => 'Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('home', $data);
    }

}

```

nah, langkah selanjutnya, sesuai dengan baris kode di atas, kita akan buat file views baru dengan nama ```home.php``` di direktori ```app/Views```, lalu kita ketik kode ini...

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<section class="jumbotron text-center" style="height: 500px">
    <h1 class="mt-5">BELAJAR KODING MULAI DARI NOL</h1>
    <p class="lead text-muted">
        Mau buat website bingung mulai dari mana? Yuk kita sama-sama belajar di sini.
    </p>
    <a href="<?php echo base_url('login'); ?>" class="btn btn-outline-primary my-2">Login</a>
    <a href="<?php echo base_url('register'); ?>" class="btn btn-success my-2">Register</a>
</section>

<?= $this->endSection() ?>
```

Ya, tampilannya kita buat sederhana, hanya ada tulisan, dan link menuju halaman login dan register. Misalkan layout atau tulisannya mau teman-teman modif lagi, itu boleh banget.

## Step 7: Membuat fitur register {#step-7-create-register-feature}
Oke, kita masuk ke fitur utama dari studi kasus tutorial codeigniter 4 ini, yaitu fitur ```register```. Nah, sekarang kita buat file modelnya dulu.

Untuk membuat model, kita akan gunakan command `spark`. Buka kembali terminal, lalu run command berikut ini.

```
php spark make:model UserModel
```

Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:40:04 UTC+00:00

File created: APPPATH\Models\UserModel.php
```

Selanjutnya buka file ```UserModel.php``` di direktori ```app/Models```, lalu kita sesuaikan beberapa atribute dari class `UserModel` seperti berikut ini.

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table = 'users';
    protected $allowedFields = ['name', 'email', 'password'];
    protected $useTimeStamps = true;
    protected $createdField = 'created_at';
    protected $updatedField = 'updated_at';

    protected $validationRules = [
        'name' => 'required',
        'email' => 'required|valid_email|is_unique[users.email]',
        'password' => 'required|min_length[8]'
    ];

    protected $validationMessages = [
        'email' => [
            'is_unique' => 'Sorry, That email has already been taken. Please choose another.'
        ]
    ];

    protected $skipValidation = false;
    protected $beforeInsert = ['hashPassword'];

    protected function hashPassword(array $data)
    {
        if (! isset($data['data']['password'])) {
            return $data;
        }

        $data['data']['password'] = password_hash($data['data']['password'], PASSWORD_DEFAULT);
        return $data;
    }

    
}

```

Nah selanjutnya kita buat controller baru dengan nama ```RegisterController.php```. Buka kembali terminal lalu run command berikut ini.
```
 php spark make:controller RegisterController
```

Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:43:19 UTC+00:00

File created: APPPATH\Controllers\RegisterController.php
```

Sekarang kita akan modifikasi file `Controllers\RegisterController.php`. Pada class `RegisterController` , kita tambahkan method ```index()``` untuk menampilkan halaman register.
```php
<?php namespace App\Controllers;

use App\Models\UserModel;

class RegisterController extends BaseController
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
            'title' => 'Register | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('auth/register', $data);
    }
}

```

Pada baris kode di atas ada kode ```view('auth/register', $data)```, itu artinya file view `register.php` ada di dalam folder `auth`.  Sekarang kita buat terlebih dahulu folder ```auth``` di dalam ```app/Views```. Misalkan foldernya itu sudah kita buat, selanjutnya kita buat file viewsnya dengan nama ```register.php```, lalu kita ketik baris kode di bawah ini:

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-4 offset-md-4">
            <div class="card">
                <div class="card-body">
                    <h4 class="text-center" style="font-weight: bold;">REGISTER</h4>
                    <hr>
                    <?php if (session()->getFlashdata('error')) : ?>
                        <div class="alert alert-danger">
                            <?php echo session()->getFlashdata('error'); ?>
                        </div>
                    <?php endif; ?>

                    <?= validation_list_errors() ?>

                    <?= form_open('register'); ?>
                    <div class="form-group">
                        <label for="name">Nama</label>
                        <input type="text" name="name" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" name="email" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" name="password" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <button class="btn btn-primary">Register</button>
                    </div>
                    <?= form_close(); ?>
                </div>

            </div>
            <div class="text-center mt-2">
                Sudah punya akun? <a href="<?php echo base_url('login'); ?>">Silakan login.</a>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>

```

Selanjutnya untuk menghandle request post, kita buka controller ```RegisterController.php``` lagi. Kita tambahkan method ```store()```:

```php
    public function store()
    {
        $data = $this->request->getPost(['name', 'email', 'password']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->index();
        }

        $user = $this->validator->getValidated();

        $save = $this->model->save($user);

        if ($save) {
            session()->setFlashdata('success', 'Register Berhasil!');
            return redirect()->to(base_url('login'));
        } else {
            session()->setFlashdata('error', $this->model->errors());
            return redirect()->back();
        }
    }
```

Jadi kesseluruhan controller ```RegisterController.php``` menjadi:

```php
<?php

namespace App\Controllers;

use App\Models\UserModel;

class RegisterController extends BaseController
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
            'title' => 'Register | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('auth/register', $data);
    }

    
    public function store()
    {
        $data = $this->request->getPost(['name', 'email', 'password']);

        if (! $this->validateData($data, $this->model->validationRules)) {
            return $this->index();
        }

        $user = $this->validator->getValidated();

        $save = $this->model->save($user);

        if ($save) {
            session()->setFlashdata('success', 'Register Berhasil!');
            return redirect()->to(base_url('login'));
        } else {
            session()->setFlashdata('error', $this->model->errors());
            return redirect()->back();
        }
    }

}

```

Sebentar, sebentar.. di file view `register.php` ada baris kode ini.
```
 <?= form_open('register'); ?>
 ```
 Action formnya itu langsung mengarah ke `register` bukan ke method `store()` yang ada di controller `RegisterController` ya?

Kawan, di tutorial ini kita coba belajar menggunakan route yang ada di codeigniter 4. Action form kita arahkan ke route yang kita tentukan, bukan langsung diarahkan ke method yang ada di controller. Sekarang kita coba atur route terlebih dahulu untuk proses pendaftaran atau register akun. Buka file ```app/Config/Routes.php```. Cari baris kode ini di bagian Route Definition:

```php
$routes->get('/', 'Home::index');

```

Di bawah baris kode tersebut, kita definisikan route untuk register:

```php

$routes->group('register', function($routes){
    $routes->get('/', 'RegisterController::index');
    $routes->post('/', 'RegisterController::store');
});

```

Setelah selesai mendefinisikan route, kita save kembali file ```app/Config/Routes.php```.

## Step 8: Membuat fitur login {#step-8-create-login-feature}
Selanjutnya kita akan menambahkan fitur untuk login. Untuk membuat fitur login, kita akan buat controller baru dengan nama ```LoginController.php```. Buka kembali terminal, lalu run command berikut ini.

```
php spark make:controller LoginController
```
Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:52:56 UTC+00:00

File created: APPPATH\Controllers\LoginController.php
```

Selanjutnya buka file `Controllers\LoginController.php`, lalu kita ketik baris kode di bawah ini:

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
        if ($this->isLoggedIn()) {
            return redirect()->to(base_url('dashboard'));
        }
        
        $data = [
            'title' => 'Login | Seri Tutorial CodeIgniter 4: Login dan Register @ qadrlabs.com'
        ];

        return view('auth/login', $data);
    }

    private function isLoggedIn(): bool
    {
        if (session()->get('logged_in')) {
            return true;
        }

        return false;
    }
}
```

Di dalam controller ```LoginController.php``` terdapat dua method, yaitu method ```index()``` untuk menampilkan halaman login dan method ```isLoggedIn()``` untuk mengecek apakah user sudah dalam keadaan login.

Selanjutnya kita buat file Views baru untuk halaman login dengan nama ```login.php``` di direktori ```app/Views/auth```. Di dalam file `login.php`, kita tambahkan kode berikut ini.

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-4 offset-md-4">
            <div class="card">
                <div class="card-body">
                    <h4 class="text-center" style="font-weight: bold;">LOGIN</h4>
                    <hr>
                    <?php if (session()->getFlashdata('success')) : ?>
                        <div class="alert alert-success">
                            <?php echo session()->getFlashdata('success'); ?>
                        </div>
                    <?php endif; ?>

                    <?php if (session()->getFlashdata('error')) : ?>
                        <div class="alert alert-danger">
                            <?php echo session()->getFlashdata('error'); ?>
                        </div>
                    <?php endif; ?>

                    <?= validation_list_errors() ?>

                    <?= form_open('login'); ?>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" name="email" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" name="password" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <button class="btn btn-primary">Login</button>
                    </div>
                    <?= form_close(); ?>

                </div>

            </div>
            <div class="text-center mt-2">
                Belum punya akun? <a href="<?php echo base_url('register'); ?>">Silakan daftar.</a>
            </div>
        </div>
    </div>
</div>

<?= $this->endSection() ?>
```

Oke, kita save dulu filenya sebelum melanjutkan.

Untuk menghandle proses login, kita tambahkan method baru di controller login kita. Kita buka lagi file ```LoginController.php```, lalu kita tambahkan method ```login()``` di dalam ```class``` ```LoginController```:

```php
    ...kode sebelumnya

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
    
    ... kode setelahnya
```

Sehingga keseluruhan file ```LoginController.php``` menjadi:

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
        if ($this->isLoggedIn()) {
            return redirect()->to(base_url('dashboard'));
        }

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

    private function isLoggedIn(): bool
    {
        if (session()->get('logged_in')) {
            return true;
        }

        return false;
    }
}
```


Berdasarkan alur skenario project login dan register codeigniter 4 yang sudah kita tentukan sebelumnya,  pengguna dialihkan ke halaman dashboard setelah proses login berhasil. Kita buat file controller baru dengan nama ```Dashboard.php```. 

Buka kembali terminal, lalu run command berikut ini.
```
php spark make:controller Dashboard
```
Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 07:57:40 UTC+00:00

File created: APPPATH\Controllers\Dashboard.php
```

Selanjutnya kita sesuaikan class `Dashboard` seperti baris kode di bawah ini:

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

Ya, pada baris kode di atas, terdapat dua method di dalam class ```Dashboard```, yaitu method ```index()``` untuk menampilkan halaman dashboard dan ```isLoggedIn()``` untuk mengecek apakah user sudah login atau belum. Pada method `index()` terdapat algoritma untuk proteksi halaman di mana user tidak bisa mengakses halaman dashboard apabila user belum login. Selain itu, pada method `index()` terdapat kode `return view('dashboard', $data);`. Nah dari kode tersebut, kita tahu file view yang digunakan untuk halaman dashboard, yaitu `dashboard.php`.

Selanjutnya kita buat file views baru untuk halaman dashboard dengan nama ```dashboard.php``` di direktori ```app/Views```, lalu kita sama-sama ketik baris kode di bawah ini:

```html
<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<section class="jumbotron text-center">
    <h1>Welcome, <?= session()->name ?></h1>
    <p>Untuk logout dari sistem silakan klik <a href="<?php echo base_url('logout');?>">Logout</a></p>
</section>

<?= $this->endSection() ?>
```

Ya, isi halaman dashboard ini kita buat sederhana. Di dalamnya ada contoh kode untuk menampilkan data session untuk nama dan ada link untuk logout.

Nah terakhir kita atur route untuk login. Buka kembali file ```app/Config/Routes.php``` lalu kita tambahkan route login dan dashboard di bawah route register.

```

$routes->group('login', function ($routes) {
    $routes->get('/', 'LoginController::index');
    $routes->post('/', 'LoginController::login');
});

$routes->get('/dashboard', 'Dashboard::index');

```

Setelah selesai jangan lupa, disave filenya ya....

## Step 9: Membuat fitur logout {#step-9-create-logout-feature}
Nah fitur terakhir, kita tambahkan fitur logout. Kita buat file controller baru untuk fitur logout dengan nama ```LogoutController.php```. Buka kembali terminal, lalu kita run command berikut ini.
```
php spark make:controller LogoutController
```

Output:
```
CodeIgniter v4.5.1 Command Line Tool - Server Time: 2024-05-08 08:01:13 UTC+00:00

File created: APPPATH\Controllers\LogoutController.php
```


Selanjutnya kita ketik baris kode ini.

```php
<?php namespace App\Controllers;

class LogoutController extends BaseController
{
    public function index()
    {
        
        $userData = [
            'name',
            'email',
            'logged_in'
        ];

        session()->remove($userData);

        return redirect()->to(base_url('login'));

    }

    //--------------------------------------------------------------------

}

```

Dan terakhir kita atur route untuk fitur logout ini. Buka kembali file ```app/Config/Routes.php```, lalu kita tambahkan route logout tepat di bawah route login:

```php

$routes->group('logout', function ($routes) {
    $routes->get('/', 'LogoutController::index');
});
```

Save kembali file `Routes.php`

Ya, akhirnya selesai. 

## **Uji Coba** {#uji-coba}
Setelah menyelesaikan semua langkah di atas, saatnya untuk menguji coba aplikasi yang telah kita buat. Berikut adalah langkah-langkah untuk melakukan uji coba:

1. **Menjalankan Server Development**:
   Buka terminal atau command prompt, lalu jalankan perintah berikut untuk menjalankan server development bawaan CodeIgniter 4:
   ```
   php spark serve
   ```
   Server akan berjalan di `http://localhost:8080`.
	 

2. **Mengakses Halaman Home**:
   Buka browser dan akses `http://localhost:8080`. Kita akan melihat halaman home dengan dua tombol: **Login** dan **Register**.
![Run project codeigniter 4](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/1-run-project-di-browser.png)

3. **Mendaftar Akun Baru**:
   - Klik tombol **Register** untuk menuju halaman pendaftaran.
![akses halaman register](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/2-akses-halaman-register.png)

   - Isi form pendaftaran dengan data yang valid, seperti nama, email, dan password.
 ![isi form pendaftaran](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/3-isi-form-di-halaman-register.png)
   - Setelah mengisi form, klik tombol **Register**.
   - Jika pendaftaran berhasil, Anda akan diarahkan ke halaman login dengan pesan sukses.
![redirect ke halaman login setelah sukses register](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/4-redirect-setelah-sukses-register.png)

4. **Login ke Aplikasi**:
   - Pada halaman login, masukkan email dan password yang telah didaftarkan.
![tes login](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/5-tes-login.png)
   - Klik tombol **Login**.
   - Jika login berhasil, Anda akan diarahkan ke halaman **Dashboard** dengan pesan selamat datang.
![redirect ke halaman dashboard](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/codeigniter/codeigniter4/login-register/6-redirect-setelah-sukses-login.png)

5. **Mengakses Dashboard**:
   - Setelah login, Anda akan melihat halaman dashboard yang menampilkan pesan selamat datang beserta nama Anda.
   - Di halaman ini, Anda juga akan menemukan link untuk **Logout**.

6. **Logout dari Aplikasi**:
   - Klik link **Logout** di halaman dashboard.
   - Anda akan diarahkan kembali ke halaman login, dan session Anda akan dihapus.

7. **Mencoba Login dengan Data yang Salah**:
   - Coba login menggunakan email atau password yang salah.
   - Aplikasi akan menampilkan pesan error yang sesuai, seperti "Email atau password Anda salah."

8. **Mencoba Register dengan Email yang Sudah Terdaftar**:
   - Coba mendaftar lagi menggunakan email yang sudah terdaftar.
   - Aplikasi akan menampilkan pesan error, seperti "Email sudah digunakan."

9. **Memeriksa Database**:
   - Buka phpMyAdmin atau alat manajemen database lainnya.
   - Periksa tabel `users` di database `platform_belajar`. Pastikan data user yang didaftarkan tersimpan dengan benar, termasuk password yang di-hash.

10. **Menguji Proteksi Halaman Dashboard**:
    - Coba akses `http://localhost:8080/dashboard` tanpa login terlebih dahulu.
    - Aplikasi akan mengarahkan Anda kembali ke halaman home karena halaman dashboard dilindungi oleh sistem autentikasi.

---

### **Hasil yang Diharapkan**
- **Register**: User dapat mendaftar dengan email yang unik dan password yang aman.
- **Login**: User dapat login menggunakan email dan password yang telah didaftarkan.
- **Dashboard**: Hanya user yang sudah login yang dapat mengakses halaman dashboard.
- **Logout**: User dapat keluar dari sistem dengan aman, dan session akan dihapus.
- **Validasi Form**: Aplikasi dapat menangani input yang tidak valid, seperti email yang sudah terdaftar atau password yang salah.

---

### **Catatan Penting**
- Pastikan semua dependensi dan ekstensi PHP yang diperlukan sudah terinstall, seperti `intl`, `mbstring`, dan `mysqlnd`.
- Jika terjadi error, periksa log error di folder `writable/logs` untuk mengetahui penyebabnya.
- Untuk keamanan lebih, pastikan untuk menggunakan environment yang tepat (`development` atau `production`) dan jangan lupa untuk mengubah `app.baseURL` sesuai dengan domain aplikasi Anda.

## Kesimpulan {#kesimpulan}
Dalam tutorial ini, kita telah berhasil membangun sebuah **aplikasi platform belajar koding sederhana** dengan fitur **login dan register** menggunakan **CodeIgniter 4**. Mulai dari instalasi dan konfigurasi framework, pembuatan database dengan **Migration**, hingga implementasi fitur authentication seperti **register**, **login**, dan **logout**, kita telah mempelajari langkah-langkah praktis yang dapat langsung diaplikasikan dalam proyek nyata.

#### **Poin-Poin Penting yang Telah Dipelajari:**
1. **Instalasi dan Konfigurasi CodeIgniter 4**: Kita belajar cara menginstal CodeIgniter 4 menggunakan Composer dan mengkonfigurasi environment project.
2. **Membuat Database dengan Migration**: Fitur Migration memudahkan kita dalam membuat dan mengelola struktur database secara terstruktur.
3. **Implementasi Fitur Authentication**: Kita berhasil membuat fitur untuk **register**, **login**, dan **logout** dengan validasi form yang aman.
4. **Templating UI**: Dengan menggunakan sistem layout CodeIgniter 4, kita dapat membuat tampilan UI yang konsisten dan mudah dikelola.
5. **Session Management**: Kita belajar cara mengelola session untuk autentikasi user dan proteksi halaman.

#### **Manfaat yang Didapat:**
- **Pemahaman Dasar CodeIgniter 4**: Tutorial ini memberikan fondasi yang kuat untuk memahami cara kerja CodeIgniter 4, terutama dalam membangun fitur authentication.
- **Keterampilan Authentication**: Anda sekarang memiliki kemampuan untuk mengimplementasikan fitur login dan register dalam aplikasi web.
- **Praktis dan Langsung Dapat Diterapkan**: Langkah-langkah yang dijelaskan dalam tutorial ini dapat langsung diaplikasikan dalam proyek nyata.

#### **Langkah Selanjutnya**
Jika Anda ingin mendalami lebih lanjut tentang CodeIgniter 4, jangan ragu untuk menjelajahi seri tutorial lainnya di [Belajar CodeIgniter 4](https://qadrlabs.com/series/belajar-codeigniter-4). Anda juga dapat mencoba mengembangkan aplikasi ini lebih lanjut, seperti menambahkan fitur autentikasi dua faktor (2FA), validasi form yang lebih kompleks, atau integrasi dengan library pihak ketiga.

Terima kasih telah mengikuti tutorial ini! Semoga panduan ini bermanfaat dan membantu Anda dalam perjalanan belajar pengembangan web dengan CodeIgniter 4. Selamat coding! 😊