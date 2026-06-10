---
title: "Laravel 13: Refactor Controller Anda dengan Form Request Validation"
slug: "refactor-controller-laravel-13-dengan-form-request-validation"
original_title: "Laravel 13: Refactor Your Controller with Form Request Validation"
original_slug: "laravel-13-refactor-your-controller-with-form-request-validation"
category: "Laravel"
date: "2026-03-24"
status: "draft"
---

Pada [tutorial CRUD](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step) kita, kita membangun aplikasi blog yang berfungsi dengan logika validasi di dalam controller. Pada [tutorial testing](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application) kita, kita menulis 19 Pest test untuk mencakup setiap operasi CRUD dan setiap kasus tepi validasi.

Sekarang kita memiliki jaring pengaman. Dan itulah saat yang tepat ketika refactoring menjadi aman dan produktif.

Pada tutorial ini, kita akan mengekstrak logika validasi dari `PostController` ke dalam class Form Request khusus. Controller menjadi lebih ramping, aturan validasi menjadi dapat digunakan kembali, dan test yang sudah ada memastikan tidak ada yang rusak sepanjang prosesnya.


## Ikhtisar {#overview}

Tutorial ini melanjutkan dari proyek blog yang sudah selesai beserta Pest test suite-nya. Kita akan melakukan refactor pada method `store()` dan `update()` di `PostController` dengan memindahkan logika validasinya ke dalam class Form Request khusus.

### Apa yang Akan Anda Lakukan

Anda akan membuat dua class Form Request (`StorePostRequest` dan `UpdatePostRequest`), memindahkan aturan validasi dan logika pembuatan slug ke dalamnya, menyederhanakan method controller, dan menjalankan test suite yang sudah ada untuk memastikan semuanya tetap berfungsi.

### Apa yang Akan Anda Pelajari

Dengan mengikuti tutorial ini, Anda akan belajar cara:

- Membuat class Form Request menggunakan Artisan.
- Memindahkan aturan validasi dari controller ke class Form Request.
- Menggunakan method `prepareForValidation()` untuk memanipulasi data request sebelum validasi.
- Menangani keunikan slug secara berbeda untuk operasi store dan update.
- Menggunakan type-hint Form Request pada method controller untuk validasi otomatis.
- Menggunakan test yang sudah ada untuk memverifikasi bahwa sebuah refactor tidak menimbulkan regresi.

### Apa yang Anda Butuhkan

- Proyek blog yang sudah selesai beserta Pest test suite dari [tutorial testing](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application).
- PHP 8.3 atau lebih tinggi.
- Pemahaman dasar tentang controller dan validasi Laravel.


## Masalahnya: Logika Validasi di Dalam Controller {#the-problem}

Mari kita lihat method `store()` dan `update()` saat ini di `app/Http/Controllers/PostController.php`:

```php
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
```

Ini berfungsi, tetapi ada beberapa masalah seiring berkembangnya aplikasi:

- **Controller melakukan terlalu banyak hal.** Ia menangani pembuatan slug, validasi, operasi database, dan logika response semuanya di dalam method yang sama. Setiap method memiliki banyak tanggung jawab.
- **Aturan validasi terduplikasi.** Method `store()` dan `update()` berbagi sebagian besar aturan yang sama, dengan hanya aturan keunikan slug yang berbeda. Jika Anda perlu menambahkan field baru atau mengubah sebuah aturan, Anda harus memperbaruinya di dua tempat.
- **Pembuatan slug tercampur dengan validasi.** Pemanggilan `$request->merge()` memodifikasi request sebelum validasi, yang memang berfungsi tetapi membuat alurnya lebih sulit diikuti.

Class Form Request Laravel menyelesaikan semua masalah ini dengan memberikan validasi class khususnya sendiri.


## Langkah 1: Jalankan Test Sebelum Refactoring {#step-1-run-tests-before}

Sebelum mengubah kode apa pun, jalankan test suite yang sudah ada untuk memastikan semuanya lolos:

```
php artisan test
```

Ke-19 test seharusnya lolos. Inilah baseline hijau kita. Jika ada test yang gagal setelah refactoring, kita akan langsung tahu bahwa refactor tersebut menimbulkan masalah.


## Langkah 2: Membuat StorePostRequest {#step-2-create-store-post-request}

Buat class Form Request untuk operasi store:

```
php artisan make:request StorePostRequest
```

Perintah ini membuat file baru di `app/Http/Requests/StorePostRequest.php`. Buka file tersebut dan ganti isinya dengan:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str; // add this line

class StorePostRequest extends FormRequest
{
    /**
        * Determine if the user is authorized to make this request.
        */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->title),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ];
    }
}

```

Mari kita telusuri setiap bagiannya:

**`authorize()`** menentukan apakah user saat ini diizinkan untuk membuat request ini. Karena blog kita belum memiliki autentikasi, kita mengembalikan `true` untuk mengizinkan semua request. Pada aplikasi nyata, Anda akan menambahkan logika otorisasi di sini, seperti memeriksa apakah user memiliki izin untuk membuat post.

**`prepareForValidation()`** dipanggil secara otomatis sebelum aturan validasi diterapkan. Ini adalah tempat yang sempurna untuk logika pembuatan slug yang sebelumnya ada di controller. Method ini menggabungkan slug yang dihasilkan ke dalam data request, sehingga ketika `rules()` berjalan, field `slug` sudah tersedia dan dapat divalidasi seperti field lainnya.

**`rules()`** mengembalikan aturan validasi. Ini adalah aturan yang persis sama dengan yang ada di method `store()` controller. Aturan `unique:posts,slug` memastikan tidak ada slug duplikat di dalam database.

Simpan file tersebut.


## Langkah 3: Membuat UpdatePostRequest {#step-3-create-update-post-request}

Buat class Form Request untuk operasi update:

```
php artisan make:request UpdatePostRequest
```

Buka `app/Http/Requests/UpdatePostRequest.php` dan ganti isinya dengan:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str; // add this line

class UpdatePostRequest extends FormRequest
{
    /**
         * Determine if the user is authorized to make this request.
         */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->title),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug,' . $this->route('post')->id . '|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ];
    }
}

```

Strukturnya hampir identik dengan `StorePostRequest`, dengan satu perbedaan penting pada aturan validasi slug.

**`'slug' => 'required|unique:posts,slug,' . $this->route('post')->id . '|max:255'`** menambahkan pengecualian pada pemeriksaan keunikan. `$this->route('post')` mengambil instance model `Post` dari parameter route (berkat route model binding), dan `->id` mendapatkan primary key-nya. Ini memberi tahu aturan `unique` untuk mengabaikan post saat ini ketika memeriksa duplikat. Tanpa ini, memperbarui sebuah post tanpa mengubah judulnya akan gagal karena slug yang sudah ada akan ditandai sebagai duplikat dari dirinya sendiri.

Di dalam controller, kita memiliki akses langsung ke variable `$post`. Di dalam Form Request, kita menggunakan `$this->route('post')` untuk mengakses instance model yang terikat route yang sama.

Simpan file tersebut.


## Langkah 4: Refactor Controller {#step-4-refactor-controller}

Sekarang mari kita perbarui `app/Http/Controllers/PostController.php` agar menggunakan class Form Request yang baru. Buka file tersebut dan terapkan perubahan berikut.

Pertama, perbarui statement `use` di bagian atas file. Hapus import `Illuminate\Http\Request` dan `Illuminate\Support\Str` (karena keduanya tidak lagi dibutuhkan di controller) dan tambahkan dua class Form Request:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;

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

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        Post::create($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdatePostRequest $request, Post $post)
    {
        $post->update($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

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

Bandingkan method `store()` dan `update()` yang baru dengan versi aslinya. Berikut yang berubah:

**Sebelum (store):**
```php
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
```

**Sesudah (store):**
```php
public function store(StorePostRequest $request)
{
    Post::create($request->validated());

    return redirect()->route('posts.index')->with('success', 'Post created successfully.');
}
```

Method tersebut berkurang dari 13 baris menjadi 4 baris. Semua logika pembuatan slug dan validasi telah dipindahkan ke `StorePostRequest`. Berikut yang terjadi di balik layar:

1. Ketika Laravel melihat `StorePostRequest` pada signature method, ia secara otomatis menginstansiasi class tersebut dan menjalankan validasi sebelum method controller dieksekusi.
2. Jika validasi gagal, Laravel mengarahkan kembali ke halaman sebelumnya dengan pesan error. Method controller tidak pernah dipanggil.
3. Jika validasi lolos, `$request->validated()` mengembalikan hanya field yang lolos validasi, yang kemudian diteruskan langsung ke `Post::create()`.

Pola yang sama berlaku untuk `update()`. Memberikan type-hint `UpdatePostRequest` memicu validasi otomatis dengan aturan khusus update, dan `$request->validated()` menyediakan data bersih untuk `$post->update()`.

Perhatikan bahwa import `use Illuminate\Http\Request` dan `use Illuminate\Support\Str` tidak lagi dibutuhkan di controller. Class `Request` telah digantikan oleh class Form Request yang spesifik, dan `Str` kini digunakan di dalam method `prepareForValidation()` milik Form Request.

Simpan file controller tersebut.


## Langkah 5: Jalankan Test Setelah Refactoring {#step-5-run-tests-after}

Inilah momen penentuan. Jalankan test suite untuk memverifikasi bahwa refactor tidak merusak apa pun:

```
php artisan test
```

Anda seharusnya melihat hasil yang sama seperti sebelumnya:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts
  ✓ index page shows empty state when no posts exist
  ✓ create page displays the form
  ✓ a new post can be stored
  ✓ slug is automatically generated from the title
  ✓ store validates required fields
  ✓ store validates title max length
  ✓ store validates status must be draft or publish
  ✓ store validates slug uniqueness
  ✓ show page displays a single post
  ✓ show returns 404 for non-existent post
  ✓ edit page displays the form with existing data
  ✓ a post can be updated
  ✓ update validates required fields
  ✓ update allows same slug for the same post
  ✓ a post can be deleted
  ✓ deleting a non-existent post returns 404

  Tests:    19 passed
  Duration: 0.52s
```

Ke-19 test lolos. Refactor berhasil. Perilaku validasi identik dengan yang kita miliki sebelumnya, tetapi kode kini terorganisasi lebih baik.

Inilah persis alasan kita menulis test tersebut pada tutorial sebelumnya. Tanpanya, kita harus menguji secara manual setiap pengiriman form, setiap skenario validasi, dan setiap kasus tepi di browser. Dengan adanya test suite, satu perintah `php artisan test` mengonfirmasi semuanya dalam hitungan detik.


## Apa yang Telah Kita Capai {#what-we-achieved}

Mari kita rangkum perubahan struktural dan mengapa hal itu penting.

### Sebelum: Controller Menangani Semuanya

```
PostController
├── store()    → slug generation + validation rules + create + redirect
└── update()   → slug generation + validation rules + update + redirect
```

### Sesudah: Tanggung Jawab yang Terpisah

```
StorePostRequest
├── prepareForValidation()  → slug generation
└── rules()                 → validation rules

UpdatePostRequest
├── prepareForValidation()  → slug generation
└── rules()                 → validation rules (with uniqueness exception)

PostController
├── store()    → create + redirect
└── update()   → update + redirect
```

Setiap class kini memiliki satu tanggung jawab yang jelas:

- **Form Request** menangani persiapan data dan validasi.
- **Controller** menangani logika bisnis (operasi database) dan logika response (redirect).

Pemisahan ini membuat codebase lebih mudah dipelihara. Jika Anda perlu mengubah sebuah aturan validasi, Anda tahu persis di mana harus mencarinya. Jika Anda perlu menggunakan kembali validasi yang sama pada sebuah endpoint API, Anda dapat memberikan type-hint pada class Form Request yang sama tanpa menduplikasi aturannya.


## Kesimpulan {#conclusion}

Pada tutorial ini, kita melakukan refactor pada `PostController` dengan mengekstrak logika validasi ke dalam class Form Request khusus. Method controller menjadi jauh lebih pendek dan lebih fokus, sementara aturan validasi dan logika pembuatan slug menemukan tempat yang semestinya di `StorePostRequest` dan `UpdatePostRequest`.

Berikut poin-poin pentingnya:

- **Test membuat refactoring menjadi aman.** Ke-19 Pest test yang kita tulis pada tutorial sebelumnya memberi kita keyakinan untuk merestrukturisasi kode tanpa takut merusak perilaku yang sudah ada. Menjalankan `php artisan test` setelah refactor mengonfirmasi semuanya tetap berfungsi.
- **`prepareForValidation()` adalah tempat yang tepat untuk transformasi data.** Alih-alih memanggil `$request->merge()` di controller, memindahkan pembuatan slug ke `prepareForValidation()` menjaga alur data tetap bersih: transformasi dulu, baru validasi.
- **`$this->route('post')` memberikan akses ke model yang terikat route.** Di dalam Form Request, Anda tidak dapat mengakses parameter method controller secara langsung. Gunakan `$this->route()` untuk mengambil instance model dari route model binding.
- **`$request->validated()` mengembalikan hanya data yang tervalidasi.** Ini lebih aman daripada menggunakan `$request->all()` karena memastikan hanya field yang lolos validasi yang digunakan untuk mass assignment.
- **Form Request dapat digunakan kembali.** Jika nanti Anda membangun sebuah endpoint API yang juga membuat post, Anda dapat memberikan type-hint pada `StorePostRequest` yang sama di controller API. Logika validasi tidak perlu ditulis ulang.
- **Controller yang ramping lebih mudah dipelihara.** Ketika setiap method hanya beberapa baris panjangnya, langsung jelas apa yang dilakukan method tersebut. Kompleksitasnya berada di class khusus tempat ia lebih mudah ditemukan, diuji, dan dimodifikasi.

Pola refactoring ini berlaku untuk controller Laravel mana pun yang memiliki validasi inline. Mulailah dengan method yang memiliki logika validasi terbanyak dan lanjutkan dari sana.

Pada tutorial berikutnya, kita akan [menambahkan Authentication dan Authorization dengan PHP Attributes](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes) ke proyek kita.
