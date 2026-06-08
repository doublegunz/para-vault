---
title: "Belajar TDD Laravel: Studi Kasus Menambahkan Post Baru"
slug: "belajar-tdd-laravel-studi-kasus-menambahkan-post-baru"
category: "Laravel"
date: "2025-02-12"
status: "published"
---

## Introduction{#introduction}
Halo, teman-teman developer! Pernahkah kamu mendengar istilah **Test-Driven Development (TDD)**? Jika belum, jangan khawatir—kita akan membahasnya secara mendalam dalam artikel ini. Atau, mungkin kamu sudah familiar dengan TDD tapi masih bingung bagaimana menerapkannya dalam proyek Laravel? Nah, artikel ini adalah jawabannya! Kita akan belajar menggunakan TDD untuk membuat fitur "Menambahkan Post Baru" di Laravel, lengkap dengan pembuatan *view add post form* dan penyimpanan data ke database. Seru banget, kan?

Dengan pendekatan TDD, kita akan memastikan bahwa setiap baris kode yang kita tulis benar-benar berfungsi sebagaimana mestinya. Bukan hanya itu, kita juga bisa menghindari bug yang biasanya muncul saat pengembangan aplikasi. Yuk, langsung saja kita mulai perjalanan belajar ini!

## Overview{#overview}
Sebelum kita masuk ke tutorial teknis, ada baiknya kita pahami dulu apa yang akan kita pelajari dalam artikel **Belajar TDD Laravel: Studi Kasus Menambahkan Post Baru (View Add Post Form dan Store New Post Data)** ini. Singkatnya, kita akan membangun sebuah fitur sederhana namun penting: menambahkan postingan baru ke dalam aplikasi web. 

Apa saja yang akan kita bahas? Berikut adalah gambaran umumnya:

1. **Pendekatan TDD**: Kita akan memulai dengan menulis tes terlebih dahulu sebelum menulis kode fungsional. Ini adalah inti dari TDD.
2. **Membuat View Form**: Kita akan merancang halaman formulir untuk menambahkan postingan baru.
3. **Menyimpan Data ke Database**: Setelah formulir dibuat, kita akan memastikan data yang dimasukkan oleh pengguna tersimpan dengan benar ke dalam database.
4. **Validasi Input**: Tidak hanya menyimpan data, kita juga akan memastikan input dari pengguna divalidasi agar sesuai dengan aturan yang ditentukan.
5. **Refactoring**: Terakhir, kita akan melakukan refactoring untuk memastikan kode kita tetap bersih dan mudah dipahami.

Dengan mempelajari semua ini, kamu tidak hanya akan memahami bagaimana cara kerja TDD, tetapi juga mendapatkan wawasan tentang bagaimana membangun aplikasi Laravel dengan cara yang lebih terstruktur dan efisien. Siap untuk mulai? Mari kita lanjutkan!

## Daftar Isi
1. [Introduction](#introduction)  
2. [Overview](#overview)  
3. [Apa Itu TDD dan Mengapa Penting?](#apa-itu-tdd-dan-mengapa-penting)  
4. [Persiapan Awal: Setup Laravel dan Testing Environment](#persiapan-awal-setup-laravel-dan-testing-environment)  
5. [Langkah 1: Menulis Tes untuk View Add Post Form](#langkah-1-menulis-tes-untuk-view-add-post-form)  
6. [Langkah 2: Implementasi View Add Post Form](#langkah-2-implementasi-view-add-post-form)  
7. [Langkah 3: Menulis Tes untuk Store New Post Data](#langkah-3-menulis-tes-untuk-store-new-post-data)  
8. [Langkah 4: Implementasi Store New Post Data](#langkah-4-implementasi-store-new-post-data)  
9. [Langkah 5: Validasi Input dan Refactoring](#langkah-5-validasi-input-dan-refactoring)  
10. [Kesimpulan](#kesimpulan)  

## Apa Itu TDD dan Mengapa Penting?{#apa-itu-tdd-dan-mengapa-penting}

Sebelum kita mulai coding, mari kita bahas sedikit tentang konsep TDD. TDD, atau **Test-Driven Development**, adalah metode pengembangan perangkat lunak yang mengharuskan kita menulis tes terlebih dahulu sebelum menulis kode fungsional. Ya, kamu tidak salah dengar—kita menulis tes *sebelum* kode utama! Konsep ini mungkin terdengar aneh bagi beberapa orang, tapi percayalah, ini sangat efektif.

### Bagaimana Cara Kerja TDD?

Proses TDD biasanya mengikuti siklus yang disebut **Red-Green-Refactor**:

1. **Red**: Tulis tes yang gagal karena fitur belum diimplementasikan.
2. **Green**: Tulis kode minimal yang cukup untuk membuat tes tersebut lulus.
3. **Refactor**: Perbaiki dan optimalkan kode tanpa mengubah perilaku fungsionalnya.

Dengan pendekatan ini, kita bisa memastikan bahwa setiap fitur yang kita buat benar-benar bekerja sesuai harapan. Selain itu, TDD juga membantu kita menghindari over-engineering, alias menulis kode yang lebih rumit daripada yang sebenarnya dibutuhkan.

### Mengapa TDD Penting dalam Laravel?

Laravel adalah framework PHP yang sangat populer, dan salah satu alasannya adalah dukungan kuatnya terhadap testing. Dengan Laravel, kita bisa dengan mudah menulis tes unit, tes integrasi, hingga tes end-to-end. Jadi, jika kamu ingin menjadi developer Laravel yang handal, memahami TDD adalah langkah yang sangat bijak.

Nah, sekarang setelah kita paham apa itu TDD dan mengapa itu penting, mari kita mulai persiapan awal untuk proyek kita. Yuk, lanjut ke bagian berikutnya!



## Persiapan Awal: Setup Laravel dan Testing Environment{#persiapan-awal-setup-laravel-dan-testing-environment}

Sebelum kita mulai menulis tes atau kode fungsional, ada beberapa hal yang perlu kita siapkan terlebih dahulu. Jangan khawatir, ini tidak serumit yang kamu bayangkan—kita hanya butuh beberapa langkah sederhana untuk memastikan semuanya berjalan lancar.

### 1. Instalasi Laravel

Pertama-tama, pastikan kamu sudah menginstal Laravel di komputer kamu. Jika belum, kamu bisa melakukannya dengan mudah menggunakan Composer. Buka terminal atau command prompt, lalu jalankan perintah berikut:

```bash
composer create-project laravel/laravel belajar-tdd-laravel
```

Perintah ini akan membuat proyek Laravel baru dengan nama folder `belajar-tdd-laravel`. Setelah proses instalasi selesai, masuk ke direktori proyek tersebut:

```bash
cd belajar-tdd-laravel
```

### 2. Konfigurasi Database

Karena kita akan menyimpan data postingan ke dalam database, kita perlu mengonfigurasi koneksi database terlebih dahulu. Buka file `.env` di root proyek, lalu atur detail koneksi database sesuai dengan pengaturan lokal kamu. Contohnya:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=belajar_tdd_laravel
DB_USERNAME=root
DB_PASSWORD=
```

Setelah itu, buat database kosong dengan nama `belajar_tdd_laravel` di MySQL (atau sistem database lain yang kamu gunakan). Kamu bisa melakukannya melalui phpMyAdmin atau menggunakan perintah SQL:

```sql
CREATE DATABASE belajar_tdd_laravel;
```

### 3. Menjalankan Migration

Laravel memiliki fitur migration yang sangat berguna untuk mengelola struktur database. Untuk studi kasus ini, kita akan membuat tabel `posts` untuk menyimpan data postingan. Jalankan perintah berikut untuk membuat migration baru:

```bash
php artisan make:migration create_posts_table
```

Setelah itu, buka file migration yang baru saja dibuat di folder `database/migrations`. Tambahkan kolom-kolom yang diperlukan, seperti `title` dan `content`, ke dalam tabel `posts`. Berikut adalah contoh kode migration:

```php
public function up(): void
{
    Schema::create('posts', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->text('content');
        $table->timestamps();
    });
}
```

Simpan file tersebut, lalu jalankan migration untuk membuat tabel di database:

```bash
php artisan migrate
```

Apabila teman-teman belum membuat database, akan tampil prompt untuk membuat database. Ketik `yes`, lalu tekan `enter` untuk melanjutkan.

```
$ php artisan migrate

   WARN  The database 'belajar_tdd_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 19.75ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 91.10ms DONE
  0001_01_01_000001_create_cache_table .......................... 33.84ms DONE
  0001_01_01_000002_create_jobs_table ........................... 81.44ms DONE
  2025_02_12_131426_create_posts_table .......................... 16.85ms DONE


```



### 4. Mengaktifkan Testing Environment

Laravel sudah dilengkapi dengan PHPUnit sebagai framework testing bawaan. Untuk memastikan environment testing berfungsi dengan baik, jalankan perintah berikut:

```bash
php artisan test
```

Jika semuanya berjalan lancar, kamu akan melihat pesan bahwa semua tes berhasil (meskipun saat ini mungkin belum ada tes yang ditulis). Ini berarti environment testing sudah siap digunakan.

Output:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s  

  Tests:    2 passed (2 assertions)
  Duration: 0.15s

```





## Langkah 1: Menulis Tes untuk View Add Post Form{#langkah-1-menulis-tes-untuk-view-add-post-form}

Sekarang kita sudah siap untuk mulai menerapkan TDD! Seperti yang telah disebutkan sebelumnya, langkah pertama dalam TDD adalah menulis tes. Dalam kasus ini, kita akan menulis tes untuk memastikan bahwa halaman formulir "Add Post" dapat diakses dan menampilkan elemen-elemen yang diperlukan.

### Membuat Test Case

Untuk membuat test case baru, jalankan perintah berikut:

```bash
php artisan make:test PostTest
```

Perintah ini akan membuat file baru di folder `tests/Feature` dengan nama `PostTest.php`. Buka file tersebut, lalu tambahkan kode berikut untuk menulis tes pertama kita:

```php
namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class PostTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_shows_the_add_post_form()
    {
        // Mengakses halaman add post form
        $response = $this->get('/posts/create');

        // Memastikan halaman berhasil dimuat (status code 200)
        $response->assertStatus(200);

        // Memastikan halaman menampilkan elemen form
        $response->assertSee('Add New Post');
        $response->assertSee('Title');
        $response->assertSee('Content');
        $response->assertSee('Submit');
    }
}
```

### Apa yang Dilakukan Tes Ini?

Tes ini melakukan beberapa hal:

1. Mengakses halaman `/posts/create` (yang nantinya akan menjadi halaman formulir).
2. Memastikan halaman tersebut berhasil dimuat dengan status code 200.
3. Memastikan halaman menampilkan elemen-elemen penting seperti judul form, input title, input content, dan tombol submit.

### Menjalankan Tes

Setelah menulis tes, jalankan perintah berikut untuk menjalankan tes:

```bash
php artisan test
```

Tentu saja, tes ini akan gagal karena kita belum membuat route atau view untuk halaman tersebut. Itu wajar—ini adalah bagian dari siklus TDD! Selanjutnya, kita akan mengimplementasikan halaman tersebut agar tes ini berhasil.



## Langkah 2: Implementasi View Add Post Form{#langkah-2-implementasi-view-add-post-form}

Setelah menulis tes, sekarang saatnya kita membuat halaman formulir "Add Post". Kita akan mulai dengan menambahkan route, controller, dan view yang diperlukan.

### 1. Menambahkan Route

Buka file `routes/web.php`, lalu tambahkan route baru untuk halaman formulir:

```php
use App\Http\Controllers\PostController;

Route::get('/posts/create', [PostController::class, 'create'])->name('posts.create');
```

### 2. Membuat Controller

Selanjutnya, kita perlu membuat controller untuk menangani logika halaman ini. Jalankan perintah berikut untuk membuat controller baru:

```bash
php artisan make:controller PostController
```

Buka file `PostController.php` yang baru saja dibuat, lalu tambahkan method `create`:

```php
namespace App\Http\Controllers;

use Illuminate\Http\Request;

class PostController extends Controller
{
    public function create()
    {
        return view('posts.create');
    }
}
```

### 3. Membuat View

Sekarang, kita perlu membuat file view untuk halaman formulir. Buat folder baru bernama `posts` di dalam folder `resources/views`, lalu buat file baru bernama `create.blade.php`. Isi file tersebut dengan kode berikut:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Add New Post</title>
</head>
<body>
    <h1>Add New Post</h1>
    <form action="/posts" method="POST">
        @csrf
        <label for="title">Title:</label><br>
        <input type="text" id="title" name="title"><br><br>

        <label for="content">Content:</label><br>
        <textarea id="content" name="content"></textarea><br><br>

        <button type="submit">Submit</button>
    </form>
</body>
</html>
```

### 4. Menjalankan Tes Lagi

Setelah semua langkah di atas selesai, jalankan tes lagi menggunakan perintah:

```bash
php artisan test
```

Jika semuanya berjalan dengan baik, tes ini seharusnya berhasil! Kamu sekarang sudah berhasil membuat halaman formulir "Add Post" menggunakan pendekatan TDD.

## Langkah 3: Menulis Tes untuk Store New Post Data{#langkah-3-menulis-tes-untuk-store-new-post-data}

Setelah berhasil membuat halaman formulir "Add Post", sekarang kita akan melanjutkan ke langkah berikutnya dalam **Belajar TDD Laravel**: menulis tes untuk memastikan data yang dimasukkan oleh pengguna tersimpan dengan benar ke dalam database. Ingat, dalam TDD, kita selalu menulis tes terlebih dahulu sebelum menulis kode fungsional.

### Membuat Test Case untuk Penyimpanan Data

Kembali ke file `PostTest.php` yang sudah kita buat sebelumnya, tambahkan test case baru untuk memeriksa apakah data postingan dapat disimpan dengan benar. Berikut adalah contoh kode yang bisa kamu gunakan:

```php
#[Test]
public function it_stores_new_post_data()
{
    // Data dummy untuk di-submit
    $postData = [
        'title' => 'Judul Postingan Pertama',
        'content' => 'Ini adalah konten dari postingan pertama saya.',
    ];

    // Mengirim POST request ke route /posts
    $response = $this->post('/posts', $postData);

    // Memastikan data tersimpan di database
    $this->assertDatabaseHas('posts', $postData);

    // Memastikan pengguna diarahkan ke halaman tertentu setelah submit
    $response->assertRedirect('/posts');
}
```

### Apa yang Dilakukan Tes Ini?

Tes ini melakukan beberapa hal penting:

1. Mengirimkan data dummy (judul dan konten) melalui metode POST ke route `/posts`.
2. Memastikan bahwa data tersebut tersimpan di tabel `posts` di database.
3. Memastikan pengguna diarahkan ke halaman tertentu (misalnya, halaman daftar postingan) setelah data berhasil disimpan.

### Menjalankan Tes

Setelah menulis tes ini, jalankan perintah berikut untuk menjalankan semua tes:

```bash
php artisan test
```

Seperti biasa, tes ini akan gagal karena kita belum membuat route, controller method, atau logika penyimpanan data. Itu wajar—ini adalah bagian dari siklus TDD! Sekarang, mari kita lanjutkan ke implementasi fitur ini.



## Langkah 4: Implementasi Store New Post Data{#langkah-4-implementasi-store-new-post-data}

Setelah menulis tes, saatnya kita mengimplementasikan fitur untuk menyimpan data postingan ke dalam database. Kita akan mulai dengan menambahkan route, mengupdate controller, dan menambahkan logika penyimpanan data.

### 1. Menambahkan Route untuk Penyimpanan Data

Buka kembali file `routes/web.php`, lalu tambahkan route baru untuk menangani POST request:

```php
Route::post('/posts', [PostController::class, 'store'])->name('posts.store');
```

### 2. Mengupdate Controller

Selanjutnya, buka file `PostController.php` dan tambahkan method `store`. Method ini akan menangani proses penyimpanan data ke dalam database:

```php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Post; // tambahkan statement use

class PostController extends Controller
{
    // baris kode lainnya ....
    
    public function store(Request $request)
    {
        // Validasi input (akan dibahas lebih lanjut di langkah berikutnya)
        $validatedData = $request->validate([
            'title' => 'required|max:255',
            'content' => 'required',
        ]);

        // Menyimpan data ke database
        Post::create($validatedData);

        // Redirect ke halaman tertentu setelah data tersimpan
        return redirect('/posts')->with('success', 'Postingan berhasil ditambahkan!');
    }
}
```

### 3. Membuat Model Post

Untuk menyimpan data ke dalam database, kita membutuhkan model. Jika kamu belum membuat model `Post`, jalankan perintah berikut:

```bash
php artisan make:model Post
```

Model ini secara otomatis akan terhubung ke tabel `posts` di database. Pastikan kolom-kolom yang ingin disimpan (seperti `title` dan `content`) sudah ada di migration tabel `posts`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    protected $fillable = [
        'title',
        'content',
    ];
}

```



### 4. Menjalankan Tes Lagi

Setelah semua langkah di atas selesai, jalankan tes lagi menggunakan perintah:

```bash
php artisan test
```

Jika semuanya berjalan dengan baik, tes ini seharusnya berhasil! Kamu sekarang sudah berhasil menyimpan data postingan ke dalam database menggunakan pendekatan TDD.



## Langkah 5: Validasi Input dan Refactoring{#langkah-5-validasi-input-dan-refactoring}

Meskipun fitur penyimpanan data sudah berfungsi, ada beberapa hal yang masih bisa kita tingkatkan. Salah satunya adalah validasi input untuk memastikan data yang dimasukkan oleh pengguna sesuai dengan aturan yang ditentukan. Selain itu, kita juga akan melakukan refactoring untuk memastikan kode tetap bersih dan mudah dipahami.

### 1. Menambahkan Validasi Input

Validasi input sangat penting untuk mencegah data tidak valid masuk ke database. Dalam method `store` di `PostController`, kita sudah menambahkan validasi sederhana. Namun, mari kita pastikan bahwa validasi ini juga diuji dalam tes kita.

Tambahkan test case baru di `PostTest.php` untuk memeriksa validasi:

```php
#[Test]
public function it_validates_input_data()
{
    // Mengirim data kosong
    $response = $this->post('/posts', []);

    // Memastikan validasi gagal dan pengguna mendapatkan error message
    $response->assertSessionHasErrors(['title', 'content']);
}
```

Tes ini memastikan bahwa jika pengguna mengirimkan data kosong, sistem akan memberikan pesan error untuk field `title` dan `content`.

### 2. Refactoring Kode

Setelah semua fitur berfungsi dengan baik, saatnya kita melakukan refactoring. Refactoring adalah proses memperbaiki struktur kode tanpa mengubah perilaku fungsionalnya. Beberapa hal yang bisa kita lakukan antara lain:

- Memindahkan logika validasi ke Form Request untuk membuat controller lebih bersih.
- Menggunakan resource controller untuk mengelola CRUD operations secara lebih terstruktur.

#### Contoh: Menggunakan Form Request

Untuk memindahkan logika validasi, kita bisa membuat Form Request baru:

```bash
php artisan make:request StorePostRequest
```

Buka file `StorePostRequest.php` yang baru saja dibuat, lalu tambahkan aturan validasi:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => 'required|max:255',
            'content' => 'required',
        ];
    }
}

```

Setelah itu, update method `store` di `PostController` untuk menggunakan Form Request ini:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest; // tambahkan statement use
use App\Models\Post;

class PostController extends Controller
{
	// .. baris kode lainnya

    public function store(StorePostRequest $request)
    {
        Post::create($request->validated());

        return redirect('/posts')->with('success', 'Postingan berhasil ditambahkan!');
    }
}

```

Dengan cara ini, controller kita menjadi lebih bersih dan mudah dipahami.

### 3. Menjalankan Tes Lagi

Setelah semua langkah di atas selesai, jalankan tes lagi menggunakan perintah:

```bash
php artisan test
```

Output:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  

   PASS  Tests\Feature\PostTest
  ✓ it shows the add post form                                           0.64s  
  ✓ it stores new post data                                              0.04s  
  ✓ it validates input data                                              0.02s  

  Tests:    5 passed (13 assertions)
  Duration: 0.84s

```





## Kesimpulan{#kesimpulan}

Selamat! Kamu sudah berhasil menyelesaikan tutorial **Belajar TDD Laravel: Studi Kasus Menambahkan Post Baru (View Add Post Form dan Store New Post Data)**. Dalam artikel ini, kita telah mempelajari bagaimana menerapkan pendekatan TDD untuk membangun fitur sederhana namun penting dalam aplikasi web. Mulai dari menulis tes, membuat view form, menyimpan data ke database, hingga melakukan validasi dan refactoring.

Tidak hanya itu, kamu juga sudah memahami bagaimana TDD dapat membantu kita menghasilkan kode yang lebih bersih, efisien, dan bebas bug. Ingatlah bahwa TDD bukan hanya tentang menulis tes, tetapi juga tentang membangun mindset yang berfokus pada kualitas dan keandalan aplikasi.

Jadi, apa langkahmu selanjutnya? Cobalah terapkan TDD dalam proyek-proyek Laravel lainnya. Semakin sering kamu melakukannya, semakin nyaman kamu akan merasa dengan pendekatan ini. Jangan lupa untuk terus eksplorasi fitur-fitur Laravel lainnya, seperti authentication, API development, dan banyak lagi!

Terima kasih sudah membaca artikel ini. Semoga bermanfaat dan selamat coding! 😊