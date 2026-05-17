---
title: "Belajar Laravel 8: Refactor Controller Menggunakan Form Request Validation"
slug: "belajar-laravel-8-refactor-controller-menggunakan-form-request-validation"
category: "Laravel"
date: "2022-06-05"
status: "published"
---

Adakalanya saat kita mengembangkan web, setelah kita perhatikan dan kita review kembali ternyata logika kita menumpuk di satu tempat, misalnya di controller class. Dan boleh jadi untuk satu logika bisnis ini menghabiskan banyak baris kode di satu method. Misalkan pada saat membuat blog (yang sering dijadikan studi kasus di sini) untuk proses insert data saja, kadang terdapat beberapa proses, di mulai dari validasi form, create data post baru, upload image untuk header post, ada proses kirim notifikasi ke subscriber dan lain-lain. Banyak proses dalam satu method. Biasanya kita ingin memisahkan logika ini ke tempat lain supaya codingan kita tidak terlalu banyak. Cara ini biasanya disebut refactor.

Mengutip tulisan om Martin Fowler, [Refactor](https://martinfowler.com/tags/refactoring.html) adalah teknik restrukturisasi kode program komputer yang ada tanpa mengubah perilaku eksternalnya. Sebagai contoh studi kasusnya, kita akan coba merefactor kode dari seri belajar laravel 8 sebelumnya tentang crud. Pada fitur crud tentu ada fitur menambahkan data dan update data dan di dalamnya terdapat proses validasi form. Bagian validasi form ini akan kita coba ubah dan pisahkan dari method untuk menambahkan data dan update data dengan menggunakan solusi yang terdapat pada framework laravel, yaitu [Form Request Validation](https://laravel.com/docs/9.x/validation#form-request-validation). Selain itu, kita juga akan coba menggunakan `phpunit` untuk proses testing supaya setelah proses refactoring tidak mengubah fungsionalitas dari method yang sudah kita refactor nantinya. Nah, sekarang kita coba mulai belajar refactor controller.

## Overview {#overview}
Dalam tutorial kali ini, kita akan belajar tentang proses refactoring kode pada controller Laravel 8, khususnya dalam menangani validasi form. Seringkali saat mengembangkan aplikasi web, kita menemukan bahwa logika bisnis menumpuk di satu tempat seperti di controller class. Contohnya pada proses insert data blog yang memiliki berbagai proses mulai dari validasi form, create data post, upload image, hingga kirim notifikasi ke subscriber. 

Untuk mengatasi hal tersebut, kita akan menggunakan teknik refactoring dengan memanfaatkan fitur Form Request Validation yang disediakan Laravel. Fokus utama tutorial ini adalah memisahkan logika validasi dari method store() dan update() di PostController ke dalam class terpisah. Selain itu, kita juga akan menggunakan phpunit untuk memastikan bahwa fungsionalitas kode tetap sama setelah proses refactoring.

Goal yang ingin dicapai dalam tutorial ini adalah menghasilkan kode yang lebih ringkas dan terorganisir dengan tetap mempertahankan fungsionalitasnya. Kita akan melihat bagaimana cara mengimplementasikan Form Request Validation dan melakukan testing untuk memverifikasi bahwa perubahan yang kita lakukan tidak mengubah behavior dari aplikasi.

## Persiapan{#persiapan}
Project yang akan kita gunakan dalam percobaan refactor kali ini adalah project hasil dari tutorial [Testing Feature CRUD](https://qadrlabs.com/post/belajar-laravel-8-testing-crud-feature). Kenapa kita pakai project hasil dari tutorial tersebut? Karena kita perlu fitur CRUD yang sudah jadi dan yang akan kita coba refactor. Dan yang kedua kita juga perlu feature testing yang sudah kita coding di tutorial tersebut. Feature testing ini kita gunakan untuk memastikan tidak ada perubahan atau error ketika kita mengimplementasikan form request validation class. Jadi untuk mengikuti percobaan refactor kali ini, pastikan teman-teman sudah mengikuti tutorial testing feature crud, dari seri belajar laravel 8 sebelumnya.

Setelah sample project yang akan kita refactor siap, sebelum kita mulai refactor, kita run dulu phpunit. Buka terminal lalu kita run command berikut ini.
```
vendor/bin/phpunit
```

Output di terminal tampil hasil testing kurang lebih seperti di bawah ini.
```
PHPUnit 9.5.20 #StandWithUkraine

......                                                              6 / 6 (100%)

Time: 00:00.255, Memory: 32.00 MB

OK (6 tests, 26 assertions)
```

Karena belum ada perubahan jadi hasilnya masih sama seperti hasil seri belajar laravel 8 sebelumnya.

## Step 1 - Creating Form Request{#step-1}
Sekarang kita cek  kembali `PostController.php`. Di dalam class `PostController` terdapat dua method yang menggunakan proses validasi, yaitu `store()` dan `update()`.
```php
<?php

// .. baris kode lainnya

class PostController extends Controller
{
    // .. baris kode lainnya

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

    // ...

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

    // baris kode lainnya
}

```

Bagian yang akan kita refactor ini adalah bagian validasi untuk `store()` dan `update()`, jadi sekarang kita akan buat dua class Form Request Validation menggunakan  `artisan` command. Buka kembali terminal, lalu kita run command di bawah ini.
```
php artisan make:request StorePostRequest
php artisan make:request UpdatePostRequest
```

Setelah kita run dua command di atas, kita bisa lihat ada dua file baru hasil generate di direktori `app/Http/Requests`, yaitu file `StorePostRequest.php` dan `UpdatePostRequest.php`.

Sekarang kita buka file `StorePostRequest.php`.
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        return false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        return [
            //
        ];
    }
}

```

Di dalamnya terdapat dua method, yaitu `authorize()` dan `rules()`.

Sekarang kita ubah isi kedua method tersebut.
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ];
    }
}
```

Method `authorize()` kita jadikan `true`, sedangkan `rules()` kita ambil dari rule validasi dari method `store()` di `PostController`.

Selanjutnya kita modifikasi juga isi dari `app/Http/Requests/UpdatePostRequest.php`. 
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePostRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'title' => 'required|string|max:155',
            'content' => 'required',
            'status' => 'required'
        ];
    }
}
```

Ya, isinya tidak jauh berbeda dari class `StorePostRequest`. Kita ubah isi dari `authorize()` menjadi true dan juga `rules()` kita sesuaikan dengan aturan validasi dari method `update()` di `PostController`.

## Step 2 - Refactor Controller{#step-2}
Langkah selanjutnya adalah refactor `PostController` dan sebelum kita mulai, kita run kembali phpunit.
```
$ vendor/bin/phpunit
PHPUnit 9.5.20 #StandWithUkraine

......                                                              6 / 6 (100%)

Time: 00:00.258, Memory: 32.00 MB

OK (6 tests, 26 assertions)
```

Pertama kita coba refactor dulu method `store()`. Kita buka kembali `Http/Controllers/PostController.php` di text editor. Awalnya method `store()` seperti di bawah ini.
```php
<?php

// ... baris kode lainnya

class PostController extends Controller
{
    // ... baris kode lainnya

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

    // ... baris kode lainnya
}

```

Kita refactor menjadi seperti baris kode berikut ini.
```php
<?php

namespace App\Http\Controllers;

// ... baris kode lainnya

use App\Http\Requests\StorePostRequest; // tambahkan ini

class PostController extends Controller
{
    // ... baris kode lainnya

    public function store(StorePostRequest $request) // ubah parameter
    {
        $post = Post::create($request->validated() + ['slug' => Str::slug($request->title)]);

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

    // ... baris kode lainnya
}

```

Bisa kita perhatikan baris kode di atas. Awalnya *typehint* untuk `$request` merujuk ke `Illuminate\Http\Request`, sekarang kita gunakan form request validation class yang sebelumnya sudah kita buat, yaitu `App\Http\Requests\StorePostRequest`. Karena validasi sudah ditangani class `App\Http\Requests\StorePostRequest`, jadi kita bisa menghapus code validasi di method `store()` dan kita juga bisa menggunakan `$request->validated()` untuk insert data yang berisi array dari input yang sudah tervalidasi.

Setelah kita refactor method `store()`, sekarang kita test kembali menggunakan `phpunit`. Buka kembali terminal, lalu run phpunit.
```
$ vendor/bin/phpunit
PHPUnit 9.5.20 #StandWithUkraine

......                                                              6 / 6 (100%)

Time: 00:00.181, Memory: 32.00 MB

OK (6 tests, 26 assertions)
```

Ya, tidak ada error.

Baik kita lanjutkan.

Sekarang kita coba refactor method `update()`. Sebelum refactor, method `update()` berisi baris kode berikut ini.

```php
<?php

// ...  baris kode lainnya

class PostController extends Controller
{
    
    // ...  baris kode lainnya

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

    // ...  baris kode lainnya
}

```

Sekarang kita implementasikan `UpdatePostRequest` dan refactor method `update()`.
```php
<?php

namespace App\Http\Controllers;

// ... baris kode lainnya

use App\Http\Requests\UpdatePostRequest;  // tambahkan ini

class PostController extends Controller
{
    // ... baris kode lainnya

    public function update(UpdatePostRequest $request, $id)
    {
        $post = Post::findOrFail($id);

        $post->update($request->validated() + ['slug' => Str::slug($request->title)]);

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

    
    // ... baris kode lainnya
}
```

Sama seperti method `store()`, pada method `update()` kita ubah *typehint* `$request` dari `Illuminate\Http\Request` menjadi `App\Http\Requests\UpdatePostRequest` class. Selain itu pada proses update data, kita gunakan data yang sudah divalidasi untuk diupdate ke table menggunakan `$request->validated()`.

Sekarang kita coba test kembali, apakah berhasil atau ada error? Buka kembali terminal lalu kita run `phpunit`.
```
vendor/bin/phpunit
```
Outputnya:
```
vendor/bin/phpunit
PHPUnit 9.5.20 #StandWithUkraine

......                                                              6 / 6 (100%)

Time: 00:00.262, Memory: 32.00 MB

OK (6 tests, 26 assertions)
```
Ya, Refactor kita berhasil dan tidak ada error.

## Penutup {#penutup}
Pada tutorial kali ini kita telah berhasil melakukan refactoring pada controller Laravel 8 dengan memisahkan logika validasi ke class Form Request Validation yang terpisah. Kita telah mempelajari beberapa hal penting yaitu:

Pertama, kita berhasil memindahkan rules validasi dari PostController ke dalam class StorePostRequest dan UpdatePostRequest. Kedua, kita mengimplementasikan Form Request pada method store() dan update() sehingga membuat kode menjadi lebih ringkas namun tetap powerful. Dan yang tidak kalah penting, kita menggunakan phpunit untuk memastikan bahwa setiap perubahan yang kita lakukan tidak mengubah fungsionalitas aplikasi.

Hasil dari refactoring ini membuat kode kita menjadi lebih terorganisir dan mudah dimaintain karena logika validasi sudah dipisahkan ke class tersendiri. Meskipun secara jumlah file menjadi lebih banyak, namun pendekatan ini memberikan beberapa keuntungan seperti kode yang lebih modular, kemudahan dalam testing, dan potensi untuk reuse logika validasi di tempat lain.

Bagaimana menurutmu? Apakah pendekatan refactoring seperti ini lebih membantu dalam development aplikasi Laravel? Atau kamu punya pendekatan lain yang lebih baik? Mari kita diskusikan di kolom komentar.