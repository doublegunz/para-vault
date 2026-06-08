---
title: "Belajar Laravel 8: Membuat Aplikasi CRUD Sederhana"
slug: "belajar-laravel-8-membuat-aplikasi-crud-sederhana"
category: "Laravel"
date: "2021-09-18"
status: "published"
---

Mana yang lebih baik framework Laravel atau framework yang lain? Ya, ini adalah salah satu dari sekian pertanyaan yang sering kita temukan dan boleh jadi kita sendiri yang membuat pertanyaan. Dan untuk menemukan jawaban pertanyaan ini, saya memutuskan untuk mencoba belajar Laravel 8 sampai membuat aplikasi CRUD sederhana. Tentu saja untuk mempelajari dengan sungguh-sungguh, ada roadmap belajar yang bisa kita ikuti untuk mempelajari framework Laravel 8. Tulisan ini saya buat untuk mendokumentasikan hasil belajar laravel 8 ketika sudah memasuki materi crud.

## CRUD App Overview {#overview}
Sebagai komparasi dengan framework yang saya tulis di postingan sebelumnya, aplikasi crud sederhana yang akan kita buat di dalam tutorial ini adalah sebuah blog sederhana. Dalam pembuatan aplikasi ini, kita akan mempelajari beberapa hal yang berhubungan dengan operasi yang berinteraksi dengan database, seperti create data, read data, update data, dan delete data. Untuk menangani operasi yang berinteraksi dengan database, kita akan menggunakan `Eloquent`, sebuah object-relational-mapper (ORM) dari framework laravel.

## Step 1 - Install laravel 8 {#step-1}
Karena di tutorial sebelumnya kita sudah sering menggunakan `composer`, jadi sekarang kita coba install laravel 8 melalui `composer` juga. Kita buka terminal / cmd, lalu kita jalankan command di bawah ini untuk membuat project laravel 8 yang baru.

```bash
composer create-project laravel/laravel:^8.0 blog
```


**Catatan**: Pada proses instalasi di atas, kita menambahkan versi laravel yang akan kita install , yaitu `laravel/laravel:^8.0` yang merujuk ke laravel versi 8. Kalau kita run pakai command `composer create-project --prefer-dist laravel/laravel blog`, maka yang akan terinstall laravel versi terbaru. FYI, tutorial ini masih compatible dengan laravel versi 8 juga.

Bisa teman-teman perhatikan pada output terminal, setelah kita run command di atas, kita bisa melihat proses instalasi laravel 8. Setelah proses instalasi selesai kita bisa lihat folder project baru dengan nama `blog`. Kita masuk ke direktori project dengan menjalankan command.

```
cd blog
```

Selanjutnya kita bisa coba terlebih dahulu apakah proses instalasi project laravel 8 kita berhasil. Kita tes dengan menjalankan local development server menggunakan command `serve` punya Artisan CLI.
```
php artisan serve
```

Teman-teman bisa membuka `http://127.0.0.1:8000` di browser untuk tes instalasi. Ketika kita buka url di browser, kita bisa lihat halaman awal laravel 8, tanda instalasi laravel 8 berhasil.

## Step 2 - Konfigurasi Database {#step-2}
Langkah selanjutnya adalah mengatur konfigurasi database dari project kita. Sebagai contoh di project kita kali ini, katakanlah nama database yang akan kita pakai itu `db_blog`, lalu credential mysql di laptop kita itu usernamenya itu `admin` dan passwordnya itu `password`. 

Teman-teman boleh membuat terlebih dahulu database dengan nama `db_blog`, bisa lewat `phpmyadmin` atau lewat terminal pun boleh.

Setelah kita selesai membuat database,  untuk menghubungkan dengan database `db_blog` harus sesuaikan terlebih dahulu konfigurasinya di file `.env`. Sekarang kita buka file `.env` di text editor, lalu sesuaikan konfigurasi database seperti di bawah ini.
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_blog
DB_USERNAME=admin
DB_PASSWORD=password

```

Setelah selesai kita save lagi file `.env` sebelum melanjutkan ke langkah selanjutnya.

## Step 3 - Membuat Model dan Migration {#step-3}
Di langkah ini kita akan mencoba membuat model dan migration dengan satu `artisan` command. Kita buka kembali terminal atau cmd, kita jalankan `artisan` command di bawah ini.

```
php artisan make:model Post -m
```

Kita bisa lihat ada dua file yang berhasil digenerate menggunakan command di atas, yang pertama adalah file model `app/Models/Post.php` dan yang kedua file migration  `database/migrations/2021_08_18_043743_create_posts_table.php`. Sebagai catatan nama file migration itu disesuaikan dengan tanggal pada saat file migration itu dibuat. 

Misalkan teman-teman bertanya, kalau tanpa file migration gimana `artisan` command yang kita pakai? Kita bisa langsung ketik command `php artisan make:model Post` tanpa ada tanda atau opsi `-m`. Untuk generate file migration pada saat kita generate model, kita bisa tambahkan opsi `--migration` atau `-m` seperti yang dicontohkan di atas.

Selanjutnya kita coba atur atau definisikan atribut model apa saja yang akan kita tambahkan pada saat `mass assignment` atau proses insert data baru ke dalam database. Buka file `app/Models/Post.php`, lalu tambahkan properties `$fillable` di dalam class Post.
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

Bisa kita lihat di baris kode di atas, di dalam properties `$fillable`, kita mengijinkan atribut model, yaitu `title`, `content`, `slug` dan `status` untuk diinsert ke dalam database pada saat kita menggunakan method `create` nanti. Opsi lain kita bisa menggunakan attribut `$guarded`.

Setelah mengatur mass assignable di model, selanjutnya kita akan membuat tabel menggunakan file migration yang sudah kita generate sebelumnya. Buka file migration `2021_08_18_043743_create_posts_table.php` (jangan lupa namanya sesuai dengan tanggal file migration digenerate, jadi sudah pasti namanya beda di tanggalnya saja). Selanjutnya kita definisikan kolom apa saja yang ada di tabel `posts` yang akan kita buat.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePostsTable extends Migration
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
}


```

Setelah selesai, kita run migration menggunakan `artisan` command berikut ini.

```
php artisan migrate
```

Kita bisa lihat ada beberapa table baru di database project kita, termasuk table `posts` yang baru saja kita definisikan di file migration.

## Step 4 - Menampilkan Data Post {#step-4}
Baik, persiapan project kita sudah selesai, selanjutnya kita sudah bisa mulai untuk membuat fitur pertama, yaitu fitur untuk menampilkan data. Tentu saja, karena studi kasus kita tentang blog, data yang akan kita tampilkan adalah data post dari blog kita.

Untuk menangani data yang akan ditampilkan, kita coba buat controller baru yaitu `PostController` menggunakan `artisan` command berikut ini.
```
php artisan make:controller PostController

```

Kita bisa lihat ada file controller baru setelah command di atas berhasil kita run yaitu file `PostController.php` di direktori `app/Http/Controllers`. Kita buka file `app/Http/Controllers/PostController.php` di text editor. Setelah file `app/Http/Controllers/PostController.php` kita buka, kita tambahkan method `index()` di dalam class `PostController`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post; // load Post model
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::latest()->get();
        return view('posts.index', compact('posts'));
    }
}


```

Seperti yang teman-teman lihat di baris kode di atas, di dalam method `index()` kita mengambil data post, lalu kita passing data post itu ke view `index.blade.php` melalui method `view()` sebagai parameter kedua. Karena kita menggunakan model jangan lupa kita import terlebih dahulu class nya menggunakan statement `use`.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post; // tambahkan statement use untuk load model
use Illuminate\Http\Request;

class PostController extends Controller
{
			// isi class PostController
}


```

Baik kita lanjutkan.

Pada method `view()`, terdapat parameter `posts.index` ini artinya kita akan membuat sebuah folder baru yaitu `posts` di `resources/views`. Setelah itu kita buat file baru `resources/views/posts/index.blade.php`. Lalu kita ketik kode berikut ini.

```html

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Post List - Tutorial CRUD Laravel 8 @ qadrlabs.com</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>

<body>

    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12">

                <!-- Notifikasi menggunakan flash session data -->
                @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
                @endif

                @if (session('error'))
                <div class="alert alert-error">
                    {{ session('error') }}
                </div>
                @endif

                <div class="card border-0 shadow rounded">
                    <div class="card-body">
                        <a href="{{ route('post.create') }}" class="btn btn-md btn-success mb-3 float-right">New
                            Post</a>

                        <table class="table table-bordered mt-1">
                            <thead>
                                <tr>
                                    <th scope="col">Title</th>
                                    <th scope="col">Status</th>
                                    <th scope="col">Create At</th>
                                    <th scope="col">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse ($posts as $post)
                                <tr>
                                    <td>{{ $post->title }}</td>
                                    <td>{{ $post->status == 0 ? 'Draft':'Publish' }}</td>
                                    <td>{{ $post->created_at->format('d-m-Y') }}</td>
                                    <td class="text-center">
                                        <form onsubmit="return confirm('Apakah Anda Yakin ?');"
                                            action="{{ route('post.destroy', $post->id) }}" method="POST">
                                            <a href="{{ route('post.edit', $post->id) }}"
                                                class="btn btn-sm btn-primary">EDIT</a>
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-danger">HAPUS</button>
                                        </form>
                                    </td>
                                </tr>
                                @empty
                                <tr>
                                    <td class="text-center text-mute" colspan="4">Data post tidak tersedia</td>
                                </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

</body>

</html>

```

Ya, di dalam view kita terdapat beberapa blade directive, yaitu `@forelse` yang digunakan untuk menampilkan data, dan `@if` untuk menampilkan notifikasi. Selain itu, terdapat juga method 'route()' untuk menuju halaman `create`, `edit` dan `delete` data. 

Selanjutnya kita coba register route baru, kita buka file `routes/web.php`. Kita tambahkan route baru untuk membuka halaman data post kita di dalam file tersebut.

```php
<?php

use App\Http\Controllers\PostController; //load controller post

// baris kode lain

Route::resource('post', PostController::class);
```

Satu route di atas mendeklarasikan beberapa route yang dapat menangani beberapa action untuk `resource` seperti `create`, `show`, `update`, `delete` dan lain-lain. Teman-teman dapat mengecek route yang ada menggunakan `artisan` command.

```
php artisan route:list
```

Command tersebut menampilkan route yang terdapat di aplikasi laravel kita. 
```
+--------+-----------+---------------------+--------------+------------------------------------------------------------+------------------------------------------+
| Domain | Method    | URI                 | Name         | Action                                                     | Middleware                               |
+--------+-----------+---------------------+--------------+------------------------------------------------------------+------------------------------------------+
|        | GET|HEAD  | post                | post.index   | App\Http\Controllers\PostController@index                  | web                                      |
|        | POST      | post                | post.store   | App\Http\Controllers\PostController@store                  | web                                      |
|        | GET|HEAD  | post/create         | post.create  | App\Http\Controllers\PostController@create                 | web                                      |
|        | GET|HEAD  | post/{post}         | post.show    | App\Http\Controllers\PostController@show                   | web                                      |
|        | PUT|PATCH | post/{post}         | post.update  | App\Http\Controllers\PostController@update                 | web                                      |
|        | DELETE    | post/{post}         | post.destroy | App\Http\Controllers\PostController@destroy                | web                                      |
|        | GET|HEAD  | post/{post}/edit    | post.edit    | App\Http\Controllers\PostController@edit                   | web                                      |
+--------+-----------+---------------------+--------------+------------------------------------------------------------+------------------------------------------+
```

Dari daftar route di atas, kita juga bisa lihat method apa saja yang harus ada di class `PostController`.

## Step 5 - Membuat Post Baru {#step-5}
Halaman daftar postnya sudah kita buat, akan tetapi kita belum bisa menambahkan data baru. Nah, sekarang kita akan coba menambahkan fitur untuk membuat post baru. Untuk menambahkan fitur tersebut, kita coba buka kembali controller `PostController`, lalu kita tambahkan method baru untuk menampilkan halaman form untuk membuat post baru.

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

Lalu setelah itu kita membuat view baru sesuai dengan yang ada di method `view('posts.create)` di baris kode di atas. Buat file view baru `resources/views/posts/create.blade.php`, lalu kita coba ketik baris kode berikut ini.

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Create New Post - Tutorial CRUD Laravel 8 @ qadrlabs.com</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <!-- include summernote css -->
    <link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote.min.css" rel="stylesheet">
</head>

<body>

    <div class="container mt-5 mb-5">
        <div class="row">
            <div class="col-md-12">

                <!-- Notifikasi menggunakan flash session data -->
                @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
                @endif

                @if (session('error'))
                <div class="alert alert-error">
                    {{ session('error') }}
                </div>
                @endif

                <div class="card border-0 shadow rounded">
                    <div class="card-body">

                        <form action="{{ route('post.store') }}" method="POST">
                            @csrf

                            <div class="form-group">
                                <label for="title">Title</label>
                                <input type="text" class="form-control @error('title') is-invalid @enderror"
                                    name="title" value="{{ old('title') }}" required>

                                <!-- error message untuk title -->
                                @error('title')
                                <div class="invalid-feedback">
                                    {{ $message }}
                                </div>
                                @enderror
                            </div>

                            <div class="form-group">
                                <label for="status">Publish Status</label>
                                <select name="status" class="form-control" required>
                                    <option value="1" selected>Publish</option>
                                    <option value="0">Draft</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="content">Content</label>
                                <textarea
                                    name="content" id="content"
                                    class="form-control @error('content') is-invalid @enderror"
                                    rows="5"
                                    required>{{ old('content') }}</textarea>

                                <!-- error message untuk content -->
                                @error('content')
                                <div class="invalid-feedback">
                                    {{ $message }}
                                </div>
                                @enderror
                            </div>

                            <button type="submit" class="btn btn-md btn-primary">Save</button>
                            <a href="{{ route('post.index') }}" class="btn btn-md btn-secondary">back</a>

                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"
        integrity="sha384-9/reFTGAW83EW2RDu2S0VKaIzap3H66lZH81PoYlFhbGU+6BZp6G7niu735Sk7lN" crossorigin="anonymous">
    </script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

    <!-- include summernote js -->
    <script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote.min.js"></script>
    <script>
        $(document).ready(function() {
            $('#content').summernote({
                height: 250, //set editable area's height
            });
        })
    </script>
</body>

</html>

```

Pada form di atas, form action mengarah ke route `post.store`, jika kita cek menggunakan `artisan` command route ini mengarah ke method `store()` yang ada di dalam class `PostController`. Selanjutnya kita tambahkan method `store()` yang akan menghandle proses save data di `PostController`.

```php
<?php

// ... baris kode sebelumnya

use Illuminate\Support\Str; // tambahkan kode ini

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

    public function store(Request $request)
    {
        $this->validate($request, [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ]);

        $post = Post::create([
            'title' => $request->title,
            'content' => $request->content,
            'status' => $request->status,
            'slug' => Str::slug($request->title)
        ]);

        if ($post) {
            return redirect()
                ->route('post.index')
                ->with([
                    'success' => 'New post has been created successfully'
                ]);
        } else {
            return redirect()
                ->back()
                ->withInput()
                ->with([
                    'error' => 'Some problem occurred, please try again'
                ]);
        }
    }
}


```

Algoritma untuk menambahkan data di method `store()` ini terdapat tiga bagian, yaitu proses validasi, proses save data, dan redirect ke halaman ketika proses save selesai. 

Pada bagian proses validasi kita menggunakan method `validate()` dengan `$request` sebagai parameter pertama dan aturan validasi sebagai parameter kedua. Sebagai contoh, di tutorial ini kita hanya menggunakan `required` atau harus diisi, `string` untuk tipe data string, dan `max:value` untuk isian field. Apabila isian form tidak sesuai dengan aturan validasi, web akan menampilkan kembali halaman form tambah data dan akan menampilkan pesan error di masing-masing field. Teman-teman bisa cek kembali file `create.blade.php` terdapat kode berikut ini.

```html
<!-- error message untuk title -->
@error('title')
<div class="invalid-feedback">
    {{ $message }}
</div>
@enderror
```

`@error` directive kita gunakan untuk mengecek apakah terdapat pesan error validasi untuk atribut tertentu. Di dalam `@error` directive, kita bisa menampilkan pesan error dengan cara `echo` variable `$message`.

Apabila proses validasi sudah sesuai, selanjutnya terdapat proses insert data. Pada bagian kode untuk proses insert data, di tutorial ini kita menggunakan method `create()`. Di mana method ini menerima array dari atribut dan melakukan proses insert data ke dalam database.

```php
$post = Post::create([
    'title' => $request->title,
    'content' => $request->content,
    'status' => $request->status,
    'slug' => Str::slug($request->title)
]);
```

Oh iya untuk atribut `slug`, kita pakai helper `str` untuk generate slug yang URL friendly. Karena itu terdapat tambahan statement `use` sebelum deklarasi class `PostController`.

```php
use Illuminate\Support\Str;
```

Dan bagian terakhir adalah `redirect` ke halaman yang sudah ditentukan sesuai dengan kondisi berhasilnya proses insert data. Ketika proses insert berhasil kita arahkan ke halaman daftar post, dan apabila terjadi error diarahkan kembali ke halaman form.

## Step 6 - Update Data Post {#step-6}
Setelah menambahkan data, kita bisa melihat terdapat tombol `edit` di setiap baris data yang terdapat di dalam table daftar post. Teman-teman bisa cek kembali di file index.blade.php terdapat baris kode berikut ini.

```html
<a href="{{ route('post.edit', $post->id) }}" class="btn btn-sm btn-info shadow">Edit</a>
```

Tombol edit mengarah ke route `post.edit` dengan `$post->id` sebagai parameternya, di mana route ini mengarah ke method `edit()` di class `PostController`. Sekarang kita buka kembali `PostController`, lalu kita tambahkan method `edit()` untuk menampilkan halaman edit data.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

    public function edit($id)
    {
        $post = Post::findOrFail($id);
        return view('posts.edit', compact('post'));
    }
}


```

Pada method `edit()` di atas, kita coba passing data `$post` yang berisi data post berdasarkan parameter `$id` ke view `edit.blade.php` dengan menuliskan di parameter kedua method `view()`.

Selanjutnya kita buat file view baru `resources/views/posts/edit.blade.php`, lalu kita ketik baris kode berikut ini.

```html

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Edit Post - Tutorial CRUD Laravel 8 @ qadrlabs.com</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <!-- include summernote css -->
    <link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote.min.css" rel="stylesheet">
</head>

<body>

    <div class="container mt-5 mb-5">
        <div class="row">
            <div class="col-md-12">

                <!-- Notifikasi menggunakan flash session data -->
                @if (session('success'))
                <div class="alert alert-success">
                    {{ session('success') }}
                </div>
                @endif

                @if (session('error'))
                <div class="alert alert-error">
                    {{ session('error') }}
                </div>
                @endif

                <div class="card border-0 shadow rounded">
                    <div class="card-body">
                        <form action="{{ route('post.update', $post->id) }}" method="POST">
                            @csrf
                            @method('PUT')

                            <div class="form-group">
                                <label for="title">Title</label>
                                <input type="text" class="form-control @error('title') is-invalid @enderror"
                                    name="title" value="{{ old('title', $post->title) }}" required>

                                <!-- error message untuk title -->
                                @error('title')
                                <div class="invalid-feedback">
                                    {{ $message }}
                                </div>
                                @enderror
                            </div>

                            <div class="form-group">
                                <label for="status">Publish Status</label>
                                <select name="status" class="form-control" required>
                                    <option value="1" {{ $post->status == 1 ? 'selected':'' }}>Publish</option>
                                    <option value="0" {{ $post->status == 0 ? 'selected':'' }}>Draft</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="content">Content</label>
                                <textarea
                                    name="content" id="content"
                                    class="form-control @error('content') is-invalid @enderror" name="content" id="content"
                                    rows="5" required>{{ old('content', $post->content) }}</textarea>

                                <!-- error message untuk content -->
                                @error('content')
                                <div class="invalid-feedback">
                                    {{ $message }}
                                </div>
                                @enderror
                            </div>

                            <button type="submit" class="btn btn-md btn-primary">Update</button>
                            <a href="{{ route('post.index') }}" class="btn btn-md btn-secondary">back</a>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"
        integrity="sha384-9/reFTGAW83EW2RDu2S0VKaIzap3H66lZH81PoYlFhbGU+6BZp6G7niu735Sk7lN" crossorigin="anonymous">
    </script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <!-- include summernote js -->
    <script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote.min.js"></script>
    <script>
        $(document).ready(function() {
            $('#content').summernote({
                height: 250, //set editable area's height
            });
        })
    </script>
</body>

</html>

```

View yang kita buat untuk halaman edit data post tidak jauh beda dengan halaman tambah data post, kecuali di bagian berikut ini.

```html
<form action="{{ route('post.update', $post->id) }}" method="POST">
    @csrf
    @method('PUT')
```

Bisa kita perhatikan di bagian form. Yang pertama untuk proses update, kita menambahkan method PUT, mengingat HTML form tidak dapat membuat request PUT. Dan yang kedua form action mengarah ke route `post.update` dengan id sebagai parameternya. 

Sekarang kita buat method baru untuk menghandle proses update data di `PostController` sesuai dengan form action.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    
    // ... baris kode sebelumnya

    public function update(Request $request, $id)
    {
        $this->validate($request, [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ]);

        $post = Post::findOrFail($id);

        $post->update([
            'title' => $request->title,
            'content' => $request->content,
            'status' => $request->status,
            'slug' => Str::slug($request->title)
        ]);

        if ($post) {
            return redirect()
                ->route('post.index')
                ->with([
                    'success' => 'Post has been updated successfully'
                ]);
        } else {
            return redirect()
                ->back()
                ->withInput()
                ->with([
                    'error' => 'Some problem has occured, please try again'
                ]);
        }
    }
}

```

Algoritma untuk method `update()` tidak jauh berbeda dengan method `store()` proses insert data, kecuali bagian proses update data. Pada bagian proses update data kita mengambil data post berdasarkan parameter `$id` menggunakan method `findOrFail()`, lalu selanjutnya melakukan proses update data menggunakan method `update()` dengan array yang berisi atribut sebagai parameternya.
```php
        $post = Post::findOrFail($id);

        $post->update([
            'title' => $request->title,
            'content' => $request->content,
            'status' => $request->status,
            'slug' => Str::slug($request->title)
        ]);
```

## Step 7 - Hapus Data Post {#step-7}
Fitur terakhir dari `crud` yang akan kita tambahkan ke project kita adalah fitur untuk menghapus data post. Kita buka kembali file `PostController.php`, lalu di dalam class `PostController` kita tambahkan method `destroy()` yang akan menangani proses menghapus data dengan id sebagai parameter.

```php
<?php

// ... baris kode sebelumnya

class PostController extends Controller
{
    // ... baris kode sebelumnya

    public function destroy($id)
    {
        $post = Post::findOrFail($id);
        $post->delete();

        if ($post) {
            return redirect()
                ->route('post.index')
                ->with([
                    'success' => 'Post has been deleted successfully'
                ]);
        } else {
            return redirect()
                ->route('post.index')
                ->with([
                    'error' => 'Some problem has occurred, please try again'
                ]);
        }
    }
}

```

Algoritma untuk proses menghapus data ini kita bagi menjadi tiga bagian, yaitu pengecekan data berdasarkan id, proses delete data, dan bagian redirect ke halaman daftar post. Pada bagian pengecekan data, `$id` ini berdasarkan id post yang sudah kita tulis di halaman daftar post atau view `index.blade.php`. Pada view `index.blade.php` terdapat baris kode berikut ini.

```html
<form onsubmit="return confirm('Apakah Anda Yakin ?');"
    action="{{ route('post.destroy', $post->id) }}" method="POST">
    <a href="{{ route('post.edit', $post->id) }}"
        class="btn btn-sm btn-info shadow">Edit</a>
    @csrf
    @method('DELETE')
    <button type="submit" class="btn btn-sm btn-danger shadow">Delete</button>
</form>
```

Data diambil berdasarkan id menggunakan method `findOrFail()`. Apabila data ditemukan, data tersebut ditampung kedalam variable `$post`, dan apabila tidak ditemukan halaman akan menampilkan error. Setelah data ditemukan, kita gunakan method `delete()` untuk menghapus data.

```php
$post->delete();
```

Setelah itu kita alihkan kembali ke halaman daftar post, lalu menampilkan pesan sesuai dengan kondisi berhasil atau tidaknya proses delete.

Akhirnya seluruh step-step tutorial CRUD Laravel 8 ini selesai. Teman-teman bisa langsung coba running kembali aplikasinya dengan `artisan command`.

```
php artisan serve
```

Lalu buka url `http://127.0.0.1:8000/post` di browser. Teman-teman bisa coba untuk menambahkan data, mengedit data dan juga menghapus data.

## Kesimpulan {#kesimpulan}
Mana yang lebih baik framework Laravel atau framework yang lain? Itulah pertanyaan yang sering kita temukan di forum programming dan boleh jadi menjadi pertanyaan yang sering kita tanyakan. Setelah mempelajari laravel 8 untuk membuat aplikasi crud sederhana ini, ada beberapa hal yang saya temukan. Ya, kurang lebih saya sudah menemukan jawabannya. Bagaimana dengan kamu? Apakah sudah kamu temukan jawabannya?