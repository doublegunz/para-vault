---
title: "REST API CRUD With Laravel Sanctum"
slug: "rest-api-crud-with-laravel-sanctum"
category: "Laravel"
date: "2022-06-12"
status: "published"
---

Setelah mencoba membuat [Rest API Authentication](https://qadrlabs.com/post/rest-api-authentication-with-laravel-sanctum) menggunakan laravel sanctum, rasanya tidak lengkap kalau belum mencoba menambahkan fitur REST API untuk CRUD. Oleh karena itu, pada tutorial ini kita coba lanjutkan belajar laravel sanctum dan kita coba ambil studi kasus dari seri belajar laravel sebelumnya, yaitu blog. 

Pada tutorial ini kita akan belajar bagaimana membuat REST API yang menangani proses CRUD (create, read, update, dan delete) sebuah postingan dalam blog dan me-return response berupa JSON. Selain itu, kita juga akan coba menggunakan token based authentication setiap mengirimkan request ke api endpoint. Dan supaya kedepannya hasil belajar sekarang bisa digunakan untuk SPA juga, kita juga akan menambahkan sanctum middleware untuk memastikan setiap request yang masuk dari SPA dapat diotentikasi menggunakan session cookies punya Laravel. Apa saja langkah-langkah yang akan kita lakukan di tutorial ini? 

- [Persiapan](#persiapan)
- [Step 1 - Membuat Model dan Migration File](#step-1)
- [Step 2 - Membuat API Resources](#step-2)
- [Step 3 - Membuat API Controller](#step-3)
- [Step 4 - Definisikan Route](#step-4)
- [Step 5 - Uji Coba](#step-5)
- [Uji Coba Tambah Data Baru](#uji-coba-1)
- [Uji Coba ambil semua data](#uji-coba-2)
- [Uji Coba ambil satu data berdasarkan id](#uji-coba-3)
- [Uji Coba Update Data](#uji-coba-4)
- [Uji Coba Delete Data](#uji-coba-5)
- [Penutup](#penutup)

## Persiapan {#persiapan}

Untuk teman-teman yang ingin ikut belajar, ada tiga hal yang harus dipersiapkan.

1. Project dari tutorial sebelumnya, yaitu [REST API Authentication](https://qadrlabs.com/post/rest-api-authentication-with-laravel-sanctum). Karena ini tutorial lanjutan, jadi pastikan sudah selesai membuat project dari tutorial sebelumnya.
2. Token untuk otentikasi. Token ini didapatkan setelah teman-teman uji coba proses login di tutorial sebelumnya. Jadi jangan lupa catat tokennya pada saat berhasil uji coba proses login.
3. `Postman`. Sama seperti tutorial sebelumnya, postman akan kita gunakan untuk proses uji coba mengirimkan request.

Kalau semua persiapan sudah selesai, sekarang kita bisa mulai belajar membuat REST API CRUD dengan Laravel Sanctum.

**Catatan:**
Awalnya tutorial ini disusun dan diujicoba menggunakan laravel 11. Per tanggal 5 Maret 2025, tutorial ini telah diuji coba menggunakan framework [laravel versi 12](https://qadrlabs.com/post/laravel-12).

## Step 1 - Membuat Model dan Migration File{#step-1}

Sekarang kita buat file model dan migration untuk table `posts`. Seperti yang sudah sebelumnya kita bahas, kita ambil studi kasus dari seri belajar laravel sebelumnya tentang blog. Jadi skema table-nya pun kita samakan dengan skema table dari seri belajar sebelumnya.

Sekarang kita generate file model dan migration menggunakan `artisan` command berikut ini.

```
php artisan make:model Post -m
```

Setelah kita run command di atas terdapat dua file baru, yaitu file model dan juga migration. Sekarang kita buka file `app/Models/Post.php` lalu kita definisikan property `$fillable` untuk mass assignment proses insert.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = ['title', 'content', 'slug', 'status']; // tambahkan $fillable
}

```

Selanjutnya kita modifikasi file migration `database/migrations/xxxx_xx_xx_114240_create_posts_table.php` untuk membuat table `posts`.

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

Bisa kita lihat pada baris kode di atas, skema untuk table `posts` sama seperti seri belajar laravel sebelumnya.

Setelah selesai, selanjutnya kita coba run `migrate` artisan command .

```
php artisan migrate
```

## Step 2 - Membuat API Resources{#step-2}

Selanjutnya kita perlu layer yang dapat mengubah model atau model collection menjadi JSON. Di sini kita akan coba gunakan Eloquent Api Resources class yang menangani model untuk diubah menjadi JSON. Untuk generate resource class, kita gunakan `artisan` command berikut ini.

```
php artisan make:resource PostResource
```

Kita bisa lihat ada file baru di  direktori `app/Http/Resources`, yaitu `PostResource.php`. Selanjutnya kita buka file `app/Http/Resources/PostResource.php`, lalu kita modifikasi dan sesuaikan method `toArray()`.

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array|\Illuminate\Contracts\Support\Arrayable|\JsonSerializable
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'slug' => $this->slug,
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}

```

Pada baris kode di atas, method `toArray()` ini me-return sebuah array yang nantinya akan diubah menjadi JSON ketika resource class di-return sebagai response di method pada controller nantinya.

## Step 3 - Membuat API Controller{#step-3}

Langkah selanjutnya adalah membuat sebuah controller yang akan menangani crud rest api di project kita. Kita generate controller baru menggunakan `artisan` command berikut ini.

```
php artisan make:controller Api/PostController --model=Post
```

Setelah `PostController` berhasil digenerate, selanjutnya kita sesuaikan isi class `PostController`.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        $posts = Post::latest()->get();
        return response()->json([
            'data' => PostResource::collection($posts),
            'message' => 'Fetch all posts',
            'success' => true
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'data' => [],
                'message' => $validator->errors(),
                'success' => false
            ]);
        }

        $post = Post::create([
            'title' => $request->get('title'),
            'content' => $request->get('content'),
            'status' => $request->get('status'),
            'slug' => Str::slug($request->get('title'))
        ]);

        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Post created successfully.',
            'success' => true
        ]);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Post  $post
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Post $post)
    {
        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Data post found',
            'success' => true
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Post  $post
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Post $post)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'data' => [],
                'message' => $validator->errors(),
                'success' => false
            ]);
        }

        $post->update([
            'title' => $request->get('title'),
            'content' => $request->get('content'),
            'status' => $request->get('status'),
            'slug' => Str::slug($request->get('title'))
        ]);

        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Post updated successfully',
            'success' => true
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Post  $post
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Post $post)
    {
        $post->delete();

        return response()->json([
            'data' => [],
            'message' => 'Post deleted successfully',
            'success' => true
        ]);
    }
}
```

Bisa kita lihat pada `PostController`, kita hanya menggunakan 5 method untuk menangani operasi crud, yaitu `index()` untuk menampilkan semua data, `show()` menampilkan satu data berdasarkan id, `store()` untuk menambahkan data baru, `update()` untuk memperbaharui data, dan `delete()` untuk menghapus data berdasarkan id.

## Step 4 - Definisikan Route{#step-4}

Selanjutnya kita definisikan route baru untuk controller API kita. Buka file `routes/api.php` lalu kita tambahkan route baru.

```php
<?php

// ... baris kode lainnya

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);

    Route::resource('/posts', \App\Http\Controllers\Api\PostController::class); // tambahkan ini
});

```

Bisa kita lihat pada baris kode di atas, route untuk api crud kita definisikan dengan middleware `auth:sanctum` sama seperti route `logout` dari tutorial sebelumnya. Alasannya adalah karena kita akan coba gunakan token based authentication untuk setiap request yang masuk.

Sekarang kita coba cek route yang baru saja kita definisikan menggunakan command ini.

```
php artisan route:list --except-vendor
```

Output:

```
  GET|HEAD        / .......................................................... 
  POST            api/login ......................... Api\AuthController@login
  POST            api/logout ....................... Api\AuthController@logout
  GET|HEAD        api/posts ........... posts.index › Api\PostController@index
  POST            api/posts ........... posts.store › Api\PostController@store
  GET|HEAD        api/posts/create .. posts.create › Api\PostController@create
  GET|HEAD        api/posts/{post} ...... posts.show › Api\PostController@show
  PUT|PATCH       api/posts/{post} .. posts.update › Api\PostController@update
  DELETE          api/posts/{post} posts.destroy › Api\PostController@destroy
  GET|HEAD        api/posts/{post}/edit . posts.edit › Api\PostController@edit
  POST            api/register ................... Api\AuthController@register
  GET|HEAD        api/user ................................................... 

                                                           Showing [12] routes
```

Ya, ditambah dengan route dari tutorial sebelumnya terdapat 12 routes, termasuk route untuk menangani crud yang baru saja kita definisikan.

## Step 5 - Uji Coba{#step-5}

Sebelum kita mulai testing, sekarang kita run project kita menggunakan `artisan` command.

```
php artisan serve
```

Sebagai pengingat dan seperti yang sudah kita bahas di bagian **Persiapan**,  kita akan menggunakan token yang didapat pada saat proses login. Cara untuk mendapatkan tokennya, teman-teman bisa baca-baca kembali [tutorial sebelumnya](https://qadrlabs.com/post/rest-api-authentication-with-laravel-sanctum) di bagian **Uji Coba Login**.

### Uji Coba Tambah Data Baru{#uji-coba-1}

Selanjutnya kita coba untuk menambahkan data baru melalui api. Sekarang kita buka `postman` lalu kita tambahkan http request baru. Kita sesuaikan seperti berikut ini.

1. Pada menu `HTTP request method` kita pilih `POST` method.
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/posts`.
3. Pada tab `Body`, kita pilih radio button `form-data`, lalu kita coba masukan sample data untuk `title`, `content` dan `status`.
4. Selanjutnya buka tab `Authorization`, pilih type `Bearer Token` dan masukan token yang didapat pada saat uji coba login di form input `Token`.

Setelah itu kita kirim POST request dengan menekan tombol `Send`. Kurang lebih output yang ditampilkan sepert di bawah ini.

![Uji coba kirim request tambah data baru](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-sanctum/uji-coba-create.png)

Teman-teman boleh coba send Post request beberapa kali.

### Uji Coba ambil semua data{#uji-coba-2}

Selanjutnya kita coba untuk mengambil semua data. Kita buka kembali `postman`, lalu kita sesuikan kembali seperti berikut ini.

1. Pada menu `HTTP request method` kita ubah menjadi `GET` method.
2. Untuk url ambil semua data masih sama seperti sebelumnya, yaitu `http://127.0.0.1:8000/api/posts`.
3. Selanjutnya pada tab `Authorization`, pengaturannya masih sama seperti sebelumnya.

Selanjutnya kita tekan tombol `Send` untuk mengirim GET request dan output yang ditampilkan seperti gambar di bawah ini.

![Uji coba kirim request ambil semua data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-sanctum/uji-coba-ambil-semua-data.png)

### Uji Coba ambil satu data berdasarkan id{#uji-coba-3}

Pada output uji coba ambil semua data, kita bisa lihat ada data dengan id 3. Selanjutnya kita coba ambil data id 3 ini menggunakan `postman`. Kita sesuaikan kembali pengaturannya.

1. Pada menu `HTTP request method`  masih sama yaitu kita gunakan `GET` method.
2. Untuk url ambil data berdasarkan id, kita set url-nya menjadi `http://127.0.0.1:8000/api/posts/3`.
3. Selanjutnya pada tab `Authorization`, pengaturannya masih sama seperti sebelumnya.

Setelah kita sesuaikan, selanjutnya kita kirim GET request untuk mengambil data berdasarkan id. 

![Uji coba kirim request ambil satu data berdasarkan id](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-sanctum/uji-coba-ambil-satu-data.png)

### Uji Coba Update Data{#uji-coba-4}

Sekarang kita coba perbaharui data untuk post dengan id 3. Kita buka kembali, lalu kita sesuaikan pengaturannya seperti berikut ini.

1. Pada menu `HTTP request method` kita ubah menjadi `PUT` method.
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/posts/3` dengan id 3 sebagai parameternya.
3. Pada tab `Params`, kita coba masukan sample data untuk `title`, `content` dan `status` yang sudah diperbaharui.
4. Selanjutnya pada tab `Authorization`, pengaturannya masih sama seperti sebelumnya.

Sekarang kita coba kirim PUT request untuk memperbaharui data dengan cara menekan tombol `Send` dan kita bisa lihat outputnya kurang lebih seperti pada gambar di bawah ini.

![Uji coba kirim request update data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-sanctum/uji-coba-update.png)

### Uji Coba Delete Data{#uji-coba-5}

Ini adalah uji coba kita yang terakhir, yaitu delete data berdasarkan id. Langsung saja kita sesuaikan pengaturannya untuk mengirim DELETE request.

1. Pada menu `HTTP request method` kita ubah menjadi `DELETE` method.
2. Pada input url kita arahkan urlnya ke `http://127.0.0.1:8000/api/posts/3` dengan id 3 sebagai parameternya.
3. Selanjutnya pada tab `Authorization`, pengaturannya masih sama seperti sebelumnya.

Baik, sekarang kita klik tombol `Send` untuk mulai mengirimkan DELETE request dan kurang lebih hasilnya seperti gambar di bawah ini.

![Uji coba kirim request delete data](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/crud-laravel-sanctum/uji-coba-delete.png)

## Penutup{#penutup}

Pada tutorial REST API CRUD dengan Laravel Sanctum ini kita sudah coba melanjutkan project dari tutorial sebelumnya dengan menambahkan api endpoint untuk menangani proses CRUD. Proses CRUD yang tersedia atau yang sudah kita tambahkan meliputi proses ambil semua data, ambil satu data berdasarkan id, menambahkan data, memperbaharui data dan menghapus data berdasarkan id. Kita juga sudah coba bagaimana melakukan request untuk proses CRUD ini dengan menggunakan `postman`. Selain itu untuk mengirimkan request, kita juga perlu token yang didapat pada saat uji coba login yang sebelumnya sudah kita coba di tutorial laravel sanctum sebelumnya.

Bagiamana kalau ingin belajar lebih banyak tentang Laravel Sanctum? Kalau tertarik untuk belajar lagi, kita bisa mengkaji [dokumentasi resmi laravel sanctum](https://laravel.com/docs/12.x/sanctum).