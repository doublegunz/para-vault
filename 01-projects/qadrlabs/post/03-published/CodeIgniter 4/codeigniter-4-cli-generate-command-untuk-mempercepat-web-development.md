---
title: "CodeIgniter 4 CLI Generate Command untuk Mempercepat Web Development"
slug: "codeigniter-4-cli-generate-command-untuk-mempercepat-web-development"
category: "CodeIgniter 4"
date: "2022-06-04"
status: "published"
---

Pada saat kita mengembangkan web menggunakan framework CodeIgniter 3, hampir semua kode kita tulis secara manual. Dimulai dengan coding controller, model ataupun class  lainnya. Berbeda dengan pendahulunya, sekarang CodeIgniter 4 dilengkapi dengan generator yang memudahkan kita untuk membuat controller, model, entity class dan lain-lain. Dan bisa juga generate satu set code hanya dengan run satu command. Seperti apa cli command-nya? Yuk kita bahas!

## Generate Controller Class{#generate-controller}
Seperti yang kita ketahui, controller adalah sebuah class yang menangani sebuah HTTP request. Untuk generate file controller baru, kita bisa run `command` dengan format berikut ini:
```
php spark make:controller <nama-controller> [options]
```

Sebagai contoh misalkan kita ingin generate file controller dengan nama `PostController`, kita run command di bawah ini.
```
php spark make:controller PostController
```

Kurang lebih output yang ditampilkan di terminal seperti di bawah ini.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 10:55:05 UTC+00:00

File created: APPPATH/Controllers/PostController.php
```

Terdapat keterangan ada file baru yang berhasil dibuat, yaitu file `Controllers/PostController.php`. Selanjutnya kita coba buka file `Controllers/PostController.php` di text editor. Kita bisa lihat ada class controller, yaitu `PostController` dengan satu method default `index()`.

```php
<?php

namespace App\Controllers;

use App\Controllers\BaseController;
use CodeIgniter\HTTP\ResponseInterface;

class PostController extends BaseController
{
    public function index()
    {
        //
    }
}
```

Pada baris kode di atas, `PostController` secara default extends atau merupakan class turunan dari class `BaseController`. Nah, misalkan kita ingin buat class dengan tujuan yang berbeda, misalnya untuk Restful resource. Kita bisa tambahkan opsi `--restful`.
```
php spark make:controller ProductController --restful
```

Sama seperti sebelumnya output yang ditampilkan di terminal adalah keterangan file berhasil dibuat.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 10:56:02 UTC+00:00

File created: APPPATH/Controllers/ProductController.php

```

Sekarang kita coba buka file `Controllers/ProductController.php` di text editor. 
```php
<?php

namespace App\Controllers;

use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\RESTful\ResourceController;

class ProductController extends ResourceController
{
    /**
     * Return an array of resource objects, themselves in array format.
     *
     * @return ResponseInterface
     */
    public function index()
    {
        //
    }

    /**
     * Return the properties of a resource object.
     *
     * @param int|string|null $id
     *
     * @return ResponseInterface
     */
    public function show($id = null)
    {
        //
    }

    /**
     * Return a new resource object, with default properties.
     *
     * @return ResponseInterface
     */
    public function new()
    {
        //
    }

    /**
     * Create a new resource object, from "posted" parameters.
     *
     * @return ResponseInterface
     */
    public function create()
    {
        //
    }

    /**
     * Return the editable properties of a resource object.
     *
     * @param int|string|null $id
     *
     * @return ResponseInterface
     */
    public function edit($id = null)
    {
        //
    }

    /**
     * Add or update a model resource, from "posted" properties.
     *
     * @param int|string|null $id
     *
     * @return ResponseInterface
     */
    public function update($id = null)
    {
        //
    }

    /**
     * Delete the designated resource object from the model.
     *
     * @param int|string|null $id
     *
     * @return ResponseInterface
     */
    public function delete($id = null)
    {
        //
    }
}

```

Berbeda dengan class hasil generate command sebelumnya, class `ProductController` extends atau turunan dari class `ResourceController` dan memiliki beberapa method hasil generate.

## Generate Model Class{#generate-model}
Model pada CodeIgniter menyediakan fitur yang memudahkan dan terdapat manfaat tambahan yang sering digunakan untuk bekerja dengan sebuah table pada database. Model memiliki method yang dapat digunakan untuk berinteraksi dengan database seperti mencari data, update data, menghapus data dan lain-lain. Selain dengan banyaknya method dalam model, sekarang kita bisa generate class model ini dengan satu command. Sama seperti controller, command untuk generate model memiliki format seperti berikut ini:
```
php spark make:model <nama-model> [options]
```

Sebagai contoh, kita coba buat class model baru dengan nama `PostModel`. Kita run command berikut ini.
```
php spark make:model PostModel
```

Sama seperti sebelumnya, output yang ditampilkan di terminal adalah keterangan bahwa file `PostModel.php` telah dibuat.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 10:56:46 UTC+00:00

File created: APPPATH/Models/PostModel.php

```

Selanjutnya kita coba cek seperti apa sih hasil generate-nya? Kita buka file `Models/PostModel.php` di text editor dan kurang lebih hasil generate-nya seperti baris kode di bawah ini.

```php
<?php

namespace App\Models;

use CodeIgniter\Model;

class PostModel extends Model
{
    protected $table            = 'posts';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $allowedFields    = [];

    protected bool $allowEmptyInserts = false;
    protected bool $updateOnlyChanged = true;

    protected array $casts = [];
    protected array $castHandlers = [];

    // Dates
    protected $useTimestamps = false;
    protected $dateFormat    = 'datetime';
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';
    protected $deletedField  = 'deleted_at';

    // Validation
    protected $validationRules      = [];
    protected $validationMessages   = [];
    protected $skipValidation       = false;
    protected $cleanValidationRules = true;

    // Callbacks
    protected $allowCallbacks = true;
    protected $beforeInsert   = [];
    protected $afterInsert    = [];
    protected $beforeUpdate   = [];
    protected $afterUpdate    = [];
    protected $beforeFind     = [];
    protected $afterFind      = [];
    protected $beforeDelete   = [];
    protected $afterDelete    = [];
}

```

Ya, berbeda dengan coding manual, file model hasil generate menampilkan banyak properties yang dimiliki model class. Kalau biasanya kita hanya memodifikasi bagian properties `$table`, `$allowedFields`, dan `$validation`, sekarang kita bisa lebih mengoptimalkan penggunaan model sesuai dengan kebutuhan.

## Generate Entity Class{#generate-entity}
CodeIgniter mendukung entity class sebagai class pertama dari layer database. Biasanya class ini digunakan sebagai bagian dari repository pattern, sekarang bisa juga digunakan langsung dengan Model sesuai dengan kebutuhan. Entity class itu sederhananya class yang merepresentasikan sebuah baris database. Class ini memiliki property yang merepresentasikan kolom pada database, dan mendukung method tambahan untuk mengimplementasikan business logic untuk baris tersebut.

Untuk menggenerate sebuah entity class, kita bisa gunakan command dengan format.
```
php spark make:entity <nama-entity> [options]
```

Sebagai contoh kita coba buat entity untuk `Post`, kita run command di bawah ini.
```
php spark make:entity Post
```

Setelah command kita run, output yang ditampilkan terminal kurang lebih seperti ini.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 10:57:54 UTC+00:00

File created: APPPATH/Entities/Post.php

```

Selanjutnya kita bisa buka file `Entities/Post.php` di text editor.
```php
<?php

namespace App\Entities;

use CodeIgniter\Entity\Entity;

class Post extends Entity
{
    protected $datamap = [];
    protected $dates   = ['created_at', 'updated_at', 'deleted_at'];
    protected $casts   = [];
}

```

Pada baris kode di atas, secara default `Post` class memiliki properties hasil generate `$datamap`, `$dates` dan `$casts`.

## Generate Migration File{#generate-migration}
Migration adalah cara mudah untuk memodifikasi database dengan cara yang terstruktur dan terorganisasi. Dengan menggunakan migration ini, setiap ada perubahan pada database atau migration mana yang sudah dirun akan terlacak dan disimpan di dalam table migration. Jadi nantinya database yang akan digunakan sesuai dengan migration yang terbaru. Untuk generate migration file, kita bisa run command dengan format berikut ini.
```
php spark make:migration <nama-class> [options]
```

Contohnya kita coba buat file migration untuk `Post` table. Kita run command berikut ini.
```
php spark make:migration Post
```

Output yang ditampilkan di terminal setelah run command.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 10:59:24 UTC+00:00

File created: APPPATH/Database/Migrations/2025-02-24-105924_Post.php

```

File migration hasil generate memiliki format nama sesuai dengan timestamp saat migration file dibuat. Saat tulisan ini dibuat, nama file hasil generate adalah `2025-02-24-105924_Post.php` dan kalau kita buka filenya di text editor kita bisa lihat ada class `Post` extends ke `Migration` class.

```php
<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class Post extends Migration
{
    public function up()
    {
        //
    }

    public function down()
    {
        //
    }
}

```

## Generate Seeder{#generate-seeder}
Database seeding adalah cara sederhana untuk menambahkan data ke dalam database. Biasanya database seed ini sangat bermanfaat pada saat development, terutama saat kita perlu sample data.

Untuk generate sebuah seeder class, kita run command dengan format:
```
php spark make:seeder <nama-seeder> [options]
```

Di sini kita coba generate seeder untuk menambahkan data post.
```
php spark make:seeder PostSeeder
```

Output:
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 11:00:14 UTC+00:00

File created: APPPATH/Database/Seeds/PostSeeder.php

```

Selanjutnya kita coba buka file `Database/Seeds/PostSeeder.php` hasil generate.
```php
<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class PostSeeder extends Seeder
{
    public function run()
    {
        //
    }
}
```
Class `PostSeeder` dan method `run()` sudah digenerate, jadi nanti kita bisa langsung tulis baris kode untuk menambahkan data di dalam method `run()`.

## Generate Filter{#generate-filter}
Filter atau kalau dalam istilah di framework lain itu biasanya disebut middleware merupakan sebuah class yang memiliki dua method, yaitu `before()` dan `after()` yang memiliki kode yang akan di-run sebelum dan sesudah controller yang didefinisikan. Untuk generate filter, kita bisa run command dengan format.
```
php spark make:filter <nama-filter-class> [options]
```

Contoh filter yang biasa kita temukan dalam web ataupun aplikasi yang kita kembangkan adalah `LoginFilter` atau class yang berisi pengecekan apakah user itu sudah login atau belum. Untuk generate class `LoginFilter` kita bisa run command ini.
```
php spark make:filter LoginFilter
```

Output yang ditampilkan setelah command di-run.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 11:01:01 UTC+00:00

File created: APPPATH/Filters/LoginFilter.php
```

File hasil generate terdapat di dalam direktori `Filters` dengan nama `LoginFilter.php`. Selanjutnya kita coba buka file `LoginFilter.php` di text editor.

```php
<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

class LoginFilter implements FilterInterface
{
    /**
     * Do whatever processing this filter needs to do.
     * By default it should not return anything during
     * normal execution. However, when an abnormal state
     * is found, it should return an instance of
     * CodeIgniter\HTTP\Response. If it does, script
     * execution will end and that Response will be
     * sent back to the client, allowing for error pages,
     * redirects, etc.
     *
     * @param RequestInterface $request
     * @param array|null       $arguments
     *
     * @return RequestInterface|ResponseInterface|string|void
     */
    public function before(RequestInterface $request, $arguments = null)
    {
        //
    }

    /**
     * Allows After filters to inspect and modify the response
     * object as needed. This method does not allow any way
     * to stop execution of other after filters, short of
     * throwing an Exception or Error.
     *
     * @param RequestInterface  $request
     * @param ResponseInterface $response
     * @param array|null        $arguments
     *
     * @return ResponseInterface|void
     */
    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        //
    }
}

```
Seperti yang disebutkan sebelumnya, hasil generatenya berupa class `Filter` yang mengimplementasikan `FilterInterface` class dan secara default memiliki dua method, yaitu `before()` dan `after()`. Nantinya kita bisa isi salah satu atau kedua method tersebut dan kita juga bisa mengosongkan salah satu method apabila tidak diperlukan.

## Command Generate Scaffolding{#generate-scaffolding}
Kadang pada saat development, kita membuat sebuah modul sesuai dengan grup. Misalkan saat membuat grup admin. Grup ini memiliki controller, model, migration file, dan entity masing-masing. Lebih mudah kalau kita tidak perlu run command satu persatu di terminal dan cukup satu command untuk generate semuanya. Kabar baiknya di CodeIgniter 4 tersedia command untuk generate beberapa class sekaligus, seperti controller, model, entity, migration dan seeder dengan satu command, yaitu `make:scaffold` command.

Sebagai contoh di sini kita coba generate class yang berhubungan dengan objek `Post`, kita run command berikut ini.
```
php spark make:scaffold Post
```
Output yang ditampilkan di terminal setelah command kita run kurang lebih seperti di bawah ini.

```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 11:03:35 UTC+00:00

File created: APPPATH/Controllers/Post.php

File created: APPPATH/Models/Post.php

File created: APPPATH/Database/Migrations/2025-02-24-110335_Post.php

File created: APPPATH/Database/Seeds/Post.php

```
Karena umumnya kita tidak terlalu sering pakai entity class, jadi hanya empat class yang di-generate. Nah untuk generate entity class. Kita bisa tambahkan opsi `--return entity`.

```
php spark make:scaffold Post --return entity
```
Output yang ditampilkan di terminal.
```
CodeIgniter v4.6.0 Command Line Tool - Server Time: 2025-02-24 11:04:05 UTC+00:00

File created: APPPATH/Controllers/Post.php

File created: APPPATH/Entities/Post.php

File created: APPPATH/Models/Post.php

File created: APPPATH/Database/Migrations/2025-02-24-110405_Post.php

File created: APPPATH/Database/Seeds/Post.php

```
Bisa kita lihat dan kita cek langsung ada file entity juga yang di-generate setelah command kita run.

## Penutup{#penutup}
Pada tulisan kali ini kita sudah membahas tentang CLI generator command yang dimiliki CodeIgniter 4. Ada banyak command yang bisa kita gunakan untuk generate class, dan kita sudah coba untuk generate controller, model, entity, migration, seeder dan filter. Selain itu kita juga sudah mencoba menggunakan generate scaffolding satu set code seperti controller, model, entity, seeder, dan migration file hanya dengan run satu command saja.