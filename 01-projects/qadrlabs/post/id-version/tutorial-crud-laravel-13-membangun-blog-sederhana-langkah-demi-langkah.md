---
title: "Tutorial CRUD Laravel 13: Membangun Blog Sederhana Langkah demi Langkah"
slug: "tutorial-crud-laravel-13-membangun-blog-sederhana-langkah-demi-langkah"
original_title: "Laravel 13 CRUD Tutorial: Build a Simple Blog Step by Step"
original_slug: "laravel-13-crud-tutorial-build-a-simple-blog-step-by-step"
category: "Laravel"
date: "2026-03-23"
status: "draft"
---

Laravel 13 baru saja hadir dengan fitur-fitur baru yang menarik, seperti atribut `#[Fillable]` dan perluasan dukungan PHP attributes. Namun jika Anda baru mengenal framework ini atau sedang melakukan upgrade dari versi lama, menerapkan perubahan-perubahan tersebut dalam proyek nyata bisa terasa membingungkan. Dokumentasi resmi menjelaskan "apa"-nya, tetapi tidak selalu menjelaskan "bagaimana"-nya secara praktis. Tutorial ini hadir untuk menjembatani kesenjangan tersebut. Kita akan membangun blog sederhana dengan fitur CRUD lengkap menggunakan Laravel 13 secara bertahap, sehingga Anda bisa melihat secara langsung bagaimana setiap bagian saling terhubung dalam sebuah aplikasi yang berjalan.


## Ikhtisar {#overview}

Tutorial ini memandu Anda dalam membangun aplikasi blog dasar dari awal menggunakan Laravel 13. Kita akan membuat sistem manajemen post di mana Anda bisa membuat, melihat, mengedit, dan menghapus blog post.

### What You'll Build

Aplikasi blog sederhana dengan fitur-fitur berikut:

- Halaman daftar yang menampilkan semua post dengan pagination.
- Formulir untuk membuat post baru dengan kolom title, content, dan status.
- Halaman detail untuk melihat satu post.
- Formulir untuk mengedit post yang sudah ada.
- Fungsi hapus dengan konfirmasi.

![Project Preview](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/00-app-preview.webp)

### What You'll Learn

Dengan mengikuti tutorial ini, Anda akan belajar cara:

- Menyiapkan proyek Laravel 13 baru dari awal.
- Membuat model, migration, dan controller menggunakan perintah Artisan.
- Mendefinisikan skema database dan menjalankan migration.
- Membangun operasi CRUD dengan resource controller.
- Membuat Blade view yang diberi style dengan Tailwind CSS.
- Menggunakan atribut baru `#[Fillable]` di Laravel 13 pada Eloquent model.
- Menyiapkan resource route untuk pola URL RESTful.

### What You'll Need

Sebelum memulai, pastikan Anda sudah memiliki:

- PHP 8.3 atau lebih tinggi
- Composer terinstal secara global
- MySQL (atau database lain yang didukung)
- Code editor (Visual Studio Code direkomendasikan)
- Pemahaman dasar tentang PHP dan konsep Laravel


## Langkah 1: Buat Proyek Laravel {#step-1-create-laravel-project}

Mulailah dengan membuat proyek Laravel baru menggunakan Composer. Kita akan menamai proyek ini `blog`:

```
composer create-project laravel/laravel --prefer-dist blog
```

```
$ composer create-project laravel/laravel --prefer-dist blog
Creating a "laravel/laravel" project at "./blog"
Installing laravel/laravel (v13.1.0)
.
.
.
```

Tunggu hingga Composer selesai mengunduh dan menginstal semua dependencies. Output mengonfirmasi bahwa Laravel v13.1.0 sedang diinstal.

Setelah instalasi selesai, masuk ke direktori proyek:

```
cd blog
```

Jika Anda menggunakan Visual Studio Code, Anda bisa membuka proyek langsung dari terminal:

```
code .
```

Ini akan membuka seluruh folder proyek di editor Anda, sehingga mudah untuk berpindah antar file saat kita membangun aplikasi.


## Langkah 2: Konfigurasi Database {#step-2-setup-database-configuration}

Sebelum bisa menyimpan data, kita perlu memberi tahu Laravel cara terhubung ke database. Buka file `.env` di root proyek Anda dan perbarui pengaturan database:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password
```

**Catatan:** Sesuaikan nilai `DB_USERNAME` dan `DB_PASSWORD` dengan kredensial MySQL lokal Anda. Nilai `DB_DATABASE` adalah nama database yang akan digunakan Laravel. Anda tidak perlu membuat database secara manual, karena Laravel akan menawarkan untuk membuatnya saat Anda menjalankan perintah migration nanti.

Simpan file `.env` setelah melakukan perubahan.


## Langkah 3: Buat Model dan Migration {#step-3-create-model-and-migration}

Laravel menyediakan perintah Artisan yang menghasilkan boilerplate code untuk Anda. Perintah berikut membuat model `Post` dan file migration yang sesuai dalam satu langkah:

```
php artisan make:model Post -m
```

```
$ php artisan make:model Post -m

   INFO  Model [app/Models/Post.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_23_032654_create_posts_table.php] created successfully.  

```

Flag `-m` memberi tahu Artisan untuk menghasilkan file migration bersamaan dengan model. Ini menghemat Anda dari menjalankan dua perintah terpisah.

### Definisikan Skema Database

Buka file migration yang dihasilkan di `database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php` dan modifikasi dengan konten berikut:

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
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->enum('status', ['draft', 'publish'])->default('draft');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

Berikut fungsi masing-masing kolom:

- `id()` membuat primary key yang auto-increment.
- `string('title')` menyimpan title post sebagai kolom VARCHAR.
- `string('slug')->unique()` menyimpan versi title yang ramah URL. Constraint `unique()` memastikan tidak ada dua post dengan slug yang sama.
- `text('content')` menyimpan isi post, yang bisa lebih panjang dari yang diizinkan VARCHAR.
- `enum('status', ['draft', 'publish'])->default('draft')` membatasi status hanya pada dua nilai yang mungkin dan mengatur post baru ke "draft" secara default.
- `timestamps()` menambahkan kolom `created_at` dan `updated_at` yang dikelola otomatis oleh Laravel.

Simpan file migration.

### Konfigurasi Model

Buka `app/Models/Post.php` dan ganti isinya dengan:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'slug', 'content', 'status'])]
class Post extends Model
{
    use HasFactory;
}
```

Perhatikan atribut `#[Fillable]` pada deklarasi class. Ini adalah fitur baru di Laravel 13 yang menggunakan sintaks native PHP attribute untuk mendefinisikan kolom mana yang bisa di-mass-assign. Pada versi sebelumnya, Anda perlu mengatur properti `$fillable` di dalam class. Pendekatan dengan attribute ini membuat konfigurasi lebih deklaratif dan terletak bersama definisi class.

Simpan file model.

### Jalankan Migration

Sekarang jalankan migration untuk membuat tabel `posts` di database Anda:

```
php artisan migrate
```

```
$ php artisan migrate

   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Karena database belum ada, Laravel menanyakan apakah Anda ingin membuatnya. Pilih **Yes** dan tekan Enter untuk melanjutkan. Laravel akan membuat database dan menjalankan semua migration yang tertunda, termasuk tabel `posts` yang baru saja kita definisikan.


## Langkah 4: Bangun Fitur Daftar Post {#step-4-build-post-listing}

Dengan database yang sudah siap, mari mulai membangun lapisan aplikasi. Kita akan mulai dengan halaman daftar post.

### Buat Resource Controller

Gunakan Artisan untuk menghasilkan resource controller yang sudah terhubung dengan model `Post`:

```
php artisan make:controller PostController --model=Post --resource
```

```
$ php artisan make:controller PostController --model=Post --resource

   INFO  Controller [app/Http/Controllers/PostController.php] created successfully.  

```

Flag `--resource` menghasilkan controller dengan tujuh metode RESTful (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) yang sudah dibuat. Flag `--model=Post` menambahkan type-hint model `Post` pada metode yang membutuhkannya, seperti `show`, `edit`, `update`, dan `destroy`.

### Implementasi Metode Index

Buka `app/Http/Controllers/PostController.php` dan modifikasi metode `index()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::latest()->paginate(10);
        return view('posts.index', compact('posts'));
    }

    // ... [other lines of code]
}
```

`Post::latest()` mengurutkan query berdasarkan `created_at` secara descending, sehingga post terbaru muncul pertama. `paginate(10)` membatasi hasil hingga 10 per halaman dan secara otomatis menghasilkan link pagination. Fungsi `compact('posts')` meneruskan variabel `$posts` ke Blade view.

Simpan file controller.

### Buat Index View

Buat file baru di `resources/views/posts/index.blade.php` dan tambahkan konten berikut:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
            <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                Create New Post
            </a>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-6" role="alert">
                <span class="block sm:inline">{{ session('success') }}</span>
            </div>
        @endif

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">No</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($posts as $post)
                    <tr class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">{{ $posts->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $post->title }}</td>
                        <td class="px-6 py-4 text-sm text-gray-500 break-words">{{ $post->slug }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                                {{ ucfirst($post->status) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                            <a href="{{ route('posts.show', $post) }}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:outline-none transition ease-in-out duration-150 shadow-sm">View</a>
                            <a href="{{ route('posts.edit', $post) }}" class="inline-flex items-center px-3 py-1.5 bg-amber-500 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-600 focus:outline-none transition ease-in-out duration-150 shadow-sm">Edit</a>
                            <form action="{{ route('posts.destroy', $post) }}" method="POST" class="inline-block m-0">
                                @csrf
                                @method('DELETE')
                                <button type="submit" onclick="return confirm('Are you sure you want to delete this post?')" class="inline-flex items-center px-3 py-1.5 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-700 focus:outline-none transition ease-in-out duration-150 shadow-sm">Delete</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No posts found.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            {{ $posts->links() }}
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

Beberapa hal yang perlu diperhatikan tentang view ini:

- Kita menggunakan **Tailwind CSS via CDN** untuk styling, yang membuat tutorial ini sederhana tanpa memerlukan proses build.
- Direktif `@forelse` / `@empty` menangani kedua kondisi: saat post ada dan saat tabel kosong.
- `$posts->firstItem() + $loop->index` menghitung nomor baris yang benar di halaman yang berbeda-beda. Misalnya, di halaman 2 dengan 10 item per halaman, penomoran dimulai dari 11, bukan kembali ke 1.
- Tombol delete dibungkus dalam form dengan `@method('DELETE')` karena form HTML hanya mendukung GET dan POST. Laravel menggunakan hidden field ini untuk menginterpretasikan request sebagai metode DELETE.
- `{{ $posts->links() }}` merender kontrol pagination secara otomatis.

Simpan file view.

### Daftarkan Routes

Buka `routes/web.php` dan daftarkan resource route untuk `PostController`:

```php
<?php

use App\Http\Controllers\PostController; // add this use statement
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::resource('posts', PostController::class); // add this resource route
```

`Route::resource()` mendaftarkan semua tujuh route RESTful (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) dalam satu baris. Ini setara dengan menulis tujuh definisi route secara manual. Laravel memetakan setiap route ke metode yang sesuai di `PostController`.

Simpan file route.


## Langkah 5: Bangun Fitur Buat Post {#step-5-build-create-post}

Sekarang mari implementasikan kemampuan untuk menambahkan post baru.

### Implementasi Metode Create

Buka `app/Http/Controllers/PostController.php` dan perbarui metode `create()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    // ... [other lines of code]
}
```

Metode ini cukup mengembalikan view form create. Tidak ada data yang perlu diteruskan karena form dimulai dalam keadaan kosong.

Simpan file controller.

### Buat Form View

Buat file baru di `resources/views/posts/create.blade.php` dan tambahkan konten berikut:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Post</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Create Post</h1>
            <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>
        
        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('posts.store') }}" method="POST" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            

            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content') }}</textarea>
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status') == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="publish" {{ old('status') == 'publish' ? 'selected' : '' }}>Publish</option>
                </select>
            </div>
            
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Submit Post
                </button>
            </div>
        </form>
    </div>


    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

Beberapa hal yang perlu disorot dari form ini:

- `@csrf` menghasilkan hidden field token CSRF. Laravel mewajibkan ini pada semua form POST, PUT, PATCH, dan DELETE untuk mencegah serangan cross-site request forgery.
- `{{ old('title') }}` mengisi ulang kolom dengan data yang sebelumnya dikirimkan jika validasi gagal, sehingga pengguna tidak perlu mengetik ulang semuanya.
- Blok `@if($errors->any())` di bagian atas menampilkan pesan error validasi ketika pengiriman form ditolak.

Simpan file view.

### Implementasi Metode Store

Buka `app/Http/Controllers/PostController.php` lagi dan perbarui metode `store()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str; // add this line of code

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->merge([
            'slug' => Str::slug($request->title),
        ]);

        $validatedData = $request->validate([
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ]);

        Post::create($validatedData);

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    // ... [other lines of code]
}
```

Berikut yang terjadi langkah per langkah:

1. `$request->merge()` menghasilkan slug dari title menggunakan `Str::slug()`. Misalnya, "My First Post" menjadi "my-first-post". Ini digabungkan ke data request sebelum validasi.
2. `$request->validate()` memeriksa bahwa semua kolom yang wajib ada dan valid. Aturan `unique:posts,slug` memastikan tidak ada slug duplikat di database. Aturan `in:draft,publish` membatasi status hanya pada dua nilai tersebut. Jika validasi gagal, Laravel secara otomatis redirect kembali ke form dengan pesan error.
3. `Post::create($validatedData)` menyisipkan record baru ke tabel `posts` menggunakan hanya kolom yang sudah divalidasi. Ini berfungsi karena kita mendefinisikan atribut `#[Fillable]` pada model sebelumnya.
4. `redirect()->route('posts.index')->with('success', ...)` mengirim pengguna kembali ke halaman daftar dengan flash message yang mengonfirmasi bahwa post berhasil dibuat.

Karena kita akan mengonversi title menjadi slug, kita akan menggunakan helper class dari framework Laravel dengan menambahkan `use Illuminate\Support\Str;`.

```php
use Illuminate\Support\Str; // add this line of code

class PostController extends Controller
{
    // ... [other lines of code]
}
```

Simpan file controller.


## Langkah 6: Bangun Fitur Lihat Detail Post {#step-6-build-view-post-detail}

Selanjutnya, mari tambahkan kemampuan untuk melihat detail satu post.

### Implementasi Metode Show

Buka `app/Http/Controllers/PostController.php` dan perbarui metode `show()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    // ... [other lines of code]
}
```

Parameter `Post $post` menggunakan **route model binding** dari Laravel. Ketika pengguna mengunjungi `/posts/1`, Laravel secara otomatis mencari `Post` dengan ID 1 dan menyuntikkannya ke dalam metode. Jika tidak ada record yang cocok, Laravel mengembalikan respons 404.

Simpan file controller.

### Buat Show View

Buat file baru di `resources/views/posts/show.blade.php` dan tambahkan:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Post - {{ $post->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-6">
        <div class="flex justify-between items-start mb-6 pb-6 border-b border-gray-200">
            <div>
                <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ $post->title }}</h1>
                <div class="flex items-center space-x-4 text-sm text-gray-500">
                    <span class="flex items-center">
                        <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                        </svg>
                        {{ $post->slug }}
                    </span>
                    <span class="px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                        {{ ucfirst($post->status) }}
                    </span>
                </div>
            </div>
            <div class="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3 items-end sm:items-center">
                <a href="{{ route('posts.index') }}" class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</a>
                <a href="{{ route('posts.edit', $post) }}" class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit Post</a>
            </div>
        </div>
        
        <div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap text-[17px]">
{{ $post->content }}
        </div>
        
        <div class="mt-10 pt-6 border-t border-gray-100 flex flex-col sm:flex-row sm:justify-between text-sm text-gray-500">
            <span>Posted: {{ $post->created_at->format('M d, Y H:i') }}</span>
            @if($post->updated_at != $post->created_at)
                <span>Updated: {{ $post->updated_at->format('M d, Y H:i') }}</span>
            @endif
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

View ini menampilkan title post, slug, badge status, konten lengkap, dan timestamp. Pemanggilan `$post->created_at->format('M d, Y H:i')` menggunakan Carbon (yang sudah disertakan Laravel secara default) untuk memformat timestamp menjadi string yang mudah dibaca seperti "Mar 23, 2026 15:30".

Simpan file view.


## Langkah 7: Bangun Fitur Perbarui Post {#step-7-build-update-post}

Sekarang mari tambahkan kemampuan untuk mengedit post yang sudah ada.

### Implementasi Metode Edit

Buka `app/Http/Controllers/PostController.php` dan perbarui metode `edit()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    // ... [other lines of code]
}
```

Seperti metode `show()`, `edit()` menggunakan route model binding untuk mengambil post. Data post yang ada diteruskan ke view agar form bisa diisi sebelumnya.

Simpan file controller.

### Buat Edit View

Buat file baru di `resources/views/posts/edit.blade.php` dan tambahkan:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Post - {{ $post->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Edit Post</h1>
            <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>
        
        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('posts.update', $post) }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title" value="{{ old('title', $post->title) }}" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            

            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content', $post->content) }}</textarea>
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status', $post->status) == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="publish" {{ old('status', $post->status) == 'publish' ? 'selected' : '' }}>Publish</option>
                </select>
            </div>
            
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Update Post
                </button>
            </div>
        </form>
    </div>


    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

Form edit mirip dengan form create, dengan dua perbedaan utama:

- `@method('PUT')` menambahkan hidden field yang memberi tahu Laravel untuk memperlakukan pengiriman form ini sebagai request PUT, yang dipetakan ke metode controller `update()`.
- `{{ old('title', $post->title) }}` menggunakan parameter kedua sebagai fallback. Jika tidak ada old input (yaitu form belum pernah dikirimkan), maka nilai saat ini dari database yang ditampilkan. Ini memastikan form terisi dengan data yang ada saat pengguna pertama kali membukanya.

Simpan file view.

### Implementasi Metode Update

Buka `app/Http/Controllers/PostController.php` dan perbarui metode `update()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Post $post)
    {
        $request->merge([
            'slug' => Str::slug($request->title),
        ]);

        $validatedData = $request->validate([
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug,' . $post->id . '|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ]);

        $post->update($validatedData);

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

    // ... [other lines of code]
}
```

Metode `update()` mengikuti pola yang mirip dengan `store()`, tetapi dengan satu perbedaan penting dalam aturan validasi. Pengecekan keunikan slug menyertakan `$post->id` sebagai pengecualian: `unique:posts,slug,' . $post->id`. Ini memberi tahu Laravel untuk mengabaikan post saat ini ketika memeriksa slug duplikat. Tanpa pengecualian ini, memperbarui post tanpa mengubah title-nya akan gagal validasi karena slug yang ada akan ditandai sebagai duplikat dari dirinya sendiri.

Simpan file controller.


## Langkah 8: Bangun Fitur Hapus Post {#step-8-build-delete-post}

Operasi CRUD terakhir adalah menghapus post.

### Implementasi Metode Destroy

Buka `app/Http/Controllers/PostController.php` dan perbarui metode `destroy()`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

Metode `destroy()` cukup sederhana. Ia memanggil `$post->delete()` untuk menghapus record dari database, lalu redirect kembali ke halaman daftar dengan pesan sukses. Tombol delete di index view sudah menyertakan dialog JavaScript `confirm()`, sehingga pengguna mendapat konfirmasi sebelum penghapusan dieksekusi.

Simpan file controller.


## Langkah 9: Uji Aplikasi {#step-9-test-the-application}

Dengan semua operasi CRUD yang sudah diimplementasikan, saatnya menguji aplikasi. Jalankan development server:

```
php artisan serve
```

Buka browser dan navigasikan ke `http://127.0.0.1:8000/posts`. Anda akan melihat halaman daftar post dengan tabel kosong dan tombol "Create New Post".
![View Post listing page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/01-view-post-lists.webp)

### Uji Membuat Post

Klik tombol **Create New Post**. Isi form dengan title, content, dan status, lalu klik **Submit Post**. Anda akan diarahkan kembali ke halaman daftar dengan pesan sukses berwarna hijau, dan post baru Anda akan muncul di tabel.

![test create new post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/02-test-create-new-post-feature.webp)

![post created](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/03-post-created.webp)

### Uji Melihat Post

Klik tombol **View** pada salah satu post di tabel. Anda akan melihat halaman detail yang menampilkan title post, slug, status, konten lengkap, dan timestamp.

![view post by id](https://cdn.jsdelivr.net/gh/gungunpriatna/qadrlabs-assets@main/laravel/laravel-13/crud-tutorial/04-test-view-post-by-id.webp)

### Uji Mengedit Post

Klik tombol **Edit** pada salah satu post. Form akan terisi otomatis dengan data post saat ini. Lakukan beberapa perubahan dan klik **Update Post**. Anda akan diarahkan kembali ke halaman daftar dengan pesan sukses, dan data yang diperbarui akan terlihat di tabel.

![test view edit post form](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/05-test-view-edit-post-form.webp)

![test update post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/06-test-update-post-feature.webp)

![post updated](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/07-post-updated.webp)

### Uji Menghapus Post

Klik tombol **Delete** pada salah satu post. Dialog konfirmasi browser akan muncul. Klik OK untuk mengonfirmasi. Post akan dihapus dari tabel dan pesan sukses akan ditampilkan.

![test delete post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/08-test-delete-post-feature.webp)

![post deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/09-post-deleted.webp)

## Kesimpulan {#conclusion}

Dalam tutorial ini, kita membangun aplikasi CRUD lengkap menggunakan Laravel 13 dari awal. Dimulai dari proyek baru, kita menyiapkan database, membuat model dengan atribut baru `#[Fillable]`, menghasilkan resource controller, membangun Blade view dengan Tailwind CSS, dan mengimplementasikan semua empat operasi CRUD.

Berikut adalah poin-poin penting yang bisa dipetik:

- **Artisan mempercepat proses scaffolding.** Perintah seperti `make:model -m` dan `make:controller --resource` menghasilkan boilerplate code sehingga Anda bisa fokus pada logika bisnis.
- **Resource controller dan route mengurangi pengulangan.** Satu baris `Route::resource()` mendaftarkan semua tujuh route RESTful, dan flag `--resource` pada controller menghasilkan stub metode yang sesuai.
- **Atribut `#[Fillable]` adalah tambahan baru di Laravel 13.** Alih-alih mendefinisikan properti `$fillable` di dalam model, sekarang Anda bisa menggunakan PHP attribute pada deklarasi class untuk pendekatan yang lebih bersih dan deklaratif.
- **Validasi dan pembuatan slug bekerja bersama.** Dengan menggabungkan slug ke dalam request sebelum validasi, Anda bisa memvalidasinya seperti kolom lainnya, termasuk memeriksa keunikannya.
- **Route model binding menyederhanakan pengambilan data.** Type-hinting sebuah model dalam metode controller membuat Laravel secara otomatis menemukan record atau mengembalikan 404.
- **Selalu uji setelah setiap fitur.** Menjalankan aplikasi dan memverifikasi setiap operasi CRUD memastikan semuanya berfungsi sebelum melanjutkan ke langkah berikutnya.

Source code lengkap untuk proyek ini tersedia sebagai referensi di [https://github.com/qadrLabs/laravel-13-crud-demo](https://github.com/qadrLabs/laravel-13-crud-demo). Pada tutorial berikutnya, kita akan belajar [cara melakukan testing menggunakan Pest](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application) pada aplikasi blog yang sudah kita kembangkan dalam tutorial ini.
