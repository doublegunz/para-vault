---
title: "Tutorial Laravel: Upload Gambar Menggunakan Dropzone.js"
slug: "tutorial-laravel-upload-gambar-menggunakan-dropzonejs"
category: "Laravel"
date: "2024-08-09"
status: "published"
---

Upload gambar adalah fitur yang sering diperlukan di banyak aplikasi web. Dengan Dropzone.js, sebuah plugin jQuery yang populer, kita dapat meningkatkan fitur ini dengan interface yang intuitif untuk upload banyak gambar sekaligus. Pada seri tutorial edisi kali ini akan memandu teman-teman melalui proses mengintegrasikan Dropzone.js dan laravel dengan contoh praktis dan instruksi langkah demi langkah.

## Overview{#overview}
Pada seri tutorial Laravel edisi kali ini, kita akan belajar tentang cara mengimplementasikan fitur upload multiple images dengan menggunakan Dropzone.js dalam aplikasi Laravel. Dropzone.js adalah library JavaScript yang menyediakan antarmuka drag-and-drop yang interaktif dan intuitif untuk mengunggah file.

Tutorial ini akan membahas secara komprehensif proses integrasi Dropzone.js dengan Laravel, mulai dari setup awal project hingga implementasi lengkap. Kita akan membuat aplikasi sederhana yang memungkinkan pengguna untuk mengunggah beberapa gambar sekaligus dengan tampilan preview yang menarik.

![Akses form upload with dropzone](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/dropzone/1-form-with-dropzone.png)

Di akhir tutorial ini, Anda akan memahami:
- Cara membuat project Laravel baru dan mengonfigurasinya
- Cara membuat controller yang menangani proses upload file
- Cara mengimplementasikan Dropzone.js di view Laravel
- Cara menyimpan dan mengelola file yang diunggah pengguna
- Praktik terbaik dalam menangani upload file dalam aplikasi web

Tutorial ini cocok untuk developer pemula hingga menengah yang ingin memperluas pengetahuan mereka tentang Laravel dan interaksi frontend-backend. Semua langkah akan dijelaskan secara detail dengan kode yang dapat langsung diimplementasikan.

## Step 1: Buat Project Baru{#step-1-buat-project-baru}
Langkah pertama adalah membuat project Laravel baru. Buka terminal kita dan jalankan perintah berikut:

```bash
composer create-project --prefer-dist laravel/laravel dropzone-app
```

Setelah instalasi selesai, masuk ke direktori project:

```bash
cd dropzone-app
```

## Step 2: Buat Controller Baru{#step-2-buat-controller-baru}
Untuk menangani proses upload gambar, kita perlu membuat controller baru. Jalankan perintah berikut di terminal:

```bash
php artisan make:controller FileController
```

Output:

```
   INFO  Controller [app/Http/Controllers/FileController.php] created successfully.  
```


## Step 3: Tambahkan Method di FileController{#step-3-tambahkan-Method-di-filecontroller}
Buka file `app/Http/Controllers/FileController.php` dan tambahkan kode berikut:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FileController extends Controller
{
    public function create()
    {
        return view('file.create');
    }

    public function store(Request $request)
    {
        $image = $request->file('file');
        $imageName = time().$image->getClientOriginalName();
        $image->move(public_path('images'), $imageName);

        return response()->json(['success' => $imageName]);
    }
}
```

**Penjelasan:**

- `create()` : Method ini hanya mengembalikan view yang akan digunakan untuk upload gambar. Ini adalah method yang mengarahkan user ke view `file/create.blade.php`.
- `store(Request $request)` : Method ini menangani proses upload gambar. Gambar yang diupload diambil dari objek `Request` menggunakan method `file('file')` (gambar yang diupload oleh user). Nama file baru dibuat dengan menambahkan timestamp pada nama asli file untuk menghindari bentrokan nama file. File kemudian dipindahkan ke direktori `public/images`, dan jika berhasil, respons JSON dengan nama file yang diupload dikirim kembali ke klien.

## Step 4: Buat File View{#step-4-buat-file-view}
Selanjutnya, kita akan membuat file view untuk mengatur Dropzone.js. Buat file baru bernama `resources/views/file/create.blade.php` dan tambahkan kode berikut:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Tutorial Laravel: Upload Multiple Images using Dropzone.js @qadrlabs.com</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <link rel="stylesheet" href="https://unpkg.com/dropzone@5/dist/min/dropzone.min.css" type="text/css" />

    <style>
        body {
            background-color: #f6f8fd;
        }
    </style>
</head>
<body>
<div class="container">
    <div class="card mt-5 p-4">
        <div class="card-body">
            <h4 class="mb-3">Tutorial Laravel: Upload Multiple Images using Dropzone.js @ <a href="https://qadrlabs.com">qadrlabs.com</a></h4>
            <form action="{{ route('file.store') }}" method="post" enctype="multipart/form-data" class="dropzone" id="image-upload">
                @csrf
            </form>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
<script src="https://unpkg.com/dropzone@5/dist/min/dropzone.min.js"></script>
<script type="text/javascript">
    Dropzone.options.imageUpload = {
        maxFilesize: 1,
        acceptedFiles: ".jpeg,.jpg,.png,.gif"
    };
</script>
</body>
</html>
```

**Penjelasan:**

- `form action="{{ route('file.store') }}"` : Formulir ini dikonfigurasi untuk mengunggah file ke route `file.store` menggunakan method `POST`. Dropzone.js akan menangani proses upload file secara otomatis.
- `@csrf` : Ini adalah direktif Blade untuk memasukkan token CSRF, yang diperlukan untuk mengamankan form dari serangan CSRF.
- `Dropzone.options.imageUpload` : Ini adalah konfigurasi untuk Dropzone.js. `maxFilesize` membatasi ukuran file maksimal yang diupload (dalam megabyte), dan `acceptedFiles` menentukan jenis file yang diizinkan.

## Step 5: Registrasi route Baru{#step-5-registrasi-route-baru}
Langkah selanjutnya adalah menambahkan route baru di file `routes/web.php`:

```php
<?php

use App\Http\Controllers\FileController; // tambahkan use statement
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/file/create', [FileController::class, 'create'])->name('file.create'); // tambahkan route baru
Route::post('/file/store', [FileController::class, 'store'])->name('file.store'); // tambahkan route baru
```

**Penjelasan:**

- `Route::get('/file/create', [FileController::class, 'create'])` : route ini menampilkan halaman upload gambar dengan mengarahkan ke method `create()` di `FileController`.
- `Route::post('/file/store', [FileController::class, 'store'])` : route ini menangani permintaan `POST` untuk menyimpan gambar yang diupload dengan mengarahkan ke method `store()` di `FileController`.

## Step 6: Jalankan project{#step-6-jalankan-project}
Sekarang, jalankan project Laravel kita dengan perintah berikut:

```bash
php artisan serve
```

Buka browser dan akses `http://localhost:8000/file/create` untuk melihat form upload gambar dengan Dropzone.js.
![Akses form upload with dropzone](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/dropzone/1-form-with-dropzone.png)

Selanjutnya kita bisa *drag and drop* gambar ke dropzone (area dengan tulisan *Drop files here to upload*). Selanjutnya kita bisa lihat file berhasil kita upload.
![file berhasil diupload](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/dropzone/2-file-berhasil-diupload.png)

Kita juga bisa cek gambar yang berhasil kita upload di direktori `public/images`.

## Kesimpulan{#kesimpulan}
Pada tutorial ini, kita telah berhasil membuat aplikasi Laravel sederhana yang mengintegrasikan Dropzone.js untuk fitur upload multiple images. Kita telah mempelajari beberapa langkah penting dalam proses pengembangan, mulai dari pembuatan project Laravel baru, pembuatan controller untuk menangani upload file, membuat view dengan implementasi Dropzone.js, hingga konfigurasi route.

Dropzone.js menawarkan antarmuka yang intuitif dan user-friendly untuk upload gambar, memungkinkan pengguna melakukan drag and drop file dengan mudah. Dengan kombinasi Laravel dan Dropzone.js, kita dapat mengembangkan fitur upload gambar yang powerful dan efisien.

Beberapa poin penting yang telah kita pelajari:
- Cara membuat dan mengkonfigurasi controller untuk menangani upload file
- Implementasi Dropzone.js dalam view Laravel
- Pengaturan rute untuk menangani permintaan upload
- Penyimpanan file yang diupload ke direktori public

Dengan pemahaman yang didapat dari tutorial ini, Anda dapat mengembangkan fitur upload file yang lebih kompleks sesuai kebutuhan aplikasi yang Anda bangun.

## Referensi{#referensi}
- [Dokumentasi Dropzone.js](https://www.dropzonejs.com/)
- [Dokumentasi Laravel](https://laravel.com/docs/)