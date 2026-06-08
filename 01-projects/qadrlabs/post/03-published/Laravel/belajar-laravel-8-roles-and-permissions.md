---
title: "Belajar Laravel 8: Roles and Permissions"
slug: "belajar-laravel-8-roles-and-permissions"
category: "Laravel"
date: "2021-11-26"
status: "published"
---

Halo, di seri Belajar Laravel 8 edisi kali ini kita akan belajar bagaimana cara menggunakan package **spatie laravel-permission** di project laravel kita. [Spatie laravel-permission](https://github.com/spatie/laravel-permission) adalah sebuah package yang memungkinkan kita untuk mengelola user permission dan role di dalam database. Dengan menggunakan package ini kita juga bisa belajar tentang konsep role dan permission yang sering digunakan untuk membedakan level user untuk mengakses aplikasi yang kita kembangkan.

Ketika kita sudah mengembangkan sebuah aplikasi, kadang terjadi perubahan requirement. Salah satu perubahan itu adalah bertambahnya pengguna dengan level yang berbeda. Salah satu pendekatan solusi yang digunakan adalah membedakan hak akses berdasarkan level user. Admin mengakses halaman admin dan user mengakses halaman user. Solusi sederhana dengan melakukan pengecekan level user lalu diarahkan ke halaman sesuai dengan level user tersebut. Setelah itu muncul pertanyaan, misalkan ada kebutuhan untuk menambahkan level user yang berbeda, tapi dapat mengakses halaman yang sama, apakah harus dibuatkan lagi halaman yang berbeda? Contoh sederhananya di dalam sistem akademik, seorang admin dapat mengakses sebuah dashboard tertentu, lalu terdapat kebutuhan ketua program studi juga mesti bisa akses dashboard itu, dan auditor mesti bisa akses juga. Ya, di sini kita bisa menggunakan pendekatan solusi yang berbeda yaitu menggunakan role dan permission. Dan untuk menerapkan role dan permission ini kita dapat menggunakan package Spatie laravel-permission.

Ada beberapa hal yang akan kita pelajari di edisi [belajar laravel 8](https://qadrlabs.com/series/belajar-laravel-8) tentang role dan permission ini.
1. Cara install package spatie laravel-permission.
2. Persiapan sebelum menggunakan package.
3. Cara membuat permission baru dan merelasikan dengan role.
4. Cara memberikan akses super admin.
5. Penggunaan permission middleware dan pengecekan permission di view.

Karena ada contoh penggunaan, kita akan menambahkan studi kasus dan di sini kita akan menggunakan kembali hasil belajar laravel 8 di edisi sebelumnya, yaitu aplikasi crud sederhana tentang mengelola post. Di edisi belajar 8 kali ini, kita akan coba menambahkan role dan permission di aplikasi tersebut. Role yang akan kita tambahkan ada tiga, yaitu `superadmin`, `admin`, dan `writer`. Pengguna dengan role `writer` dapat melakukan operasi crud post. Sebagai pembeda, role `admin` nanti dapat melakukan publish dan unpublish post selain operasi crud. Sedangkan superadmin bebas bisa melakukan apa saja. Ya, ini hanya contoh, jadi studi kasusnya saya buat sederhana saja.

## Persiapan{#persiapan}
Sebelum memulai, teman-teman boleh mencoba dulu [membuat aplikasi crud sederhana](https://qadrlabs.com/post/belajar-laravel-8-membuat-aplikasi-crud-sederhana) di seri belajar laravel 8 edisi sebelumnya. Sebagai alternatif, teman-teman bisa juga langsung clone dari [repositori hasil belajar laravel 8](https://github.com/qadrLabs/belajar-laravel-8-crud-example), lalu ikuti petunjuknya di README.

Apabila projek laravel sudah siap, kita lanjutkan ke langkah selanjutnya.

## Install Auth Scaffolding{#install-auth-scaffolding}
Ada dua package yang akan kita coba gunakan, yaitu `laravel ui` untuk auth scaffolding dan `spatie laravel-permission` untuk handle `role` dan `permission`.

Berdasarkan repositorinya, `laravel ui` yang support untuk laravel 8.x adalah versi `3.x`. Jadi kita coba install laravel ui yang support untuk laravel 8, kita buka kembali terminal, lalu kita run `command` ini.
```bash
composer require laravel/ui:^3 --dev
```

Setelah proses instalasi selesai, run `command` di bawah ini untuk menggunakan bootstrap UI di auth scaffolding yang akan kita gunakan.
```bash
php artisan ui bootstrap --auth
```

Setelah auth scaffolding terinstall, selanjutnya kita install dependensi dan compile asset untuk user interface auth scaffolding aplikasi kita.
```bash
npm install && npm run dev
```

Kita tunggu sebentar sampai js dan css berhasil di-compile.

## Install laravel permission{#install-laravel-permission}
Langkah selanjutnya adalah menginstall package `spatie laravel permission`. Buka kembali terminal, lalu kita run `command` di bawah ini.
```bash
composer require spatie/laravel-permission
```

Selanjutnya kita publish `spatie laravel-permission` menggunakan `command` di bawah ini.
```bash
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

Kita bisa lihat ada file migration baru untuk table `permissions` dan `role` dari package spatie laravel-permission. Selanjutnya kita run `migration`.
```bash
php artisan migrate
```

Setelah kita run `migration`, kita bisa lihat ada beberapa table baru dari package ini dan juga table `users` di database.

## Penggunaan{#penggunaan}
Untuk menggunakan spatie laravel-permission, kita bisa menambahkan trait Spatie\Permission\Traits\HasRoles ke dalam `User` model. Buka `app/Models/User.php`, lalu kita tambahkan statement `use` di dalam class `User` model.

```php
<?php

use Illuminate\Foundation\Auth\User as Authenticatable;
use Spatie\Permission\Traits\HasRoles;

 // ... baris kode lainnya...

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
    use HasRoles;

    // ... baris kode lainnya...
}

```

Package ini memungkinkan `users` berelasi dengan `permissions` dan juga `roles`. Setiap role berelasi dengan multiple permission.

## Menambahkan Permissions{#add-permission}
Langkah selanjutnya adalah menambahkan beberapa permission dan juga role dengan menggunakan database seeder sesuai dengan yang sudah kita bahas sebelumnya. Buka kembali terminal, lalu kita run `command` untuk membuat seeder.

```bash
php artisan make:seeder PermissionDemoSeeder
```

Setelah `PermissionDemoSeeder` dibuat, selanjutnya buka file `database/seeders/PermissionDemoSeeder.php`. Lalu kita ketik kode berikut ini.

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class PermissionDemoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // reset cahced roles and permission
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        // create permissions
        Permission::create(['name' => 'view posts']);
        Permission::create(['name' => 'create posts']);
        Permission::create(['name' => 'edit posts']);
        Permission::create(['name' => 'delete posts']);
        Permission::create(['name' => 'publish posts']);
        Permission::create(['name' => 'unpublish posts']);

        //create roles and assign existing permissions
        $writerRole = Role::create(['name' => 'writer']);
        $writerRole->givePermissionTo('view posts');
        $writerRole->givePermissionTo('create posts');
        $writerRole->givePermissionTo('edit posts');
        $writerRole->givePermissionTo('delete posts');

        $adminRole = Role::create(['name' => 'admin']);
        $adminRole->givePermissionTo('view posts');
        $adminRole->givePermissionTo('create posts');
        $adminRole->givePermissionTo('edit posts');
        $adminRole->givePermissionTo('delete posts');
        $adminRole->givePermissionTo('publish posts');
        $adminRole->givePermissionTo('unpublish posts');

        $superadminRole = Role::create(['name' => 'super-admin']);
        // gets all permissions via Gate::before rule

        // create demo users
        $user = User::factory()->create([
            'name' => 'Example user',
            'email' => 'writer@qadrlabs.com',
            'password' => bcrypt('12345678')
        ]);
        $user->assignRole($writerRole);

        $user = User::factory()->create([
            'name' => 'Example admin user',
            'email' => 'admin@qadrlabs.com',
            'password' => bcrypt('12345678')
        ]);
        $user->assignRole($adminRole);

        $user = User::factory()->create([
            'name' => 'Example superadmin user',
            'email' => 'superadmin@qadrlabs.com',
            'password' => bcrypt('12345678')
        ]);
        $user->assignRole($superadminRole);
    }
}

```

Di dalam method `run()` dari class `PermissionDemoSeeder`, kita menambahkan tiga tahapan proses, yaitu 
1. Mendefinisikan permission sesuai dengan studi kasus yaitu operasi crud dan operasi untuk publish atau unpublish post, 
2. Mendefinisikan role `writer`, `admin` dan `superadmin`, lalu menambahkan permission untuk masing-masing role 
3. dan membuat demo user dengan rolenya masing-masing.

Jangan lupa kita import beberapa class, menggunakan statement `use` sebelum deklarasi class `PermissionDemoSeeder`.

```php
use App\Models\User;  
use Illuminate\Database\Seeder;  
use Spatie\Permission\Models\Permission;  
use Spatie\Permission\Models\Role;  
use Spatie\Permission\PermissionRegistrar;
```

Selanjutnya kita re-migrate dan juga run seeder.
```bash
php artisan migrate:fresh --seed --seeder=PermissionDemoSeeder
```

Setelah command di atas kita run, kita bisa lihat sample data untuk `permissions`, `roles` dan juga `users`.

## Grant akses Super Admin{#superadmin}
Di class `PermissionDemoSeeder`, kita menambahkan role `super-admin` dan di dalamnya kita belum mendefinisikan `permission` untuk role tersebut. Di sini kita akan coba memberikan akses super admin melalui `gate` di dalam `AuthServiceProvider`. Buka file `app/Providers/AuthServiceProvider.php`, lalu kita modifikasi method `boot()`.

```php
<?php

 // ... baris kode lainnya ...

class AuthServiceProvider extends ServiceProvider
{

    // ... baris kode lainnya ...
		
    public function boot()
    {
        $this->registerPolicies();

        // Implicitly grant "Super Admin" role all permission checks using can()
        Gate::before(function ($user, $ability) {
            if ($user->hasRole('super-admin')) {
                return true;
            }
        });
    }
}

```

Pada baris kode di atas, ketika super admin login ke dalam web, semua pengecekan permission yang memanggil function `call()` atau `@can()` akan bernilai true. Ya, super admin bebas mau melakukan apa saja.

## Menggunakan permission middleware{#use-permission-middleware}
Untuk menggunakan middleware dari spatie laravel-permission, kita harus mendefinisikan middleware-nya terlebih dahulu. Buka file `app/Http/Kernel.php`, lalu cek sekitar baris 56 terdapat `$routeMiddleware`, properties dari class `Kernel`. Kita tambahkan route middleware untuk `role`, `permission` dan `role_or_permission` dari spatie laravel-permission.

```php
    protected $routeMiddleware = [
				// ...

        'role' => \Spatie\Permission\Middlewares\RoleMiddleware::class,
        'permission' => \Spatie\Permission\Middlewares\PermissionMiddleware::class,
        'role_or_permission' => \Spatie\Permission\Middlewares\RoleOrPermissionMiddleware::class,
    ];
```

Di aplikasi studi kasus kita kali ini, terdapat 6 contoh permission untuk crud dan juga status publish. Kita tambahkan dulu action untuk publish dan unpublish di halaman daftar post. Buka file `resources/views/posts/index.blade.php`, lalu kita modifikasi bagian row untuk button actionnya.

```html
<td class="text-center">

    @can('edit posts', Post::class)
        <a href="{{ route('post.edit', $post->id) }}" class="btn btn-sm btn-primary">EDIT</a>
    @endcan

    @can('delete posts', Post::class)
        <form onsubmit="return confirm('Apakah Anda Yakin ?');" action="{{ route('post.destroy', $post->id) }}" method="POST">

            @csrf
            @method('DELETE')
            <button type="submit" class="btn btn-sm btn-danger">HAPUS</button>
        </form>

    @endcan

    @can('publish posts', Post::class)
    <form onsubmit="return confirm('Publish post ini?');" action="{{ route('post.publish', $post->id) }}" method="POST">

        @csrf
        @method('PUT')
        <button type="submit" class="btn btn-sm btn-info">Publish</button>
    </form>

    @endcan

    @can('unpublish posts', Post::class)
    <form onsubmit="return confirm('Unpublish post ini?');" action="{{ route('post.unpublish', $post->id) }}" method="POST">

        @csrf
        @method('PUT')
        <button type="submit" class="btn btn-sm btn-info">Unpublish</button>
    </form>

    @endcan

</td>
```

Pada baris kode di atas, kita menambahkan action untuk publish dan unpublish. Selain itu terdapat pengecekan `permission` menggunakan `@can()`.

Selanjutnya kita tambahkan method sederhana untuk handle publish dan unpublish post. Buka `app/Http/Controllers/PostController.php`, lalu tambahkan dua method `publish()` dan `unpublish()` di dalam class `PostController`.

```php
<?php

// ... baris kode lainnya ...

class PostController extends Controller
{
		// ... baris kode lainnya ...

    public function publish(int $id)
    {
        echo 'post berhasil dipublish';
    }

    public function unpublish(int $id)
    {
        echo 'post berhasil diunpublish';
    }
}

```

Ya, actionnya cuma menampilkan keterangan saja, karena fokus tutorial ini membahas tentang permission jadi kita buat sederhana saja.

Selanjutnya kita tambahkan route untuk menangani action publish dan unpublish. Buka file `routes/web.php`, lalu tambahkan route baru.

```php
Route::put('post/{id}/publish', [PostController::class, 'publish'])->name('post.publish');
Route::put('post/{id}/unpublish', [PostController::class, 'unpublish'])->name('post.unpublish');
```

Dan langkah terakhir adalah menambahkan permission middleware. Sebagai contoh kita akan coba menambahkan permission middleware ini di controller. Buka `app/Http/Controllers/PostController.php`, lalu kita tambahkan middleware di dalam constructor.

```php
<?php

// ... baris kode lainnya ...

class PostController extends Controller
{

    public function __construct()
    {
        $this->middleware('permission:view posts', ['only' => ['index']]);
        $this->middleware('permission:create posts', ['only' => ['create', 'store']]);
        $this->middleware('permission:edit posts', ['only' => ['edit', 'update']]);
        $this->middleware('permission:delete posts', ['only' => ['destroy']]);
        $this->middleware('permission:publish posts', ['only' => ['publish']]);
        $this->middleware('permission:unpublish posts', ['only' => ['unpublish']]);
    }

    // ... baris kode lainnya ...
}

```

Kita menambahkan proteksi untuk masing-masing fitur sesuai dengan permissionnya. Alternatif lain, teman-teman dapat menambahkan middleware ini route.

## Uji coba{#uji-coba}
Untuk menguji coba, kita run `artisan command`:
```php
php artisan serve
```

Setelah itu buka project di browser dengan mengakses `http://127.0.0.1:8000`. Teman-teman bisa coba login menggunakan demo user untuk masing-masing role. Setelah itu coba akses halaman `http://127.0.0.1:8000/post` dengan role yang berbeda. 

Ketika mengakses halaman daftar post, kita bisa lihat ada button yang hanya dilihat oleh role `admin` dan `superadmin` saja, yaitu button action untuk publish dan unpublish. Kenapa demikian? Karena terdapat pengecekan `permission` menggunakan `@can()` di view.
```html
@can('publish posts', Post::class)
<form onsubmit="return confirm('Publish post ini?');" action="{{ route('post.publish', $post->id) }}" method="POST">

    @csrf
    @method('PUT')
    <button type="submit" class="btn btn-sm btn-info">Publish</button>
</form>

@endcan

@can('unpublish posts', Post::class)
<form onsubmit="return confirm('Unpublish post ini?');" action="{{ route('post.unpublish', $post->id) }}" method="POST">

    @csrf
    @method('PUT')
    <button type="submit" class="btn btn-sm btn-info">Unpublish</button>
</form>

@endcan
```

Misalkan kita hapus directive `@can()` untuk publish dan unpublish, kita bisa lihat kembali button publish dan unpublish ketika coba akses dengan role `writer`. Setelah itu kita coba klik salah satu buttonnya, misalkan kita klik button `publish`, kita bisa lihat keterangan `403 | USER DOES NOT HAVE THE RIGHT PERMISSIONS` tanda permission middleware berjalan dengan baik.

## Penutup{#penutup}
Pada seri Belajar Laravel 8 ini kita sudah coba menerapkan role dan permission di project laravel yang sebelumnya sudah kita buat menggunakan package spatie laravel-permission. Kita sudah belajar cara install package, cara membuat permission dan role, cara menerapkan akses super admin dan cara menggunakan permission middleware di controller dan juga pengecekan permission di view.

Setelah mencoba, apa lagi yang bisa kita eksplore? Karena yang ada di edisi belajar kali ini masih contoh penggunaan dasar, tentu ada banyak hal yang kita eksplore, misalnya bagaimana cara menggunakan `model policies`, best practices antara `role` vs `permission`, tentang performance tips, testing, dan lain-lain. Selamat mencoba..