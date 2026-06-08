---
title: "Memulai belajar Laravel 10 dan Tailwind css untuk membangun crud app sederhana"
slug: "memulai-belajar-laravel-10-dan-tailwindcss-untuk-membangun-crud-app"
category: "Laravel"
date: "2023-02-20"
status: "published"
---

Dalam perjalanan pengembangan web yang telah berlangsung selama bertahun-tahun, setiap developer pasti menghadapi momen krusial untuk memilih teknologi yang tepat. Sebagai seorang developer yang telah mengeksplorasi berbagai framework, perjalanan saya dengan Laravel dimulai pada September 2021 dengan Laravel 8.

Dunia teknologi bergerak dengan sangat dinamis. Dalam kurun waktu singkat, Laravel telah merilis dua versi major - Laravel 9 di Februari 2022 dan yang terbaru Laravel 10 di tahun 2023. Situasi ini menimbulkan dilema yang sering dihadapi developer pemula: haruskah kita tetap mendalami versi yang sudah familiar, atau beralih ke versi terbaru?

Beberapa pertanyaan kritis yang muncul:
- Bagaimana perbedaan fundamental antara Laravel 8 dan Laravel 10?
- Apakah ada perubahan signifikan dalam sintaks dan struktur kode?
- Seberapa besar learning curve yang harus dihadapi?

Untuk menjawab keraguan tersebut, saya memutuskan untuk melakukan eksperimen langsung dengan Laravel 10. Project yang dipilih adalah pengembangan aplikasi CRUD (Create, Read, Update, Delete) - fondasi dari setiap aplikasi web modern. Untuk memberikan nilai tambah, project ini juga mengintegrasikan Tailwind CSS sebagai framework UI, berbeda dengan [tutorial crud Laravel 8 sebelumnya](https://qadrlabs.com/post/belajar-laravel-8-membuat-aplikasi-crud-sederhana).

## Persiapan Environment Development{#persiapan}
Sebelum memulai perjalanan dengan Laravel 10, pastikan environment development kita memenuhi persyaratan teknis. Laravel 10 membutuhkan PHP versi 8.1 atau yang lebih tinggi. Mari kita verifikasi versi PHP yang terinstal:

```bash
php -v
```

Pada environment development kita, terinstal PHP 8.1.6:
```bash
PHP 8.1.6 (cli) (built: May 12 2022 23:30:39) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.1.6, Copyright (c) Zend Technologies
    with Xdebug v3.1.4, Copyright (c) 2002-2022, by Derick Rethans
    with Zend OPcache v8.1.6, Copyright (c), by Zend Technologies
```

### Checklist Requirement Laravel 10:
✓ PHP >= 8.1
✓ Extension Packages:
- Ctype PHP Extension
- cURL PHP Extension
- DOM PHP Extension
- Fileinfo PHP Extension
- Filter PHP Extension
- Hash PHP Extension
- Mbstring PHP Extension
- OpenSSL PHP Extension
- PCRE PHP Extension
- PDO PHP Extension
- Session PHP Extension
- Tokenizer PHP Extension
- XML PHP Extension

Dengan environment yang sudah siap, kita dapat memulai petualangan membangun aplikasi CRUD modern menggunakan Laravel 10 dan Tailwind CSS. Tertarik untuk ikut dalam perjalanan ini? Mari kita mulai langkah pertama bersama!

## Overview{#overview}
Pada tutorial laravel kali ini kita akan membuat project sederhana seperti pada tutorial crud Laravel versi sebelumnya yaitu project blog. Kita akan coba beberapa hal yaitu:
* Menggunakan Tailwind Css sebagai Framework UI.
* Menggunakan opsi untuk generate method dan route model binding pada saat membuat controller menggunakan `php artisan`
* Menggunakan Route Model Binding (disebut dua kali supaya lebih jelas)

## Step 1 - Setup Project{#step-1}
Langkah pertama adalah install Laravel 10 untuk project crud kita. Buka terminal lalu run `composer` untuk menginstall Laravel 10.
```bash
composer create-project laravel/laravel:^10.0 blog
```
Karena pada saat ini laravel 10 bukan versi terbaru, jadi kita tambahkan constrain versi `:^10.0` pada command create-project untuk menggunakan versi laravel 10.x terbaru yang kompatibel.

Setelah Laravel 10 sudah terinstall, selanjutnya kita masuk ke direktori project.
```bash
cd blog
```

Setelah itu kita bisa coba run project kita menggunakan `artisan` command.
```bash
php artisan serve
```

Kemudian buka url `http://127.0.0.1:8000/` di browser. Setelah project kita buka di browser, kita bisa lihat halaman default framework laravel dan kita juga bisa lihat keterangan versi laravel dan versi PHP yang kita pakai di posisi kanan bawah, misalnya `Laravel v10.0.3 (PHP v8.1.6)`.

## Step 2 - Set Konfigurasi Database{#step-2}
Setelah Laravel 10 berhasil kita install dan coba kita run di langkah sebelumnya, sekarang kita akan atur konfigurasi database. Buka file `.env`, lalu sesuaikan dengan credentials mysql dan nama database.

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_blog
DB_USERNAME=admin
DB_PASSWORD=password
```

Sebagai contoh, nama database untuk project kita adalah `db_blog`, sedangkan untuk credentials mysql, usernamenya `admin` dan passwordnya `password`.

Setelah selesai save kembali file `.env`.

Selanjutnya kita buat database baru dengan nama `db_blog` (atau nama database apapun yang kamu setting di file `.env`). Kita bisa buat database baru melalui `phpmyadmin` atau command sql. Buka terminal lalu kita login ke mysql. 
```bash
mysql -u admin -p
```
Setelah kita masukan passwordnya, akan tampil output seperti di bawah ini.
```bash
$ mysql -u admin -p

Enter password: 

Welcome to the MySQL monitor.  Commands end with ; or \g.

Your MySQL connection id is 85

Server version: 5.7.37 Homebrew

  

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

  

Oracle is a registered trademark of Oracle Corporation and/or its

affiliates. Other names may be trademarks of their respective

owners.

  

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
```

Selanjutnya kita buat database baru menggunakan command.
```bash
CREATE DATABASE db_blog;
```

Output:
```
mysql> CREATE DATABASE db_blog;

Query OK, 1 row affected (0.00 sec)
```

Setelah database kita buat, selanjutnya keluar dari cli mysql.
```bash
exit;
```

## Step 3 - File Model dan Migration{#step-3}
Pada tahapan ini kita akan membuat file model sekaligus file migration menggunakan `artisan` command. Karena project kita tentang blog, kita akan buat model untuk post dengan nama `Post`. Buka kembali terminal, lalu kita run command untuk membuat model dan migration.
```bash
php artisan make:model Post -m
```

Output:
```bash
  
INFO  Model **[app/Models/Post.php]** created successfully.  

  
INFO  Migration **[database/migrations/2023_02_20_130437_create_posts_table.php]** created successfully.
```

Pada output yang ditampilkan, kita bisa lihat file model dan file migration berhasil dibuat. Dengan menggunakan opsi `-m` pada `artisan` command `make:model`, kita bisa langsung buat file migration sesuai dengan model-nya.

Selanjutnya kita buka file model yang baru saja dibuat. yaitu `app/Models/Post.php`, lalu kita definisikan properties `$fillable` untuk mengatur `mass assignment` atau data apa saja yang diperbolehkan ketika ada proses insert atau update.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;
    
    protected $fillable = [
        'title', 'content', 'slug', 'status'
    ];
}
```

Pada baris kode di atas, hanya `title`, `content`, `slug`, dan `status` yang bisa ditambahkan ke table `posts` pada saat proses insert ataupun update.

Selanjutnya kita buat table `posts` menggunakan file migration yang sebelumnya berhasil kita generate menggunakan `artisan command`. Buka file `database/migrations/yyyy_mm_dd_xxxxxx_create_posts_table.php`, lalu kita tambahkan kolom untuk table `posts` sesuai dengan yang dengan yang sudah kita atur pada model `Post`.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content');
            $table->string('slug');
            $table->smallInteger('status');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('posts');
    }
};
```

Setelah itu kita run migration.
```bash
php artisan migrate
```

Output:
```
INFO  Preparing database.  



Creating migration table ......................................... 25ms **DONE**



INFO  Running migrations.  



2014_10_12_000000_create_users_table ............................. 23ms **DONE**

2014_10_12_100000_create_password_reset_tokens_table ............. 21ms **DONE**

2019_08_19_000000_create_failed_jobs_table ....................... 15ms **DONE**

2019_12_14_000001_create_personal_access_tokens_table ............ 24ms **DONE**

2023_02_20_130437_create_posts_table .............................. 9ms **DONE**
```
Ya, table `posts` (dan table lainnya) berhasil dibuat setelah kita run migration.

## Step 4 - Coding Fitur Menampilkan Data{#step-4}
Fitur pertama yang akan tambahkan adalah fitur untuk menampilkan data `post` pada project kita. Pertama kita buat terlebih dahulu file controller menggunakan artisan command.
```bash
php artisan make:controller PostController --model=Post --resource
```
Output:

```
INFO  Controller **[app/Http/Controllers/PostController.php]** created successfully.
```

Seperti yang sudah disebutkan pada Overview Project, kita coba gunakan opsi `--model` dan `resource` untuk generate `PostController`.
* Opsi `--model=Post` kita tambahkan karena kita akan coba menggunakan `route model binding`. Jadi nanti controller hasil generate akan memiliki method dengan type hint instance sebuah model.
* Opsi `--resource` kita tambahkan untuk generate controller yang menangani crud. Jadi ketika controller di-generate, controller akan memiliki method yang menangani crud.

Supaya lebih jelas, sekarang kita buka file `app/Http/Controllers/PostController.php` dan kita bisa lihat ada beberapa method yang sudah di-generate, seperti method `index()`, `create()`,`store()`,`show()`,`edit()`, `update()`, dan `destroy()`.

Baik kita lanjutkan. 

Sekarang kita tambahkan baris kode pada method `index()` untuk menampilkan halaman daftar post.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{

	public function index() 
	{  
	    $posts = Post::orderBy('id', 'DESC')->paginate(10);  
	    return view('posts.index', compact('posts'));  
	}
}
```

Method `index()` ini menangani untuk menampilkan halaman daftar post. Pada baris kode di atas, terdapat `$posts` yang berisi data post yang akan dipassing dan ditampilkan di view `posts.index`. 

Langkah berikutnya adalah membuat file view yang akan kita pakai untuk menampilkan data dari variable `$posts`, yaitu `posts/index.blade.php`. Kita buat dulu folder baru dengan nama `posts`, lalu di dalam folder `posts` kita buat file `index.blade.php`. Di dalam file `index.blade.php` kita tambahkan baris kode berikut ini.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Post List - Tutorial CRUD Laravel 10 @ qadrlabs.com</title>

</head>

<body>

<div class="container mx-auto mt-10 mb-10 px-10">
    <div class="grid grid-cols-8 gap-4 mb-4 p-5">
        <div class="col-span-4 mt-2">
            <h1 class="text-3xl font-bold">
                DAFTAR POST
            </h1>
        </div>
        <div class="col-span-4">
            <div class="flex justify-end">
                <a href="{{ route('post.create') }}"
                   class="inline-block px-6 py-2.5 bg-blue-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-blue-700 hover:shadow-lg focus:bg-blue-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-blue-800 active:shadow-lg transition duration-150 ease-in-out"
                   id="add-post-btn">+ Create New Post</a>
            </div>
        </div>
    </div>
    <div class="bg-white p-5 rounded shadow-sm">
        <!-- Notifikasi menggunakan flash session data -->
        @if (session('success'))
            <div class="p-3 rounded bg-green-500 text-green-100 mb-4">
                {{ session('success') }}
            </div>
        @endif

        <table class="min-w-full table-auto border">
            <thead class="border-b">
            <tr>
                <th scope="col" class="text-sm font-medium text-gray-900 px-6 py-4 text-left">Title</th>
                <th scope="col" class="text-sm font-medium text-gray-900 px-6 py-4 text-center">Status</th>
                <th scope="col" class="text-sm font-medium text-gray-900 px-6 py-4 text-center">Create At</th>
                <th scope="col" class="text-sm font-medium text-gray-900 px-6 py-4 text-center">Action</th>
            </tr>
            </thead>
            <tbody>
            @forelse ($posts as $post)
                <tr class="border-b">
                    <td class="text-sm text-gray-900 font-light px-6 py-4 whitespace-nowrap">{{ $post->title }}</td>
                    <td class="text-sm text-gray-900 font-light px-6 py-4 whitespace-nowrap text-center">{{ $post->status == 0 ? 'Draft':'Publish' }}</td>
                    <td class="text-sm text-gray-900 font-light px-6 py-4 whitespace-nowrap text-center">{{ $post->created_at->format('d-m-Y') }}</td>
                    <td class="text-sm text-gray-900 font-light px-6 py-4 whitespace-nowrap text-center">

                        <form onsubmit="return confirm('Apakah Anda Yakin ?');"
                              action="{{ route('post.destroy', $post->id) }}" method="POST">

                            @csrf
                            @method('DELETE')
                            <a href="{{ route('post.edit', $post->id) }}" id="{{ $post->id }}-edit-btn"
                               class="inline-block px-6 py-2.5 bg-blue-400 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-blue-500 hover:shadow-lg focus:bg-blue-500 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-blue-600 active:shadow-lg transition duration-150 ease-in-out">Edit</a>

                            <button type="submit"
                                    class="inline-block px-6 py-2.5 bg-red-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-red-700 hover:shadow-lg focus:bg-red-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-red-800 active:shadow-lg transition duration-150 ease-in-out"
                                    id="{{ $post->id }}-delete-btn">Delete
                            </button>
                        </form>

                    </td>
                </tr>
            @empty
                <tr>
                    <td class="text-center text-sm text-gray-900 px-6 py-4 whitespace-nowrap" colspan="4">Data post tidak tersedia</td>
                </tr>
            @endforelse
            </tbody>
        </table>

        <div class="mt-3">
            {{ $posts->links() }}
        </div>
    </div>

</div>

<script src="https://cdn.tailwindcss.com/?plugins=forms"></script>

</body>

</html>

```

Pada baris kode di atas, terdapat variable `$posts` yang sebelumnya kita passing dari controller pada method `index()` menggunakan function `view()`. Selanjutnya kita looping `$posts` menggunakan blade directive, yaitu `@forelse`. Selain `@forelse`, kita bisa lihat ada blade directive `@if` untuk pengecekan notifikasi.

Untuk tampilan atau user interface, kita coba memakai tailwindcss. Bisa kita lihat terdapat script untuk load tailwindcss sebelum tag `</body>`.

```
<script src="https://cdn.tailwindcss.com/?plugins=forms"></script>
```

Karena belum menambahkan route, kita belum bisa run project untuk melihat halaman daftar post. Jadi sekarang kita tambahkan atau register route baru di file `routes/web.php`.
```php
<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::resource('post', \App\Http\Controllers\PostController::class); // tambahkan ini
```

Route pada baris kode di atas, sudah menangani route untuk menampilkan data, menambahkan data, memperbaharui data dan menghapus data. Untuk mengecek route yang sudah kita register, kita bisa gunakan command.
```bash
php artisan route:list
```

Output:
```bash
  GET|HEAD        / .......................................................... 

  POST            _ignition/execute-solution ignition.executeSolution › Spati…

  GET|HEAD        _ignition/health-check ignition.healthCheck › Spatie\Larave…

  POST            _ignition/update-config ignition.updateConfig › Spatie\Lara…

  GET|HEAD        api/user ................................................... 

  GET|HEAD        post ..................... post.index › PostController@index

  POST            post ..................... post.store › PostController@store

  GET|HEAD        post/create ............ post.create › PostController@create

  GET|HEAD        post/{post} ................ post.show › PostController@show

  PUT|PATCH       post/{post} ............ post.update › PostController@update

  DELETE          post/{post} .......... post.destroy › PostController@destroy

  GET|HEAD        post/{post}/edit ........... post.edit › PostController@edit

  GET|HEAD        sanctum/csrf-cookie sanctum.csrf-cookie › Laravel\Sanctum  …
```

Setelah route kita register, kita bisa akses halaman daftar post dengan membuka url `http://127.0.0.1:8000/post` di browser.

## Step 5 - Coding Fitur Menambahkan Data{#step-5}
Tahapan selanjutnya adalah menambahkan fitur untuk tambah data di project kita. Buka kembali file controller `PostController.php`, lalu kita tambahkan baris kode pada method `create()` untuk menampilkan form menambah data baru.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

	public function create()  
	{  
	    return view('posts.create');  
	}
}

```

Ya, method ini menangani untuk proses menampilkan halaman untuk menambahkan data, dengan me-return function `view()`. Selanjutnya kita buat file view baru, sesuai yang ada pada method view, yaitu file `create.blade.php` di dalam folder `posts`.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Create New Post - Tutorial CRUD Laravel 10 @ qadrlabs.com</title>
</head>

<body>

<div class="container mx-auto mt-10 mb-10 px-10">
    <div class="grid grid-cols-8 gap-4 p-5">
        <div class="col-span-4 mt-2">
            <h1 class="text-3xl font-bold">
                CREATE NEW POST
            </h1>
        </div>
        <div class="col-span-4">

        </div>
    </div>
    <div class="bg-white p-5 rounded shadow-sm">
        <form action="{{ route('post.store') }}" method="POST">
            @csrf

            <div class="mb-5">
                <label for="title">Title</label>
                <input type="text" class="
                    form-control
                    block
                    w-full
                    px-3
                    py-1.5
                    text-base
                    font-normal
                    text-gray-700
                    bg-white bg-clip-padding
                    border border-solid border-gray-300
                    rounded-full
                    transition
                    ease-in-out
                    m-0
                    focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none
                  " name="title" value="{{ old('title') }}" required>

                <!-- error message untuk title -->
                @error('title')
                <div class="bg-red-400 p-2 shadow-sm rounded mt-2">
                    {{ $message }}
                </div>
                @enderror
            </div>

            <div class="mb-5">
                <label for="status">Publish Status</label>
                <select name="status" class="form-select appearance-none
                      block
                      w-full
                      px-3
                      py-1.5
                      text-base
                      font-normal
                      text-gray-700
                      bg-white bg-clip-padding bg-no-repeat
                      border border-solid border-gray-300
                      rounded-full
                      transition
                      ease-in-out
                      m-0 focus:text-gray-700 focus:bg-white
                      focus:border-blue-600 focus:outline-none" required>
                    <option value="1" selected>Publish</option>
                    <option value="0">Draft</option>
                </select>
            </div>

            <div class="mb-5">
                <label for="content">Content</label>
                <textarea
                    name="content" id="content"
                    class="
                        form-control
                        block
                        w-full
                        px-3
                        py-1.5
                        text-base
                        font-normal
                        text-gray-700
                        bg-white bg-clip-padding
                        border border-solid border-gray-300
                        rounded
                        transition
                        ease-in-out
                        m-0
                        focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none
                      "
                    cols="30" rows="10"
                    required>{{ old('content') }}</textarea>

                <!-- error message untuk content -->
                @error('content')
                <div class="invalid-feedback">
                    {{ $message }}
                </div>
                @enderror
            </div>

            <div class="mt-3">
                <button type="submit"
                        class="inline-block px-6 py-2.5 bg-blue-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-blue-700 hover:shadow-lg focus:bg-blue-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-blue-800 active:shadow-lg transition duration-150 ease-in-out">
                    Save
                </button>
                <a href="{{ route('post.index') }}"
                   class="inline-block px-6 py-2.5 bg-gray-200 text-gray-700 font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-gray-300 hover:shadow-lg focus:bg-gray-300 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-gray-400 active:shadow-lg transition duration-150 ease-in-out">back</a>
            </div>

        </form>

    </div>

</div>

<script src="https://cdn.tailwindcss.com/?plugins=forms"></script>
<script src="https://cdn.ckeditor.com/4.18.0/standard/ckeditor.js"></script>
<script>
    CKEDITOR.replace('content');
</script>
</body>

</html>

```

Kalau di tutorial sebelumnya (CRUD Laravel 8), kita gunakan summernote untuk menulis konten, di tutorial ini kita coba gunakan CKEditor supaya kita tidak perlu menggunakan Jquery.

Pada baris kode di atas, action pada form mengarah ke route `post.store`.
```html
<form action="{{ route('post.store') }}" method="POST">
```

Route `post.store` ini mengarah ke method `store()` di dalam `PostController`. Sekarang kita buka kembali `PostController`, lalu kita tambahkan baris kode pada  method `store()` untuk menangani proses insert data.

```php
<?php

// ... baris kode sebelumnya
use Illuminate\Support\Str;

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

	public function store(Request $request)  
	{  
	    $this->validate($request, [  
	        'title' => 'required|string|max:151',  
	        'content' => 'required',  
	        'status' => 'required|integer'  
	    ]);  
	  
	    $post = Post::create([  
	        'title' => $request->get('title'),  
	        'content' => $request->get('content'),  
	        'status' => $request->get('status'),  
	        'slug' => Str::slug($request->get('title'))  
	    ]);  
	  
	    return redirect()->route('post.index')  
	        ->with('success', 'Post created successfully.');  
	}
}

```

Algoritma untuk method `store()` ini terbagi menjadi tiga bagian, yaitu validasi, proses insert data dan proses redirect ke halaman daftar post. Pada proses validasi, kita gunakan function `validate()` dan kita definisikan aturan validasi untuk field yang akan kita insert ke dalam table `posts`, yaitu `title`, `content` dan `status`. Apabila isian form tidak sesuai dengan aturan validasi yang sudah didefinisikan, project akan menampilkan kembali halaman create post dan menampilkan pesan error. 

Dan apabila isian form sudah sesuai, proses akan dilanjutkan ke proses insert data. Pada proses insert data, di sini kita gunakan method eloquent `create()`. Data yang dapat kita insert ke dalam table sesuai dengan yang sudah kita definisikan di property `$fillable` pada model `Post`. Untuk `slug`, kita gunakan helper dari Laravel 10 untuk generate slug berdasarkan title. Sebelum deklarasi class `PostController`, kita import class `Illuminate\Support\Str`.

```php
use Illuminate\Support\Str;
```
Selanjutnya, kita gunakan `Str` class untuk generate slug berdasarkan title.
```php
Str::slug($request->get('title'))
```

Setelah proses insert, web akan ter-redirect route `post.index` atau halaman daftar post dan menampilkan flashdata `success`.

## Step 6 - Coding Fitur Memperbaharui Data{#step-6}
Tahapan selanjutnya adalah coding fitur untuk memperbaharui data. Pada file `index.blade.php`, proses untuk memperbaharui data mengarah ke route `post.edit` dan route ini mengarah ke method `edit()` pada controller `PostController`. Sekarang kita coba tambahkan baris kode pada method `edit()`. Buka kembali file controller `PostController`, lalu kita tambahkan baris kode pada method `edit()` untuk menangani proses menampilkan halaman edit data post.
```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    // ... baris kode sebelumnya

    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }
}

```

Bisa kita lihat parameter untuk method `edit()` agak berbeda dari biasanya. Kalau di tutorial sebelumnya, kita gunakan `$id`, di sini kita coba gunakan model `Post` sebagai parameternya atau biasa disebut `Route Model Binding`. Dengan menggunakan route model binding, secara otomatis model instance akan diinject langsung ke dalam route sesuai dengan id pada request URI. Selanjutnya model instance ini ditampung di dalam `$post`, lalu kemudian dipassing ke view menggunakan `compact('post')`. Pada halaman view, isi dari `$post` akan ditampilkan pada masing-masing form input.

Selanjutnya kita buat file view sesuai dengan yang sudah kita definisikan pada function `view()` yang ada pada method `edit()`, yaitu file `edit.blade.php`. Kita buat file `edit.blade.php` di dalam direktori `posts`, lalu kita tambahkan baris kode berikut ini.
```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Edit Post - Tutorial CRUD Laravel 10 @ qadrlabs.com</title>
</head>

<body>

<div class="container mx-auto mt-10 mb-10 px-10">
    <div class="grid grid-cols-8 gap-4 p-5">
        <div class="col-span-4 mt-2">
            <h1 class="text-3xl font-bold">
                EDIT POST
            </h1>
        </div>
        <div class="col-span-4">

        </div>
    </div>
    <div class="bg-white p-5 rounded shadow-sm">
        <form action="{{ route('post.update', $post->id) }}" method="POST">
            @csrf
            @method('PUT')

            <div class="mb-5">
                <label for="title">Title</label>
                <input type="text" class="
                    form-control
                    block
                    w-full
                    px-3
                    py-1.5
                    text-base
                    font-normal
                    text-gray-700
                    bg-white bg-clip-padding
                    border border-solid border-gray-300
                    rounded-full
                    transition
                    ease-in-out
                    m-0
                    focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none
                  " name="title" value="{{ old('title', $post->title) }}" required>

                <!-- error message untuk title -->
                @error('title')
                <div class="bg-red-400 p-2 shadow-sm rounded mt-2">
                    {{ $message }}
                </div>
                @enderror
            </div>

            <div class="mb-5">
                <label for="status">Publish Status</label>
                <select name="status" class="form-select appearance-none
                      block
                      w-full
                      px-3
                      py-1.5
                      text-base
                      font-normal
                      text-gray-700
                      bg-white bg-clip-padding bg-no-repeat
                      border border-solid border-gray-300
                      rounded-full
                      transition
                      ease-in-out
                      m-0 focus:text-gray-700 focus:bg-white
                      focus:border-blue-600 focus:outline-none" required>
                    <option value="1" {{ old('status', $post->status) == 1 ? 'selected':'' }} >Publish</option>
                    <option value="0" {{ old('status', $post->status) == 0 ? 'selected':'' }} >Draft</option>
                </select>
            </div>

            <div class="mb-5">
                <label for="content">Content</label>
                <textarea
                    name="content" id="content"
                    class="
                        form-control
                        block
                        w-full
                        px-3
                        py-1.5
                        text-base
                        font-normal
                        text-gray-700
                        bg-white bg-clip-padding
                        border border-solid border-gray-300
                        rounded
                        transition
                        ease-in-out
                        m-0
                        focus:text-gray-700 focus:bg-white focus:border-blue-600 focus:outline-none
                      "
                    cols="30" rows="10"
                    required>{{ old('content', $post->content) }}</textarea>

                <!-- error message untuk content -->
                @error('content')
                <div class="invalid-feedback">
                    {{ $message }}
                </div>
                @enderror
            </div>

            <div class="mt-3">
                <button type="submit"
                        class="inline-block px-6 py-2.5 bg-blue-600 text-white font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-blue-700 hover:shadow-lg focus:bg-blue-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-blue-800 active:shadow-lg transition duration-150 ease-in-out">
                    Update
                </button>
                <a href="{{ route('post.index') }}"
                   class="inline-block px-6 py-2.5 bg-gray-200 text-gray-700 font-medium text-xs leading-tight uppercase rounded-full shadow-md hover:bg-gray-300 hover:shadow-lg focus:bg-gray-300 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-gray-400 active:shadow-lg transition duration-150 ease-in-out">back</a>
            </div>

        </form>

    </div>

</div>

<script src="https://cdn.tailwindcss.com/?plugins=forms"></script>
<script src="https://cdn.ckeditor.com/4.18.0/standard/ckeditor.js"></script>
<script>
    CKEDITOR.replace('content');
</script>
</body>

</html>

```

Pada baris kode di atas, `$post` kita tampilkan di value pada form input masing-masing. Misalnya untuk title, kita tampilkan pada value form input dengan name.
```html
<input type="text" name="title" value="{{ old('title', $post->title) }}">
```

Untuk action form, form edit ini mengarah ke route `post.update` dengan id sebagai parameternya dan route ini mengarah ke method `update()` pada `PostController`.

```html
<form action="{{ route('post.update', $post->id) }}" method="POST">
    @csrf
    @method('PUT')
```
Selain itu, karena ini proses untuk update data jadi kita tambahkan blade directive `@method('PUT')`.

Selanjutnya kita akan menambahkan kode pada method `update()` yang akan menangani proses update data. Buka kembali file controller `PostController`, lalu kita tambahkan baris kode pada method `update()`.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    // ... baris kode sebelumnya

    public function update(Request $request, Post $post)  
	{  
	    $this->validate($request, [  
	        'title' => 'required|string|max:151',  
	        'content' => 'required',  
	        'status' => 'required|integer'  
	    ]);  
	  
	    $post->update([  
	        'title' => $request->get('title'),  
	        'content' => $request->get('content'),  
	        'status' => $request->get('status'),  
	        'slug' => Str::slug($request->get('title'))  
	    ]);  
	  
	    return redirect()->route('post.index')  
	        ->with('success', 'Post updated successfully.');  
	}
}
```

Sama seperti method `edit()`, method `update()` juga menggunakan model `Post` sebagai parameter. Jadi secara otomatis, `$post` ini merupakan instance dari model `Post` berdasarkan id pada request URI yang didefinisikan pada action form.
```html
<form action="{{ route('post.update', $post->id) }}" method="POST">
    @csrf
    @method('PUT')
```

Algoritma method `update()` ini terbagi menjadi tiga bagian, yaitu validasi, proses update data, dan proses redirect ke route `post.index` atau halaman daftar post.

## Step 7 - Coding Fitur Hapus Data{#step-7}
Fitur terakhir untuk project kita adalah fitur hapus data post. Buka kembali file controller `PostController`, lalu kita tambahkan method `destroy()`.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

	public function destroy(Post $post)  
	{  
	    $post->delete();  
	    return redirect()  
	        ->route('post.index')  
	        ->with('success', 'Post deleted successfully.');  
	}
}
```

Ya, sama seperti method `edit()` dan `update()`, kita gunakan model `Post` sebagai parameter untuk method `destroy()`. Method `destroy()` ini menangani proses untuk menghapus data berdasarkan id yang terdapat pada request URI yang sebelumnya sudah kita definisikan pada route `post.destroy` di form delete pada file `index.blade.php`. 

Teman-teman bisa buka kembali file `index.blade.php`, lalu temukan baris kode berikut ini.

```html
<form onsubmit="return confirm('Apakah Anda Yakin ?');"
      action="{{ route('post.destroy', $post->id) }}" method="POST">
    @csrf
    @method('DELETE')
```

Pada baris kode di atas, `$post->id` pada parameter route akan digunakan sebagai id untuk model instance `$post` pada method `destroy()`. Selain route `post.destroy` yang mengarah ke method `destroy()`, kita perlu menambahkan blade directive `@method('DELETE')` sebagai tanda action form ini menggunakan HTTP DELETE method.

## Step 8 - Run Project{#step-8}
Kita sudah selesai coding fitur CRUD untuk project kita, dimulai dari fitur menampilkan data, menambahkan data, memperbaharui data dan menghapus data. Sekarang kita bisa coba run project kita. Buka kembali terminal, lalu run command berikut ini.
```bash
php artisan serve
```

Setelah itu buka url `http://127.0.0.1:8000/post` di browser. Setelah kita bisa coba tambahkan data, perbaharui data dan hapus data.

## Penutup{#penutup}
Dalam tutorial ini, kita telah mempelajari tentang Laravel 10 dan Tailwindcss untuk membuat aplikasi web dengan fitur CRUD. Setelah mengikuti tutorial ini, kita akan memahami perbedaan antara Laravel 8 dan Laravel 10, khususnya dalam hal fitur dan sintaksis. Kita telah sama-sama belajar cara membuat aplikasi web dari awal hingga akhir, termasuk instalasi, konfigurasi database, dan pembuatan fitur CRUD. Kita juga telah membahas cara menggunakan Tailwindcss untuk merancang tampilan user interface dan meningkatkan kinerja aplikasi web.

Setelah berhasil membuat aplikasi CRUD menggunakan Laravel 10 dan Tailwind CSS, Kita bisa menyimpulkan sejauh ini tidak ada perbedaan untuk codingan di Laravel 10, kecuali beberapa bagian yang menjadi perbedaan laravel 10 dengan laravel sebelumnya seperti.
1. Laravel 10 menggunakan PHP versi 8.1 sebagai syarat minimumnya dan sudah tidak menggunakan php versi 8.0. Bisa kita cek di file `composer.json` Kedepannya kita bisa lihat penggunaan fitur PHP 8.1 ketika menggunakan laravel 10 ini.
2. Terdapat **return type** di setiap method atau function ketika kita generate menggunakan `artisan` command. Contohnya bisa kita lihat di file controller `PostController.php`.

Dari hasi belajar kali ini baru dua fitur laravel 10 yang saya temukan, selain percobaan menggunakan tailwind CSS dan penggunaan route model binding. 

Kembali ke pertanyaan awal, apakah fokus belajar laravel 8 atau mulai mencoba laravel 10? Menurut saya, terlepas dari versi yang kita gunakan, kita lebih baik fokus ke basic dan memahami konsep dari framework laravel. Sehingga ketika ada rilis versi berapa pun, selama kita paham, kita bisa dengan mudah mempelajarinya.