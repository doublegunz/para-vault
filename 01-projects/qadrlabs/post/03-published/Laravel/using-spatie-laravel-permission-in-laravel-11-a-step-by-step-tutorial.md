---
title: "Using Spatie Laravel Permission IN LARAVEL 11+:  A Step-by-Step Tutorial"
slug: "using-spatie-laravel-permission-in-laravel-11-a-step-by-step-tutorial"
category: "Laravel"
date: "2025-01-11"
status: "published"
---

Pada seri tutorial Belajar Laravel 8 tentang [Role and Permission](https://qadrlabs.com/post/belajar-laravel-8-roles-and-permissions), kita sudah belajar cara menggunakan package spatie laravel-permission. Pada tutorial tersebut kita sudah belajar dimulai dari setup package, contoh penggunaan sampai dengan uji coba. Namun setelah laravel 11 rilis, tutorial tersebut tidak bisa kita gunakan karena terdapat perbedaan konfigurasi laravel 11 dengan laravel versi sebelumnya. Oleh karena itu kita akan coba bahas kembali tentang role dan permission menggunakan package Spatie Laravel Permission.

## Overview {#overview}

Tutorial ini akan membahas cara mengimplementasikan role dan permission di Laravel 11 menggunakan package Spatie Laravel Permission. Kita akan membangun sebuah sistem pengelolaan user dengan hak akses berbeda untuk setiap role, sehingga setiap user hanya dapat mengakses fitur sesuai dengan permission yang dimiliki.

### Apa yang akan dipelajari

- Setup dan konfigurasi Spatie Laravel Permission di Laravel 11
- Perbedaan konfigurasi middleware di Laravel 11 dibanding versi sebelumnya
- Pembuatan dan pengelolaan role dan permission
- Implementasi permission middleware di controller
- Penggunaan blade directive untuk mengatur tampilan berdasarkan permission
- Pengujian sistem role dan permission dengan berbagai skenario user

### Goals

Setelah mengikuti tutorial ini, teman-teman diharapkan dapat:

- Memahami konsep dasar role dan permission di Laravel
- Mengimplementasikan sistem role dan permission menggunakan Spatie Laravel Permission
- Mengelola hak akses user berdasarkan role dan permission
- Mengamankan route dan tampilan berdasarkan permission user
- Menerapkan best practice dalam implementasi role dan permission di Laravel 11

### Prasyarat

Untuk mengikuti tutorial ini, teman-teman memerlukan:

- Pengetahuan dasar Laravel dan PHP
- PHP 8.2 atau versi lebih tinggi
- Composer untuk instalasi package
- Node.js dan NPM untuk mengelola frontend assets
- Database MySQL atau PostgreSQL
- Text editor atau IDE (Visual Studio Code, PHPStorm, dll)
- Telah mengikuti tutorial CRUD Laravel 11 sebelumnya atau mengclone repository [crud-laravel-11](https://github.com/qadrLabs/crud-laravel-11)

Dengan memenuhi prasyarat di atas, teman-teman akan dapat mengikuti tutorial ini dengan lebih mudah dan mendapatkan hasil yang optimal.

## Persiapan {#persiapan}

Pertama, kita persiapkan dulu sample aplikasi dari [tutorial crud](https://qadrlabs.com/post/percobaan-development-crud-app-sederhana-menggunakan-laravel-11) untuk mengelola user. Apabila teman-teman belum sempat mengikuti tutorial tersebut, teman-teman bisa clone dari repositori [crud laravel 11](https://github.com/qadrLabs/crud-laravel-11) lalu ikuti petunjuk setup di bagian [How to use](https://github.com/qadrLabs/crud-laravel-11?tab=readme-ov-file#how-to-use).

Kedua kita akan gunakan Node Package Manager (NPM) untuk install frontend dependensi dan juga compile assets. Jadi pastikan sudah menginstall NPM. Apabila NPM belum terinstall dan OS yang kita gunakan itu Ubuntu, kita bisa setup terlebih dahulu dengan mengikuti [tutorial install nodejs ini](https://qadrlabs.com/post/cara-install-multiple-node-js-version-menggunakan-nvm-di-ubuntu-22-04).



## Step 1: Install Package Auth Scaffolding {#step-1-install-package-auth-scaffolding}

Pada tutorial crud 11, kita sudah gunakan bootstrap untuk user interface-nya. Jadi supaya sama-sama menggunakan bootstrap pada ui autentikasinya kita akan gunakan [https://github.com/laravel/ui](https://github.com/laravel/ui). Tentu saja teman-teman bisa gunakan starter kit lainnya, seperti laravel breeze atau laravel jetstream.



Untuk install laravel ui, kita buka terminal lalu kita masuk ke direktori project kita dan setelah itu kita install laravel ui dengan run command berikut ini.

```
composer require laravel/ui
```

Setelah `laravel/ui` terinstall, selanjutnya kita install auth scaffolding dengan bootstrap.

```
php artisan ui bootstrap --auth
```

Ketika tampil prompt seperti berikut:

```
The [Controller.php] file already exists. Do you want to replace it? (yes/no) [yes]

```

Kita ketik `yes`, lalu tekan `enter` untuk melanjutkan.

```
$ php artisan ui bootstrap --auth

  The [Controller.php] file already exists. Do you want to replace it? (yes/no) [yes]
❯ yes

   INFO  Authentication scaffolding generated successfully.  

   INFO  Bootstrap scaffolding installed successfully.  

   WARN  Please run [npm install && npm run dev] to compile your fresh scaffolding. 
```

Seperti petunjuk pada output yang ditampilkan setelah proses generate selesai, kita run command berikut ini.

```
npm install && npm run dev
```

Output yang ditampilkan setelah selesai.

```
$ npm install && npm run dev

added 39 packages, and audited 40 packages in 10s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

> dev
> vite


  VITE v5.4.11  ready in 144 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help

  LARAVEL v11.37.0  plugin v1.1.1

  ➜  APP_URL: http://localhost
```

Selanjutnya kita bisa stop command `npm run dev` dengan menekan tombol `CTRL+c`, lalu kita bisa langsung build menggunakan command.

```
npm run build
```

Selanjutnya kita bisa run `php artisan serve`, lalu akses `http://127.0.0.1:8000/login` di browser dan kita bisa lihat halaman login.

Selain itu terdapat definisi route baru di `routes/web.php`.

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', [\App\Http\Controllers\UserController::class, 'index']);

Route::resource('user', \App\Http\Controllers\UserController::class);

Auth::routes();

Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');

```



## Step 2: Install Package Spatie Laravel-Permission {#step-2-install-package-spatie-laravel-permission}

Pada step ini kita install Package spatie `laravel-permission` menggunakan composer.

```
composer require spatie/laravel-permission
```

Setelah proses install package selesai, selanjutnya kita publish migration dan file config.

```
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

Output:

```
$ php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"

   INFO  Publishing assets.  

  Copying file [vendor/spatie/laravel-permission/config/permission.php] to [config/permission.php]  DONE
  Copying file [vendor/spatie/laravel-permission/database/migrations/create_permission_tables.php.stub] to [database/migrations/2025_01_11_020329_create_permission_tables.php]  DONE

```



Selanjutnya kita clear cache konfigurasi terlebih dahulu sebelum run migration.

```
php artisan config:clear
```

output:

```
$ php artisan config:clear

   INFO  Configuration cache cleared successfully.  
```

Setelah itu kita run migration.

```
php artisan migrate
```

Output:

```
2$ php artisan migrate

   INFO  Running migrations.  

  2025_01_11_020329_create_permission_tables .................... 34.64ms DONE

```



## Step 3: Menambahkan Trait ke User Model {#step-3-menambahkan-trait-ke-user-model}

Selanjutnya kita buka file `app/Models/User.php`. Pada class `User`, kita tambahkan trait `HasRoles`.

```php
<?php

namespace App\Models;


// baris kode lainnya

use Spatie\Permission\Traits\HasRoles; // tambahkan ini

class User extends Authenticatable
{
    use HasFactory, Notifiable;
    use HasRoles; // tambahkan ini

    // baris kode lainnya
}

```

Selanjutnya save kembali file `app/Models/User.php`.



## Step 4: Register Alias untuk Package Middleware {#step-4-register-alias-untuk-package-middleware}

Untuk menambahkan alias pada laravel 11 berbeda dengan laravel versi sebelumnya. Di laravel versi sebelumnya, kita menambahkan di file `app/Http/Kernel.php`, sedangkan di versi terbaru (laravel 11) kita perlu menambahkan di file `bootstrap/app.php`.

Sekarang buka file `bootstrap/app.php`, lalu tambahkan alias pada bagian `withMiddleware()`

```php
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);
    })
```

save kembali file `bootstrap/app.php`.

## Step 5: Mendefinisikan Super Admin {#step-5-mendefinisikan-super-admin}

Untuk mendefinisikan user dengan role `super-admin`, kita akan handle dengan mengatur rule global di `Gate::before` dengan mengecek apakah role user `super-admin` atau bukan. Setelah itu kita bisa implementasikan best practice menggunakan `permission-based` control (seperti `@can`, `$user-can` dan lain-lain) di dalam aplikasi yang kita bangun.

Berbeda dengan laravel versi sebelumnya, di laravel 11 kita perlu definisikan di file `app/Providers/AppServiceProvider.php`. Kita buka terlebih dahulu file `app/Providers/AppServiceProvider.php`, lalu kita modifikasi method `boot()`.

```php
<?php

namespace App\Providers;

// baris kode lainnya

use Illuminate\Support\Facades\Gate; // tambahkan ini

class AppServiceProvider extends ServiceProvider
{
    // baris kode lainnya


    public function boot(): void
    {
        Paginator::useBootstrapFive();


        // tambahkan baris kode berikut ini
        Gate::before(function ($user, $ability) {
            return $user->hasRole('super-admin') ? true : null;
        });
    }
}
```

Save kembali file.

Pada tahapan ini kita sudah selesai setup package spatie `laravel-permission`. Selanjutnya kita akan mulai masuk ke dalam studi kasus untuk fitur mengelola user.



## Step 6: Menambahkan Field Status Ke Table Users {#step-6-menambahkan-field-status-ke-table-users}

Karena kita akan menambah permission untuk suspend atau block user, kita harus menambahkan field baru untuk menangani status user. Buka kembali terminal, lalu kita buat file migration baru.

```
php artisan make:migration add_status_to_users_table --table=users
```

Output:

```
$ php artisan make:migration add_status_to_users_table --table=users

   INFO  Migration [database/migrations/2025_01_11_025146_add_status_to_users_table.php] created successfully.  

```

Selanjutnya buka file migration `database/migrations/xxxx_xx_xx_xxxxxx_add_status_to_users_table.php`, lalu kita sesuaikan dengan baris kode berikut ini.

```php
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
            $table->string('status')->default('active')->after('password')
                ->comment('status: active, suspended, blocked');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('status');
        });
    }
};
```

Save kembali file migration.

Selanjutnya kita run command migration.

```
php artisan migrate
```

Sekarang buka file `app/Models/User.php`, lalu tambahkan `status` ke `$fillable`.

```php
    protected $fillable = [
        'name',
        'email',
        'password',
        'status', // tambahkan
    ];
```

Selanjutnya save kembali file `app/Models/User.php`.



## Step 7: Membuat Seeder Role dan Permission {#step-7-membuat-seeder-role-dan-permission}

Sekarang kita akan membuat seeder untuk role, permission dan juga user. Buka kembali  terminal, lalu run command berikut ini untuk generate seeder.

```
php artisan make:seed RolePermissionSeeder
```

Output:

```
$ php artisan make:seed RolePermissionSeeder

   INFO  Seeder [database/seeders/RolePermissionSeeder.php] created successfully
```

Selanjutnya kita buka file `database/seeders/RolePermissionSeeder.php`, lalu kita sesuaikan menjadi seperti baris kode berikut ini.

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolePermissionSeeder extends Seeder
{
    /**
     * Create the initial roles and permissions.
     */
    public function run(): void
    {
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        // create permission
        Permission::create(['name' => 'view any users']);
        Permission::create(['name' => 'create users']);
        Permission::create(['name' => 'view users']);
        Permission::create(['name' => 'update users']);
        Permission::create(['name' => 'delete users']);

        Permission::create(['name' => 'view any roles']);
        Permission::create(['name' => 'create roles']);
        Permission::create(['name' => 'view roles']);
        Permission::create(['name' => 'update roles']);
        Permission::create(['name' => 'delete roles']);

        Permission::create(['name' => 'view any permissions']);
        Permission::create(['name' => 'create permissions']);
        Permission::create(['name' => 'view permissions']);
        Permission::create(['name' => 'update permissions']);
        Permission::create(['name' => 'delete permissions']);

        // create role
        $superAdminRole = Role::create(['name' => 'super-admin']); // gets all permissions via Gate::before rule;

        $adminRole = Role::create(['name' => 'admin']);
        $adminRole->givePermissionTo('view any users');
        $adminRole->givePermissionTo('create users');
        $adminRole->givePermissionTo('view users');
        $adminRole->givePermissionTo('update users');
        $adminRole->givePermissionTo('delete users');

        $moderatorRole = Role::create(['name' => 'moderator']);
        $moderatorRole->givePermissionTo('view any users');
        $moderatorRole->givePermissionTo('view users');
        $moderatorRole->givePermissionTo('update users');

        // create users
        $superAdminUser = User::factory()->create([
            'name' => 'Super Admin',
            'email' => 'superadmin@example.com',
        ]);
        $superAdminUser->assignRole($superAdminRole);

        $adminUser = User::factory()->create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
        ]);
        $adminUser->assignRole($adminRole);

        $moderatorUser = User::factory()->create([
            'name' => 'Moderator',
            'email' => 'moderator@example.com',
        ]);
        $moderatorUser->assignRole($moderatorRole);
    }
}

```

Selanjutnya buka file `database/seeders/DatabaseSeeder.php`, lalu kita sesuaikan isi dari method `run()`.

```php
<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RolePermissionSeeder::class,
        ]);
    }
}

```

Setelah itu kita running seeder dengan command berikut ini.

```
php artisan db:seed
```

Output:

```
$ php artisan db:seed

   INFO  Seeding database.  

  Database\Seeders\RolePermissionSeeder .............................. RUNNING  
  Database\Seeders\RolePermissionSeeder .......................... 628 ms DONE 
```

Seeder sudah berhasil kita running dan sekarang kita sudah punya sample data akun user yang berelasi dengan role dan permission.



## Step 8: Menggunakan Permission Middleware {#step-8-menggunakan-permission-middleware}

Sekarang kita akan modifikasi kembali code fitur user management pada aplikasi sample crud laravel 11. Pada step ini kita akan gunakan permission middleware untuk masing-masing fitur, sehingga setiap akun user dapat mengakses fitur sesuai dengan permission yang terdapat pada role akun user tersebut.

Buka file `app/Http/Controllers/UserController.php`, lalu kita tambahkan middleware di method constructor class `UserController`.

```
<?php

namespace App\Http\Controllers;

// baris kode lainnya

class UserController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
        $this->middleware('permission:view any users', ['only' => ['index']]);
        $this->middleware('permission:create users', ['only' => ['create', 'store']]);
        $this->middleware('permission:update users', ['only' => ['edit', 'update']]);
        $this->middleware('permission:delete users', ['only' => ['destroy']]);

    }

    // baris kode lainnya
}
```

Pada baris kode di atas, kita gunakan alias middleware `permission` yang sebelumnya sudah kita daftarkan di [step 4](#step-4-register-alias-untuk-package-middleware) sebelumnya. Sebagai informasi, middleware dari package spatie `laravel-permission` dapat kita gunakan di `routes` juga.



## Step 9: Menggunakan Blade Directives {#step-9-menggunakan-blade-directives}

Setelah kita tambahkan middleware, kita juga bisa menambahkan pengecekan permission menggunakan `@can` directive.

Buka kembali file `resources/views/users/index.blade.php`, lalu temukan baris kode berikut ini.

```html
<a href="{{ route('user.create') }}" class="btn btn-md btn-success mb-3 float-end">New User</a>
```

Sekarang kita tambahkan pengecekan permission `create users`.

```html
@can('create users')
<a href="{{ route('user.create') }}" class="btn btn-md btn-success mb-3 float-end">New User</a>
@endcan
```

Sekarang temukan button untuk edit dan delete data.

```html
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
```

Kita modifikasi dan kita tambahkan pengecekan permission `update users` dan `delete users`.

```html
<td>
    @can('update users')
    <a href="{{ route('user.edit', $user->id) }}"
       class="btn btn-sm btn-primary">EDIT</a>
    @endcan
    
    @can('delete users')
    <form onsubmit="return confirm('Apakah Anda Yakin ?');"
          action="{{ route('user.destroy', $user->id) }}" method="POST">

        @csrf
        @method('DELETE')
        <button type="submit" class="btn btn-sm btn-danger">DELETE</button>
    </form>
    @endcan
</td>
```

Sekarang kita save kembali file `resources/views/users/index.blade.php`.



## Step 10: Uji Coba {#step-10-uji-coba}

Pada step ini kita akan coba run project crud laravel 11 untuk menguji apakah implementasi role dan permission kita berhasil. Sekarang kita run terlebih dahulu project kita.

```
php artisan serve
```

Lalu buka `http://127.0.0.1:8000` di browser dan kita bisa lihat aplikasi mengalihkan ke halaman login. Untuk login, kita akan gunakan akun yang sebelumnya sudah kita tambahkan ketika kita run command `db:seed` di step sebelumnya. Apabila teman-teman lupa akunnya, teman-teman bisa cek di file  `database/seeders/RolePermissionSeeder.php`.

### Uji Coba Login Sebagai Super Admin

Pada halaman login, kita coba masukan email dan password akun user dengan role `super admin`, yaitu `superadmin@example.com` dan `password`. Setelah berhasil login, kita bisa lihat daftar halaman `User List` lengkap dengan button dan link menuju masing-masing fitur, yaitu link `New User` untuk akses form tambah data, link `EDIT` untuk akses halaman form edit data, dan button `DELETE` untuk menghapus data.

![Uji Coba Login Sebagai role superadmin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/use-spatie-laravel-permission-in-laravel-11/1-uji-coba-login-sebagai-role-superadmin.png)

Kita bisa langsung uji coba menambahkan data, memperbaharui data, dan menghapus data seperti biasa. Pada saat tutorial ini ditulis dan diujicoba pada tanggal 11 Januari 2025, semua fitur dapat digunakan dengan baik.

Apabila kita telah selesai, kita bisa akses halaman home dengan mengakses `http://127.0.0.1:8000/home` di browser.

![Logout sebagai user dengan role superadmin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/use-spatie-laravel-permission-in-laravel-11/2-logout-sebagai-superadmin.png)

Lalu pada dropdown di text nama user, kita tekan link `Logout` untuk logout dari aplikasi sebagai `super admin`.

### Uji Coba Login Sebagai Admin

Selanjutnya kita akan coba login menggunakan akun user dengan role `admin`, yaitu dengan email `admin@example.com` dan password `password`. 

![Uji coba login sebagai role admin](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/use-spatie-laravel-permission-in-laravel-11/3-uji-coba-login-sebagai-role-admin.png)

Sama seperti role `super admin`, role `admin` dapat mengakses fitur yang sama. Karena ketika assign permission, role `admin` memiliki permission untuk crud data user. Kita bisa cek kembali di file `database/seeders/RolePermissionSeeder.php`.

```php
$adminRole = Role::create(['name' => 'admin']);
$adminRole->givePermissionTo('view any users');
$adminRole->givePermissionTo('create users');
$adminRole->givePermissionTo('view users');
$adminRole->givePermissionTo('update users');
$adminRole->givePermissionTo('delete users');
```

Untuk logout, kita bisa gunakan cara yang sama, yaitu akses halaman home, lalu klik link `Logout`.



### Uji Coba Login Sebagai Moderator

Ketika kita login sebagai role `super admin` dan `admin`, kita tidak bisa lihat perbedaan karena kedua role memiliki permission yang sama. Pada uji coba kali ini kita bisa lihat perbedaannya. Mari kita buka kembali halaman login, lalu kita login sebagai moderator menggunakan email `moderator@example.com` dan password `password`. Setelah berhasil login kita bisa lihat halaman `User List` seperti pada gambar screenshot berikut ini.

![Uji coba login sebagai role moderator](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/use-spatie-laravel-permission-in-laravel-11/4-uji-coba-login-sebagai-role-moderator.png)

Pada gambar di atas, kita bisa lihat hanya ada link `EDIT` saja, sedangkan link `New User` untuk mengakses halaman form tambah data dan button `DELETE` untuk menghapus data tidak ditampilkan. Karena role moderator hanya memiliki permission untuk `view any users`, `view users` dan `update users`.

```php
$moderatorRole = Role::create(['name' => 'moderator']);
$moderatorRole->givePermissionTo('view any users');
$moderatorRole->givePermissionTo('view users');
$moderatorRole->givePermissionTo('update users');
```

Sekarang kita coba akses halaman form tambah data dengan mengakses langsung `http://127.0.0.1:8000/user/create` di browser dan kita bisa lihat tampilan berikut ini.

![Uji coba akses halaman form tambah data dengan role sebagai moderator](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/use-spatie-laravel-permission-in-laravel-11/5-uji-coba-akses-halaman-tambah-data-dengan-role-sebagai-moderator.png)

Kita bisa lihat terdapat error `403` dengan keterangan `User does not have the right permissions.`. Halaman ini tidak dapat diakses karena kita sudah menambahkan middleware di method constructor pada class `UserController`.

```php
$this->middleware('permission:create users', ['only' => ['create', 'store']]);
```

Sedangkan role `moderator` tidak memiliki permission `create users`. Untuk fitur `delete` data, kita tidak bisa menguji langsung di browser, karena fitur tersebut hanya dapat di akses dengan http method `DELETE`.

Pada tahapan uji coba ini kita bisa mengambil kesimpulan middleware dan blade direktive untuk pengecekan permission berjalan dengan baik.

## Penutup {#penutup}

Pada tutorial ini kita telah berhasil mengimplementasikan package Spatie Laravel Permission di Laravel 11. Kita sudah mempelajari beberapa hal penting, mulai dari:

- Setup package dan konfigurasi yang berbeda dengan versi Laravel sebelumnya, terutama pada bagian registrasi middleware di `bootstrap/app.php`
- Pembuatan role dan permission menggunakan seeder
- Implementasi permission middleware di controller
- Penggunaan blade directive untuk menampilkan atau menyembunyikan fitur berdasarkan permission
- Pengujian implementasi dengan berbagai role user yang memiliki permission berbeda

Dengan menggunakan package Spatie Laravel Permission, kita dapat dengan mudah mengelola hak akses user berdasarkan role dan permission. Package ini sangat flexible dan dapat disesuaikan dengan kebutuhan aplikasi yang kita bangun. Selain itu, implementasi role dan permission juga membantu kita dalam mengamankan aplikasi dengan membatasi akses user sesuai dengan peran mereka masing-masing.

Teman-teman dapat mengembangkan lebih lanjut implementasi role dan permission ini sesuai dengan kebutuhan aplikasi yang sedang dikembangkan, misalnya dengan menambahkan fitur management role dan permission, atau mengimplementasikan permission yang lebih spesifik untuk fitur-fitur lainnya.

Semoga tutorial ini bermanfaat dan dapat membantu teman-teman dalam mengimplementasikan role dan permission di aplikasi Laravel 11. Jangan lupa untuk selalu mengecek dokumentasi resmi package Spatie Laravel Permission untuk informasi lebih detail dan update terbaru.